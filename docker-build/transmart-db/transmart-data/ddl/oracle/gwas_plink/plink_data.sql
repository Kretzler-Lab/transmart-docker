--
-- Type: TABLE; Schema: gwas_plink; Owner: GWAS_PLINK; Name: PLINK_DATA
--
 CREATE TABLE "GWAS_PLINK"."PLINK_DATA"
  (     "PLINK_DATA_ID" NUMBER(10,0) NOT NULL ENABLE,
"STUDY_ID" VARCHAR2(50) NOT NULL ENABLE,
"BED" BLOB,
"BIM" BLOB,
"FAM" BLOB,
 CONSTRAINT "PLINK_DATA_" PRIMARY KEY ("PLINK_DATA_ID")
 USING INDEX
 TABLESPACE "INDX" ENABLE,
 CONSTRAINT "PLINK_DATA_STUDY_ID_KEY" UNIQUE ("STUDY_ID")
 USING INDEX
 TABLESPACE "INDX" ENABLE
 ) SEGMENT CREATION IMMEDIATE
TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: GWAS_PLINK; Name: TRG_PLINK_DATA_ID
--
CREATE OR REPLACE TRIGGER "GWAS_PLINK"."TRG_PLINK_DATA_ID" 
BEFORE INSERT ON "GWAS_PLINK"."PLINK_DATA"
FOR EACH ROW
BEGIN
IF INSERTING THEN
IF :NEW."PLINK_DATA_ID" IS NULL THEN
SELECT SEQ_PLINK_DATA_ID.nextval
INTO :NEW."PLINK_DATA_ID"
FROM dual;
END IF;
END IF;
END;
/

ALTER TRIGGER "GWAS_PLINK"."TRG_PLINK_DATA_ID" ENABLE;
