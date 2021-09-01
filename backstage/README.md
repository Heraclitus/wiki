# Things to look into
- Exposing kubernetes things to Developers 		https://backstage.io/docs/features/kubernetes/overview
- Extending types 								https://backstage.io/docs/features/software-catalog/extending-the-model#adding-a-new-type-of-an-existing-kind	
- Backstage API  								curl https://backstage.corp.companyx.com/api/catalog/entities?filter=kind=API | jq .
- Auth security 								https://github.com/backstage/backstage/blob/master/contrib/docs/tutorials/authenticate-api-requests.md

# Background 
- Entity Schema         https://backstage.io/docs/features/software-catalog/descriptor-format
- Configuration 		https://backstage.io/docs/conf/writing
- example catalog-info 	https://github.com/backstage/backstage/blob/master/catalog-info.yaml
- auth 					https://backstage.io/docs/auth/ & https://backstage.io/docs/tutorials/quickstart-app-auth
-| repo crawl			gitlab "integration" host, token, apiBaseURL allows periodic sweeps of repos 
-| warning				https://backstage.io/docs/auth/using-auth#identity---wip
- Writing Templates		https://backstage.io/docs/features/software-templates/writing-templates
-- Actions				https://backstage.corp.companyx.com/create/actions	

# Technical details 
Gitlab action https://github.com/backstage/backstage/blob/49574a8a3e7365a3c1474b787685d5956b1730cb/plugins/scaffolder-backend/src/scaffolder/actions/builtin/publish/gitlab.ts

## To use backstage what does Company X need in the installation?
Gitlab "integration" - https://backstage.io/docs/integrations/gitlab/locations
Gitlab "location" - https://backstage.io/docs/features/software-catalog/configuration#static-location-configuration
OPTIONAL: Gitlab auth https://backstage.io/docs/tutorials/quickstart-app-auth

# Idiosyncracies
1. Locations
 - can't ingest from branches (only master)
2. In definining API's and relationships
 - not a great way to automate the import, without parser help
 -- find . -type f -name "*.go" -exec grep 'api' {} \;

# Backstage, what can you do?
Add a "component" to the service catalog

0. Terminology https://backstage.io/docs/features/software-catalog/system-model
1. Get familiar with how backstage ingests components https://backstage.io/docs/features/software-catalog/descriptor-format
2. Register a pre-existing component https://git.companyx.com/astappenbeck/backstage/-/blob/master/catalog-info.yaml
3. Add an API to the catalog : https://backstage.io/docs/features/software-catalog/descriptor-format#kind-api
4. Execute a template 


# Template Scaffholding Structure
You see "Beginning step {step.name} - plugins/scaffolder-backend/src/scaffolder/tasks/TaskWorker.ts
- Handlebar compiler                - import * as handlebars from 'handlebars';
- Example                           - https://handlebarsjs.com/examples/builtin-helper-each-block.html

alfreds-back… │ 2021-04-20T16:21:48.388Z backstage info Created UrlReader predicateMux{readers=azure{host=dev.azure.com,authed=false},bitbucket{host=bitbucket.org,authed=false},github{host=github.com,authed=false},gitlab{host=git.companyx.com,authed=true},gitlab{host=gitlab.com,authed=false},fetch{} 
alfreds-back… │ Backend failed to start up, TypeError: Invalid type in config for key 'catalog.rules' in 'app-config.yaml', got object, wanted object-array
alfreds-back… │ [K8s EVENT: Pod alfreds-backstage-backend-8777758b9-lbs56 (ns: microservice-catalog)] Back-off restarting failed container

