
基本硬件配置
============
1. SSD硬盘(SATA接口）：容量128G，存储Golden Image，供用户出错时恢复系统
2. HDD硬盘：可以为SATA硬盘或者RAID磁盘阵列，单盘容量4T, 用于正常系统运行和用户数据存储，
   分为lv-root, lv-home, lv-bglog三个LVM。 
3. Live USB安装盘: 容量16G, 供OEM厂商初始化安装系统和用户恶劣情况下重新安装系统。

系统设计原则
============
1. 方便生产：系统可以由OEM厂商一键安装，经过测试后直接发往客户
2. 系统容灾：向客户提供错误恢复功能，可以恢复至最近备份或出厂设置。
3. 使用简洁：grub启动选项尽量精简，避免错误进入。Golden image恢复系统时
   提供二次确认选项，避免用户一次错误选择意外损失数据，无法恢复。 
4. 自动友好：提供系统自动备份，自动一致性检查，自动告警功能，减少用户介入
5. 误操作保护：对于Golden Image设为只读格式，避免误操作。同时提供USB紧急恢复盘，双重恢复机制。 

生产流程：
==========
1. 志翔（Zshield）向OEM厂商提供USB安装盘（或者镜像文件，由OEM厂商dd到USB盘）。 
2. OEM厂商从USB盘启动，一键完成系统初始化安装。
3. OEM厂商运行出厂测试程序，可能是另外一个测试 USB 启动盘，测试通过后，直接发货给客户

用户使用流程：
=============
1. 正常使用：用户从HDD硬盘启动,正常使用系统。
2. 系统备份：系统每日凌晨自动进行系统备份，用户也可手动执行系统备份命令。
3. 系统升级：用户上网下载升级包，按照用户指导手册，升级系统。系统升级命令会自动触发系统备份。升级系统，长期目标为rpm方式。
4. 系统恢复：
            a)当系统无法正常启动时，从SSD硬盘的Golden Image启动，按照提示框选择恢复至出厂设置/最近一次备份/退出恢复重启，完成恢复后系统自动重启。
            b)当系统运行时出现一致性检查告警，弹出提示框，可选择恢复至出厂设置/最近一次备份，恢复完成后，自动重启系统。
5. 系统紧急回复：向用户提供USB紧急回复盘（与USB安装盘相同），用于恶劣情况下的系统重新安装。 
					
snapshot 设计
================
1. 系统仅对lvm-root, 即根文件系统做snapshot和恢复，其他lvm不做snapshot和恢复。lvm-root大小50G，放在HDD硬盘上。
2. 系统对lvm-root，维护两个snapshot，factory 为出厂备份，完成安装后自动产生。latest为最新备份, 由系统每日凌晨自动备份。
   factory和latest均位于HDD硬盘上。 
3. 系统维护一个备份dameon， 每日凌晨自动对lvm-root进行snapshot, 更新latest.
4. 提供zshield_backup备份命令，供用户在断电或其他事件前备份系统（过程与3相同）。
5. 系统升级命令会自动触发系统备份。

Prototype Live USB安装盘创建
===================
1. 通过标准CentOS 7 installer精简安装到 USB,并创建根文件系统。
2. 拷贝ISP系统运行时kernel image，initrd image和源文件系统压缩包（已安装至安盾系统）至USB根文件系统。
3. 在step 1里应该已经完成grub-install过程。如果没有，须手动执行grub-install --target=i386-pc --boot-directory=/boot /dev/sda完成USB盘上的grub安装。
4. 修改/etc/rc.d/rc.local, 添加zshield_manufactory.py脚本执行
5. Protoype Live USB安装盘完成. 
6. 运行dd命令产生镜像文件。镜像文件可以发送给OEM厂商，用dd产生后续Live USB安装盘.

zshield_manufactory.py功能介绍
===================
1. 初始化HDD硬盘:
	a) 初始化硬盘，创建/boot分区，创建lvm-root, lvm-home, lvm-bglog三个LVM分区。
	b) 拷贝kernel image和initrd image至/boot分区，解压源文件系统压缩包至lvm-root。
	c) 对HDD安装grub
	d) HDD硬盘初始化完成

2. 初始化SSD硬盘
	a) 初始化硬盘，创建/boot和/root分区
	b) 拷贝kernel image和initrd image至/boot分区，从Live USB盘拷贝精简文件系统至/root分区。
	c) 对SSD安装grub
        d) 向Golden系统添加自动运行python脚本，供用户选择恢复至出厂设置/恢复至最近备份/退出恢复。
        e) SSD硬盘初始化完成
3. 在HDD上创建factory和latest两个snapshot
4. 安装完成, 重新启动系统

Golden Image启动和恢复过程
===================
1. 用户选择从SSD硬盘启动，进入Golden Image。
2. 执行python脚本弹出对话框，供客户选择恢复至出厂设置/最近一次备份/退出恢复。对应操作如下：
	 a)恢复至出场设置：
				扫描/dev/sdb硬盘内的vgs和lv
				将factory进行merge到lv-root
				重启系统
	 b)恢复至最近一次备份 
				扫描/dev/sdb硬盘内的vgs和lv
				将latest进行merge到lv-root
				重启系统
	 c)退出恢复：
	      重启系统			

zshield backup和自动备份dameon工作基本内容
===================
lvremove /dev/VolGroup/latest
lvcreate -s -n latest -L 50G /dev/VolGroup/lv-root


Golden Image保护
================
由于snapshot无法覆盖/boot分区的备份，Golden Image采用ISO9660文件系统，然后overlay ramFS。


示意图
============


初始

| Live USB    | SSD Disk|  HDD Disk |
| ----        | :--:    |   -------:|
| grub        |         |           |
| /boot       |         |           |
| File System |         |           |


OEM厂商初始化安装（或者用户选择USB重新恢复）

| Live USB    | SSD Disk            |  HDD Disk         |
| ----        | :--:                |         -------:  |
| grub        | Golden grub         | ISP grub          |
| /boot       | /Golden boot        | ISP boot          |
| File System | /Golden FS          | lv-root           |
|             |                     | lv-home           |
|             |                     | lv-bglog          |
|             |                     | factory-->lv-root |
|             |                     | latest-->lv-root  |
                        


出厂时产生factory, 每日自动更新latest对lv-root进行备份。系统出错后，可以选择从恢复出厂设置或者最近一次备份
恢复出厂设置或者最近一次备份, 此时无需Live USB
| SSD Disk            |  HDD Disk         |
| :--:                |         -------:  |
| Golden grub         | ISP grub          |
| /Golden boot        | ISP boot          |
| /Golden FS          | lv-root merged    |
|                     | lv-home           |
|                     | lv-bglog          |
|                     | factory-->lv-root |
|                     | latest-->lv-root  |

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


