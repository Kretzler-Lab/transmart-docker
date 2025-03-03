--
-- Type: TABLE; Owner: TS_BATCH; Name: BATCH_JOB_EXECUTION_PARAMS
--
 CREATE TABLE "TS_BATCH"."BATCH_JOB_EXECUTION_PARAMS" 
  (	"JOB_EXECUTION_ID" NUMBER(18,0) NOT NULL ENABLE,
"TYPE_CD" VARCHAR2(6 BYTE) NOT NULL ENABLE,
"KEY_NAME" VARCHAR2(100 BYTE) NOT NULL ENABLE,
"STRING_VAL" VARCHAR2(250 BYTE),
"DATE_VAL" TIMESTAMP (6),
"LONG_VAL" NUMBER(22,0),
"DOUBLE_VAL" NUMBER(38,4),
"IDENTIFYING" CHAR(1 BYTE) NOT NULL ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: REF_CONSTRAINT; Owner: TS_BATCH; Name: JOB_EXEC_PARAMS_FK
--
ALTER TABLE "TS_BATCH"."BATCH_JOB_EXECUTION_PARAMS" ADD CONSTRAINT "JOB_EXEC_PARAMS_FK" FOREIGN KEY ("JOB_EXECUTION_ID")
 REFERENCES "TS_BATCH"."BATCH_JOB_EXECUTION" ("JOB_EXECUTION_ID") ENABLE;
