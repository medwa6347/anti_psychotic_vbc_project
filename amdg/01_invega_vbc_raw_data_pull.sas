 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC INVEGA VBC ANALYSIS FOR JANSSEN - CLAIMS		|
 | PROGRAM 1 OF 2 - RAW DATA PULL									|
 |  HTTP://DMO.OPTUM.COM/PRODUCTS/UGAP.HTML							|
 | AUTHOR: MICHAEL EDWARDS 2020-03-02 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/

* COMMAND LINE (USING 0000_shell.ksh);								
/*
cd /sasnas/ls_cs_nas/mwe/janssen/invega_vbc_202003/amdg
screen -dm -S ms2 ./0001_shell.ksh 
*/

%macro amdg(inp_dsn_pfx=,out_dsn_pfx=,testobs=);

/*-----------------------------------------------------------------*/
/*---> GLOBAL <----------------------------------------------------*/
/**/
%global person_id; %let person_id = mbr_sys_id;
%util_dates(start_dt='01Jul2019'd,yr_num=1,months=36)
data _null_; call symput("sysdate_word",left(put("&sysdate"d,worddate.))); run;

/*-----------------------------------------------------------------*/
/*---> DEFINE UGAP OPTIONS <---------------------------------------*/
/**/
%local ugap_specs;
%let ugap_specs = user="&un_ms." password="&pw_ms." server="udwprod" mode=teradata schema=ecro;
libname ugap_tmp teradata &ugap_specs. dbmstemp=yes;

/*-----------------------------------------------------------------*/
/*---> INVEGA PRODUCTS <-------------------------------------------*/
/**/
%let apsy_s = 'C9255','J2426','50458056001','50458056101','50458056201','50458056301','50458056401';
%let apsy_t = '50458060601','50458060701','50458060801','50458060901';
%goto skipme;
/*-----------------------------------------------------------------*/
/*---> UGAP MXRX CLAIMS <------------------------------------------*/
/**/
proc sql;          
connect to teradata (&ugap_specs.);	
/*
	create table inp.v&out_dsn_pfx._01_sust_rx_raw as
		select * from connection to teradata
		    (	    	    
		    select
					rx.mbr_sys_id as &person_id.
				, 'cs_pharmacy' as src_tbl
				,	n.ndc
				,	rx.allw_amt
				,	rx.ancl_amt
				,	rx.bil_amt
				,	rx.calc_pur_ingrdnt_amt
				,	rx.copay_amt
				,	rx.day_spl_cnt as days_supply
				,	rx.ded_amt
				,	rx.dispensing_fee_amt
				,	rx.ingredient_amt
				,	rx.pd_amt
				,	rx.qty_cnt
				,	rx.scrpt_cnt
				,	fdt.full_dt as fill_date
					from uhcdm001.cs_pharmacy rx
					join uhcdm001.ndc_drug n
					on rx.ndc_drg_sys_id = n.ndc_drg_sys_id
					join uhcdm001.hp_date fdt
					on rx.fill_dt_sys_id = fdt.dt_sys_id
					where n.ndc in (&apsy_s.)
					and fdt.year_nbr >= &cur_st_yrn.
				
				);

	create table inp.v&out_dsn_pfx._01_trin_rx_raw as
		select * from connection to teradata
		    (
		    select
					rx.mbr_sys_id as &person_id.
				, 'cs_pharmacy' as src_tbl
				,	n.ndc
				,	rx.allw_amt
				,	rx.ancl_amt
				,	rx.bil_amt
				,	rx.calc_pur_ingrdnt_amt
				,	rx.copay_amt
				,	rx.day_spl_cnt as days_supply
				,	rx.ded_amt
				,	rx.dispensing_fee_amt
				,	rx.ingredient_amt
				,	rx.pd_amt
				,	rx.qty_cnt
				,	rx.scrpt_cnt
				,	fdt.full_dt as fill_date
					from uhcdm001.cs_pharmacy rx
					join uhcdm001.ndc_drug n
					on rx.ndc_drg_sys_id = n.ndc_drg_sys_id
					join uhcdm001.hp_date fdt
					on rx.fill_dt_sys_id = fdt.dt_sys_id
					where n.ndc in (&apsy_t.)
					and fdt.year_nbr >= &cur_st_yrn.

				);
		*/		
	%let out_proc_fld_num = 4; %let out_dx_fld_num = 9;

	create table /*inp.v&out_dsn_pfx._01_sust_mx_out_raw*/ inp.v&out_dsn_pfx._01_all_mcd_mx_out_raw as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_outpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, mbr.mkt_nbr
			/*	, n.ndc 
				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &out_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &out_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &out_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &out_dx_fld_num %then %str(,); %end;
				*/,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_outpatient md  /*                                              
				  %do i=1 %to &out_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &out_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &out_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &out_proc_fld_num %then %str( ); %end;
				*/	join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					join uhcdm001.ndc_drug n
					on md.ndc_drg_sys_id = n.ndc_drg_sys_id
					join uhcdm001.cs_enrollment mbr
					on md.&person_id. = mbr.&person_id.
					/*where ( 
					(%do i=1 %to &out_proc_fld_num; p&i..proc_&i._cd in (&apsy_s.) %if &i ne &out_proc_fld_num %then %str(or); %end;)																				
					or
					(n.ndc in 	(&apsy_s.))
					)					 
					and */where dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        
/*
	create table inp.v&out_dsn_pfx._01_trin_mx_out_raw as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_outpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, n.ndc                                                                
				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &out_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &out_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &out_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &out_dx_fld_num %then %str(,); %end;
				,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_outpatient md                                                
				  %do i=1 %to &out_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &out_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &out_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &out_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					join uhcdm001.ndc_drug n
					on md.ndc_drg_sys_id = n.ndc_drg_sys_id
					where ( 
					(%do i=1 %to &out_proc_fld_num; p&i..proc_&i._cd in (&apsy_t.) %if &i ne &out_proc_fld_num %then %str(or); %end;)																				
					or
					(n.ndc in 	(&apsy_t.))
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				); 
*/
	%let inp_proc_fld_num = 6; %let inp_dx_fld_num = 9;

	create table /*inp.v&out_dsn_pfx._01_sust_mx_inp_raw*/ inp.v&out_dsn_pfx._01_all_mcd_mx_inp_raw as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_inpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, mbr.mkt_nbr
/*				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &inp_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &inp_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &inp_dx_fld_num %then %str(,); %end;
*/				,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_inpatient md                                                
/*				  %do i=1 %to &inp_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &inp_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &inp_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &inp_proc_fld_num %then %str( ); %end;
*/					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					join uhcdm001.cs_enrollment mbr
					on md.&person_id. = mbr.&person_id.
					/*where ( 
					(%do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd in (&apsy_s.) %if &i ne &inp_proc_fld_num %then %str(or); %end;)																				
					)					 
					and */ where dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        
/*
	create table inp.v&out_dsn_pfx._01_trin_mx_inp_raw as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_inpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &inp_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &inp_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &inp_dx_fld_num %then %str(,); %end;
				,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_inpatient md                                                
				  %do i=1 %to &inp_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &inp_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &inp_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &inp_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					where ( 
					(%do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd in (&apsy_t.) %if &i ne &inp_proc_fld_num %then %str(or); %end;)																				
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				); 
*/
disconnect from teradata;
quit;

/*-----------------------------------------------------------------*/
/*---> INITIAL ID PERIOD COHORT <----------------------------------*/
/**

proc sql;
create table cht.v&out_dsn_pfx._01_invega_mbrs as (
select distinct mbrs.&person_id. from (
 															select &person_id. from inp.v&inp_dsn_pfx._01_sust_rx_raw 
 										union all select &person_id. from inp.v&inp_dsn_pfx._01_sust_mx_out_raw 
 										union all select &person_id. from inp.v&inp_dsn_pfx._01_sust_mx_inp_raw 
 										union all select &person_id. from inp.v&inp_dsn_pfx._01_trin_rx_raw 
 										union all select &person_id. from inp.v&inp_dsn_pfx._01_trin_mx_out_raw
 										union all select &person_id. from inp.v&inp_dsn_pfx._01_trin_mx_inp_raw 										
 										) mbrs
);
quit;

/*-----------------------------------------------------------------*/
/*---> UGAP ENROLLMENT <-------------------------------------------*/
/**/
%skipme:;
%util_query_list(
												tgt_dsn					=	cht.v&inp_dsn_pfx._01_invega_mbrs
											, lst_fld					=	&person_id.
											,	lst_nbr					=	2000
											,	lst_pfx					=	mbr
											,	lst_fld_ischar	=	0
											);
/**/
*PULL ENROLLMENT;
proc sql;          
connect to teradata (&ugap_specs.);	

	%do j = 1 %to &ndsn.;

	create table t&out_dsn_pfx._01_mbr_enr_raw_&j. as
		select * from connection to teradata
		    (

		    select
					mbr.&person_id. as &person_id.
				, mbr.indv_sys_id as indv_sys_id
				, mbr.grp_sys_id as grp_sys_id
				,	dt_eff.indv_id_eff_full_dt as eff_date                                               
				,	dt_end.indv_id_end_full_dt as end_date                                               
				, mbr.dob	as date_of_birth
				, mbr.gdr_cd as gender
				, rx_cov.phrm_cov_ind
				, mbr.mkt_nbr
					from uhcdm001.cs_enrollment mbr
					join uhcdm001.date_indv_enr_eff dt_eff                                                 
					on mbr.eff_dt_sys_id = dt_eff.indv_id_eff_dt_sys_id                                  
					join uhcdm001.date_indv_enr_end dt_end                                                 
					on mbr.end_dt_sys_id = dt_end.indv_id_end_dt_sys_id                                  
					join uhcdm001.pharmacy_coverage rx_cov                                                 
					on mbr.phrm_cov_sys_id = rx_cov.phrm_cov_sys_id                                  
					where mbr.&person_id in (&&&mbr_list_&j.) 				
				);
	/*			
	create table t&out_dsn_pfx._01_all_rx_raw_&j. as
		select * from connection to teradata
		    (	    	    
		    select
					rx.mbr_sys_id as &person_id.
				, 'cs_pharmacy' as src_tbl
				,	n.ndc
				,	rx.allw_amt
				,	rx.ancl_amt
				,	rx.bil_amt
				,	rx.calc_pur_ingrdnt_amt
				,	rx.copay_amt
				,	rx.day_spl_cnt as days_supply
				,	rx.ded_amt
				,	rx.dispensing_fee_amt
				,	rx.ingredient_amt
				,	rx.pd_amt
				,	rx.qty_cnt
				,	rx.scrpt_cnt
				,	fdt.full_dt as fill_date
					from uhcdm001.cs_pharmacy rx
					join uhcdm001.ndc_drug n
					on rx.ndc_drg_sys_id = n.ndc_drg_sys_id
					join uhcdm001.hp_date fdt
					on rx.fill_dt_sys_id = fdt.dt_sys_id
					where rx.&person_id in (&&&mbr_list_&j.) 				
					and fdt.year_nbr >= &cur_st_yrn.
				
				);
				
	%let out_proc_fld_num = 4; %let out_dx_fld_num = 9;

	create table t&out_dsn_pfx._01_all_mx_out_raw_&j. as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_outpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, n.ndc 
				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &out_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &out_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &out_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &out_dx_fld_num %then %str(,); %end;
				,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_outpatient md                                                
				  %do i=1 %to &out_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &out_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &out_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &out_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					join uhcdm001.ndc_drug n
					on md.ndc_drg_sys_id = n.ndc_drg_sys_id
					where md.&person_id in (&&&mbr_list_&j.) 				
					and dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        

	%let inp_proc_fld_num = 6; %let inp_dx_fld_num = 9;

	create table t&out_dsn_pfx._01_all_mx_inp_raw_&j. as                                                     
		select * from connection to teradata                                               
		    (
		    select                                                                        
					md.mbr_sys_id as &person_id.                                                 
				, 'cs_inpatient' as src_tbl
				,	p.ama_pl_of_srvc_cd                                                          
				,	md.net_pd_amt                                                                
				, md.adj_srvc_unit_cnt                                                               
				, %do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd as prc&i. %if &i ne &inp_proc_fld_num %then %str(,); %end;
				, %do i=1 %to &inp_dx_fld_num; dx&i..diag_&i._cd as dx&i. %if &i ne &inp_dx_fld_num %then %str(,); %end;
				,	dt_svc.full_dt as first_service_date                                               
				,	dt_svc_lst.full_dt as last_service_date                                               
					from uhcdm001.cs_inpatient md                                                
				  %do i=1 %to &inp_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &inp_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &inp_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &inp_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.hp_date dt_svc_lst                                                 
					on md.lst_srvc_dt_sys_id = dt_svc_lst.dt_sys_id                                  
					where md.&person_id in (&&&mbr_list_&j.) 				
					and dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        
*/
	%end;		

disconnect from teradata;
quit;

data inp.v&out_dsn_pfx._01_mbr_enr_raw; 
	set %do k = 1 %to &ndsn.; t&out_dsn_pfx._01_mbr_enr_raw_&k. %if &k. ne &ndsn. %then %str( ); %end; ;
	format date_of_birth eff_date end_date mmddyy10.; 
run;
/*
data inp.v&out_dsn_pfx._01_all_rx_raw; 
	set %do k = 1 %to &ndsn.; t&out_dsn_pfx._01_all_rx_raw_&k. %if &k. ne &ndsn. %then %str( ); %end; ;
	format fill_date mmddyy10.; 
run;
data inp.v&out_dsn_pfx._01_all_mx_out_raw; 
	set %do k = 1 %to &ndsn.; t&out_dsn_pfx._01_all_mx_out_raw_&k. %if &k. ne &ndsn. %then %str( ); %end; ;
	format first_service_date last_service_date mmddyy10.; 
run;
data inp.v&out_dsn_pfx._01_all_mx_inp_raw; 
	set %do k = 1 %to &ndsn.; t&out_dsn_pfx._01_all_mx_inp_raw_&k. %if &k. ne &ndsn. %then %str( ); %end; ;
	format first_service_date last_service_date mmddyy10.; 
run;
*/

/*------> CLEANUP <------------------------------------------------*/
/**/ 

*DELETE ANY LEFTOVER DATA;
proc datasets nolist; delete t&out_dsn_pfx.:; quit;


%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/
%amdg(inp_dsn_pfx=400,out_dsn_pfx=700,testobs=);



