--
-- Type: TABLE; Owner: SEARCHAPP; Name: SEARCH_AUTH_SEC_OBJECT_ACCESS
--
 CREATE TABLE "SEARCHAPP"."SEARCH_AUTH_SEC_OBJECT_ACCESS" 
  (	"AUTH_SEC_OBJ_ACCESS_ID" NUMBER(18,0) NOT NULL ENABLE, 
"AUTH_PRINCIPAL_ID" NUMBER(18,0), 
"SECURE_OBJECT_ID" NUMBER(18,0), 
"SECURE_ACCESS_LEVEL_ID" NUMBER(18,0), 
 CONSTRAINT "SCH_SEC_A_A_S_A_PK" PRIMARY KEY ("AUTH_SEC_OBJ_ACCESS_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: REF_CONSTRAINT; Owner: SEARCHAPP; Name: SCH_SEC_S_O_FK
--
ALTER TABLE "SEARCHAPP"."SEARCH_AUTH_SEC_OBJECT_ACCESS" ADD CONSTRAINT "SCH_SEC_S_O_FK" FOREIGN KEY ("SECURE_OBJECT_ID")
 REFERENCES "SEARCHAPP"."SEARCH_SECURE_OBJECT" ("SEARCH_SECURE_OBJECT_ID") ENABLE;

--
-- Type: REF_CONSTRAINT; Owner: SEARCHAPP; Name: SCH_SEC_A_U_FK
--
ALTER TABLE "SEARCHAPP"."SEARCH_AUTH_SEC_OBJECT_ACCESS" ADD CONSTRAINT "SCH_SEC_A_U_FK" FOREIGN KEY ("AUTH_PRINCIPAL_ID")
 REFERENCES "SEARCHAPP"."SEARCH_AUTH_PRINCIPAL" ("ID") ENABLE;

--
-- Type: REF_CONSTRAINT; Owner: SEARCHAPP; Name: SCH_SEC_S_A_L_FK
--
ALTER TABLE "SEARCHAPP"."SEARCH_AUTH_SEC_OBJECT_ACCESS" ADD CONSTRAINT "SCH_SEC_S_A_L_FK" FOREIGN KEY ("SECURE_ACCESS_LEVEL_ID")
 REFERENCES "SEARCHAPP"."SEARCH_SEC_ACCESS_LEVEL" ("SEARCH_SEC_ACCESS_LEVEL_ID") ENABLE;

--
-- Type: TRIGGER; Owner: SEARCHAPP; Name: TRG_SEARCH_AU_OBJ_ACCESS_ID
--
  CREATE OR REPLACE TRIGGER "SEARCHAPP"."TRG_SEARCH_AU_OBJ_ACCESS_ID"
before insert on SEARCH_AUTH_SEC_OBJECT_ACCESS
  for each row begin
    if inserting then
      if :NEW.AUTH_SEC_OBJ_ACCESS_ID is null then
        select SEQ_SEARCH_DATA_ID.nextval into :NEW.AUTH_SEC_OBJ_ACCESS_ID from dual;
      end if;
    end if;
  end;
/
ALTER TRIGGER "SEARCHAPP"."TRG_SEARCH_AU_OBJ_ACCESS_ID" ENABLE;
 
