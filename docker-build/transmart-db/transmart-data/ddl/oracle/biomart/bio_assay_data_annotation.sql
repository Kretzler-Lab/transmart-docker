--
-- Type: TABLE; Owner: BIOMART; Name: BIO_ASSAY_DATA_ANNOTATION
--
 CREATE TABLE "BIOMART"."BIO_ASSAY_DATA_ANNOTATION" 
  (	"BIO_ASSAY_FEATURE_GROUP_ID" NUMBER(18,0), 
"BIO_MARKER_ID" NUMBER(18,0) NOT NULL ENABLE, 
"DATA_TABLE" CHAR(5 BYTE),
 CONSTRAINT "BIO_D_FG_M_MARKER2_PK" UNIQUE ("BIO_MARKER_ID", "BIO_ASSAY_FEATURE_GROUP_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: INDEX; Owner: BIOMART; Name: BIO_A_O_AN_IDX2
--
CREATE INDEX "BIOMART"."BIO_A_O_AN_IDX2" ON "BIOMART"."BIO_ASSAY_DATA_ANNOTATION" ("BIO_ASSAY_FEATURE_GROUP_ID", "BIO_MARKER_ID")
TABLESPACE "INDX" 
PARALLEL 4 ;

--
-- Type: INDEX; Owner: BIOMART; Name: BIO_A_O_FG_ID_IDX
--
CREATE INDEX "BIOMART"."BIO_A_O_FG_ID_IDX" ON "BIOMART"."BIO_ASSAY_DATA_ANNOTATION" ("BIO_ASSAY_FEATURE_GROUP_ID")
TABLESPACE "INDX" 
PARALLEL 4 ;

