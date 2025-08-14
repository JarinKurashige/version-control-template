# Make file for version-control-template

.PHONY: init create delete add remove list_local_projects list_global_projects

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

CREATE_TAG := "create"
create:
ifndef project
	$(error Path not specified. Run: make create project=[project])
endif
	@# Guard to ensure project does not exist in the global scope
	@if yq e '$(PROJECT_KEY)[]' $(GLOBAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(CREATE_TAG) | Error: $(project) exists at the global level"; \
		exit 1; \
	fi

	@# Guard to ensure project does not exist in the local scope
	@if yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(CREATE_TAG) | Error: $(project) exists at the local level"; \
		exit 1; \
	fi

	@# Add the project
	@yq e '$(PROJECT_KEY) += ["$(project)"]' -i $(LOCAL_PROJECTS)

	@cp -r $(TEMPLATE) "$(project)"
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(CREATE_TAG) | Created $(project) successfully. Make sure to commit your changes after you are done!"
	

DELETE_TAG := "delete"
delete:
ifndef project
	$(error Path not specified. Run: make delete project=[project])
endif
	@# Guard to ensure project does exist in the local scope
	@if ! yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(DELETE_TAG) | Error: $(project) does not exist at the local level"; \
		exit 1; \
	fi

	@# Guard to ensure user wants to actaully delete the project
	@read -p "$(TAG) | $(REMOVE_TAG) | Do you want to delete the $(project) folder? (y/n) " yn; \
	if [ "$$yn" = "n" ] || [ "$$yn" = "N" ]; then \
		echo "$(TAG) | $(REMOVE_TAG) | Take care of files before attempting to remove again"; \
		exit 3; \
	fi

	@yq e -i 'del($(PROJECT_KEY)[] | select(. == "$(project)"))' $(LOCAL_PROJECTS)
	@rm -rf $(project)
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(DELETE_TAG) | Deleted $(project) successfully"
	

ADD_TAG := "add"
add:
ifndef project
	$(error Path not specified. Run: make add project=[project])
endif
	@# Guard to ensure project exists in the global scope
	@if ! yq e '$(PROJECT_KEY)[]' $(GLOBAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) does not exist at the global level"; \
		exit 1; \
	fi

	@# Guard to ensure project does not exist in the local scope
	@if yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) already exists at the local level"; \
		exit 2; \
	fi
	
	@# Add the project
	@yq e '$(PROJECT_KEY) += ["$(project)"]' -i $(LOCAL_PROJECTS)

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

	@yq e -i 'del($(PROJECT_KEY)[] | select(. == "$(project)"))' $(LOCAL_PROJECTS)
	@git sparse-checkout set $$(yq e '$(TEMPLATE_KEY) + $(PROJECT_KEY) | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(REMOVE_TAG) | Removed $(project) successfully."

	@# If the project exists in the global scope
	@if yq e '$(PROJECT_KEY)[]' $(GLOBAL_PROJECTS) | grep -qx "$(project)"; then \
		echo "$(TAG) | $(REMOVE_TAG) | $(project) will no longer show up in your local projects"; \
	else \
		echo "$(TAG) | $(REMOVE_TAG) | $(project) still exists as an untracked folder."; \
		echo "$(TAG) | $(REMOVE_TAG) | If you want it deleted, next time run make delete project=[project]."; \
		echo "$(TAG) | $(REMOVE_TAG) | If you want to delete the actual folder now, delete it manually"; \
	fi

list_local_projects:
	@yq e '$(PROJECT_KEY)[]' $(LOCAL_PROJECTS)

list_global_projects:
	@yq e '$(PROJECT_KEY)[]' $(GLOBAL_PROJECTS)
