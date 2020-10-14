DOCKER_FILE=.docker

NETWORK_NAME=network

PHP_CONTAINER_NAME=php
PHP_VERSION=7.4
PHP_DOCKERFILE_PATH=${DOCKER_FILE}/Php

SRC_PATH=src
SRC_FRONT_PATH=${SRC_PATH}/assets

SERVER_CONTAINER_NAME=nginx
SERVER_DOCKERFILE_PATH=${DOCKER_FILE}/Nginx
SERVER_PORT=80
SERVER_HOST=localhost

build_network: 	
	@echo "creating network"
	docker network create ${NETWORK_NAME}

build_php:
	@echo "creating php"
	docker image build --build-arg PHP_VERSION=${PHP_VERSION} --network ${NETWORK_NAME} --tag i_${PHP_CONTAINER_NAME} ${PHP_DOCKERFILE_PATH}

build_server:
	@echo "creating server"
	docker image build --network ${NETWORK_NAME} --tag i_${SERVER_CONTAINER_NAME} ${SERVER_DOCKERFILE_PATH}

build_app:
	docker run --rm --interactive --tty --user=$(shell id -u):$(shell id -u)\
  		--volume $(shell pwd):/app \
  		composer create-project symfony/symfony-demo ${SRC_PATH}

run_php:
	docker run -d --name ${PHP_CONTAINER_NAME} \
	-v $(shell pwd)/${SRC_PATH}:/var/www/html \
	i_${PHP_CONTAINER_NAME}

run_server:
	docker run -d --name ${SERVER_CONTAINER_NAME} --publish ${SERVER_PORT}:80 \
			-v $(shell pwd)/${SERVER_DOCKERFILE_PATH}/site.conf:/etc/nginx/conf.d/default.conf \
			i_${SERVER_CONTAINER_NAME}

stop_php:
	- docker container stop ${PHP_CONTAINER_NAME}
	- docker container rm ${PHP_CONTAINER_NAME}

stop_server:
	- docker container stop ${SERVER_CONTAINER_NAME}
	- docker container rm ${SERVER_CONTAINER_NAME}

clean_network:
	@echo "cleaning network"
	- docker network rm ${NETWORK_NAME}

clean_php:
	@echo "cleaning php"
	- docker image rm ${PHP_CONTAINER_NAME}

clean_server:
	@echo "cleaning server"
	- docker image rm ${SERVER_CONTAINER_NAME}

clean_app:
	- find $(shell pwd)/${SRC_PATH}/ -regextype egrep -regex  '.*\/.*' -exec rm -r {} \;

build: build_network build_php build_server

clean: clean_server clean_php clean_network 

test_server: stop_server clean_server build_server run_server