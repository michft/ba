#!/usr/bin/env bash

if test ${1+defined}; then echo "User : $1."; 
else
  echo "No user defined"
  exit 0
fi

cat root.ba >> /root/.bash_aliases
cat user.ba >> /home/$1/.bash_aliases
cat vimrc | tee -a /root/.vimrc >> /home/$1/.vimrc

chown $1 /home/$1/.bash_aliases

if [ "0" -eq "$(grep -c aliases /etc/bash.bashrc)" ] ; then
  echo "" >> /etc/bash.bashrc
  echo "if [ -f ~/.bash_aliases ]; then" >> /etc/bash.bashrc
  echo "    . ~/.bash_aliases" >> /etc/bash.bashrc
  echo "fi" >> /etc/bash.bashrc
fi

