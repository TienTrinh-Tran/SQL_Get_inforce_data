/****** This is the 3rd of the 3 SQL scripts used to get GW inforce vehicle  ******/

DECLARE @state char(2),  @eval_date date			
SET @state = 'MD'		
SET @eval_date = '2023-05-31'
			
SELECT 
	  @eval_Date as 'EVAL_DATE'	
      --,cast(substring(pol.[POLICY_NUMBER], 4, 7) as int) as 'POLICY_NUMBER'
	  --12/15/20: use part of pol_sql_key as policy_number, removed cast arround before of overflow int error since the # of digit is longer than system	
      ,substring(pol.[POL_SQL_KEY], 4, 11) as 'POLICY_NUMBER'	
      ,pol.[RISK_STATE] as 'ST_ABB'		
      ,pol.[POLICY_EFF_DATE]			
      ,pol.[POLICY_EXP_DATE]					
      ,drv.[DRIVER_ID] as 'CLIENT_ID'			
      ,pol.[FIRST_POLICY_DATE] as 'RTNG_FIRST_POLICY_DATE'		
	  --,'Age1' = case		
			--when DRIVER_AGE >= 25 then floor(DRIVER_AGE)
			--when DRIVER_AGE < (floor(DRIVER_AGE) + ceiling(DRIVER_AGE))* 0.5 then floor(DRIVER_AGE)
			--else (floor(DRIVER_AGE) + ceiling(DRIVER_AGE))* 0.5 end
	  ,'calc_Age' = case
			when datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25 < (floor(datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25) + ceiling(datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25))*0.5 then floor(datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25)
			else (floor(datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25) + ceiling(datediff(dd,drv.[BIRTH_DATE],pol.[POLICY_EFF_DATE])/365.25))*0.5 end
	  ,DRIVER_AGE as Age
	  --,DRIVER_AGE as 'IQ_Age' --IQ field, will import to see the cutoff age for rounding up/down, then set the rounding accordingly
	  ,'Years Licensed'	= case
			when datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25 < (floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25) + ceiling(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25))*0.5 then floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25)
			else (floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25) + ceiling(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25))*0.5 end
	  --,'Years Licensed1' = case --datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25
			--when datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25 < (floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25) + ceiling(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25))*0.5 then floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25)
			--else ceiling(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25) end
	  --,'Years Licensed2' = floor(datediff(dd,drv.[LICENSE_DATE],pol.[POLICY_EFF_DATE])/365.25)
	  --,drv.NBR_YEARS_LICENSED as 'num_y_lic'
      ,drv.[LICENSED_EXPER] 		
      ,iif(drv.[SEX] = 'N', 'F', drv.[SEX]) as 'Gender' --12/21/21: N stands for 'Non-binary Gender', and CC rates as F since F's rate is lower than M's rate
      ,'Marital Status' = case 
			when drv.[MARITAL_STATUS] in ('D','P_CC','S') then 'S' --1/4/21: changed it according to Rule 29
			when (drv.[MARITAL_STATUS] = 'W' and RISK_STATE not in ('PA','MN','CA','DE','MD')) then 'S' --10/19/21 4 more states aside PD
			else 'M' end 
      ,iif(drv.[AT_SCHOOL] = 'Y', 'TRUE', 'FALSE') as 'Away At School'			
      ,iif(drv.[GOOD_STUDENT_DISC] = 'Y', 'TRUE', 'FALSE') as 'Good Student'			
      ,iif(drv.[DRV_TRN_DISC] = 'Y', 'TRUE', 'FALSE') as 'Driver Training'			
	  ,drv.[DRV_REC_PTS]  as 'Surcharge Points'		
      ,drv.[CHG_ACC_BFR_FORGV] as 'Chargeable plus waived accidents in the past 3 years'			
      ,drv.[NBR_MAJ_VIO] as 'Major Violations in the past 3 years'
	  ,drv.[NBR_MIN_VIO] as 'Minor Violations'  --12/28/20: change this to get # of Minor Violations for other states as well	
      ,iif(drv.[SR_22] = 'Y', 'TRUE', 'FALSE') as 'SR-22'			
      ,iif(drv.[COLL_GRAD_DISC] = 'Y', 'TRUE', 'FALSE') as 'College Graduate'			
      ,'Mature/Defensive' = case
			when pol.RISK_STATE in ('KS') then iif(drv.[DEFNSV_DRV_DISC_GW] = 'Y', 'TRUE', 'FALSE')
			else iif(drv.[MATURE_DRV_DISC_GW] = 'Y', 'TRUE', 'FALSE') end 		
      ,drv.[SAFE_YEAR_LEVEL_GW] as 'Safe Year Level'			
      ,drv.[DRIVER_USAGE] as 'Driver Usage'	
	  ,'' as 'For future Use 1'		
	  ,'' as 'For future Use 2'	
	  ,'' as 'For future Use 3'	
	  ,'' as 'Senior Discount (For future Use)'		
	  ,drv.[GOOD_DRIVER_IND] as 'Good Driver (For future Use)'		
	  ,'' as 'Assigned Driver' 				
      ,drv.[BIRTH_DATE] as 'Driver DOB'			
      ,drv.[MOST_REC_MAJ_VIO_DT] as 'LastCitationDate'			
	  ,drv.[LICENSE_DATE] as 'Driver Licensed Date'		
	  ,pol.[HIST_BEG_EFF_TS] as pol_beg --will need this for query to get all transactions
	  ,pol.[HIST_END_EFF_TS] as pol_end --will need this for query to get all transactions
	  ,drv.[HIST_BEG_EFF_TS] --will need this for query to get all transactions
	  ,drv.[HIST_END_EFF_TS] --will need this for query to get all transactions	  	
	  ,pol.[POL_SQL_KEY]
	  ,pol.[POLICY_NUMBER] as 'pre_split_pol_num'
	  ----added the below for CA 4/6/22
	  --,LAST_MAJ_CIT_DATE --for CA 
	  --,MOST_REC_CHG_ACC_DT --for CA
	  --,MOST_REC_MIN_VIO_DT --for CA
	  --,MOST_REC_MAJ_VIO_DT --for CA
	  --,DRV_REC_PTS --for CA
	  --,MINORS_LT_3YRS --for CA
	  --,MAJORS_LT_3YRS --for CA
	  --,MAJORS_BT_3_7YRS --for CA
	  --,CHARGE_LT_3YRS --for CA
	  --,MINORS_BT_3_6YRS --for CA
	  --,MAJORS_BT_7_10YRS --for CA
	  --,CHARGE_BT_3_7YRS --for CA
	  --,CHARGE_BT_7_10YRS --for CA
	  --,CHG_ACC_BFR_FORGV --for CA
	  --,CHG_ACC_AFT_FORGV --for CA
	  --,RECORD_POINTS --for CA
	  --,DRIVER_USAGE --for CA, VA
	  --,SAFE_YEAR_LEVEL_GW --for CA
	  --,MC_TRN_DISC --for OR, CT, 


  FROM (select * from hdb_auto.dbo.pidhst_driver where data_source_cc in ('GW')) as drv -- put data_source_cc restriction here to improve runtime
  left join (select * from hdb_auto.dbo.pidhst_policy where data_source_cc in ('GW')) as pol
  on drv.pol_sql_key = pol.pol_sql_key
  and pol.hist_beg_eff_ts < drv.hist_end_eff_ts
  and pol.hist_end_eff_ts >= drv.hist_end_eff_ts
  AND pol.POLICY_EFF_DATE<=@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
AND pol.POLICY_EXP_DATE>@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
and pol.UND_CODE5 <> 'Cancelled' --12/14/20: added to remove 'cancelled' entries as in Cemal's query - could be off a few for some policies that not cancelled now but cancelled next year

  where
  drv.EXCLUDED_IND <> 'Y'	
  and substring(drv.pol_sql_key,4,7) not like '9999%'		-- dummy policies
  and RISK_STATE = @state			
  and @eval_date between drv.hist_beg_eff_ts and drv.hist_end_eff_ts
  --and POLICY_EFF_DATE < '2020-06-01'
  --and pol.POL_SQL_KEY in ('10133684260902','10134434540602')
  --and drv.POLICY_NUMBER like '%63332724%'
  --order by POLICY_NUMBER, drv.driver_id desc	
  --and MC_TRN_DISC <> 'N'
  order by POL_SQL_KEY, drv.driver_id desc  		





