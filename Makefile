# Make file for version-control-template

.PHONY: init add remove local_projects global_projects

TAG := "Makefile"

LOCAL_PROJECTS := .local_projects.yaml
GLOBAL_PROJECTS := .global_projects.yaml
TEMPLATE := .template

TEMPLATE_KEY := .template
PROJECT_KEY := .projects

INIT_TAG := "init"
init:
	@# Make sure the user has YQ
	@command -v yq > /dev/null 2>&1 || { \
		echo "$(TAG) | $(INIT_TAG) | yq is required, but not installed."; \
		read -p "$(TAG) | $(INIT_TAG) | Do you want to install yq now? (y/n) " yn; \
		if [ "$$yn" = "y" ] || [ "$$yn" = "Y" ]; then \
			echo "$(TAG) | $(INIT_TAG) | Installing yq..."; \
			sudo apt install yq; \
		else \
			echo "$(TAG) | $(INIT_TAG) | Please install yq manually"; \
		fi \
	}
	@yq e -n '$(TEMPLATE_KEY) = ["$(TEMPLATE)"] | $(PROJECT_KEY) = []' > $(LOCAL_PROJECTS)
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(INIT_TAG) | repo init successfully"

ADD_TAG := "add"
add:
ifndef project
	$(error Path not specified. Run: make add project=[project])
endif
	@# If the folder already exists in the global scope
	@if yq e '$(PROJECT_KEY)[]' $(GLOBAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) already exists at the global level"; \
		exit 1; \
	fi

	@# If the project already exists in the local scope
	@if yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) already exists at the local level"; \
		exit 2; \
	fi
	
	@# Add the project
	@yq e '$(PROJECT_KEY) += ["$(project)"]' -i $(LOCAL_PROJECTS)

	@cp -r $(TEMPLATE) "$(project)"
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(ADD_TAG) | Added $(project) successfully"

REMOVE_TAG := "remove"
remove:
ifndef project
	$(error Path not specified. Run: make add project=[project])
endif
	@# If the project does not exist in the local scope
	@if ! yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(REMOVE_TAG) | Error: $(project) does not exist at the local level"; \
		exit 1; \
	fi

	@read -p "$(TAG) | $(REMOVE_TAG) | Do you want to delete the $(project) folder? (y/n) " yn; \
	if [ "$$yn" = "n" ] || [ "$$yn" = "N" ]; then \
		echo "$(TAG) | $(REMOVE_TAG) | Take care of files before attempting to remove again"; \
		exit 3; \
	fi

	@yq e -i 'del($(PROJECT_KEY)[] | select(. == "$(project)"))' $(LOCAL_PROJECTS)
	@rm -rf $(project)
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(REMOVE_TAG) | Removed $(project) successfully"

list_local_projects:
	@yq e "." $(LOCAL_PROJECTS)

list_global_projects:
	@yq e "." $(GLOBAL_PROJECTS)
