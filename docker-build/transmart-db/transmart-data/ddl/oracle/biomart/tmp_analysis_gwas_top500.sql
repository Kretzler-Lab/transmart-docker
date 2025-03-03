--
-- Type: TABLE; Owner: BIOMART; Name: TMP_ANALYSIS_GWAS_TOP500
--
 CREATE TABLE "BIOMART"."TMP_ANALYSIS_GWAS_TOP500" 
  (	"BIO_ASY_ANALYSIS_GWAS_ID" NUMBER(18,0) NOT NULL ENABLE, 
"BIO_ASSAY_ANALYSIS_ID" NUMBER(18,0) NOT NULL ENABLE, 
"RS_ID" VARCHAR2(50), 
"P_VALUE" BINARY_DOUBLE, 
"LOG_P_VALUE" BINARY_DOUBLE, 
"ETL_ID" NUMBER(18,0), 
"EXT_DATA" VARCHAR2(4000 BYTE), 
"P_VALUE_CHAR" VARCHAR2(100 BYTE), 
"RNUM" NUMBER
  ) SEGMENT CREATION IMMEDIATE
NOCOMPRESS NOLOGGING
 TABLESPACE "TRANSMART" ;
