REPO_URL="https://github.com/sparksbenjamin/kali-scripts.git"
DIR_NAME="$HOME/kali-scripts"
ALIASES_FILE="aliases.zsh"
ZSHRC_FILE="$HOME/.zshrc"


## Install / update software
echo "[!] Installing / Updating Software"
echo "SecLists (https://github.com/danielmiessler/SecLists)"
sudo apt install seclists
echo "Getting Wordlists"
cd /usr/share/wordlists
sudo mkdir assetnote
cd assetnote
sudo wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off
cd ~
echo "subfinder nuculei naabu"
sudo apt install subfinder nuclei naabu
echo "Installing waymore"
sudo pipx waymore
echo "Installing python3.11"
cd /tmp
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
tar -xf Python-3.11.9.tgz
cd Python-3.11.9
./configure --enable-optimizations --prefix=/opt/python3.11
make -j$(nproc)
sudo make altinstall
cd ~
echo "Setting up openconnect-sso"
/opt/python3.11/bin/python3.11 -m venv ~/vpn_env311
sudo apt install libxml2-dev libxslt-dev python3-dev build-essential zlib1g-dev libxslt1-dev gcc
source vpn_env311/bin/activate
pip install "openconnect-sso[full]"
echo "Installing Brave"
curl -fsS https://dl.brave.com/install.sh | sh
echo "Installing VSCode"
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install code
# Check if the directory exists
if [ -d "$DIR_NAME" ]; then
    echo "Directory $DIR_NAME exists. Updating the repository."
    cd $DIR_NAME
    git pull
    cd ..
else
    echo "Directory $DIR_NAME does not exist. Cloning the repository."
    git clone $REPO_URL $DIR_NAME
fi

# Check if the aliases file exists in the repository
if [ -f "$DIR_NAME/$ALIASES_FILE" ]; then
    echo "Found $ALIASES_FILE in the repository."

    # Check if .zshrc already sources this aliases file
    if ! grep -q "source $DIR_NAME/$ALIASES_FILE" $ZSHRC_FILE; then
        echo "Sourcing $ALIASES_FILE in .zshrc."
        echo "source $DIR_NAME/$ALIASES_FILE" >> $ZSHRC_FILE
    else
        echo "$ALIASES_FILE is already sourced in .zshrc."
    fi

    # Apply the changes immediately
    #source "$ZSHRC_FILE"
    source "~/.zshrc"
else
    echo "$ALIASES_FILE not found in the repository."
fi
