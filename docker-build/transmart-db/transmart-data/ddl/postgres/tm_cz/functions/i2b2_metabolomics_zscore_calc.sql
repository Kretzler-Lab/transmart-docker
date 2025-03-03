--
-- Name: i2b2_metabolomics_zscore_calc(character varying, character varying, character varying, numeric, character varying, numeric); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_metabolomics_zscore_calc(trial_id character varying, source_cd character varying, run_type character varying DEFAULT 'L'::character varying, currentjobid numeric DEFAULT 0, data_type character varying DEFAULT 'R'::character varying, log_base numeric DEFAULT 2) RETURNS numeric
    LANGUAGE plpgsql
AS $$
    declare

    /*************************************************************************
     This Stored Procedure is used in ETL load METABOLOMICS data
     Date:1/3/2014
     ******************************************************************/

    TrialID varchar(100);
    sourceCD	varchar(50);
    sqlText varchar(2000);
    runType varchar(10);
    dataType varchar(10);
    stgTrial varchar(100);
    idxExists numeric;
    pExists	numeric;
    nbrRecs numeric;
    logBase numeric;

    --Audit variables
    newJobFlag numeric(1);
    databaseName varchar(100);
    procedureName varchar(100);
    jobID integer;
    stepCt integer;
    rowCt integer;

begin

    TrialId := trial_id;
    runType := run_type;
    dataType := data_type;
    logBase := log_base;
    sourceCd := source_cd;
    RAISE NOTICE 'DK0';
    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_metabolomics_zscore_calc';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    IF(coalesce(jobID::text, '') = '' or jobID < 1)
    THEN
	newJobFlag := 1; -- True
	perform tm_cz.cz_start_audit (procedureName, databaseName, jobID);
	END IF;

    stepCt := 0;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting zscore calc for ' || TrialId || ' RunType: ' || runType || ' dataType: ' || dataType,0,stepCt,'Done');

    if runType != 'L' then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Invalid runType passed - procedure exiting'
			       ,SQL%ROWCOUNT,stepCt,'Done');
	--Handle errors.
    	perform tm_cz.cz_error_handler(jobId, procedureName, SQLSTATE, SQLERRM);
    	--End Proc
    	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    --	For Load, make sure that the TrialId passed as parameter is the same as the trial in stg_subject_METABOLOMICS_data
    --	If not, raise exception

    if runType = 'L' then
	select distinct trial_name into stgTrial
	from tm_wz.wt_subject_mbolomics_probeset;

	if stgTrial != TrialId then
	    stepCt := stepCt + 1;
	    get diagnostics rowCt := ROW_COUNT;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'TrialId not the same as trial in wt_subject_mbolomics_probeset - procedure exiting'
				   ,rowCt,stepCt,'Done');
	    --Handle errors.
    	    perform tm_cz.cz_error_handler(jobId, procedureName, SQLSTATE, SQLERRM);
    	    --End Proc
    	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
	end if;
    end if;

    --	truncate tmp tables

    execute('truncate table tm_wz.wt_subject_metabolomics_logs');
    execute('truncate table tm_wz.wt_subject_metabolomics_calcs');
    execute('truncate table tm_wz.wt_subject_metabolomics_med');

    select count(*)
      into idxExists
      from pg_indexes
     where tablename = 'wt_subject_metabolomics_logs'
       and indexname = 'wt_subject_mbolomics_logs_i1'
       and owner = 'tm_wz';

    if idxExists = 1 then
	execute('drop index tm_wz.wt_subject_mbolomics_logs_i1');
    end if;

    select count(*)
      into idxExists
      from pg_indexes
     where tablename = 'wt_subject_metabolomics_calcs'
       and indexname = 'wt_subject_metabolomics_calcs_i1'
       and owner = 'tm_wz';

    if idxExists = 1 then
	execute('drop index tm_wz.wt_subject_metabolomics_calcs_i1');
    end if;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done');

    --	if dataType = L, use intensity_value as log_intensity
    --	if dataType = R, always use intensity_value


    if dataType = 'L' then

	insert into tm_wz.wt_subject_metabolomics_logs
	(probeset
	,intensity_value
	,assay_id
	,log_intensity
	,patient_id
	--	,sample_cd
	,subject_id
	)
	select probeset
	,log_base ^ intensity_value
	,assay_id
	,intensity_value
	,patient_id
	--	  ,sample_cd
	,subject_id
	from tm_wz.wt_subject_mbolomics_probeset
	where trial_name = TrialId;

	--end if;
    else

        insert into tm_wz.wt_subject_metabolomics_logs
		    (probeset
		    ,intensity_value
		    ,assay_id
		    ,log_intensity
		    ,patient_id
		    --	,sample_cd
		    ,subject_id
		    )
	select probeset
	       ,intensity_value
	       ,assay_id
	       ,log(log_base,intensity_value)
	       ,patient_id
	    --		  ,sample_cd
	       ,subject_id
	  from tm_wz.wt_subject_mbolomics_probeset
	 where trial_name = TrialId;
	--		end if;

    end if;

    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Loaded data for trial in wt_subject_mirna_logs',rowCt,stepCt,'Done');

    commit;

    execute('create index wt_subject_mbolomics_logs_i1 on tm_wz.wt_subject_metabolomics_logs (trial_name, probeset) nologging  tablespace "INDX"');
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create index on wt_subject_mbolomics_logs_I1',0,stepCt,'Done');

    --	calculate mean_intensity, median_intensity, and stddev_intensity per experiment, probe

    insert into tm_wz.wt_subject_metabolomics_calcs
		(trial_name
		,probeset
		,mean_intensity
		,median_intensity
		,stddev_intensity
		)
    select d.trial_name
	   ,d.probeset
	   ,avg(log_intensity)
	   ,median(log_intensity)
	   ,stddev(log_intensity)
      from tm_wz.wt_subject_metabolomics_logs d
     group by d.trial_name
	      ,d.probeset;
    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate intensities for trial in wt_subject_metabolomics_calcs',rowCt,stepCt,'Done');

    commit;

    --execute immediate('create index wt_subject_METABOLOMICS_calcs_i1 on tm_wz.wt_subject_metabolomics_calcs (trial_name, probeset_id) nologging tablespace "INDX"');
    --stepCt := stepCt + 1;
    --perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create index on subject_metabolomics_calcs',0,stepCt,'Done');

    -- calculate zscore


    insert into tm_wz.wt_subject_metabolomics_med
		(probeset
		,intensity_value
		,log_intensity
		,assay_id
		,mean_intensity
		,stddev_intensity
		,median_intensity
		,zscore
		,patient_id
		--	,sample_cd
		,subject_id
		)
    select d.probeset
	   ,d.intensity_value
	   ,d.log_intensity
	   ,d.assay_id
	   ,c.mean_intensity
	   ,c.stddev_intensity
	   ,c.median_intensity
	   ,(CASE WHEN stddev_intensity=0 THEN 0 ELSE (log_intensity - median_intensity ) / stddev_intensity END)
	   ,d.patient_id
	--	  ,d.sample_cd
	   ,d.subject_id
      from tm_wz.wt_subject_metabolomics_logs d
	   ,tm_wz.wt_subject_metabolomics_calcs c
     where trim(d.probeset) = c.probeset;
    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate Z-Score for trial in wt_subject_metabolomics_med',rowCt,stepCt,'Done');

    commit;

    /*
      select count(*) into n
      select count(*) into nbrRecs
      from tm_wz.wt_subject_metabolomics_med;

      if nbrRecs > 10000000 then
      tm_cz.i2b2_mrna_index_maint('DROP',,jobId);
      stepCt := stepCt + 1;
      perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Drop indexes on de_subject_metabolomics_data',0,stepCt,'Done');
      else
      stepCt := stepCt + 1;
      perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Less than 10M records, index drop bypassed',0,stepCt,'Done');
      end if;
     */



    /*
      insert into deapp.de_subject_metabolomics_data
      (
      trial_source
      ,trial_name
      ,metabolite_annotation_id
      --,component
      --,gene_symbol
      --,gene_id
      ,assay_id
      ,subject_id
      ,raw_intensity
      ,log_intensity
      ,zscore
      ,patient_id
      )
      select m.trial_name || ':' || mpp.source_cd,
      TrialID
      ,d.Id
      ,m.assay_id
      ,m.subject_id
      ,m.intensity_value
      ,log(2.0,m.intensity_value)
      ,case when m.intensity_value < -2.5
      then -2.5
      when m.intensity_value > 2.5
      then 2.5
      else m.intensity_value
      end as zscore
      ,m.patient_id
      from tm_wz.wt_subject_mbolomics_probeset  m,
      (select distinct mp.source_cd From "tm_lz"."lt_src_metabolomic_map" mp where rownum = 1 and mp.trial_name =TrialID) mpp
      ,deapp.de_metabolite_annotation d
      where m.trial_name = TrialID
      and d.biochemical_name = m.probeset;
     */
    insert into deapp.de_subject_metabolomics_data
		(
		    trial_source
		    ,trial_name
		    ,metabolite_annotation_id
		    --,component
		    --,gene_symbol
		    --,gene_id
		    ,assay_id
		    ,subject_id
		    ,raw_intensity
		    ,log_intensity
		    ,zscore
		    ,patient_id
		)
    select
        TrialId || ':' || mpp.source_cd,
        TrialId
        ,d.id
        --,m.probeset_id
        --,d.hmdb_id
        --,d.biomarker_id
        ,m.assay_id
        ,m.subject_id
	--  ,decode(dataType,'R',m.intensity_value,'L',power(logBase, m.log_intensity),null)
        ,m.intensity_value
	,round(m.log_intensity,4)
        ,round(CASE WHEN m.zscore < -2.5 THEN -2.5 WHEN m.zscore >  2.5 THEN  2.5 ELSE round(m.zscore,5) END,5)
        ,m.patient_id
      from tm_wz.wt_subject_metabolomics_med m,
           (select distinct mp.source_cd,mp.platform From "TM_LZ"."LT_SRC_METABOLOMIC_MAP" mp LIMIT 1 OFFSET 1 and mp.trial_name =TrialID) mpp
	   , deapp.de_metabolite_annotation d
     where trim(d.biochemical_name) = trim(m.probeset)
       and d.gpl_id = mpp.platform;

    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial in de_subject_metabolomics_data',rowCt,stepCt,'Done');

    commit;

    --	add indexes, if indexes were not dropped, procedure will not try and recreate
    /*
      tm_cz.i2b2_mrna_index_maint('ADD',,jobId);
      stepCt := stepCt + 1;
      perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Add indexes on de_subject_metabolomics_data',0,stepCt,'Done');
     */

    --	cleanup tmp_ files

    --execute immediate('truncate table tm_wz.WT_SUBJECT_METABOLOMICS_LOGS');
    --execute immediate('truncate table tm_wz.WT_SUBJECT_METABOLOMICS_CALCS');
    --execute immediate('truncate table tm_wz.WT_SUBJECT_METABOLOMICS_MED');

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done');

    ---Cleanup OVERALL JOB if this proc is being run standalone
    IF newJobFlag = 1
    THEN
	perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
    END IF;

    return 1;

EXCEPTION
    when OTHERS THEN
    --Handle errors.
	perform tm_cz.cz_error_handler(jobId, procedureName, SQLSTATE, SQLERRM);


	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
END;

$$;

--
-- Name: i2b2_metabolomics_zscore_calc(character varying, character varying, character varying, numeric, character varying, character varying, numeric, character varying, numeric); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_metabolomics_zscore_calc(trial_id character varying, partition_name character varying, partition_indx character varying, partitionid numeric, source_cd character varying, run_type character varying DEFAULT 'L'::character varying, currentjobid numeric DEFAULT 0, data_type character varying DEFAULT 'R'::character varying, log_base numeric DEFAULT 2) RETURNS numeric
    LANGUAGE plpgsql
AS $$
    declare

    /*************************************************************************
     This Stored Procedure is used in ETL load METABOLOMICS data
     Date:1/3/2014
     ******************************************************************/

    TrialID		varchar(100);
    sourceCD		varchar(50);
    sqlText		varchar(2000);
    runType		varchar(10);
    dataType		varchar(10);
    stgTrial		varchar(100);
    idxExists		numeric;
    pExists		numeric;
    nbrRecs		numeric;
    logBase		numeric;
    partitionName	varchar(200);
    partitionindx	varchar(200);


    --Audit variables
    newJobFlag		integer;
    databaseName	varchar(100);
    procedureName	varchar(100);
    jobID		numeric;
    stepCt		numeric;
    rowCt		bigint;
    errorNumber		character varying;
    errorMessage	character varying;

begin

    TrialId := trial_id;
    runType := run_type;
    dataType := data_type;
    logBase := log_base;
    sourceCd := source_cd;
    RAISE NOTICE 'DK0';
    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    partitionindx := partition_indx;
    partitionName := partition_name;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_metabolomics_zscore_calc';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    if(coalesce(jobID::text, '') = '' or jobID < 1) then
	newJobFlag := 1; -- True
	select tm_cz.cz_start_audit (procedureName, databaseName, jobID) into jobId;
    end if;

    stepCt := 0;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting zscore calc for ' || TrialId || ' RunType: ' || runType || ' dataType: ' || dataType,0,stepCt,'Done');

    if runType != 'L' then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Invalid runType passed - procedure exiting'
			       ,0,stepCt,'Done');
	perform tm_cz.cz_error_handler(jobid,procedurename, '-1', 'Application raised error');
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return -16;
    end if;

    --	For Load, make sure that the TrialId passed as parameter is the same as the trial in stg_subject_METABOLOMICS_data
    --	If not, raise exception

    if runType = 'L' then
	select distinct trial_name into stgTrial
	from TM_WZ.WT_SUBJECT_MBOLOMICS_PROBESET;

	if stgTrial != TrialId then
	    stepCt := stepCt + 1;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'TrialId not the same as trial in WT_SUBJECT_MBOLOMICS_PROBESET - procedure exiting'
				   ,0,stepCt,'Done');
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	    perform tm_cz.cz_end_audit (jobId,'FAIL');
	    return -16;
	end if;
    end if;

    --	remove Reload processing
    --	For Reload, make sure that the TrialId passed as parameter has data in de_subject_metabolomics_data
    --	If not, raise exception

    if runType = 'R' then
	select count(*) into idxExists
	from deapp.de_subject_metabolomics_data
	where trial_name = TrialId;

	if idxExists = 0 then
	    stepCt := stepCt + 1;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'No data for TrialId in de_subject_metabolomics_data - procedure exiting'
				  ,0,stepCt,'Done');
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	    perform tm_cz.cz_end_audit (jobId,'FAIL');
	    return -16;
	end if;
    end if;

    execute('truncate table tm_wz.wt_subject_metabolomics_logs');
    execute('truncate table tm_wz.wt_subject_metabolomics_calcs');
    execute('truncate table tm_wz.wt_subject_metabolomics_med');

    execute('drop index if exists tm_wz.wt_subject_mbolomics_logs_i1');
    execute('drop index if exists tm_wz.wt_subject_metabolomics_calcs_i1');

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Truncate work tables in TM_WZ',0,stepCt,'Done');

    --	if dataType = L, use intensity_value as log_intensity
    --	if dataType = R, always use intensity_value
    begin
	if dataType = 'L' then
	    insert into wt_subject_metabolomics_logs
	    (probeset
	    ,intensity_value
	    ,assay_id
	    ,log_intensity
	    ,patient_id
	    ,subject_id
	    )
	    select probeset
	    ,log_base ^ intensity_value
	    ,assay_id
	    ,intensity_value
	    ,patient_id
	    ,subject_id
	    from tm_wz.wt_subject_mbolomics_probeset
	    where trial_name = TrialId;
	else
	    insert into tm_wz.wt_subject_metabolomics_logs
			(probeset
			,intensity_value
			,assay_id
			,log_intensity
			,patient_id
			,subject_id
			)
	    select probeset
		   ,intensity_value
		   ,assay_id
		   ,log(log_base,cast(intensity_value as numeric))   -- wt_subject_mbolomics_probeset should only contain strictly positive intensities, otherwise throwing an error here is correct thing to do
		   ,patient_id
		   ,subject_id
	      from tm_wz.wt_subject_mbolomics_probeset
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
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Loaded data for trial in wt_subject_mirna_logs',rowCt,stepCt,'Done');

    execute('create index wt_subject_mbolomics_logs_i1 on tm_wz.wt_subject_metabolomics_logs (trial_name, probeset) tablespace "indx"');
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create index on tm_wz.wt_subject_mbolomics_logs_i1',0,stepCt,'Done');

    --	calculate mean_intensity, median_intensity, and stddev_intensity per experiment, probe
    begin
	insert into wt_subject_metabolomics_calcs
		    (trial_name
		    ,probeset
		    ,mean_intensity
		    ,median_intensity
		    ,stddev_intensity
		    )
	select d.trial_name
	       ,d.probeset
	       ,avg(log_intensity)
	       ,median(log_intensity)
	       ,coalesce(stddev(log_intensity),0)
	  from tm_wz.wt_subject_metabolomics_logs d
	 group by d.trial_name
		  ,d.probeset;
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
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate intensities for trial in tm_wz.wt_subject_metabolomics_calcs',rowCt,stepCt,'Done');

    -- calculate zscore
    begin
        insert into tm_wz.wt_subject_metabolomics_med
		    (probeset
		    ,intensity_value
		    ,log_intensity
		    ,assay_id
		    ,mean_intensity
		    ,stddev_intensity
		    ,median_intensity
		    ,zscore
		    ,patient_id
		    ,subject_id
		    )
	select d.probeset
	       ,d.intensity_value
	       ,d.log_intensity
	       ,d.assay_id
	       ,c.mean_intensity
	       ,c.stddev_intensity
	       ,c.median_intensity
	       ,(CASE WHEN stddev_intensity=0 THEN 0 ELSE (log_intensity - median_intensity ) / stddev_intensity END)
	       ,d.patient_id
	       ,d.subject_id
	  from tm_wz.wt_subject_metabolomics_logs d
	       ,tm_wz.wt_subject_metabolomics_calcs c
	 where trim(d.probeset) = c.probeset;
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
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate Z-Score for trial in wt_subject_metabolomics_med',rowCt,stepCt,'Done');

    begin
	sqlText := 'insert into ' || partitionName ||
	    '(partition_id, trial_source ,trial_name ,metabolite_annotation_id ' ||
	    ',assay_id ,subject_id ,raw_intensity ,log_intensity ,zscore ,patient_id) ' ||
	    'select ' || partitioniD::text || ', ''' || TrialId || '''' ||
	    ',''' || TrialId || ''',d.id ,m.assay_id ,m.subject_id ' ||
            ',m.intensity_value ,m.log_intensity ' ||
            ',CASE WHEN m.zscore < -2.5 THEN -2.5 WHEN m.zscore >  2.5 THEN  2.5 ELSE m.zscore END ' ||
            ',m.patient_id ' ||
	    'from tm_wz.wt_subject_metabolomics_med m, ' ||
            '(select distinct mp.source_cd,mp.platform From TM_LZ.LT_SRC_METABOLOMIC_MAP mp where mp.trial_name = ''' || TrialId || ''') as mpp ' ||
	    ', deapp.de_metabolite_annotation d ' ||
            'where trim(d.biochemical_name) = trim(m.probeset) ' ||
            'and d.gpl_id = mpp.platform ';
        raise notice 'sqlText= %', sqlText;
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
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial in de_subject_metabolomics_data',rowCt,stepCt,'Done');

    sqlText := ' create index ' || partitionIndx || '_idx1 on ' || partitionName || ' using btree (partition_id) tablespace indx';
    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx2 on ' || partitionName || ' using btree (assay_id) tablespace indx';
    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx3 on ' || partitionName || ' using btree (metabolite_annotation_id) tablespace indx';
    raise notice 'sqlText= %', sqlText;
    execute sqlText;
    sqlText := ' create index ' || partitionIndx || '_idx4 on ' || partitionName || ' using btree (assay_id, metabolite_annotation_id) tablespace indx';
    raise notice 'sqlText= %', sqlText;
    execute sqlText;

    ---Cleanup OVERALL JOB if this proc is being run standalone
    if newJobFlag = 1 then
	perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
    end if;

    return 1;
end;

$$;

