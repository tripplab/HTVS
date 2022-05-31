
################################# runDock by trippm@bmd ##########################
##                                                                              ##
## ./runDock.sh > my_unique.log &                                               ##
##                                                                              ##
############################ User Configuration ##################################

ver=15072021

## CB-Dock path (install from http://clab.labshare.cn/cb-dock/php/manual.php#download)
cbdock=/path/to/perl_file/CB-Dock/prog/AutoBlindDock.pl

#####

## How many independent docking cycles
cycles=$2

## How many cavities to dock/report (ranked by size)
ncavs=$3

nT=$4
nL=$5

## Docking results will be organized here during calculation and used for analysis
DDir="docking"
RDir="results"
vizDir="${RDir}/viz"

## Will put the results of the last N cycles in the AllData file
## Goal: shave to have a consistent number of columns
## This will only affect what is written on the AllData file (allresF="${RDir}/docking_all_data.csv")
#keepNcycles=$cycles
keepNcycles=30

## if need to exclude first k cycles from analsis for some reason
exclude_cycles=0

###########################################################

## Do docking =1 , do analysis =2
if [[ $1 -eq 1 ]]; then
 #echo "$1 docking $calc"
 calc=1
elif [[ $1 -eq 2 ]]; then
 #echo "$1 anal $calc"
 calc=2
elif [[ $1 -eq 3 ]]; then
 #echo "$1 cavs $calc"
 calc=3
elif [[ $1 -eq 4 ]]; then
 #echo "$1 best $calc"
 calc=4
elif [[ $1 -eq 5 ]]; then
 #echo "$1 replace $calc"
 calc=5
elif [[ $1 -eq 6 ]]; then
 #echo "$1 viz $calc"
 calc=6
elif [[ $1 -eq 7 ]]; then
 #echo "$1 tar $calc"
 calc=7
else
    echo "Illegal first parameter"
    echo "CBDock.sh dock=1|anal=2|cavities=3|best=4|replace=5|viz=6|tar=7"
    exit 2
fi

#narg=$#
calcArg=$((5+nT+nL))
analArg=$((5+nT+nL+nT))
replArg=$((5+nT+nL+1))
vizArg=$((5+nT+nL+3))
#echo $calcArg $analArg

i=1;
for param in "$@" 
do
    #echo "parameter - $i: $param";
    i=$((i + 1));
done

if [[ $calc -eq 1 && $# -ne $calcArg ]]; then
    echo "Illegal number of parameters: expecting $calcArg, found $#"
    echo "CBDock.sh 1 cycles ncavs ntargets nligands targ1...targn lig1...lign"
    exit 2
elif [[ $calc -eq 2 && $# -eq $calcArg ]]; then
    echo "Will do automatic analysis of all $ncavs cavities per target"
    all_cavs=1
    for_ncavs=$ncavs
elif [[ $calc -eq 2 && $# -eq $analArg ]]; then
    echo "Will do analysis of cavities defined by user for the targets"
    all_cavs=0
    for_ncavs=1
elif [[ $calc -eq 2 ]]; then
    echo "Illegal number of parameters: expecting $calcArg or $analArg, found $#"
    echo "CBDock.sh 2 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn"
    exit 2
elif [[ $calc -eq 5 && $# -ne $replArg ]]; then
    echo "Illegal number of parameters: expecting $replArg, found $#"
    echo "CBDock.sh 5 cycles ncavs ntargets nligands targ1...targn lig1...lign file.csv"
    exit 2
elif [[ $calc -eq 6 && $# -ne $vizArg ]]; then
    echo "Illegal number of parameters: expecting $vizArg, found $#"
    echo "CBDock.sh 6 cycles ncavs ntargets nligands targ1...targn lig1...lign state_file tmp_tar tmp_lig"
    exit 2
fi

shift 5

## List of target proteins
## structure must be in target/Tname1/Tname1.pdb
## prepare file with chimera's Dock Prep (in 'Structure Editing' menu)
## https://www.cgl.ucsf.edu/chimera/docs/ContributedSoftware/dockprep/dockprep.html
for (( t=1; t<=$nT; t++ ))
do  
   #echo " $t $1"
   target+=($1)
   shift 1
done

## List of ligands
## structure must be in ligands/Lname1.mol2 AND ligands/Lname1.pdbqt
## those files can be generated with MGLTools ADT
for (( l=1; l<=$nL; l++ ))
do  
   #echo " $l $1"
   ligand+=($1)
   shift 1
done

## List of cavities found for analysis
## label of the cavity of the corresponding target
## found in docking/target/ligand/ligand-target-id_number/ligand-target-id_number_results.txt
if [[ $calc -eq 2 ]]
then
 for (( c=1; c<=$nT; c++ ))
 do  
   #echo " $c $1"
   cavity+=($1)
   shift 1
 done
elif [[ $calc -eq 5 ]]
then
 inF=$1
elif [[ $calc -eq 6 ]]
then
 inF=$1
 tmpT=$2
 tmpL=$3
 #echo test viz $inF $tmpT $tmpL
fi

#for t in ${!target[@]} ## for every target in the list
#do
#    echo ${target[$t]}
#done
#
#for l in ${!ligand[@]} ## for every ligand in the list
#do
#    echo ${ligand[$l]}
#done
#
#for c in ${!cavi01[@]} ## for every cavity in the list
#do
#    echo ${cavi01[$c]}
#done
#

NT=${#target[@]}
NL=${#ligand[@]}
echo "Will work with $NT targets and $NL ligands"
echo "Targets: ${target[@]}"
if [[ $all_cavs -eq 0 ]]
then
 echo "Cavities: ${cavity[@]}"
fi
echo "Ligands: ${ligand[@]}"
echo ""

## https://tldp.org/LDP/abs/html/timedate.html
MPHR=60    # Minutes per hour.
HPD=24     # Hours per day.

## https://linuxize.com/post/bash-functions/
diff2 () {
        printf '%s' $(( $(date -u -d"$2" +%s) -
                        $(date -u -d"$1" +%s)))
}

## to avoid "perl: warning: Setting locale failed"
## https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"


###########################################################

if [[ $calc -eq 1 ]]  
then
 DockStart=$(date)
 echo 'Doing Docking with version ' $ver
 echo 'Job starting on ' $DockStart
 echo 'Reporting: ' $ncavs ' cavities'

 n="1"
 while [ $n -le $cycles ]
 do ## for cycles

  CycleStart=$(date)
  echo '******************************'
  echo 'Cycle: ' $n ' starting on ' $CycleStart
  echo

  for T in ${!target[@]} ## for every target in the list
  do ## for targets

    TargetStart=$(date)
    echo -en 'Target: ' ${target[$T]} 
    echo ' Cycle ' $n ' of ' $cycles '. TIME Starting on ' $TargetStart

    TStruct=target/${target[$T]}/${target[$T]}.pdb
    if [ -f "$TStruct" ]; then
       ##ls -l $TStruct
       echo "Found structure file: " $TStruct
    else
       echo "ERROR Did not find structure file: " $TStruct
       exit
    fi

    for L in ${!ligand[@]} ## for every ligand in the list
    do  ## for ligands
      echo
      echo
      echo
      LigandStart=$(date)
      echo -en 'Ligand: ' ${ligand[$L]} 
      echo -en ' Target: ' ${target[$T]} 
      echo ' Cycle: ' $n ' of ' $cycles '. TIME Starting on ' $LigandStart

      LStruct=ligands/${ligand[$L]}.mol2
      if [ -f "$LStruct" ]; then
         ##ls -l $LStruct
         echo "Found structure file: " $LStruct

      else
         echo "ERROR Did not find structure file: " $LStruct
         exit
      fi
      Lpdbqt=ligands/${ligand[$L]}.pdbqt
      if [ -f "$Lpdbqt" ]; then
         ##ls -l $Lpdbqt
         echo "Found pdbqt file: " $Lpdbqt
      else
         echo "WARNING Did not find pdbqt file: " $Lpdbqt
      fi

      mkdir -vp ${DDir}/${target[$T]}/${ligand[$L]}

########################   CBDock VINA   ###################################      
      ## Target_PDB Ligand_MOL2 How_Many_Cavs Wher_to_put_results
      ${cbdock} $TStruct $LStruct $ncavs ${target[$T]}/${ligand[$L]}
############################################################################      

      LigandEnd=$(date)
      MINS=$(( $(diff2 "$LigandStart" "$LigandEnd") / $MPHR ))
      echo
      echo -en 'Ligand: ' ${ligand[$L]} 
      echo -en ' Target: ' ${target[$T]} 
      echo -en ' Cycle: ' $n ' of ' $cycles '. TIME Ending on ' $LigandEnd
      echo ". ELAPSED: $MINS minutes"
      echo
      echo
    done  ## for ligands

    TargetEnd=$(date)
    MINS=$(( $(diff2 "$TargetStart" "$TargetEnd") / $MPHR ))
    echo
    echo -en 'Target: ' ${target[$T]} 
    echo -en ' cycle ' $n ' of ' $cycles '. TIME Ending on ' $TargetEnd
    echo ". ELAPSED: $MINS minutes"
    echo
    echo
    echo
  done ## for targets

  CycleEnd=$(date)
  MINS=$(( $(diff2 "$CycleStart" "$CycleEnd") / $MPHR ))
  echo
  echo -en ' Cycle ' $n ' of ' $cycles '. TIME Ending on ' $CycleEnd
  echo ". ELAPSED: $MINS minutes"
  n=$[$n+1]
 done # for cycles

  DockEnd=$(date)
  MINS=$(( $(diff2 "$DockStart" "$DockEnd") / $MPHR ))
  echo
  echo -en ' Job done. TIME Ending on ' $DockEnd
  echo ". ELAPSED: $MINS minutes"

fi # if dock



###########################################################


 ## Cavities Matrix Data file
 cavF="cavities.dat"
 cavRF="cavities_rev.dat"



if [[ $calc -eq 2 ]]
then
 echo 'Doing anal with version ' $ver
 echo -en 'TIME Starting on '
 date

 allresF="${RDir}/docking_all_data.csv"

 if [ -f "$allresF" ]; then
    echo "Found  $allresF, will overwrite"
    rm $allresF
 fi

 for ((j=1; j<="$for_ncavs"; j++))
 #for n in 1 ## Read only once for testing
 do

    ## Results Matrix Data file
    if [[ $all_cavs -eq 1 ]]
    then

      if [ -f "${cavF}" ]; then
         echo "SUCCESS Found file: " $cavF
      else
         echo "ERROR Did not find file: " $cavF
         echo "First run CBDock.sh 3 Ncyc Ncav NT NL targets_list"
         echo
         exit 2
      fi

      cav_rank=$j
      echo "Quering cavity with rank $cav_rank"

      resF="${RDir}/docking_cav${cav_rank}.csv"
      echo "Results in $resF"

      ## https://www.baeldung.com/linux/read-command
      exec {file_descriptor}<"$cavF"
      declare -a cavity
      n=1
      while IFS=" " read -a cavity -u $file_descriptor 
      do
         #echo "$n: ${cavity[0]},${cavity[1]}" 
         if [[ $n -eq $((cav_rank + 1)) ]]
         then
          break
         fi
         n=$[$n+1]
      done
      exec {file_descriptor}>&-
  
      ## https://stackoverflow.com/questions/10586153/split-string-into-an-array-in-bash
      #echo "From input: ${cavi01[@]}"
      NC=${#cavity[@]}
         if [[ $NC -eq $NT ]]
         then
          echo "GOOD: $NC cavities found for $NT targets"
          echo "From file: ${cavity[@]}"
         else
          echo "WARNING: $NC cavities found for $NT targets"
          echo "From file: ${cavity[@]}"
          #exit 2
         fi

    elif [[ $all_cavs -eq 0 ]]
    then
       resF="${RDir}/docking_manual.csv"
    fi

    echo "Li_Ta, " > $resF
    for R in ${!ligand[@]} ## for every ligand in the list
    do
       echo ${ligand[$R]} ", " >> $resF
    done

     echo
     echo "-------------------begin--------------------"
     echo
     for i in ${!target[@]} ## for every target in the list
     do
       echo 'Target: ' ${target[$i]} ', cavity: ' ${cavity[$i]}
       resFtmp=results_${target[$i]}.out
       if [[ $((i + 1)) -lt $nT ]]
       then
        echo "${target[$i]}, " > $resFtmp
       else
        echo "${target[$i]} " > $resFtmp
       fi

         TDir=${DDir}/${target[$i]}
         if [ -d "$TDir" ]; then
            donothing=1
         else
            echo "ERROR Did not find directory: " $TDir
            exit 0
         fi

       result=()

       for R in ${!ligand[@]} ## for every ligand in the list
       do

         LDir=$TDir/${ligand[$R]}
         if [ -d "$LDir" ]; then
            donothing=1
         else
            echo "ERROR Did not find directory: " $LDir
            exit 0
         fi

         echo -en ${ligand[$R]} '\t'
#         grep ${cavity[$i]} $LDir/*/*results.txt | awk '{printf "%s %4.1f \n",$1,$9}' > tmp
         ## tmp will hold the affinity values ($9) and their location ($1) of ligand R in cavity j of target i as they were calculated in each cycle 
         ## ('-rt' oldest first and newest last, 
         ## PSC1, lf_01, cav_1, 19.3, 2.9,17.5, 5.2,13.9, 0.9, 4.5, 4.2, 4.5,12.9, 4.5, 5.0, 5.8, 12.4, 6.9, 7.6, 4.2,10.4, 1.0, 4.7, 8.6, 9.4, 5.2, 4.4,13.5, 4.2, 4.4 
         ## '-t' newest first and oldest last)
         ## PSC1, lf_01, cav_1,  4.4, 4.2,13.5, 4.4, 5.2, 9.4, 8.6, 4.7, 1.0,10.4, 4.2, 7.6, 6.9, 12.4, 5.8, 5.0, 4.5,12.9, 4.5, 4.2, 4.5, 0.9,13.9, 5.2,17.5, 2.9,19.3

	 #rank_cav="'^$cav_rank ${cavity[$i]} '"
         #echo "$i, ${target[$i]}, ${ligand[$R]}, $cav_rank, ${cavity[$i]}, $rank_cav"
         #ls -t $LDir/*/*results.txt | xargs -d '\n' grep ${cavity[$i]} | awk '{printf "%s %4.1f \n",$1,$9}' > tmp
         ls -t $LDir/*/*results.txt | xargs -d '\n' grep ^${cav_rank}' '${cavity[$i]}' ' | awk '{printf "%s %4.1f \n",$1,$9}' > tmp
         ## remove the first k lines if needed
         k=${exclude_cycles}
         tail -n+$k tmp > tmp3
         ## tmp2 will hold the affinity values ($2) and their location ($1) of ligand R in cavity j of target i in increasing order (lowest first and highest last)
         sort -k 2n tmp3 > tmp2
         cat tmp2 | awk '{printf "%4.1f ",$2}'

          echo -en "${target[$i]}, ${ligand[$R]}, cav_$j, " >> $allresF
          cat tmp3 | awk '{printf " %4.1f,",$2}' >> $allresF
          echo >> $allresF

         ##grep ${cavi01[$i]} $LDir/*/*res* | awk '{printf "%4.1f ",$9}'
         ##grep ${cavi01[$i]} docking/${target[$i]}/min/${R}/*/*res* | awk '{printf "%4.1f ",$9}'
         echo

         best=$(head -1 tmp2 | awk '{print $2}')
         bestDir=$(head -1 tmp2 | awk '{printf "%s ",$1}' | xargs dirname)
         ## This construction replaces all occurrences of '\/' (the initial // means global replace) in the 
         ## string bestDir with ' ' (a single space), then interprets the space-delimited string as an array 
         ## (that's what the surrounding parentheses do).
         ## eg: docking/4y29/01BF/01BF-4y29-20210118192707 -> 01BF-4y29-20210118192707
         BD=(${bestDir//\// })
         #echo ${BD[3]}

         resmol2=$(ls -l $bestDir/*out_${j}.*mol2 | awk '{printf "%s",$9}')
         mol2=(${resmol2//\// })
         #echo "resmol2: $resmol2, mol2: ${mol2[4]}"

         if [[ $((j)) -lt 10 ]]
         then
           lns="${target[$i]}-${ligand[$R]}_best_cav_0$j.mol2"
           sdf="${target[$i]}-${ligand[$R]}_best_cav_0$j.sdf"
           #lns="cav_0$j.mol2"
         else
           lns="${target[$i]}-${ligand[$R]}_best_cav_$j.mol2"
           sdf="${target[$i]}-${ligand[$R]}_best_cav_$j.sdf"
         fi

         BDir=$LDir/best

         if [ ! -d "$BDir" ]; then
            echo "Will create $BDir"
            mkdir $BDir
         fi

          CD=$(pwd)
          if [ -h "$BDir/$lns" ]; then
            echo "WARNING: Found $BDir/$lns, will replace it"
            rm -rf $BDir/$lns
            rm -rf $BDir/$sdf
            cd $BDir
            ln -s ../${BD[3]}/${mol2[4]} $lns
            #cd $CD
          else
            echo "Will create link $BDir/$lns"
            cd $BDir
            ln -s ../${BD[3]}/${mol2[4]} $lns
            #cd $CD
          fi

         ## convert from MOL2 to SDF format only the first model of cavity j
#         obabel -imol2 $lns -osdf -x3 -l 1 > $sdf

         cd $CD

         echo -en "Best affinity value is " $best " found in " $bestDir 
         ##head -1 tmp2 | awk '{printf "%f ",$2}'
         echo -en " out of "
         wc -l tmp2 | awk '{printf "%d ",$1}' 
         echo -e ' independent docking cycles. Data linked in ' $BDir/$lns
         ##head -1 tmp2 | awk '{printf "%s ",$1}' | xargs dirname
 
         result+=($best)
         if [[ $((i + 1)) -lt $nT ]]
         then
           echo $best ", " >> $resFtmp
         else
           echo $best >> $resFtmp
         fi
         #echo ${ligand[$R]} $best >> $resFtmp

       done # for ligands

       paste $resF $resFtmp > tmp4
       mv tmp4 $resF
       #echo ${result[@]}
       results+=(${result[@]})
       echo "-------------------done---------------------"
       echo

     done #for targets
 done # for cavs



     ## Put the first model for each cavity of each ligand for each target in a single SDF file
     for i in ${!target[@]} ## for every target in the list
     do

       TDir=${DDir}/${target[$i]}
       TsdfAll="${TDir}/${target[$i]}-ligands_best_cav_all.sdf"
       #touch $TsdfAll
       if [ -f "$TsdfAll" ]; then
            echo "WARNING: Found $TsdfAll, will replace it"
            rm $TsdfAll
       else
            echo "Will create $TsdfAll"
       fi

       for R in ${!ligand[@]} ## for every ligand in the list
       do

         LDir=$TDir/${ligand[$R]}
         BDir=$LDir/best
         sdfAll="${BDir}/${target[$i]}-${ligand[$R]}_best_cav_all.sdf"

         if [ -f "$sdfAll" ]; then
            echo "WARNING: Found $sdfAll, will replace it"
            rm $sdfAll
         else
            echo "Will create $sdfAll"
         fi

         for ((j=1; j<="$for_ncavs"; j++))
         do

           if [[ $((j)) -lt 10 ]]
           then
             sdf="${BDir}/${target[$i]}-${ligand[$R]}_best_cav_0$j.sdf"
           else
             sdf="${BDir}/${target[$i]}-${ligand[$R]}_best_cav_$j.sdf"
           fi

#           cat $sdf >> $sdfAll

         done # for cavs

#         cat $sdfAll >> $TsdfAll

       done # for ligands

     done #for targets


 ## Remove last comma character from every line of AllData File
 sed -i 's/.$//' $allresF
 ## Keep first 3+N columns
 keepNcycles=$((keepNcycles+3))
 cut -d "," -f-$keepNcycles $allresF > tmp5
 mv tmp5 $allresF
 awk '{printf "nFields: %s %s %s %d ",$1,$2,$3,NF-3;if(NF!='$((keepNcycles-0))'){print "WARNING"}else{print ""}}' $allresF > "$RDir/nFields.out"

 ## Clean/Remove temp files
 rm tmp* results_*

 echo
 echo "Created CSV files in ${RDir}"
 echo "Created nFields.out file in ${RDir}"
 echo
 echo -en 'TIME Ending on '
 date
fi # if anal
  

###########################################################


if [[ $calc -eq 3 ]]
then
 echo
 echo "-------------------begin--------------------"
 echo
 echo 'Doing cavities  with version ' $ver
 echo -en 'TIME Starting on '
 date

 rm $cavF $cavRF

 ##echo "cavities, " > $cavF
 #echo "   " > $cavF
 #n="1"
 #while [ $n -le $ncavs ]
 #do
 #   echo ${n} >> $cavF
 #   ##echo ${n} ", " >> $cavF
 #   n=$[$n+1]
 #done

  for i in ${!target[@]} ## for every target in the list
  do
    echo 'Target: ' ${target[$i]}

      TDir=${DDir}/${target[$i]}
      cavsF="${TDir}/conf.txt"
      if [ -f "${cavsF}" ]; then
         echo "SUCCESS Found file: " $cavsF
         donothing=1
      else
         echo "ERROR Did not find file: " $cavsF
         exit 0
      fi

     echo "${target[$i]} " > tmp

    result=()

    n="1"
    while [ $n -le $ncavs ]
    do
     cav_read=$(grep -P "^$n\t" ${cavsF} | awk '{printf "%d",$8}')
     echo "${cav_read} " >> tmp
     n=$[$n+1]
    done

    if [[ $((i + 0)) -eq 0 ]]
    then
     mv tmp $cavF
    else
     paste -d "" $cavF tmp > tmp2
     mv tmp2 $cavF
    fi

   done

   sep=" "
   numc=$(($(head -n 1 "$cavF" | grep -o "$sep" | wc -l)+1))
   for ((i=1; i<="$numc"; i++))
   do 
    cut -d "$sep" -f"$i" "$cavF" | paste -s -d "$sep" >> $cavRF
   done

 rm tmp*
 echo
 echo "Created files $cavF and $cavRF"
 echo
 echo -en 'TIME Ending on '
 date
 echo "-------------------done---------------------"
 echo
fi # if cavities



###########################################################




if [[ $calc -eq 4 ]]
then
 echo
 echo "-------------------begin--------------------"
 echo
 echo 'Doing extract best for ' $ncavs ' cavities with version' $ver
 echo -en 'TIME Starting on '
 date

   ## https://stackoverflow.com/questions/16487258/how-to-declare-2d-array-in-bash
   declare -A matrix
   declare -A rank_best
   num_rows=$NT
   num_columns=$NL
   
   for ((i=0;i<=num_rows;i++)) do
      tmpF=${RDir}'/'${target[$((i-0))]}'.csv'
      if [ -f "${tmpF}" ]; then
         rm $tmpF
      fi
   done
   ## Initialize 'matrix' cells
   ## Populate labels for targets (first row) and ligands (first column)
   for ((i=0;i<=num_rows;i++)) do
       #echo "i:$i " ${target[$i]}
       for ((j=0;j<=num_columns;j++)) do
         if [[ $j -lt $num_columns ]]
         then
          echo ${ligand[$((j-0))]} >> ${RDir}'/'${target[$((i-0))]}'.csv'
         fi
         #echo "j:$j " ${ligand[$j]}
           matrix[$i,$j]=1000
         if [[ $j -eq 0 ]]
         then
           rank_best[$((i+1)),$((j+0))]=${target[$i]}
           #echo "i:$i " ${target[$i]}
         elif [[ $i -eq 0 ]]
         then
           rank_best[$((i+0)),$((j+0))]=${ligand[$((j-1))]}
         else
           rank_best[$i,$j]=0
           #rank_best[$i,$j]="$i,$j"
         fi
       done
   done
   rank_best[0,0]='Li_Ta'

 for ((k=1;k<=ncavs;k++))
 #for ((k=1;k<=1;k++))
 do
#   echo "k: $k"

   resF="${RDir}/docking_cav${k}.csv"
   echo "Reading $resF"

   ## https://www.baeldung.com/linux/read-command
   exec {file_descriptor}<"$resF"
   declare -a cavity
   j=0  # rows
   while IFS="," read -a cavity -u $file_descriptor 
   do
#      echo -en "j$j: " 
      #for ((i=0;i<=num_rows;i++)) do
      for ((i=0;i<=NT;i++)) do   # columns
#        echo -en "i$i:${cavity[$i]} " 
        # tmpF="${RDir}/${target[$i]}.csv"
        #if [[ $j -eq 0 ]]; then  # first row
           #if [ -f "${tmpF}" ]; then
           #   rm ${tmpF}
           #fi
        #   echo "cav${k}" >> "${tmpF}"
        #fi
        #if [[ $i -gt 0 ]]; then
        #   echo $k $j $i ${cavity[$i]} >> ${RDir}'/'${target[$((i-1))]}'.csv'
        #fi
        if [[ $i -gt 0 && $j -gt 0 ]]; then
           echo ${cavity[$i]} >> ${RDir}'/'${target[$((i-1))]}'.csv'
         num1=${cavity[$i]}
         num2=${matrix[$i,$j]}
         #echo "Comparing " $num1, $num2
         if (( $(echo "$num1 < $num2" | bc -l) )); then
           matrix[$i,$j]=${cavity[$i]}
           rank_best[$i,$j]=$k
         fi
        else
           matrix[$i,$j]=${cavity[$i]}
           #echo $k $i  ${target[$((i-1))]} ${cavity[$i]}
           echo $k ${cavity[$i]}
           #echo ${cavity[$i]} >> ${RDir}'/'${target[$((i-1))]}'.csv'
        fi
      done   # columns
      j=$[$j+1]
   done   # rows
   exec {file_descriptor}>&-

 done # for k

   resF="${RDir}/docking_best.csv"
   ranF="${RDir}/docking_best_ranking.csv"
   rm $resF $ranF

   for ((j=0;j<=num_columns;j++)) do
       for ((i=0;i<=num_rows;i++)) do
           if [[ $((i + 0)) -lt $nT ]]
           then
             echo -en ${matrix[$i,$j]} ", " >> $resF
             echo -en ${rank_best[$i,$j]} ", " >> $ranF
           else
             echo ${matrix[$i,$j]} >> $resF
             echo ${rank_best[$i,$j]} >> $ranF
           fi
       done
   done

   for ((i=0;i<num_rows;i++)) do
      tmpF=${RDir}'/'${target[$((i-0))]}'.csv'
      if [ -f "${tmpF}" ]; then
         echo "Reading $tmpF" 
         touch tmp2
         exec {file_descriptor}<"$tmpF"
         declare -a row
         j=1  # rows
         while IFS="" read -a row -u $file_descriptor 
         do
            #echo -en "  j$j: $row" 
            echo $row >> tmp1
            if [[ $((j + 0)) -eq $nL ]]
            then
             #echo ""
             ##more tmp2
             paste -d "," tmp2 tmp1 > tmp3
             mv tmp3 tmp2
             rm tmp1
             j=1
             #echo ""
             #echo ""
            else
             j=$[$j+1]
            fi
         done   # rows
         exec {file_descriptor}>&-

         head=""
         for ((k=1;k<=ncavs;k++))
         do
            head=$head',cav_'$k
         done

         cut -c 2- tmp2 > ${target[$((i-0))]}'.csv'
         sed -i '1s/^/Lig_Cav'$head'\n/' ${target[$((i-0))]}'.csv'
         mv ${target[$((i-0))]}'.csv' ${RDir}'/'${target[$((i-0))]}'.csv'
         rm tmp*
         #echo ""
         #echo ""
      fi
   done

 echo
 echo "Wrote files $resF and $ranF"
 echo

 echo -en 'TIME Ending on '
 date
 echo "-------------------done---------------------"
 echo
fi # if best


###########################################################



if [[ $calc -eq 5 ]]
then
 echo
 echo "-------------------begin--------------------"
 echo
 echo 'Doing replace labels in file ' $inF ' with version ' $ver
 echo -en 'TIME Starting on '
 date

   declare -A matrix
   num_rows=$NT
   num_columns=$NL
   for ((i=0;i<=num_rows;i++)) do
       #echo "i:$i " ${target[$i]}
       for ((j=0;j<=num_columns;j++)) do
         #echo "j:$j " ${ligand[$j]}
         if [[ $j -eq 0 ]]
         then
           matrix[$((i+1)),$((j+0))]=${target[$i]}
         elif [[ $i -eq 0 ]]
         then
           matrix[$((i+0)),$((j+0))]=${ligand[$((j-1))]}
         else
           matrix[$i,$j]=0
         fi
       done
   done
   matrix[0,0]='Li_Ta'

   ## https://www.baeldung.com/linux/read-command
   exec {file_descriptor}<"$inF"
   declare -a cavity
   j=0
   while IFS="," read -a cavity -u $file_descriptor 
   do
#      echo -en "j$j: " 
      for ((i=0;i<=num_rows;i++)) do
#        echo -en "i$i:${cavity[$i]} " 
        if [[ $i -ne 0 && $j -ne 0 ]]; then
           matrix[$i,$j]=${cavity[$i]}
        fi
      done
      j=$[$j+1]
   done
   exec {file_descriptor}>&-

   for ((j=0;j<=num_columns;j++)) do
       for ((i=0;i<=num_rows;i++)) do
           if [[ $((i + 0)) -lt $nT ]]
           then
             echo -en ${matrix[$i,$j]} ", " >> tmp
           else
             echo ${matrix[$i,$j]} >> tmp
           fi
       done
   done
   mv tmp $inF

 echo
 echo "Wrote file $inF"
 echo

 echo -en 'TIME Ending on '
 date
 echo "-------------------done---------------------"
 echo
fi # if replace




###########################################################



if [[ $calc -eq 6 ]]
then
 echo
 echo "-------------------begin--------------------"
 echo
 echo 'Doing viz  with version ' $ver
 echo -en 'TIME Starting on '
 date

  if [ -d $vizDir ]; then
    echo "Found ${vizDir}, will replace all data in it"
#    rm -rf ${vizDir}
#  else
#    echo "Will create ${vizDir}"
  fi

  state=${inF}
  stateF=${state}
  if [ ! -f $stateF ]; then
            echo "ERROR: state file was not found: $stateF, templates: ${tmpT} ${tmpL}"
            echo "Generate first with VMD and then continue."
            echo
            exit 2
  else
            echo "Found state file: $stateF, templates: ${tmpT} ${tmpL}"
  fi

 for T in ${!target[@]}
 do

  tar=${target[$T]}

  Dir="${vizDir}/${tar}"
  if [ ! -d $Dir ]; then
            echo "Will create $Dir"
            mkdir -vp $Dir
  fi

  for L in ${!ligand[@]}
  do

  lig=${ligand[$L]}

  ## results/state_01.vmd has Target=4y29 and Ligand=01BF (generate desired state with vmd first)
  ## will replace for 
  ## 1) target at /home/trippm/Work/Rox/docking/4y29/receptor.pdb
  ## 2) if available, co-crystalized ligand at /home/trippm/Work/Rox/target/4y29/4y29_crislig.pdb
  ## 3) ligand at all cavities (cav_*) at /home/trippm/Work/Rox/docking/4y29/01BF/best/4y29-01BF_best_cav_01.mol2

  #tmpT=4y29
  #tmpL=01BF

  vizF=${Dir}/${tar}-${lig}_${state}
  echo "Will create ${vizF}"

  tmpF=${RDir}/tmp
  sed 's/'${tmpT}'/'${tar}'/g' ${stateF} > ${tmpF}
  sed 's/'${tmpL}'/'${lig}'/g' ${tmpF} > ${vizF}
  rm ${tmpF}

  done # for ligands
 done # for targets



 echo -en 'TIME Ending on '
 date
 echo "-------------------done---------------------"
 echo
fi # if viz




###########################################################



if [[ $calc -eq 7 ]]
then
 echo
 echo "-------------------begin--------------------"
 echo
 echo 'Doing tar  with version ' $ver
 echo -en 'TIME Starting on '
 date

  tarF="cbdockbmd.tar"

  if [ -f $tarF ]; then
    echo "Found ${tarF}, will replace it with new one"
    rm -rf ${tarF}
    touch $tarF
  else
    echo "Will create ${tarF}"
    touch $tarF
  fi

 for T in ${!target[@]}
 do

  tar=${target[$T]}

  tarDir="${DDir}/${tar}"
  if [ ! -d $tarDir ]; then
            echo "ERROR no directory $tarDir. You need to run docking first."
            exit
  fi

  tarStr="${tarDir}/receptor.pdb"
  if [ ! -f $tarStr ]; then
            echo "ERROR no file $tarStr. You need to run docking first."
            exit
  else
            tar -rvf $tarF $tarStr
  fi

  for L in ${!ligand[@]}
  do

  lig=${ligand[$L]}

  ligDir="${tarDir}/${lig}/best"
  if [ ! -d $ligDir ]; then
            echo "ERROR no directory $ligDir. You need to run docking first."
            exit
  else
            tar -hcvf ${tar}-${lig}.tar $ligDir/*.mol2
            tar -rvf $tarF ${tar}-${lig}.tar 
            rm ${tar}-${lig}.tar
  fi

  vizD="${vizDir}/${tar}"
  vizF=${vizD}/${tar}-${lig}
  if [ ! -d $vizD ]; then
            echo "WARNING no directory $vizD. Visualization state won't be included."
  else
            tar -rvf $tarF $vizF*
  fi


  done # for ligands
 done # for targets



 echo -en 'TIME Ending on '
 date
 echo "-------------------done---------------------"
 echo
fi # if tar




###########################################################






