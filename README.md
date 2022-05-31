# HTVS
Implementation of a cavity-guided blind molecular docking algorithm into a high-throughput computational pipeline to automatically screen and analyze a large set of drugs over a group of proteins

INSTALL CB-DOCK

- Follow instructions from http://clab.labshare.cn/cb-dock/php/manual.php#download

- Check that everything works fine

INSTALL HTVS

- Download files from this repository
- Set execution for ech one with 'chmod u+x filename.sh'

- Put CBDock.sh in an all-user accesible path

- Edit CBDock.sh and set the 'cbdock' parameter value to point to CB-Dock/prog/AutoBlindDock.pl

- Put runDock.sh and pipeline.sh in a working directory. You can replicate these in as many working directories as needed.
- Set the values for parameters 'cyc', 'cav', 'parallel', 'targets', and 'ligands'
- Set the 'CBD' parameter value to point to CBDock.sh
- Depending on what needs to be done, configure the sections for DOCKINGS, ANALYSIS, CAVITIES, EXTRACT BEST.

- Set the desired job by uncommenting the corresponding line in pipeline.sh

- Run jobs with './pipeline.sh'
