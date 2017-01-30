#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
A simple true==true test to ensure the build succeeded
'''

from unittest import TestCase


class TestBuild(TestCase):
    '''
    TestCase which returns true
    '''

    def test_build(self):
        assert True
