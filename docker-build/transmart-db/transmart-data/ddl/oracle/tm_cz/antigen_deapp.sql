--
-- Type: SEQUENCE; Owner: TM_CZ; Name: SEQ_ANTIGEN_ID
--
CREATE SEQUENCE  "TM_CZ"."SEQ_ANTIGEN_ID"  MINVALUE 1 MAXVALUE 99999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TABLE; Owner: TM_CZ; Name: ANTIGEN_DEAPP
--
 CREATE TABLE "TM_CZ"."ANTIGEN_DEAPP" 
  (	"ANTIGEN_ID" NUMBER(22,0) NOT NULL ENABLE, 
"ANTIGEN_NAME" VARCHAR2(100 BYTE) NOT NULL ENABLE, 
"PLATFORM" VARCHAR2(100 BYTE) NOT NULL ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: TM_CZ; Name: TRG_ANTIGEN_DEAPP
--
  CREATE OR REPLACE TRIGGER "TM_CZ"."TRG_ANTIGEN_DEAPP" 
	before insert on "TM_CZ"."ANTIGEN_DEAPP"    
	for each row begin     
		if inserting then       
			if :NEW."ANTIGEN_ID" is null then
				select SEQ_ANTIGEN_ID.nextval into :NEW."ANTIGEN_ID" from dual;       
			end if;   
		end if; 
	end;

/
ALTER TRIGGER "TM_CZ"."TRG_ANTIGEN_DEAPP" ENABLE;
 
