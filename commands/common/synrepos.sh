# pull updates for repositories

synrepo(){
 echo "synchronizing $1"
 cd $1;
 git pull;
}

synrepo ~/.emacs.d
synrepo ~/repositories/clojure-play
synrepo ~/repositories/.donotrepeatyourself
synrepo ~/repositories/learning
synrepo ~/workroad
synrepo ~/repositories/raiseup
