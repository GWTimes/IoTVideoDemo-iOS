# IoTVideo-iOS Release Notes

## 更新记录 

----------------------------------------------------------------------------------------------------
#### v1.4(2001) Release 2021-06-01 
- 功能
  - 新增内置设置接口回调block
  - 新增回放策略；
  - 新增SD卡回放文件下载；
  - 新增SD卡回放文件倍速播放；
- 缺陷
  - 修复已知问题；

----------------------------------------------------------------------------------------------------
#### v1.3(1fb1) Release 2021-05-08
- 缺陷
  - 修复设备端收不到APP端的HEAD_ONLY的问题
- 优化
  - 优化对讲开关设置策略

----------------------------------------------------------------------------------------------------
#### v1.3(1fae) Release 2021-04-26
- 缺陷
  - 修复获取对讲状态不准问题
  - 修复APP启动立即创建播放器会黑屏问题
  - 修复卡回放seek之后文件剩余2秒没播完的问题

----------------------------------------------------------------------------------------------------
#### v1.3(1fa0) Release 2021-04-08
- 缺陷
  - 修复对讲开启后在设备端解析失败

----------------------------------------------------------------------------------------------------
#### v1.3(1f94) Release 2021-03-11
- 功能
  - 支持匿名登陆访问云回放

----------------------------------------------------------------------------------------------------
#### v1.3(1f7d) Release 2021-01-26
- 缺陷
  - 修复监控点击关闭对讲导致扬声器静音  
  - 修复H265解码器帧率减半问题  
  - 修复云存列表解析越界  

----------------------------------------------------------------------------------------------------
#### v1.3(1e4e) Release 2021-01-06
- 功能
  - 新增SD卡日历打点
- 缺陷
  - 修复偶现进入监控崩溃 
  - 修复物模型修改后更新不及时问题
  - 修复APP端视频通话设置视频采集帧率失效问题
  - 修复偶现视频渲染崩溃
  - 修复概率无声问题
- 优化
  - 优化监控实时性和流畅性
  - 优化偶像监控杂音问题

----------------------------------------------------------------------------------------------------
#### v1.3(1c07) Release 2020-11-28
- 缺陷
  - 修复内存泄漏
  - 修复异常数据解码崩溃
  - 修复已知缺陷

----------------------------------------------------------------------------------------------------
#### v1.3(1ab6) Release  2020-11-05
- 功能
  - 支持云存储购买
  - 支持云存事件
  - 支持匿名登录
- 优化 
	- 优化极端情况下播放器异常
- 缺陷
  - 修复已知缺陷

----------------------------------------------------------------------------------------------------
#### v1.2(15b6) Release 2020-08-27
- 优化 
  - 优化了SDK内置音视频功能模块
  - 优化了Demo示例和完善注释
- 缺陷
  - 修复已知缺陷

----------------------------------------------------------------------------------------------------
#### v1.2(12de) Release 2020-07-17
- 功能
  - 支持IPv6
  - 支持NVR（多源）
- 优化 
  - 优化播放器稳定性
  - 完善配网接口
- 缺陷
  - 修复已知缺陷

----------------------------------------------------------------------------------------------------
#### v1.1(1077) Release  2020-06-03
- 功能
	- 增加数据传输类（IVTransmission）
  - 增加扫码配网、AP配网
- 优化
  - 优化视频渲染
- 缺陷
  - 修复AirPods、A2DP耳机声音卡顿问题
  - 修复已知缺陷
- 其他
  - 其他Demo界面和功能优化

----------------------------------------------------------------------------------------------------
#### v1.1(eff) Release  2020-05-13
- 功能
  - 增加账号踢飞通知
  - 支持多路同屏和混音
  - ijk播放器增加https支持
- 优化
  - 优化视频卡顿现象
  - 优化H265解码
  - 优化播放器内部逻辑
- 缺陷
  - 修复已知bug
- 其他
  - 所有SDK改成静态库
  - 将FFmpeg库分离出来，由开发者在APP工程中导入 
      *(参考《IoTVideo-iOS开发指南.md》-#集成指南)*
  - 更新多路同屏Demo

----------------------------------------------------------------------------------------------------
####  v1.0(da7) Release  2020-04-16
- 功能
  - 适配新物模型OTA升级流程
  - 增加 获取二维码配网 token 接口
  - 增加SDK与服务器的连接状态
- 优化
  - 优化音视频缓冲和同步策略
  - 完善录像回放、云回放
  - 调整初始化SDK方法
- 其他
  - 完善OTA升级Demo
  - 修复已知bug

