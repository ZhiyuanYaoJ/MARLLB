LOCAL_DIR=$(shell pwd)
DOCKER_REPO=zhiyuanyaoj
PROJECT=marllb
DOCKER_IMAGE=${DOCKER_REPO}/${PROJECT}:latest
WORK_DIR=/opt/marllb

.PHONY: build-docker, build-origin, run

help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

build-docker: ## Build the container image
	docker build \
		-t ${DOCKER_IMAGE} \
		-f build/Dockerfile \
		.

build-origin: ## Pull all required docker images, fetch the origin KVM image, build the container image
	docker pull ${DOCKER_REPO}/${PROJECT}:base;
	docker pull ${DOCKER_REPO}/${PROJECT}:img;
	docker run -it --name ${PROJECT}-img -d ${DOCKER_REPO}/${PROJECT}:img /bin/bash;
	docker cp ${PROJECT}-img:/opt/img/origin.img data/img/origin.img;
	docker stop ${PROJECT}-img; docker rm ${PROJECT}-img;
	docker build --no-cache \
		-t ${DOCKER_IMAGE} \
		-f build/Dockerfile \
		.

run: ## Run container
	sudo docker run -it \
		--name $(PROJECT) \
		-p 8888:8888 \
		--privileged \
		--cap-add=ALL -d \
		-v $(LOCAL_DIR):$(WORK_DIR) \
		-v /dev:/dev \
		-v /sys/bus:/sys/bus \
		${DOCKER_IMAGE} \
		jupyter notebook --no-browser $(WORK_DIR) --allow-root --ip 0.0.0.0

docker-run-unittest: ## (run only in docker) Run unittest
	python3 src/test/test_pipeline.py; \
	/usr/bin/reset

docker-clean: ## (run only in docker) Shutdown all KVMs in the container and cleanup the unittest results
	python3 src/test/test_shut_all.py; \
	rm -rf data/results/unittest;

clean-all: clean ## Clean up all required images, remove all results
	docker image inspect ${DOCKER_REPO}/${PROJECT}:latest >/dev/null 2>&1 && docker rmi ${DOCKER_REPO}/${PROJECT}:latest || echo the image ${DOCKER_REPO}/${PROJECT}:latest does not exist; \
	docker image inspect ${DOCKER_REPO}/${PROJECT}:base >/dev/null 2>&1 && docker rmi ${DOCKER_REPO}/${PROJECT}:base || echo the image ${DOCKER_REPO}/${PROJECT}:base does not exist; \
	rm data/img/*.img
	

clean: stop ## Stop and remove a running container, remove KVM image docker, remove unittest results
	docker image inspect ${DOCKER_REPO}/${PROJECT}:img >/dev/null 2>&1 && docker rmi ${DOCKER_REPO}/${PROJECT}:img || echo the image ${DOCKER_REPO}/${PROJECT}:img does not exist; \
	rm -rf data/results/unittest;

stop: ## Stop and remove a running container
	if docker ps -a | grep -q $(PROJECT); then \
		docker stop $(PROJECT); docker rm $(PROJECT); \
	fi;

publish: repo-login publish-latest ## Publish the `latest` tagged containers
	
publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(PROJECT):latest

tag-latest: ## Generate container tag
	@echo 'create tag latest'
	docker tag $(PROJECT) $(DOCKER_REPO)/$(PROJECT):latest

repo-login: ## Auto login to AWS-ECR unsing aws-cli
	@echo 'login docker repo'
	docker login