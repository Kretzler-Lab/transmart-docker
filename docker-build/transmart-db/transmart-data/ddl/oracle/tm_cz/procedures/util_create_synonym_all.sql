--
-- Type: PROCEDURE; Owner: TM_CZ; Name: UTIL_CREATE_SYNONYM_ALL
--
CREATE OR REPLACE PROCEDURE TM_CZ.UTIL_CREATE_SYNONYM_ALL (
    V_FROMZONE IN VARCHAR2 DEFAULT NULL ,
    V_WHATTYPE IN VARCHAR2 DEFAULT 'PROCEDURES,FUNCTIONS,TABLES,VIEWS'
)

    AUTHID CURRENT_USER

AS

    -------------------------------------------------------------------------------------
    -- NAME: UTIL_CREATE or REPLACE _SYNONYM_ALL
    --
    -- Copyright c 2011 Recombinant Data Corp.
    --
    --------------------------------------------------------------------------------------

    --The name of the table, proc, function or view.
    V_OBJNAME VARCHAR2(50);

    --Dynamic SQL line
    V_CMDLINE VARCHAR2(200);

    --Table list
    CURSOR L_TABLE IS
	SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = UPPER(V_FROMZONE);
    --View List
    CURSOR L_VIEW IS
	SELECT VIEW_NAME FROM ALL_VIEWS WHERE OWNER = UPPER(V_FROMZONE);
    --Procedure and function list (OBJTYPE are PROCEDURE, FUNCTION, TRIGGER)
    CURSOR L_PROCEDURE (OBJTYPE VARCHAR2) IS
	SELECT DISTINCT OBJECT_NAME FROM ALL_PROCEDURES
	 WHERE OWNER = UPPER(V_FROMZONE) AND OBJECT_TYPE = OBJTYPE
	   AND UPPER(OBJECT_NAME) NOT LIKE 'UTIL%';

BEGIN

    -- Create synonyms for Tables
    IF UPPER(V_WHATTYPE) LIKE '%TABLE%' THEN

	OPEN L_TABLE;
	FETCH L_TABLE INTO V_OBJNAME;
	WHILE L_TABLE%FOUND
	    LOOP
	    BEGIN

		V_CMDLINE := 'create or replace synonym ' || V_OBJNAME || ' for ' || UPPER(V_FROMZONE) || '.' || V_OBJNAME ;

		EXECUTE IMMEDIATE V_CMDLINE;
		--DBMS_OUTPUT.PUT_LINE('SUCCESS ' || V_CMDLINE);

		FETCH L_TABLE  INTO V_OBJNAME;

	    EXCEPTION
		WHEN OTHERS THEN
		    BEGIN
			DBMS_OUTPUT.PUT_LINE('ERROR ' || V_CMDLINE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		    END;
	    END;
	END LOOP;
	CLOSE L_TABLE;
    end if;

    --CREATE or REPLACE  SYNONYMS FOR VIEWS
    IF UPPER(V_WHATTYPE) LIKE '%VIEW%' THEN

	OPEN L_VIEW;
	FETCH L_VIEW INTO V_OBJNAME;
	WHILE L_VIEW%FOUND
	    LOOP
	    BEGIN

		V_CMDLINE := 'create or replace synonym ' || V_OBJNAME || ' for ' || UPPER(V_FROMZONE) || '.' || V_OBJNAME ;

		EXECUTE IMMEDIATE V_CMDLINE;
		--DBMS_OUTPUT.PUT_LINE('SUCCESS ' || V_CMDLINE);

		FETCH L_VIEW INTO V_OBJNAME;

	    EXCEPTION
		WHEN OTHERS THEN
		    BEGIN
			DBMS_OUTPUT.PUT_LINE('ERROR ' || V_CMDLINE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		    END;
	    END;
	END LOOP;
	CLOSE L_VIEW;
    END IF;

    -- CREATE or REPLACE  SYNONYMS FOR PROCEDURES
    IF UPPER(V_WHATTYPE) LIKE '%PROCEDURE%' THEN

	OPEN L_PROCEDURE('PROCEDURE');
	FETCH L_PROCEDURE INTO V_OBJNAME;
	WHILE L_PROCEDURE%FOUND
	    LOOP
	    BEGIN

		V_CMDLINE := 'create or replace synonym ' || V_OBJNAME || ' for ' || UPPER(V_FROMZONE) || '.' || V_OBJNAME ;

		EXECUTE IMMEDIATE V_CMDLINE;
		--DBMS_OUTPUT.PUT_LINE('SUCCESS ' || V_CMDLINE);

		FETCH l_procedure INTO V_OBJNAME;

	    EXCEPTION
		WHEN OTHERS THEN
		    BEGIN
			DBMS_OUTPUT.PUT_LINE('ERROR ' || V_CMDLINE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		    END;
	    END;
	END LOOP;
	CLOSE l_procedure;
    end if;

    -- CREATE or REPLACE  SYNONYMS FOR FUNCTIONS
    IF UPPER(V_WHATTYPE) LIKE '%FUNCTION%' THEN

	OPEN l_procedure('FUNCTION');
	FETCH l_procedure INTO V_OBJNAME;
	WHILE l_procedure%FOUND
	    LOOP
	    BEGIN

		V_CMDLINE := 'create synonym ' || V_OBJNAME || ' for ' || UPPER(V_FROMZONE) || '.' || V_OBJNAME ;

		EXECUTE IMMEDIATE V_CMDLINE;
		--DBMS_OUTPUT.PUT_LINE('SUCCESS ' || V_CMDLINE);

		FETCH L_PROCEDURE INTO V_OBJNAME;

	    EXCEPTION
		WHEN OTHERS THEN
		    BEGIN
			DBMS_OUTPUT.PUT_LINE('ERROR ' || V_CMDLINE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		    END;
	    END;
	END LOOP;
	CLOSE L_PROCEDURE;
    END IF;
END;
/

