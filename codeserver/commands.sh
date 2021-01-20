sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \

chown coder:coder ~/bin/ssh+
chmod u+x ~/bin/ssh+

sudo chmod 700 /home/coder/.ssh && sudo chmod 600 /home/coder/.ssh/contabo.ssh && sudo chmod 600 /home/coder/.ssh/github.ssh && \                                                                                1 ↵
sudo chmod 600 /home/coder/.ssh/config

echo 'export PATH=/home/coder/bin/:$PATH' >> .zshrc
sed -i -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="gnzh"/g' ~/.zshrc

git config --global user.name "Sharpz7"
git config --global user.email "adam@mcaq.me"