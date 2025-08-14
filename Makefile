# Make file for version-control-template

TAG := "Makefile"

LOCAL_PROJECTS := .local_projects.yaml
GLOBAL_PROJECTS := .global_projects.yaml
TEMPLATE := template

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
	@yq e -n '.projects = []' > $(LOCAL_PROJECTS)
	@git sparse-checkout set $$(yq e '.projects | .[]' $(LOCAL_PROJECTS))
	@touch .local_projects.yaml
	@echo "$(TAG) | $(INIT_TAG) | repo init successfully"

ADD_TAG := "add"
add:
ifndef project
	$(error Path not specified. Run: make add project=[project])
endif
	# If the folder already exists in the global scope
	@if yq e ".projects[] | select(. == '$(project)')" $(GLOBAL_PROJECTS) > /dev/null; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) already exists"; \
		exit 1; \
	fi

	# If the project already exists in the local scope
	# This should never happen because it should be caught at the global level
	@if yq e ".projects[] | select(. == '$(project)')" $(LOCAL_PROJECTS) > /dev/null; then \
		echo "$(TAG) | $(ADD_TAG) | Error: $(project) already exists at the local level. Something very bad happened here"; \
		exit 2; \
	fi

	
	# Add the project
	@yq e -i ".projects += ['$(project)']" $(LOCAL_PROJECTS)

	@cp -r $(TEMPLATE) "$(project)"
	@git sparse-checkout set $$(yq e '.projects | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(ADD_TAG) | Added $(project) successfully"

REMOVE_TAG := "remove"
remove:
ifndef project
	$(error Path not specified. Run: make add project=[project])
endif
	# If the project does not exist in the local scope
	@if ! yq e ".projects[] | select(. == '$(project)')" $(LOCAL_PROJECTS) > /dev/null; then \
		echo "$(TAG) | $(REMOVE_TAG) | Error: $(project) does not exist in the list of local projects"; \
		exit 1; \
	fi

	@yq e -i "del(.projects[] | select(. == '$(project)'))" $(LOCAL_PROJECTS)
	@git sparse-checkout set $$(yq e '.projects | .[]' $(LOCAL_PROJECTS))
	@echo "$(TAG) | $(REMOVE_TAG) | Removed $(project) successfully"

local_projects:
	@yq e "." $(LOCAL_PROJECTS)

global_projects:
	@yq e "." $(GLOBAL_PROJECTS)
