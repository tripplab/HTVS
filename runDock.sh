
######################## runDock by trippm@tripplab.com ##########################
##                                 August 2021                                   #
## These options are defined in pipeline.sh                                      #
## ./runDock.sh dock                                                             #
## ./runDock.sh cavs                                                             #
## ./runDock.sh anal                                                             #
## ./runDock.sh best                                                             #
## ./runDock.sh replab                                                           #
## ./runDock.sh viz                                                              #
## ./runDock.sh tar                                                              #
##                                                                               #
############################ Data Configuration ##################################

## How many cycles (1 for test/timing run)
cyc=48 #36 #1
## How many cavities
cav=5
## Turn on (1) or off (0) automatic parallelization
## Make sure the value of 'cyc' is a multiple of 6, our CPU has 24 cores
## CB-Dock uses 4 cores per docking
parallel=1

## List of target proteins
## structure must be in target/Tname1/Tname1.pdb
## prepare file with chimera's Dock Prep (in 'Structure Editing' menu)
## https://www.cgl.ucsf.edu/chimera/docs/ContributedSoftware/dockprep/dockprep.html
targets=(4y29 3et1 3gz9 4l7b 5yp6 1ypq 1k4u 1k4uP 1k4uS)
nT=${#targets[@]}

## List of ligands
## structure must be in ligands/Lname1.mol2 AND ligands/Lname1.pdbqt
## those files can be generated with MGLTools ADT
ligands=(CTI EEY BRL isoC17 zeax2 tzeax-C8 tzeax-C13 tzeax-C15 gpl01 gl01 gl02 gl03 gl04 gl05 pep01)
nL=${#ligands[@]}

## List of cavities found for analysis
## label/size of the cavity of the corresponding target
## found in docking/target/ligand/ligand-target-id_number/ligand-target-id_number_results.txt
## This can be passed to CBDock to do an analysis of selected cavities (one per target),
## otherwise an analysis of all cavities for all targets will be made.
cavities=()
nC=${#cavities[@]}


############################ Directories Configuration ##################################

## Where are energy results (structure results are in docking/target/ligand/best)
RDir="results"
LDir="logs"

## Where is CBDock.sh
CBD=/path/to/file/CBDock.sh

## Unique label to distinguish runs
date=$(date +%F)

############################ Running Configuration ##################################
## Configure sections below for:
##  DOCKINGS
##  ANALYSIS
##  CAVITIES
##  EXTRACT BEST
##  REPLACE LABELS 
##  CREATE VIZUALISATION STATE 
##  CREATE ARCHIVE (cbdockbmd.tar) WITH TARGET AND LIGANDS BEST CONFORMATION STRUCTURES
#########################################

## https://opensource.com/article/19/10/programming-bash-logical-operators-shell-expansions
if [[ $1 == 'dock' ]]; then
 c=1
elif [[ $1 == 'anal' ]]; then
 c=2
elif [[ $1 == 'cavs' ]]; then
 c=3
elif [[ $1 == 'best' ]]; then
 c=4
elif [[ $1 == 'replab' ]]; then
 c=5
elif [[ $1 == 'viz' ]]; then
 c=6
elif [[ $1 == 'tar' ]]; then
 c=7
else
    echo "$CBD: Illegal first parameter, found $1"
    echo "dock|anal|cavs|best|replab|viz|tar"
    exit 2
fi

  if [ ! -d "$RDir" ]; then
     mkdir $RDir       
     echo "Created directory: " $RDir
  fi

  if [ ! -d "$LDir" ]; then
     mkdir $LDir       
     echo "Created directory: " $LDir
  fi

########################### DOCKINGS #########################################
## For docking
## CBDock.sh 1 cycles ncavs ntargets nligands targ1...targn lig1...lign &> file.log
##

if [[ $c -eq 1 ]]; then

  echo ""
  echo "This is runDock.sh Doing docking at $date"
  echo "Number of cavities to analize: $cav"
  echo "Targets ($nT): ${targets[@]}"
  echo "Ligands ($nL): ${ligands[@]}"


 if [[ $cyc -eq 1 ]]; then
   echo "This is a test/timing run"
   echo "$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]}"
   $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} #&> $logF &
 fi

 if [[ $parallel -eq 1 ]]; then

  jobs=6
  mod=$(($cyc%$jobs))
  if [[ $mod -eq 1 ]]; then
	  echo "ERROR: The number of cycles ("$cyc") has to be a multiple of " $jobs
	  exit
  fi

  echo ""
  echo "Parallelizing " $cyc " cycles in 6 jobs with 4 threads each (24 cores)"

  read -p "Is this what you want to do [Y|n]: " ans
  echo "Your answer is " $ans
  if test "$ans" != "Y"; then
	  echo "Thank you. Exiting now"
	  exit
  fi

  cyc=$(($cyc/$jobs))
  echo "Each job will have " $cyc " cycles now, please wait..."

  for ((i=1;i<=jobs;i++))
  do

       logF=$LDir/job$i-${date}.log

       echo "All Targets vs All Ligands"
       sleep 10s
       ##echo "$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} &> $logF &"
       $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} &> $logF &
       jobPID=$!; echo -n "Starting job " $i "/" $jobs " with PID = $jobPID,  " #> $LDir/PIDs-${date}.log
       echo "Log in " $logF
  done

  echo "Monitor jobs with 'htop'"
  echo ""

 fi ## parallel


  ## Examples of how to run a few Targets vs All Ligands

#  $CBD $c $cyc $cav 2 $nL REC1 REC2 ${ligands[@]} &> $LDir/REC1_REC2-${date}.log &
#    jobPID01=$!; echo "Running job"; echo "Starting job 01 with PID = $jobPID01" > $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 $nL REC3 REC4 ${ligands[@]} &> $LDir/REC3_REC4-${date}.log &
#    jobPID02=$!; echo "Running job"; echo "Starting job 02 with PID = $jobPID02" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 $nL REC5 PSC3 ${ligands[@]} &> $LDir/REC5_PSC3-${date}.log &
#    jobPID03=$!; echo "Running job"; echo "Starting job 03 with PID = $jobPID03" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 $nL PSC4 PSC5 ${ligands[@]} &> $LDir/PSC4_PSC5-${date}.log &
#    jobPID04=$!; echo "Running job"; echo "Starting job 04 with PID = $jobPID04" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 $nL PSC6 PSC7 ${ligands[@]} &> $LDir/PSC6_PSC7-${date}.log &
#    jobPID05=$!; echo "Running job"; echo "Starting job 05 with PID = $jobPID05" >> $LDir/PIDs-${date}.log
#  ### "6vxx_1_1_1_AAA" "6vxx_1_1_1_A" "6vxx_1_1_1_AAA_head" -> PSC1 PSC1H PSC2
#  $CBD $c $cyc $cav 2 $nL 6vxx_1_1_1_AAA PSC2R ${ligands[@]} &> $LDir/PSC1_PSC2R-${date}.log &
#    jobPID06=$!; echo "Running job"; echo "Starting job 06 with PID = $jobPID06" >> $LDir/PIDs-${date}.log

#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_AAA_head ${ligands[@]} &> $LDir/PSC1H_01-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 01 with PID = $jobPID07" > $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_A ${ligands[@]} &> $LDir/PSC2_01-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 02 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_AAA_head ${ligands[@]} &> $LDir/PSC1H_02-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 03 with PID = $jobPID07" > $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_A ${ligands[@]} &> $LDir/PSC2_02-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 04 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_AAA_head ${ligands[@]} &> $LDir/PSC1H_03-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 05 with PID = $jobPID07" > $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 1 $nL 6vxx_1_1_1_A ${ligands[@]} &> $LDir/PSC2_03-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 06 with PID = $jobPID07" >> $LDir/PIDs-${date}.log

#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_01-${date}.log &
#    jobPID01=$!; echo "Running job"; echo "Starting job 01 with PID = $jobPID01" > $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_02-${date}.log &
#    jobPID02=$!; echo "Running job"; echo "Starting job 02 with PID = $jobPID02" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_03-${date}.log &
#    jobPID03=$!; echo "Running job"; echo "Starting job 03 with PID = $jobPID03" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_04-${date}.log &
#    jobPID04=$!; echo "Running job"; echo "Starting job 04 with PID = $jobPID04" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_05-${date}.log &
#    jobPID05=$!; echo "Running job"; echo "Starting job 05 with PID = $jobPID05" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 $nL REC3 ${ligands[@]} &> $LDir/REC3_06-${date}.log &
#    jobPID06=$!; echo "Running job"; echo "Starting job 06 with PID = $jobPID06" >> $LDir/PIDs-${date}.log



  ## Examples of how to run All Targets vs a few Ligands

#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_01-${date}.log &
#    jobPID01=$!; echo "Running job " $jobPID01; echo "Starting job 01 with PID = $jobPID01" > $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_02-${date}.log &
#    jobPID02=$!; echo "Running job " $jobPID02; echo "Starting job 02 with PID = $jobPID02" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_03-${date}.log &
#    jobPID03=$!; echo "Running job " $jobPID03; echo "Starting job 03 with PID = $jobPID03" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_04-${date}.log &
#    jobPID04=$!; echo "Running job " $jobPID04; echo "Starting job 04 with PID = $jobPID04" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_05-${date}.log &
#    jobPID05=$!; echo "Running job " $jobPID05; echo "Starting job 05 with PID = $jobPID05" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav $nT 3 ${targets[@]} la_14 lp_10 lp_09 &> $LDir/la_14_06-${date}.log &
#    jobPID06=$!; echo "Running job " $jobPID06; echo "Starting job 06 with PID = $jobPID06" >> $LDir/PIDs-${date}.log
#    sleep 10s



  ## Examples of how to run Few Targets vs a few Ligands (keep track of jobs PID)

#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands1[@]} &> $LDir/PSC1H_PSC2_01-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 01 with PID = $jobPID07" > $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands2[@]} &> $LDir/PSC1H_PSC2_02-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 02 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands1[@]} &> $LDir/PSC1H_PSC2_03-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 03 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands2[@]} &> $LDir/PSC1H_PSC2_04-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 04 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands1[@]} &> $LDir/PSC1H_PSC2_05-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 05 with PID = $jobPID07" >> $LDir/PIDs-${date}.log
#  $CBD $c $cyc $cav 2 11 6vxx_1_1_1_AAA_head 6vxx_1_1_1_A ${ligands2[@]} &> $LDir/PSC1H_PSC2_06-${date}.log &
#    jobPID07=$!; echo "Running job"; echo "Starting job 06 with PID = $jobPID07" >> $LDir/PIDs-${date}.log

#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_01-${date}.log &
#  jobPID01=$!; echo "Starting job with PID = $jobPID01" > $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_02-${date}.log &
#  jobPID02=$!; echo "Starting job with PID = $jobPID02" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_03-${date}.log &
#  jobPID03=$!; echo "Starting job with PID = $jobPID03" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_04-${date}.log &
#  jobPID04=$!; echo "Starting job with PID = $jobPID04" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_05-${date}.log &
#  jobPID05=$!; echo "Starting job with PID = $jobPID05" >> $LDir/PIDs-${date}.log
#    sleep 10s
#  $CBD $c $cyc $cav 1 1 REC3 la_14 &> $LDir/REC3-la_14_06-${date}.log &
#  jobPID06=$!; echo "Starting job with PID = $jobPID06" >> $LDir/PIDs-${date}.log

#  $CBD $c $cyc $cav 1 1 PSC8 lq_01 &> $LDir/PSC8_lq_01-${date}.log &

fi

########################### ANALYSIS #########################################
## For analysis
## CBDock.sh 0 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 2 ]]; then

  echo "Doing analysis $date"
  echo "please wait..."
  echo "I'm still working..."

  ## Analyse all cavities
  echo "$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]}"
  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} > $RDir/docking_all_cavs-${date}.out
  #$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]}

  ## For a specific set of cavities
#  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} ${cavities[@]} > $RDir/docking_manual-${date}.out
  #$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} ${cavities[@]}

  #$CBD $c $cyc $cav 1 1 REC3 la_14
  #$CBD $c $cyc $cav 1 1 REC0 lk_01 466
  #$CBD $c $cyc $cav $nT 1 ${targets[@]} lk_01 ${cavities[@]}
  #$CBD $c $cyc $cav 1 $nL REC0 ${ligands[@]} 466

  echo "output in $RDir/docking_all_cavs-${date}.out"

fi

########################### CAVITIES #########################################
## For cavities
## CBDock.sh 3 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 3 ]]; then

  echo "Doing cavities $date"

  $CBD $c $cyc $cav $nT $nL ${targets[@]}

  #$CBD $c $cyc $cav 1 $nL REC3

fi


########################### EXTRACT BEST #########################################
## For best
## CBDock.sh 4 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 4 ]]; then

  echo "Doing extract best $date"
  echo "please wait..."
  echo "I'm still working..."

  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]}

fi


########################### REPLACE LABELS #########################################
## For best
## CBDock.sh 5 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 5 ]]; then

  echo "$c Doing replace labels $date"

  ## Exmanples of how you can Modify 'ligands' here
  ligands=(INH01 INH02 INH03 INH04 INV01 INV02 INV03 INV04 INV05 RPA01 RPA02 RPA03 RPA04 RPA05 RPA06 RPA07 RPA08 RPA09 RPA10 RPA11 RPA12 RPA13 RPA14 RPA15 RPB01 RPB02 RPB03 RPB04 RPB05 RPB06 RPB07 RPB08 RPC01 RPC02 RPC03 RPC04 RPC05 RPC06 RPC07 RPC08 RPC09 RPC10 RPC11 RPC12 RPC13 RPC14 RPD01 EXT01 EXT02 EXT03 EXT04 EXT05 EXT06 EXT07 EXT08 EXT09 EXT10 ALI01 ALI02 ALI03 ALI04 ALI05 ALI06 ALI07 ALI08 ALI09 ALI10 ALI11 ALI12 ALI13 ALI14 ALI15 ALI16 ALI17 ALI18 ALI19 ALI20 ALI21 ALI22 ALI23 ALI24 ALI25 ALI26)

  ## Do not modify 'targets' here, do it below
  for ((k=1;k<=cav;k++))
  do
     #head=$head',cav_'$k
     head+=("cav_$k")
  done

  for ((j=0; j<"$nT"; j++))
  do
    $CBD $c $cyc $cav ${#head[@]} $nL ${head[@]} ${ligands[@]} $RDir/${targets[$j]}.csv
    ls -l $RDir/${targets[$j]}.csv
  done

  ## Modify 'targets' here
  ## targets=(REC0 REC1 REC2 REC3 REC4 REC5 PSC1 PSC1H PSC2 PSC2R PSC3 PSC4 PSC5 PSC6 PSC7 PSC8)
  targets=("H00" "H01" "H02" "H03" "H04" "H05" "V01" "V01H" "V02" "V02R" "V03" "V04" "V05" "V06" "V07" "V08")

  cp $RDir/docking_best.csv $RDir/docking_best_origLabel.csv
  cp $RDir/docking_best_ranking.csv $RDir/docking_best_ranking_origLabel.csv
  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} $RDir/docking_best.csv
  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} $RDir/docking_best_ranking.csv
  #for i in 1 2 3 4 5
  for ((j=1; j<="$cav"; j++))
  do
    cp $RDir/docking_cav${j}.csv $RDir/docking_cav${j}_origLabel.csv
    $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} $RDir/docking_cav${j}.csv
  done

  echo "Backup in $RDir/docking_best_origLabel.csv, $RDir/docking_best_ranking_origLabel.csv, and $RDir/docking_cav*.csv"

  ## Declare Asociative Arrays

  declare -A reptar=([REC0]=H00 [REC1]=H01 [REC2]=H02 [REC3]=H03 [REC4]=H04 [REC5]=H05 [PSC1]=V01 [PSC1H]=V01H [PSC2]=V02  [PSC2R]=V02R [PSC3]=V03 [PSC4]=V04 [PSC5]=V05 [PSC6]=V06 [PSC7]=V07 [PSC8]=V08)

  declare -A replig=([lk_01]=INH01 [la_14]=INH02 [lm_01]=INH03 [ln_01]=INH04 [lo_01]=INV01 [lp_10]=INV02 [lp_09]=INV03 [lq_01]=INV04 [lr_01]=INV05 [la_01]=RPA01 [la_02]=RPA02 [la_03]=RPA03 [la_04]=RPA04 [ll_01]=RPA05 [la_06]=RPA06 [la_07]=RPA07 [la_08]=RPA08 [la_09]=RPA09 [la_10]=RPA10 [la_11]=RPA11 [la_12]=RPA12 [la_13]=RPA13 [la_05]=RPA14 [lm_02]=RPA15 [lb_01]=RPB01 [lb_02]=RPB02 [lb_03]=RPB03 [lb_04]=RPB04 [lb_05]=RPB05 [lb_06]=RPB06 [lb_07]=RPB07 [lo_02]=RPB08 [lc_03]=RPC01 [lc_04]=RPC02 [ld_01]=RPC03 [lp_01]=RPC04 [lp_02]=RPC05 [lp_03]=RPC06 [lp_04]=RPC07 [lp_05]=RPC08 [lp_06]=RPC09 [lp_07]=RPC10 [lp_08]=RPC11 [lc_01]=RPC12 [lc_02]=RPC13 [lc_05]=RPC14 [lq_02]=RPD01 [le_01]=EXT01 [le_02]=EXT02 [le_03]=EXT03 [lf_01]=EXT04 [lg_01]=EXT05 [lh_01]=EXT06 [li_01]=EXT07 [lj_01]=EXT08 [lj_02]=EXT09 [lj_03]=EXT10 [ac_01]=ALI01 [ac_02]=ALI02 [ac_03]=ALI03 [ac_04]=ALI04 [ac_05]=ALI05 [ac_06]=ALI06 [ac_07]=ALI07 [ac_08]=ALI08 [ac_09]=ALI09 [ac_10]=ALI10 [ac_11]=ALI11 [ac_12]=ALI12 [ac_13]=ALI13 [ac_14]=ALI14 [ac_15]=ALI15 [ac_16]=ALI16 [ac_17]=ALI17 [ac_18]=ALI18 [ac_19]=ALI19 [ac_20]=ALI20 [ac_21]=ALI21 [ac_22]=ALI22 [ac_23]=ALI23 [ac_24]=ALI24 [ac_25]=ALI25 [ac_26]=ALI26)

 for F in docking_all_data.csv docking_manual.csv
 do	 
  #inF="$RDir/docking_all_data.csv"
  inF="$RDir/$F"
  echo "Replacing labels in $F"
  cp $inF tmp

  for T in ${!reptar[@]}
  do
    echo $T ${reptar[$T]}
    sed 's/'$T'/'${reptar[$T]}'/g' tmp > tmp2
    cp tmp2 tmp
  done

  for L in ${!replig[@]}
  do
    echo $L ${replig[$L]}
    sed 's/'$L'/'${replig[$L]}'/g' tmp > tmp2
    cp tmp2 tmp
  done

  cp $inF "$inF.original"
  mv tmp $inF
  rm tmp2

  echo "Backup in $inF.original"

 done

  echo

fi

###################  CREATE VIsUALIzATION STATE  #################################
## For viz
## CBDock.sh 6 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 6 ]]; then

  echo "$c Doing viz $date"

  ## Create a 'state' with VMD using a target and a ligand and use that file to propagate same state to all target-ligand pairs
  #$CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]} spike_01.vmd PSC1 lb_05

  $CBD $c $cyc $cav 1 1 REC0 lk_01 spike_01.vmd PSC1 lb_05

fi



###################  CREATE ARCHIVE  #################################
## For tar
## CBDock.sh 6 cycles ncavs ntargets nligands targ1...targn lig1...lign cav1...cavn&>file.log
##

if [[ $c -eq 7 ]]; then

  echo "Doing tar $date"

  $CBD $c $cyc $cav $nT $nL ${targets[@]} ${ligands[@]}
  #$CBD $c $cyc $cav 1 3 PSC1 lb_05 lf_01 la_13

fi


######################## nothing to do here ###################################


## Check how many cycles are done
#grep '^ Cycle ' logs/*0902*

## Check how long each ligand takes
#grep Ligand logs/PSC2R_03-090221.log | grep ELAPSED


## Check for times taken for vina
#grep CPU logs/1k4u-190121.log | awk '{split($0,a,"elapsed");split(a[1],b," "); print b[3]}'

## Batch convert from TGA to JPG controling final resolution
#ls -1 *tga | xargs -n 1 bash -c 'convert -resample 100 "$0" "${0%.*}.jpg"'


