#Created by kenhuang on 2019-06-01.
#!/usr/bin/env bash
if [ -z "$UNIVERSAL_USB_SH" ];then
    UNIVERSAL_USB_SH=true
    import src/usb/Hackintosh.sh
########################################################################################################################
#编译clover时需要在选项界面选择4 "run my script on the source"
#备忘：
#1.不要将iso写到第一个分区，会按照MBR模式启动
#2.clover在mbr分区系统下并不会自动将EFI分区信息写入EFI分区，而是将文件写在Apple分区。
#3.mbr+UEFI兼容模式，貌似从头往后扫描启动分区。
#4.可以直接用clover加载deepin linux内核，或者使用其efi。但此时仍旧是UEFI，并没有转成legacy
#5.pe和deepin linux均有.efi可供启动
#6.UEFI并不在乎EFI分区的名称是否为EFI，而是查看分区是否含有/boot/BOOTx86.efi
#7.应该将iso写在第一个分区
#8.Gui->Custom Entries->Path 必须使用'\'进行路径分隔（'/'无效）。Linux 'Add Arguments'使用'/'
#9.memdisk只适用于mbr，不适用于UEFI
#10.window PE不能放在MBR逻辑卷中
#clover
#1 Mac进入安装界面后报安装盘不完整,可能需要使用USB2或者USB kext驱动没放置
#2 clover的OEM每个文件夹都必须放kext驱动。
#http://www.easy2boot.com/download/
#deepin live 免安装 https://bbs.deepin.org/forum.php?mod=viewthread&tid=166409
########################################################################################################################
#对bash做美化可能导致Build_Clover.command错误！ 报错"Error: unsupported MODE"
#http://dev.tonymacx86.com/threads/guide-using-clover-to-hotpatch-acpi.200137/
#xcode4 环境变量 https://www.cnblogs.com/shirley-1019/p/3823906.html
#https://www.jianshu.com/p/5f37dbf3a4d6
#https://kgp-hackintosh-corner.com/how-to-compile-clover-fakesmc-kext-and-hwsensor-kexts-lilu-kext-and-lilu-pugin-kexts-from-source-code-distributions-2
#https://developer.apple.com/library/archive/technotes/tn2339/_index.html
#https://help.apple.com/xcode/mac/current/#/dev745c5c974
#1.clover的驱动,kext驱动不能全放进去，根据教程来,或者在clover配置文件中禁用
#2.bios设置
#In order to boot the Clover from the USB, you should visit your BIOS settings:
#DVMT-prealloc至少64M
#- "VT-d" (virtualization for directed i/o) should be disabled if possible (the config.plist includes dart=0 in case you can't do this)
#- "DEP" (data execution prevention) should be enabled for OS X
#- "secure boot " should be disabled
#- "legacy boot" optional (recommend enabled, but boot UEFI if you have it)
#- "CSM" (compatibility support module) enabled or disabled (varies) (recommend enabled, but boot UEFI)
#- "fast boot" (if available) should be disabled.
#- "boot from USB" or "boot from external" enabled
#- SATA mode (if available) should be AHCI
#- TPM should be disabled
#Note: If you get a "garbled" screen when booting the installer in UEFI mode, enable legacy boot and/or CSM in BIOS
# (but still boot UEFI). Enabling legacy boot/CSM generally tends to clear that problem.
#3.clover再次安装驱动时，需要勾选已经安装的驱动，否则会被删除
#4.编译选项
# -sdk 这个选项似乎只能指定sdk版本不能指定路径。路径通过SDKROOT环境变量指定。
# xcodebuild -showBuildSettings可以看到相关选项
#GCC_VERSION="com.apple.compilers.llvm.clang.1_0"
#MACOSX_DEPLOYMENT_TARGET=10.7
#CXXFLAGS="-stdlib=libc++ -mmacosx-version-min=10.7" \
#LDFLAGS=-libc++ \
#CPPFLAGS="-stdlib=libc++" LIBS=-lc++ \
#XCODE_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
#XCODE_SDK_DIR=$XCODE_DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs
#sudo xcode-select -s  $XCODE_DEVELOPER_DIR
#5.You need one additional driver. HFSPlus.efi
#Do not forget ApfsDriverLoader-64 to install.
#Without HFSPlus, you won't be able to see any HFS+ volumes including your installation drive.
#It's recommended to use AptioMemoryFix-64. With the use of AptioMemoryFix-64, you don't need to use EmuVariableUefi-64.
#If you're having issues when booting, use OsxAptioFix2Drv-64 or OsxAptioFixDrv-64.
#Do not install AppleKeyFeeder-64 from Drivers UEFI.
# clover编译
# https://github.com/tianocore/edk2/blob/58e8a1d8044f7cac85e76f2cc62c68413f3e24b4/MdeModulePkg/MdeModulePkg.dec
#  ## GUID indicates the tiano custom compress/decompress algorithm.
#  #  Include/Guid/TianoDecompress.h
#  gTianoCustomDecompressGuid     = { 0xA31280AD, 0x481E, 0x41B6, { 0x95, 0xE8, 0x12, 0x7F, 0x4C, 0x98, 0x47, 0x79 }}
#-net nic,model=?
#          -vga std \
# -D SECURE_BOOT_ENABLE \
#  安装kvm GUI并模拟启动
########################################################################################################################
#$1 DEEPIN_ISO_PATH
#$2 MACOS_APP_PATH
#$3 WINDOW_ISO
#$5 clover版本
#$6 编译所需CodeSignIdentity
UniversalUSB_make(){
    local efiDirPath mountDisk mountPath result usbNo appMode
    export CONFIG_DIR=`dirname $BASH_SOURCE`/config
    #使用deepin-boot-maker不要选择格式化，否则会破坏U盘分区！！！！
    #根据建议为了兼容性，使用MBR模式,使用fdisk分区，以下命令WINPE会变成逻辑分区
    #http://man.openbsd.org/fdisk#COMMAND_MODE
    diskutil list
    chmod 744 $CONFIG_DIR/correct-source.sh
    read -p "Please enter the target usb disk number(eg input 3 for /dev/disk3):" usbNo
    if [ ! -e /dev/disk"$usbNo" ]; then
        echo "/dev/disk$usbNo doesn't exist."
        exit 1
    fi
    echo "Please enter the option of how to deal with apps:"
    echo "[1] backup and install"
    echo "[2] backup"
    echo "[3] none"
    while [ 0 -eq 0 ]; do
        read -p "[1]:" appMode
        if [ -z $appMode ]; then
            appMode=1
        fi
        if [ "$appMode" -ge 1 -a "$appMode" -le 3 ]; then
            break
        fi
    done

#    if [ ! -e /Volumes/DATA ] || [ ! -e /Volumes/APPLE ] || [ ! -e /Volumes/EFI ] || [ ! -e /Volumes/WINPE ]; then
#        diskutil partitionDisk /dev/disk"$usbNo" 3 MBR \
#            fat32 "DATA"  R \
#            HFS+J "Apple" 8.5g \
#            fat32 "DEEPIN" 0.905g
#        diskutil splitPartition /dev/disk"$usbNo"s3 \
#            fat32 "EFI" 300m \
#            fat32 "WINPE"  600m
#    fi
#    #复制grub文件夹
#    cp -r $CONFIG_DIR/boot "/Volumes/EFI"
#    #让clover可以支持legacy mode，boot文件夹提取自clover，不能和clover efi的/boot文件夹共存于同一分区，且只能放在mbr第一分区
#    cp -r $CONFIG_DIR/../boot  "/Volumes/DATA"
    efiDirPath=`df -h|grep /dev/disk"$usbNo"s3|awk '{print $9}'`
    if [ ! -e "$efiDirPath/EFI/CLOVER/kexts/Other" ] || [ "`ls $efiDirPath/EFI/CLOVER/kexts/Other`" == "" ]; then
        local backupDirPath="/Volumes/DATA/hackintosh"
        mkdir -p  $backupDirPath
        Hackintosh_installClover "$efiDirPath" "$4" "$5" "$backupDirPath"
    fi

#    if [ ! -e "/Volumes/WINPE/EFI" ] && [ ! -e "/Volumes/WINPE/sources" ] && [ -f "$3" ]; then
#        result=`hdiutil mount "$3"`
#        mountDisk=`echo $result|awk '{print $1}'`
#        mountPath=`echo $result|awk '{print $2}'`
#        sudo cp -a "$mountPath/" "/Volumes/WINPE"
#        hdiutil eject "$mountDisk"
#    else
#        echo "Skip to write $3 into USB as it's not a valid file."
#    fi
#    local winAutoDir=`dirname $BASH_SOURCE`/../../windows/PE/auto
#    if [ -e ${winAutoDir} ]; then
#        mkdir -pv /Volumes/DATA/iso
#        cp  -Rf ${winAutoDir} /Volumes/DATA/iso
#    fi
#    if [ $appMode -ne 3 ]; then
#        local backAppdir="/Volumes/DATA/hackintosh/app"
#        mkdir -pv $backAppdir
#        Hackintosh_compileMaciASL "$backAppdir" $appMode
#        Hackintosh_buildApp "$backAppdir" $appMode
#    fi
#
#    if [ -d "$2" ]; then
#        Hackintosh_installMacOS "$2"
#    else
#       echo /dev/"${usbNo}s3 isn't mounted."
#    fi
    echo "Succeed to make UniversalUSB!"
}

########################################################################################################################
#  测试
########################################################################################################################
UniversalUSB_enableVMwareTest(){
    #  VMware fusion 启用U盘启动
    #找出U盘分区号和序号
    diskutil list
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-rawdiskCreator create /dev/disk3 1 usb ide
    #将生成结果复制到虚拟机文件夹
    #添加.vmx配置
    #ide0:0.present = "TRUE"
    #ide0:0.fileName = "usb.vmdk"
    #ide0:0.deviceType = "rawDisk"
    #suspend.disabled = "TRUE"
}

#$1 usb编号
#$2 虚拟盘路径
UniversalUSB_testWithQemu(){
    local usbNo=${1:-"3"} imagePath=${2:-/Volumes/Virtual/macos.img}
    sudo diskutil unmountDisk  /dev/disk$usbNo
    if [ ! -f "$imagePath" ]; then
        qemu-img create -f qcow2 "$imagePath" 20G
    fi
    if [ -e "/dev/disk$usbNo" ]; then
        sudo qemu-system-x86_64 -m 2048  \
            -cpu Haswell \
            -bios /Volumes/Virtual/OVMF.fd \
            -hda /dev/disk$usbNo \
            -hdb "$imagePath" \
            -net nic,macaddr=52:54:00:12:34:22,model=rtl8139 \
            -boot order=c,order=d \
            -usbdevice keyboard \
            -usbdevice mouse \
            -D SECURE_BOOT_ENABLE
    else
        echo "/dev/disk$usbNo doesn't exist."
        exit 1
    fi
}

#UniversalUSB_enableQemuTest(){
#    brew tap jeffreywildman/homebrew-virt-manager
#    brew install virt-manager virt-viewer
#    #brew install lsusb
#    #lsusb
#    #system_profiler SPUSBDataType
#    #直接使用数值，前面不能有0
#    #qemu-system-x86_64 -m 512  -usb -device usb-host,hostbus=20,hostaddr=22
#    #更为直接的办法，将u盘直接作为硬盘启动
#
#}
fi
