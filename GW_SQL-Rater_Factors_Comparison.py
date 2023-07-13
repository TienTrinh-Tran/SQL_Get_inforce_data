# -*- coding: utf-8 -*-
"""
Created on Thu Apr  4 11:43:45 2019

@author: ttrinhtran

8/7/19: plan
--added blank row for MD
--create dict for cov by state
"""

import numpy as np
import pandas as pd
import pymssql
import time

#--Start timing--#
start_time=time.time()

#--GET inputs from user--#
pw = input('Please enter password: ' ).upper()
st = input('Please enter State, e.g. WA: ' ).upper()

#--Create connection--#
con = pymssql.connect(server=pw)

#--Set table parameter--#
tbl1 = '[HIS_User2].[CCMC\syao].[OLPRIF_STAGING_MO_VHCL_RERTD_202105]'
tbl2 = '[HIS_User2].[CCMC\syao].[OLPRIF_STAGING_MO_DRVR_RERTD_202105]'

#--Read the list of policies user wants to get factors--#
list_df = pd.read_excel ('List.xlsx', sheet_name='List')

#--Create the output Excel workbook--#
writer = pd.ExcelWriter('Results\%s_Pricing_calculated_GW_factors.xlsx' %(st), engine='xlsxwriter') 
wb  = writer.book
format1 = wb.add_format({'bold': True, 'color': 'red'})
format2 = wb.add_format({'bold': True, 'color': 'blue'})
format3 = wb.add_format({'bold': True, 'font_color': 'red', 'bg_color': 'yellow'})
format4 = wb.add_format({'bg_color': 'lime'})
format5 = wb.add_format({'bold': True, 'text_wrap': True, 'border': 1})
    
#--Output the list of policies into 1st sheet named List--#
list_df.to_excel(writer,'List', index=False, header=False, startrow=1)
ws = writer.sheets['List']
for col_num, value in enumerate(np.append(list_df.columns.values,['Rater Issue','Pricing Issue'])):
    ws.write(0, col_num, value, format5)
ws.set_column('F:F', 60)
ws.set_column('G:G', 60)

#--Create list of all columns corresponding to coverages applicable to state--#
input_df = pd.read_excel ('List.xlsx', sheet_name='Coverage')
st_cov = list(input_df.columns)
sort_order = dict(zip(st_cov,range(len(st_cov))))

#--Start the loop--#
for i in range(0,len(list_df)):

    #--parameters--#
    veh_type = list_df.iloc[i,1]
    pol_sym = list_df.iloc[i,2]
    unit = list_df.iloc[i,3]
    pol_num = list_df.iloc[i,4]


    #--Queries to retrieve data from Pricing Rating tables--#
    My_Query1= """
    SELECT
          COV_GW as 'Order'         
          ,[EVAL_DATE]
          ,[ST_ABB]
          ,[POLICY_EFF_DATE]
          ,[POLICY_EXP_DATE]
          ,[POLICY_POINTER]
          ,[VEHICLE_TYPE]
          ,[POLICY_NUMBER]
          ,[POLICY_SYMBOL]
          ,[UNIT]								
          ,[COV_GW]
          ,[BaseRates_Factor]
          ,[BASERATEMISC]  
          ,[BASERATESINSUREDAMOUNT_FACTOR]         
          ,[CMBND_TYPE_FACTOR]
          ,[ZONE_FACTOR]
          ,[ILF_FACTOR]
          ,[CMBND_DCTBL_FACTOR]
          ,[CMBND_MODELYEAR_FACTOR]
          ,[VEHAGE_FACTOR]
          ,[VEHUSE_FACTOR]
          ,[MILEAGE_FACTOR]
          ,[CMBND_LPMP_FACTOR]
          ,[TGRF_FACTOR]
          ,[LOANLEASE_FACTOR]
          ,[PASSIVERESTRAINT_FACTOR]
          ,[ABS_FACTOR]
          ,[ANTITHEFT_FACTOR]
          ,[MatureDefensive_Factor]
          ,[DRIVER_COMPOSITE_FACTOR]
          ,[HHC_FACTOR_CAPPED]
          ,[CMBND_GOLDSTAR_FACTOR]
          ,[GROUP_SYSTEM_FACTOR]
          ,[MULTICAR_FACTOR]
          ,[PACKAGE_FACTOR]
          ,[PERSISTENCY_FACTOR]
          ,[AUTOHOMEDISCOUNT_FACTOR]
          ,[NewPolicy_Factor]
          ,[LOYALTY_FACTOR]
          ,[GOPAPERLESS_FACTOR]
          ,[PYMTPLAN_FACTOR]
    	  ,1 as 'FR/Insurance_Score_factor'
          ,[RTNG_RNL_CAP_FACTOR]
          ,[CURRENT_RATE]
          ,[GV_FACTOR]
    	  ,'' as 'Blank1'
    	  ,'' as 'Blank2'
    	  ,'' as 'Blank3'
          ,[MinLic_Factor]
          ,[MAXAGE_FACTOR]
          ,[RESIDENCE_SYSTEM_FACTOR]
          ,[NUM_DRV_VEH_FACTOR]
    	  ,'' as 'Empty1'
          ,[HHC_FACTOR]
    	  ,'' as 'Empty2'
          ,[HHC_Min_Max1_Factor]
          ,[HHC_Min_Max_Factor]
    	  ,'' as 'Empty3'
          ,[HHC_FACTOR_CAPPED]
      FROM %s
      where policy_number = %s
      and policy_symbol = %s
      and unit = %s
      order by 'Order'
    """ % (tbl1, pol_num, pol_sym, unit)

    My_Query2= """
    SELECT
          [CLIENT_ID] 	      
    	  ,[COVERAGE]
          ,[DrvChar_Factor]
          ,[GSD_DTD_FACTOR]
          ,[DRVRECORD_FACTOR]
          ,[SR_22_FACTOR]
          ,[CGR_FACTOR]
          ,[MatureDefensive_Factor]
          ,[SDD_FACTOR]
          ,[DrvUse_Factor]
          ,[DRVR_FACTOR]
      FROM %s
      where policy_number = %s
      and [RTNG_EXCLUDED_IND] = 'N'
      order by [CLIENT_ID] desc   
    """ % (tbl2, pol_num)    

    #--Run Query--#    
    Pol_Veh_factor_df = pd.read_sql_query(My_Query1, con) 
    Pol_Veh_factor_df.POLICY_NUMBER = pd.to_numeric(Pol_Veh_factor_df.POLICY_NUMBER)
    Pol_Veh_factor_df.POLICY_SYMBOL= pd.to_numeric(Pol_Veh_factor_df.POLICY_SYMBOL)

    #--Tranpose result--#    
    df = Pol_Veh_factor_df.T
    
    #--Make the 1st row header--#
    new_header = df.iloc[10]
    df = df[1:]
    df.columns = new_header
    cov_list = list(df.columns)

    #--Create empty columns--#    
    for each in st_cov:
        if each not in(cov_list):
            df[each] = ''
    df = df[st_cov]        
             
    #--Write to sheet--#
    k = str(i + 1)
    df.to_excel(writer, k, index=True)
    writer.sheets[k].set_column('A:A', 36)
    writer.sheets[k].freeze_panes('B12')
    writer.sheets[k].set_row(10, None, format1)
    writer.sheets[k].set_row(43, None, format2)
    
    #--Indicate the location to where user needs to paste the factors from rater--#
    writer.sheets[k].write('N10', 
                 'Paste-value the result from Rater (including coverage names) to the green cell right below',
                 format2)
    writer.sheets[k].write('N11', None, format4)
    writer.sheets[k].write_url('A1', 'internal:List!A1', string='Back to List')
    
    #--Apply conditional formatting, currently the range is fixed, 
    #--which is probably ok, we use 11 columns for now, but we could set to 13, the max cov in PA--#
    writer.sheets[k].conditional_format("B12:L59", {'type':'formula', 
                 'criteria':'=OR(AND(B12<>N12,B12<>"",N12<>"n/a"),AND(B$11<>"",B12="",N12<>"n/a",N12<>"",N12<>1))', 'format':format3})    
    writer.sheets[k].conditional_format("N12:X59", {'type':'formula', 
                 'criteria':'=OR(AND(B12<>N12,B12<>"",N12<>"n/a"),AND(B$11<>"",B12="",N12<>"n/a",N12<>"",N12<>1))', 'format':format3})    

    writer.sheets['List'].write_url('A' + str(i+2), 'internal:' + k +'!A1', string='ws-' + k)
#    writer.sheets['List'].write_url(i+1,1, 'internal:' + k +'!A1')
    
    #--Query the driver factors only for appliable-type vehicle--#    
    if veh_type in ('PP','PU','VN','CL','NN','DB'):
        Dri_factor_df0 = pd.read_sql_query(My_Query2, con)
        Dri_factor_df1 = Dri_factor_df0[Dri_factor_df0['COVERAGE'].isin(st_cov)]
        Dri_factor_df1['Rank'] = Dri_factor_df1['COVERAGE'].map(sort_order)
        Dri_factor_df1.sort_values(['CLIENT_ID','Rank'], ascending = [False, True], inplace = True)
        try:
            Dri_factor_df = Dri_factor_df1.pivot(index='CLIENT_ID'
                                                 , columns='Rank'
                                                 , values=['DrvChar_Factor', 'GSD_DTD_FACTOR', 'DRVRECORD_FACTOR'
                                                           ,'SR_22_FACTOR', 'CGR_FACTOR', 'MatureDefensive_Factor'
                                                           ,'SDD_FACTOR', 'DrvUse_Factor', 'DRVR_FACTOR'])
            newcolname = dict(zip(Dri_factor_df.columns.levels[1], st_cov))
            Dri_factor_df = Dri_factor_df.rename(columns=newcolname, level=1)
            Dri_factor_df = Dri_factor_df.sort_index(ascending=False)
        except:
            Dri_factor_df = Dri_factor_df1

        #--Write to sheet--#
        k = str(i + 1)
        Dri_factor_df.to_excel(writer, 'Dri-'+k)
        writer.sheets['Dri-'+k].set_column('A:A', 30)
        writer.sheets['Dri-'+k].freeze_panes('B4')
        writer.sheets['Dri-'+k].write_url('A1', 'internal:List!A1', string='Back to List')
        
#--Save workbook--#
writer.save()

#--Calculate running time--#
runtime = round(time.time() - start_time, 0)
minutes = round(runtime // 60)
seconds = round(runtime % 60)
print("Process took %dm:%ds" %(minutes, seconds))
print('Complete!')

#https://stackoverflow.com/questions/23482668/sorting-by-a-custom-list-in-pandas
#https://xlsxwriter.readthedocs.io/example_pandas_header_format.html