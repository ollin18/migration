#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import urllib.request
import os
import json
import string
import csv
import pandas as pd

path="./data/"
#  import sys
#  reload(sys)
#  sys.setdefaultencoding('UTF8')

with urllib.request.urlopen("https://gist.githubusercontent.com/erdem/8c7d26765831d0f9a8c62f02782ae00d/raw/248037cd701af0a4957cce340dabb0fd04e38f4c/countries.json") as url:
    countries = json.loads(url.read().decode())

names = list(map(lambda x: x['name'],countries))
codes = list(map(lambda x: x['country_code'],countries))
latlng = list(map(lambda x: x['latlng'],countries))
lat = list(map(lambda x: x[0],latlng))
lon = list(map(lambda x: x[1],latlng))

cols = {'Country':names,'Code':codes,'lat':lat,'lon':lon}

Countries = pd.DataFrame.from_dict(cols)
Countries.to_csv(path+"countries.csv",index=False,header=False,sep="|")

fix = {"Dem. Rep. of the Congo":"DR Congo",
       "Congo":"Republic of the Congo",
       "Saint-Pierre-et-Miquelon":"Saint Pierre and Miquelon",
       "Sao Tome and Principe":"São Tomé and Príncipe",
       "Rep. of Moldova":"Moldova",
       "Holy See (the)":"Vatican City",
       "US Virgin Islands":"United States Virgin Islands",
       "United Kingdom of Great Britain and Northern Ireland":"United Kingdom",
       "Niger":"Nigeria",
       "Brunei Darussalam":"Brunei",
       "Cabo Verde":"Cape Verde",
       "Palestinian":"Palestine",
       "Viet Nam":"Vietnam",
       "Samoa":"American Samoa",
       "Russian Federation":"Russia",
       "Serbia and Kosovo (S/RES/1244 (1999))" : "Serbia",
       "Serbia and Kosovo: S/RES/1244 (1999)" : "Kosovo",
       "Czech Rep.":"Czech Republic",
       "Micronesia (Federated States of)":"Micronesia",
       "Rep. of Korea":"South Korea",
       "Dem. People's Rep. of Korea":"North Korea",
       "United States of America" : "United States",
       "China, Macao SAR":"Macau",
       "Central African Rep." : "Central African Republic",
       "Lao People's Dem. Rep." : "Laos",
       "Sint Maarten (Dutch part)":"Sint Maarten",
       "The former Yugoslav Republic of Macedonia":"Macedonia",
       "The former Yugoslav Rep. of Macedonia":"Macedonia",
       "China, Hong Kong SAR":"Hong Kong",
       "United Rep. of Tanzania" : "Tanzania",
       "Dominican Rep." : "Dominica",
       "Iran (Islamic Rep. of)":"Iran",
       "Venezuela (Bolivarian Republic of)":"Venezuela",
       "CuraÃ§ao":"Curaçao",
       "Bolivia (Plurinational State of)":"Bolivia",
       "Syrian Arab Rep." : "Syria",
       "CÃ´te d'Ivoire":"Ivory Coast",
       "Côte d'Ivoire":"Ivory Coast"
       }

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
            open(path+"raw/_"+files, 'wb') as fout:
        for line in fin:
            n += 1
            line = line.decode('Latin-1').encode('utf-8')
            if n > 3:
                fout.write(line)

def clean_countries(files):
    df = pd.read_csv(path+"raw/_"+files,low_memory=False)
    df = df.replace({"Country / territory of asylum/residence": fix})
    if 'Origin' in df.columns:
        df = df.replace({"Origin": fix})
    df.to_csv(path+"clean/"+files,index=False,header=False,sep="|")



if __name__ == '__main__':
    for name in data:
        get_file(name)
        remove_header(name)
        clean_countries(name)

