--
-- Type: TABLE; Owner: BIOMART; Name: BIO_CONTENT_REFERENCE
--
 CREATE TABLE "BIOMART"."BIO_CONTENT_REFERENCE" 
  (	"BIO_CONTENT_REFERENCE_ID" NUMBER(18,0) NOT NULL ENABLE, 
"BIO_CONTENT_ID" NUMBER(18,0) NOT NULL ENABLE, 
"BIO_DATA_ID" NUMBER(18,0) NOT NULL ENABLE, 
"CONTENT_REFERENCE_TYPE" VARCHAR2(200) NOT NULL ENABLE, 
"ETL_ID" NUMBER(18,0), 
"ETL_ID_C" VARCHAR2(30 BYTE), 
 CONSTRAINT "BIO_CONTENT_REFERENCE_PK" PRIMARY KEY ("BIO_CONTENT_REFERENCE_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: REF_CONSTRAINT; Owner: BIOMART; Name: BIO_CONTENT_REF_CONT_FK
--
ALTER TABLE "BIOMART"."BIO_CONTENT_REFERENCE" ADD CONSTRAINT "BIO_CONTENT_REF_CONT_FK" FOREIGN KEY ("BIO_CONTENT_ID")
 REFERENCES "BIOMART"."BIO_CONTENT" ("BIO_FILE_CONTENT_ID") ENABLE;

--
-- Type: TRIGGER; Owner: BIOMART; Name: TRG_BIO_CONTENT_REF_ID
--
  CREATE OR REPLACE TRIGGER "BIOMART"."TRG_BIO_CONTENT_REF_ID"
before insert on "BIO_CONTENT_REFERENCE"
  for each row begin
    if inserting then
      if :NEW."BIO_CONTENT_REFERENCE_ID" is null then
        select SEQ_BIO_DATA_ID.nextval into :NEW."BIO_CONTENT_REFERENCE_ID" from dual;
      end if;
    end if;
  end;
/
ALTER TRIGGER "BIOMART"."TRG_BIO_CONTENT_REF_ID" ENABLE;
 
