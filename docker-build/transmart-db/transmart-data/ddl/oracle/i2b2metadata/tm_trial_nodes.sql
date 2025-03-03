--
-- Type: TABLE; Owner: I2B2METADATA; Name: TM_TRIAL_NODES
--
 CREATE TABLE "I2B2METADATA"."TM_TRIAL_NODES"
  (	"TRIAL" VARCHAR2(50 BYTE) NOT NULL ENABLE,
"C_FULLNAME" VARCHAR2(700 BYTE) NOT NULL ENABLE,
 CONSTRAINT "TM_TRIAL_NODES_PK" PRIMARY KEY ("C_FULLNAME")
 USING INDEX
 TABLESPACE "I2B2_INDEX"  ENABLE
   ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2" ;

--
-- Type: INDEX; Owner: I2B2METADATA; Name:TM_TN_TRIAL
--
CREATE INDEX "I2B2METADATA"."TM_TN_TRIAL" ON "I2B2METADATA"."TM_TRIAL_NODES" ("TRIAL")
TABLESPACE "I2B2_INDEX" ;
