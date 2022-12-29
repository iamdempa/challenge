IMAGE_NAME = hello
CUSTOMER_NAME ?= A

run:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 80
	
build-app:
	docker build -t $(IMAGE_NAME) app/
run-app:
	docker run --rm --name hello-app -it -p 8080:80 -e CUSTOMER_NAME=$(CUSTOMER_NAME) $(IMAGE_NAME)

deploy-a:
	helm template -f app-chart/A.values.yaml app-chart/
	helm install -f app-chart/A.values.yaml customer-a app-chart/ --namespace customer-a --create-namespace 

deploy-b:
	helm template -f app-chart/B.values.yaml app-chart/
	helm install -f app-chart/B.values.yaml customer-b app-chart/ --namespace customer-b --create-namespace 

deploy-c:
	helm template -f app-chart/C.values.yaml app-chart/
	helm install -f app-chart/C.values.yaml customer-c app-chart/ --namespace customer-c --create-namespace 
