#!/usr/bin/env bash

#fractional intensity should be determined prior running atlasBREX
#nohup siterate.sh &

echo "PID: $BASHPID"

for file in *'sj_'*'.nii.gz'*
do

btemplate=b_T1_2weeks.nii.gz
nbtemplate=nb_T1_2weeks.nii.gz

#remove 'sj'
name=$(echo $file | cut -d "_" -f2- )

#atlasBREX: FNIRT
bash atlasBREX.sh -b $btemplate -nb $nbtemplate -h $file -f 0.8 -reg 1 -w 5,5,5 -msk a,0,0
wait

#remove prefix and rename
mv -f ${file%%.*}_brain.nii.gz FNIRT_${name%%.*}_brain.nii.gz 
mv -f ${file%%.*}_brain_lin.nii.gz FLIRT_${name%%.*}_brain_lin.nii.gz 

#remove warp files and matrix
rm -f *std2high*

wait 

#atlasBREX: ANTs/SyN
bash atlasBREX.sh -b $btemplate -nb $nbtemplate -h $file -f 0.8 -reg 2 -w 1 -msk a,0,0
wait

#remove prefix and rename
mv -f ${file%%.*}_brain.nii.gz SyN_${name%%.*}_brain.nii.gz 
mv -f ${file%%.*}_brain_lin.nii.gz ANTS_${name%%.*}_brain_lin.nii.gz

#remove warp files and matrix
rm -f *std2high*

wait 

done
