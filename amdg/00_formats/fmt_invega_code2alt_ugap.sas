/*-----------------------------------------------------------------*\
 | CODES INPUT AND FORMATTING STATEMENT								      				 |
 | AUTHOR: MICHAEL W EDWARDS 10-15-18 AMDG                           |
 \*-----------------------------------------------------------------*/
/**/

*CODESET INPUT.  MATCHES PROC FORMAT CNTLIN= SYNTAX;
*FMTNAME = THREE-LETER ALPHA DESIGNATION FOR GROUPING 
*(I.E. "RA" = RHEUMATOID ARTHRITIS);
*TYPE = FORMAT TYPE;
*START = CODES;
*LABEL = FORMAT VALUE;
data tmp_rawcodes(keep=start label); 
infile cards dsd dlm='|';
input
start				:$11. 
label				:3.;
cards;
50458056201|594252
50458056301|594253
50458056401|594255
50458060701|594294
50458060601|594293
50458056001|594250
50458060801|594295
50458056101|594251
50458060901|594296
C9255|214527
J2426|248494
	;
run;

*FORMAT TO RETURN ANY CODE GROUP PROVIDED GIVEN CODE;
data tmp_rawcodes2;
   retain fmtname 'invega_code2alt_ugap' type 'i' hlo '';
   set tmp_rawcodes end=last;
   output;
   if last then do; start=''; hlo = 'O'; label=99999; output; end;   
run;
proc format cntlin=tmp_rawcodes2 library=work; run;

proc datasets nolist; delete tmp_:; run;





