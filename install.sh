#!/bin/bash
# http://www.gnu.org/software/bash/manual/bash.html
# 1. ln all the commands to $home/bin


ln_commands(){
    
  for f in $(find commands/ali-work  -name "*.sh" -type f); do
      chmod u+x $f
      echo $f
      source $f
  done
  source init.sh
}

#ln_commands
source init.sh
