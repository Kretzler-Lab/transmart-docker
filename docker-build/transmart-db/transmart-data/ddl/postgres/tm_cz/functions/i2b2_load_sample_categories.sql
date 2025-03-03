--
-- Name: i2b2_load_sample_categories(bigint); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_sample_categories(currentjobid bigint DEFAULT NULL::bigint) RETURNS void
    LANGUAGE plpgsql
AS $$
    declare

    --Audit variables
    newJobFlag numeric(1);
    databaseName varchar(100);
    procedureName varchar(100);
    jobID integer;
    stepCt integer;
    rowCt integer;

    --	JEA@20110916	New
    --	JEA@20120209	Remove insert of sample to patient_dimension

    --
    -- Copyright ? 2011 Recombinant Data Corp.
    --

begin

    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_load_sample_categories';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    if(coalesce(jobID::text, '') = '' or jobID < 1) then
	newJobFlag := 1; -- True
	perform tm_cz.cz_start_audit (procedureName, databaseName, jobID);
    end if;

    stepCt := 0;

    --	delete any data for study in sample_categories_extrnl from lz_src_sample_categories

    delete from tm_lz.lz_src_sample_categories
     where trial_cd in (select distinct trial_cd from tm_lz.lt_src_sample_categories);

    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Deleted existing study data in lz_src_sample_categories',rowCt,stepCt,'Done');
    commit;

    /*
	--	create records in patient_dimension for samples if they do not exist
	--	format of sourcesystem_cd:  trial:S:[site:]subject_cd:sample_cd
	--	if no sample_cd specified, then the patient_num of the trial:[site]:subject_cd should have already been created

	insert into i2b2demodata.patient_dimension
	( patient_num,
	sex_cd,
	age_in_years_num,
	race_cd,
	update_date,
	download_date,
	import_date,
	sourcesystem_cd
	)
	select i2b2demodata.seq_patient_num.nextval,
	'Unknown' as sex_cd,
	null::integer as age_in_years_num,
	null as race_cd,
	sysdate,
	sysdate,
	sysdate,
	regexp_replace(s.trial_cd || ':S:' || s.site_cd || ':' || s.subject_cd || ':' || s.sample_cd,
	'(:){2,}', ':')
	from (select distinct trial_cd
	,site_cd
	,subject_cd
	,sample_cd
	from tm_cz.sample_categories_extrnl s
	where s.sample_cd is not null
	and not exists
	(select 1 from i2b2demodata.patient_dimension x
	where x.sourcesystem_cd =
	regexp_replace(s.trial_cd || ':S:' || s.site_cd || ':' || s.subject_cd || ':' || s.sample_cd,
	'(:){2,}', ':'))
	) s;

	stepCt := stepCt + 1;
	get diagnostics rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Added new sample_cds for study in I2B2DEMODATA patient_dimension',rowCt,stepCt,'Done');
	commit;
     */

    --	Load data into lz_src_sample_categories table, joins to make sure study/trial exists and there's an entry in the patient_dimension

    insert into tm_lz.lz_src_sample_categories
		(trial_cd
		,site_cd
		,subject_cd
		,sample_cd
		,category_cd
		,category_value
		)
    select distinct s.trial_cd
		    ,s.site_cd
		    ,s.subject_cd
		    ,s.sample_cd
		    ,replace(s.category_cd,'"',null)
		    ,replace(s.category_value,'"',null)
      from tm_lz.lt_src_sample_categories s
     where replace(s.category_cd,'"',null) is not null
       and replace(s.category_value,'"',null) is not null
       and s.trial_cd in (select distinct x.sourcesystem_cd from i2b2metadata.i2b2 x)
	   ;

    stepCt := stepCt + 1;
    get diagnostics rowCt := ROW_COUNT;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted sample data in lz_src_sample_categories',rowCt,stepCt,'Done');
    commit;

    if newjobflag = 1
    then
	perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
	end if;

exception
    when others then
    --Handle errors.
	perform tm_cz.cz_error_handler(jobId, procedureName, SQLSTATE, SQLERRM);

    --End Proc
	perform tm_cz.cz_end_audit (jobID, 'FAIL');

end;

$$;

