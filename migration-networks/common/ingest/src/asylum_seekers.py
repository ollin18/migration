#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import urllib.request
import zipfile
import requests
from time import strptime
import io
import os
import json
import string
import csv
import pandas as pd

path="/data"

with urllib.request.urlopen("https://gist.githubusercontent.com/erdem/8c7d26765831d0f9a8c62f02782ae00d/raw/248037cd701af0a4957cce340dabb0fd04e38f4c/countries.json") as url:
    countries = json.loads(url.read().decode())

names = list(map(lambda x: x['name'],countries))
codes = list(map(lambda x: x['country_code'],countries))
latlng = list(map(lambda x: x['latlng'],countries))
lat = list(map(lambda x: x[0],latlng))
lon = list(map(lambda x: x[1],latlng))

cols = {'Country':names,'lat':lat,'lon':lon,'co':codes}

Countries = pd.DataFrame.from_dict(cols)

with urllib.request.urlopen("https://query.data.world/s/ab2po6isxjxe25awy7eougitf3n5ga") as url:
    i = 0
    for line in url:
        if i == 4:
            columns = line.decode().replace("\"","").split(",")
            columns.pop()
            del columns[2:4]
            pop = pd.DataFrame(columns=columns)
        elif i > 4:
            row = line.decode().replace("\"","").split(",")
            if "COG" in row[2]:
                row[0] = "Congo"
            if "COD" in row[2]:
                row[0] = "DR Congo"
            if "PRK" in row[2]:
                row[0] = "North Korea"
            if "KOR" in row[2]:
                row[0] = "South Korea"
            rowcp = row.copy()
            row.pop()
            if len(row) ==  63:
                del row[1]
                del row[2:5]
                pop = pop.append(pd.Series(row,index=columns),ignore_index=True)
            elif len(row) == 62:
                del row[2:5]
                pop = pop.append(pd.Series(row,index=columns),ignore_index=True)
        i += 1

r = requests.get("http://api.worldbank.org/v2/en/indicator/NY.GDP.MKTP.CD?downloadformat=csv")
z = zipfile.ZipFile(io.BytesIO(r.content))
z.extractall(path+"/raw")
with open(path+"/raw/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_150998.csv", 'rb') as f:
    i = 0
    for line in f:
        if i == 4:
            columns = line.decode("utf-8").replace("\"","").split(",")
            columns.pop()
            del columns[2:4]
            gdp = pd.DataFrame(columns=columns)
        elif i > 4:
            row = line.decode("utf-8").replace("\"","").split(",")
            if "COG" in row[2]:
                row[0] = "Congo"
            if "COD" in row[2]:
                row[0] = "DR Congo"
            if "PRK" in row[2]:
                row[0] = "North Korea"
            if "KOR" in row[2]:
                row[0] = "South Korea"
            rowcp = row.copy()
            row.pop()
            if len(row) ==  64:
                del row[1]
                del row[2:4]
                gdp = gdp.append(pd.Series(row,index=columns),ignore_index=True)
            elif len(row) == 63:
                del row[2:4]
                gdp = gdp.append(pd.Series(row,index=columns),ignore_index=True)
        i += 1

pop = pop.rename(index=str, columns={"Country Name":"Country", "Country Code":"Code"})
gdp = gdp.rename(index=str, columns={"Country Name":"Country", "Country Code":"Code"})

for word in ["income","IBRD","only","total","blend","IDA","Not classified","members","World"]:
    pop=pop[~pop.Country.str.contains(word)]
    gdp=gdp[~gdp.Country.str.contains(word)]

drops = ["Arab World","Central Europe and the Baltics",
        "Channel Islands","Caribbean small states",
        'Early-demographic dividend','Latin America & Caribbean',
        'East Asia & Pacific','Least developed countries: UN classification',
        'Europe & Central Asia','European Union','Middle East & North Africa',
        'Late-demographic dividend','North America','Other small states',
        'Pre-demographic dividend','Pacific island small states',
        'Post-demographic dividend','South Asia','Sub-Saharan Africa',
        'Small states','West Bank and Gaza',
        'Euro area','Fragile and conflict affected situations',
        'Heavily indebted poor countries (HIPC)',
        ]

pop = pop[~pop["Country"].isin(drops)]
gdp = gdp[~gdp["Country"].isin(drops)]

fix_pop = {"Brunei Darussalam":"Brunei",
       "Cote d'Ivoire":"Ivory Coast",
       "Lao PDR":"Laos",
       "Virgin Islands (U.S.)":"United States Virgin Islands",
       "Syrian Arab Republic":"Syria",
       "St. Vincent and the Grenadines":"Saint Vincent and the Grenadines",
       "Sint Maarten (Dutch part)":"Sint Maarten",
       "Slovak Republic":"Slovakia",
       "Sao Tome and Principe":"São Tomé and Príncipe",
       "Russian Federation":"Russia",
       "St. Martin (French part)":"Saint Martin",
       "St. Lucia":"Saint Lucia",
       "St. Kitts and Nevis":"Saint Kitts and Nevis",
       "Congo":"Republic of the Congo",
       "Cabo Verde":"Cape Verde",
       "Kyrgyz Republic":"Kyrgyzstan",
       "Curacao":"Curaçao",
       "Hong Kong SAR":"Hong Kong",
       "Macao SAR":"Macau",
       "North Macedonia":"Macedonia",
       "Swaziland":"Eswatini",
       }

pop = pop.replace({"Country": fix_pop})
gdp = gdp.replace({"Country": fix_pop})

gdp = gdp.replace({"Code": {"XKX":"KSV"}})

Countries_pop = Countries.set_index("Country").join(pop.set_index("Country")).reset_index()
Countries_pop["Code"] = Countries_pop["Code"].fillna(Countries_pop["co"])
Countries_pop = Countries_pop.drop(["2016","co"],axis=1)
popu = pd.melt(Countries_pop.drop(["Code","lat","lon"],axis=1),id_vars=['Country']).fillna(0)

Countries_gdp = Countries.set_index("Country").join(gdp.set_index("Country")).reset_index()
Countries_gdp["Code"] = Countries_gdp["Code"].fillna(Countries_gdp["co"])
Countries_gdp = Countries_gdp.drop("co",axis=1)
gdp = pd.melt(Countries_gdp.drop(["Code","lat","lon"],axis=1),id_vars=['Country']).fillna(0)

Countries_pop.to_csv(path+"/clean/countries_pop.csv",index=False,header=False,sep="|")
popu.to_csv(path+"/clean/population.csv",index=False,header=False,sep="|")
Countries_gdp.to_csv(path+"/clean/countries_gdp.csv",index=False,header=False,sep="|")
gdp.to_csv(path+"/clean/gdp.csv",index=False,header=False,sep="|")

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
    response = urllib.request.urlretrieve(url,path+"/raw/"+files)

def remove_header(files):
    n = 0
    with open(path+"/raw/"+files,'rb') as fin,\
            open(path+"/raw/_"+files, 'wb') as fout:
        for line in fin:
            n += 1
            line = line.decode('Latin-1').encode('utf-8')
            if n > 3:
                fout.write(line)

def clean_countries(files):
    df = pd.read_csv(path+"/raw/_"+files,low_memory=False)
    df = df.replace({"Country / territory of asylum/residence": fix})
    if 'Origin' in df.columns:
        df = df.replace({"Origin": fix})
        df = df[df['Origin'].isin(names)]
    df = df[df['Country / territory of asylum/residence'].isin(names)]
    if 'Month' in df.columns:
        df["Month"] = df.Month.map(lambda x: strptime(x,'%B')[1])
    df.to_csv(path+"/clean/"+files,index=False,header=False,sep="|")


if __name__ == '__main__':
    for name in data:
        get_file(name)
        remove_header(name)
        clean_countries(name)
