import csv
import os, sys
sys.path.append(os.path.join(os.path.dirname(__file__)))
ROOT_DIR = (os.path.dirname(os.path.abspath(__file__)))
datafile = ROOT_DIR +"/EURUSD-M5.csv"


import chardet
with open(datafile, 'rb') as rawdata:
    result = chardet.detect(rawdata.read(100000))
print(result)


import pandas as pd 
# Read data from file 'filename.csv' 
# (in the same directory that your python process is based)
# Control delimiters, rows, column names with read_csv (see later) 
data = pd.read_csv(datafile, encoding = "utf-16", sep=',')
data['Gmt time'] = data['Gmt time'].str.strip()
# Preview the first 5 lines of the loaded data 
#print(data.shape)
#print(data['Gmt time'])
print(data)