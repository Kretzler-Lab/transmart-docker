--
-- Type: TABLE; Owner: BIOMART; Name: BIO_LIT_REF_DATA
--
 CREATE TABLE "BIOMART"."BIO_LIT_REF_DATA" 
  (	"BIO_LIT_REF_DATA_ID" NUMBER(18,0) NOT NULL ENABLE, 
"ETL_ID" VARCHAR2(50), 
"COMPONENT" VARCHAR2(100), 
"COMPONENT_CLASS" VARCHAR2(250), 
"GENE_ID" VARCHAR2(100), 
"MOLECULE_TYPE" VARCHAR2(50), 
"VARIANT" VARCHAR2(250), 
"REFERENCE_TYPE" VARCHAR2(50), 
"REFERENCE_ID" VARCHAR2(250), 
"REFERENCE_TITLE" VARCHAR2(2000), 
"BACK_REFERENCES" VARCHAR2(1000), 
"STUDY_TYPE" VARCHAR2(250), 
"DISEASE" VARCHAR2(250), 
"DISEASE_ICD10" VARCHAR2(250), 
"DISEASE_MESH" VARCHAR2(250), 
"DISEASE_SITE" VARCHAR2(250), 
"DISEASE_STAGE" VARCHAR2(250), 
"DISEASE_GRADE" VARCHAR2(250), 
"DISEASE_TYPES" VARCHAR2(250), 
"DISEASE_DESCRIPTION" VARCHAR2(1000), 
"PHYSIOLOGY" VARCHAR2(250), 
"STAT_CLINICAL" VARCHAR2(500), 
"STAT_CLINICAL_CORRELATION" VARCHAR2(250), 
"STAT_TESTS" VARCHAR2(500), 
"STAT_COEFFICIENT" VARCHAR2(500), 
"STAT_P_VALUE" VARCHAR2(100), 
"STAT_DESCRIPTION" VARCHAR2(1000), 
 CONSTRAINT "BIO_LIT_REF_DATA_PK" PRIMARY KEY ("BIO_LIT_REF_DATA_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: BIOMART; Name: TRG_BIO_LIT_REF_DATA_ID
--
  CREATE OR REPLACE TRIGGER "BIOMART"."TRG_BIO_LIT_REF_DATA_ID" 
before insert on "BIO_LIT_REF_DATA"
for each row
begin
     if inserting then
       if :NEW."BIO_LIT_REF_DATA_ID" is null then
          select SEQ_BIO_DATA_ID.nextval into :NEW."BIO_LIT_REF_DATA_ID" from dual;
       end if;
    end if;
  end;
/
ALTER TRIGGER "BIOMART"."TRG_BIO_LIT_REF_DATA_ID" ENABLE;
 
