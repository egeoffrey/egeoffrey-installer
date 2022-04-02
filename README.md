# eGeoffrey Installer

Takes care of installing all the required dependencies, eGeoffrey's main components to run them all.

## Usage

To install eGeoffrey, simply download and install the `egeoffrey-installer.sh` file (ensure it is executable first). You need root privileges to have all the dependencies correctly installed.

The installer can also be run with the following a one-line command:

```
sudo bash -c "$(curl -ssL https://get.egeoffrey.com)"
```

Please ensure to point out to the correct branch.

## How it works

Once executed, the installed will:

- Collect basic system information such as the current timezone and the CPU architecture
- Install (through apt-get) operating system dependencies (python, pip, ifconfig, git)
- Install Python dependencies (yaml, requests)
- Install Docker and docker-compose
- Ask the user for an eGeoffrey installation directory so to create an empty docker-compose.yml file
- Ask the user if running a local instance or if the brand new installation needs to connect to a cloud instance. If the latter is selected, hostname, port, house id and passcode are requested
- Install the egeoffrey-cli
- Install eGeoffrey's core packages such as the gateway, the database, the controller and the gui

If any of the dependencies is already satisfied, the associated step is skept. 
Installer's logs are saved in `/tmp/egeoffrey-installer.log`. If the installer fails for any reason, feel free to run it again (if e.g. dependencies cannot be installed automatically, fix the problem and run the installer again).

Once the installation completes you will be able to access eGeoffrey web interface by pointing your browser to the host where eGeoffrey has been installed, port 80.

Just click on the login button to get in!



