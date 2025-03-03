--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: UPLOAD_STATUS
--
 CREATE TABLE "I2B2DEMODATA"."UPLOAD_STATUS"
  (	"UPLOAD_ID" NUMBER(38,0) NOT NULL ENABLE,
"UPLOAD_LABEL" VARCHAR2(500 BYTE) NOT NULL ENABLE,
"USER_ID" VARCHAR2(100 BYTE) NOT NULL ENABLE,
"SOURCE_CD" VARCHAR2(50 BYTE) NOT NULL ENABLE,
"NO_OF_RECORD" NUMBER,
"LOADED_RECORD" NUMBER,
"DELETED_RECORD" NUMBER,
"LOAD_DATE" DATE NOT NULL ENABLE,
"END_DATE" DATE,
"LOAD_STATUS" VARCHAR2(100 BYTE),
"MESSAGE" CLOB,
"INPUT_FILE_NAME" CLOB,
"LOG_FILE_NAME" CLOB,
"TRANSFORM_NAME" VARCHAR2(500 BYTE),
 CONSTRAINT "PK_UP_UPSTATUS_UPLOADID" PRIMARY KEY ("UPLOAD_ID")
 USING INDEX
 TABLESPACE "I2B2_INDEX"  ENABLE
  ) SEGMENT CREATION DEFERRED
 TABLESPACE "I2B2"
LOB ("MESSAGE") STORE AS SECUREFILE (
 TABLESPACE "I2B2" ENABLE STORAGE IN ROW CHUNK 8192
 NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES )
LOB ("INPUT_FILE_NAME") STORE AS SECUREFILE (
 TABLESPACE "I2B2" ENABLE STORAGE IN ROW CHUNK 8192
 NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES )
LOB ("LOG_FILE_NAME") STORE AS SECUREFILE (
 TABLESPACE "I2B2" ENABLE STORAGE IN ROW CHUNK 8192
 NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES ) ;
--
-- Type: SEQUENCE; Owner: I2B2DEMODATA; Name: SQ_UPLOADSTATUS_UPLOADID
--
CREATE SEQUENCE  "I2B2DEMODATA"."SQ_UPLOADSTATUS_UPLOADID"  MINVALUE 1 MAXVALUE 9999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  ORDER  NOCYCLE ;

-- no trigger in i2b2

--
-- Type: TRIGGER; Owner: I2B2DEMODATA; Name: TRG_UPLOAD_STATUS_UPLOAD_ID
--
---  CREATE OR REPLACE TRIGGER "I2B2DEMODATA"."TRG_UPLOAD_STATUS_UPLOAD_ID"
---   before insert on "I2B2DEMODATA"."UPLOAD_STATUS"
---   for each row
---begin
---   if inserting then
---      if :NEW."UPLOAD_ID" is null then
---         select SQ_UPLOADSTATUS_UPLOADID.nextval into :NEW."UPLOAD_ID" from dual;
---      end if;
---   end if;
---end;
---/
---ALTER TRIGGER "I2B2DEMODATA"."TRG_UPLOAD_STATUS_UPLOAD_ID" ENABLE;
