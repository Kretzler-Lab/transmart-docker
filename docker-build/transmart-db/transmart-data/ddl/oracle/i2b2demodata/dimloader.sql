--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: DIMLOADER
--
 CREATE TABLE "I2B2DEMODATA"."DIMLOADER"
  (	"C_HLEVEL" NUMBER(22,0),
"C_FULLNAME" VARCHAR2(900 BYTE),
"C_NAME" VARCHAR2(2000 BYTE),
"C_SYNONYM_CD" CHAR(1 BYTE),
"C_VISUALATTRIBUTES" CHAR(3 BYTE),
"C_TOTALNUM" NUMBER(22,0),
"C_BASECODE" VARCHAR2(50 BYTE),
"C_METADATAXML" CLOB,
"C_FACTTABLECOLUMN" VARCHAR2(50 BYTE),
"C_TABLENAME" VARCHAR2(50 BYTE),
"C_COLUMNNAME" VARCHAR2(50 BYTE),
"C_COLUMNDATATYPE" VARCHAR2(50 BYTE),
"C_OPERATOR" VARCHAR2(10 BYTE),
"C_DIMCODE" VARCHAR2(900 BYTE),
"C_COMMENT" CLOB,
"C_TOOLTIP" VARCHAR2(900 BYTE),
"UPDATE_DATE" DATE,
"DOWNLOAD_DATE" DATE,
"IMPORT_DATE" DATE,
"SOURCESYSTEM_CD" VARCHAR2(50 BYTE),
"VALUETYPE_CD" VARCHAR2(50 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2"
LOB ("C_METADATAXML") STORE AS SECUREFILE (
 TABLESPACE "I2B2" ENABLE STORAGE IN ROW CHUNK 8192
 NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES )
LOB ("C_COMMENT") STORE AS SECUREFILE (
 TABLESPACE "I2B2" ENABLE STORAGE IN ROW CHUNK 8192
 NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES ) ;
