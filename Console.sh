#Created by kenhuang on 2018/9/15.
#!/usr/bin/env bash
set -e
function Git_cloneRepositories(){
    local repository projectName item
    if [ ! -e "$2" ]; then
        mkdir -pv "$2"
    fi
    for item in $1; do
        repository=${item##*::}
        projectName=${item%%::*}
        if [ ! -e "$2/$projectName" ]; then
            git clone "$repository" "$2/$projectName"
        fi
    done
}
#$1 文件夹或者文件
function import() {
    local tempPath
    export SHELL_LIB_PATH=$(cd `dirname $BASH_SOURCE`;pwd)
    for item in ${@} ; do
        if [[ $item =~ ^/.* ]]; then
            #绝对路径
            tempPath=$item
        else
            tempPath=$SHELL_LIB_PATH/$item
        fi
        if [ -f "$tempPath" ]; then
            source "$tempPath"
        else
            for file in `ls "$tempPath"`; do
                import "$tempPath/$file"
            done
        fi
    done
}
function Console_createUniversalUSB(){
    import lib/Hackintosh.sh
    import lib/UniversalUSB.sh
    local usbNumber=3
    UniversalUSB_make "" \
    "/Volumes/Backup/Application/Install macOS Catalina.app" \
    "/Volumes/Work/doc/软件/WinPEgood.iso" "v2.5k_r5093" ""
#    UniversalUSB_testWithQemu "$usbNumber" "/Volumes/Spare/macos.img"
}
if ! `hash git 2> /dev/null`; then
    echo Please install Xcode first!
    exit 1
fi
Console_createUniversalUSB




