
COMPOSE := docker compose
LOCAL_FILE := docker-compose.yml
PROD_FILE := docker-compose.prod.yml

.PHONY: init local local-down prod prod-down logs ps

init:
	./init.sh

local:
	$(COMPOSE) -f $(LOCAL_FILE) up -d --build

local-down:
	$(COMPOSE) -f $(LOCAL_FILE) down

prod:
	$(COMPOSE) -f $(PROD_FILE) up -d --build

prod-down:
	$(COMPOSE) -f $(PROD_FILE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps
