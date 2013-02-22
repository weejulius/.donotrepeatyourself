# http://www.gnu.org/software/bash/manual/bash.html
# 1. ln all the commands to $home/bin


ln_commands(){
  for f in $(find commands  -type f); do
      chmod u+x $f
      echo ln "-f" $f ~"/bin/"`basename $f .sh`|sh
  done
  echo "source "`pwd`"/init.sh" >> ~/.bashrc
}

ln_commands
