# Cervical SC Study

## Data struture:
The automatic script was created for the following data structure.
Manual segmentations for T1w are named: `SC_seg.nii.gz`, for T2w: `T2w_seg.nii.gz` and for T2w_flair: `T2w_flair_seg.nii.gz. 
Manual disc labels are named: `CONTRAST_labels-manual.nii.gz`.

~~~
SCT_Cervical.Cord
│
├── Geneuro0001_W0
├── Geneuro0001_W048
├── Geneuro0002_W0
│   │
│   ├── SC_seg.nii.gz --> T1w spinal cord segmentation
│   ├── T1w.nii.gz
│   ├── T1w_labels-manual.nii.gz --> Manual C2-C3 disc label
│   ├── T2w.nii.gz
│   ├── T2w_seg.nii.gz --> Manual segmentation of T2w
│   ├── T2w_flair.nii.gz
│   ├── T2w_flair.nii.gz --> Manual segmentation of T2w_flair
│   └── sub-1000710_T2w.nii.gz
...
~~~

## Processing
Processing will generate spinal cord segmentation, vertebral labels, and compute cord CSA for T1w, T2w and T2w_flair. Specify the path of preprocessed dataset with the flag `-path-data`.

Launch processing:
~~~
sct_run_batch -path-data <PATH_DATA> -path-output ~/cervical_sc_results/ -jobs -1 -script process_data.sh  -subject-prefix Geneuro
~~~

## Manual correction

### Disc labeling
To create manual disc labeling, lauch the following command and click at the posterior disc for C1-C2, C2-C3 and C3-C4.

~~~
sct_label_utils -i <IMAGE> -create-viewer 2,3,4 -o <IMAGE>_labels-manual.nii..gz
~~~
~~~
