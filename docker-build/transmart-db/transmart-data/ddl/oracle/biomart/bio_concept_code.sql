--
-- Type: TABLE; Owner: BIOMART; Name: BIO_CONCEPT_CODE
--
 CREATE TABLE "BIOMART"."BIO_CONCEPT_CODE" 
  (	"BIO_CONCEPT_CODE" VARCHAR2(200), 
"CODE_NAME" VARCHAR2(200 BYTE), 
"CODE_DESCRIPTION" VARCHAR2(1000), 
"CODE_TYPE_NAME" VARCHAR2(200), 
"BIO_CONCEPT_CODE_ID" NUMBER(18,0) NOT NULL ENABLE, 
"FILTER_FLAG" CHAR(1 BYTE) DEFAULT 0, 
 CONSTRAINT "BIO_CONCEPT_CODE_PK" PRIMARY KEY ("BIO_CONCEPT_CODE_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE, 
 CONSTRAINT "BIO_CONCEPT_CODE_UK" UNIQUE ("BIO_CONCEPT_CODE", "CODE_TYPE_NAME")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: BIOMART; Name: TRG_BIO_CONCEPT_CODE_ID
--
  CREATE OR REPLACE TRIGGER "BIOMART"."TRG_BIO_CONCEPT_CODE_ID"
before insert on "BIO_CONCEPT_CODE"
  for each row begin
    if inserting then
      if :NEW."BIO_CONCEPT_CODE_ID" is null then
        select SEQ_BIO_DATA_ID.nextval into :NEW."BIO_CONCEPT_CODE_ID" from dual;
      end if;
    end if;
  end;
/
ALTER TRIGGER "BIOMART"."TRG_BIO_CONCEPT_CODE_ID" ENABLE;
 
--
-- Type: INDEX; Owner: BIOMART; Name: BIO_CONCEPT_CODE_TYPE_INDEX
--
CREATE INDEX "BIOMART"."BIO_CONCEPT_CODE_TYPE_INDEX" ON "BIOMART"."BIO_CONCEPT_CODE" ("CODE_TYPE_NAME")
TABLESPACE "INDX" 
PARALLEL 4 ;

