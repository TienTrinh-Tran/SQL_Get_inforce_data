# -*- coding: utf-8 -*-
"""
Created on Fri Mar 15 09:35:51 2019
Major Update on Wed Jan 23 2020 for GW data

@author: ttrinhtran
"""

import pandas as pd
import numpy as np
import pymssql
import time

start_time=time.time()

"""Queries to retrieve data from HDB"""

#--Get inputs from user--#
#pw = input('Please enter password: ' ).upper()

#--Create connection--#
con = pymssql.connect(server='xyz')

st = 'CO'
#tbl = '[HIS_User2].[CCMC\jgalebach].[OLPRIF_STAGING_WA_VHCL_RERTD_WITHCAP]' #[HIS_User2].[CCMC\syao].[OLPRIF_STAGING_MN_VHCL_RERTD_WITHCAP]

#curr_str = "SET @state = 'IN'"
#new_str = "SET @state = '%s'" %st

#curr_tbl = "FROM [HIS_User2].[CCMC\elopez].[OLPRIF_STAGING_IN_VHCL_RERTD]"
#new_tbl = "FROM %s" %tbl
  
with open("SQL\GW_tables\Pol_Veh_data_GW.sql", "r") as myfile:
    Pol_Veh = myfile.read()
#    Pol_Veh = Pol_Veh.replace(curr_str, new_str) 
#    Pol_Veh = Pol_Veh.replace(curr_tbl, new_tbl) 
Pol_Veh_df0 = pd.read_sql_query(Pol_Veh, con) 
Pol_Veh_df = Pol_Veh_df0
       
with open("SQL\GW_tables\Limit_Ded_Prem_data_GW.sql", "r") as myfile:
    Lim_Ded_Prem = myfile.read()
#    Lim_Ded_Prem = Lim_Ded_Prem.replace(curr_str, new_str)
#    Lim_Ded_Prem = Lim_Ded_Prem.replace(curr_tbl, new_tbl)
Lim_Ded_Prem_df = pd.read_sql_query(Lim_Ded_Prem, con)

with open("SQL\GW_tables\Driver_data_GW.sql", "r") as myfile:
    Driver_data = myfile.read()
#    Driver_data = Driver_data.replace(curr_str, new_str)    
Driver_df = pd.read_sql_query(Driver_data, con)

"""Putting results together"""

mask1 = Lim_Ded_Prem_df.filter(items=['Pol_Num', 'Pol_Symbol', 'Unit'],axis=1)
mask2 = Lim_Ded_Prem_df.filter(like='Prem',axis=1)
mask3 = Lim_Ded_Prem_df.filter(like='Limit',axis=1)
Pol_Veh_Premium = pd.concat([mask1,mask2],axis=1)
Pol_Veh_LimDed = pd.concat([mask1,mask3],axis=1)
Pol_Veh_df1 = pd.merge(Pol_Veh_df,Pol_Veh_LimDed,how='left',
                          left_on=['POLICY_NUMBER','POLICY_SYMBOL','Vehicle #'],
                          right_on=['Pol_Num','Pol_Symbol','Unit'])

#--Drop columns and rename--#
Pol_Veh_df1 = Pol_Veh_df1.drop(['Pol_Num','Pol_Symbol','Unit'], axis=1)

col_lim_dict = {'BI_Limit':'BI',
            'PD_Limit':'PD',
            'MP_Limit':'MP',
            'UMB_Limit':'UM',
            'UIM_Limit':'UIM',
            'UMP_Limit':'UMP',
            'UIMPD_Limit':'UIMPD',
            'CMP_Limit':'CMP',
            'COL_Limit':'COL',
            'PIP_Limit':'PIP',
            'PIPAdd_Limit':'APIP',
            'ILB_Limit':'Work Loss',
            'ADB_Limit':'Auto Death',
            'TDB_Limit':'Total Disability Benefits (TDB)',
            'FUN_Limit':'Funeral',
            'TL_Limit':'T&L',
            'TE_Limit':'Transporation Expense (TE)',
            'EEE_Limit':'Excess Electronic Equ. (EEE)',
            }
Pol_Veh_df1.rename(index=str, columns= col_lim_dict, inplace=True)

#--Change Unknown value in Prior_BI_Limit to current BI limit if Renewalbusiness--#

def prior_lim (x, y):
    if pd.isna(y):
        return x
    elif x == 'Unknown':
        return y
    else:
        return x
    
Pol_Veh_df1.rename(columns={'Prior BI Limit': 'Prior_BI_Lim_org'}, inplace=True)
#Pol_Veh_df1 = np.where(Pol_Veh_df1['Prior_BI_Lim_org'] == 'Unknown' & Pol_Veh_df1['BI'] != '', Pol_Veh_df1['BI'], Pol_Veh_df1['Prior_BI_Lim_org'])
Pol_Veh_df1['Prior BI Limit'] =  Pol_Veh_df1.apply(lambda x: prior_lim(x['Prior_BI_Lim_org'],x['BI']),axis=1) 
#--Move UM/UIM Stacking for PA & UM STD/ENH for MD to appropriate columns--#
if st in ('MD','PA'):
    try:
        Pol_Veh_df1.rename(columns={'UM': 'UM_org', 'UIM': 'UIM_org'}, inplace=True) #
        Pol_Veh_df1[['UM','Stack/Option 1']] = Pol_Veh_df1['UM_org'].str.split(" ",expand=True)
        Pol_Veh_df1[['UIM','Stack/Option 2']] = Pol_Veh_df1['UIM_org'].str.split(" ",expand=True)
#        Pol_Veh_df1 = Pol_Veh_df1.drop(['UM_org'], axis=1) #don't drop in case need to see in the output
#        Pol_Veh_df1 = Pol_Veh_df1.drop(['UIM_org'], axis=1) #don't drop in case need to see in the output        
    except:
        pass

#--Move MP limit to MP, CMB & EMB columns accordingly--#
if st in ('PA'):
    Pol_Veh_df1.rename(columns={'MP': 'MP_org'}, inplace=True) #
    Pol_Veh_df1['MP'] = Pol_Veh_df1['MP_org'].apply (lambda x: '' if (x == '177.5' or x == '177.5EM') else x)
    Pol_Veh_df1['MP'] = Pol_Veh_df1['MP'].apply (lambda x: 100000 if (x == '100EM') else x)
    Pol_Veh_df1['CMB (PA Combined Medical)'] = Pol_Veh_df1['MP_org'].apply (lambda x: 177500 if (x == '177.5' or x == '177.5EM') else '')
    Pol_Veh_df1['EMB (PA Extraordinary Medical Benefits)'] = Pol_Veh_df1['MP_org'].apply (lambda x: 'EMB' if (x == '100EM' or x == '177.5EM') else '')       
#    Pol_Veh_df1['MP'] = Pol_Veh_df1['MP'].replace('100EM',100000) #this works as well

#--Split PIP for MN to PIP, PipDed, Stack/Option 1, Work Loss; CMP to CMP & CMP Full Glass columns--#
    #updated 12/6 to include AZ, don't need to split Pip & CMP into 2 separate lines, but need to re-arrange the steps, else CMP won't split 
    #when it command for Pip fails, it stops trying = all the subsequent steps in try won't be executed
    
if st in ('AZ','MN'): 
    try:
        Pol_Veh_df1.rename(columns={'PIP': 'PIP_org', 'CMP': 'CMP_org'}, inplace=True) #this doesn't fail for AZ even AZ has no Pip, and doesn't stop try
#        Pol_Veh_df1.rename(columns={'CMP': 'CMP_org'}, inplace=True) # 
#        Pol_Veh_df1.rename(columns={'PIP': 'PIP_org'}, inplace=True) #        
        Pol_Veh_df1[['CMP','CMP Full Glass']] = Pol_Veh_df1['CMP_org'].str.split(" ",expand=True) #need to move this line from the bottom to here        
        Pol_Veh_df1[['PIP','Work Loss','PIP Deductible','Stack/Option 1']] = Pol_Veh_df1['PIP_org'].str.split(" ",expand=True)
#        Pol_Veh_df1[['CMP','CMP Full Glass']] = Pol_Veh_df1['CMP_org'].str.split(" ",expand=True) #was here before adding AZ  
    except:
        pass

#--Calculate # of vehicles and create index--#                                  
Pol_Veh_df1['Pol_Num'] = Pol_Veh_df1['POLICY_NUMBER'].astype(int)
Pol_Veh_df1['Veh_Num'] = Pol_Veh_df1.groupby('POLICY_NUMBER').cumcount()+1  
Pol_Veh_df1['# of Processed Rated Vehicles'] = Pol_Veh_df1.groupby('POLICY_NUMBER')['POLICY_NUMBER'].transform('count') 
Pol_Veh_df1 = Pol_Veh_df1.set_index(['Pol_Num','Veh_Num'])

#--Calculate # of drivers and create index--#  
Driver_df1 = Driver_df.copy()
Driver_df1['Pol_Num'] = Driver_df1['POLICY_NUMBER'].astype(int)
Driver_df1['Drv_Num'] = Driver_df.groupby('POLICY_NUMBER').cumcount()+1
Driver_df1['# of Processed Rated Drivers'] = Driver_df1.groupby('POLICY_NUMBER')['POLICY_NUMBER'].transform('count') 
Driver_df1 = Driver_df1.drop(['EVAL_DATE','POLICY_NUMBER','ST_ABB','POLICY_EFF_DATE','POLICY_EXP_DATE','RTNG_FIRST_POLICY_DATE'], axis=1)
Driver_df1 = Driver_df1.set_index(['Pol_Num','Drv_Num'])


#--Get MY from Pricing if the MY from Auto-Staging returns Null--# 
    #--this happens because we use OLPRIF evaluation date is slightly different from Staging (monthly)--#
#Pol_Veh_df1['Model Year'] = Pol_Veh_df1['Model Year Pricing'].apply (lambda x: '' if (x == '177.5' or x == '177.5EM') else x)
  

#--Combine Policy, Vehicle & Driver data--# 
pol_veh_drv_df = pd.concat([Pol_Veh_df1,Driver_df1], axis=1)

#--create a loop to fill na by ffill for some columns--# 
col_to_fillna = ['POLICY_NUMBER','# of Processed Rated Drivers','# of Processed Rated Vehicles'] #,'Total Drivers','Total Vehicles'] #4/30: stop fill na for # dri # veh
                 
for nacol in col_to_fillna:
    pol_veh_drv_df[nacol] = pol_veh_drv_df[nacol].fillna(method='ffill') #TT: need to fix this, when no driver, it takes the count from the previous pol

#--Date comes from SQL is in string format, need to convert to datatime, and also take only the date not time part--#
col_to_format_date = ['Policy Effective Date','Auto ORG Date','Loyalty Date',
                      'Prior Carrier ORG Date','Driver DOB']
for coldt in col_to_format_date:
    pol_veh_drv_df[coldt] = pol_veh_drv_df[coldt].apply(pd.to_datetime).dt.date #comment out due to error

#--Convert data (coming from SQL) from string to numeric/numbers--#
col_to_convert = ['RISK_STATE','POLICY_NUMBER','POLICY_SYMBOL','Vehicle Index', 'Persistency in months',
                  'PD','MP','UMP','CMP','COL','PIP', 'Work Loss', 'Acc Death', 'Auto Death', 'Funeral',
                  'SYM','SYM CMP','SYM COL','BIPD LPMP SYM','PIPMED LPMP SYM','MC Engine Size (in cc)','Model Year',
                  'ZIP Code','Annual Mileage','MC Assigned Driver Age','CLIENT_ID']

for col in col_to_convert:
    try:
        pol_veh_drv_df[col] = pol_veh_drv_df[col].apply(pd.to_numeric, errors='ignore')
    except:
        pass

#--Create empty columns, formatting on pol_veh_drv_df--#
df = pd.read_excel ('Var_List_Order_GW.xlsx', sheet_name='Sit_Order',header=None)

newcols = list(df[0])

for each in newcols:
    if each not in(pol_veh_drv_df.columns):
        pol_veh_drv_df[each] = ''
pol_veh_drv_df = pol_veh_drv_df[newcols]

#--Format T/F columns--#
def T_F (x):
    if x == 'TRUE':
        return True
    elif x == 'FALSE':
        return False
    else:
        return x
col_to_T_F = ['Prior Insurance','Go PaperLess Discount', 'Tort included','Stack/Option 1', 'Stack/Option 2',
              'Passive Restraint Discount','Anti-lock Brake Discount','Package Discount Type',
              'Anti-theft Discount','Loan/Lease','MC/MH Mature/Defensive Driver Indicator'
              ,'Away At School','Good Student', 'Work Loss', 'CMP Full Glass',
              'Driver Training','SR-22','College Graduate','Mature/Defensive']
for column in col_to_T_F:
    pol_veh_drv_df[column] = pol_veh_drv_df[column].apply(T_F)

#--Convert Rate Level to proper type for Rater to read--#            
def two_three (x):
    if x == '2':
        return 2
    elif x == '3':
        return 3
    else:
        return x
pol_veh_drv_df['Rate Level'] = pol_veh_drv_df['Rate Level'].apply(two_three)
  

#--Reorder coverage Premium columns on Pol_Veh_Premium--#
#try:
#    Pol_Veh_Premium = Pol_Veh_Premium.apply(pd.to_numeric, errors='ignore') #use try still doesn't work
#except:
#    pass
Pol_Veh_Premium = Pol_Veh_Premium.apply(pd.to_numeric, errors='ignore')
#Pol_Veh_Premium.loc[:,Pol_Veh_Premium.columns != ']

df1 = pd.read_excel ('Var_List_Order_GW.xlsx', sheet_name='Prem_Order',header=None)
newcols1 = list(df1[0])

newcols1x = []
for item in newcols1:
    if item in Pol_Veh_Premium.columns:
        newcols1x.append(item)
Pol_Veh_Premium = Pol_Veh_Premium[newcols1x]

"""Write results to Excel file"""

#--Write data--#
writer = pd.ExcelWriter(r'Results\%s_Inforce_Data_GW.xlsx' %(st), engine='xlsxwriter')
#Pol_Veh_df0.to_excel(writer,'Pol_Veh_data')
#Lim_Ded_Prem_df.to_excel(writer,'Limit_Ded_Prem_data')
#Driver_df.to_excel(writer,'Driver_data')
Pol_Veh_Premium.to_excel(writer,'Premium')
pol_veh_drv_df.to_excel(writer,'Situations')

#--Formatting--#
wb  = writer.book
format0 = wb.add_format({'bg_color': 'yellow'})



writer.sheets['Premium'].freeze_panes('E2')
writer.sheets['Situations'].freeze_panes('N2') 
writer.sheets['Situations'].set_column('C:E', None, None, {'level': 1, 'hidden': True})
writer.sheets['Situations'].autofilter('A1:EG1') 
#writer.sheets['Situations'].write('I1', None, format0) #this stupid one will overwirte the content in the cell too
#writer.sheets['Situations'].write('DJ1', None, format0)
#format1 = wb.add_format({'text_wrap':True}) 
#format1.set_text_wrap() #need to use this if nothing inside bracket in the line above
#writer.sheets['Situations'].write('A1:DP1', None, format1)
#writer.sheets['Situations'].set_selection('DJ1')
writer.sheets['Situations'].conditional_format('I1:DZ1', {'type':'no_errors','format':format0})
#pd.formats.format.header_style = None

writer.save()

runtime = round(time.time() - start_time, 0)
minutes = round(runtime // 60)
seconds = round(runtime % 60)
print("Process took %dm:%ds" %(minutes, seconds))
print('Complete!')

