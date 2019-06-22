#!/bin/bash

VERSION="1.0"
DEFAULT_MYHOUSE_VERSION="development"
MYHOUSE_CLI_URL="https://github.com/myhouse-project/myhouse-cli/blob/development/myhouse-cli"

# print out an error message and exit
error() {
    echo 
    echo -e "\033[91mERROR\033[0m: $1"
    exit 1
}

# install an OS package if not already installed
install_os() {
    FILENAME=$1
    PACKAGE=$2
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mnot found\033[0m"
        echo -n "Installing required package $PACKAGE..."
        # ensure we have a package manager, otherwise exit
        APT_GET=$(which apt-get)
        if [ -z $APT_GET ]; then
            error "apt-get not found, please install $PACKAGE manually and run this script again"
        fi
        # install it
        apt-get install $PACKAGE >/dev/null 2>&1
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
    echo -e "\033[92mdone\033[0m"
}

# install docker if not already installed
install_docker() {
    FILENAME="docker"
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mnot found\033[0m"
        echo -n "Installing docker..."
        curl -sSL https://get.docker.com/ | sh >/dev/null 2>&1
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
    echo -e "\033[92mdone\033[0m"
}

# install docker-compose if not already installed
install_docker_compose() {
    FILENAME="docker-compose"
    echo -n "Checking for $FILENAME..."
    OUTPUT=$(which $FILENAME)
    # if the required dependency does not exist, install it
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mnot found\033[0m"
        echo -n "Installing docker-compose..."
        curl -L https://github.com/docker/compose/releases/download/1.25.0-rc1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose >/dev/null 2>&1
        chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
    else 
        echo -e "\033[32mok\033[0m"
        return
    fi
    # ensure the installation was successful 
    OUTPUT=$(which $FILENAME)
    if [ -z "$OUTPUT" ]; then
        echo -e "\033[91mfailed\033[0m"
        error "Installation of docker-compose failed, please install it manually (https://docs.docker.com/compose/install/) and run this script again"
    fi
    echo -e "\033[92mdone\033[0m"
}

# install a python module if not already installed
install_python() {
    MODULE_NAME=$1
    PACKAGE=$2
    echo -n "Checking for python module $MODULE_NAME..."
    OUTPUT=$(python -c "import $MODULE_NAME" 2>&1)
    # if the required dependency does not exist, install it
    if [ -n "$OUTPUT" ]; then
        echo -e "\033[91mnot found\033[0m"
        echo -n "Installing required python module $PACKAGE..."
        pip install $PACKAGE >/dev/null 2>&1
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
    echo -e "\033[92mdone\033[0m"
}

# detect timezone
detect_timezone() {
    echo -n "Detecting timezone..."
    OUTPUT=$(readlink /etc/localtime|sed -E 's/^.+zoneinfo\///' 2>&1)
    if [ -n "$OUTPUT" ]; then
        TIMEZONE=$OUTPUT
        echo -e "\033[32mok\033[0m ($TIMEZONE)"
    else
        TIMEZONE="Europe/Paris"
        echo -e "\033[33mfailed, using defeault $TIMEZONE\033[0m"
    fi
}

# detect architecture
detect_architecture() {
    echo -n "Detecting CPU architecture..."
    ARCHITECTURE=""
    case $(uname -m) in
        x86_64) ARCHITECTURE="amd64" ;;
        arm)    ARCHITECTURE="arm32v6" ;;
    esac
    if [ -n "$ARCHITECTURE" ]; then
        echo -e "\033[32mok\033[0m ($ARCHITECTURE)"
    else
        error "Unable to determine system architecture ($OUTPUT)"
    fi
}

# ask for installation directory
ask_install_directory() {
    CURRENT_DIR=$(pwd)
    echo "Where do you want to install myHouse? [$CURRENT_DIR]"
    read INPUT
    if [ -z "$INPUT" ]; then
        INSTALL_DIRECTORY=$CURRENT_DIR
    else
        if [ ! -d "$INPUT" ]; then
            mkdir -p $INPUT
        fi
        INSTALL_DIRECTORY=$INPUT
    fi
}

# ask for myhouse version
ask_version() {
    echo "Which version of myHouse you want to bind to? [$DEFAULT_MYHOUSE_VERSION]"
    read INPUT
    if [ -z "$INPUT" ]; then
        MYHOUSE_VERSION=$DEFAULT_MYHOUSE_VERSION
    else
        MYHOUSE_VERSION=$INPUT
    fi
}

# setup the myhouse docker environment
install_myhouse_docker() {
    echo -n "Setting up myHouse docker environment into $INSTALL_DIRECTORY..."
    cat > $INSTALL_DIRECTORY/.env <<EOF
VERSION=$MYHOUSE_VERSION
ARCHITECTURE=$ARCHITECTURE
TZ=$TIMEZONE
MYHOUSE_GATEWAY_HOSTNAME=myhouse-gateway
#MYHOUSE_GATEWAY_PORT=443
#MYHOUSE_ID=default_house
#MYHOUSE_PASSCODE=
PYTHONUNBUFFERED=1
EOF
    echo -e "\033[32mdone\033[0m"
}

# download myhouse-cli
install_myhouse_cli() {
    echo -n "Installing myhouse-cli utility..."
    if [ -f $INSTALL_DIRECTORY/myhouse-cli ]; then
        echo -e "\033[33mskipping, file already exists\033[0m"
    else
        curl -ssL $MYHOUSE_CLI_URL > $INSTALL_DIRECTORY/myhouse-cli 2>&1
        chmod 755 $INSTALL_DIRECTORY/myhouse-cli
        echo -e "\033[92mdone\033[0m"
    fi
}

# install myhouse base modules
install_myhouse_modules() {
    echo -n "Installing myHouse modules..."
    myhouse-cli install myhouse-gateway myhouse-db myhouse-controller myhouse-gui >/dev/null 2>&1
    if grep -q myhouse-gateway $INSTALL_DIRECTORY/docker-compose.yml; then
        echo -e "\033[92mdone\033[0m"
    else
        echo -e "\033[91mfailed\033[0m"
        error "unable to install myHouse modules"
    fi
}

# main
echo -e "\033[4mmyHouse Installer v$VERSION\033[24m"
echo
# install required OS dependencies
install_os python python
install_os pip python-pip
# install required python dependencies
install_python requests requests
install_python yaml pyyaml
# install docker
install_docker
install_docker_compose
# detect timezone
detect_timezone
# detect CPU architecture
detect_architecture
echo
# ask where to install
ask_install_directory
# ask for version to bind
ask_version
# create docker files
install_myhouse_docker
# install myhouse-cli
install_myhouse_cli
# install base modules
install_myhouse_modules

echo -e "\033[33mUsing default environment settings for local installation, if connecting to a remote instance or if provided with House ID and Passcode, please edit $INSTALL_DIRECTORY/.env\033[0m"


