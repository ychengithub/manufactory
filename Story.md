
基本硬件配置
============

1. CompactFlash：（sata接口）容量32G/64G/128G都选
2. 硬盘：(LSI raid card)，系统盘容量500G(LVM分区）。其他还有两个LVM分区：用户区、审计区（存放日志）

生产流程：
==========
1. 志翔（Zshield）将系统拷贝到CompactFlash，邮寄给OEM厂商。
2. OEM厂商安装CompactFlash，初始化系统，运行出厂测试程序
3. 测试通过后，直接发货给客户

用户使用流程：
=============
1. 上电正常使用
2. 升级系统：用户上网下载升级包，通过web管理页面升级系统
3. Rescue流程：因各种原因，当用户升级失败时，可以通过选抢救选项，从Golden Image启动，再重新升级。

基于以上需求，对OS改造及boot部分要求如下：
=========================================
1. Centos7系统盘要分离，变为只读和可读写部分，只读放在CompactFlash上，可读写部分放在硬盘上。
2. CompactFlash要支持两个分区，一个分区给Golden Image，永远不能updgrade，另外一个给latest系统，可以upgrade
3. 支持可以从GoldenImage boot，但default从latest系统boot。

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


[LVM snapshot 可以跨不同的 PV](https://stackoverflow.com/questions/28942795/lvm-create-snapshot-between-volume-groups)

这个比较重要是因为， CF 卡和硬盘是不同的硬盘设备，属于不同的 PV。
snapshot 需要跨 CF 和 硬盘。

[LVM snapshot merge](https://www.thegoldfish.org/2011/09/reverting-to-a-previous-snapshot-using-linux-lvm/)
这个练习建议跟一下。 snapshot merge 就是把 snapshot 写回原来的 lv。
相当于 lv 里面自从take snapshot 以后更改的内容就完全丢弃了。

注意， 不可以创建 snapshot 的 snapshot。


/boot 分区的考虑
================

LVM 的sanpshot 并不覆盖 /boot 分区。因为 /boot 分区是 Grub 用来加载 linux
kernel 的，Grub 不是 Linux 并不能理解和访问 LVM。所以snapshot 恢复的时候
/boot 分区需要单独处理, 包括复制 /boot 分区。

建议方案是 Golden 和系统正常跑的都有自己的单独的 /boot 分区。
Golden 的 /boot 分区先启动，如果没有用户输入的话，缺省跳入系统的 /boot
分区。

下载 upgrade 的时候会创建一个系统 /boot 分区并在 （LVM ? TBD) 里面保存一个
/boot 分区的备份镜像。这样恢复的时候可以直接拷贝。


初始系统的创立
===================
Golden 在网络下载新的系统镜像。在硬盘创建 LV 写入。
在完成下载以后，创建一个初始的 snapshot “factory”。

这个 factory snapshot 可以用来把硬盘的系统分区恢复到出场设置。

然后系统盘启动以后正常写入。


系统盘的恢复
============

进入 golen 盘，把 factory snapshot 进行 merge 操作：
lvconvert --merge /dev/vg-name/lv-factory
从新覆盖 /boot 分区。
重启就可以了。


用户 YUM 升级
=============
升级前，用户可以先 take sanpshot， "before-upgrade".
然后用户正常 yum 升级。
升级完和以后，用户检测是否满意成功。
如果成功 可以删除 “before-upgrade”
如果不成功，把 "before-upgrade" merge 回系统盘。
系统盘丢失升级造成的改动。


示意图
============

初始

| CF         | 硬盘|
|---         |--:|
|/boot Golden| |
|Golden      | |


下载系统升级以后

| CF         | 硬盘         |
|---         |-----:        |
|/boot Golden|              |
|Golden      | System       |
|            |              |
|            |              |


本地系统初始化以后
创建 factory snapshot
创建 /boot 的备份


| CF         | 硬盘         |
|---         |-----:        |
|/boot Golden| /boot system |
|Golden      | System       |
|            | Factory snapshot|
|            | /backup of boot|




