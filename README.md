\# CI Phase – Jenkins Setup \& GitHub Webhook



This document covers the CI (Continuous Integration) phase of the Netflix Clone DevSecOps project.



\## CI Architecture


The CI flow is:

GitHub


&#x20;  ↓

GitHub Webhook

&#x20;  ↓

ngrok

&#x20;  ↓

Jenkins

&#x20;  ↓

Docker Build

&#x20;  ↓

Docker Hub



The deployment/CD phase is handled separately by Argo CD.



\---



\# 1. Jenkins Server



Jenkins is installed on the CI server and runs on port `8080`.



Check Jenkins status:



```bash

sudo systemctl status jenkins



Start Jenkins:



sudo systemctl start jenkins



Stop Jenkins:



sudo systemctl stop jenkins



Restart Jenkins:



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



A small XML mistake can prevent Jenkins from starting.



For example, an accidental string before the XML declaration:



trueifali<?xml version='1.1' encoding='UTF-8'?>



makes the configuration invalid.



The file should start with:



<?xml version='1.1' encoding='UTF-8'?>

<hudson>

3\. Jenkins Troubleshooting



If Jenkins fails to start:



sudo systemctl status jenkins --no-pager -l



Check Jenkins logs:



sudo journalctl -u jenkins --no-pager -n 50



If the configuration was recently modified, restore the backup:



sudo systemctl stop jenkins



sudo cp /var/lib/jenkins/config.xml.backup \\

/var/lib/jenkins/config.xml



sudo systemctl reset-failed jenkins



sudo systemctl start jenkins



Verify:



sudo systemctl status jenkins --no-pager



Expected:



Active: active (running)

4\. Validate Jenkins XML Configuration



Install XML validation tools:



sudo apt install -y libxml2-utils



Validate the Jenkins configuration:



sudo xmllint --noout /var/lib/jenkins/config.xml



Note:



Jenkins may use XML version 1.1. xmllint can display a warning such as:



Unsupported version '1.1'



This does not necessarily mean the Jenkins configuration is broken.



5\. Running Jenkins Manually for Troubleshooting



If systemd cannot start Jenkins, it can be useful to run Jenkins directly to see the actual application error:



sudo systemctl stop jenkins

sudo -u jenkins /usr/bin/jenkins



If Jenkins starts successfully, you should see:



Jenkins is fully up and running



Stop the manually running Jenkins with:



Ctrl + C



Then start it normally:



sudo systemctl start jenkins

6\. Jenkins Users



Jenkins local users are stored under:



/var/lib/jenkins/users/



List Jenkins users:



sudo ls -la /var/lib/jenkins/users/



Find user configuration files:



sudo find /var/lib/jenkins/users -maxdepth 2 -name config.xml -print



The Jenkins username must match an existing Jenkins user.



Do not assume that the username is always:



admin

7\. Jenkins Web Access Using ngrok



Because Jenkins is running on:



localhost:8080



ngrok can expose Jenkins to GitHub.



Start ngrok:



sudo ngrok http 8080



ngrok will provide a public HTTPS address similar to:



https://example.ngrok-free.dev



Open this address in a browser to access Jenkins.



8\. Run ngrok in Background



To run ngrok without keeping the terminal attached:



nohup ngrok http 8080 > /tmp/ngrok.log 2>\&1 \&



Check whether ngrok is running:



ps aux | grep ngrok



Check ngrok logs:



cat /tmp/ngrok.log



ngrok's local API can be checked with:



curl http://127.0.0.1:4040/api/tunnels

Important



The free ngrok URL can change when ngrok is restarted.



If the URL changes, the GitHub webhook must be updated.



9\. GitHub Webhook



Go to:



GitHub Repository

→ Settings

→ Webhooks

→ Add webhook



Use:



Payload URL:

https://<NGROK-URL>/github-webhook/



Example:



https://example.ngrok-free.dev/github-webhook/



Set:



Content type:

application/json



For the initial setup, select:



Just the push event



Enable:



Active



Then click:



Add webhook

10\. Git Branch Workflow



The project uses a feature branch and main branch.



Example:



git checkout feature



Make changes and check status:



git status



Add files:



git add .



Commit:



git commit -m "update configuration"



Push the feature branch:



git push origin feature



Then create a Pull Request from:



feature → main



After the Pull Request is merged, main receives a push event.



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



\*/main



Script Path:



Jenkinsfile



The Jenkinsfile should be stored in the project repository.



13\. CI Pipeline



The planned CI pipeline is:



Developer

&#x20;   ↓

Feature Branch

&#x20;   ↓

Pull Request

&#x20;   ↓

main

&#x20;   ↓

GitHub Webhook

&#x20;   ↓

Jenkins

&#x20;   ↓

Checkout

&#x20;   ↓

Build Docker Image

&#x20;   ↓

Push Docker Image to Docker Hub

&#x20;   ↓

Update Deployment



Argo CD handles the Kubernetes deployment/CD portion.



14\. Docker Image



The application Docker image is:



itsurvey6/netflix



The Docker image can be built using:



docker build -t itsurvey6/netflix:latest .



Check images:



docker images



Login to Docker Hub:



docker login



Push the image:



docker push itsurvey6/netflix:latest



Never put a Docker Hub password or access token directly inside the Jenkinsfile.



Use Jenkins Credentials instead.



15\. Kubernetes Deployment



The Kubernetes manifests are located in:



k8s/



Current files:



k8s/

├── deployment.yml

└── service.yml



Deployment:



apiVersion: apps/v1

kind: Deployment



Service:



apiVersion: v1

kind: Service



The application runs on container port:



3000



The service uses:



targetPort: 3000



and is configured as:



type: LoadBalancer

16\. Argo CD



Argo CD watches the GitHub repository:



https://github.com/itsurvey6-lab/netflix-clone.git



Path:



k8s



Destination:



in-cluster



Namespace:



netflix



The Argo CD application is:



netflix-clone



Check Argo CD application:



kubectl get applications -n argocd



Example:



NAME            SYNC STATUS   HEALTH STATUS

netflix-clone   Synced        Healthy

17\. Kubernetes Verification



Check the application namespace:



kubectl get all -n netflix



Check deployment:



kubectl get deployment -n netflix



Check pods:



kubectl get pods -n netflix



Check ReplicaSets:



kubectl get rs -n netflix



Check service:



kubectl get svc -n netflix



Expected deployment:



netflix-app



Expected replicas:



2/2

18\. Argo CD Troubleshooting



Check the application:



kubectl get applications -n argocd



Detailed information:



kubectl describe application netflix-clone -n argocd



If the application reports:



namespaces "netflix" not found



create the namespace:



kubectl create namespace netflix



Then sync the Argo CD application again.



19\. Important Kubernetes Lesson



The following are different concepts:



netflix-clone



is the Argo CD Application name.



netflix-app



is the Kubernetes Deployment/Service application name.



netflix



is the Kubernetes namespace.



They are not the same thing.



The relationship is:



Argo CD Application

&#x20;       |

&#x20;       | deploys

&#x20;       ↓

Kubernetes namespace: netflix

&#x20;       |

&#x20;       ├── Deployment: netflix-app

&#x20;       |

&#x20;       ├── Pods: netflix-app-xxxxx

&#x20;       |

&#x20;       └── Service: netflix-app

20\. Final CI/CD Architecture



The completed project follows:



&#x20;                   GitHub

&#x20;                      |

&#x20;                      |

&#x20;                Feature Branch

&#x20;                      |

&#x20;                      ↓

&#x20;                Pull Request

&#x20;                      |

&#x20;                      ↓

&#x20;                    main

&#x20;                      |

&#x20;                      ↓

&#x20;                 Webhook

&#x20;                      |

&#x20;                      ↓

&#x20;                   ngrok

&#x20;                      |

&#x20;                      ↓

&#x20;                  Jenkins

&#x20;                      |

&#x20;             ┌────────┴────────┐

&#x20;             ↓                 ↓

&#x20;         Build Image       Test/Scan

&#x20;             |

&#x20;             ↓

&#x20;         Docker Hub

&#x20;             |

&#x20;             ↓

&#x20;       Kubernetes Manifest

&#x20;             |

&#x20;             ↓

&#x20;           Argo CD

&#x20;             |

&#x20;             ↓

&#x20;       Kubernetes Cluster

&#x20;             |

&#x20;             ↓

&#x20;       Netflix Application

Troubleshooting Summary

Jenkins does not start

sudo systemctl status jenkins --no-pager -l

sudo journalctl -u jenkins --no-pager -n 50

Jenkins configuration was accidentally modified



Restore backup:



sudo systemctl stop jenkins

sudo cp /var/lib/jenkins/config.xml.backup /var/lib/jenkins/config.xml

sudo systemctl reset-failed jenkins

sudo systemctl start jenkins

Check Jenkins is running

sudo systemctl status jenkins



Expected:



Active: active (running)

Check Jenkins port

sudo ss -tulnp | grep 8080

Check ngrok

ps aux | grep ngrok

curl http://127.0.0.1:4040/api/tunnels

Check GitHub webhook



GitHub:



Repository

→ Settings

→ Webhooks

→ Recent Deliveries



Look for a successful delivery.



Check Argo CD

kubectl get applications -n argocd

Check Kubernetes application

kubectl get all -n netflix

Security Notes



Do not commit any of the following to GitHub:



Jenkins passwords

Docker Hub passwords

Docker Hub access tokens

GitHub tokens

Kubernetes secrets

ngrok authentication tokens



Use Jenkins Credentials or another secret-management mechanism instead.



Current Status



The following components have been completed:



&#x20;Kubernetes cluster

&#x20;Prometheus

&#x20;Grafana

&#x20;Argo CD

&#x20;Netflix Kubernetes Deployment

&#x20;Netflix Kubernetes Service

&#x20;Argo CD application

&#x20;GitHub repository

&#x20;Jenkins

&#x20;ngrok

&#x20;GitHub webhook setup



Next CI automation tasks:



&#x20;Create Jenkinsfile

&#x20;Configure Jenkins Pipeline

&#x20;Add Docker Hub credentials to Jenkins

&#x20;Build Docker image automatically

&#x20;Push image to Docker Hub

&#x20;Connect CI changes with Argo CD deployment

&#x20;Test complete GitHub → Jenkins → Docker Hub → Argo CD → Kubernetes workflow

