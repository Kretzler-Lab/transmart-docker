--
-- Type: SEQUENCE; Owner: TM_LZ; Name: LT_CHROMO_REGION_ID_SEQ
--
CREATE SEQUENCE  "TM_LZ"."LT_CHROMO_REGION_ID_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;

--
-- Type: TABLE; Owner: TM_LZ; Name: LT_CHROMOSOMAL_REGION
--
 CREATE TABLE "TM_LZ"."LT_CHROMOSOMAL_REGION" 
  (	"REGION_ID" NUMBER NOT NULL ENABLE, 
"GPL_ID" VARCHAR2(50 BYTE), 
"CHROMOSOME" VARCHAR2(2 BYTE), 
"START_BP" NUMBER, 
"END_BP" NUMBER, 
"NUM_PROBES" NUMBER(*,0), 
"REGION_NAME" VARCHAR2(100 BYTE), 
"CYTOBAND" VARCHAR2(100 BYTE), 
"GENE_SYMBOL" VARCHAR2(100 BYTE), 
"GENE_ID" NUMBER, 
"ORGANISM" VARCHAR2(100 BYTE), 
 CONSTRAINT "LT_CHROMOSOMAL_REGION_PK" PRIMARY KEY ("REGION_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: TM_LZ; Name: TRG_LT_CHROMO_REGION_ID
--
  CREATE OR REPLACE TRIGGER "TM_LZ"."TRG_LT_CHROMO_REGION_ID" 
   before insert on "TM_LZ"."LT_CHROMOSOMAL_REGION" 
   for each row 
begin  
   if inserting then 
      if :NEW."REGION_ID" is null then 
         select LT_CHROMO_REGION_ID_SEQ.nextval into :NEW."REGION_ID" from dual; 
      end if; 
   end if; 
end;
/
ALTER TRIGGER "TM_LZ"."TRG_LT_CHROMO_REGION_ID" ENABLE;
 
