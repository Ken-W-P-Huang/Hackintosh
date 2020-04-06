#Created by kenhuang on 2019-05-10.
#!/usr/bin/env bash
if [ -z "$HACKINTOSH_SH" ];then
    HACKINTOSH_SH=true
########################################################################################################################
#MacOS Linux不需要定义
readonly SEDS=\"\"
#https://github.com/tianocore/tianocore.github.io/wiki/Xcode
#查看Xcode对应LLVM版本https://en.wikipedia.org/wiki/Xcode#Latest_versions
#clang -v提供的信息无用，Apple LLVM version 10.0.1对应7.0.0
#$1 cctools版本
#$2 LLVM版本
#$3 MTOC存放路径
#$4 编译临时文件夹
function Hackintosh_installMTOC(){
    local cctoolsVersion=${1-"895"} \
    llvmVersion=${2-"4.0.0"} \
    mtocPath=${3-"/usr/local/bin/"} \
    tempPath=${4-"/tmp"}
    local cctools="cctools-"$cctoolsVersion \
    llvm="llvm-$llvmVersion.src"
    cd "$tempPath"
    if [ ! -f "/tmp/$cctools.tar.gz" ]; then
        curl -L "https://opensource.apple.com/tarballs/cctools/$cctools".tar.gz -o "$cctools.tar.gz"
    fi
    if [ ! -f "/tmp/$llvm.tar.xz" ]; then
        curl -L "http://releases.llvm.org/$llvmVersion/$llvm".tar.xz -o "$llvm.tar.xz"
    fi
    tar -xf "$cctools.tar.gz"
    tar -xf "$llvm.tar.xz"
    cp "$cctools"/include/llvm-c/Disassembler.h .
    cp -R "$llvm"/include/llvm "$cctools/include"
    cp -R "$llvm"/include/llvm-c "$cctools/include"
    mv Disassembler.h "$cctools/include/llvm-c"
    make  -C "./$cctools"
    make  -C "./$cctools/efitools"
#    sudo cp "./$cctools/efitools/mtoc.NEW" "$mtocPath"
    cd -
}
#UEFI支持
#linux windows https://blog.csdn.net/jiangwei0512/article/details/52244440
#http://blog.sina.com.cn/s/blog_8ea8e9d50102wj5q.html
function Hackintosh_installOVMF(){
    Hackintosh_installMTOC
    git clone https://github.com/tianocore/edk2.git
    cd edk2
    git submodule update --init --recursive
    OvmfPkg/build.sh -a X64
    sudo cp /Users/kenhuang/Downloads/Hackintosh/edk2/Build/OvmfX64/DEBUG_XCODE5/FV/OVMF.fd /usr/local/share/
}
#$1 clover源码路径
function Hackintosh_compileClover(){
    #Clover文件夹首字母必须大写
   local CLOVER_DIR_PATH=${1:-"/tmp/Build_Clover"}
   local dxeServicesLibPath="$CLOVER_DIR_PATH/src/edk2/MdePkg/Library/DxeResetSystemLib"
   local patchPath="$CLOVER_DIR_PATH/src/edk2/Clover/Patches_for_EDK2/MdePkg/Library/DxeServicesLib"
   if [ ! -e "$CLOVER_DIR_PATH/Build_Clover.command" ]; then
       rm -rf "$CLOVER_DIR_PATH"
       git clone https://github.com/Micky1979/Build_Clover.git "$CLOVER_DIR_PATH"
   fi
   local findString="eval \"\${MY_SCRIPT}\" || printHeader \"You should export MY_SCRIPT with the path to your script\.\.\" && CleanExit;;"
   local upateString="eval \"\${MY_SCRIPT}\" || printHeader \"You should export MY_SCRIPT with the path to your script\.\.\";;"
   sed -i $SEDS "s/$findString/$upateString/g" "$CLOVER_DIR_PATH/Build_Clover.command"
   if ! eval "$CLOVER_DIR_PATH/Build_Clover.command --cfg $CONFIG_DIR/BuildCloverConfig.txt"; then
       echo "Failed to compile clover."
       exit 1
   fi
}
#$1 clover路径
#$2 驱动备份路径
#$3 DEVELOPMENT_TEAM,可不指定
function Hackintosh_compileKexts(){
    local kextsSourceDirPath="/tmp/kexts" CODE_SIGN_IDENTITY="Mac Developer: $3" \
     tmpkextsDirPath="/tmp/kexts/build" teamName=
    local projectName item buildDirPath codeSignIdentity=$CODE_SIGN_IDENTITY repositories=(
        #USB库在10.11有改动。不好修改源码，放弃
        #'BrcmPatchRAM::https://github.com/RehabMan/OS-X-BrcmPatchRAM.git'
        'ApplePS2Controller::https://github.com/RehabMan/ElanTouchpad-Driver.git'
        'Lilu::https://github.com/acidanthera/Lilu.git'
        'AppleBacklightFixup::https://github.com/RehabMan/AppleBacklightFixup.git'
        'WhateverGreen::https://github.com/acidanthera/WhateverGreen.git'
        'AppleALC::https://github.com/acidanthera/AppleALC.git'
        'HWSensors::https://github.com/RehabMan/OS-X-FakeSMC-kozlek.git'
        'USBInjectAll::https://github.com/RehabMan/OS-X-USB-Inject-All.git'
        'VoodooPS2Controller::https://github.com/RehabMan/OS-X-Voodoo-PS2-Controller.git'
        'RealtekRTL8111::https://github.com/RehabMan/OS-X-Realtek-Network.git'
        'FakePCIID::https://github.com/RehabMan/OS-X-Fake-PCI-ID.git'
        'ACPIBatteryManager::https://github.com/RehabMan/OS-X-ACPI-Battery-Driver'
        'Sinetek-rtsx::https://github.com/sinetek/Sinetek-rtsx'
        'AirportBrcmFixup::https://github.com/acidanthera/AirportBrcmFixup'
        'BT4LEContinuityFixup::https://github.com/acidanthera/BT4LEContinuityFixup'
        #https://voodooi2c.github.io/#Installation/Installation
        'VoodooI2C::https://github.com/alexandred/VoodooI2C'
        'VirtualSMC::https://github.com/acidanthera/VirtualSMC.git'
        'HibernationFixup::https://github.com/acidanthera/HibernationFixup.git'
        'VoodooPS2Controller::https://github.com/acidanthera/VoodooPS2.git'
    ) \
    target=-alltargets \
    BrcmPatchRAMPath="$kextsSourceDirPath/BrcmPatchRAM.zip" \
    SDK_VERSION=`xcodebuild -showsdks |grep "macOS.*-sdk"|awk '{print $4}'`
    #下载
    #Download error on https://pypi.python.org/simple/xxx/: [SSL: TLSV1_ALERT_PROTOCOL_VERSION] tlsv1
    # alert protocol version (_ssl.c:661) -- Some packages may not be found!
    # Couldn't find index page for 'pytest-runner' (maybe misspelled?)
    pip install pytest-runner -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
    for package in cpplint cldoc; do
        if [ ! -e /usr/local/bin/$package ]; then
            pip install $package -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
            ln -sf /Library/Frameworks/Python.framework/Versions/2.7/bin/$package /usr/local/bin
        fi
    done
    if [  -z $SDK_VERSION ]; then
        read -p 'Could not detect XCode SDK version, ple4ase enter one(e.g.macosx10.14):' SDK_VERSION
    fi
    Git_cloneRepositories "${repositories[*]}" "$kextsSourceDirPath"
    if [ ! -d "$tmpkextsDirPath" ]; then
        mkdir -p "$tmpkextsDirPath"
    fi
    if [ ! -f "$BrcmPatchRAMPath" ]; then
        #IOKit/usb/USB.h已经改版，无法编译
       curl -L https://github.com/acidanthera/BrcmPatchRAM/releases/download/2.5.1/BrcmPatchRAM-2.5.1-RELEASE.zip \
        -o  "$BrcmPatchRAMPath"
    fi
    #修正
    for code in statPhyAddr txPhyAddr rxPhyAddr statPhyAddr ; do
        sed -i $SEDS "s/$code = NULL;/$code  = 0;/g"\
        "$kextsSourceDirPath/RealtekRTL8111/RealtekRTL8111/RealtekRTL8111.cpp"
    done
    unzip -o "$BrcmPatchRAMPath" -d "$kextsSourceDirPath/BrcmPatchRAM"
    cp -rf "$kextsSourceDirPath/BrcmPatchRAM/Release/"*.kext "$tmpkextsDirPath"
    cp -f "$CONFIG_DIR/VoodooPS2synapticsPane.xib" \
    "$kextsSourceDirPath/VoodooPS2Controller/VoodooPS2synapticsPane/en.lproj"
    #OSBoolean *tmpBoolean = false; => OSBoolean *tmpBoolean = kOSBooleanFalse;
    sed -i $SEDS "s/OSBoolean \*tmpBoolean = false;/OSBoolean \*tmpBoolean = kOSBooleanFalse;/g" \
    "$kextsSourceDirPath/ApplePS2Controller/ApplePS2ElanTouchpad/ApplePS2ElanTouchpad.cpp"
    #编译
    xcodebuild build -project "$kextsSourceDirPath/HWSensors/Versioning And Distribution.xcodeproj" \
                     -target "Pre-Build" \
                     CODE_SIGNING_REQUIRED=NO
    for item in  ${repositories[*]}; do
        projectName=${item%%::*}
        if [ $projectName == 'VoodooPS2Controller' ] || [ $projectName == 'VirtualSMC' ]  \
        || [ $projectName == 'ApplePS2Controller' ]|| [ $projectName == 'Sinetek-rtsx' ]; then
            codeSignIdentity=
        else
            codeSignIdentity=
        fi
        if [ $projectName == 'RealtekRTL8111' ] ; then
            target='-target RealtekRTL8111-V2'
        else
            target=-alltargets
        fi
        buildDirPath="$kextsSourceDirPath/$projectName/build"
        if [ -d "$buildDirPath" ]; then
            rm -rf "$buildDirPath"
        fi
        if [ $projectName == 'VoodooI2C' ]; then
            if [ ! -e $kextsSourceDirPath/$projectName/Dependencies/VoodooGPIO/VoodooGPIO.xcodeproj ]; then
                rm -rf $kextsSourceDirPath/$projectName/Dependencies/VoodooGPIO
                git clone https://github.com/coolstar/VoodooGPIO.git $kextsSourceDirPath/$projectName/Dependencies/VoodooGPIO
            fi
            local satellitesDirPath="$kextsSourceDirPath/$projectName/VoodooI2C Satellites"
            if [ ! -e "$satellitesDirPath/VoodooI2CFTE/VoodooI2CFTE.xcodeproj" ]; then
                rm -rf "$satellitesDirPath"/*
                cd "$satellitesDirPath"
                for satellite in "https://github.com/kprinssu/VoodooI2CELAN.git" \
                "https://github.com/prizraksarvar/VoodooI2CFTE.git" \
                "https://github.com/alexandred/VoodooI2CHID.git" \
                "https://github.com/alexandred/VoodooI2CSynaptics.git" \
                "https://github.com/blankmac/VoodooI2CUPDDEngine.git"; do
                    git clone $satellite
                done
                cd -
            fi
            pip install cpplint cldoc
             xcodebuild build -arch x86_64 \
                -sdk "$SDK_VERSION" \
                -scheme $projectName \
                -workspace "$kextsSourceDirPath/$projectName/$projectName.xcworkspace" \
                -configuration Release \
                SYMROOT="$buildDirPath" \
                BUILD_DIR="$buildDirPath" \
                BUILD_ROOT="$buildDirPath" \
                OBJROOT="$buildDirPath/obj" \
                DEVELOPMENT_TEAM="$teamName" \
                MACOSX_DEPLOYMENT_TARGET=10.9 \
                CLANG_CXX_LIBRARY=libc++ \
                CODE_SIGN_IDENTITY="" \
                CODE_SIGNING_REQUIRED=NO
        else
            xcodebuild build -arch x86_64 \
                -sdk "$SDK_VERSION" \
                $target \
                -project "$kextsSourceDirPath/$projectName/$projectName.xcodeproj" \
                -configuration Release \
                SYMROOT="$buildDirPath" \
                BUILD_DIR="$buildDirPath" \
                BUILD_ROOT="$buildDirPath" \
                OBJROOT="$buildDirPath/obj" \
                DEVELOPMENT_TEAM="$teamName" \
                MACOSX_DEPLOYMENT_TARGET=10.9 \
                CLANG_CXX_LIBRARY=libc++ \
                CODE_SIGN_IDENTITY="" \
                CODE_SIGNING_REQUIRED=NO
            if [ $projectName == 'Lilu' ]; then
                xcodebuild build -arch x86_64 \
                    -sdk "$SDK_VERSION" \
                    -alltargets \
                    -project "$kextsSourceDirPath/$projectName/$projectName.xcodeproj" \
                    -configuration Debug \
                    SYMROOT="$buildDirPath" \
                    BUILD_DIR="$buildDirPath" \
                    BUILD_ROOT="$buildDirPath" \
                    OBJROOT="$buildDirPath/obj" \
                    DEVELOPMENT_TEAM="$teamName" \
                    MACOSX_DEPLOYMENT_TARGET=10.9 \
                    CLANG_CXX_LIBRARY=libc++ \
                    CODE_SIGN_IDENTITY="" \
                    CODE_SIGNING_REQUIRED=NO
                for kextName in "WhateverGreen" "AppleALC" "AppleBacklightFixup" "AirportBrcmFixup" "BT4LEContinuityFixup" ; do
                    ln -sf "$kextsSourceDirPath/Lilu/build/Debug/Lilu.kext" "$kextsSourceDirPath/$kextName"
                done
            fi
        fi
        cp -Rf "$buildDirPath/Release/"*.kext "$tmpkextsDirPath"
    done
    #删除无用/有冲突的驱动
    #when using WhateverGreen.kext, you will not need FakePCIID.kext + FakePCIID_Intel_HD_Graphics.kext.
    rm -rf "$tmpkextsDirPath"/{BrcmPatchRAM,BrcmNonPatchRAM,FakePCIID,FakePCIID_Intel_HD_Graphics,\
FakePCIID_AR9280_as_AR946x,FakePCIID_BCM57XX_as_BCM57765}.kext
    rm -rf "$1/kexts/"*
    mkdir -pv "$1/kexts/Other"
    cp -Rf $tmpkextsDirPath/{FakeSMC.kext,Lilu.kext,USBInjectAll.kext,VoodooPS2Controller.kext,WhateverGreen.kext} "$1/kexts/Other/"
    ls $1/OEM
    for oem in `ls $1/OEM` ; do
        if [ "$oem" == "SystemProductName" ]; then
            continue
        fi
        local path="$1/OEM/$oem/UEFI/kexts/Other/"
        mkdir -p "$path"
        cp -Rf "$tmpkextsDirPath"/{ACPIBatteryManager.kext,FakeSMC.kext,ACPISensors.kext,GPUSensors.kext,\
AirportBrcmFixup.kext,LPCSensors.kext,AppleALC.kext,Lilu.kext,AppleBacklightFixup.kext,RealtekRTL8111.kext,\
BT4LEContinuityFixup.kext,SMMSensors.kext,BrcmFirmwareData.kext,BrcmPatchRAM3.kext,USBInjectAll.kext,\
VoodooPS2Controller.kext,WhateverGreen.kext,VoodooI2C.kext,VoodooI2CELAN.kext,VoodooI2CFTE.kext,\
VoodooI2CHID.kext,VoodooI2CSynaptics.kext,VoodooI2CUPDDEngine.kext,GPUSensors.kext}  "$path"
    done
    mkdir -p "$2/kexts"
    cp -Rf "$tmpkextsDirPath"/*  "$2/kexts"
}

#$1 backupPath
#$2 选项
function Hackintosh_compileMaciASL(){
    #https://github.com/acidanthera/MaciASL.git
    local sourceDirPath="/tmp/MaciASL/" CODE_SIGN_IDENTITY="Mac Developer: $2" \
    tmpkextsDirPath="/tmp/kexts/build" teamName=${2:-"MacOS"} \
    SDK_VERSION=`xcodebuild -showsdks |grep "macOS.*-sdk"|awk '{print $4}'` \
    isal4Zip="/tmp/R04_05_19.zip" option=${2:-1}
    if [  -z $SDK_VERSION ]; then
        read -p 'Could not detect XCode SDK version, please enter one(e.g.macosx10.14):' SDK_VERSION
    fi

    if [ ! -e /tmp/iasl.git ]; then
        git clone https://github.com/RehabMan/Intel-iasl.git /tmp/iasl.git
    fi
    make -C /tmp/iasl.git
    if [ ! -e "$isal4Zip" ]; then
        curl -L  https://github.com/acpica/acpica/archive/R04_05_19.zip -o "$isal4Zip"
        unzip -o "$isal4Zip" -d "/tmp"
    fi
    make -C /tmp/acpica-R04_05_19
    if [ ! -e /tmp/MaciASL ]; then
        git clone https://github.com/RehabMan/OS-X-MaciASL-patchmatic /tmp/MaciASL
    fi
    cp /tmp/acpica-R04_05_19/generate/unix/bin/iasl /tmp/MaciASL/iasl4
    cp /tmp/iasl.git/generate/unix/bin/iasl /tmp/MaciASL/iasl62
    xcodebuild build -arch x86_64 \
            -sdk "$SDK_VERSION" \
            -alltargets \
            -project "$sourceDirPath/MaciASL.xcodeproj" \
            -configuration Release \
            SYMROOT="$sourceDirPath/build" \
            BUILD_DIR="$sourceDirPath/build" \
            BUILD_ROOT="$sourceDirPath/build" \
            OBJROOT="$sourceDirPath/build/obj" \
            DEVELOPMENT_TEAM="$teamName" \
            MACOSX_DEPLOYMENT_TARGET=10.9 \
            CLANG_CXX_LIBRARY=libc++ \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO
    if [ $option -eq 1 -a ! -e /Applications/MaciASL.app ]; then
        sudo cp -Rf /tmp/MaciASL/build/Release/MaciASL.app /Applications
    fi
    cp -Rf /tmp/MaciASL/build/Release/MaciASL.app "$1"
}
#$1 backupPath
#$2 选项
function Hackintosh_buildApp() {
    local repositories=("Hackintool::https://github.com/headkaze/Hackintool"
    "IOJones::https://github.com/acidanthera/IOJones.git") appDirPath="/tmp/app" option=${2:-1}
    if [ ! -d "$appDirPath" ]; then
        mkdir -pv "$appDirPath"
    fi
    Git_cloneRepositories "${repositories[*]}" "$appDirPath"
    for item in  ${repositories[*]}; do
        projectName=${item%%::*}
        xcodebuild build -project "$appDirPath/$projectName/$projectName.xcodeproj" \
            -target "$projectName" \
            -UseModernBuildSystem=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY=""
        if [ $option -eq 1 -a  ! -e /Applications/$projectName.app ]; then
            sudo cp -Rf "$appDirPath/$projectName/build/Release/$projectName.app" /Applications
        fi
        cp -Rf "$appDirPath/$projectName/build/Release/$projectName.app" "$1"
    done
}

#$1 clover安装路径
#$2 clover版本
#$3 编译所需CodeSignIdentity,似乎可以忽略
#$4 结果保存路径
function Hackintosh_installClover(){
    local cloverVersion=${2:-v2.5k_r5058} installPath=${1:-"/Volumes/DEEPIN"} cloverSrcDirPath="/tmp/Build_Clover" \
          cloverSavePath=${4:-"/Volumes/DATA/hackintosh"}
    local outputDirPath="${cloverSrcDirPath}/src/edk2/Clover/CloverPackage" \
    pkgPath=${cloverSrcDirPath}/src/edk2/Clover/CloverPackage/sym/Clover*.pkg
    isoPath=${cloverSrcDirPath}/src/edk2/Clover/CloverPackage/sym/CloverISO-5093/Clover*.iso
    if [ ! -e $pkgPath ]; then
        Hackintosh_compileClover "${cloverSrcDirPath}"
    fi
    if [ ! -e "$cloverSavePath" ]; then
        mkdir -p "$cloverSavePath"
    fi
    cp $pkgPath "$cloverSavePath/"
    cp $isoPath "$cloverSavePath/"
    if [ ! -e "$installPath/EFI/CLOVER/CLOVERX64.efi" ]; then
        sudo installer -pkg $pkgPath -target "$installPath"
            #apfs.efi无法使用且不能在config.plist中禁止
        cp "$outputDirPath/sym/CloverCD/EFI/CLOVER/drivers/off"/* "$installPath/EFI/CLOVER/drivers/UEFI"
        #cp -f "$CONFIG_DIR/HFSPlus.efi" "$installPath/EFI/CLOVER/drivers/UEFI"
        #cp -Rf "$CONFIG_DIR/themes"/*  "$installPath/EFI/Clover/themes"
        cp -f "$CONFIG_DIR/config.plist" "$installPath/EFI/Clover/config.plist"
        cp -Rf "$CONFIG_DIR/OEM"/* "$installPath/EFI/CLOVER/OEM"
    fi
    #驱动
    Hackintosh_compileKexts "$installPath/EFI/Clover"  "$cloverSavePath"  "$3"
}


#$1 系统镜像路径
#$2 安装路径
function Hackintosh_installMacOS(){
    local appPath=${1:-`ls -d "/Applications/Install macOS "*.app|awk '{print $1}'`}
    local macosName=${appPath##*macOS }
    macosName=${macosName%%.app*}
    local installPath=${2:-"/Volumes/Apple"}
    if [ ! -d "$installPath" ]; then
         echo "$installPath does not exist."
         exit 1
    fi
    if [ ! -d "$appPath" ]; then
         echo "$appPath does not exist."
         exit 1
    fi
    sudo "$appPath"/Contents/Resources/createinstallmedia \
           --volume "$installPath" \
           --applicationpath "$appPath" \
           --nointeraction
}

function Hackintosh_disassembleAML() {
    iasl -dl -da DSDT.aml SSDT*.aml #iasl -dl DSDT.aml SSDT*.aml
}

########################################################################################################################
fi




