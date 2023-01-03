IMAGE_NAME = hello:v1
CONTAINER_NAME = hello-app
CUSTOMER_NAME ?= A

CURRENT_USER = $(shell echo $$USER)

install-k3s:
	curl -sfL https://get.k3s.io | sh - 
	
	echo "Waiting for cluster to be online..."
	sleep 10

	sudo chown $(CURRENT_USER) /etc/rancher/k3s/k3s.yaml
	sudo chmod 777 /etc/rancher/k3s/k3s.yaml
	export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

	k3s kubectl get node 

run:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 80
	
build-app:
	docker build -t $(IMAGE_NAME) app/
run-app:
	docker stop $(CONTAINER_NAME) || true
	docker run --rm --name $(CONTAINER_NAME) -itd -p 80:80 -e CUSTOMER_NAME=$(CUSTOMER_NAME) $(IMAGE_NAME)

deploy:
	sudo chown $(whoami) /etc/rancher/k3s/k3s.yaml
	sudo 777 /etc/rancher/k3s/k3s.yaml
	export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

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

import-docker-image: build-app
	docker save --output $(IMAGE_NAME).tar $(IMAGE_NAME)
	sudo k3s ctr images import $(IMAGE_NAME).tar

test: build-app run-app
	docker exec -it $(IMAGE_NAME) bash -c pytest

clean:
	docker stop -f $(CONTAINER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
	/usr/local/bin/k3s-uninstall.sh || true