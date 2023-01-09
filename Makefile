IMAGE_NAME = hello:v1
CONTAINER_NAME = hello-app
CUSTOMER_NAME ?= A

CURRENT_USER = $(shell echo $$USER)
CURRENT_PATH = $(shell echo $$PWD)
INTERNAL_USER_A = A
INTERNAL_USER_B = B
INTERNAL_USER_C = C
INTERNAL_USER_INVALID = X

.EXPORT_ALL_VARIABLES:
KUBECONFIG = /etc/rancher/k3s/k3s.yaml

install-k3s:
	echo "Installing K3S and running the cluster..."
	curl -sfL https://get.k3s.io | sh - 
	
	echo "Waiting for cluster to be online..."
	sleep 10

run:
	@printf "\nInstalling dependencies..."
	pip3 install --no-cache-dir --upgrade -r app/requirements.txt --user

	sudo chown $(CURRENT_USER) app/*
	sudo chmod 644 app/*

	@printf "\nRunning the application locally..."
	export CUSTOMER_NAME=$(CUSTOMER_NAME)
	uvicorn app.main:app --reload --host 0.0.0.0 --port 80
	
build-app:
	echo "Building the Docker image..."

	docker stop $(CONTAINER_NAME)-$(INTERNAL_USER_A) || true
	docker stop $(CONTAINER_NAME)-$(INTERNAL_USER_B) || true
	docker stop $(CONTAINER_NAME)-$(INTERNAL_USER_C) || true
	docker stop $(CONTAINER_NAME)-$(INTERNAL_USER_INVALID) || true
	docker rmi $(IMAGE_NAME) || true

	docker build -t $(IMAGE_NAME) app/

run-app:

	@printf "\n\nRunning Invalid Customer Application..."
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_INVALID) -itd -p 8083:80 -e CUSTOMER_NAME=$(INTERNAL_USER_INVALID) $(IMAGE_NAME)

	sleep 1

	@printf "\n\nRunning Customer A Application..."
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_A) -itd -p 8080:80 -e CUSTOMER_NAME=$(INTERNAL_USER_A) $(IMAGE_NAME)

	sleep 1

	@printf "\n\nRunning Customer B Application..."
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_B) -itd -p 8081:80 -e CUSTOMER_NAME=$(INTERNAL_USER_B) $(IMAGE_NAME)

	sleep 1

	@printf "\n\nRunning Customer C Application..."
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_C) -itd -p 8082:80 -e CUSTOMER_NAME=$(INTERNAL_USER_C) $(IMAGE_NAME)

deploy: install-k3s import-docker-image
	sudo chown $(CURRENT_USER) /etc/rancher/k3s/k3s.yaml
	sudo chmod 644 /etc/rancher/k3s/k3s.yaml

	sleep 3

	@printf "\nDeploying the Customer A\n"

	helm template -f app-chart/customer-values/A.values.yaml app-chart/
	helm install -f app-chart/customer-values/A.values.yaml customer-a app-chart/ --namespace customer-a --create-namespace 

	@printf "\nDeploying the Customer B\n"
	sleep 2

	helm template -f app-chart/customer-values/B.values.yaml app-chart/
	helm install -f app-chart/customer-values/B.values.yaml customer-b app-chart/ --namespace customer-b --create-namespace 

	@printf "\nDeploying the Customer C\n"
	sleep 2

	helm template -f app-chart/customer-values/C.values.yaml app-chart/
	helm install -f app-chart/customer-values/C.values.yaml customer-c app-chart/ --namespace customer-c --create-namespace 

	@printf "\nRetrieving the LoadBalancer IP...\n"
	sleep 5
	
	@printf "\n---------------------\nAdd the Following IP as an entry to the /etc/hosts with domain names\n\n"
	@printf "$$(k3s kubectl get svc traefik -n kube-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}') customer-a.parcellab.com customer-b.parcellab.com customer-c.parcellab.com\n"
	

import-docker-image: build-app
	sudo chown $(CURRENT_USER) /etc/rancher/k3s/k3s.yaml
	sudo chmod 644 /etc/rancher/k3s/k3s.yaml

	echo "Importing the docker image to K3S..."
	docker save --output $(IMAGE_NAME).tar $(IMAGE_NAME)
	sudo k3s ctr images import $(IMAGE_NAME).tar

test: build-app run-app

	@printf "\n\nTesting the endpoint of the Customer $(INTERNAL_USER_INVALID)...\n"
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_INVALID) pytest

	sleep 2

	@printf "\n\nTesting the endpoint of the Customer $(INTERNAL_USER_A)...\n"
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_A) pytest

	sleep 2
	
	@printf "\n\nTesting the endpoint of the Customer $(INTERNAL_USER_B)...\n"
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_B) pytest

	sleep 2

	@printf "\n\nTesting the endpoint of the Customer $(INTERNAL_USER_C)...\n"
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_C) pytest


clean:
	@printf "\nStopping and Removing the Docker Containers...\n"
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_A) || true
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_B) || true
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_C) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_A) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_B) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_C) || true	
	
	@printf "\nRemoving Docker image...\n"
	docker rmi -f $(IMAGE_NAME) || true

	@printf "\nUninstalling K3S...\n"
	/usr/local/bin/k3s-uninstall.sh || true

	@printf "\nRemoving the .tar...\n"
	rm -rf $(IMAGE_NAME).tar