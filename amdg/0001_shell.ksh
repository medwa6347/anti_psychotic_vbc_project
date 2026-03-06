#!/usr/bin/ksh
#######################################################################################
# Author:  M.W. Kirksey, with edits by Michael Edwards
# Date  :  12/09/2019
# Descrp:  0000_shell.ksh - execute SAS on HPA
#
########################################	AMDG  #######################################
#
#######################################################################################

#######################################################################################
# Script debugging option.  Uncomment for debug mode.
#######################################################################################
# set -x   # Uncomment to debug this shell script (Korn shell only)

#######################################################################################
# Assign
# - client
# - script ID
# - production source code directory (d)
# - test source code directory (t)
# - project root directory (p)
# - SAS Data library (lib)
# - iteration ID (i)
# - Email Address (eml) - In case of job/step failure or job conclusion
#######################################################################################
client=Janssen
script=0001_shell.ksh
d=/sasnas/ls_cs_nas/mwe/janssen/invega_vbc_202003/amdg
p=/sasnas/ls_cs_nas/mwe/janssen/invega_vbc_202003/amdg
lib=/hpsaslca/mwe/janssen/invega_vbc_202003/amdg_data/05_out_rep
i=_v700
eml=$( grep -oP "(?<=').*(?=')" /sasnas/ls_cs_nas/mwe/zz_common/00_common/00_email.txt )

#######################################################################################
# Step 01:  Run 0100_invega_vbc_raw_data_pull.sas
#
#           - Datetime stamp (dt) - Attach to log and report name
#           - Specify program (pgm) name (without .sas) at each step
#           - Specify step code (scode) reference
#
#           sas <SAS Source code folder/<sas program>.sas
#           -AUTOEXEC <SAS Source code folder/<sas program>.sas
#           -LOG = SAS Logs folder
#           -RPT = SAS Reports folder
#           -SYSPARM = Parameter string 
#           -MEMSIZE = Memorary allocation
#           -F = Run job in foreground.  Need to do to capture RC, properly
#           -GRIDJOBNAME = Assign a unique job name to the job
#
#######################################################################################
dt=$(date +'%Y%m%d.%H.%M.%S')
pgm=01_invega_vbc_raw_data_pull
scode=01
sas_tws ${d}/${pgm}.sas \
    -autoexec ${p}/00_common/00_common.sas \
    -sysparm ${i} \
    -log ${p}/00_loglst/keep/v700/${pgm}${i}_${dt}.log \
    -print ${p}/00_loglst/keep/v700/${pgm}${i}_${dt}.lst \
    -memsize 1G \
    -f \
    -GRIDJOBNAME ${script:0:7}_${scode}

rc=$?
if (( ${rc} == 1 )) then
  rc=0  ## Allow for SAS Warnings
elif (( ${rc} == 47 )) then
  rc=0  ## Log/Report copy delay
fi
echo ${scode}' - Preliminary RC='${rc}

if (( ${rc} != 0 )) then
  echo 'Current Step:  '${scode}
  echo 'Error in Step.  Error Code='${rc}
  echo "${script} - Job Failure:  Step "${scode} | mailx -s "$client - ${script}" "${eml}"
  exit ${scode}  ## Use current step as exit code
fi

#######################################################################################
# Write Success message, if the job had no errors
#######################################################################################
echo "Job ${script} completed successfully!"
echo "${client} - ${script} / Job Completed!" | mailx -s "$client - ${script}" "${eml}"

#######################################################################################
# End of Script.
#######################################################################################