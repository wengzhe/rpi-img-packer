# rpi-img-packer
树莓派镜像打包脚本（测试于2017-03-02版本）

## 基本步骤如下：
* 安装必要软件并清理apt-get
  * 同时删除`raspberrypi.img`和`raspberrypi.tar.gz`
* 计算所需空间并建立全0的`raspberrypi.img`
  * 同时建立fat32和ext4文件系统
* 复制文件
  * 开始前会有提示，如果前面的步骤出了问题，可以中止
  * 不包括`raspberrypi.img` `.cache` `/var/cache/*` `/media/*` `/run/*` `/sys/*` `/boot/*` `/proc/*` `/tmp/*` `/var/swap` `/var/lib/dhcpcd5/*` `/var/lib/dhcp/*`
  * 之后会建立一个空的`var/lib/dhcp/dhclient.leases`(会重置dhcp客户端状态，保证移植完之后会重新分配ip地址)
* umount这个文件(`raspberrypi.img`)
  * 开始前也会有提示，此时可以先对文件做出修改再继续
    * boot目录在`/media/B`
    * root文件系统在`/media/R`
    * 这时可以增加自动扩容脚本
  * 务必保证完全退出`/media`目录再继续，否则可能无法成功umount
* 打包成`raspberrypi.tar.gz`
  * 开始前也会有提示
  * 打包是为了减小传输时的体积，如果网络状况很好，或者不准备使用网络传输镜像，可以不打包

## 自动扩容方法
参考了原版镜像的扩容方法，但是需要稍作改动：
1. 在cmdline.txt末尾加上` quiet init=/usr/lib/raspi-config/init_resize.sh`
  * 这个文件在`/media/B`目录下
2. 在`/usr/lib/raspi-config/init_resize.sh`的`fix_partuuid()`函数的最后加上一行`resize2fs ${ROOT_DEV}p2`
  * 如果是修改镜像中的此脚本，则应该是`/media/R/usr/lib/raspi-config/init_resize.sh`
  * 可以在开始复制文件前直接修改本机的`init_resize.sh`，这样复制过去的就是修改好的脚本
    * 这个脚本只会用于第一次启动树莓派，所以可以放心修改

如果觉得自动扩容比较麻烦，也可以不做修改，在烧写后通过`raspi-config`来进行手动扩容。

## 注意事项
* 如果是在不同的系统版本上，第一次请务必逐行运行，以观察其效果是否正确，尽量保证不会出现不可逆的破坏。
