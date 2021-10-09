# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import os
import pandas as pd
import numpy as np 
import matplotlib.pyplot as plt
import datetime


os.chdir('./Documents/DS4A')

#%% Read in data 
ucl_df = pd.read_csv('./Data/cov19tracker_cleaned.csv')
ucl_df.describe()

#%% Drop rows with no data
ucl_df['household_size'].value_counts()
ucl_df['household_children'].value_counts()

ucl_df = ucl_df[ucl_df['household_children']!='Prefer not to say']
ucl_df = ucl_df[ucl_df['household_children']!="Don't know"]

ucl_df['household_children'].value_counts()

#%% divide datasets to pre-vaccine and post-vaccine 
ucl_df['year-month'].value_counts()
ucl_df['year-month'] = pd.to_datetime(ucl_df['year-month'])

vaccine_date = datetime.datetime(2021, 5, 1)
pre_vaccine = ucl_df[ucl_df['year-month'] < vaccine_date ]
post_vaccine = ucl_df[ucl_df['year-month'] >= vaccine_date ]

#%% Histogram of Household Children
plt.xlim([0, 10])
plt.hist(pre_vaccine['household_children'], bins=range(0,10))
plt.show()

plt.xlim([0, 10])
plt.hist(post_vaccine['household_children'], bins=range(0,10))
plt.show()

#%% Histogram of Household size 
plt.xlim([0, 20])
plt.hist(pre_vaccine['household_size'], bins=range(0,20))
plt.show()

plt.xlim([0, 20])
plt.hist(post_vaccine['household_size'], bins=range(0,20))
plt.show()
