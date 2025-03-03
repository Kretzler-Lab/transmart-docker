--
-- Type: TABLE; Owner: DEAPP; Name: DE_SNP_DATA_BY_PROBE
--
 CREATE TABLE "DEAPP"."DE_SNP_DATA_BY_PROBE" 
  (	"SNP_DATA_BY_PROBE_ID" NUMBER(22,0) NOT NULL ENABLE, 
"PROBE_ID" NUMBER(22,0), 
"PROBE_NAME" VARCHAR2(255 BYTE), 
"SNP_ID" NUMBER(22,0), 
"SNP_NAME" VARCHAR2(255 BYTE), 
"TRIAL_NAME" VARCHAR2(100 BYTE), 
"DATA_BY_PROBE" CLOB, 
 CONSTRAINT "DE_SNP_DATA_BY_PROBE_PK" PRIMARY KEY ("SNP_DATA_BY_PROBE_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" 
LOB ("DATA_BY_PROBE") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE NOLOGGING ) ;

--
-- Type: REF_CONSTRAINT; Owner: DEAPP; Name: FK_SNP_BY_PROBE_PROBE_ID
--
ALTER TABLE "DEAPP"."DE_SNP_DATA_BY_PROBE" ADD CONSTRAINT "FK_SNP_BY_PROBE_PROBE_ID" FOREIGN KEY ("PROBE_ID")
 REFERENCES "DEAPP"."DE_SNP_PROBE" ("SNP_PROBE_ID") ENABLE;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_SNP_DATA_BY_PROBE_ID
--
  CREATE OR REPLACE TRIGGER "DEAPP"."TRG_SNP_DATA_BY_PROBE_ID" 
before insert on DE_SNP_DATA_BY_PROBE
for each row
begin
   if inserting then
      if :NEW.SNP_DATA_BY_PROBE_ID is null then
         select SEQ_DATA_ID.nextval into :NEW.SNP_DATA_BY_PROBE_ID from dual;
      end if;
  end if;
end;

/
ALTER TRIGGER "DEAPP"."TRG_SNP_DATA_BY_PROBE_ID" ENABLE;
 
--
-- Type: REF_CONSTRAINT; Owner: DEAPP; Name: FK_SNP_BY_PROBE_SNP_ID
--
ALTER TABLE "DEAPP"."DE_SNP_DATA_BY_PROBE" ADD CONSTRAINT "FK_SNP_BY_PROBE_SNP_ID" FOREIGN KEY ("SNP_ID")
 REFERENCES "DEAPP"."DE_SNP_INFO" ("SNP_INFO_ID") ENABLE;

