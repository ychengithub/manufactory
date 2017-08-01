
基本硬件配置
============
1. SSD硬盘(SATA接口）：容量64G以上
2. HDD硬盘：(LSI raid card)，系统盘容量500G(LVM分区）。其他还有两个LVM分区：用户区、审计区（存放日志）

系统设计原则
============
1. 方便生产：系统可以由OEM厂商一键安装，经过测试后直接发往客户
2. 系统容灾：向客户提供错误恢复功能，可以恢复至最近备份或出厂设置。
3. 启动迅速：日常启动从SSD启动，保证尽量快速
4. 使用简洁：grub启动选项尽量精简，避免错误进入。同时提供二次选项，避免用户错误选择无法恢复。 
5. 自动友好：提供系统自动备份，自动一致性检查，自动告警功能，减少用户介入
6. 误操作保护：对于Golden Image设为只读格式，避免误操作。同时提供USB紧急恢复盘，双重恢复机制。 

生产流程：
==========
1. 志翔（Zshield）向OEM厂商提供USB安装盘（或者镜像文件，由OEM厂商dd到USB盘）。 
2. OEM厂商从USB盘启动，一键完成系统初始化安装。
3. OEM厂商运行出厂测试程序，测试通过后，直接发货给客户

用户使用流程：
=============
1. 正常使用：用户从SSD硬盘启动，选择默认（第一个）grub选项，正常使用系统。
2. 系统备份：系统每日凌晨自动进行系统备份，用户也可手动执行系统备份命令。
3. 系统升级：用户上网下载升级包，按照用户指导手册，升级系统。系统升级命令会自动触发系统备份。
4. 系统恢复：
							a)当系统无法正常启动时，选择Grub选项的Golden Image恢复，按照提示框选择恢复至出厂设置/最近一次备份/退出恢复，完成恢复后系统自动重启。
							b)当系统运行时出现一致性检查告警，弹出提示框，可选择恢复至出厂设置/最近一次备份，恢复完成后，无须重启系统。
5. 系统紧急回复：向用户提供USB紧急回复盘（与USB安装盘相同），用于恶劣情况下的系统重新安装。 
					
snapshot 设计
================
1. 系统仅对lvm-root, 即根文件系统做snapshot，其他lvm不做snapshot和恢复。lvm-root可能使用SSD硬盘或者HDD硬盘，取决于SSD硬盘大小。
2. 系统对lvm-root，维护两个snapshot，snap0为出厂备份，完成安装后自动产生。snap1为最新备份，由系统每日凌晨备份。两个snapshot，均位于HDD硬盘上。 
3. 系统维护一个备份dameon， 每日凌晨自动对lvm-root进行snapshot， 即删除旧snap1，重新创建snap1。
4. 提供zshield_backup备份命令， 供用户在断电或其他事件前备份系统（过程与3相同）。
5. 系统升级命令会自动触发系统备份。

USB安装盘创建
===================
1. 通过标准CentOS 7 installer精简安装到USB，并创建根文件系统。
2. 拷贝ISP系统运行kernel image，initrd image和系统压缩根文件系统（包含至安盾）至USB根文件系统。
3. 在step 1里应该已经完成grub-install过程。如果没有，须手动执行grub-install --target=i386-pc --boot-directory=/boot /dev/sda完成USB盘上的grub安装。
4. 修改/etc/rc.d/rc.local, 添加zshield_manufactory.sh脚本执行。
5. USB安装盘完成

zshield_manufactory.sh脚本基本内容
===================
1. 初始化SSD硬盘，创建/dev/sda1和sda2区， 拷贝kernel image到sda1区，作为系统正常启动/boot区，sda2为Golden Image启动临时文件系统。
2. 在SSD上创建pv, vgs, lv-root
3. 挂载lv-root，解压系统根文件系统至lv-root。 
4. 更改lv-root下的/etc/fstab
5. 对SSD硬盘安装grub，从/boot启动，挂在lv-root文件系统
6. 更新grub, 添加Golden Image启动选项，正常情况下，依然从/boot区启动，但挂载临时文件系统。
7. 初始化/dev/sdb的HDD硬盘，创建其他lvm,并对lv-root产生snap0, snap1
8. 安装完成。

Golden Image启动和回复过程
===================
1. 用户从SSD硬盘启动，选择Golden Image启动（第二个）grub选项
2. 正常情况下，依然从/boot区启动，但挂载临时文件系统。
3. 执行python脚本弹出对话框，供客户选择恢复至出厂设置/最近一次备份/退出恢复。对应操作如下：
	 a)恢复至出场设置：
				扫描/dev/sdb硬盘内的vgs和lv
				将snap0进行merge到lv-root
				重启系统
	 b)恢复至最近一次备份 
				扫描/dev/sdb硬盘内的vgs和lv
				将snap1进行merge到lv-root
				重启系统
	 c)退出恢复：
	      重启系统			


zshield backup和自动备份dameon工作基本内容
===================
lvremove /dev/lvgroup/snap0
lvcreate -s -n snap0 -l 100G /dev/lvgroup/snap0


/boot 分区的考虑
================
由于snapshot无法覆盖/boot分区的备份，考虑使用复制/boot分区，或者使用grub2的/boot容灾机制。


示意图
============

初始

| USB         | SSD 硬盘|  HDD 硬盘 |
|grub         |--:      |						|
|/boot        |  				|						|
|File System  | 				|						|


OEM厂商初始化安装（或者用户选择USB重新恢复）

| USB         | SSD 硬盘|  HDD 硬盘 |
|grub         | grub    |	 --:			|
|/boot        | /boot		|	lv-home		|
|File System  | /tmp_FS	|	lv-xxx		|
							| lv-root | snap0			|
												| snap1			|

出厂时产生snap0, 每日自动更新snap1对lv-root进行备份。系统出错后，可以选择从恢复出厂设置或者最近一次备份

恢复出厂设置或者最近一次备份

| USB         | SSD 硬盘						|  HDD 硬盘 |
|grub         | grub    						|	 --:			|
|/boot        | /boot								|	lv-home		|
|File System  | /tmp_FS							|	lv-xxx		|
							| lv-root+snap0/snap1 | snap0			|
																		| snap1			|


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
