echo "Install SecLists (https://github.com/danielmiessler/SecLists)"
sudo apt install seclists 
REPO_URL="https://github.com/sparksbenjamin/kali-scripts.git"
DIR_NAME="kali-scripts"
if [ -d "$DIR_NAME" ]; then
    echo "Directory $DIR_NAME exists. Updating the repository."
    cd $DIR_NAME
    git pull
else
    echo "Directory $DIR_NAME does not exist. Cloning the repository."
    git clone $REPO_URL $DIR_NAME
fi
