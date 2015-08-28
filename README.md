Eintopf
==============

A pot with the mixture of the smart development tools Docker, Vagrant and VirtualBox. Made to ease the chore of the
daily project works.

# Installation

Currently the project is in an very early state and under heavy development. There are release scripts for 
MacOS, Linux and Windows to build the native application.

Please use the Git clone way to participate.


## Prerequisites

* VirtualBox
* Vagrant >= 1.7
* Git
* (currently) NodeJS 


```
    git clone https://github.com/mazehall/eintopf.git
    cd eintopf
    npm install
    npm start
```


# How does it work?

## Paths under Eintopf controll

* ```$HOME/.eintopf/default``` mapped inBox to ```/vagrant```
  * The home of your Vagrantfile 
  
* ```$HOME/.eintopf/default/configs/*``` mapped inBox to ```/vagrant/configs```
  * The home of your project descriptions with all docker configurations 
  
* ```HOME/eintopf/*``` mapped inBox to ```/projects```
  * The home of your project sources

## Ports and Proxy

* __4480__  -> Proxy that provides all docker container with exposed port __80__ 
* __31313__  -> Eintopf http GUI




# Development

## Structure of the project

There are **two** `package.json` files:  

#### 1. For development
Sits on path: `eintopf/package.json`. Here you declare dependencies for your development environment and build scripts. **This file is not distributed with real application!**

Also here you declare the version of Electron runtime you want to use:
```json
"devDependencies": {
  "electron-prebuilt": "^0.24.0"
}
```

#### 2. For your application
Sits on path: `eintopf/app/package.json`. This is **real** manifest of your application. Declare your app dependencies here.

### Project's folders

- `app` - code of your application goes here.
- `config` - place for you to declare environment specific stuff.
- `releases` - ready for distribution installers will land here.
- `resources` - resources for particular operating system.
- `tasks` - build and development environment scripts.



## Installation

```
npm install
```
It will also download Electron runtime, and install dependencies for second `package.json` file inside `app` folder.


## Starting the app

```
npm start
```

#### Adding pure-js npm modules to your app

Remember to add your dependency to `app/package.json` file, so do:
```
cd app
npm install name_of_npm_module --save
```

#### Adding native npm modules to your app

If you want to install native module you need to compile it agains Electron, not Node.js you are firing in command line by typing `npm install` [(Read more)](https://github.com/atom/electron/blob/master/docs/tutorial/using-native-node-modules.md).
```
npm run app-install -- name_of_npm_module
```
Of course this method works also for pure-js modules, so you can use it all the time if you're able to remember such an ugly command.


# Making a release

**Note:** There are various icon and bitmap files in `resources` directory. Those are used in installers and are intended to be replaced by your own graphics.

To make ready for distribution installer use command:
```
npm run release
```
It will start the packaging process for operating system you are running this command on. Ready for distribution file will be outputted to `releases` directory.

You can create Windows installer only when running on Windows, the same is true for Linux and OSX. So to generate all three installers you need all three operating systems.


## Special precautions for Windows
As installer [NSIS](http://nsis.sourceforge.net/Main_Page) is used. You have to install it (version 3.0), and add NSIS folder to PATH in Environment Variables, so it is reachable to scripts in this project (path should look something like `C:/Program Files (x86)/NSIS`).


# License

The MIT License (MIT)

Copyright (c) 2015 Mazehall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
