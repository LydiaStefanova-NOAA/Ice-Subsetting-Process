#!/bin/bash 
#SBATCH --ntasks=1 -p service
#SBATCH -A fv3-cpu
#SBATCH -q batch 
#SBATCH -t 08:00:00
##SBATCH -q debug
##SBATCH -t 30
#SBATCH -J p6_ice_subset

module load intel
module load netcdf
module load nco
module load hpss 

set -x 

#===  set start/end year and month 
ystart=2016; yend=2018; ystep=1
mstart=1; mend=12; mstep=1


#=== set HPSS source, temporary work directory, and  storage directory

model=ufs_p6
hpssdir=/NCEPDEV/emc-climate/5year/Jiande.Wang/HERA/prototype6.0/c384/
tmpdir=$scratch/fromHPSS/${model}
storedir=$noscrub/Models/${model}/SeaIce

#=== work below
for (( yyyystart=$ystart; yyyystart<=$yend; yyyystart+=$ystep )) ; do
for (( mm1=$mstart; mm1<=$mend; mm1+=$mstep )) ; do
for dd1 in {15..15..140} ; do
    mmstart=$(printf "%02d" $mm1)
    ddstart=$(printf "%02d" $dd1)
    tag=$yyyystart$mmstart$ddstart
    mkdir -p $tmpdir/${tag}
    cd $tmpdir/${tag}
    workdir=$tmpdir/${tag}/gfs.${tag}/00

#==== do this?
doice=yes

    #=== do ice subset files if not yet done
    if [ $doice == "yes" ] ; then
          #htar -xvf $hpssdir/${tag}00/ice.tar 

          startdate=${yyyystart}${mmstart}${ddstart}
          nowdate=$startdate
          enddate=`date '+%C%y%m%d' -d "$startdate+34 days"`

          mkdir $storedir/$tag
          mkdir $storedir/$tag/6hrly

          if [ ! -f $workdir/ice${enddate}00.01.${startdate}00.subset.nc ] ; then
             while [ $nowdate -le $enddate ] ; do
                   yyyy=${nowdate:0:4}
                   mm=${nowdate:4:2}
                   dd=${nowdate:6:2}
                   for hh1 in {0..18..6} ; do
                       hh=$(printf "%02d" $hh1)
                       if [ ! -f $storedir/$tag/6hrly/ice${nowdate}${hh}.01.${startdate}00.subset.nc ] ; then
                          if [ $nowdate -ne $startdate ] || [ $hh -gt 0 ] ; then
                          filein=$workdir/ice${nowdate}${hh}.01.${startdate}00.nc
                          fileout=$storedir/$tag/6hrly/ice${nowdate}${hh}.01.${startdate}00.subset.nc
                          htar -xvf $hpssdir/${tag}00/ice.tar ./gfs.${tag}/00/ice${nowdate}${hh}.01.${startdate}00.nc
                          if [ ! -f $filein ] ; then
                             gunzip $filein
                          fi
                          wait
                          ncks -v aice_h,hi_h,hs_h,Tsfc_h,uvel_h,vvel_h,frz_onset_h,mlt_onset_h $filein $fileout
                          fi
                       fi
                   done
                   nowdate=`date '+%C%y%m%d' -d "$nowdate+1 days"`
             done
             if [ ! -f $storedir/$tag/6hrly/ice${nowdate}00.01.${startdate}00.subset.nc ] ; then
                 filein=$workdir/ice${nowdate}00.01.${startdate}00.nc
                 fileout=$storedir/$tag/6hrly/ice${nowdate}00.01.${startdate}00.subset.nc
                 htar -xvf $hpssdir/${tag}00/ice.tar ./gfs.${tag}/00/ice${nowdate}00.01.${startdate}00.nc
                 if [ ! -f $filein ] ; then
                     gunzip $filein
                 fi
                 wait
                 ncks -v aice_h,hi_h,hs_h,Tsfc_h,uvel_h,vvel_h,frz_onset_h,mlt_onset_h $filein $fileout
                 ##rm $workdir/ice*00.nc
             fi
          fi
    fi

done
done
done
