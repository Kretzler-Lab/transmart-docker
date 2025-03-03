--
-- Type: USER; Name: BIOMART_STAGE
--
CREATE USER "BIOMART_STAGE" IDENTIFIED BY VALUES 'S:FA2819401185E87BB34E022CB387A6B2D56735660A55BF2E96FF9621D7C8;0AF103800E386834'
   DEFAULT TABLESPACE "TRANSMART"
   TEMPORARY TABLESPACE "TEMP";
--
-- Type: TABLESPACE_QUOTA; Name: BIOMART_STAGE
--
  DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
  SQLSTR := 'ALTER USER "BIOMART_STAGE" QUOTA UNLIMITED ON "TRANSMART"';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -30041 THEN
      SQLSTR := 'SELECT COUNT(*) FROM USER_TABLESPACES
              WHERE TABLESPACE_NAME = ''TRANSMART'' AND CONTENTS = ''TEMPORARY''';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/
  DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
  SQLSTR := 'ALTER USER "BIOMART_STAGE" QUOTA UNLIMITED ON "INDX"';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -30041 THEN
      SQLSTR := 'SELECT COUNT(*) FROM USER_TABLESPACES
              WHERE TABLESPACE_NAME = ''INDX'' AND CONTENTS = ''TEMPORARY''';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/
--
-- Type: SYSTEM_GRANT; Name: BIOMART_STAGE
--
GRANT UNLIMITED TABLESPACE TO "BIOMART_STAGE";
--
-- Type: ROLE_GRANT; Name: BIOMART_STAGE
--
GRANT "CONNECT" TO "BIOMART_STAGE";
GRANT "RESOURCE" TO "BIOMART_STAGE";
GRANT "DBA" TO "BIOMART_STAGE";
