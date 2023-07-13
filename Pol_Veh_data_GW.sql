/****** This is the 1st of the 3 SQL scripts used to get GW inforce vehicle  ******/

DECLARE @state char(2),  @eval_date date			
SET @state = 'MD'		
SET @eval_date = '2023-05-31'

SELECT 
	   @eval_date as 'EVAL_DATE'
	  ,'' as 'RISK_STATE'
      ,pol.[RISK_STATE] as 'ST_ABB'
	  /* having this additional column 'Veh_Type' here to help nagivate the situation file easily */
	  ,veh.[VEHICLE_TYPE] as 'Veh_Type'
	  --,cast(substring(pol.[POLICY_NUMBER], 4, 7) as int) as 'POLICY_NUMBER'
	  --12/15/20: use part of pol_sql_key as policy_number, removed cast arround before of overflow int error since the # of digit is longer than system
	  ,substring(pol.[POL_SQL_KEY], 4, 11) as 'POLICY_NUMBER'
      ,substring(pol.[POLICY_NUMBER], 1, 3) as 'POLICY_SYMBOL'
	  ,cast(veh.[UNIT] as int) as 'UNIT'
      ,pol.[NBR_OF_DRIVERS] as 'Total Drivers'
      ,pol.[NBR_VEHICLES] as 'Total Vehicles'
      ,pol.[POLICY_EFF_DATE] as 'Policy Effective Date'
      --,pol.[POLICY_EXP_DATE]
      ,pol.[FIRST_POLICY_DATE] as 'Auto ORG Date'
      ,pol.[LOYALTY_DATE] as 'Loyalty Date'
      ,pol.[PRIOR_CARR_EFF_DATE] as 'Prior Carrier ORG Date'
	  ,'' as 'Pol_LastCitationDate' --this is not used, to be deleted if we remove this field from rater later
	  ,'' as 'Persistency Code' --to be removed, keep this to be use with existing Python
	  ,'' as 'Persistency Code plus 1' --to be removed, keep this to be use with existing Python
	  ,'' as 'Auto Team Rating Persistency Months' --to be removed, keep this to be use with existing Python	  	   
	  ,CASE 
			--when (veh.[PRIOR_INS] = 'N' and (pol.[POLICY_STATUS] = 'Renewal' or pol.[UND_CODE5] = 'Renewing')) then 'TRUE' --12/18/20: added und_Code5 criteria since the policy_status can be 'Policy change'
			--when (veh.[PRIOR_INS] = 'N' and veh.[PERSISTENCY] >= 12) then 'TRUE' --12/18/20 the above criterion will cause other problems
			when veh.[PRIOR_INS] = 'N' then 'FALSE'
			else 'TRUE' end as 'Prior Insurance' --may need to revisit the logic
	  --,veh.[PRIOR_INS]
	  ,'' as 'ORG Years' --Rater calculates this	
      ,pol.[LOYALTY_YEARS] as 'Loyalty Years' --Rater calculates this
	  ,veh.[PERSISTENCY] as 'Persistency in months' --Rater calculates this
	  --12*(YEAR(POL_EFF_DATE)-YEAR($E$51))+(MONTH(POL_EFF_DATE)-MONTH($E$51))+IF(DAY(POL_EFF_DATE)>=DAY($E$51),0,-1)
	  ,CASE veh.[GOLD_STAR_RATE_LEVEL] 
			when 'Platinum' then 'P'
			when 'Gold Star' then '2'
			else '3' end as 'Rate Level'
      ,pol.[FULL_CREDIT_SCORE] as 'Insurance_Score'
      ,iif(pol.[SALES_CODE] in ('0069', '0500', '0502', '0227', '0549'), 'EP01', pol.[GROUP_RATE_LEVEL]) as 'Group Discount Code'
      ,cast(pol.[SALES_CODE] as int) as 'Sales Code'
	  ,ltrim(rtrim(veh.[AUTO_HOME_DISCOUNT])) as 'Auto/Home Discount'
      ,pol.[RESIDENCE_TYPE] as 'Residence Type'
      ,CASE pol.[PRIOR_BI_LIMIT]  --12/17/20: added more values seen from table
			when '$1,000,000/Person-$1,000,000/Accident' then '1M/1M'
			when '$10,000/Person-$20,000/Accident' then '1010/20'
			when '$100,000/Person-$300,000/Accident' then '100/300'
			when '$15,000/Person-$30,000/Accident' then '15/30'
			when '$20,000/Person-$40,000/Accident' then '20/40'
			when '$25,000/Person-$50,000/Accident' then '25/50'
			when '$250,000/Person-$500,000/Accident' then '250/500'
			when '$30,000/Person-$60,000/Accident' then '30/60'
			when '$300,000/Person-$500,000/Accident' then '300/500'
			when '$50,000/Person-$100,000/Accident' then '50/100'
			when '$500,000/Person-$1,000,000/Accident' then '500/1M'
			when '$500,000/Person-$500,000/Accident' then '500/500'
			when '25000/50000' then '25/50'
			when '50000/100000' then '50/100'
			when '100000/300000' then '100/300'
			when '250000/500000' then '250/500'
			else 'Unknown' end as 'Prior BI Limit' --Hardcode for now, may/maynot create the PriorLimit conversion table later
	  ,'' as 'Years with prior carrier' --Rater calculates this
	  ,'' as 'Total Chargeable accidents in the past 3 years' --Rater calculates this	
	  ,'' as 'Total Major Violations in the past 3 years' --Rater calculates this
      ,iif(pol.[EDOC_DISC] = 'N', 'FALSE', 'TRUE') as 'Go PaperLess Discount'	  	
      ,CASE 
			when left(pol.ARS_BILL_CLASS,3) = 'SPA' then 'AN'
			when left(pol.ARS_BILL_CLASS,3) = 'SP5' then 'IN'
			when left(pol.ARS_BILL_CLASS,2) = 'PR' then 'PAYROLL' --12/22/20 changed from PR to PAYROLL
			when left(pol.ARS_BILL_CLASS,2) = 'EF' and right(pol.ARS_BILL_CLASS,1) = '0' then 'EZ10'
			when left(pol.ARS_BILL_CLASS,2) = 'EF' and right(pol.ARS_BILL_CLASS,1) = '2' then 'EZ12'
			else 'ERROR' end as 'Preferred Payment Type' --Need to check with Laura, should we default as error to catch or default to 'AN'
	  ,pol.[MIN_YEARS_LIC] as 'Min Years Licensed' --Rater calculates this
	  ,pol.[MAX_AGE] as 'Max Age' --Rater calculates this
	  ,pol.[NEW_POL_DISC_LEVEL] as 'New Policy Type' --Rater calculates this
      ,pol.[RNL_CAP_FACTOR] as 'Capping Factors'
	  ,'' as 'Blank Col1'	
	  ,'' as 'Vehicle Info' --Empty/Dummy column to separate Vehicle Info section
	  /* The Limit/Ded and Cov Premium will be from separate query */
	  ,FIRST_VEHICLE
	  ,case
			when pol.[RISK_STATE] in ('CO','KS','NJ') then iif(FIRST_VEHICLE = 'TRUE', '1', '')
			else 'n/a' end as 'Vehicle Index' --updated 6/10/22 for existing GW state --> Future update required when other GW states are live
	 -- ,[Vehicle Index] = 		
		--iif(veh.[UNIT]=MIN(case 	
		--	when pol.[RISK_STATE] not in ('CO', 'KY', 'OK', 'RI', 'KS', 'MT', 'NJ') then 'n/a'
		--	--when pol.[RISK_STATE] = 'NJ' then IIF ([LIMIT_MOD] = '1','1','2')
		--	when [BASE_RATE_MOD] in ('1', '1   M', '1   S') then '1'
		--	else '2'
		--	end) over (Partition by A.[POLICY_NUMBER], A.[POLICY_POINTER],A.[UNIT]),1,2)
	  ,cast(veh.[UNIT] as int) as 'Vehicle #'
	  ,veh.[VEHICLE_TYPE] as 'Vehicle Type'
	  --,'' as 'PIP Deductible' --removed 6/10/22 Python takes care of this, else will have 2 columns in the final output in Pip states
	  --,iif(veh.[PA_TORT_IND] = 'Y', 'TRUE', 'FALSE') as 'Tort included' --added 2/4/21 for PA
	  ,case 
			when (pol.[RISK_STATE]='PA' and veh.[PA_TORT_IND] = 'Y') then 'TRUE' 
			when (pol.[RISK_STATE]='PA' and veh.[PA_TORT_IND] <> 'Y') then 'FALSE'
			else '' end as 'Tort included' --added 6/10/22 for PA
	  ,case 
			when (pol.[RISK_STATE]='NJ' and veh.[PA_TORT_IND] = 'Y') then 'TRUE' 
			when (pol.[RISK_STATE]='NJ' and veh.[PA_TORT_IND] <> 'Y') then 'FALSE'
			else '' end as 'Limitation on Lawsuit Option' --added 6/10/22 for NJ
	  --,'' as 'Limitation on Lawsuit Option'
	  ,ltrim(rtrim(veh.[SYMBOL])) as 'SYM' --May not need to trim anymore
	  ,iif(veh.[CPH_PYD_SYM] = '', ltrim(rtrim(veh.[SYMBOL])), ltrim(rtrim(veh.[CPH_PYD_SYM]))) as 'SYM CMP' --added 12/17/20 to take value from SYM if blank
	  ,iif(veh.[CLL_PYD_SYM] = '', ltrim(rtrim(veh.[SYMBOL])), ltrim(rtrim(veh.[CLL_PYD_SYM]))) as 'SYM COL' --added 12/17/20 to take value from SYM if blank
	  ,ltrim(rtrim(veh.[BI_PD_LIA_SYM])) as 'BIPD LPMP SYM'
	  ,ltrim(rtrim(veh.[PIP_MED_PMT_SYM])) as 'PIPMED LPMP SYM'
	  ,veh.[COST_NEW] as 'High Value (Original Cost)'
	  ,iif(veh.[VEHICLE_TYPE] = 'CP' and veh.[STATED_AMOUNT] = 0, veh.[COST_NEW],veh.[STATED_AMOUNT]) as 'Amount of Insurance'
	  ,veh.[CUBIC_CENTIMETERS] as 'MC Engine Size (in cc)'
	  ,'' as 'Model Year Pricing' --No longer need this
	  ,veh.[MODEL_YEAR] as 'Model Year'
	  ,'' as 'Age of Vehicle' --Rater calculates this
	  ,cast(left(veh.[GARAGE_ZIPCODE], 5) as int) as 'ZIP Code'
	  ,veh.[ZONE] as 'Zone' --Rater calculates this
	  ,veh.[USE_CODE] as 'Commute Mileage'
	  ,veh.[ANNUAL_MILES] as 'Annual Mileage'
	  ,iif(veh.[PKG_DISC_IND] = 'N', 'FALSE', veh.[PKG_DISC_IND]) as 'Package Discount Type'
	  ,iif(veh.[PASSIVE_RESTRAINT] = 'N', 'FALSE', ltrim(rtrim(veh.[PASSIVE_RESTRAINT]))) as 'Passive Restraint Discount'
	  ,iif(veh.[ANTILOCK_BRAKE_IND] in ('Y', '2'), 'TRUE', 'FALSE') as 'Anti-lock Brake Discount'
	  --,iif((veh.[ANTITHEFT_DEVICE] in ('','N') or substring(veh.[ANTITHEFT_DEVICE],3,1) <> 1), 'FALSE', 'TRUE') as 'Anti-theft Discount' 
	  ,iif(veh.[ANTITHEFT_DEVICE] in ('','N'), 'FALSE', veh.[ANTITHEFT_DEVICE]) as 'Anti-theft Discount'  --1/4/20: fixed to read ST# code as is and test with IN, ID, CO & KS
	  ,iif(veh.[LOAN_LEASE_GW] ='Y', 'TRUE', 'FALSE') as 'Loan/Lease'
	  ,VEH_HIST_SCORE as 'Vehicle History' --5/20/21: added
	  ,CASE 
			when veh.[VEHICLE_TYPE] = 'MC' then 25
			else '' end as 'MC Assigned Driver Age' --Default 25/blank for now; 1/4/21: GW HDB doesn't have indicator, need to use python
	  ,CASE
			when veh.[VEHICLE_TYPE] in ('MC','MH') then 'FALSE' --2/2/21 added MH, it was only MC before
			else '' end as 'MC/MH Mature/Defensive Driver Indicator' --Default FALSE/blank for now based on the current inforce; 1/24/21: GW HDB doesn't have indicator, need to use python
	  ,'' as 'Blank Col2'
	  ,'' as 'Driver Info' --Empty/Dummy column to separate Driver Info section
      ,pol.[NBR_MAJ_HH_NPD] --Need to ask Laura what it is
      ,pol.[EXP_CAP_PRM_AMT] --Need to ask Cemal if we want to have this for comparison
      ,pol.[RNL_UCP_PRM_AMT] --Need to ask Cemal if we want to have this for comparison
      ,pol.[EXP_CAP_FACTOR] --Need to ask Cemal if we want to have this for comparison
      --,pol.[MODULE] --Jenny suggested to match by Module as well, need to work on this later
      ,pol.[HIST_BEG_EFF_TS] as pol_beg --will need this for query to get all transactions
      ,pol.[HIST_END_EFF_TS] as pol_end --will need this for query to get all transactions
      ,veh.[HIST_BEG_EFF_TS] --will need this for query to get all transactions
      ,veh.[HIST_END_EFF_TS] --will need this for query to get all transactions
	  ,pol.[POL_SQL_KEY]
	  ,pol.[POLICY_NUMBER] as 'pre_split_pol_num'
	  ,pol.[POLICY_STATUS],pol.UND_CODE5
	  --,pc_job.[JOB_NBR]

	  --,veh.[DATA_SOURCE_CC]
	  --,veh.[SERIAL_NUMBER] as 'IQ_VIN'
	  --,veh.[MAKE_DESC]
	  --,veh.[BODY_STYLE]
	  --,veh.[PA_TORT_IND]
	  --added the below for CA 4/6/22
	  ,EXC_VEH_IND
	  ,GOLD_STAR_RATE_LEVEL
	  ,MATURE_DRV_DSC_IND
	  ,GOOD_DRVR_DISC_IND 
	  ,MULTICAR_DISC_FLAG
	  ,Drv_Asgn_Primary_GW
	  ,Drv_Asgn_Secondary_GW
	  ,SAFE_DRV_YRS
	  ,DRIVER_ASSIGNED --for VA
	  --added below for new fields 3/14/23
	  ,convert(date,z_first_quote_date) as 'Quote Date'
	  ,EARLY_SHOPPING_DAYS as 'Early Shopping Days'
	  ,NO_OF_LATEPYMNTS as 'Number of Late Payments'
	  ,NO_OF_NON_PAYCANC as 'Number of Cancellations'
	  ,LAPSE_DAYS

	  
	  	  
FROM (select * from hdb_auto.dbo.pidhst_policy where [DATA_SOURCE_CC] = 'GW') pol 		--use this if to get only transaction happening in GW
left join (select * from hdb_auto.dbo.pidhst_vehicle where [DATA_SOURCE_CC] = 'GW') veh   --use this if to get only transaction happening in GW
--FROM (select * from hdb_auto.dbo.pidhst_policy) pol 		
--left join (select * from hdb_auto.dbo.pidhst_vehicle) veh
on pol.[POL_SQL_KEY] = veh.[POL_SQL_KEY]
and pol.[HIST_BEG_EFF_TS] < veh.[HIST_END_EFF_TS] --This will give us only the row corresponding to latest transaction
and pol.[HIST_END_EFF_TS] >= veh.[HIST_END_EFF_TS] --This will give us only the row corresponding to latest transaction

/*  Get PC Job Number for use in Python code that runs XMLs in PC (use for mismatches) */
--this first method works for sql but causes error in python since it would require connection to gwis02
--left join (select [POL_NO],[JOB_NBR],[JOB_TYPE_CD],[TRAN_PROC_DTS] from xx1.dbo.z_cs_job_tran
--			join xx1.dbo.cs_policy_base  
--			on cs_policy_base.[POL_KEY] = z_cs_job_tran.[POL_KEY]) pc_job
--on pc_job.[POL_NO] = pol.[POLICY_NUMBER] 
--and pol.[HIST_BEG_EFF_TS] = pc_job.[TRAN_PROC_DTS]

--left join (select * from openquery(xx1, 'select [POL_NO],[JOB_NBR],[JOB_TYPE_CD],[TRAN_PROC_DTS] from xx2.dbo.z_cs_job_tran
--			join xx2.dbo.cs_policy_base  
--			on cs_policy_base.[POL_KEY] = z_cs_job_tran.[POL_KEY]')) pc_job
--on pc_job.[POL_NO] = pol.[POLICY_NUMBER] 
--and pol.[HIST_BEG_EFF_TS] = pc_job.[TRAN_PROC_DTS]

WHERE pol.[RISK_STATE] = @state			
and substring(pol.[POLICY_NUMBER],4,7) not like '9999%'
and veh.[DATA_SOURCE_CC] = 'GW' --use this if to get only transaction happening in GW
--and veh.[DATA_SOURCE_CC] in ('HDB','GW')
and @eval_date between veh.[HIST_BEG_EFF_TS] and veh.[HIST_END_EFF_TS]
AND pol.POLICY_EFF_DATE<=@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
AND pol.POLICY_EXP_DATE>@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
and pol.UND_CODE5 <> 'Cancelled' --12/14/20: added to remove 'cancelled' entries as in Cemal's query - could be off a few for some policies that not cancelled now but cancelled next year
--and VEHICLE_TYPE in ('PP')
--and POLICY_EFF_DATE >= '2019-11-30'
--and pol.POL_SQL_KEY = '10155922902002'
--ORDER BY POLICY_NUMBER, POLICY_SYMBOL, 'Vehicle #'
ORDER BY POL_SQL_KEY, POLICY_SYMBOL, 'Vehicle #'
