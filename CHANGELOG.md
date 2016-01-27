
[Added] end to end tests

[Fixed] error handling on proxy installation
[Fixed] shuffling of project list order
[Fixed] unnecessary proxy installation error messages on startup

[Changed] updated README
[Changed] fetching docker containers info to lessen cpu load
[Changed] replaced watchjs with kefir-storage
[Changed] increased eintopf proxy version to use increased proxy timeout

## 1.1.1

[Fixed] registry exception on startup

## 1.1.0

[Added] container list in project detail view
[Added] running apps in project detail view
[Added] Eintopf version info in application menu
[Added] password input on vagrant up for unix/macos
[Added] additional private registry listing

[Fixed] multiple change event emits on watchermodel.set when watchermodel.get was used beforehand
[Fixed] project state update in frontend

[Changed] improved vagrant backup functionality
[Changed] project ids to match name in docker-compose
[Changed] improved eintopf proxy monitoring
[Changed] updated README

## 1.0.2

[Added] update project detail view on changes

[Fixed] switch to log view after actions were triggered
[Fixed] url for project resources should not directly use the project id
[Fixed] observe the VM and renew the .vagrant backup on changes
[Fixed] exception when vboxmanage is not available

[Changed] monitoring of vagrant ssh config only on startup
[Changed] view design
[Changed] updated docker-compose version to 1.4.2 in vagrant default file
[Changed] default projects definition

## 1.0.1

[Fixed] startup without default folder

[Changed] removed unnecessary async helper function in tests 

## 1.0.0

[Added] proxy deploying/monitoring through Eintopf
[Added] reload project configurations in an interval
[Added] maintainers list in package.json

[Fixed] proxy should redirect to configured SSL port
[Fixed] occasional 'Cannot get /' Error on startup
[Fixed] creating a project which already exists deletes the existing project
[Fixed] missing DOCKER_HOST env for project scripts
[Fixed] only show SSL URLs when registered in proxy
[Fixed] project looses running states after reloading projects

[Changed] configuration abstraction
[Changed] project certs synchronisation

## 0.1.4 (pre-release)

[Fixed] copy/paste in electron browser
[Fixed] nodejs should not be a requirement to do project actions

[Changed] running start/stop and custom actions of projects
[Changed] improved release building
[Changed] updated README

## 0.1.3 (pre-release)

[Fixed] incorrect container order
[Fixed] wrong app renaming while building
[Fixed] missing property check before accessing the object in list.coffee

[Changed] improved release building
[Changed] fetching docker containers info
[Changed] updated README

## 0.1.2 (pre-release)