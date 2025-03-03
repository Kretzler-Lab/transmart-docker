--
-- Type: TABLE; Owner: I2B2METADATA; Name: TM_CONCEPT_COUNTS
--
 CREATE TABLE "I2B2METADATA"."TM_CONCEPT_COUNTS"
  (	"CONCEPT_PATH" VARCHAR2(500 BYTE),
"PARENT_CONCEPT_PATH" VARCHAR2(500 BYTE),
"PATIENT_COUNT" NUMBER(38,0)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2" ;
--
-- Type: INDEX; Owner: I2B2METADATA; Name: TM_CONCEPT_COUNTS_IDX
--
CREATE INDEX "I2B2METADATA"."TM_CONCEPT_COUNTS_IDX" ON "I2B2METADATA"."TM_CONCEPT_COUNTS" ("CONCEPT_PATH")
TABLESPACE "I2B2_INDEX" ;
