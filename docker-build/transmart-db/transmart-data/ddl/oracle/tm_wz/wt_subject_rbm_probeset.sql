--
-- Type: TABLE; Owner: TM_WZ; Name: WT_SUBJECT_RBM_PROBESET
--
 CREATE TABLE "TM_WZ"."WT_SUBJECT_RBM_PROBESET" 
  (	"PROBESET" VARCHAR2(1000 BYTE), 
"EXPR_ID" VARCHAR2(500 BYTE), 
"INTENSITY_VALUE" NUMBER, 
"NUM_CALLS" NUMBER, 
"PVALUE" NUMBER, 
"ASSAY_ID" NUMBER(18,0), 
"PATIENT_ID" NUMBER(22,0), 
"SAMPLE_ID" VARCHAR2(100 BYTE), 
"SUBJECT_ID" VARCHAR2(100 BYTE), 
"TRIAL_NAME" VARCHAR2(100 BYTE), 
"TIMEPOINT" VARCHAR2(250 BYTE), 
"SAMPLE_TYPE" VARCHAR2(100 BYTE), 
"PLATFORM" VARCHAR2(200 BYTE), 
"TISSUE_TYPE" VARCHAR2(200 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

