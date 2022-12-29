# Challenge

This repository responsible for creating a REST-API which responds with different salutations for different customers. And the application is Containerized and deployed in a selected container orchestrator (`Kubernetes`)


## 1. Directory Hierarchy 

```
.
├── Makefile
├── README.md
├── app
│   ├── Dockerfile
│   ├── __init__.py
│   ├── main.py
│   ├── requirements.txt
│   └── test_main.py
├── app-chart
   ├── A.values.yaml
   ├── B.values.yaml
   ├── C.values.yaml
   ├── Chart.yaml
   └── templates
       ├── _helpers.tpl
       ├── deployment.yaml
       ├── ingress.yaml
       └── service.yaml
```

## 2. Assumptions Made

As per the requirements, the application is deployed **individually** for each customer. 

> Therefore, the assumptions is to have an Application that is a very generic boilerplate and keep it **DRY** (Don't Repeat Yourself) - i.e. for each customer, it only requires to adjust a very minimum set of configurations to make it more specific to the customer (to get the specific response they expect). By this, application itself will be re-usable. 


## 3. Prerequisites


- A Kubernetes Cluster - In this example a simple [K3S](https://k3s.io/) cluster is used

Installation:

```
// install k3s
curl -sfL https://get.k3s.io | sh - 

// Setup cluster access - Need for helm deployments and kubectl access
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

k3s kubectl get node 
```

- [Helm](https://helm.sh/)

- [Docker](https://www.docker.com/)

- [Python](https://www.python.org/downloads/) - If planning to run locally

- You are using Linux :) 

## 4. Run the API 🚀

### Get the most out of `Makefile`

In this example, for automating the build and deployment process of this application, a `Makefile` is introduced. It is nothing but a file with set of tasks defined to be executed. Consider it as a simple pipeline to automate the manual tasks associated with building, running and deploying the application both locally and in kubernetes. 

1. Run Locally

```
// install the requirements
# pip install --no-cache-dir --upgrade -r app/requirements.txt

// run the application
# make run
```

2. Build Image & Run 

Since the application is a container-ready application, a `Dockerfile` is used to build the image. This is the most hassle-free solution to share your application and run it anywhere where the Docker is installed. 

```
// build the Docker image
make build-app

// run the Docker container
export CUSTOMER_NAME=<CUSTOMER-NAME> # eg:- export CUSTOMER_NAME=A
make run-app

// access the application
curl -kv http://0.0.0.0:8080
```

2. Deploy in Kubernetes

Before deploying the application in `Kubernetes`, make sure you have installed `helm` and `k3s` (and it is up and running) as mentioned in the Prerequsites section above. 

And also since we are using local repository for storing the Docker image of our application, we need to import that image to the K3S's (This is useful for anyone who cannot get k3s server to work with the `--docker` flag)

```
// this will export the docker image from local repository and import it into K3s
make import-docker-image

// list the image in K3s context
k3s ctr image list
```

Once everything is satisified;

```
// deploy the application for customer "A"
make deploy-a
k3s kubectl get po,svc,ing -n customer-a 


// deploy the application for customer "B"
make deploy-b
k3s kubectl get po,svc,ing -n customer-b

// deploy the application for customer "C"
make deploy-c
k3s kubectl get po,svc,ing -n customer-c 
```

By default `k3s` uses `Traefik` as the ingress-controller.

There are many other tools out there to satisfy the need of an ingress-controller, but to make things super clean, clear and easier, we are using the `Traefik` that comes by-default with `k3s`. 

Traefik create s `LoadBalancer` type Service in the `kube-system` namepsace And since we are using different `Ingress` rules for each customer with custom-domains that doesn't exist, we have to map the custom-domains to Traefik's LoadBalancer Service if we need to access our deployments. To access;

Get the `EXTERNAL-IP` of the Traefik's LoadBalancer type Service

```
k3s kubectl get svc -n kube-system | grep traefik

traefik          LoadBalancer   10.43.11.175    10.70.1.173   80:32537/TCP,443:30694/TCP   5h8m
```

```
// add the DNS entry at /etc/hosts
sudo vim /etc/hosts
```

Add the following entry. `10.70.1.173` is the `EXTERNAL-IP` and DNS names are specific to customers and defined in the `Ingress` rules (eg: "`- host: customer-a.parcellab.com`")

```
10.70.1.173 customer-a.parcellab.com customer-b.parcellab.com customer-c.parcellab.com
```

Once the entries are added, you can access the each customer application instance as below:

```
// access the Customer "A" application
curl -kv http://customer-a.parcellab.com

*   Trying 127.0.0.1:80...
* Connected to customer-b.parcellab.com (127.0.0.1) port 80 (#0)
...
< HTTP/1.1 200 OK
...
* Connection #0 to host customer-b.parcellab.com left intact

{"response":"Hi!"}



// access the Customer "B" application
curl -kv http://customer-b.parcellab.com

*   Trying 127.0.0.1:80...
* Connected to customer-b.parcellab.com (127.0.0.1) port 80 (#0)
...
< HTTP/1.1 200 OK
...
* Connection #0 to host customer-b.parcellab.com left intact

{"response":"Dear Sir or Madam!"}



// access the Customer "C" application
curl -kv http://customer-c.parcellab.com

*   Trying 127.0.0.1:80...
* Connected to customer-b.parcellab.com (127.0.0.1) port 80 (#0)
...
< HTTP/1.1 200 OK
...
* Connection #0 to host customer-b.parcellab.com left intact

{"response":"Moin!"}
```

As mentioned above, the response varies according to the domain (customer)