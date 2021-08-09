##### 不同日志级别划分，参考IVLogLevel
```
16:36:04.830 [SDK] [F]📵 这是一条「严重」级别日志
16:36:04.830 [SDK] [E]💔 这是一条「错误」级别日志
16:36:04.830 [SDK] [W]⚠️ 这是一条「警告」级别日志
16:36:04.830 [SDK] [I]💙 这是一条「信息」级别日志
16:36:04.830 [SDK] [D]   这是一条「调试」级别日志
16:36:04.830 [SDK] [V]   这是一条「跟踪」级别日志
```

##### 折叠与非折叠日志
```
16:36:04.830 [SDK] [I]💙 这是一条非折叠的「信息」级别日志
16:36:04.830 [SDK] [I]💙 {...12} 这是一条折叠了12次的「信息」级别日志，表明此处共有12条(包括本条)同类日志，且本条是最后一次日志的内容，此举是为了防止日志过于冗余
```

##### SDK相关信息（版本、编译日期、日志级别）
```
16:36:04.930 [SDK] [I]💙 > sdk-version:       1.4(2056) Debug  
16:36:04.930 [SDK] [I]💙 > compile-date:      2021-07-14 16:35:37  
16:36:04.930 [SDK] [I]💙 > log-level:         [D] 
```

##### SDK正在注册，待SDK连接状态变为'在线'方可正常使用
```
16:36:04.938 [SDK] [I]💙 IoTVideoSDK is registering, waiting for SDK-ONLINE, see `linkStatus` and `-[IoTVideoDelegate didUpdateLinkStatus:]`
```

##### SDK连接状态变更
```
16:36:05.234 [SDK] [I]💙 IoTVideoSDK 🟩SDK在线(1)
16:36:05.234 [SDK] [W]⚠️ IoTVideoSDK 🟧SDK离线(2)
16:36:05.234 [SDK] [W]⚠️ IoTVideoSDK 🟥accessToken校验失败(3)
16:36:05.234 [SDK] [W]⚠️ IoTVideoSDK 🟪账号被踢飞/在别处登陆(6)
```

##### 收到物模型通知（msgid:0是通知，msgid非0是APP主动请求）
```
16:36:05.244 [SDK] [I]💙 rcv_gdm_data_callback msgid:0 tid:031400005f9f70193835ef9af8f9b08e type:2 path:ProReadonly json:{"_online":{"stVal":1,"t":16...
16:36:05.246 [SDK] [I]💙 rcv_gdm_data_callback msgid:0 tid:031400005f9f70193835ef9af8f9b08e type:3 path:Action json:{"_otaVersion":{"stVal":"","t":0}...
```

##### 物模型发送与接收，收发msgid应一一对应
```
16:36:05.336 [SDK] [I]💙 send message msgid:1060388670 devid:031400005f3c94906ff55e0d1c7b5fc2, path:ProReadonly._online, json:, raw:, rspMode:1 cb:0x1c4443f00
16:36:05.336 [SDK] [I]💙 send message msgid:1060388671 devid:031400005f9f70193835ef9af8f9b08e, path:ProReadonly._online, json:, raw:, rspMode:1 cb:0x1c425e9f0
16:36:05.530 [SDK] [I]💙 get_gdm_data_callback msgid:1060388670 tid:031400005f3c94906ff55e0d1c7b5fc2 {"stVal":0,"t":0} ok
16:36:05.534 [SDK] [I]💙 get_gdm_data_callback msgid:1060388671 tid:031400005f9f70193835ef9af8f9b08e {"stVal":1,"t":1626250568} ok
```

##### 收到内置指令消息 
```
16:36:19.709 [SDK] CH1 rcv built-in cmd:0x30 msgid:2754142944 {length=17, bytes=0xffffff88 00020900 00300000 e0e228a4 01}
16:36:19.710 [SDK] CH1 rcv built-in cmd:0x31 msgid:2754142944 {length=17, bytes=0xffffff88 00020900 00310000 e0e228a4 00}
```

##### ffmpeg库版本信息
```
16:36:19.091 [SDK] [I]💙 FFmpeg       : ff3.4--ijk0.8.7--20180103--001
16:36:19.091 [SDK] [I]💙 libavutil    : 55.78.100
16:36:19.091 [SDK] [I]💙 libavcodec   : 57.107.100
16:36:19.093 [SDK] [I]💙 libavformat  : 57.83.100
16:36:19.095 [SDK] [I]💙 libswscale   : 4.8.100
16:36:19.095 [SDK] [I]💙 libswresample: 2.9.100
16:36:19.095 [SDK] [I]💙 libavfilter  : 6.107.100
```

##### 创建播放器（监控、回放、双向视频通话）
```
16:36:18.843 [SDK] IVMonitorPlayer(0x1051ed800) init 031400005f9f70193835ef9af8f9b08e:0 1.4(2056) Debug
16:36:38.657 [SDK] IVPlaybackPlayer(0x105101850) init 031400005f9f70193835ef9af8f9b08e:0 1.4(2056) Debug
16:37:10.922 [SDK] IVLivePlayer(0x1051375b0) init 031400005f9f70193835ef9af8f9b08e:0 1.4(2056) Debug
```

##### 监控清晰度设置与响应
```
16:36:21.869 [SDK] CH1 async setDefinition: 0
16:36:22.040 [SDK] [I]💙 CH1 setDefinition:0 succ rsp:<01>
```

##### 设置视频渲染缓冲区大小
```
16:36:19.221 [SDK] CH1 render_buf_rst renderSize:750x1206
```

##### 开始播放（异步）
```
16:36:19.229 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) async play
```

##### 准备中/连接中
```
16:36:19.229 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH-1 status=Preparing...
16:36:19.233 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH-1 connStatus=Connecting...
```

##### 已连接/已就绪
```
16:36:19.674 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 connStatus=Connected
16:36:19.674 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 status=Ready
```

##### 加载中
```
16:36:19.675 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 status=Loading...
```

##### 收到音视频流信息(音频编码类型、声道模式、音频子编码类型、位宽、采样率、每帧采样数、视频编码类型、帧率、宽、高)
```
16:36:19.729 [SDK] [I]💙 CH1 rcv AVHeader at:4 am:0 ac:2 abw:16 ar:8000 aspf:1024 vt:5 vr:15 vw:2304 vh:1296 
```

##### 包含流的种类（音频流、视频流的组合）
```
16:36:19.729 [SDK] [I]💙 CH1 media-streams: Audio + Video
```

##### 启动了视频渲染器
```
16:36:19.731 [SDK] [I]💙 CH1 start_vi_render W2304xH1296
```

##### 启动了音频渲染器
```
16:36:19.735 [SDK] [I]💙 CH1 start_au_render
```

##### 注册AAC音视编/解码器
```
16:36:19.751 [SDK] [I]💙 CH1 adec:aac register ch:1 ar:8000
16:36:19.813 [SDK] [I]💙 CH1 aenc:aac register ch:1 ar:8000
```

##### 注册H265视频解码器
```
16:36:19.846 [SDK] [I]💙 CH1 vdec:h265 register
```

##### 收到了视频帧（未解码）
```
16:36:19.846 [SDK] CH1 vi_rcv pts:0 (+0) len:31150
```

##### 解码了视频帧
```
16:36:19.874 [SDK] CH1 vi_dec i:0x114c0c000(31150) o:0x10585c2f8->0x10585c2f8(92652304) pts:0
```

##### 渲染了视频帧
```
16:36:19.891 [SDK] CH1 vi_ren pts:0 (+0) remain:+0
```

##### 视频帧解码失败
```
16:36:20.006 [SDK] [W]⚠️ CH1 vdec:h265 failed, expected 2304x1296 pts:66672 [IVH265Codec.m:248 ]
```

##### 视频比音频快，暂停渲染以等待音频
```
16:36:43.664 [SDK] CH1 vi_ren wait vpts(1626227975061000)-apts(1626227975045000)=+16000
```

##### 已成功播放（渲染了第一帧视频）
```
16:36:19.891 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 status=Playing...
```

##### 收到了音频帧（未解码）
```
16:36:19.955 [SDK] CH1 au_rcv pts:128000 (+128000) len:214
```

##### 解码了音频帧
```
16:36:20.005 [SDK] CH1 au_dec i:0x10628c600(214) o:0x112eb8000(2048) pts:128000
```

##### 渲染了音频帧
```
16:36:21.120 [SDK] CH1 au_ren pts:128000 (+128000) remain:+170625 size:170
```

##### 网络抖动引起缓存区积累了较多数据，在监控/双向音视频通话时要加速播放，防止积累延迟
```
16:36:20.117 [SDK] CH1 jitter stalled apts:138750 delay:245250 tolerance:200000 a
```

##### 无视频可渲染
```
16:36:22.037 [SDK] CH1 vi_ren no frame
```

##### 无音频可渲染
```
16:36:22.037 [SDK] CH1 au_ren no frame
```

##### 启动音频采集
```
16:36:24.402 [SDK] CH1 start_au_capture
```

##### 音频采集
```
16:36:24.522 [SDK] CH1 au_fill in:2048
```

##### 音频编码
```
16:36:25.933 [SDK] CH1 au_enc i:0x106285200(2048) o:0x10626da00(260)
```

##### 停止播放（同步）
```
16:36:38.053 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 sync stop
```

##### 停止音频采集
```
16:36:26.215 [SDK] CH1 stop_au_capture
```

##### 停止音频渲染
```
16:36:38.055 [SDK] CH1 stop_au_render
```

##### 停止视频渲染
```
16:36:22.079 [SDK] CH1 stop_vi_render
```

##### 销毁AAC音频编码器
```
16:36:38.060 [SDK] CH1 aenc:aac unregister
16:36:38.060 [SDK] CH1 aenc:aac dealloc
```

##### 销毁AAC音频解码器
```
16:36:22.038 [SDK] CH1 adec:aac unregister
16:36:22.038 [SDK] CH1 adec:aac dealloc
```

##### 销毁H265视频解码器
```
16:36:22.040 [SDK] CH1 vdec:h265 unregister
16:36:22.040 [SDK] CH1 vdec:h265 dealloc
```

##### 停止中/断开中
```
16:36:38.054 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 status=Stopping...
16:36:38.055 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 connStatus=Disconnecting...
```

##### 已断开/播放停止
```
16:36:38.095 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 connStatus=Disconnected
16:36:38.096 [SDK] [I]💙 IVMonitorPlayer(0x1051ed800) CH1 status=Stopped
```

##### 销毁播放器
```
16:36:38.104 [SDK] IVMonitorPlayer(0x1051ed800) will dealloc
16:36:38.104 [SDK] IVMonitorPlayer(0x1051ed800) dealloc
```

##### 卡回放列表请求与响应
```
16:36:38.733 [SDK] getPlaybackList dev:031400005f9f70193835ef9af8f9b08e pageIdx:0 perPage:10000 maxRecNum:3217 cmd:0x10 t0:1626105600.000 t1:1626192000.000 ft:(null) order:1
16:36:38.774 [SDK] [I]💙 rspV3 cmd:0x10 page:1/1 pkgIdx:0xFFFFFFFF itemcnt:68 basetime:1626159678252 typeCnt:1 t0:1626105600.000
```

##### 文件回放开始
```
16:36:42.237 [SDK] [I]💙 CH2 willBeginOfFile:1626227969548
```

##### 文件回放结束
```
16:36:43.214 [SDK] [I]💙 CH2 didEndOfFile:1626227969548 (null)
```

##### 设置回放倍速与响应
```
16:36:48.600 [SDK] CH2 async setPlaybackSpeed: 16.000
16:36:48.733 [SDK] [I]💙 CH2 setPlaybackSpeed:16.000 succ rsp:<02>
```

##### seek到指定位置
```
16:36:58.151 [SDK] [I]💙 CH2 seekToTime:1626230202.257 file[1626230128.328 - 1626230490.312](361.984) curr_pts:1626229117.410 seek_offset:+1084.847(s)
16:36:58.151 [SDK] [I]💙 IVPlaybackPlayer(0x105101850) CH2 status=Seeking...
```

##### 无效的音视频（根据pts判断是否seek到位）
```
16:36:58.159 [SDK] [W]⚠️ CH2 invalid apts:1626229117471250 seek:1626230202257272 (-1084786022) [IVPlayer.m:1553 ]
16:36:58.167 [SDK] [W]⚠️ CH2 invalid vpts:1626229117474000 seek:1626230202257272 (-1084783272) [IVPlayer.m:1519 ]
```

##### 音视频seek已到位
```
16:36:58.480 [SDK] [I]💙 CH2 au_seek done apts:1626230203721375 seek:1626230202257272 (+1464103)
16:36:58.643 [SDK] [I]💙 CH2 vi_seek done vpts:1626230203704000 seek:1626230202257272 (+1446728)
```

