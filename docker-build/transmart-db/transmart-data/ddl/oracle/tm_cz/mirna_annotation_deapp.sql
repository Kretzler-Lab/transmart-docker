--
-- Type: TABLE; Owner: TM_CZ; Name: MIRNA_ANNOTATION_DEAPP
--
 CREATE TABLE "TM_CZ"."MIRNA_ANNOTATION_DEAPP" 
  (	"ID_REF" VARCHAR2(100 BYTE), 
"PROBE_ID" VARCHAR2(100 BYTE), 
"MIRNA_SYMBOL" VARCHAR2(100 BYTE), 
"MIRNA_ID" VARCHAR2(100 BYTE), 
"PROBESET_ID" NUMBER(22,0), 
"ORGANISM" VARCHAR2(100 BYTE), 
"GPL_ID" VARCHAR2(50 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

