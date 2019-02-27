#!/usr/bin/env python
# -*- coding: utf-8 -*-

import urllib.request
import os
import string
import csv

#  path=os.getcwd()+"/../../data/"
path="/home/ollin/Documentos/migration/data/"

data = ["asylum_seekers_monthly.csv",
        "persons_of_concern.csv",
        "demographics.csv",
        "asylum_seekers.csv",
        "resettlement.csv"]

def get_file(files):
    url = "http://popstats.unhcr.org/en/"+files
    response = urllib.request.urlretrieve(url,path+"raw/"+files)

def remove_header(files):
    n = 0
    with open(path+"raw/"+files,'rb') as fin,\
            open(path+"clean/"+files, 'w') as fout:
        for line in fin:
            n += 1
            line = line.decode('Latin-1')
            if n > 3:
                fout.write(line)

if __name__ == '__main__':
    for name in data:
        get_file(name)
        remove_header(name)

