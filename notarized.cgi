#!/bin/zsh
emulate -L zsh

DB=$0:h
cd $DB

clearsign(){ print -l -- $* | /usr/bin/gpg2 --clearsign }
sha1(){ print -n -- ${"$(/usr/bin/sha1sum)"[1,40]} }

zmodload -F zsh/files b:mkdir
zmodload zsh/mapfile

# TODO security
clientSHA=$(</dev/stdin)
if [[ ! $clientSHA =~ ^sha1=[[:alnum:]]{40}$ ]]; then
  exit
fi
clientSHA=${clientSHA[6,46]}

time=$(/bin/date -Iseconds -u)

last_stamp=$mapfile[HEAD]
stamp=$(clearsign 'date '${time} 'data '${clientSHA} 'parent '${last_stamp})
stampSHA=$(print -n -- $stamp | sha1)

# TODO check for existence

mkdir -p stamp/${stampSHA[1,2]}
mapfile[stamp/${stampSHA[1,2]}/${stampSHA[3,40]}]=$stamp

mkdir -p client/${clientSHA[1,2]}
mapfile[client/${clientSHA[1,2]}/${clientSHA[3,40]}]+=${stampSHA}$'\n'

mapfile[HEAD]=$stampSHA

print -l 'Content-Type: text/plain' '' $stamp
