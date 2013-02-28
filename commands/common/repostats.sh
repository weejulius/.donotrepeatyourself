# get status of repositories

repostatus(){
    if [ -d "$1" ];
    then
        cd $1
        git status
    fi
    }

repostatus ~/.emacs.d
repostatus ~/repositories/clojure-play
repostatus ~/repositories/.donotrepeatyourself
repostatus ~/repositories/learning
repostatus ~/repositories/workroad
repostatus ~/workroad
repostatus ~/clojure
