
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


1. 如果不涉及写到 lv0 的话，lv0 和 lv0-real 是一回事。读 lv0 会从 lv0-real 来读
2. 读 snap1 就是透过 snap1-cow 来读 lv0-real。如果不写的话，读 snap1 就是读
   lv0-real。这个时候 snap1-cow 是空文件。
3. 写 snap1 就是写 snap1-cow, 被写过的块就在 cow 文件创立。下次读 snap1 这个块就读到
  cow 这个写过的块而不用管 lv0-real。
4. 比较复杂的是写 lv0.这个时候要看 cow 文件有没有覆盖这个写的块。
  如果没有就要复制到 cow 文件。如果有多个 snapshot 就会有多个 cow 要复制。

对应到我这个例子，CF 卡的 Golden 就是 lv0, 从 Golden 启动就需要用到 snapshot，
就是 snap1， 这个 snap1 是在硬盘上。 也就是说，启动过程需要写的文件，都在 snap1
写入，自动就把读写分区放到了硬盘上。我们不需要改动 Cento 7 的系统盘划分只读部分
和可以写部分。

每次进入 Golden 启动就是很简单，删除 snap1，去掉上次进入 Golden 的残留
状态。从新创立 snap1，就是用 CF 卡的 Golden 来做 lv0. 这个删除和创立 snapshot
很快，因为等价删除文件和创立空文件，不需要拷贝任何数据。


[LVM snapshot 可以跨不同的 PV](https://stackoverflow.com/questions/28942795/lvm-create-snapshot-between-volume-groups)

这个比较重要是因为， CF 卡和硬盘是不同的硬盘设备，属于不同的 PV。
snapshot 需要跨 CF 和 硬盘。

