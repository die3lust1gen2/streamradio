FROM bluenviron/mediamtx AS server
FROM alpine:latest

#app defaults
ENV APPNAME="streamradio"
ENV DEFAULTS_BITRATE="32k"
ENV DEFAULTS_LOGLEVEL="error"
ENV DEFAULTS_PLATFORM="twitch.tv"
ENV DEFAULTS_YTQUALITY="480p"
ENV SCRIPT_TRANSCODE="stream.sh"

#mediamtx: stream config
ENV MTX_PATHDEFAULTS_RUNONDEMAND=./${SCRIPT_TRANSCODE}
ENV MTX_PATHDEFAULTS_RUNONDEMANDSTARTTIMEOUT=30s
ENV MTX_PATHDEFAULTS_RUNONDEMANDCLOSEAFTER=120s

#mediamtx: disable transports
ENV MTX_WEBRTC="no"
ENV MTX_SRT="no"
ENV MTX_RTMP="no"
ENV MTX_HLSVARIANT="fmp4"
ENV MTX_HLSSEGMENTDURATION=4s

#install ffmpeg, pip3 and tzdata
RUN apk --no-cache add shadow su-exec tzdata bash ffmpeg python3 py3-pip

#install streamlink via pip3 (I know, I know, should be updated to venv)
RUN pip3 install --upgrade --no-cache-dir --break-system-packages streamlink

#include mediamtx binary and default config
COPY --from=server /mediamtx /mediamtx
COPY --from=server /mediamtx.yml /mediamtx.yml

#include transcode script
COPY ${SCRIPT_TRANSCODE} ./${SCRIPT_TRANSCODE}
RUN chmod +x ./${SCRIPT_TRANSCODE}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888/tcp

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/mediamtx" ]