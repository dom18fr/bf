TARGETS:=$(MAKEFILE_LIST)
WITHDOCKER:=$(if $(shell which docker),$(shell which docker),)
COMPOSER_ARGS=--no-interaction

RED:=\033[0;31m
GREEN:=\033[0;32m
NC=\033[0m

.PHONY: help
help: ## This help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(TARGETS) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

-include .env
.env:
	$(MAKE) .env

.PHONY: install
install: .env docker-compose.yml start vendor site cim restart

.PHONY: vendor
vendor:
	$(call dc,exec,app,composer install $(COMPOSER_ARGS))

.PHONY: update
update:
	$(call dc,exec,app,composer update $(COMPOSER_ARGS))

.PHONY: sql
sql:
	$(call dc,exec,app,mysql -u ${MYSQL_USER} -p$(MYSQL_PASSWORD)) $(MYSQL_DATABASE)

.PHONY: site
site:
	$(call dc,exec,app,cp web/sites/default/bf.settings.local.php web/sites/default/settings.local.php)
	$(call dc,exec,app,cp web/sites/default/bf.services.local.yml web/sites/default/services.local.yml)
	$(call dc,exec,app, drush sql-drop -y)
	$(call dc,exec,app,drush site:install minimal --account-name=admin --account-mail=admin@admin.com --account-pass=admin -y)
	$(call dc, exec, app, drush config-set system.site uuid $(CONFIG_UUID) -y)

.PHONY: cms-reset-data
cms-reset-data: ## restore init dump
	docker-compose stop mysql
	docker-compose rm -f mysql
	docker volume rm mysql-data
	docker-compose up -d mysql

ifneq ($(WITHDOCKER),)
define dc
    docker-compose $(1) $(2) $(3)
endef
define dcornot
    docker-compose $(1) $(2) $(3)
endef
else
define dc
    $(3)
endef
define dcornot
endef
endif

OS := $(shell uname)
RUNNING:=$(shell docker ps -q --filter status=running --filter name=^/$(COMPOSE_PROJECT_NAME) | xargs)

.PHONY: start
start: docker-compose.yml
ifneq ($(WITHDOCKER),)
ifeq ($(RUNNING),)
	$(call dc,up -d)
endif
endif

.PHONY: stop
stop: docker-compose.yml
	$(call dc,stop)
	$(call dc,down)

.PHONY: restart
restart:
	$(call dc,stop)
	$(call dc,down)
	$(call dc,up -d)

.PHONY: cim
cim:
	$(call dc,exec,app,bash -c "drush cim -y")

.PHONY: cex
cex:
	$(call dc,exec,app,bash -c "drush cex -y")

.PHONY: require
require:
	$(call dc,exec,app,bash -c "composer require $${vendor}")

.PHONY: remove
remove:
	$(call dc,exec,app,bash -c "composer remove $${vendor}")

.PHONY: cr
cr:
	$(call dc,exec,app,bash -c "drush cr")

.PHONY: add
add:
	$(call dc,exec,app,bash -c "composer require drupal/$${module}")
	$(call dc,exec,app,bash -c "drush en $${module} -y")

.PHONY: en
en:
	$(call dc,exec,app,bash -c "drush en $${module} -y")

.PHONY: bash
make bash:
	$(call dc,exec,app,bash -c "export COLUMNS=`tput cols`; export LINES=`tput lines`; exec bash")

.PHONY: refresh
refresh: 
	$(call dc,exec,app,bash -c "composer install $(COMPOSER_ARGS)")
	$(call dc,exec,app,bash -c "drush cr")
	$(call dc,exec,app,bash -c "drush cim -y")
	$(call dc,exec,app,bash -c "drush updb -y")
	$(call dc,exec,app,bash -c "drush entity:update -y")