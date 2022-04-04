#!/bin/bash
#
# Process data.
#
# Usage:
#   ./process_data.sh <SUBJECT>
#
# Manual segmentations or labels should be located under:
# XXX
#
# Authors: Sandrine Bédard

set -x
# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1

# Save script path
PATH_SCRIPT=$PWD

# get starting time:
start=`date +%s`

# FUNCTIONS
# ==============================================================================
# Check if manual segmentation already exists. If it does, copy it locally. If it does not, perform segmentation.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"

  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  FILESEGMANUAL="${PATH_DATA}/${SUBJECT}/SC_seg.nii.gz"
  FILESEGMANUAL2="${PATH_DATA}/${SUBJECT}/${file}_seg.nii.gz"
  echo 
  if [[ -e $FILESEGMANUAL ]]; then
    if  [ $file == "T1w" ]; then
      FILESEGMANUAL2=${FILESEGMANUAL}
    fi
  fi
  echo
  echo "Looking for manual segmentation: $FILESEGMANUAL2"
  if [[ -e $FILESEGMANUAL2 ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL2 ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}

# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd ${PATH_DATA_PROCESSED}

# Copy source images
rsync -avzh $PATH_DATA/$SUBJECT .
# Go to anat folder where all structural data are located
cd ${SUBJECT}


# Check if manual label already exists. If it does, copy it locally. If it does
# not, perform labeling.
# NOTE: manual disc labels include C1-2, C2-3 and C3-4.
label_if_does_not_exist(){
  local file="$1"
  local file_seg="$2"
  # Update global variable with segmentation file name
  FILELABEL="${file}_labels"
  FILELABELMANUAL="${PATH_DATA}/${SUBJECT}/${FILELABEL}-manual.nii.gz"
  echo "Looking for manual label: $FILELABELMANUAL"
  if [[ -e $FILELABELMANUAL ]]; then
    echo "Found! Using manual labels."
    rsync -avzh $FILELABELMANUAL ${FILELABEL}.nii.gz
    # Generate labeled segmentation from manual disc labels
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -discfile ${FILELABEL}.nii.gz -c t1
  else
    echo "Not found. Proceeding with automatic labeling."
    # Generate labeled segmentation
    sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg}.nii.gz -c t1
  fi
}


# T1w
# ------------------------------------------------------------------------------
file_t1="T1w"

# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t1 "t1"
file_t1_seg=$FILESEG

# Create labeled segmentation (only if it does not exist) 
label_if_does_not_exist ${file_t1} ${file_t1_seg}
file_t1_seg_labeled="${file_t1_seg}_labeled"

# Generate QC report to assess vertebral labeling
sct_qc -i ${file_t1}.nii.gz -s ${file_t1_seg_labeled}.nii.gz -p sct_label_vertebrae -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t1_seg}.nii.gz -vert 2:3 -vertfile ${file_t1_seg_labeled}.nii.gz -o ${PATH_RESULTS}/csa-SC_c2c3_T1.csv -append 1


# T2w
# ------------------------------------------------------------------------------
file_t2="T2w"

# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2 "t2"
file_t2_seg=$FILESEG

# Create labeled segmentation (only if it does not exist) 
label_if_does_not_exist ${file_t2} ${file_t2_seg}
file_t2_seg_labeled="${file_t2_seg}_labeled"

# Generate QC report to assess vertebral labeling
sct_qc -i ${file_t2}.nii.gz -s ${file_t2_seg_labeled}.nii.gz -p sct_label_vertebrae -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t2_seg}.nii.gz -vert 2:3 -vertfile ${file_t2_seg_labeled}.nii.gz -o ${PATH_RESULTS}/csa-SC_c2c3_T2.csv -append 1


# T2w_flair
# ------------------------------------------------------------------------------
file_t2_flair="T2w_flair"

# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2_flair "t1"
file_t2_flair_seg=$FILESEG

# Create labeled segmentation (only if it does not exist) 
label_if_does_not_exist ${file_t2_flair} ${file_t2_flair_seg}
file_t2_flair_seg_labeled="${file_t2_flair_seg}_labeled"

# Generate QC report to assess vertebral labeling
sct_qc -i ${file_t2_flair}.nii.gz -s ${file_t2_flair_seg_labeled}.nii.gz -p sct_label_vertebrae -qc ${PATH_QC} -qc-subject ${SUBJECT}
# Compute average cord CSA between C2 and C3
sct_process_segmentation -i ${file_t2_flair_seg}.nii.gz -vert 2:3 -vertfile ${file_t2_flair_seg_labeled}.nii.gz -o ${PATH_RESULTS}/csa-SC_c2c3_T2_flair.csv -append 1


# Verify presence of output files and write log file if error
# ------------------------------------------------------------------------------
FILES_TO_CHECK=(
  "T1w_seg.nii.gz" 
  "T1w_seg_labeled.nii.gz"
  "T2w_seg.nii.gz" 
  "T2w_seg_labeled.nii.gz"
  "T2w_flair_seg.nii.gz" 
  "T2w_flair_seg_labeled.nii.gz"    
)
pwd
for file in ${FILES_TO_CHECK[@]}; do
  if [[ ! -e $file ]]; then
    echo "${SUBJECT}/anat/${file} does not exist" >> $PATH_LOG/_error_check_output_files.log
  fi
done

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
