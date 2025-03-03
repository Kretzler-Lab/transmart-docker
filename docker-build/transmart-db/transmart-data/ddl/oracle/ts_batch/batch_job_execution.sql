--
-- Type: TABLE; Owner: TS_BATCH; Name: BATCH_JOB_EXECUTION
--
 CREATE TABLE "TS_BATCH"."BATCH_JOB_EXECUTION" 
  (	"JOB_EXECUTION_ID" NUMBER(18,0) NOT NULL ENABLE,
"VERSION" NUMBER(18,0),
"JOB_INSTANCE_ID" NUMBER(18,0) NOT NULL ENABLE,
"CREATE_TIME" TIMESTAMP (6) NOT NULL ENABLE,
"START_TIME" TIMESTAMP (6),
"END_TIME" TIMESTAMP (6),
"STATUS" VARCHAR2(10 BYTE), 
"EXIT_CODE" VARCHAR2(2500 BYTE), 
"EXIT_MESSAGE" VARCHAR2(2500 BYTE),
"LAST_UPDATED" TIMESTAMP (6),
"JOB_CONFIGURATION_LOCATION" VARCHAR2(2500 BYTE),
CONSTRAINT "BATCH_JOB_EXECUTION_PK" PRIMARY KEY ("JOB_EXECUTION_ID")
USING INDEX
TABLESPACE "INDX" ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: REF_CONSTRAINT; Owner: TS_BATCH; Name: JOB_INST_EXEC_FK
--
ALTER TABLE "TS_BATCH"."BATCH_JOB_EXECUTION" ADD CONSTRAINT "JOB_INST_EXEC_FK" FOREIGN KEY ("JOB_INSTANCE_ID")
 REFERENCES "TS_BATCH"."BATCH_JOB_INSTANCE" ("JOB_INSTANCE_ID") ENABLE;
