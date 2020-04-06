#Created by kenhuang on 2019-06-06.
#!/usr/bin/env bash
#此脚本的$PWD为运行Build_Clover.command时的路径
set -e
function Clover_correctSource(){

   local dxeServicesLibPath="$DIR_MAIN/edk2/MdePkg/Library/DxeResetSystemLib"
   local patchPath="$DIR_MAIN/edk2/Clover/Patches_for_EDK2/MdePkg/Library/DxeServicesLib"
   local themesDestinationPath="$DIR_MAIN/edk2/Clover/CloverPackage/CloverV2/themespkg"
   local theme themes=(Asus HP Dell thinkpad Universe SilverLight Lightness)
   #删除主题并下载主题,主题名称不能带有空格，编译器不识别
   rm -rf "$themesDestinationPath/"{BGM,cesium,christmas,newyear}
   for theme in ${themes[@]} ; do
       if [ ! -d "$themesDestinationPath/$theme" ]; then
           echo "Downloading $theme into $themesDestinationPath/$theme..."
           git archive --remote=git://git.code.sf.net/p/cloverefiboot/themes HEAD themes/"$theme" | \
              tar -x -C "/tmp"
           mv  "/tmp/themes/$theme" "$themesDestinationPath"
       fi
   done

   if [ ! -e "$DIR_MAIN/edk2/Clover/CloverPackage/sym/CloverCD/EFI/CLOVER/config.plist" ]; then
       mkdir -pv "$DIR_MAIN/edk2/Clover/CloverPackage/sym/CloverCD/EFI/CLOVER"
       cp -f $CONFIG_DIR/config.plist  \
       "$DIR_MAIN/edk2/Clover/CloverPackage/sym/CloverCD/EFI/CLOVER/config.plist"
   fi
   cp -f $CONFIG_DIR/target.txt "$DIR_MAIN/edk2/Conf"
   #解决gTianoCustomDecompressGuid未找到
   cp -f $CONFIG_DIR/MdeModulePkg.dec "$DIR_MAIN/edk2/MdeModulePkg"
   if [ ! -d "/tmp/Build_Clover/src/edk2/NetworkPkg" ]; then
        svn update "/tmp/Build_Clover/src/edk2/NetworkPkg"
   fi
   local efiDestinationPath="$DIR_MAIN/edk2/Clover/CloverPackage/CloverV2/EFI/CLOVER/drivers/off/UEFI" \
     APTIOFIX_ZIP=AptioFix-R27-RELEASE
   if [ ! -e "/tmp/$APTIOFIX_ZIP" ]; then
        curl -L "https://github.com/acidanthera/AptioFixPkg/releases/download/R27/$APTIOFIX_ZIP.zip" \
   -o "/tmp/$APTIOFIX_ZIP.zip"
        unzip -o "/tmp/$APTIOFIX_ZIP.zip" -d "/tmp/$APTIOFIX_ZIP"
   fi
   mkdir -pv $efiDestinationPath/{MemoryFix,FileSystem}
   cp -f "/tmp/$APTIOFIX_ZIP"/Drivers/{AptioInputFix.efi,AptioMemoryFix.efi} "$efiDestinationPath"/MemoryFix
   cp -f "$CONFIG_DIR/HFSPlus.efi" "$efiDestinationPath"/FileSystem
}
Clover_correctSource

#   if [ ! -e "$patchPath/DxeServicesLib.inf" ]; then
#        mkdir -pv "$dxeServicesLibPath"
#        curl -L 'https://www.kgp-hackintosh-corner.com/wp-content/uploads/2018/09/DxeServicesLib.inf_.zip' \
#        -o "$dxeServicesLibPath/DxeServicesLib.inf_.zip"
#        unzip -o "$dxeServicesLibPath/DxeServicesLib.inf_.zip" -d "$dxeServicesLibPath"
#        mkdir -p "$patchPath"
#        cat "$dxeServicesLibPath"/DxeServicesLib.inf | sed -e 's/^.*HobLib/#  HobLib/'  > "$patchPath/DxeServicesLib.inf"
#   fi
#function Clover_downloadThirdParty() {
#忽略AptioFixPkg和AppleSupportPkg的编译错误,使用AppleSupportPkg和OpenCorePkg.Clover已经自带
#    if [ ! -d /tmp/Build_Clover/src/edk2/AptioFixPkg ]; then
#        cp -r src/usb/AptioFixPkg /tmp/Build_Clover/src/edk2
#    fi
#    for package in AppleSupportPkg EfiPkg OcSupportPkg; do
#        if [ ! -d "/tmp/Build_Clover/src/edk2/$package" ]; then
#            git clone "https://github.com/acidanthera/$package.git" "/tmp/Build_Clover/src/edk2/$package"
#        fi
#    done
#}
#Clover_downloadThirdParty







