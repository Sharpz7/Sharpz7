## Things to get started on a new Server

TODO: IMPROVE THIS!!!!!!!!!!!!!!!!!!!!

## SSH User Creation

> \$ adduser adam

> \$ apt install sudo

> \$ reboot now

> \$ visudo

Add This line:

`adam   ALL=(ALL:ALL) ALL`

> \$ su adam

> \$ mkdir ~/.ssh

> \$ touch ~/.ssh/authorized_keys

Add your key here

> \$ chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys


## Other Useful commands

> \$ passwd

> \$ sudo nano /etc/ssh/sshd_config

> \$ sudo systemctl restart ssh


## Use ufw to manage firewall

Install ufw

> \$ sudo apt install ufw

> \$ sudo ufw allow 22/tcp
> \$ sudo ufw allow http
> \$ sudo ufw allow https


## Other Useful Links

   - [2FA in Terminals](https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04)



