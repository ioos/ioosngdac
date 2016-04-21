#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
tests/test_slocum_reader.py

Tests for the SlocumReader
'''

from unittest import TestCase
from ioosngdac.readers.slocum_reader import SlocumReader

import os


class TestSlocumReader(TestCase):
    '''
    Test the slocum reader
    '''

    def test_extractor(self):
        '''
        Ensure the archive unzipping works
        '''

        reader = SlocumReader('tests/data/ru28-458-sbd-ascii.zip')
        assert os.path.exists(reader.path)
        assert os.path.exists(os.path.join(reader.path, 'ru28_2015_267_0_35_sbd.dat'))

        reader = SlocumReader('tests/data/ru28-458-sbd-ascii.tar.gz')
        assert os.path.exists(reader.path)
        assert os.path.exists(os.path.join(reader.path, 'ru28_2015_267_0_35_sbd.dat'))

