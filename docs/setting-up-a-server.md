Sharp - Things to get started on a new Server
============================================


SSH User Creation
============

> \$ adduser sharp

> \$ apt install sudo

> \$ reboot now

> \$ visudo

Add This line:

`sharp   ALL=(ALL:ALL) ALL`

> \$ su sharp

> \$ mkdir ~/.ssh

> \$ touch ~/.ssh/authorized_keys

Add your key here

> \$ chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys


Other Useful commands
============

> \$ passwd

> \$ sudo nano /etc/ssh/sshd_config

> \$ sudo systemctl restart ssh

Scripts
=============

Contains info on how to install docker and docker-compose


Other Useful Links
============

   - [2FA in Terminals](https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04)

