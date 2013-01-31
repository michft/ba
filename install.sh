#!/bin/bash

if test ${1+defined}; then echo "User : $1."; 
else
  echo "No user defined"
  exit 0
fi

cp root.ba /root/.bash_aliases
cp user.ba /home/$1/.bash_aliases
chown $1 /home/$1/.bash_aliases
cat git_ps >> /root/.bash_aliases
cat git_ps >> /home/$1/.bash_aliases

echo "" >> /etc/bash.bashrc
echo "if [ -f ~/.bash_aliases ]; then" >> /etc/bash.bashrc
echo "    . ~/.bash_aliases" >> /etc/bash.bashrc
echo "fi" >> /etc/bash.bashrc

