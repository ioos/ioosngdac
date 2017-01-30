#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Setup file for the ioosngdac package
'''

from setuptools import find_packages, setup
from ioosngdac import __version__

def readme():
    '''
    Returns the README document as a string
    '''
    with open('README.md', 'r') as f:
        return f.read()

def requirements():
    with open('requirements.txt') as f:
        return [line.strip() for line in f]

setup(
        name="ioosngdac",
        version=__version__,
        description='Tools and python modules for working with Glider data and the GliderDAC',
        long_description=readme(),
        license='MIT',
        author='Luke Campbell',
        author_email='luke.s.campbell@gmail.com',
        url='https://github.com/ioos/ioosngdac/',
        packages=find_packages(),
        install_requires=requirements(),
        tests_require=['pytest'],
        classifiers          = [
            'Development Status :: 5 - Production/Stable',
            'Intended Audience :: Developers',
            'Intended Audience :: Science/Research',
            'License :: OSI Approved :: Apache Software License',
            'Operating System :: POSIX :: Linux',
            'Programming Language :: Python',
            'Topic :: Scientific/Engineering',
        ]
)


