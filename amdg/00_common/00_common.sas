 /*-----------------------------------------------------------------*\
 | PROGRAM TO DEFINE GENERIC MACRO VARIABLES AND LIBNAME FOR COMMON  |
 | USE IN MANY/ALL PROJECTS.  THE MAIN PURPOSE TO MAXIMIZE           |
 | PORTABILITY OF PROGRAMS BY LIMITING THE HARD-CODING OF DIRECTORY  |
 | NAMES WHERE GENERIC PROGRAMS AND LIBRARIES ARE LOCATED ON THE     |
 | SERVER.                                                           |
 | AUTHOR: FELIX FRIEDMAN 2013-08-19                                 |
 | MODIFIED: MICHAEL W EDWARDS 2018-01-03														 |
 \*-----------------------------------------------------------------*/
title1 "Michael W Edwards - AMDG - ";
%let code_fldr = amdg;

 /*-----------------------------------------------------------------*/
 /*---> DEFINE TOP LEVEL DIRECTORIES <------------------------------*/
/**/
%let om_code			 = /sasnas/ls_cs_nas/mwe/janssen/invega_vbc_202003/&code_fldr.; 				*<---CODE;
%let om_data			 = /hpsaslca/mwe/janssen/invega_vbc_202003/&code_fldr._data;		*<---DATA;
%let om_formats		 = &om_code/00_formats;  																				*<---FORMATS;
%let om_common		 = &om_code/00_common;  																				*<---COMMON CODE;
%let om_macros		 = /sasnas/ls_cs_nas/mwe/zz_common/00_macros;														*<---MACROS;
%let om_mst_common = /sasnas/ls_cs_nas/mwe/zz_common/00_common;														*<---MASTER COMMON;
%let om_mst_formats= /sasnas/ls_cs_nas/mwe/zz_common/00_formats;													*<---MASTER FORMATS;
%let fmtlib=work; * <=== SPECIFY FORMATS DIRECTORY ("WORK" IS OKAY);

data _null_;
   put
      / @01 80*"#"
      / @01 "NOTE: The following global macro variables were defined:"
      / @10 "om_code			 = &om_code			"
      / @10 "om_common		 = &om_common		"
      / @10 "om_formats		 = &om_formats	"      
      / @10 "om_macros		 = &om_macros		"  
      / @10 "om_data			 = &om_data			"
      / @01 80*"#" /;
run;

 /*-----------------------------------------------------------------*/
 /*---> ALPHA  <----------------------------------------------------*/
/**/
libname	 fmts 	  "&om_data/00_formats";									* <---FORMATS LIBRARY;
libname	 cht 			"&om_data/01_cohort";										* <---COHORT LIBRARIES;
libname	 inp 			"&om_data/02_input";										* <---INPUT LIBRARIES;
libname	 ads 		 	"&om_data/04_ads";											* <---ADS LIBRARIES;
libname	 rep 		 	"&om_data/05_out_rep";									* <---REPORT LIBRARIES;
libname  zz_com		"/sasnas/ls_cs_nas/mwe/zz_common_data";					* <---COMMON DATA;
%include "/sasnas/ls_cs_nas/mwe/zz_common/00_common/00_key.sas";  * <---CREDENTIALS;
 /*-----------------------------------------------------------------*/
 /*---> GENERIC SAS SESSION OPTIONS <-------------------------------*/
/**/
%let Teradata_Opt = cast=yes bulkload=yes dbsliceparm=all dbindex=yes fastexport=yes;
options missing ='' ps=60 ls=170 lrecl=10000 nocenter nomprint nosymbolgen nomacrogen nomlogic
   sqlconstdatetime nofmterr fmtsearch=(work fmts) compress=binary
   sasautos=("%sysfunc(pathname(sasautos))" "&om_macros");
ods noproctitle;

 /*-----------------------------------------------------------------*/
