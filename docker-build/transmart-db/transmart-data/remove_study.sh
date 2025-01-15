#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Completely remove a study. This includes clinical and omics data."
    echo "Usage: $0 <STUDY_ID>"
    echo " STUDY_ID: e.g. GSEXXXX, i.e. all caps"
    exit
fi
STUDYID=${1^^} 

cat << EOD
DELETE FROM i2b2metadata.i2b2_tags WHERE path=
  (SELECT c_fullname FROM i2b2metadata.i2b2
  WHERE sourcesystem_cd='$STUDYID' ORDER BY c_hlevel ASC LIMIT 1);
DELETE FROM i2b2demodata.concept_dimension WHERE sourcesystem_cd='$STUDYID';
DELETE FROM i2b2metadata.tm_concept_counts WHERE concept_path IN
  (SELECT c_fullname FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='$STUDYID');
DELETE FROM i2b2demodata.patient_dimension WHERE sourcesystem_cd LIKE '$STUDYID:%';
DELETE FROM i2b2demodata.observation_fact WHERE sourcesystem_cd='$STUDYID';
DELETE FROM i2b2demodata.patient_trial WHERE trial='$STUDYID';
DELETE FROM deapp.de_subject_microarray_data WHERE trial_name='$STUDYID';
DELETE FROM deapp.de_subject_sample_mapping WHERE TRIAL_NAME='$STUDYID';
DELETE FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='$STUDYID';
DELETE FROM i2b2metadata.i2b2_secure WHERE c_fullname='$STUDYID';
DELETE FROM i2b2demodata.encounter_mapping WHERE project_id='$STUDYID';
DELETE FROM deapp.de_subject_metabolomics_data WHERE trial_name='$STUDYID';
DELETE FROM i2b2metadata.tm_trial_nodes WHERE trial='$STUDYID';
EOD
