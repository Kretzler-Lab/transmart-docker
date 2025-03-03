--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: DX
--
 CREATE GLOBAL TEMPORARY TABLE "I2B2DEMODATA"."DX"
  (	"ENCOUNTER_NUM" NUMBER(38,0),
"INSTANCE_NUM" NUMBER(38,0),
"PATIENT_NUM" NUMBER(38,0),
"CONCEPT_CD" VARCHAR2(50 BYTE),
"START_DATE" DATE,
"PROVIDER_ID" VARCHAR2(50 BYTE),
"TEMPORAL_START_DATE" DATE,
"TEMPORAL_END_DATE" DATE
  ) ON COMMIT PRESERVE ROWS ;
