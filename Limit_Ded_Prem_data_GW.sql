/****** This is the 2nd of the 3 SQL scripts used to get GW inforce vehicle  ******/

--DROP TABLE IF EXISTS #TempCAT1; --have to remove this since GWIS02 is SQL Server 2014 while this syntax is for 2016

DECLARE @state char(2),  @eval_date date			
SET @state = 'MD'		
SET @eval_date = '2023-05-31'

select t1.POL_SQL_KEY, t1.POLICY_NUMBER, cast(t1.unit as int) as unit 
	,t1.COVERAGE_CD 
	--,t1.COVERAGE_LIMIT as 'lim_o', t1.STACKING_IND
	--,iif((risk_state = 'PA' and COVERAGE_CD in ('UIM','UMB')),rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.STACKING_IND)),t1.COVERAGE_LIMIT) as COVERAGE_LIMIT --added 2/4/21 for PA --comment out 6/29/22 to use casewhen with NJ
	--,iif((risk_state = 'NJ' and COVERAGE_CD in ('PIP')),
	--		rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION,'_',t1.PIP_MED_OPTION,'_',t1.NJ_EXT_MED_LIMIT)),t1.COVERAGE_LIMIT) as COVERAGE_LIMIT --added 6/9/22 for NJ but not use, use casewhen with PA
	,case
		when (risk_state = 'PA' and COVERAGE_CD in ('UIM','UMB')) then 
			rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.STACKING_IND))
		when risk_state = 'MD' and COVERAGE_CD in ('UMB') then
			rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION))
		when (risk_state = 'NJ' and COVERAGE_CD in ('PIP')) then
			rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION,'_',t1.PIP_MED_OPTION,'_',t1.NJ_EXT_MED_LIMIT))
		else t1.COVERAGE_LIMIT end as COVERAGE_LIMIT
	,t3.GW_RATER_VALUE,t1.COV_PREMIUM_AMT, t2.HIST_BEG_EFF_TS as pol_beg, t2.HIST_END_EFF_TS as pol_end, t1.HIST_BEG_EFF_TS, t1.HIST_END_EFF_TS, t2.RISK_STATE
INTO #TempCAT1
from (select * from hdb_auto.dbo.pidhst_vehcov 
		where [DATA_SOURCE_CC] = 'GW' --use this if to get only transaction happening in GW
		--where [DATA_SOURCE_CC] in ('HDB','GW')
		and @eval_date between [HIST_BEG_EFF_TS] and [HIST_END_EFF_TS]) t1 
LEFT outer join hdb_auto.dbo.pidhst_policy t2
ON t1.POL_SQL_KEY = t2.POL_SQL_KEY
LEFT outer join Competitive.dbo.z_HDB_RATER_Conversion_GW t3
ON t1.COVERAGE_CD = t3.GW_COV_PERIL
--and iif(risk_state = 'PA' and COVERAGE_CD in ('UIM','UMB'),rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.STACKING_IND)),t1.COVERAGE_LIMIT) = t3.GW_HDB_VALUE--added 2/4/21 for PA --comment out 6/29/22 to use casewhen with NJ
--and iif((risk_state = 'NJ' and COVERAGE_CD in ('PIP')),
--			rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION,'_',t1.PIP_MED_OPTION,'_',t1.NJ_EXT_MED_LIMIT)),t1.COVERAGE_LIMIT) = t3.GW_HDB_VALUE--added 6/9/22 for NJ but not use, use casewhen with PA
and (case  
	when risk_state = 'PA' and COVERAGE_CD in ('UIM','UMB') then 
		rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.STACKING_IND))--added 2/4/21 for PA
	when risk_state = 'MD' and COVERAGE_CD in ('UMB') then
		rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION))--added 6/7/23 for MD
	when risk_state = 'NJ' and COVERAGE_CD in ('PIP') then
		rtrim(CONCAT(t1.COVERAGE_LIMIT,'_',t1.COV_OPTION,'_',t1.PIP_MED_OPTION,'_',t1.NJ_EXT_MED_LIMIT)) --added 6/9/22 for NJ
	else t1.COVERAGE_LIMIT end) = t3.GW_HDB_VALUE 
and t2.RISK_STATE = t3.ST_ABB
where t2.RISK_STATE =  @state
and t2.[HIST_BEG_EFF_TS] < t1.[HIST_END_EFF_TS]
and t2.[HIST_END_EFF_TS] >= t1.[HIST_END_EFF_TS]
AND t2.POLICY_EFF_DATE<=@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
AND t2.POLICY_EXP_DATE>@eval_date --12/14/20: added to remove duplicate entries around the cutoff date
and t2.UND_CODE5 <> 'Cancelled' --12/14/20: added to remove 'cancelled' entries as in Cemal's query - could be off a few for some policies that not cancelled now but cancelled next year
and substring(t2.[POLICY_NUMBER],4,7) not like '9999%'
--and COVERAGE_CD in ('UMB','UIM')
--and POLICY_EFF_DATE < '2020-06-01' --add this one if there are 2 rate changes and want to run separately

		
DECLARE @colsLimit AS NVARCHAR(MAX), @colsPrem AS NVARCHAR(MAX), 		
    @query  AS NVARCHAR(MAX);	
		
SET @colsLimit = STUFF((SELECT distinct ',' + COVERAGE_CD + '_Limit'		
	FROM #TempCAT1
	FOR XML PATH(''), TYPE	
	).value('.', 'NVARCHAR(MAX)'),1,1,'')	

SET @colsPrem = STUFF((SELECT distinct ','+ COVERAGE_CD  + '_System_Prem' 		
FROM #TempCAT1
	FOR XML PATH(''), TYPE	
	).value('.', 'NVARCHAR(MAX)'),1,1,'')	

--12/15/20: use part of pol_sql_key as policy_number, removed cast arround before of overflow int error since the # of digit is longer than system
SET @query = 		
'SELECT substring(POL_SQL_KEY, 4, 11) as Pol_Num, substring(POLICY_NUMBER, 1, 3) as Pol_Symbol, Unit, ' + @colsLimit + ',  ' + @colsPrem + ', pol_beg, pol_end, HIST_BEG_EFF_TS, HIST_END_EFF_TS, RISK_STATE, POLICY_NUMBER as pre_split_pol_num, POL_SQL_KEY FROM
        (SELECT POLICY_NUMBER, POL_SQL_KEY, Unit, pol_beg, pol_end, HIST_BEG_EFF_TS, HIST_END_EFF_TS, RISK_STATE, COVERAGE_CD + ''_'' + col as col, value FROM 		
	    (SELECT POLICY_NUMBER, POL_SQL_KEY, Unit, cast(GW_RATER_VALUE as VARCHAR(50)) as Limit, cast(COV_PREMIUM_AMT as VARCHAR(50)) System_Prem, COVERAGE_CD, pol_beg, pol_end, HIST_BEG_EFF_TS, HIST_END_EFF_TS, RISK_STATE	
		from #TempCAT1
		group by POLICY_NUMBER, POL_SQL_KEY, Unit, COVERAGE_CD,GW_RATER_VALUE, COV_PREMIUM_AMT, pol_beg, pol_end, HIST_BEG_EFF_TS, HIST_END_EFF_TS, RISK_STATE
	) tbl1	
	UNPIVOT 	
	(	
	value for col in (Limit, System_Prem)) tbl2	
	) tbl3	
	PIVOT 	
	(	
	max(value)	
	for col in (' + @colsLimit + ',' + @colsPrem + ')	
	) tbl4	
	order by POL_SQL_KEY, Pol_Num, Pol_Symbol, Unit'	

exec(@query)		

DROP TABLE #TempCAT1	
