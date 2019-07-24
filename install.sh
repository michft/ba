#!/usr/bin/env bash

set -uex pipefail

if test ${1+defined}; then echo "User : $1."; 
else
  echo "No user defined"
  exit 1
fi

cat root.ba >> /root/.bash_aliases
cat user.ba >> /home/$1/.bash_aliases
cat term.config >> /home/$1/.config/terminator/config
cat term.desktop >> /home/$1/.local/share/applications/terminator.desktop
cat vimrc | tee -a /root/.vimrc >> /home/$1/.vimrc
cat .inputrc | tee /root/.inputrc >> /home/$1/.inputrc

if test git 2>/dev/null; then
    git config --global user.name "Michael Tomkins"
    echo "set User=Michael Tomkins run \# git config --global user.email EMAIL"
else
    echo "GIT not INSTALLED!! install git"
fi

chown $1:$1 /home/$1/.bash_aliases

if [ "0" -eq "$(grep -c aliases /etc/bash.bashrc)" ] ; then
  echo "" >> /etc/bash.bashrc
  echo "if [ -f ~/.bash_aliases ]; then" >> /etc/bash.bashrc
  echo "  . ~/.bash_aliases" >> /etc/bash.bashrc
  echo "fi" >> /etc/bash.bashrc
fi

exit 0
