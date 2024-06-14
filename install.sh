sudo apt get install SecLists
echo "Installing Aliases"
wget "https://raw.githubusercontent.com/sparksbenjamin/kali-scripts/master/aliases.zsh" ~/kali_aliases.zsh
tee -a "source ~/kali_aliases.zsh" > ~/.zshrc

