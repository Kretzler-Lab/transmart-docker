--
-- Type: TABLE; Owner: TM_CZ; Name: BIO_EXPERIMENT_RELEASE
--
 CREATE TABLE "TM_CZ"."BIO_EXPERIMENT_RELEASE" 
  (	"BIO_EXPERIMENT_ID" NUMBER(18,0), 
"BIO_EXPERIMENT_TYPE" VARCHAR2(200), 
"TITLE" VARCHAR2(1000), 
"DESCRIPTION" VARCHAR2(2000), 
"DESIGN" VARCHAR2(2000), 
"START_DATE" DATE, 
"COMPLETION_DATE" DATE, 
"PRIMARY_INVESTIGATOR" VARCHAR2(400), 
"CONTACT_FIELD" VARCHAR2(400), 
"ETL_ID" VARCHAR2(100), 
"STATUS" VARCHAR2(100 BYTE), 
"OVERALL_DESIGN" VARCHAR2(2000), 
"ACCESSION" VARCHAR2(100) NOT NULL ENABLE, 
"ENTRYDT" DATE, 
"UPDATED" DATE, 
"INSTITUTION" VARCHAR2(100), 
"COUNTRY" VARCHAR2(50), 
"BIOMARKER_TYPE" VARCHAR2(255), 
"TARGET" VARCHAR2(255), 
"RELEASE_STUDY" VARCHAR2(100) NOT NULL ENABLE, 
"ACCESS_TYPE" VARCHAR2(100)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

