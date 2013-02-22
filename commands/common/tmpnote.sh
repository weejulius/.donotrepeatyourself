tmpnote(){
    month_str=`date +"%m-%y"`
    day_str=`date +"%d %T"`
    cd ~
    user=`pwd`
    file=$user"/notes/"$month_str"-tmp.md"
    echo "making temporal note in " $month_str
    echo "saving to " $file
    echo "* "$day_str >> $file
    echo $@ >> $file

}

tmpnote $@
