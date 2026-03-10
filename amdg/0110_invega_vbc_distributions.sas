 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC INVEGA VBC ANALYSIS FOR JANSSEN - CLAIMS		|
 | PROGRAM 1 OF 2 - RAW DATA PULL									|
 |  HTTP://DMO.OPTUM.COM/PRODUCTS/UGAP.HTML							|
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
%util_dates(start_dt='01Jan2019'd,yr_num=1,months=18)
data _null_; call symput("sysdate_word",left(put("&sysdate"d,worddate.))); run;

/**/ 
* WATERFALL; 
proc sql noprint; create table rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall as select "wf01_sustenna_raw_rx_mbr_count" as wlevel length = 50, "All Invega Sustenna Distinct Rx Members" as wlevel_disc length=150, count(distinct &person_id.) as distinct_mbrs format=comma12. from inp.v&rd_vz._01_sust_rx_raw; 
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_sustenna_raw_mx_out_mbr_count" as wlevel, "All Invega Sustenna Distinct Outpatient Mx Members" as wlevel_disc, count(distinct &person_id.) as distinct_members from inp.v&rd_vz._01_sust_mx_out_raw;	
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_sustenna_raw_mx_inp_mbr_count" as wlevel, "All Invega Sustenna Distinct Inpatient Mx Members" as wlevel_disc, count(distinct &person_id.) as distinct_members from inp.v&rd_vz._01_sust_mx_inp_raw;	
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_trinza_raw_rx_mbr_count" as wlevel, "All Invega Trinza Distinct Rx Members" as wlevel_disc, count(distinct &person_id.) as distinct_members from inp.v&rd_vz._01_trin_rx_raw;	
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_trinza_raw_mx_out_mbr_count" as wlevel, "All Invega Trinza Distinct Outpatient Mx Members" as wlevel_disc, count(distinct &person_id.) as distinct_members from inp.v&rd_vz._01_trin_mx_out_raw;	
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_trinza_raw_mx_inp_mbr_count" as wlevel, "All Invega Trinza Distinct Inpatient Mx Members" as wlevel_disc, count(distinct &person_id.) as distinct_members from inp.v&rd_vz._01_trin_mx_inp_raw;	 			
 									insert into rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall select "wf01_mxrx_unq_mbr_count" as wlevel, "All Invega Distinct Members" as wlevel_disc, count(distinct mbrs.&person_id.) as distinct_members from (
 															select &person_id. from inp.v&rd_vz._01_sust_rx_raw 
 										union all select &person_id. from inp.v&rd_vz._01_sust_mx_out_raw 
 										union all select &person_id. from inp.v&rd_vz._01_sust_mx_inp_raw 
 										union all select &person_id. from inp.v&rd_vz._01_trin_rx_raw 
 										union all select &person_id. from inp.v&rd_vz._01_trin_mx_out_raw
 										union all select &person_id. from inp.v&rd_vz._01_trin_mx_inp_raw 										
 										) mbrs;	
quit; 
proc print data=rep.v&rd_vz.&sd_vz.&rp_vz._r1_waterfall; title "Invega Waterfall"; run;

* CLAIM FREQUENCIES; 
proc freq data=inp.v&rd_vz._01_sust_rx_raw; tables fill_date; format fill_date yymmn6.; title "Invega Sustenna Rx Frequency by YearMonth"; run;
proc freq data=inp.v&rd_vz._01_sust_mx_out_raw; tables service_date; format service_date yymmn6.; title "Invega Sustenna Outpatient Mx Frequency by YearMonth"; run;
proc freq data=inp.v&rd_vz._01_sust_mx_inp_raw; tables service_date; format service_date yymmn6.; title "Invega Sustenna Inpatient Mx Frequency by YearMonth"; run;

proc freq data=inp.v&rd_vz._01_trin_rx_raw; tables fill_date; format fill_date yymmn6.; title "Invega Trinza Rx Frequency by YearMonth"; run;
proc freq data=inp.v&rd_vz._01_trin_mx_out_raw; tables service_date; format service_date yymmn6.; title "Invega Trinza Outpatient Mx Frequency by YearMonth"; run;
proc freq data=inp.v&rd_vz._01_trin_mx_inp_raw; tables service_date; format service_date yymmn6.; title "Invega Trinza Inpatient Mx Frequency by YearMonth"; run;

/**/ 
* DAYS SUPPLY ANALYSIS; 
proc freq data=inp.v&rd_vz._01_sust_rx_raw order=freq; 
	tables days_supply / missing; title "Invega Sustenna Rx Days Supply Frequency"; 
run;
proc freq data=inp.v&rd_vz._01_trin_rx_raw order=freq; 
	tables days_supply / missing; title "Invega Trinza Rx Days Supply Frequency"; 
run;
* SERVICE UNIT COUNT ANALYSIS; 
proc freq data=inp.v&rd_vz._01_sust_mx_out_raw order=freq; 
	tables adj_srvc_unit_cnt / missing; title "Invega Sustenna Outpatient Mx Adjusted Service Unit Count Frequency"; 
run;
proc freq data=inp.v&rd_vz._01_sust_mx_inp_raw order=freq; 
	tables adj_srvc_unit_cnt / missing; title "Invega Sustenna Inpatient Mx Adjusted Service Unit Count Frequency"; 
run;
proc freq data=inp.v&rd_vz._01_trin_mx_out_raw order=freq; 
	tables adj_srvc_unit_cnt / missing; title "Invega Trinza Outpatient Mx Adjusted Service Unit Count Frequency"; 
run;
proc freq data=inp.v&rd_vz._01_trin_mx_inp_raw order=freq; 
	tables adj_srvc_unit_cnt / missing; title "Invega Trinza Inpatient Mx Adjusted Service Unit Count Frequency"; 
run;

/*------> CLEANUP <------------------------------------------------*/
/**/ 

*DELETE ANY LEFTOVER DATA;
proc datasets nolist; delete t&rd_vz.&sd_vz.&rp_vz.:; quit;

%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/
%amdg(rd_vz=2,sd_vz=0,rp_vz=0,testobs=);



