--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_ADD_SNP_BIOMARKER_NODES
--
CREATE OR REPLACE PROCEDURE TM_CZ.I2B2_ADD_SNP_BIOMARKER_NODES (
    trial_id 		VARCHAR2
    ,ont_path		varchar2
    ,currentJobID 	NUMBER := null
)

AS
    --	Adds SNP platform and sample type nodes into Biomarker Data ontology and adds rows into observation_fact for
    --	each subject/concept combination

    --	JEA@20110120	New
    --	JEA@@0111218	Remove hard-coded "Biomarker Data" node, use what's supplied in ont_path

    TrialID	varchar2(100);
    ontPath		varchar2(500);

    RootNode	VARCHAR2(300);
    pExists 	number;
    platformTitle	varchar2(200);
    tText		varchar2(1000);
    ontLevel	integer;
    nodeName	varchar2(200);

    --Audit variables
    newJobFlag INTEGER(1);
    databaseName VARCHAR(100);
    procedureName VARCHAR(100);
    jobID number(18,0);
    stepCt number(18,0);

    --	raise exception if platform not in de_gpl_info

    missing_GPL exception;

    --	cursor to add platform-level nodes, need to be inserted before de_subject_sample_mapping

    cursor addPlatform is
	select
	    distinct REGEXP_REPLACE(ont_path || '\' || g.title || '\' ,
				    '(\\){2,}', '\') as path
	    ,g.title
	  from deapp.de_subject_snp_dataset s
	       ,deapp.de_gpl_info g
	 where s.trial_name = TrialId
	   and nvl(s.platform_name,'GPL570') = g.platform
	   and upper(g.organism) = 'HOMO SAPIENS';

    --	cursor to add sample-level nodes

    cursor addSample is
	select distinct regexp_replace(ont_path || '\' || g.title || '\' ||
				       s.sample_type || '\',	'(\\){2,}', '\') as sample_path
			,s.sample_type as sample_name
	  from deapp.de_subject_snp_dataset s
	       ,deapp.de_gpl_info g
	 where s.trial_name = TrialId
	   and nvl(s.platform_name,'GPL570') = g.platform
	   and upper(g.organism) = 'HOMO SAPIENS'
	   and s.sample_type is not null;

BEGIN

    TrialID := upper(trial_id);
    ontPath := ont_path;

    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    SELECT sys_context('USERENV', 'CURRENT_SCHEMA') INTO databaseName FROM dual;
    procedureName := $$PLSQL_UNIT;

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    IF(jobID IS NULL or jobID < 1) THEN
	newJobFlag := 1; -- True
	tm_cz.cz_start_audit (procedureName, databaseName, jobID);
    END IF;

    stepCt := 0;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_add_snp_node',0,stepCt,'Done');
    stepCt := stepCt + 1;

    --	determine last node in ontPath

    select length(ontPath)-length(replace(ontPath,'\','')) into ontLevel from dual;
    select tm_cz.parse_nth_value(ontPath,ontLevel,'\') into nodeName from dual;

    --	add the high level \ node if it doesn't exist (first time loading data)

    select count(*)
      into pExists
      from i2b2metadata.i2b2
     where c_fullname = REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\');

    if pExists = 0 then
	tm_cz.i2b2_add_node(TrialId, REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\'), nodeName, jobID);
        stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Add node for ontPath',0,stepCt,'Done');
    end if;

    --	check if a node exists for the platform, if yes, then delete existing data, make sure all platforms in de_subject_snp_dataset have an
    --	entry in de_gpl_info, if not, raise exception

    select count(*) into pExists
      from deapp.de_subject_snp_dataset s
	   ,deapp.de_gpl_info g
     where s.trial_name = TrialId
       and nvl(s.platform_name,'GPL570') = g.platform(+)
       and  'HOMO SAPIENS' = upper(g.organism(+))
       and g.platform is null;

    if pExists > 0 then
	raise missing_GPL;
    end if;

    --	add SNP platform nodes

    for r_addPlatform in addPlatform Loop

	tm_cz.i2b2_delete_all_nodes(REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\') || r_addPlatform.title || '\', jobID);
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete existing SNP Platform for trial in I2B2METADATA i2b2',0,stepCt,'Done');

	tm_cz.i2b2_add_node(TrialId, r_addPlatform.path, r_addPlatform.title, jobId);
	tText := 'Added Platform: ' || r_addPlatform.path || '  Name: ' || r_addPlatform.title;
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,SQL%ROWCOUNT,stepCt,'Done');
    end loop;

    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Added SNP Platform nodes',0,stepCt,'Done');
    stepCt := stepCt + 1;
    commit;

    --	Insert the sample-level nodes

    for r_addSample in addSample Loop

	tm_cz.i2b2_add_node(TrialId, r_addSample.sample_path, r_addSample.sample_name, jobId);
	tText := 'Added Sample: ' || r_addSample.sample_path || '  Name: ' || r_addSample.sample_name;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;

    end loop;

    --	Insert records for patients into observation_fact

    insert into i2b2demodata.observation_fact (
	patient_num
	,concept_cd
	,modifier_cd
	,valtype_cd
	,tval_char
	,nval_num
	,sourcesystem_cd
	,import_date
	,valueflag_cd
	,provider_id
	,location_cd
	,units_cd
    )
    select p.patient_num
	   ,t.concept_cd
	   ,t.sourcesystem_cd
	   ,'T' -- Text data type
	   ,'E'  --Stands for Equals for Text Types
	   ,null	--	not numeric for Proteomics
	   ,t.sourcesystem_cd
	   ,sysdate
	   ,'@'
	   ,'@'
	   ,'@'
	   ,'' -- no units available
      from i2b2demodata.concept_dimension t
	   ,deapp.de_subject_snp_dataset p
	   ,deapp.de_gpl_info g
     where p.trial_name =  TrialId
       and nvl(p.platform_name,'GPL570') = g.platform
       and upper(g.organism) = 'HOMO SAPIENS'
       and t.concept_path = REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\') || g.title || '\' || p.sample_type || '\'
     group by p.patient_num
	      ,t.concept_cd
	      ,t.sourcesystem_cd;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
    stepCt := stepCt + 1;
    commit;

    --	update concept_cd in de_subject_snp_dataset

    update deapp.de_subject_snp_dataset d
       set concept_cd = (
	   select t.concept_cd
	     from deapp.de_subject_snp_dataset p
		  ,deapp.de_gpl_info g
		  ,i2b2demodata.concept_dimension t
	    where d.subject_snp_dataset_id = p.subject_snp_dataset_id
	      and nvl(p.platform_name,'GPL570') = g.platform
	      and upper(g.organism) = 'HOMO SAPIENS'
	      and t.concept_path = REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\') || g.title || '\' || p.sample_type || '\'
       )
     where d.trial_name = TrialId;

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update concept_cd in DEAPP de_subject_snp_dataset',SQL%ROWCOUNT,stepCt,'Done');
    commit;

    --	Update visual attributes for leaf active (default is folder)

    update i2b2metadata.i2b2 a
       set c_visualattributes = 'LA'
     where 1 = (select count(*)
		  from i2b2metadata.i2b2 b
		 where b.c_fullname like (a.c_fullname || '%'))
	   and a.c_fullname like REGEXP_REPLACE(ont_path || '\','(\\){2,}', '\') || '%';
    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update leaf active attribute for trial in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
    commit;

    --	fill in tree

    --	get top level for study, this will be used for fill-in and create_concept_counts
    --	if this fails, check to make sure the trialId is not a sourcesystem_cd at an higher level than the study

    select b.c_fullname into nodeName
      from i2b2metadata.i2b2 b
     where b.c_hlevel =
	   (select min(x.c_hlevel) from i2b2metadata.i2b2 x
	     where b.sourcesystem_cd = x.sourcesystem_cd)
       and ontPath like b.c_fullname || '%'
       and b.sourcesystem_cd = TrialId;

    tm_cz.i2b2_fill_in_tree(TrialID,REGEXP_REPLACE(nodeName || '\','(\\){2,}', '\'), jobID);
    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Fill in tree for Biomarker Data for trial',SQL%ROWCOUNT,stepCt,'Done');

    --Build concept Counts
    --Also marks any i2B2 records with no underlying data as Hidden, need to do at Biomarker level because there may be multiple platforms and patient count can vary

    tm_cz.i2b2_create_concept_counts(REGEXP_REPLACE(nodeName || '\','(\\){2,}', '\'),jobID );
    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create concept counts',0,stepCt,'Done');

    --Reload Security: Inserts one record for every I2B2 record into the security table

    tm_cz.i2b2_load_security_data(jobId);
    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Load security data',0,stepCt,'Done');

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'End i2b2_process_protein_data',0,stepCt,'Done');

    ---Cleanup OVERALL JOB if this proc is being run standalone
    IF newJobFlag = 1 THEN
	tm_cz.cz_end_audit (jobID, 'SUCCESS');
    END IF;

EXCEPTION

    WHEN missing_GPL then
    --	put message in log
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'One or more GPL platforms in de_subject_snp_dataset is not in de_gpl_info',0,stepCt,'Done');

    --End Proc
	tm_cz.cz_end_audit (jobID, 'FAIL');

    WHEN OTHERS THEN
	--Handle errors.
	tm_cz.cz_error_handler (jobID, procedureName);
    --End Proc
	tm_cz.cz_end_audit (jobID, 'FAIL');

END;
/
