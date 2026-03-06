 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC INVEGA VBC ANALYSIS FOR JANSSEN - CLAIMS				|
 | PROGRAM 1 OF 2 - RAW DATA PULL																		|
 |  HTTP://DMO.OPTUM.COM/PRODUCTS/UGAP.HTML													|
 | AUTHOR: MICHAEL EDWARDS 2020-03-02 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/

* COMMAND LINE (USING 0000_shell.ksh);								
/*
cd /hpsaslca/mwe/janssen/invega_vbc_202003/amdg
screen -dm -S ms2 ./0001_shell.ksh 
*/

%macro amdg(rd_vz=,sd_vz=,rp_vz=,testobs=);

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
/*---> FORMATS <---------------------------------------------------*/
/**/
%include "&om_code./00_formats/fmt_invega_code2alt_ugap.sas";        
        
/*-----------------------------------------------------------------*/
/*---> GENERATE DRUG LISTS <---------------------------------------*/
/**/
%global drug_fams drug_fam_drugs;
%let drug_fams 			= apsy_t apsy_s;
%let drug_fam_drugs = trinza | sustenna; 
/**/
%util_drug_lists( 
								  drug_list_name				=	invega
								,	lu_lib								= zz_com
								,	glx_lu_tbl_loc				=	glx_medi_span_ndc
								,	hcpcs_tbl_loc					= hcpcs2brand	
								, lcl_xlsx_file_nm			=	
								,	force_lcl_xlsx				=	0
								, xlsx_ndc_tabs					=	
								, xlsx_hcpcs_tabs				=	
								,	lcl_sas_file_nm				=	
								,	force_lcl_sas					=	0
								,	force_xlsx_or_sas			=	0
								, routes								= IM|IJ
								,	drug_fams							= &drug_fams.
								, drug_fam_drugs				= &drug_fam_drugs.
								, printout							=	1
								); 

/*-----------------------------------------------------------------*/
/*---> UGAP MXRX CLAIMS <------------------------------------------*/
/**/
proc sql;          
connect to teradata (&ugap_specs.);	

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
				
	%let out_proc_fld_num = 4; %let out_dx_fld_num = 9;

	create table inp.v&out_dsn_pfx._01_sust_mx_out_raw as                                                     
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
				,	dt_svc.full_dt as service_date                                               
					from uhcdm001.cs_outpatient md                                                
				  %do i=1 %to &out_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &out_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &out_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &out_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.ndc_drug n
					on md.ndc_drg_sys_id = n.ndc_drg_sys_id
					where ( 
					(%do i=1 %to &out_proc_fld_num; md.proc_&i._cd_sys_id in (&apsy_s_alt.) %if &i ne &out_proc_fld_num %then %str(or); %end;)																				
					or
					(n.ndc in 	(&apsy_s.))
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        

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
				,	dt_svc.full_dt as service_date                                               
					from uhcdm001.cs_outpatient md                                                
				  %do i=1 %to &out_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &out_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &out_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &out_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					join uhcdm001.ndc_drug n
					on md.ndc_drg_sys_id = n.ndc_drg_sys_id
					where ( 
					(%do i=1 %to &out_proc_fld_num; md.proc_&i._cd_sys_id in (&apsy_t_alt.) %if &i ne &out_proc_fld_num %then %str(or); %end;)																				
					or
					(n.ndc in 	(&apsy_t.))
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				); 

	%let inp_proc_fld_num = 6; %let inp_dx_fld_num = 9;

	create table inp.v&out_dsn_pfx._01_sust_mx_inp_raw as                                                     
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
				,	dt_svc.full_dt as service_date                                               
					from uhcdm001.cs_inpatient md                                                
				  %do i=1 %to &inp_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &inp_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &inp_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &inp_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					where ( 
					(%do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd in (&apsy_s.) %if &i ne &inp_proc_fld_num %then %str(or); %end;)																				
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				);                                        

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
				,	dt_svc.full_dt as service_date                                               
					from uhcdm001.cs_inpatient md                                                
				  %do i=1 %to &inp_dx_fld_num; join uhcdm001.diagnosis_code_&i. dx&i. on md.diag_&i._cd_sys_id = dx&i..diag_&i._cd_sys_id %if &i ne &inp_dx_fld_num %then %str( ); %end;
				  %do i=1 %to &inp_proc_fld_num; join uhcdm001.procedure_code_&i. p&i. on md.proc_&i._cd_sys_id = p&i..proc_&i._cd_sys_id %if &i ne &inp_proc_fld_num %then %str( ); %end;
					join uhcdm001.place_of_service_code p                                        
					on md.pl_of_srvc_sys_id = p.pl_of_srvc_sys_id                                
					join uhcdm001.hp_date dt_svc                                                 
					on md.fst_srvc_dt_sys_id = dt_svc.dt_sys_id                                  
					where ( 
					(%do i=1 %to &inp_proc_fld_num; p&i..proc_&i._cd in (&apsy_t.) %if &i ne &inp_proc_fld_num %then %str(or); %end;)																				
					)					 
					and dt_svc.year_nbr >= &cur_st_yrn.									
				); 

disconnect from teradata;
quit;

/*-----------------------------------------------------------------*/
/*---> INITIAL ID PERIOD COHORT <----------------------------------*/
/**/
proc sql;
create table cht.v&out_dsn_pfx._01_invega_mbrs as (
select distinct mbrs.&person_id. from (
 															select &person_id. from inp.v&out_dsn_pfx._01_sust_rx_raw 
 										union all select &person_id. from inp.v&out_dsn_pfx._01_sust_mx_out_raw 
 										union all select &person_id. from inp.v&out_dsn_pfx._01_sust_mx_inp_raw 
 										union all select &person_id. from inp.v&out_dsn_pfx._01_trin_rx_raw 
 										union all select &person_id. from inp.v&out_dsn_pfx._01_trin_mx_out_raw
 										union all select &person_id. from inp.v&out_dsn_pfx._01_trin_mx_inp_raw 										
 										) mbrs
);
quit;

/*-----------------------------------------------------------------*/
/*---> UGAP ENROLLMENT <-------------------------------------------*/
/**/
proc delete data=ugap_tmp.t&out_dsn_pfx._mbrs; run;

proc sql;              
*CREATE VOLATILE TABLE OF MEMBERS;
connect to teradata_tmp (&ugap_specs. bulkload=yes);	
	execute(
	create volatile table t&out_dsn_pfx._mbrs 
					(&person_id. numeric(9)) 
					primary index (&person_id.) 
					on commit preserve rows
				) by teradata_tmp;
	insert into ugap_tmp.t&out_dsn_pfx._mbrs
          select distinct &person_id.
          from cht.v&out_dsn_pfx._01_invega_mbrs;

*PULL ENROLLMENT;
proc sql;          
connect to teradata (&ugap_specs.);	

	create table inp.v&out_dsn_pfx._01_mbr_enr_raw as
		select * from connection to teradata
		    (

		    select
					mbr.&person_id. as &person_id.
				,	dt_eff.full_dt as eff_date                                               
				,	dt_end.full_dt as end_date                                               
				, mbr.dob	as date_of_birth
				, mbr.gdr_cd
				, rx_cov.phrm_cov_ind
					from uhcdm001.cs_enrollment mbr
					join uhcdm001.hp_date dt_eff                                                 
					on mbr.eff_dt_sys_id = dt_eff.eff_dt_sys_id                                  
					join uhcdm001.hp_date dt_end                                                 
					on mbr.end_dt_sys_id = dt_end.end_dt_sys_id                                  
					join uhcdm001.pharmacy_coverage rx_cov                                                 
					on mbr.phrm_cov_sys_id = rx_cov.phrm_cov_sys_id                                  
					where rx.&person_id in (select &person_id. from t&out_dsn_pfx._mbrs) 				
				);

disconnect from teradata;
quit;
proc delete data=ugap_tmp.t&out_dsn_pfx._mbrs; run;

/*------> CLEANUP <------------------------------------------------*/
/**/ 

*DELETE ANY LEFTOVER DATA;
proc datasets nolist; delete t&out_dsn_pfx.:; quit;


%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/
%amdg(out_dsn_pfx=200,testobs=);



