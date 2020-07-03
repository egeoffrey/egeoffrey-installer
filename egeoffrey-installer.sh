#!/bin/bash

VERSION="1.0"
REVISION="8"
EGEOFFREY_CLI_URL="https://raw.githubusercontent.com/egeoffrey/egeoffrey-cli/master/egeoffrey-cli"
DEFAULT_BRANCH="master"
LOG_FILE="/tmp/egeoffrey-installer.log"
APT_GET_UPDATE_DONE=""

# print out an error message and exit
error() {
    echo 
    echo -e "\033[91mERROR\033[0m: $1"
    echo "Installer logs saved in $LOG_FILE"
    exit 1
}

# run a command and log
run() {
    COMMAND=$1
    echo "" >> $LOG_FILE
    echo ">> "$COMMAND >> $LOG_FILE
    eval $COMMAND >>$LOG_FILE 2>&1
}

# install an OS package if not already installed
install_os() {
    FILENAME=$1
    PACKAGE=$2
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -ne "\033[33mnot found\033[0m..."
        echo -n "installing $PACKAGE..."
        # ensure we have a package manager, otherwise exit
        APT_GET=$(which apt-get)
        if [ -z $APT_GET ]; then
            error "apt-get not found, please install $PACKAGE manually and run this script again"
        fi
        # run apt-get update if not already done
        if [ -z $APT_GET_UPDATE_DONE ]; then
            run "apt-get update"
            APT_GET_UPDATE_DONE="Y"
        fi
        # install it
        run "apt-get install -y $PACKAGE"
    else
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful 
    OUTPUT=$(which $FILENAME)
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of $PACKAGE failed, please install it manually and run this script again"
    fi
    echo -e "\033[32mdone\033[0m"
}

# install a python module if not already installed
install_python() {
    MODULE_NAME=$1
    PACKAGE=$2
    echo -n "Checking for python module $MODULE_NAME..."
    OUTPUT=$(python -c "import $MODULE_NAME" 2>&1)
    # if the required dependency does not exist, install it
    if [ -n "$OUTPUT" ]; then
        echo -ne "\033[33mnot found\033[0m..."
        echo -n "installing $PACKAGE..."
        run "pip install $PACKAGE"
    else
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful 
    OUTPUT=$(python -c "import $MODULE_NAME" 2>&1)
    if [ -n "$OUTPUT" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of python module $MODULE_NAME failed, please install it manually and run this script again"
    fi
    echo -e "\033[32mdone\033[0m"
}

# check if a python module exists, if not install a os package
install_python_os() {
    MODULE_NAME=$1
    PACKAGE=$2
    echo -n "Checking for python module $MODULE_NAME..."
    OUTPUT=$(python -c "import $MODULE_NAME" 2>&1)
    # if the required dependency does not exist, install it
    if [ -n "$OUTPUT" ]; then
        echo -ne "\033[33mnot found\033[0m..."
        echo -n "Installing $PACKAGE..."
        # ensure we have a package manager, otherwise exit
        APT_GET=$(which apt-get)
        if [ -z $APT_GET ]; then
            error "apt-get not found, please install $PACKAGE manually and run this script again"
        fi
        # run apt-get update if not already done
        if [ -z $APT_GET_UPDATE_DONE ]; then
            run "apt-get update"
            APT_GET_UPDATE_DONE="Y"
        fi
        # install it
        run "apt-get install -y $PACKAGE"
    else
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful 
    OUTPUT=$(python -c "import $MODULE_NAME" 2>&1)
    if [ -n "$OUTPUT" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of python module $MODULE_NAME failed, please install it manually and run this script again"
    fi
    echo -e "\033[32mdone\033[0m"
}

# install docker if not already installed
install_docker() {
    FILENAME="docker"
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -ne "\033[33mnot found\033[0m..."
        echo -n "installing docker..."
        run "curl -sSL https://get.docker.com/ | sh"
    else
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful 
    OUTPUT=$(which $FILENAME)
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of Docker failed, please install it manually (https://docs.docker.com/install/) and run this script again"
    fi
    # start docker
    run "/etc/init.d/docker start"
    echo -e "\033[32mdone\033[0m"
}

# install docker-compose if not already installed
install_docker_compose() {
    FILENAME="docker-compose"
    FILE_PATH="/usr/local/bin/docker-compose"
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -ne "\033[33mnot found\033[0m..."
        echo -n "installing docker-compose..."
        # install docker-compose as a docker image
        run "curl -L --fail https://github.com/docker/compose/releases/download/1.24.0/run.sh -o $FILE_PATH"
        run "chmod +x $FILE_PATH"
        # for ARM architecture we need a different docker-compose image
        if [ $ARCHITECTURE = "arm32v6" ]; then
            run "sed -i 's/IMAGE=\"docker\/compose:\$VERSION\"/IMAGE=\"korbai\/docker-compose\"/' $FILE_PATH"
        fi
    else 
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful
    OUTPUT=$(which $FILENAME)
    OUTPUT_2=$(docker-compose version 2>/dev/null|grep 'docker-compose version')
    if [ -z "$OUTPUT" ] || [ -z "$OUTPUT_2" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of docker-compose failed, please install it manually (https://docs.docker.com/compose/install/) and run this script again"
    fi
    echo -e "\033[32mdone\033[0m"
}

# detect architecture
detect_architecture() {
    echo -n "Detecting CPU architecture..."
    ARCHITECTURE=""
    OUTPUT=$(uname -m)
    if [[ $OUTPUT == *"x86_64"* ]]; then
        ARCHITECTURE="amd64"
    fi
    if [[ $OUTPUT == *"arm"* ]]; then
        ARCHITECTURE="arm32v6"
    fi
    if [ -n "$ARCHITECTURE" ]; then
        echo -e "\033[32mok\033[0m ($ARCHITECTURE)"
    else
        error "Unable to determine system architecture ($OUTPUT)"
    fi
}

# install egeoffrey
install_egeoffrey() {
    CURRENT_DIR=$(pwd)
    echo "Where do you want to install eGeoffrey? An 'egeoffrey' subdirectory will be appended to your input [$CURRENT_DIR/egeoffrey]"
    read INPUT
    if [ -z "$INPUT" ]; then
        INSTALL_DIRECTORY=$CURRENT_DIR/egeoffrey
    else
        INSTALL_DIRECTORY=$INPUT/egeoffrey
    fi
    if [ ! -d "$INSTALL_DIRECTORY" ]; then
        mkdir -p $INSTALL_DIRECTORY
    fi
	echo "Running eGeoffrey setup..."
	egeoffrey-cli -d $INSTALL_DIRECTORY setup
}

# download egeoffrey-cli
install_egeoffrey_cli() {
    echo -n "Installing egeoffrey-cli utility..."
    FILE_PATH="/usr/local/bin/egeoffrey-cli"
    curl -ssL $EGEOFFREY_CLI_URL > $FILE_PATH 2>&1
    chmod +x $FILE_PATH
    if [ -f $FILE_PATH ]; then
        echo -e "\033[32mdone\033[0m"
    else
        echo -e "\033[91mfailed\033[0m"
        error "unable to install egeoffrey-cli"
    fi
}

# install egeoffrey base modules
install_egeoffrey_modules() {
    echo -n "Installing and starting eGeoffrey..."
    # install the packages
    run "egeoffrey-cli -d $INSTALL_DIRECTORY install egeoffrey-gateway:$DEFAULT_BRANCH egeoffrey-database:$DEFAULT_BRANCH egeoffrey-controller:$DEFAULT_BRANCH egeoffrey-gui:$DEFAULT_BRANCH && egeoffrey-cli -d $INSTALL_DIRECTORY start"
    if [ -f "$INSTALL_DIRECTORY/docker-compose.yml" ]; then
        echo -e "\033[32mdone\033[0m"
    else
        echo -e "\033[91mfailed\033[0m"
        error "unable to install eGeoffrey modules"
    fi
}

# main
echo -e "\033[4meGeoffrey Installer v$VERSION-$REVISION\033[24m"
echo
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root"
fi
# detect CPU architecture
detect_architecture
# install required OS dependencies (file to search - package to install if not found)
install_os python python
install_os pip python-pip
install_os ifconfig net-tools
install_os git git
install_os curl curl
# install other required OS dependencies (python module to import - package to install if not found)
install_python_os yaml python-yaml
# install required python dependencies (python module to import - python package to install if not found)
install_python requests requests
# install docker
install_docker
install_docker_compose
echo
# install egeoffrey-cli
install_egeoffrey_cli
# install egeoffrey
install_egeoffrey
# install base modules
install_egeoffrey_modules

# print out completed message
# TODO: show the main IP only
MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'|tail -1)
echo ""
echo -e "\033[32mCOMPLETED!\033[0m - eGeoffrey has been started, please wait a couple of minutes and then access the web interface on http://$MY_IP"
echo "Run 'egeoffrey-cli' to stop/restart eGeoffrey, search the marketplace and add additional packages to your installation."
echo "If you need to change any of the information provided during the setup, please run 'sudo egeoffrey-cli setup'"

