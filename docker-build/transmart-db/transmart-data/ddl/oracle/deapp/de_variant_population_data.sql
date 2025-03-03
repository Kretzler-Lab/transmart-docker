--
-- Type: TABLE; Owner: DEAPP; Name: DE_VARIANT_POPULATION_DATA
--
 CREATE TABLE "DEAPP"."DE_VARIANT_POPULATION_DATA" 
  (	"VARIANT_POPULATION_DATA_ID" NUMBER NOT NULL ENABLE, 
"DATASET_ID" VARCHAR2(50 BYTE), 
"CHR" VARCHAR2(50 BYTE), 
"POS" NUMBER, 
"INFO_NAME" VARCHAR2(100 BYTE), 
"INFO_INDEX" NUMBER(*,0) DEFAULT 0, 
"INTEGER_VALUE" NUMBER, 
"FLOAT_VALUE" FLOAT(126), 
"TEXT_VALUE" VARCHAR2(4000 BYTE), 
 CONSTRAINT "DE_VAR_POPULAT_DATA_ID_IDX" PRIMARY KEY ("VARIANT_POPULATION_DATA_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: REF_CONSTRAINT; Owner: DEAPP; Name: DE_VARIANT_POPULATION_DATA_FK
--
ALTER TABLE "DEAPP"."DE_VARIANT_POPULATION_DATA" ADD CONSTRAINT "DE_VARIANT_POPULATION_DATA_FK" FOREIGN KEY ("DATASET_ID")
 REFERENCES "DEAPP"."DE_VARIANT_DATASET" ("DATASET_ID") ENABLE;

--
-- Type: INDEX; Owner: DEAPP; Name: DE_VAR_POPULAT_DEFAULT_IDX
--
CREATE INDEX "DEAPP"."DE_VAR_POPULAT_DEFAULT_IDX" ON "DEAPP"."DE_VARIANT_POPULATION_DATA" ("DATASET_ID", "CHR", "POS", "INFO_NAME")
TABLESPACE "INDX" ;

--
-- Type: SEQUENCE; Owner: DEAPP; Name: DE_VARIANT_POPULATION_DATA_SEQ
--
CREATE SEQUENCE  "DEAPP"."DE_VARIANT_POPULATION_DATA_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_DE_VARIANT_PD_ID
--
  CREATE OR REPLACE TRIGGER "DEAPP"."TRG_DE_VARIANT_PD_ID" 
before insert on "DEAPP"."DE_VARIANT_POPULATION_DATA"
for each row begin
       	if inserting then
               	if :NEW."VARIANT_POPULATION_DATA_ID" is null then
                       	select DE_VARIANT_POPULATION_DATA_SEQ.nextval into :NEW."VARIANT_POPULATION_DATA_ID" from dual;
               	end if;
       	end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_DE_VARIANT_PD_ID" ENABLE;
 
