#!/bin/zsh
emulate -L zsh

TRAPZERR(){print error;exit 1}

cd $0:h

print -l 'Content-Type: text/plain' ''

# TODO security
clientSHA=$(</dev/stdin)
if [[ ! $clientSHA =~ ^sha1=[[:alnum:]]{40}$ ]]; then
  exit 1
fi
clientSHA=${clientSHA[6,46]}

clearsign(){ print -l -- $* | /usr/bin/gpg2 --batch --homedir /home/http/gpg.insec --default-key 4A5A5597 --clearsign }
sha1(){ print -n -- ${"$(/usr/bin/sha1sum)"[1,40]} }

zmodload -F zsh/files b:mkdir
zmodload zsh/mapfile

if [[ $1 == notarize ]]; then
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

  print -- $stamp
elif [[ $1 == verify ]]; then
  # TODO verify based on timestamp hash
  for s in ${(f)mapfile[client/${clientSHA[1,2]}/${clientSHA[3,40]}]};
    print -- "$(<stamp/${s[1,2]}/${s[3,40]})"
fi
