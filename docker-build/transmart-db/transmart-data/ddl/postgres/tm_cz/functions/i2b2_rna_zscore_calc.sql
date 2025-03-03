--
-- Name: i2b2_rna_zscore_calc(character varying, character varying, character varying, numeric, character varying, numeric, character varying, bigint, character varying); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_rna_zscore_calc(trial_id character varying, partition_name character varying, partition_indx character varying, partitionid numeric, run_type character varying DEFAULT 'L'::character varying, currentjobid numeric DEFAULT 0, data_type character varying DEFAULT 'R'::character varying, log_base numeric DEFAULT 2, source_cd character varying DEFAULT NULL::character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE

    /*************************************************************************
     * This stored procedure is used to calculate z-scores for RNA sequencing data load
     * Date:10/23/2013
     ******************************************************************/

    TrialID varchar(50);
    sourceCD	varchar(50);
    sqlText varchar(2000);
    runType varchar(10);
    dataType varchar(10);
    stgTrial varchar(50);
    idxExists bigint;
    pExists	bigint;
    nbrRecs bigint;
    logBase numeric;
    partitionName varchar(200);
    partitionindx varchar(200);

    --Audit variables
    newJobFlag integer;
    databaseName varchar(100);
    procedureName varchar(100);
    jobID bigint;
    stepCt bigint;
    rowCt			bigint;
    errorNumber		character varying;
    errorMessage	character varying;

    cleanTablesValue	character varying(255);

BEGIN

    select paramvalue
      into cleanTablesValue
      from tm_cz.etl_settings
     where paramname in ('cleantables','CLEANTABLES');

    TrialId := trial_id;
    runType := run_type;
    dataType := data_type;
    logBase := log_base;
    sourceCd := source_cd;

    partitionindx := partition_indx;
    partitionName := partition_name;

    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_rna_zscore_calc';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    IF(coalesce(jobID::text, '') = '' or jobID < 1)
    THEN
	newJobFlag := 1; -- True
	perform tm_cz.cz_start_audit (procedureName, databaseName, jobID);
	END IF;

    stepCt := 0;

    select count(*) into pExists
      from information_schema.tables
     where table_name = partitionindx;

    if pExists = 0 then
	sqlText := 'create table ' || partitionName || ' ( constraint rna_' || partitionId::text || '_check check ( partition_id = ' || partitionId::text ||
	    ')) inherits (deapp.de_subject_rna_data)';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create partition ' || partitionName,1,stepCt,'Done');
    else
	sqlText := 'drop index if exists ' || partitionIndx || '_idx1';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	sqlText := 'drop index if exists ' || partitionIndx || '_idx2';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	sqlText := 'drop index if exists ' || partitionIndx || '_idx3';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	sqlText := 'drop index if exists ' || partitionIndx || '_idx4';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Drop indexes on ' || partitionName,1,stepCt,'Done');
	sqlText := 'truncate table ' || partitionName;
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate ' || partitionName,1,stepCt,'Done');
    end if;

    if runType != 'L' then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Invalid runType passed - procedure exiting'
			       ,0,stepCt,'Done');
	perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return -16;
    end if;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting zscore calc for ' || TrialId || ' RunType: ' || runType || ' dataType: ' || dataType,0,stepCt,'Done');

    if runType = 'L' then
	select distinct trial_name into stgTrial
	from tm_wz.wt_subject_rna_probeset;

	if stgTrial != TrialId then
	    stepCt := stepCt + 1;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'TrialId not the same as trial in wt_subject_rna_probeset - procedure exiting'
				   ,0,stepCt,'Done');
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	    perform tm_cz.cz_end_audit (jobId,'FAIL');
	    return -16;
	end if;
    end if;

    --	truncate tmp tables

    EXECUTE('truncate table tm_wz.wt_subject_rna_logs');
    EXECUTE('truncate table tm_wz.wt_subject_rna_calcs');
    EXECUTE('truncate table tm_wz.wt_subject_rna_med');

    EXECUTE('drop index if exists tm_wz.WT_SUBJECT_RNA_LOGS_I1');
    EXECUTE('drop index if exists tm_wz.WT_SUBJECT_RNA_CALCS_I1');

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done');

    --	if dataType = L, use intensity_value as log_intensity
    --	if dataType = R, always use intensity_value
    begin
	if dataType = 'L' then
	    insert into tm_wz.wt_subject_rna_logs
	    (probeset_id
	    ,intensity_value
	    ,assay_id
	    ,log_intensity
	    ,patient_id
	    )
	    select probeset
	    ,intensity_value
	    ,assay_id
	    ,intensity_value
	    ,patient_id
	    from tm_wz.wt_subject_rna_probeset
	    where trial_name = TrialId;

	else
	    insert into tm_wz.wt_subject_rna_logs
			(probeset_id
			,intensity_value
			,assay_id
			,log_intensity
			,patient_id
			)
	    select probeset
		   ,intensity_value
		   ,assay_id
		   ,round((CASE WHEN intensity_value <= 0 THEN ln(0.001) -- intensity should already be corrected to 0.001
			   ELSE ln(intensity_value)/ln(logBase::double precision) END)::numeric,5)
		   ,patient_id
	      from tm_wz.wt_subject_rna_probeset
	     where trial_name = TrialId;
	end if;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Loaded data for trial in tm_wz wt_subject_rna_logs',rowCt,stepCt,'Done');

    begin
	EXECUTE('create index wt_subject_rna_logs_i1 on tm_wz.wt_subject_rna_logs (trial_name, probeset_id) tablespace "indx"');
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create index on tm_wz wt_subject_rna_logs_i1',0,stepCt,'Done');

    --	calculate mean_intensity, median_intensity, and stddev_intensity per experiment, probe
    begin
	insert into tm_wz.wt_subject_rna_calcs
		    (trial_name
		    ,probeset_id
		    ,mean_intensity
		    ,median_intensity
		    ,stddev_intensity
		    )
	select d.trial_name
	       ,d.probeset_id
	       ,avg(log_intensity)
	       ,median(log_intensity)
	       ,stddev(log_intensity)
	  from tm_wz.wt_subject_rna_logs d
	 group by d.trial_name
		  ,d.probeset_id;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate intensities for trial in TM_WZ wt_subject_rna_calcs',rowCt,stepCt,'Done');

    begin
	EXECUTE('create index wt_subject_rna_calcs_i1 on tm_wz.wt_subject_rna_calcs (trial_name, probeset_id) tablespace "indx"');
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create index on tm_wz wt_subject_rna_calcs_i1',0,stepCt,'Done');

    -- calculate zscore
    begin
	insert into tm_wz.wt_subject_rna_med
		    (probeset_id
		    ,intensity_value
		    ,log_intensity
		    ,assay_id
		    ,mean_intensity
		    ,stddev_intensity
		    ,median_intensity
		    ,zscore
		    ,patient_id
		    )
	select d.probeset_id
	       ,d.intensity_value
	       ,d.log_intensity
	       ,d.assay_id
	       ,c.mean_intensity
	       ,c.stddev_intensity
	       ,c.median_intensity
	       ,CASE WHEN stddev_intensity=0 THEN 0 ELSE (log_intensity - median_intensity ) / stddev_intensity END
	       ,d.patient_id
	  from tm_wz.wt_subject_rna_logs d
	       ,tm_wz.wt_subject_rna_calcs c
	 where d.probeset_id = c.probeset_id;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate Z-Score for trial in TM_WZ wt_subject_rna_med',rowCt,stepCt,'Done');

    begin
	sqlText := 'insert into ' || partitionName ||
	    '(partition_id, trial_source,trial_name,assay_id,probeset_id,raw_intensity ' ||
	    ',log_intensity,zscore,patient_id) '||
	    'select ' || partitioniD::text || ', ''' || TrialId || '''' ||
	    ',''' || TrialId || ''',m.assay_id,m.probeset_id ' ||
	    ',round((case when ''' || dataType || '''= ''R'' then m.intensity_value::numeric '||
	    'when ''' || dataType || '''= ''L'' ' ||
	    'then case when ' || logBase || '= -1 then null else power(' || logBase || ', m.log_intensity)::numeric end ' ||
	    'else null end),4) as raw_intensity ' ||
	    ',round(m.log_intensity::numeric,4) ' ||
	    ',round(CASE WHEN m.zscore < -2.5 THEN -2.5 WHEN m.zscore >  2.5 THEN  2.5 ELSE round(m.zscore::numeric,5) END,5) ' ||
	    ',m.patient_id ' ||
	    'from tm_wz.wt_subject_rna_med m';
--	raise notice 'sqlText= %', sqlText;
	execute sqlText;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted data into ' || partitionName,rowCt,stepCt,'Done');

    -- create indexes on partition

    sqlText := ' create index ' || partitionIndx || '_idx1 on ' || partitionName || ' using btree (partition_id) tablespace indx';
--    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx2 on ' || partitionName || ' using btree (assay_id) tablespace indx';
--    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx3 on ' || partitionName || ' using btree (probeset_id) tablespace indx';
--    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx4 on ' || partitionName || ' using btree (assay_id, probeset_id) tablespace indx';
--    raise notice 'sqlText= %', sqlText;
    execute sqlText;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Created indexes on '||partitionName,4,stepCt,'Done');

    if (coalesce(cleanTablesValue,'yes')) then
        EXECUTE('truncate table tm_wz.wt_subject_rna_logs');
        EXECUTE('truncate table tm_wz.wt_subject_rna_calcs');
        EXECUTE('truncate table tm_wz.wt_subject_rna_med');

	stepCt := stepCt + 1;
    	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done');
    end if;

---Cleanup OVERALL JOB if this proc is being run standalone
    IF newJobFlag = 1
    THEN
	perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
    END IF;

    return 1;
END;

$$;

