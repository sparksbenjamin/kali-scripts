REPO_URL="https://github.com/sparksbenjamin/kali-scripts.git"
DIR_NAME="$HOME/kali-scripts"
ALIASES_FILE="aliases.zsh"
ZSHRC_FILE="$HOME/.zshrc"


## Install / update software
echo "Installing / Updating Software"
echo "Complete Distro Update"
sudo sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y autoremove
echo "SecLists (https://github.com/danielmiessler/SecLists)"
sudo apt install seclists

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
