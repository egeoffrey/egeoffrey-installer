#!/bin/bash

VERSION="1.0"
REVISION="3"
EGEOFFREY_CLI_URL="https://raw.githubusercontent.com/egeoffrey/egeoffrey-cli/development/egeoffrey-cli"
DEFAULT_BRANCH="development"
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

# detect timezone
detect_timezone() {
    echo -n "Detecting system timezone..."
    OUTPUT=$(cat /etc/timezone 2>/dev/null)
    if [ -n "$OUTPUT" ]; then
        TIMEZONE=$OUTPUT
        echo -e "\033[32mok\033[0m ($TIMEZONE)"
    else
        TIMEZONE="Europe/Paris"
        echo -e "\033[33mfailed, using default $TIMEZONE\033[0m"
    fi
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

# ask for installation directory
ask_install_directory() {
    CURRENT_DIR=$(pwd)
    echo "Where do you want to install eGeoffrey? [$CURRENT_DIR/egeoffrey]"
    read INPUT
    if [ -z "$INPUT" ]; then
        INSTALL_DIRECTORY=$CURRENT_DIR/egeoffrey
    else
        if [ ! -d "$INPUT/egeoffrey" ]; then
            mkdir -p $INPUT/egeoffrey
        fi
        INSTALL_DIRECTORY=$INPUT/egeoffrey
    fi
}

# ask for egeoffrey settings
ask_egeoffrey_settings() {
    # gateway hostname
    echo "What is the hostname of your eGeoffrey Gateway? [egeoffrey-gateway]"
    read INPUT
    if [ -z "$INPUT" ]; then
        EGEOFFREY_GATEWAY_HOSTNAME="egeoffrey-gateway"
    else
        EGEOFFREY_GATEWAY_HOSTNAME=$INPUT
    fi
    # gateway port
    echo "On which port the eGeoffrey Gateway is listening to? [443]"
    read INPUT
    if [ -z "$INPUT" ]; then
        EGEOFFREY_GATEWAY_PORT="443"
    else
        EGEOFFREY_GATEWAY_PORT=$INPUT
    fi
    # house id
    echo "What is your House ID? [default_house]"
    read INPUT
    if [ -z "$INPUT" ]; then
        EGEOFFREY_ID="default_house"
    else
        EGEOFFREY_ID=$INPUT
    fi
    # house passcode
    echo "What is your House Passcode? []"
    read INPUT
    if [ -z "$INPUT" ]; then
        EGEOFFREY_PASSCODE=""
    else
        EGEOFFREY_PASSCODE=$INPUT
    fi
    echo -n "Saving eGeoffrey settings in $INSTALL_DIRECTORY/.env..."
    cat > $INSTALL_DIRECTORY/.env <<EOF
ARCHITECTURE=$ARCHITECTURE
TZ=$TIMEZONE
EGEOFFREY_GATEWAY_HOSTNAME=$EGEOFFREY_GATEWAY_HOSTNAME
EGEOFFREY_GATEWAY_PORT=$EGEOFFREY_GATEWAY_PORT
EGEOFFREY_ID=$EGEOFFREY_ID
EGEOFFREY_PASSCODE=$EGEOFFREY_PASSCODE
PYTHONUNBUFFERED=1
EOF
    echo -e "\033[32mdone\033[0m"
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
    run "egeoffrey-cli -d $INSTALL_DIRECTORY install egeoffrey-gateway:$DEFAULT_BRANCH egeoffrey-database:$DEFAULT_BRANCH egeoffrey-controller:$DEFAULT_BRANCH egeoffrey-controller-config:$DEFAULT_BRANCH egeoffrey-gui:$DEFAULT_BRANCH && egeoffrey-cli -d $INSTALL_DIRECTORY start"
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
# detect timezone
detect_timezone
# detect CPU architecture
detect_architecture
# install required OS dependencies (file to search - package to install if not found)
install_os python python
install_os pip python-pip
install_os ifconfig net-tools
install_os git git
# install other required OS dependencies (python module to import - package to install if not found)
install_python_os yaml python-yaml
# install required python dependencies (python module to import - python package to install if not found)
install_python requests requests
# install docker
install_docker
install_docker_compose
echo
# ask where to install
ask_install_directory
# ask egeoffrey settings
ask_egeoffrey_settings
# install egeoffrey-cli
install_egeoffrey_cli
# install base modules
install_egeoffrey_modules

# print out completed message
# TODO: show the main IP only
MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'|tail -1)
echo ""
echo -e "\033[32mCOMPLETED!\033[0m - eGeoffrey should be up and running now, you can access the web interface on http://$MY_IP"
echo "Run 'egeoffrey-cli' to search the marketplace and add additional packages to your installation."
echo "If connecting to a remote instance or provided with HouseID/Passcode, please edit $INSTALL_DIRECTORY/.env and run 'egeoffrey-cli reload'"
