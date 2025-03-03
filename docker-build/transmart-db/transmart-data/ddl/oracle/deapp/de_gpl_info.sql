--
-- Type: TABLE; Owner: DEAPP; Name: DE_GPL_INFO
--
 CREATE TABLE "DEAPP"."DE_GPL_INFO" 
  (	"PLATFORM" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"TITLE" VARCHAR2(500 BYTE), 
"ORGANISM" VARCHAR2(100 BYTE), 
"ANNOTATION_DATE" TIMESTAMP (6), 
"MARKER_TYPE" VARCHAR2(100 BYTE), 
"RELEASE_NBR" VARCHAR2(50 BYTE), 
"GENOME_BUILD" VARCHAR2(20 BYTE), 
"GENE_ANNOTATION_ID" VARCHAR2(50 BYTE), 
 CONSTRAINT "DE_GPL_INFO_PK" PRIMARY KEY ("PLATFORM")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

