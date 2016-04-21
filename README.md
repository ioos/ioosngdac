IOOS Glider DAC V2
==================

Documents describing the version 2.0 file format and design of the
Integrated Ocean Observing System National Glider Data Assembly Center.

##Contents##
- [Documentation](https://github.com/kerfoot/ioosngdac/wiki)
- [Links](#links)
- [Data Access](#data-access)

###Links###

- [Documentation](https://github.com/kerfoot/ioosngdac/wiki)
- [Links for Data Providers](https://github.com/ioos/ioosngdac/wiki/Links-for-Data-Providers)
- [Links for Data Consumers](https://github.com/ioos/ioosngdac/wiki/Links-for-Data-Consumers)

###Data Access###
The IOOS National Glider Data Assembly Center provides access to all submitted data sets through 2 services:

- __ERDDAP Data Set Access__: http://data.ioos.us/gliders/erddap/tabledap/index.html
- __THREDDS Data Set Access__: http://data.ioos.us/gliders/thredds/catalog.html


ioosngdac
=========

This repository also comes with of python packages for the purpose of interfacing with glider data and the GliderDAC.

MIT License

Copyright (C) 2016 RPS ASA

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Development and Testing
=======================

Data files are somewhat large and not managed by git source control. To download these files execute the following:

```
curl -s -o tests/data/ru28-458-sbd-ascii.zip https://asa-dev.s3.amazonaws.com/ioosngdac/data/ru28-458-sbd-ascii.zip
curl -s -o tests/data/ru28-458-sbd-ascii.tar.gz https://asa-dev.s3.amazonaws.com/ioosngdac/data/ru28-458-sbd-ascii.tar.gz
```


