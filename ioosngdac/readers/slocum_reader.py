#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Readers for SLOCUM ASCII-Format
'''
from __future__ import print_function

from zipfile import ZipFile
import tarfile
import tempfile
import os
import shutil


class SlocumReader(object):
    '''
    A Reader for slocum ASCII files
    '''

    def __init__(self, path):
        '''
        :param str path: Path to an archive or a folder containing the ASCII dat files
        '''
        self.cleanup = False
        self.is_open = False

        if not os.path.exists(path):
            raise IOError("Failed to open {} file doesn't exist".format(path))

        if os.path.isdir(path):
            self.path = path
            self.is_open = True
        else:
            self.load_from_archive(path)

    def load_from_archive(self, path):
        '''
        Loads data files from an archive
        '''
        if self.is_open:
            raise IOError("Reader is already open")

        # Create a temporary folder and mark this object as dirty
        dirpath = tempfile.mkdtemp()
        self.path = dirpath
        self.cleanup = True

        if path.endswith('.zip'):
            self.extract_zipfile(path, dirpath)
        elif path.endswith('.tar.gz'):
            self.extract_tgz(path, dirpath)

    @classmethod
    def extract_zipfile(cls, path, dirpath):
        '''
        Loads a zip archive

        :param str path: Path to zip archive to load
        :param str dirpath: Directory to unzip to
        '''
        with ZipFile(path, 'r') as zfile:
            for member in zfile.namelist():
                head, tail = os.path.split(member)
                zfile.extract(member, os.path.join(dirpath, tail))

    @classmethod
    def extract_tgz(cls, path, dirpath):
        '''
        Loads a .tar.gz file

        :param str path: Path to .tar.gz archive to load
        :param str dirpath: Directory to unzip to
        '''

        with tarfile.open(path, 'r:*') as zfile:
            for member in zfile.getnames():
                head, tail = os.path.split(member)
                zfile.extract(member, os.path.join(dirpath, tail))

    def __del__(self):
        '''
        Cleans up any temporary files
        '''

        if self.cleanup:
            shutil.rmtree(self.path)

