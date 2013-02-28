#switch the current work copy to specific branch
#usage:
#svnswitch $branchname $project

olps_url=http://svn.alibaba-inc.com/repos/ali_china/olps
is=industry_shared
iw=industry_web
ic=industry_center

projects=~/projects
is_local=$projects/industry_shared_20120106
ic_local=$projects/industry_center_20120106
iw_local=$projects/industryweb

branch=$1
project=$2

merge_branch()
{
    if [ ! -d "$1" ]
    then
        svn checkout "$olps_url/$2/branches/$branch" $svn_copy
    else
        echo $1
        cd $1
        svn revert -R .
        svn switch "$olps_url/$2/branches/$branch"
    fi
}

merge_branch $is_local $is
merge_branch $ic_local $ic
merge_branch $iw_local $iw
