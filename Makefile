########################################
##         Migration Pipeline         ##
##     Ollin Demian Langle Chimal     ##
########################################

.PHONY: clean data lint init deps sync_to_gs sync_from_gs

########################################
##            Variables               ##
########################################

PROJECT_NAME:=$(shell cat .project-name)
PROJECT_VERSION:=$(shell cat .project-version)

## Python Version
VERSION_PYTHON:=$(shell python -V)

## GS Bucket
GS_BUCKET := gs://$(PROJECT_NAME)

SHELL := /bin/bash

## Airflow variables
AIRFLOW_GPL_UNIDECODE := yes

########################################
##       Environment Tasks            ##
########################################

init: prepare ##@dependencias Prepara la computadora para el funcionamiento del proyecto

prepare: deps
#	pyenv virtualenv ${PROJECT_NAME}_venv
#	pyenv local ${PROJECT_NAME}_venv

#pyenv: .python-version
#	@pyenv install $(VERSION_PYTHON)

deps: pip airdb

pip: requirements.txt
	@pip install -r $<

airdb:
	@source .env
	--directory=$(AIRFLOW_HOME)
	@airflow initdb

info:
	@echo Project: $(PROJECT_NAME) ver. $(PROJECT_VERSION)
	@python --version
	# @pyenv --version
	@pip --version

########################################
##          Infrastructure            ##
##    	   Execution Tasks            ##
########################################

create: ##@infrastructure Crea infraestructura necesaria: Pull de imágenes y crea el storage local
	$(MAKE) --directory=infrastructure create

start: create ##@infraestructura Inicializa la infraestructura y ejecuta el entrenamiento
	$(MAKE) --directory=infrastructure start

stop: ##@infrastructure Detiene la infrastructure
	$(MAKE) --directory=infrastructure stop

status: ##@infrastructure Informa el estatus de la infrastructure
	$(MAKE) --directory=infrastructure status

logs:   ##@infrastructure Despliega en pantalla las salidas de los logs de la infrastructure
	$(MAKE) --directory=infrastructure logs

restart: ##@infrastructure Reinicializa la infrastructure
	$(MAKE) --directory=infrastructure restart

destroy: ##@infrastructure Destruye la infrastructure
	$(MAKE) --directory=infrastructure clean

nuke: ##@infrastructure Destruye la infrastructure (incluyendo las imágenes)
	$(MAKE) --directory=infrastructure nuke

neo4j:
	@$(MAKE) --directory=infrastructure init

ingest:
	@$(MAKE) --directory=infrastructure ingester
########################################
##           Data Sync Tasks          ##
########################################

sync_to_gs: ##@data Sincroniza los datos hacia GCP GS
	@gsutil -m rsync -R data/ $(GS_BUCKET)/data/

sync_from_gs: ##@data Sincroniza los datos desde GCP GS
	@gsutil -m rsync -R $(GS_BUCKET)/data/ data/


########################################
##          Project Tasks             ##
########################################

run:       ##@proyecto Ejecuta el pipeline de datos
	$(MAKE) --directory=$(PROJECT_NAME) run

setup: build install ##@proyecto Crea las imágenes del pipeline e instala el pipeline como paquete en el PYTHONPATH

build:
	$(MAKE) --directory=$(PROJECT_NAME) build

install:
	@pip install --editable .

uninstall:
	@while pip uninstall -y ${PROJECT_NAME}; do true; done
	@python setup.py clean

########################################
##            Funciones               ##
##           de soporte               ##
########################################

## NOTE: Tomado de https://gist.github.com/prwhite/8168133 , en particular,
## del comentario del usuario @nowox, lordnynex y @HarasimowiczKamil

## COLORS
BOLD   := $(shell tput -Txterm bold)
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
BLUE   := $(shell tput -Txterm setaf 5)
RESET  := $(shell tput -Txterm sgr0)

## NOTE: Las categorías de ayuda se definen con ##@categoria
HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-z0-9_\-]+)\s*:.*\#\#(?:@([a-z0-9_\-]+))?\s(.*)$$/ }; \
    print "uso: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${BOLD}${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${BOLD}${BLUE}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }

## Verificando dependencias
## Basado en código de Fernando Cisneros @ datank

EXECUTABLES = docker docker-compose docker-machine rg pip
TEST_EXEC := $(foreach exec,$(EXECUTABLES),\
				$(if $(shell which $(exec)), some string, $(error "${BOLD}${RED}ERROR${RESET}: $(exec) is not in the PATH")))

