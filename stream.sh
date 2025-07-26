#!/bin/bash

#+-----------------------------------------------------------------------------
#| Defaults
#+-----------------------------------------------------------------------------

#All parameters
PARAM_LOGLEVEL="$DEFAULTS_LOGLEVEL"
PARAM_BITRATE="$DEFAULTS_BITRATE"
PARAM_PLATFORM="$DEFAULTS_PLATFORM"
PARAM_YTQUALITY="$DEFAULTS_YTQUALITY"

PARAM_AUTH=""
PARAM_LL=""
PARAM_MONO=""
PARAM_FFMPEG=""
PARAM_STREAMLINK=""
PARAM_CUTOFF=""
PARAM_CHANNEL=""
PARAM_QUALITY=""

#Colors
CD='\033[0m'    #Default
CG='\033[0;32m' #Green
CR='\033[0;31m' #Red
CP='\033[1;35m' #Purple

#+-----------------------------------------------------------------------------
#| Parse environment variables
#+-----------------------------------------------------------------------------

#Loglevel
if [ -n "$SR_LOGLEVEL" ]; then
        if [ "$SR_LOGLEVEL" != "$PARAM_LOGLEVEL" ]; then
                PARAM_LOGLEVEL="$SR_LOGLEVEL"
                echo "Using custom loglevel: $PARAM_LOGLEVEL"
        fi
fi

if [ -n "$SR_TOKEN" ];            then PARAM_AUTH="--twitch-api-header=Authorization=OAuth $SR_TOKEN"; fi
if [ -n "$SR_BITRATE" ];          then PARAM_BITRATE="$SR_BITRATE"; fi
if [ -n "$SR_CUTOFF" ];           then PARAM_CUTOFF="$SR_CUTOFF"; fi
if [ -n "$SR_PARAM_STREAMLINK" ]; then PARAM_STREAMLINK="$SR_PARAM_STREAMLINK"; fi
if [ -n "$SR_PARAM_FFMPEG" ];     then PARAM_FFMPEG="$SR_PARAM_FFMPEG"; fi
if [ -n "$SR_PLATFORM" ];         then PARAM_PLATFORM="$SR_PLATFORM"; fi
if [ "$SR_LOWLATENCY" = "true" ]; then PARAM_LL="--twitch-low-latency"; fi
if [ "$SR_MONO" = "true" ];       then PARAM_MONO="-ac 1"; fi

#+-----------------------------------------------------------------------------
#| Parse URL parameters and override defaults from environment
#+-----------------------------------------------------------------------------

STRING="${MTX_PATH#/}"  # Remove leading slash

IFS='/' read -ra parts <<< "$STRING"

len=${#parts[@]}

for i in "${!parts[@]}"; do

  part="${parts[i]}"

  if   [[ $i -eq $((len - 1)) ]];     then PARAM_CHANNEL="$part"
  elif [[ "$part" == ll ]];           then PARAM_LL="--twitch-low-latency"
  elif [[ "$part" == mono ]];         then PARAM_MONO="-ac 1"
  elif [[ "$part" == stereo ]];       then PARAM_MONO=""
  elif [[ "$part" =~ ^([0-9]+k)$ ]];  then PARAM_BITRATE="${BASH_REMATCH[1]}"
  elif [[ "$part" =~ ^([0-9]+)hz$ ]]; then PARAM_CUTOFF="${BASH_REMATCH[1]}"
  elif [[ "$part" =~ ^([0-9]+p)$ ]];  then PARAM_YTQUALITY="${BASH_REMATCH[1]}"
  elif [[ $i -eq 0 && $len -gt 1 ]];  then PARAM_PLATFORM="$part"
  fi

done

#+-----------------------------------------------------------------------------
#| prepare output
#+-----------------------------------------------------------------------------

STREAMINFO=""

#Auth token
if [ -n "$PARAM_AUTH" ]; then STREAMINFO="${STREAMINFO}${CD}Token: ${CG}yes${CD}"
else                          STREAMINFO="${STREAMINFO}${CD}Token: ${CR}no${CD}"
fi

#Bitrate
STREAMINFO="${STREAMINFO}, ${CD}Bitrate: ${CG}$PARAM_BITRATE${CD}"

#low latency
if [ -n "$PARAM_LL" ]; then STREAMINFO="${STREAMINFO}, ${CD}Low Latency: ${CG}yes${CD}"
else                        STREAMINFO="${STREAMINFO}, ${CD}Low Latency: ${CR}no${CD}"
fi

#Mono audio
if [ -n "$PARAM_MONO"  ]; then STREAMINFO="${STREAMINFO}, ${CD}Mono: ${CG}yes${CD}"
else                           STREAMINFO="${STREAMINFO}, ${CD}Mono: no"
fi

#Hz cutoff
if [ -n "$PARAM_CUTOFF" ]; then STREAMINFO="${STREAMINFO}, ${CD}Hz cutoff: ${CG}$PARAM_CUTOFF${CD}"
else                            STREAMINFO="${STREAMINFO}, ${CD}Hz cutoff: ${CD}no${CD}"
fi

#streamlink extra parameters
if [ -n "$PARAM_STREAMLINK" ]; then
        echo "Using additional streamlink parameters: $PARAM_STREAMLINK"
fi

#ffmpeg extra parameters
if [ -n "$PARAM_FFMPEG" ]; then
        echo "Using additional ffmpeg parameters: $PARAM_FFMPEG"
fi

#+-----------------------------------------------------------------------------
#| Build parameters
#+-----------------------------------------------------------------------------

if [ -n "$PARAM_CUTOFF" ]; then
        PARAM_CUTOFF="-cutoff ${PARAM_CUTOFF}"
fi

PARAM_QUALITY="audio_only"

if [ "$PARAM_PLATFORM" == "y" ] || [ "$PARAM_PLATFORM" == "youtube.com" ]; then
        PARAM_PLATFORM="youtube.com"
        PARAM_CHANNEL="@$PARAM_CHANNEL"
        PARAM_QUALITY="$PARAM_YTQUALITY,best"
        STREAMINFO="Streaming: ${CR}${PARAM_PLATFORM}/${PARAM_CHANNEL}${CD} (${STREAMINFO}${CD})"

elif [ "$PARAM_PLATFORM" == "t" ] || [ "$PARAM_PLATFORM" == "twitch.tv" ]; then
        PARAM_PLATFORM="twitch.tv"
        PARAM_QUALITY="audio_only"
        STREAMINFO="Streaming: ${CP}${PARAM_PLATFORM}/${PARAM_CHANNEL}${CD} (${STREAMINFO}${CD})"
fi

#Output stream info
echo -e $STREAMINFO

# Disable globbing to avoid issues with * or ? in params
set -f

#build parameters
PARAMS_STREAMLINK="https://$PARAM_PLATFORM/$PARAM_CHANNEL $PARAM_QUALITY $PARAM_LL $PARAM_STREAMLINK --retry-max 0 --loglevel $PARAM_LOGLEVEL --stdout"
PARAMS_FFMPEG="-loglevel $PARAM_LOGLEVEL -nostats -re -i pipe:0 -vn -c:a libopus -compression_level 10 $PARAM_CUTOFF -b:a $PARAM_BITRATE $PARAM_MONO $PARAM_FFMPEG -f rtsp rtsp://localhost:$RTSP_PORT/$MTX_PATH"

#+-----------------------------------------------------------------------------
#| Start stream
#+-----------------------------------------------------------------------------

if [ -n "$PARAM_AUTH" ]; then
        set -- $PARAMS_STREAMLINK; streamlink "$@" "$PARAM_AUTH" | ( set -- $PARAMS_FFMPEG; ffmpeg "$@" )
else
        set -- $PARAMS_STREAMLINK; streamlink "$@" | ( set -- $PARAMS_FFMPEG; ffmpeg "$@" )
fi