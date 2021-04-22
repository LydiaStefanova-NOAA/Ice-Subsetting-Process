#!/bin/bash 
#SBATCH --ntasks=1  
#SBATCH -A fv3-cpu
##SBATCH -q batch
##SBATCH -t 4:00:00
#SBATCH -q debug
#SBATCH -t 30
#SBATCH -J todaily

module load intel
module load netcdf
module load nco
#set -x 

#===  set start/end year and month 
ystart=2015; yend=2018; ystep=100
mstart=9; mend=12 ;  mstep=100
dstart=1; dend=15; dstep=14
todaily=yes

subsetdir=$noscrub/Models/ufs_p6/SeaIce
dailydir=${subsetdir}

#==== do aggregation of hourly to daily4
     if [ $todaily == "yes" ] ; then
     for (( yyyystart=$ystart; yyyystart<=$yend; yyyystart+=$ystep )) ; do
        for (( mm1=$mstart; mm1<=$mend; mm1+=$mstep )) ; do
           for (( dd1=$dstart; dd1<=$dend; dd1+=$dstep )) ; do

               mmstart=$(printf "%02d" $mm1)
               ddstart=$(printf "%02d" $dd1)
               tag=$yyyystart$mmstart$ddstart

               startdate=${yyyystart}${mmstart}${ddstart}
               nowdate=$startdate
               enddate=`date '+%C%y%m%d' -d "$startdate+34 days"`

               mkdir -p $dailydir/${tag}

               if [ -f $subsetdir/$tag/6hrly/ice${nowdate}06.01.${startdate}00.subset.nc ] ; then
                       while [ $nowdate -le $enddate ] ; do

                             tomorrow=`date '+%C%y%m%d' -d "$nowdate+1 days"`

                             if [ ! -f $dailydir/$tag/ice${nowdate}.01.${startdate}00.subset.nc ] ; then
                                echo ${nowdate}06 ${nowdate}12 ${nowdate}18 ${tomorrow}00

                                filein1=$subsetdir/$tag/6hrly/ice${nowdate}06.01.${startdate}00.subset.nc
                                filein2=$subsetdir/$tag/6hrly/ice${nowdate}12.01.${startdate}00.subset.nc
                                filein3=$subsetdir/$tag/6hrly/ice${nowdate}18.01.${startdate}00.subset.nc
                                filein4=$subsetdir/$tag/6hrly/ice${tomorrow}00.01.${startdate}00.subset.nc
                                fileout=$dailydir/$tag/ice${nowdate}.01.${startdate}00.subset.nc

                                echo now doing $fileout
                                ncra -O -v aice_h,hi_h,hs_h,Tsfc_h,uvel_h,vvel_h,frz_onset_h,mlt_onset_h $filein1 $filein2 $filein3 $filein4 $fileout
                             else 
                                echo $dailydir/$tag/ice${nowdate}.01.${startdate}00.subset.nc already done
                             fi  
                             nowdate=`date '+%C%y%m%d' -d "$nowdate+1 days"`
                       done
              fi
         done
       done
     done
     fi
