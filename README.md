# streamradio

Provides audio-only HLS Opus streams for Twitch and Youtube. Listen to any live stream with **minimal** bandwidth usage. **1h** stream consumes less than **15MB** (depending on the setting).

Dead simple Docker container that just glues <a href=https://github.com/streamlink/streamlink>Streamlink</a> and <a href="https://github.com/bluenviron/mediamtx">MediaMTX</a> together.

**Notes:**
* Do not expect crisp high fidelity audio. Low bitrate and bandwidth come at a cost.
* **There is no authentication feature!** If you choose to deploy this yourself, make sure to add an authentication layer or deploy this within a trusted, non-public network you can VPN into.


# Usage

Spin up the container, then access the stream of your choice.

## start a stream
Access a live stream with your Browser or VLC. Select the platform with their first letter shortcut.
It will take a couple of seconds for the stream to start.

Platform | Client |  Channel | Stream URL
---|---|---|---
<span style="font-weight:bold;color:purple">t</span>witch.tv | Browser | shroud | http:&zwnj;//dockerhost:8888<span style="font-weight:bold;color:purple">/t</span>/shroud
<span style="font-weight:bold;color:purple">t</span>witch.tv | VLC     | shroud | http:&zwnj;//dockerhost:8888<span style="font-weight:bold;color:purple">/t</span>/shroud/index.m3u8
<span style="font-weight:bold;color:red">y</span>outube.com  | Browser | @ESLCS | http:&zwnj;//dockerhost:8888<span style="font-weight:bold;color:red">/y</span>/ESLCS
<span style="font-weight:bold;color:red">y</span>outube.com  | VLC     | @ESLCS | http:&zwnj;//dockerhost:8888<span style="font-weight:bold;color:red">/y</span>/ESLCS/index.m3u8

Without the shortcut, streamradio uses twitch.tv as default platform. The default can be changed via environment variable.

Platform | Client | Channel | Stream URL
---|---|---|---
twitch.tv | Browser | shroud | http:&zwnj;//dockerhost:8888/shroud
twitch.tv | VLC     | shroud | http:&zwnj;//dockerhost:8888/shroud/index.m3u8

## start a stream with different quality settings

The default quality settings are defined by environment variables. If you want to use different settings (overriding the defaults) for a stream, just add the settings to the URL between platform and channel.

http:&zwnj;//dockerhost:8888/\<platform\>/<span style="font-weight:bold;color:green">[/param1]</span><span style="font-weight:bold;color:lightblue">[/param2]</span><span style="font-weight:bold;color:orange">[/param3]</span>/\<channel\>

**Examples:**
Settings | URL
---|---
32k bitrate | http:&zwnj;//dockerhost:8888/t/32k/shroud
mono audio | http:&zwnj;//dockerhost:8888/t/mono/shroud
use Hz cutoff | http:&zwnj;//dockerhost:8888/t/10000hz/shroud
use all above | http:&zwnj;//dockerhost:8888/t/32k/mono/1000hz/shroud

**All available settings:**
Setting | Definition | Example
---|---|---
audio bitrate | / + number + **k** | /20k, /32k, /64k
mono or stereo | / + string | /mono, /stereo
Hz cutoff | / + number + **hz** | /4000hz, 6000hz, 8000hz, 12000hz or 20000hz
low latency (twitch only) | / + string | /ll
Source quality (youtube only) | / + number + **p** | /360p, /480p, /720p, /1080p

# Quality considerations

The goal is to use as less data/bandwith as possible while keeping a "good enough" quality and easy usability. "Good enough" quality is subjective, so you may need to test for your personal preferences.

**What I chose and why:**
Setting | Reason
---|---
20kb | very low bitrate, but good enough for me in combination with cutoff and mono audio.
mono | I do not need stereo. Giving the few kbits we have to one channel increases quality.
10000hz cutoff | Drop higher frequencies, so encoding those do not starve bits from the lower ones. Helps to reduce consonants smearing and metallic artifacts.

If you want stereo, consider a bitrate of at least 32kb or 48kb or even higher.

**HLS segments:**

The default segment length is set to 4 seconds to reduce HTTP requests. With a low bitrate the HTTP overhead actually becomes a relevant factor in data usage. The downside of this, is that streams takes longer to start up.
Segements with 1 second length and a bitrate of 20kb consume around 3kB/s, HLS HTTP requests use 1kB/s. So 25% of the traffic would just be HLS HTTP.

# Setup

# docker compose

Some deployment examples.

### simple setup
```yaml
services:

  streamradio:
    image: ghcr.io/die3lust1gen2/streamradio
    restart: unless-stopped
    ports:
      - 8888:8888/tcp
```

### Twitch auth token + higher bitrate + timezone
```yaml
services:

  streamradio:
    image: ghcr.io/die3lust1gen2/streamradio
    restart: unless-stopped
    ports:
      - 8888:8888/tcp
    environment:
      TZ: Europe/Berlin
      SR_TOKEN: asdfasdfasdfasdf
      SR_BITRATE: 64k
    security_opt: ['no-new-privileges:true']
```

# Configuration

The following parameters can be set with environment variables.
They are all optional.

variable | value | default | setting
---|---|---|---
UID / GID           | user ID / group ID                          | 1000      | user ID / group ID used for the app.
TZ                  | timezone (eg. Europe/Berlin)                | UTC       | Set container timezone.
SR_TOKEN            | OAuth token string                          | empty     | Twitch OAuth token. Useful for subbed channels or Twitch Turbo. See <a href="https://streamlink.github.io/cli/plugins/twitch.html">here</a> on how to get one for your own Twitch account.
SR_BITRATE          | number + unit (eg. 20k/24k/32k/48k)         | 32k       | streaming bitrate in kbit/s.
SR_LOWLATENCY       | true \| false                               | false     | enables streamlink's twitch low latency mode.
SR_MONO             | true \| false                               | false     | encodes mono audio. Using only one channel increases quality, but is ... mono.
SR_CUTOFF           | 4000, 6000, 8000, 12000 or 20000            | empty     | Sets audio bandwidth (in Hz)
SR_PLATFORM         | youtube.com or twitch.tv                    | twitch.tv | Default streaming platform.
SR_YTQUALITY        | 360p, 480p, 720p, 1080p, best               | 480p      | quality selection for youtube streams. Youtube does not provide audio only streams, so we have to use full video streams and extract the audio.
SR_PARAM_STREAMLINK | see streamlink docs                         | empty     | add additional parameters to streamlink.
SR_PARAM_FFMPEG     | see ffmpeg docs                             | empty     | add additional parameters to ffmpeg.
SR_LOGLEVEL         | error \| warning \| info \| debug \| trace  | error     | set loglevel for streamlink and ffmpeg. debug and trace will produce **A LOT OF LOGS!**

## Advanced Configuration

You can change MediaMTX settings via the MTX_* environment variables. See the <a href="https://github.com/bluenviron/mediamtx?tab=readme-ov-file#other-features">MediaMTX documentation</a> for more information.

variable | value | default | setting
---|---|---|---
MTX_HLSSEGMENTDURATION | number + unit (eg. 1s, 4s) | 4s | Minimum duration of each segment. It usually take 3 segments (=waiting time) for playback to start.
MTX_HLSVARIANT | mpegts, fmp4, lowLatency | fmp4 |  HLS transport variant. **lowLatency** will significantly reduce stream startup times, but will also add **more overhead**. Be careful with this!
MTX_PATHDEFAULTS_RUNONDEMANDCLOSEAFTER | number + unit (eg. 60s, 120s) | 120s | Define how long the stream will be transcoded after all clients disconnected. Useful for quick reconnects.

# Reverse proxy

### Apache

Serving the container with Apache under a dedicated sub path **/streamradio/<channel>**.

To simplify and unify stream URL access for VLC, we rewrite VLC requests (identified by user-agent) to the playlist file, so:<br/>
 /streamradio/**\<channel\>** will be redirected /streamradio/**\<channel\>**/index.m3u8

```apache

<Virtualhost :443>

    #add a trailing slash (files excluded, like .mp4 or .m3u8)
    RewriteCond %{REQUEST_URI} !^/streamradio/.*\.[a-zA-Z0-9]+$
    RewriteRule ^/streamradio(?:/[^/]+)+$ %{REQUEST_URI}/ [R=301,L]

    #VLC redirect
    RewriteCond %{REQUEST_URI}      "^/streamradio/(?:\w+/)+$"
    RewriteCond %{HTTP_USER_AGENT}  "VLC.*LibVLC.*"
    RewriteRule (.*) $1index.m3u8 [R=301,L]

    ProxyPassMatch  ^/streamradio/(.*)$ http://localhost:8888/$1

</Virtualhost>
```

Now we can access streams in Browser and VLC like this:
```
https://example.com/streamradio/shroud
```

# Playlist

Example for a simple playlist file.

**streamradio.m3u**
```
#EXTM3U
#PLAYLIST: streamradio

#EXTINF:-1,twitch.tv/shroud
https://example.com/streamradio/t/shroud/index.m3u8

#EXTINF:-1,youtube.com/@ESLCS
https://example.com/streamradio/y/ESLCS/index.m3u8
```

# Disclaimer

This program is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Twitch or Youtube.
All product and company names are trademarks™ or registered® trademarks of their respective holders.