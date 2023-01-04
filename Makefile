IMAGE_NAME = hello:v1
CONTAINER_NAME = hello-app
CUSTOMER_NAME ?= A

CURRENT_USER = $(shell echo $$USER)
INTERNAL_USER_A = A
INTERNAL_USER_B = B
INTERNAL_USER_C = C

install-k3s:
	echo "Installing K3S and running the cluster..."
	curl -sfL https://get.k3s.io | sh - 
	
	echo "Waiting for cluster to be online..."
	sleep 10

run:
	echo "Installing dependencies..."
	pip3 install --no-cache-dir --upgrade -r app/requirements.txt --user

	echo "Running the application locally..."
	export CUSTOMER_NAME=A
	uvicorn app.main:app --reload --host 0.0.0.0 --port 80
	
build-app:
	echo "Building the Docker image..."
	docker build -t $(IMAGE_NAME) app/

run-app:
	docker stop $(CONTAINER_NAME) || true

	echo "Running Customer A Application..."
	export CUSTOMER_NAME=A
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_A) -itd -p 8080:80 -e CUSTOMER_NAME=$(CUSTOMER_NAME) $(IMAGE_NAME)

	echo "Running Customer B Application..."
	export CUSTOMER_NAME=B
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_B) -itd -p 8081:80 -e CUSTOMER_NAME=$(CUSTOMER_NAME) $(IMAGE_NAME)

	echo "Running Customer C Application..."
	export CUSTOMER_NAME=C
	docker run --rm --name $(CONTAINER_NAME)-$(INTERNAL_USER_C) -itd -p 8082:80 -e CUSTOMER_NAME=$(CUSTOMER_NAME) $(IMAGE_NAME)

deploy: install-k3s import-docker-image
	sudo chown $(CURRENT_USER) /etc/rancher/k3s/k3s.yaml
	sudo chmod 600 /etc/rancher/k3s/k3s.yaml
	export KUBECONFIG=/etc/rancher/k3s/k3s.yaml	

	sleep 3

	echo "Deploying the Customer A"

	helm template -f app-chart/A.values.yaml app-chart/
	helm install -f app-chart/A.values.yaml customer-a app-chart/ --namespace customer-a --create-namespace 

	echo "Deploying the Customer B"
	sleep 2

	helm template -f app-chart/B.values.yaml app-chart/
	helm install -f app-chart/B.values.yaml customer-b app-chart/ --namespace customer-b --create-namespace 

	echo "Deploying the Customer C"
	sleep 2

	helm template -f app-chart/C.values.yaml app-chart/
	helm install -f app-chart/C.values.yaml customer-c app-chart/ --namespace customer-c --create-namespace 


	$(eval LB_IP=$(shell sh -c "k3s kubectl get svc traefik -n kube-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'"))
	@printf "\n---------------------\nAdd the Following IP as an entry to the /etc/hosts with domain names\n\n"
	@printf "$(LB_IP) customer-a.parcellab.com customer-b.parcellab.com customer-c.parcellab.com"
	

import-docker-image: build-app
	echo "Importing the docker image to K3S..."
	docker save --output $(IMAGE_NAME).tar $(IMAGE_NAME)
	sudo k3s ctr images import $(IMAGE_NAME).tar

test: build-app run-app
	echo "Testing the endpoint of the Customer $(INTERNAL_USER_A)..."
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_A) bash -c pytest

	sleep 2
	
	echo "Testing the endpoint of the Customer $(INTERNAL_USER_B)..."
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_B) bash -c pytest

	sleep 2

	echo "Testing the endpoint of the Customer $(INTERNAL_USER_C)..."
	docker exec -it $(CONTAINER_NAME)-$(INTERNAL_USER_C) bash -c pytest

clean:
	echo "Stopping and Removing the Docker Containers..."
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_A) || true
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_B) || true
	docker stop -f $(CONTAINER_NAME)-$(INTERNAL_USER_C) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_A) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_B) || true
	docker rm -f $(CONTAINER_NAME)-$(INTERNAL_USER_C) || true	
	
	echo "Remove Docker image"
	docker rmi $(IMAGE_NAME) || true

	echo "Uninstalling K3S..."
	/usr/local/bin/k3s-uninstall.sh || true