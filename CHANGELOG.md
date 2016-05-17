## 1.3.1

Changed:

- closes project detail popup when clicking an action
- redirects to project page after successful project edit save
- Improved online check to try 3 times before actually setting offline state

Fixed:

- project cloning/installation and removing not finishing when custom.json does not exist
- removing and reinstalling a running project shows wrong state in project listing
- not showing configured design after clone when there was already a customization with that id
- redundancy in apps frontend stream initialization

## 1.3

Added:

- projects can now be cloned
- installed projects can be partially edited
- loading animations for async actions
- minimal height for the browser window

Changed:

- installing through a project url now creates a local registry entry
- replaced vagrant backup with logic that repairs the broken vagrant
- removed Express Server Layer, so now native electron
- replaced most vagrant shell calls with a more durable solution
- improved Eintopf start time
- design

Fixed:

- issue when starting multiple Eintopf instances
- incorrect vagrant ssh config values
- issues when having projects with the same dir name but different upper case letters


## 1.2.2 (08.03.2016)

Changed:

- upgrade eintopf proxy to version 1.0.2

## 1.2.1 (10.02.2016)

Fixed:

- shuffling of project list order
- incorrect path building with EINTOPF_HOME env
- eintopf proxy not installing after building new vm
- fixed exception when docker container had no name entry

## 1.2.0 (28.01.2016)

Added:

- end to end tests

Fixed:

- error handling on proxy installation
- unnecessary proxy installation error messages on startup

Changed:

- updated README
- fetching docker containers info to lessen cpu load
- replaced watchjs with kefir-storage
- increased eintopf proxy version to use increased proxy timeout
- renamed steps in setup view

## 1.1.1 (07.12.2015)

Fixed:

- registry exception on startup

## 1.1.0 (27.11.2015)

Added:

- container list in project detail view
- running apps in project detail view
- Eintopf version info in application menu
- password input on vagrant up for unix/macos
- additional private registry listing

Fixed: 

- multiple change event emits on watchermodel.set when watchermodel.get was used beforehand
- project state update in frontend

Changed:
 
- improved vagrant backup functionality
- project ids to match name in docker-compose
- improved eintopf proxy monitoring
- updated README

## 1.0.2 (15.10.2015)

Added: 

- update project detail view on changes

Fixed:

- switch to log view after actions were triggered
- url for project resources should not directly use the project id
- observe the VM and renew the .vagrant backup on changes
- exception when vboxmanage is not available

Changed:

- monitoring of vagrant ssh config only on startup
- view design
- updated docker-compose version to 1.4.2 in vagrant default file
- default projects definition

## 1.0.1 (06.10.2015)

Fixed:
 
- startup without default folder

Changed:

- removed unnecessary async helper function in tests 

## 1.0.0 (05.10.2015)

Added:
 
- proxy deploying/monitoring through Eintopf
- reload project configurations in an interval
- maintainers list in package.json

Fixed:
 
- proxy should redirect to configured SSL port
- occasional 'Cannot get /' Error on startup
- creating a project which already exists deletes the existing project
- missing DOCKER_HOST env for project scripts
- only show SSL URLs when registered in proxy
- project looses running states after reloading projects

Changed:
 
- configuration abstraction
- project certs synchronisation

## 0.1.4 (pre-release - 28.09.2015)

Fixed:
 
- copy/paste in electron browser
- nodejs should not be a requirement to do project actions

Changed:

- running start/stop and custom actions of projects
- improved release building
- updated README

## 0.1.3 (pre-release - 18.09.2015)

Fixed:
 
- incorrect container order
- wrong app renaming while building
- missing property check before accessing the object in list.coffee

Changed:
 
- improved release building
- fetching docker containers info
- updated README

## 0.1.2 (pre-release - 16.09.2015)