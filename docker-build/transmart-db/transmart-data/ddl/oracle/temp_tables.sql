
--============================================================================
-- CREATE GLOBALS
--============================================================================
create  GLOBAL TEMPORARY TABLE TEMP_PDO_INPUTLIST    ( 
char_param1 varchar2(100)
 ) ON COMMIT PRESERVE ROWS
;

-- DX
CREATE GLOBAL TEMPORARY TABLE DX  (
	ENCOUNTER_NUM	NUMBER(38,0),
	INSTANCE_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	CONCEPT_CD 		varchar2(50), 
	START_DATE 		DATE,
	PROVIDER_ID 	varchar2(50), 
	temporal_start_date date, 
	temporal_end_date DATE	
 ) on COMMIT PRESERVE ROWS
;

-- QUERY_GLOBAL_TEMP
CREATE GLOBAL TEMPORARY TABLE QUERY_GLOBAL_TEMP   ( 
	ENCOUNTER_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	INSTANCE_NUM	NUMBER(18,0) ,
	CONCEPT_CD      VARCHAR2(50),
	START_DATE	    DATE,
	PROVIDER_ID     VARCHAR2(50),
	PANEL_COUNT		NUMBER(5,0),
	FACT_COUNT		NUMBER(22,0),
	FACT_PANELS		NUMBER(5,0)
 ) on COMMIT PRESERVE ROWS
;

-- GLOBAL_TEMP_PARAM_TABLE
 CREATE GLOBAL TEMPORARY TABLE GLOBAL_TEMP_PARAM_TABLE   (
	SET_INDEX	INT,
	CHAR_PARAM1	VARCHAR2(500),
	CHAR_PARAM2	VARCHAR2(500),
	NUM_PARAM1	INT,
	NUM_PARAM2	INT
) ON COMMIT PRESERVE ROWS
;

-- GLOBAL_TEMP_FACT_PARAM_TABLE
CREATE GLOBAL TEMPORARY TABLE GLOBAL_TEMP_FACT_PARAM_TABLE   (
	SET_INDEX	INT,
	CHAR_PARAM1	VARCHAR2(500),
	CHAR_PARAM2	VARCHAR2(500),
	NUM_PARAM1	INT,
	NUM_PARAM2	INT
) ON COMMIT PRESERVE ROWS
;

-- MASTER_QUERY_GLOBAL_TEMP
CREATE GLOBAL TEMPORARY TABLE MASTER_QUERY_GLOBAL_TEMP    ( 
	ENCOUNTER_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	INSTANCE_NUM	NUMBER(18,0) ,
	CONCEPT_CD      VARCHAR2(50),
	START_DATE	    DATE,
	PROVIDER_ID     VARCHAR2(50),
	MASTER_ID		VARCHAR2(50),
	LEVEL_NO		NUMBER(5,0),
	TEMPORAL_START_DATE DATE,
	TEMPORAL_END_DATE DATE
 ) ON COMMIT PRESERVE ROWS
;


