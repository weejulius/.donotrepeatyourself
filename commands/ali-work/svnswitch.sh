#switch the current work copy to specific branch
#usage:
#svnswitch $branchname $project

merge_branch()
{
    lops_url=http://svn.alibaba-inc.com/repos/ali_china/olps
    
    if [ ! -d "$1" ]
    then
        svn checkout "$olps_url/$2/branches/$3" $1
    else
        echo $1
        cd $1
        svn revert -R .
        svn switch "$olps_url/$2/branches/$3"
    fi
}

switch_all(){
    is=industry_shared
    iw=industry_web
    ic=industry_center

    is_local=$INDUSTRY_SHARED
    ic_local=$INDUSTRY_CENTER
    iw_local=$INDUSTRY_WEB
    merge_branch $is_local $is $1
    merge_branch $ic_local $ic $1
    merge_branch $iw_local $iw $1
}
