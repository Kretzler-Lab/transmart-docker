--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_MIRNA_INC_SUB_ZSCORE
--
CREATE OR REPLACE PROCEDURE TM_CZ.I2B2_MIRNA_INC_SUB_ZSCORE (
    trial_id IN VARCHAR2
    ,data_type IN VARCHAR2
    ,currentJobID 	NUMBER := null
)

AS

    TrialID		varchar2(100);
    DataType              varchar2(5);

    --Audit variables
    newJobFlag INTEGER(1);
    databaseName VARCHAR(100);
    procedureName VARCHAR(100);
    jobID number(18,0);
    stepCt number(18,0);

    cursor zscore_params_qpcr is
	SELECT AVG(-d.log_intensity)mean_value,median(-d.log_intensity)median_value,STDDEV_POP(-d.log_intensity)stddev_value,d.probeset_id
	  FROM deapp.de_subject_mirna_data d
	 WHERE d.trial_name = trial_id
	 GROUP BY d.trial_name,d.probeset_id;

    cursor zscore_params_seq is

	SELECT AVG(d.log_intensity)mean_value,median(d.log_intensity)median_value,STDDEV(d.log_intensity)stddev_value,d.probeset_id
	  FROM deapp.de_subject_mirna_data d
	 WHERE d.trial_name = trial_id
	 GROUP BY d.trial_name,
		  d.probeset_id;

BEGIN

    TrialID := upper(trial_id);
    DataType:=upper(data_type);

    SELECT sys_context('USERENV', 'CURRENT_SCHEMA') INTO databaseName FROM dual;
    procedureName := $$PLSQL_UNIT;

    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it

    IF(jobID IS NULL or jobID < 1) THEN
        newJobFlag := 1; -- True
        tm_cz.cz_start_audit (procedureName, databaseName, jobID);
    END IF;

    stepCt := 0;
    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting I2B2_MIRNA_INC_SUB_ZSCORE',0,stepCt,'Done');

    -- call the cursor and update the z-score value for incmental data;

    if  DataType='R' then
        for UpdateZscore in zscore_params_qpcr
            loop
            update deapp.de_subject_mirna_data d
               set d.zscore=(CASE WHEN UpdateZscore.stddev_value=0 THEN 0 ELSE (-d.log_intensity - UpdateZscore.median_value ) / UpdateZscore.stddev_value END)
             where d.trial_name=TrialID
                   and d.probeset_id=UpdateZscore.probeset_id;

        end loop;
    else

        for UpdateZscore in zscore_params_seq
            loop

            update deapp.de_subject_mirna_data d
               set d.zscore=(CASE WHEN UpdateZscore.stddev_value=0 THEN 0 ELSE (d.log_intensity - UpdateZscore.median_value ) / UpdateZscore.stddev_value END)
             where d.trial_name=TrialID
                   and d.probeset_id=UpdateZscore.probeset_id;

        end loop;
    end if;

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'update zscore calc for this trial',0,stepCt,'Done');
    commit;

    --Normalize the  zscore value when greater than 2.5 and lesser than -2.5

    update deapp.de_subject_mirna_data
       set zscore=(CASE WHEN zscore < -2.5 THEN -2.5 WHEN zscore >  2.5 THEN  2.5 ELSE round(zscore,5) END)
     where trial_name=TrialID;

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Normalize the zscore calc value',0,stepCt,'Done');
    commit;

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'END of I2B2_MIRNA_INC_SUB_ZSCORE',0,stepCt,'Done');
    commit;

END I2B2_MIRNA_INC_SUB_ZSCORE;
/

