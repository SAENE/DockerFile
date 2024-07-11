#!/bin/bash
PUID=${PUID:-1000}
PGID=${PGID:-1000}
echo -e "\
        Please do not modify this file. Restarting the container will overwrite it.\n\
        请不要修改此文件，重启容器会覆盖\n\
        项目地址：https://github.com/yutto-dev/yutto\n\
        默认命令 ytt 参数为 yutto -d /config/ -n 8 --vcodec='hevc:copy' -q 127 -aq 30251 --output-format=mkv --no-danmaku --no-subtitle --vip-strict --login-strict\n\
        请使用 ytt -c \"自己的 SESSDATA\" -b 下载地址\n\
        最大并行 worker 数量 -n 或 --num-workers 8 \n\
        指定视频清晰度等级 -q 或 --video-quality 127 | 126 | 125 | 120 | 116 | 112 | 80 | 74 | 64 | 32 | 16 画质随数字减小而变差\n\
        指定音频码率等级 -aq 或 --audio-quality 30280 | 30232 | 30216 音质随数字减小而变差\n\
        指定视频编码 --vcodec avc:copy | hevc:copy | av1:copy 参数需要带双引号\n\
        指定音频编码 --acodec mp4a:copy 参数需要带双引号\n\
        指定输出格式 --output-format infer | mp4 | mkv | mov 表示自动根据情况进行推导以保证输出的可用，优先MP4\n\
        指定在仅包含音频流时的输出格式 --output-format-audio-only infer | aac | flac | mp4 | mkv | mov\n\
        弹幕格式选择 -df 或 --danmaku-format ass | xml | protobuf\n\
        下载块大小 -bs 或 --block-size 以 MiB 为单位，为分块下载时各块大小，不建议更改。\n\
        强制覆盖已下载文件 -w 或 --overwrite\n\
        代理设置 -x 或 --proxy auto | no | <https?://url/to/proxy/server>\n\
        存放根目录 -d 或 --dir\n\
        临时文件目录 --tmp-dir\n\
        Cookies 设置 -c 或 --sessdata\n\
        仅下载音频流 --audio-only\n\
        不生成弹幕文件 --no-danmaku\n\
        仅生成弹幕文件 --danmaku-only\n\
        不生成字幕文件 --no-subtitle\n\
        仅生成字幕文件 --subtitle-only\n\
        生成媒体元数据文件 --with-metadata\n\
        仅生成媒体元数据文件 --metadata-only\n\
        指定媒体元数据值的格式 --metadata-format-premiered\n\
        严格校验大会员状态有效 --vip-strict\n\
        严格校验登录状态有效 --login-strict\n\
        启用 Debug 模式 --debug\n\
" > /config/README.md
cat /config/README.md
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc
chown -R ${PUID}:${PGID} /config