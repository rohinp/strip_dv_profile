# Strip Dolby Vision (Profile 5/7) → Keep HDR10  
### Manual Script for LG OLED TVs (e.g. LG OLED65B9PLA)

This script fixes **Dolby Vision playback issues on LG OLED TVs** by:

- **Detecting Dolby Vision profile**
- **Only stripping incompatible profiles (Profile 5 and 7)**
- **Leaving compatible Dolby Vision Profile 8.1 untouched**
- Keeping:
  - HEVC video (no re-encode)
  - HDR10 base layer
  - Audio tracks
  - Subtitles
  - Chapters

✅ Result: Files play perfectly on LG OLED TVs (B9, C9, CX, etc.)  
❌ No purple/green tint, no black screen, no playback fallback

---

## Why this is needed

LG OLED TVs **do not support Dolby Vision Profile 5 from local files**  
(Profile 5 is designed for streaming services like Netflix).

| Dolby Vision Profile | Action |
|---------------------|--------|
| No DV               | Do nothing |
| DV Profile 8.1      | Leave as-is (supported by LG) |
| DV Profile 5        | Strip DV → keep HDR10 |
| DV Profile 7        | Strip DV → keep HDR10 (recommended) |

---

## Requirements

### Operating System
- Linux (Ubuntu / Debian recommended)
- Works on bare metal, Docker host, NAS, or media server

---

## Install Dependencies (one-time)

### 1. Install ffmpeg, mediainfo, jq
```bash
sudo apt update
sudo apt install -y ffmpeg mediainfo jq
````

Verify:

```bash
ffmpeg -version
mediainfo --version
jq --version
```

---

### 2. Install `dovi_tool`

`dovi_tool` is required to safely remove Dolby Vision metadata while keeping HDR10.

```bash
wget https://github.com/quietvoid/dovi_tool/releases/latest/download/dovi_tool-linux-x86_64
sudo mv dovi_tool-linux-x86_64 /usr/local/bin/dovi_tool
sudo chmod +x /usr/local/bin/dovi_tool
```

Verify:

```bash
dovi_tool --help
```

---

## Script Installation

### 1. Create the script file

```bash
nano strip_dv_keep_hdr10.sh
```

Paste the script contents (provided separately).

---

### 2. Make the script executable

```bash
chmod +x strip_dv_keep_hdr10.sh
```

---

## How to Use

### ▶ Process a single file

```bash
./strip_dv_keep_hdr10.sh "Movie.Name.2160p.DV.mkv"
```

### ▶ Process an entire folder

```bash
./strip_dv_keep_hdr10.sh "/media/movies/4K"
```

The script will:

* Scan each MKV/MP4 file
* Act **only when DV Profile 5 or 7 is detected**
* Skip all other files safely

---

## Output Files

* Output files are created **next to the original**
* Naming format:

```
Original: Movie.mkv
Output:   Movie.HDR10.mkv
```

👉 Originals are **not deleted automatically** (for safety).

---

## Verification (Important)

Check the output file:

```bash
mediainfo Movie.HDR10.mkv
```

Expected:

* ❌ No Dolby Vision
* ✅ HDR10
* HEVC 10-bit
* BT.2020 / PQ

On LG OLED TV:

* HDR popup appears
* Smooth playback
* Correct colors

---

## Safety Notes

* No re-encoding → no quality loss
* Original file is untouched
* Script skips:

  * Non-DV files
  * DV Profile 8.1 files
  * Unknown DV profiles

---

## Tested Use Case

* LG OLED65B9PLA
* Plex / USB / DLNA playback
* 4K HEVC MKV files
* Tdarr-compatible workflows (manual pre-processing)

---

## Optional Improvements (Future)

* Dry-run mode
* Auto-delete original after verification
* CSV logging
* DV Profile 5 → Profile 8.1 conversion
* Tdarr integration hook

---

## Disclaimer

Use at your own risk.
Always test on a single file before batch processing.

---

## License

Free to use and modify for personal media libraries.

