This document covers the CI (Continuous Integration) phase of the Netflix Clone DevSecOps project.


\# 1. Jenkins Server



Jenkins is installed on the CI server and runs on port `8080`.

sudo systemctl start jenkins
sudo systemctl restart jenkins

Reset a failed Jenkins service:
sudo systemctl reset-failed jenkins

Check whether port 8080 is being used:
sudo ss -tulnp | grep 8080

2\. Jenkins Configuration File

Jenkins configuration is stored at:
/var/lib/jenkins/config.xml

Before modifying the configuration, create a backup:
sudo cp /var/lib/jenkins/config.xml /var/lib/jenkins/config.xml.backup


View the configuration:
sudo cat /var/lib/jenkins/config.xml

Important
Do not edit config.xml unnecessarily.

3\. Jenkins Troubleshooting

If Jenkins fails to start:
sudo systemctl status jenkins --no-pager -l

Check Jenkins logs:
sudo journalctl -u jenkins --no-pager -n 50

If the configuration was recently modified, restore the backup:
sudo systemctl stop jenkins

sudo cp /var/lib/jenkins/config.xml.backup /var/lib/jenkins/config.xml
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins

Verify:
sudo systemctl status jenkins --no-pager


4\. Validate Jenkins XML Configuration
Install XML validation tools:
sudo apt install -y libxml2-utils

Validate the Jenkins configuration:
sudo xmllint --noout /var/lib/jenkins/config.xml


6\. Jenkins Users

Jenkins local users are stored under:
/var/lib/jenkins/users/

List Jenkins users:
sudo ls -la /var/lib/jenkins/users/
Find user configuration files:


7\. Jenkins Web Access Using ngrok
Because Jenkins is running on:
localhost:8080

ngrok can expose Jenkins to GitHub.
Start ngrok:
sudo ngrok http 8080

ngrok will provide a public HTTPS address similar to:
https://example.ngrok-free.dev


9\. GitHub Webhook
Go to:
GitHub Repository

→ Settings

→ Webhooks

→ Add webhook

Use:

Payload URL:

https://<NGROK-URL>/github-webhook/

Content type:
application/json
Add webhook

10\. Git Branch Workflow

The project uses a feature branch and main branch.

Example:

git checkout feature
Make changes and check status:
git status
Add files:
Commit:
git commit -m "update configuration"

Push the feature branch:
git push origin feature


That push can trigger Jenkins.


11\. Jenkins Pipeline Trigger
Create a Jenkins Pipeline job.

Recommended configuration:

New Item

→ netflix-clone

→ Pipeline


Under:
Build Triggers
enable:
GitHub hook trigger for GITScm polling
The GitHub webhook will then notify Jenkins when a push occurs.



12\. Pipeline From GitHub

Recommended Jenkins Pipeline configuration:

Definition:

Pipeline script from SCM
SCM:
Git
Repository:
https://github.com/itsurvey6-lab/netflix-clone.git
Branch:
\*/feature
Script Path:
Jenkinsfile

The Jenkinsfile should be stored in the project repository.
# Netflix Clone — DevSecOps CI/CD

A Netflix Clone application deployed on Kubernetes using Jenkins CI, Docker Hub, Trivy, SonarQube, Dependency-Check and Argo CD.

## Architecture

Developer
   ↓
GitHub Feature Branch
   ↓
GitHub Webhook
   ↓
Jenkins CI
   ├── SonarQube
   ├── Dependency Check
   ├── Trivy FS Scan
   ├── Docker Build
   ├── Trivy Image Scan
   └── Docker Hub
          ↓
    netflix:BUILD_NUMBER
          ↓
   Pull Request
   feature → main
          ↓
       Argo CD
          ↓
     Kubernetes
          ↓
     Netflix App


## Technologies

- Next.js
- Docker
- Jenkins
- GitHub
- Docker Hub
- SonarQube
- Trivy
- OWASP Dependency-Check
- Kubernetes
- Argo CD
- AWS EKS


## Git Branch Strategy

- `feature` → development and CI
- `main` → approved/production configuration

Workflow:

```text
feature → Jenkins CI → Docker Hub → PR → main → Argo CD → Kubernetes
Docker

Dockerfile uses the TMDB API key during image build:

ARG API_KEY
ENV TMDB_KEY=${API_KEY}

Build manually:

docker build --build-arg API_KEY=YOUR_KEY -t netflix ./nextflix

Run:

docker run -p 3000:3000 netflix
Jenkins

Jenkins performs:

Checkout feature
SonarQube analysis
Dependency Check
Trivy filesystem scan
Docker build
Trivy image scan
Push image to Docker Hub

Image format:

itsurvey6/netflix:<BUILD_NUMBER>

Example:

itsurvey6/netflix:23
Jenkins Credentials

Configured credentials:

github-push
Docker-hub
tmdb-api-key
nvd-api-key

TMDB key is injected securely:

withCredentials([string(
    credentialsId: 'tmdb-api-key',
    variable: 'TMDB_API_KEY'
)]) {
    sh '''
        docker build \
        --build-arg API_KEY="$TMDB_API_KEY" \
        -t netflix ./nextflix
    '''
}
Docker Hub

Login/push is handled by Jenkins:

withDockerRegistry(
    credentialsId: 'Docker-hub',
    url: 'https://index.docker.io/v1/'
)

Image:

itsurvey6/netflix:BUILD_NUMBER
Kubernetes

Deployment:

image: itsurvey6/netflix:23

Check deployment:

kubectl get deployment -n netflix

Check pods:

kubectl get pods -n netflix

Check image:

kubectl get deployment netflix-app -n netflix \
-o jsonpath='{.spec.template.spec.containers[0].image}'; echo

Check logs:

kubectl logs -n netflix deployment/netflix-app --tail=100
Argo CD

Argo CD watches the main branch and synchronizes Kubernetes manifests.

Flow:

PR feature → main
      ↓
Argo CD detects change
      ↓
Sync
      ↓
Kubernetes
Important Git Commands

Check branch:

git branch --show-current

Check status:

git status

Switch branch:

git checkout feature
git checkout main

Update branch:

git pull origin feature
git pull origin main

Commit:

git add .
git commit -m "message"

Push:

git push origin feature
git push origin main

View history:

git log --oneline --decorate -5
Git Merge Conflict

If Git reports:

CONFLICT (content): Merge conflict in k8s/deployment.yml

Open the file and remove:


Keep the correct Docker image, for example:

image: itsurvey6/netflix:23

Then:

git add k8s/deployment.yml
git commit -m "Resolve deployment conflict"
git push origin feature
Common Problems
Jenkins not triggered

Check:

GitHub webhook URL
GitHub webhook Recent Deliveries
Jenkins GitHub hook trigger for GITScm polling
Jenkins branch:
*/feature
Repository URL and credentials
Jenkins triggers itself repeatedly

This happened because Jenkins updated deployment.yml and pushed back to the same branch.

Bad flow:

Jenkins
 ↓
update deployment.yml
 ↓
push feature
 ↓
GitHub webhook
 ↓
Jenkins again

For a clean production design, separate application CI from GitOps configuration, preferably using a separate GitOps repository.

Git push rejected

If:

! [rejected] main -> main (fetch first)

Use:

git pull --rebase origin main
git push origin main

Do not use force push unless you specifically understand the consequences.

Docker image not updating

Check Docker Hub:

docker pull itsurvey6/netflix:23

Check Kubernetes:

kubectl get deployment netflix-app -n netflix \
-o jsonpath='{.spec.template.spec.containers[0].image}'; echo
curl not found inside container

If:

exec: "curl": executable file not found

The container image doesn't contain curl.

Use Kubernetes networking/debug tools instead of installing packages into the production container.

Application API returns Error

Check:

kubectl logs -n netflix deployment/netflix-app --tail=100

Verify the TMDB API key was supplied during Docker build:

--build-arg API_KEY="$TMDB_API_KEY"

Also verify the Docker image being deployed is the expected build number.

Final CI/CD Flow
Developer
   ↓
git push feature
   ↓
GitHub Webhook
   ↓
Jenkins
   ↓
SonarQube
   ↓
Dependency Check
   ↓
Trivy
   ↓
Docker Build
   ↓
Trivy Image Scan
   ↓
Docker Hub
   ↓
itsurvey6/netflix:BUILD_NUMBER
   ↓
Pull Request
   ↓
feature → main
   ↓
Argo CD
   ↓
Kubernetes / EKS
   ↓
Netflix Application