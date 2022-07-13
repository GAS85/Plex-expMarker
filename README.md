# Plex-expMarker

Wondering how to [Auto-delete watched episodes series](https://forums.plex.tv/t/change-delete-episodes-after-watching-default-behaviour/199807)?
This is a script to automatically mark **all** Series with expiration time.
You need to set Plex URL, Plex Port and [Plex Token](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/).

## Configuration

You can set how long plex will save your Series after you watch it via config `keepDays` value, or as parameter e.g. `-k 7`. Possible values are:

- 0 - keep forever, no autodelete at all
- 1 - one day
- 7 - one Week
- 100 - Remove with a next Scan

Other values could be experimental.

Use `-h` for help, `-d` for dry run or `-s` to see current configuration.

- `PlexDomain="https://192.168.0.9"` Plex URL,
- `PlexPort="32400"` Plex Port if different from standard,
- `IgnoreCertificate=false` If using https with a self-signed Certificate - enable Certificate ignoring,
- `PlexToken="xxxxxxxxxxxxx"` Plex Token.

## Usage example

### Dry Run

Do not change anything, but see possible changes.

```shell
./plex-set-series-expiration-time.sh -d
Mi 13. Jul 10:39:39 CEST 2022 - INFO - Dry Run, will not change anything, only show output with possible changes.
Mi 13. Jul 10:39:39 CEST 2022 - INFO - Successfully connected to Host under https://192.168.0.9:32400.
Mi 13. Jul 10:39:39 CEST 2022 - INFO - Found 5 items to work with from 17 items at all.
Mi 13. Jul 10:39:39 CEST 2022 - INFO - "Vikings" with ID 6023 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:39 CEST 2022 - INFO - "Американская семейка" with ID 8531 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Друзья" with ID 6047 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Летающий цирк Монти Пайтона" with ID 6033 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Лучше звоните Солу" with ID 8504 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:41 CEST 2022 - INFO - Finished.
```

### Direct run

```shell
./plex-set-series-expiration-time.sh -k 7
Mi 13. Jul 10:39:39 CEST 2022 - INFO - Successfully connected to Host under https://192.168.0.9:32400.
Mi 13. Jul 10:39:39 CEST 2022 - INFO - Found 5 items to work with from 17 items at all.
Mi 13. Jul 10:39:39 CEST 2022 - INFO - "Vikings" with ID 6023 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:39 CEST 2022 - INFO - "Американская семейка" with ID 8531 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Друзья" with ID 6047 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Летающий цирк Монти Пайтона" with ID 6033 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:40 CEST 2022 - INFO - "Лучше звоните Солу" with ID 8504 found. Auto Delete Policy set to 7 day(s).
Mi 13. Jul 10:39:41 CEST 2022 - INFO - Finished.
```

### Via Cron

Depends on your preferences you can add this script to be run once a week or once in month in your crontab. E.g.

```shell
@weekly /usr/local/bin/plex-set-series-expiration-time.sh
```

```shell
@monthly /usr/local/bin/plex-set-series-expiration-time.sh
```
