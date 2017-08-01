
基本硬件配置
============
1. CompactFlash(SATA接口）：容量32G以上
2. 硬盘：(LSI raid card)，系统盘容量500G(LVM分区）。其他还有两个LVM分区：用户区、审计区（存放日志）

生产流程：
==========
1. 志翔（Zshield）向OEM厂商提供硬盘镜像文件（硬盘镜像文件，在原型系统完成后，通过"dd if=/dev/sdb of=CF_image.img"获得），由OEM厂商dd到CompactFlash。
2. OEM厂商从CompactFlash启动，自动完成系统初始化安装，并运行出厂测试程序
3. 测试通过后，直接发货给客户

用户使用流程：
=============
1. 正常情况下，用户从硬盘启动，正常使用系统
2. 系统每日凌晨自动进行系统备份。
3. 升级系统：用户上网下载升级包，按照用户指导手册，升级系统。在升级系统前，可以手动执行系统备份命令。
4. Rescue流程：因各种原因，当用户系统失败时，可以从CF卡启动Golden Image启动，恢复系统。
5. 系统恢复有两个选项，第一个恢复至出厂设置，第二个恢复最近一次备份。


snapshot 设计
================
1. 系统仅对lvm-root, 即根文件系统做snapshot，其他lvm不做snapshot和恢复。
2. 系统维护一个备份dameon， 每日凌晨自动对lvm-root进行snapshot， 即删除旧snap0，重新创建snap0。
3. 用户在升级系统前，可以手动执行zshield_backup备份命令，对系统进行备份（过程与2相同）。
4. 系统恢复选项，"Recover to last backup"对应从snap0恢复系统，恢复至最近一次备份。


Prototype系统的创建
===================
1. 通过标准CentOS 7 installer安装到CF卡Golden Image区。以32G CF卡为例，分区为Golden Image区和预留区（供将来使用），各16G。
2. 拷贝解压安装zshield至安盾至Golden Image区。
3. 在step 1里应该已经完成grub-install过程。如果没有，须手动执行grub-install --target=i386-pc --boot-directory=/boot /dev/sda完成CF卡上的grub安装。
4. 手动修改/etc/grub.cfg，添加root=/dev/sda1 ro内核参数，将系统启动时改为只读。
5. 继续修改grub.cfg, 复制一份启动menuentry ，分别添加“Recover to factory default"和“Recover to latest backup”描述，并分别加入zshield_recovery=default和zshield_recovery=latest内核参数.
5. 修改/etc/rc.d/rc.local, 添加zshield_recover.sh脚本执行。
6. Prototype系统创建完成

zshield_recover.sh脚本基本内容
===================
1. 如果zshield_recovery内核参数为空，返回。
2. 如果zshield_recovery为default, 完成以下初始化工作：
			初始化硬盘，创建pv, vgs, lv-root等
			挂载lv-root
			通过rsync备份golden image到lv-root
			更改lv-root下的/etc/fstab
			对硬盘安装grub
			更新grub
3. 如果zshield_recovery为恢复上次备份, 完成以下工作：
			扫描/dev/sdb硬盘内的vgs和lv
			将snap0进行merge到lv-root
			
具体内容如下：
if [-z $zshield_recovery]; then 
	exit
fi

if [ $zshield_recovery == default]; then
    fdisk /dev/sdb
    pvcreate /dev/sdb1		
    vgcreate vgroup /dev/sdb1
    lvcreate -L 100G -n vgroup lv-root
    mkfs.ext4 /dev/vgroup/lv-root
    mkdir /mnt/lv-root
    mount /dev/vgroup/lv-root/ /mnt/lv-root
    rsync -avHX / /mnt/lv-root/ --exclude '/mnt'  --exclude '/proc' --exclude '/dev' --exclude '/tmp'

		[Change fstab on target system with new UUID or LABEL, /mnt/lv-root/etc/fstab]

		mount --bind /proc /mnt/lv-root/proc
		mount --bind /sys /mnt/lv-root/sys
		mount --bind /dev /mnt/lv-root/dev
		mount --bind /run /mnt/lv-root/run
		mount --bind /boot /mnt/lv-root/boot
		chroot /mnt/lv-root

    grub-install --target=i386-pc --boot-directory=/boot /dev/sdb
		[update-grub]

elif [$zshield_recovery == latest]; then
		vgscan
		lvscan
    lvconvert --merge /dev/vgroup/snap0
fi

zshield backup和自动备份dameon工作基本内容
===================
lvremove /dev/lvgroup/snap0
lvcreate -s -n snap0 -l 100G /dev/lvgroup/snap0


示意图
============

初始

| CF         | 硬盘|
|grub        |--:|
|/boot Golden| |
|Golden      | |


OEM厂商初始化安装（或者用户选择回复出场设置）

| CF         | 硬盘         |
|grub        | grub:        |
|/boot Golden| /boot        |
|Golden      | lv-root      |
|            | snap0        |
|            |              |


每日自动更新snap0对lv-root进行备份。系统出错后，可以选择从snap0恢复最近一次备份。


| CF         | 硬盘                        |
|grub        |grub:                        |
|/boot Golden| /boot system                |
|Golden      | lv-root + merge snap0       |


LVM snapshot 介绍
================
[LVM snapshot 工作机制](https://www.clevernetsystems.com/lvm-snapshots-explained/)

这里主要搞清楚 lv0, lv0-real, snap1, snap1-cow 之间的关系。
结合我们这个例子简单的映射关系：
lv0 就是 Gloden Image，在 CF 卡上。 
snap1 就是硬盘上的可以使用的 root 分区。


1. 如果不涉及写到 lv0 的话，lv0 和 lv0-real 是一回事。读 lv0 会从 lv0-real 来读
2. 读 snap1 就是透过 snap1-cow 来读 lv0-real。如果不写的话，读 snap1 就是读
   lv0-real。这个时候 snap1-cow 是空文件。
3. 写 snap1 就是写 snap1-cow, 被写过的块就在 cow 文件创立。下次读 snap1 这个块就读到
  cow 这个写过的块而不用管 lv0-real。
4. 比较复杂的是写 lv0.这个时候要看 cow 文件有没有覆盖这个写的块。
  如果没有就要复制到 cow 文件。
