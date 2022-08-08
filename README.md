# neuropixels_preprocessing
Preprocessing pipeline for Neuropixels recordings using kilosort, additional cluster metrics, Phy2, and export functions to cellbase

## Preprocessing steps

1) Transfer .rec file for days you wish to process from the server. It’s best for this to go to an SSD
2) Open trodes 2.0.1 (important that its not 2.1.1, and you have to open it from file explorer -- C/Users/Adam/Documents/trodes2.0.1
3) From the main menu select load a playback file, and open your desired .rec file
4) File -> extract -> analgio, dio, kilosort, “start”. This takes a few hours to run on an SSD and overnight on an HDD
5) After double checking the backup of the .rec file is still on the server (and correct size etc.), delete the local copy to save space. 
6) Run either run_KS_25Torben or run_KS_25_batch, depending on whether you are processing one day, or processing multiple days. You must edit the file paths in the script. It’s good for the temporary files to be located on an SSD for speed, but the KS output file doesn’t have to be. 

7) Open anaconda powershell, and change directory to the KS output directory
8) Start the phy anaconda environment (conda activate phy2)
9) Start phy for clustering (phy template-gui params.py)
10) manually cluster
	a) (keyboard shortcuts to remember: alt +  g labels a spikes as good, alt + m labels it as bad, and :merge merges together all the selected clusters. 
	b) We prefilter with the following stats. fr > 0.5 & Amplitude > 700 & KSLabel == ‘good’ & ISIv < 3
	c) For aligning multiple days I’m somewhat lenient, I basically take a cell if it matches those criteria and has consistent spike amplitudes, isn’t obviously two clusters, and has consistent firing rate across the session break. If it’s a badly aligned day many cells wont look consistent, especially in the upper part of the probe. 


## AFTER SORTING:

- Copy convert_spikes.py  from MATLAB directory to KS output directory (for example: cp C:\Users\Adam\Documents\MATLAB\convert_spikes.py .\20210517_518\convert_spikes.py)

- Run python convert_spikes.py from KS directory (cmd: python convert_spikes.py)

- Run MakeTTNeuropixel_batchalign (matlab, editing directories as relevant)


- For each day (from cellbase directory):
	Copy relevant behavior file to cellbase
 	
	Run MakeTrialEventsNeuropixels on cellbase directory
	
	If 2nd day in alignment MakeTrialEvents2TorbenNP needs to be edited to say: Events_TTL2 Events_TS2 on line 45, Events_TTL1 Events_TS1 if first day
