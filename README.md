# Taichung Hospital consultation room called patient number monitoring

Fetch and present the current called patient number of the specified [Taichung Hospital](https://www.taic.mohw.gov.tw/) consultation room for the convenience to handle the timing for the patient to wait at the spot.

<https://gitlab.com/brlin/taichung-hospital-consultation-room-called-patient-number-monitoring>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/taichung-hospital-consultation-room-called-patient-number-monitoring/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/taichung-hospital-consultation-room-called-patient-number-monitoring/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/taichung-hospital-consultation-room-called-patient-number-monitoring/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/taichung-hospital-consultation-room-called-patient-number-monitoring/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/taichung-hospital-consultation-room-called-patient-number-monitoring "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/taichung-hospital-consultation-room-called-patient-number-monitoring)

## Notice

Before using this application please note that:

* This solution only fetches the called patient number information, the patient should adhere to the hospital consultation room's check-in instructions to avoid losing the qualification of the specialist consultation.
* Please properly set this utility's polling behavior settings to avoid overloading the hospital's IT system.
* This is NOT an official Taichung Hospital product, the author CAN NOT and WILL NOT provide compensation of any damages relating to the usage of this application.

## Environment variables to change the monitoring utility's behavior

The following environment variables can adjst the monitoring program's behavior according to the user's need:

### CHECK_INTERVAL_BASE

The base interval for the monitoring polling(unit: seconds).

Default value: `15`

### CHECK_INTERVAL_VARIANCE_MAX

The max variance value to assigning the polling interval some  randomness(unit: seconds).

The actual interval of each polling will be `CHECK_INTERVAL_BASE` + (random number % `CHECK_INTERVAL_VARIANCE_MAX` + 1) seconds.

Default value: `10`

### CHECK_URL

The Taichung Hospital consultation room patient calling status page to monitor, to acquire the URL browse [the consultation room patient calling feature page](https://www03.taic.mohw.gov.tw/RegMobileWeb/Home/RegRoomList?Flag=Y), select the proper department and doctor's name, and copy the URL of the page that contains the "目前看到" column name.

Default value: (None)  
Example value: `https://example.taic.mohw.gov.tw/RegMobileWeb/Home/RegRoom?cateId=1234&drId=5678`

### CHECK_TIMEOUT

The timeout time of the HTTP request used for monitoring(unit: seconds).

Corresponding to the `--max-time` command-line option of the curl software.

Defualt value: `30`

## References

* [看診進度](https://www03.taic.mohw.gov.tw/RegMobileWeb/Home/RegRoomList?Flag=Y)  
  The consultation room patient calling status page of the Taichung Hospital.
* curl(1) manpage  
  Explains how to use the curl HTTP client utility
* xgettext(1) manpage  
  Explains how to use the `xgettext` command to extract translatable strings from the source code file.
* msginit(1) manpage  
  Explains how to use the `msginit` command to create a new PO message catalog file from the POT template file.
* msgfmt(1) manpage  
  Explains how to use the `msgfmt` command to compile message catalog files into the binary format.
* notify-send(1) manpage  
  Explains how to use the `notify-send` command to send desktop notifications.

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the 4.0 International version of the Creative Commons Attribution-ShareAlike license](https://creativecommons.org/licenses/by-sa/4.0/), or any of its more recent versions of your preference.

This work complies to the [REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
