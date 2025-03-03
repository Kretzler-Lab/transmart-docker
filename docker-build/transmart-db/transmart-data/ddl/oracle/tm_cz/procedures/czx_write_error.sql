--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_WRITE_ERROR
--
CREATE OR REPLACE PROCEDURE TM_CZ.CZX_WRITE_ERROR (
    JOBID IN NUMBER,
    ERRORNUMBER IN NUMBER ,
    ERRORMESSAGE IN VARCHAR2 ,
    ERRORSTACK IN VARCHAR2,
    ERRORBACKTRACE IN VARCHAR2
)
    AUTHID CURRENT_USER
AS
    PRAGMA AUTONOMOUS_TRANSACTION;

    /*************************************************************************
     * Copyright 2008-2012 Janssen Research and Development, LLC.
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     * http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     ******************************************************************/

BEGIN

    INSERT INTO tm_cz.cz_job_error(
	JOB_ID
	,ERROR_NUMBER
	,ERROR_MESSAGE
	,ERROR_STACK
	,ERROR_BACKTRACE
	,SEQ_ID
    )
    SELECT
	JOBID
	,ERRORNUMBER
	,ERRORMESSAGE
	,ERRORSTACK
	,ERRORBACKTRACE
	,MAX(SEQ_ID)
      FROM tm_cz.cz_job_audit
     WHERE
	 JOB_ID=JOBID;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN ROLLBACK;
END;
/

