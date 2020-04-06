# 功能
1. 将u盘划分为4个分区
Data   数据存放分区 
Apple/"Install macOS xxx"  MacOS系统安装分区
EFI clover启动器和Linux grub启动器
WINPE WinPE系统分区
由于脚本有分区代码，非专业人员请勿使用本脚本或者在虚拟机上使用本脚本，防止误将其他磁盘格式化。
之所以会如此分区，是因为win10某版本前的所有windows只能识别u盘的第一个分区。
2. 自动将指定的MacOS系统安装镜像写到Apple分区
3. 自动下载clover和MacOS驱动源代码，并编译安装在EFI分区
4. 自动将Linux grub启动器及其配置文件复制到EFI分区
5. 自动将指定的WinPE系统安装镜像写到WINPE分区

# 使用
此脚本只能在MacOS下使用，并安装XCode。如果没有Mac的，可以使用虚拟机（推荐）。使用前请备份u盘的数据。

修改Console.sh的以下代码，参数分别为linux镜像路径，macos安装应用路径，WinPE路径，clover版本（不同的macOS版本需要的clover的版本不同）
UniversalUSB_make "/Volumes/Work/Hackintosh/Result/iso/deepin-live-system-2.0-amd64.iso" \
    "/Volumes/Backup/Application/Install macOS Catalina.app" \
    "/Volumes/Work/复制/WinPE.iso" "v2.5k_r5093" ""
    
运行Console.sh。

运行期间需要选择u盘的盘符以及选择Build_Clover.sh脚本的选项编译Clover。

#如何安装系统
1. MacOS

    开机启动后进入clover，选择macOS进行安装

2. Linux

    将Linux系统的iso镜像放在Data/iso目录下，grub启动器会到此目录下扫描合适的Linux镜像。开机启动后进入clover，选择linux进入系统安装。
不需要将Linux镜像写入分区。
3. Windows

    将Windows系统的iso镜像放在Data/iso目录下，文件名必须以win开头，忽略大小写。
如果有自动安装AutoUnattend.xml，可以将AutoUnattend.xml放到Data/iso/auto目录下。非专业人员请勿使用，可能会将整块磁盘格式化！！！
开机启动后进入clover，选择WinPE进入系统，双击桌面上的InstallWindows.bat脚本进行安装。不需要将Windows镜像写入分区。