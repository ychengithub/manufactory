
基本硬件配置
============
1. SSD硬盘(SATA接口）：容量64G以上
2. HDD硬盘：(LSI raid card)，系统盘容量500G(LVM分区）。其他还有两个LVM分区：用户区、审计区（存放日志）
3. USB 安装盘，给 OEM 厂家启动以后自动完成安装到硬盘和 SSD。

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
            b)当系统运行时出现一致性检查告警，弹出提示框，可选择恢复至出厂设置/最近一次备份，恢复完成后，自动重启系统。
5. 系统紧急回复：向用户提供USB紧急回复盘（与USB安装盘相同），用于恶劣情况下的系统重新安装。 
					
snapshot 设计
================
1. 系统仅对lvm-root, 即根文件系统做snapshot和恢复，其他lvm不做snapshot和恢复。lvm-root大小100G，放在SSD硬盘上。
（XXX: We don't need 100G for root. 50G should be more than enough.)
2. 系统对lvm-root，维护两个snapshot，snap0为出厂备份，完成安装后自动产生。snap1为最新备份，由系统每日凌晨自动备份。snap0和snap1均位于HDD硬盘上。 
3. 系统维护一个备份dameon， 每日凌晨自动对lvm-root进行snapshot， 即删除旧snap1，重新创建snap1。
4. 提供zshield_backup备份命令， 供用户在断电或其他事件前备份系统（过程与3相同）。
5. 系统升级命令会自动触发系统备份。

USB安装盘创建
===================
1. 通过标准CentOS 7 installer精简安装到USB，并创建根文件系统。
2. 拷贝ISP系统运行kernel image，initrd image和系统压缩根文件系统（包含至安盾）至USB根文件系统。
3. 在step 1里应该已经完成grub-install过程。如果没有，须手动执行grub-install --target=i386-pc --boot-directory=/boot /dev/sda完成USB盘上的grub安装。
4. 修改/etc/rc.d/rc.local, 添加zshield_manufactory.py脚本执行。
5. USB安装盘完成

(XXX: This USB install disk did not need to use EXT3 etc. Using LiveCD like image with overlay
 is likely faster. Also with normal writable partition, after each boot up the root on USB
 is written. There is a chance to damage the system.)

zshield_manufactory.py功能介绍
===================
1. 图形化界面， 无需人工介入
(XXX: if no people attent, text interface is good enough ?)

2. 初始化SSD硬盘，创建/dev/sda1和sda2区， 拷贝kernel image到sda1区，作为系统正常启动/boot区，sda2为Golden Image启动临时文件系统。
3. 在SSD上创建pv, vgs, lv-root
4. 挂载lv-root，解压系统根文件系统至lv-root。 
5. 更改lv-root下的/etc/fstab
(XXX: consider kick starter?)

6. 对SSD硬盘安装grub，从/boot启动，挂在lv-root文件系统
7. 更新grub, 添加Golden Image启动选项，正常情况下，依然从/boot区启动，但挂载临时文件系统。
8. 初始化/dev/sdb的HDD硬盘，创建其他lvm,并对lv-root产生snap0, snap1
9. 安装完成。

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

（XXX： 恢复 /boot 如何处理？）

zshield backup和自动备份dameon工作基本内容
===================
lvremove /dev/VolGroup/snap1
lvcreate -s -n snap1 -L 100G /dev/VolGroup/lv-root


/boot 分区的考虑
================
由于snapshot无法覆盖/boot分区的备份，考虑使用复制/boot分区，或者使用grub2的/boot容灾机制。


示意图
============

(XXX: USB use ISO files?)

初始

| USB Stick   | SSD Disk|  HDD Disk |
| ----        | :--:    |   -------:|
| grub        |         |           |
| /boot       |         |           |
| File System |         |           |


OEM厂商初始化安装（或者用户选择USB重新恢复）

| USB Stick   | SSD Disk            |  HDD Disk       |
| ----        | :--:                |         -------:|
| grub        | grub                | lv-home         |
| /boot       | /boot               | lv-bglog        |
| File System | /tmp_FS             | snap0-->lv-root |
|             | lv-root             | snap1-->lv-root |
                        

(XXX: what is this /tmp_FS) 

出厂时产生snap0, 每日自动更新snap1对lv-root进行备份。系统出错后，可以选择从恢复出厂设置或者最近一次备份

恢复出厂设置或者最近一次备份

| USB Stick   | SSD Disk            |  HDD Disk       |
| ----        | :--:                |         -------:|
| grub        | grub                | lv-home         |
| /boot       | /boot               | lv-bglog        |
| File System | /tmp_FS             | snap0-->lv-root |
|             | lv-root+snap0/snap1 | snap1-->lv-root |


SSD作为日常启动盘和根文件系统的潜在风险：
=======================
1. 按照资料，MLC SSD仅能支持9000~10000次读写。需要考虑用SSD做lv-root时的每日读写量。
   不过，启诚也介绍了SSD leveling， 也就是耗损平均技术，可以认为损耗是整个SSD盘平均的。
   只要每日写入不超过500G（平均5次），可以能支撑五年以上。考虑到常写的log 文件目录在
   硬盘上，这个每日写入量应该不多。可以通过观测 snapshot 大小来验证 
2. 写入时的突然断电问题。SSD可以认为是工作在write back模式，里面有volatile的RAM。 
   有些文章介绍，写入时突然断电，会有数据丢失危险。不过 Chris 反馈这属于SSD硬件的firmware
   没做好， 真正企业用的SSD硬盘应该没这个危险。具体到我们，还需要了解下SSD硬盘的厂商和型号。
   回头要做大量的写入时断电测试，来确认这个是否会成为问题。


SSD，硬盘，Raid 断电可靠性测试
==================

硬件需求： USB/WiFi power relay。连接在 SSD 电源上，测试主机可以从程序操作断SSD 的电。

测试流程
1. 连接被测试 SSD/HD 到测试主机，其中 SSD 电源经过 USB/Wifi power relay。
2. 测试脚本进入循环：
	1. 随机写若干 block
	2. 在写的过程，断电
	3. 检查硬盘是否有非写入的扇区被修改。
	4. 检查硬盘被写入扇区是否符合修改的次序
	5. 检查硬盘被写入扇区是否符合 atomic update 的特性。（all or nothing)。
	6. 检查星盘被写入内容是是否和上次写操作一致。

这样的测试同样可以在 Raid controller/ 硬盘上做。

Links and reference
===================

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


[LVM snapshot 可以跨不同的 PV](https://stackoverflow.com/questions/28942795/lvm-create-snapshot-between-volume-groups)

这个比较重要是因为， SSD 和硬盘是不同的硬盘设备，属于不同的 PV。
snapshot 需要跨 SSD 和 硬盘。

[LVM snapshot merge](https://www.thegoldfish.org/2011/09/reverting-to-a-previous-snapshot-using-linux-lvm/)
这个练习建议跟一下。 snapshot merge 就是把 snapshot 写回原来的 lv。
相当于 lv 里面自从take snapshot 以后更改的内容就完全丢弃了。
注意， 不可以创建 snapshot 的 snapshot。


