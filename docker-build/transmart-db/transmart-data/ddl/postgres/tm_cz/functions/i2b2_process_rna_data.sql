--
-- Name: i2b2_process_rna_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_process_rna_data(trial_id character varying, top_node character varying, data_type character varying DEFAULT 'R'::character varying, source_code character varying DEFAULT 'STD'::character varying, log_base numeric DEFAULT 2, secure_study character varying DEFAULT NULL::character varying, currentjobid numeric DEFAULT 0) RETURNS numeric
    LANGUAGE plpgsql
AS $$
    declare

    /*************************************************************************
     * This stored procedure is for ETL to load RNA sequencing
     * Date:10/23/2013
     ******************************************************************/
    --	***  NOTE ***
    --	The input file columns are mapped to the following table columns.
    --	This is a change from the swapping in tranSMART up to 16.3
    --
    --		tissue_type	=>	tissue_type
    --		attribute_1	=>	sample_type
    --		attribute_2	=>	timepoint

    TrialID		varchar(100);
    RootNode		varchar(2000);
    root_level		integer;
    topNode		varchar(2000);
    topLevel		integer;
    tPath		varchar(2000);
    study_name		varchar(100);
    sourceCd		varchar(50);
    secureStudy		varchar(1);

    dataType		varchar(10);
    sqlText		varchar(1000);
    tText		varchar(1000);
    gplTitle		varchar(1000);
    pExists		bigint;
    partTbl   		bigint;
    sampleCt		bigint;
    idxExists 		bigint;
    logBase		bigint;
    pCount		integer;
    sCount		integer;
    tablespaceName	varchar(200);
    v_bio_experiment_id	bigint;
    partitionId		numeric(18,0);
    partitionName	varchar(100);
    partitionIndx	varchar(100);

    --Audit variables
    newJobFlag		integer;
    databaseName	varchar(100);
    procedureName	varchar(100);
    jobId		bigint;
    stepCt		bigint;
    rowCt		numeric(18,0);
    errorNumber		character varying;
    errorMessage	character varying;
    rtnCd 		integer;
    tExplain 		text;

    addNodes CURSOR FOR
			SELECT distinct t.leaf_node
			,t.node_name
			from  tm_wz.wt_rna_nodes t
			where not exists
			(select 1 from i2b2metadata.i2b2 x
			  where t.leaf_node = x.c_fullname);


    --	cursor to define the path for delete_one_node  this will delete any nodes that are hidden after i2b2_create_concept_counts

    delNodes CURSOR FOR
			SELECT distinct c_fullname
			from  i2b2metadata.i2b2
			where c_fullname like topNode || '%'
			and substring(c_visualattributes from 2 for 1) = 'H';

    uploadI2b2 CURSOR FOR
			  select category_cd,display_value,display_label,display_unit from
			  tm_lz.lt_src_rna_display_mapping;

begin
    rtnCd := 1;

    TrialID := upper(trial_id);
    secureStudy := upper(secure_study);

    if (secureStudy not in ('Y','N') ) then
	secureStudy := 'Y';
    end if;

    topNode := REGEXP_REPLACE('\' || top_node || '\','(\\){2,}', '\','g');
    select length(topNode)-length(replace(topNode,'\','')) into topLevel ;

    if coalesce(data_type::text, '') = '' then
	dataType := 'R';
    else
	if data_type in ('R','T','L') then
	    dataType := data_type;
	else
	    dataType := 'R';
	end if;
    end if;

    logBase := log_base;
    sourceCd := upper(coalesce(source_code,'STD'));

    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobId := currentJobID;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_process_rna_data';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    if(coalesce(jobId::text, '') = '' or jobId < 1) then
	newJobFlag := 1; -- True
	select tm_cz.cz_start_audit (procedureName, databaseName, jobId) into jobId;
    end if;

    stepCt := 0;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_process_rna_data',0,stepCt,'Done');

    --	Get count of records in lt_src_rna_subj_samp_map

    select count(*) into sCount
      from tm_lz.lt_src_rna_subj_samp_map;

    --	check if all subject_sample map records have a platform, If not, abort run

    select count(*) into pCount
      from tm_lz.lt_src_rna_subj_samp_map
     where coalesce(platform::text, '') = '';

    if pCount > 0 then
	perform tm_cz.cz_write_audit(jobId,databasename,procedurename,'Platform data missing from one or more subject_sample mapping records',1,stepCt,'ERROR');
	perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return 161;
    end if;

    --	check if all subject_sample map records have a tissue_type, If not, abort run

    select count(*) into pCount
      from tm_lz.lt_src_rna_subj_samp_map
     where coalesce(tissue_type::text, '') = '';

    if pCount > 0 then
	perform tm_cz.cz_write_audit(jobId,databasename,procedurename,'Tissue Type data missing from one or more subject_sample mapping records',1,stepCt,'ERROR');
	perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return 162;
    end if;

    --	check if there are multiple platforms, if yes, then platform must be supplied in lt_src_rna_data

    select count(*) into pCount
      from (select sample_cd
	      from tm_lz.lt_src_rna_subj_samp_map
	     group by sample_cd
	    having count(distinct platform) > 1) as x;

    if pCount > 0 then
	perform tm_cz.cz_write_audit(jobId,databasename,procedurename,'Multiple platforms for sample_cd in lt_src_rna_subj_samp_map',pCount,stepCt,'ERROR');
	perform tm_cz.cz_error_handler(jobId, procedureName, errorNumber, errorMessage);
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return 164;
    end if;

    -- Get root_node from topNode

    select tm_cz.parse_nth_value(topNode, 2, '\') into RootNode ;

    select count(*) into pExists
      from i2b2metadata.table_access
     where c_name = rootNode;

    if pExists = 0 then
	perform tm_cz.i2b2_add_root_node(rootNode, jobId);
    end if;

    select c_hlevel into root_level
      from i2b2metadata.i2b2
     where c_name = RootNode;

    -- Get study name from topNode

    select tm_cz.parse_nth_value(topNode, topLevel, '\') into study_name ;

    --	Add any upper level nodes as needed

    tPath := REGEXP_REPLACE(replace(top_node,study_name,''),'(\\){2,}', '\', 'g');
    select length(tPath) - length(replace(tPath,'\','')) into pCount ;

    if pCount > 2 then
	select tm_cz.i2b2_fill_in_tree(null, tPath, jobId) into rtnCd;
	if(rtnCd <> 1) then
	    stepCt := stepCt + 1;
            tText := 'Failed to fill in tree '|| tPath;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    	end if;
    end if;

    --	uppercase study_id in lt_src_rna_subj_samp_map in case curator forgot
    begin
	update tm_lz.lt_src_rna_subj_samp_map
	   set trial_name=upper(trial_name);
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	-- perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Uppercase trial_name in lt_src_rna_subj_samp_map',rowCt,stepCt,'Done');

    select tm_cz.load_tm_trial_nodes(TrialID,topNode,jobId,false) into rtnCd;

    if(rtnCd <> 1) then
       stepCt := stepCt + 1;
       perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Failed to load tm_trial_nodes',0,stepCt,'Message');
       perform tm_cz.cz_end_audit (jobId, 'FAIL');
       return -16;
    end if;

    --	create records in patient_dimension for subject_ids if they do not exist
    --	format of sourcesystem_cd:  trial:[site:]subject_cd

    begin
	insert into i2b2demodata.patient_dimension (
	    patient_num
	    ,sex_cd
	    ,age_in_years_num
	    ,race_cd
	    ,update_date
	    ,download_date
	    ,import_date
	    ,sourcesystem_cd
	)
	select nextval('i2b2demodata.seq_patient_num')
	       ,x.sex_cd
	       ,x.age_in_years_num
	       ,x.race_cd
	       ,LOCALTIMESTAMP
	       ,LOCALTIMESTAMP
	       ,LOCALTIMESTAMP
	       ,x.sourcesystem_cd
	  from (select distinct 'Unknown' as sex_cd
				,null::integer as age_in_years_num
				,null as race_cd
				,regexp_replace(TrialId || ':' || coalesce(s.site_id,'') || ':' || s.subject_id,'(:){2,}', ':', 'g') as sourcesystem_cd
		  from tm_lz.lt_src_rna_subj_samp_map s
		 where (s.subject_id IS NOT NULL AND s.subject_id::text <> '')
		   and s.trial_name = TrialID
		   and s.source_cd = sourceCD
		   and not exists
		       (select 1 from i2b2demodata.patient_dimension x
			 where x.sourcesystem_cd =
			       regexp_replace(TrialID || ':' || coalesce(s.site_id, '') || ':' || s.subject_id,'(:){2,}', ':'))
	  ) as x;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert subjects to patient_dimension',rowCt,stepCt,'Done');

    perform tm_cz.i2b2_create_security_for_trial(TrialId, secureStudy, topLevel, jobId);

    --	Delete existing observation_fact data, will be repopulated
    begin
	delete from i2b2demodata.observation_fact obf
	 where obf.concept_cd in
	       (select distinct x.concept_code
		  from deapp.de_subject_sample_mapping x
		 where x.trial_name = TrialId
		   and coalesce(x.source_cd,'STD') = sourceCD
		   and x.platform = 'RNASEQCOG');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete data from observation_fact',rowCt,stepCt,'Done');

    --	truncate tmp node table

    execute('truncate table tm_wz.wt_rna_nodes');

    execute('truncate table tm_wz.wt_rna_node_values');

    begin
	insert into tm_wz.wt_rna_node_values (
	    category_cd
	    ,platform
	    ,tissue_type
	    ,attribute_1
	    ,attribute_2
	    ,title
	)
	select
	    distinct a.category_cd
	    ,coalesce(a.platform,'HUMAN_GENES')
	    ,coalesce(a.tissue_type,'Unspecified Tissue Type')
	    ,a.attribute_1
	    ,a.attribute_2
	    ,g.title
	  from tm_lz.lt_src_rna_subj_samp_map a
	       ,deapp.de_gpl_info g
	 where a.trial_name = TrialID
	   and a.source_cd = sourceCD
	   and coalesce(a.platform,'HUMAN_GENES') = g.platform;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert node values into DEAPP wt_rna_nodes',rowCt,stepCt,'Done');

    begin
	insert into tm_wz.wt_rna_nodes
		    (leaf_node
		    ,category_cd
		    ,platform
		    ,tissue_type
		    ,attribute_1
		    ,attribute_2
		    ,node_type
		    )
	select
	    distinct topNode || regexp_replace(replace(replace(replace(replace(replace(replace(
		category_cd,'PLATFORM',title),
		'ATTR1',coalesce(attribute_1,'')),
		'ATTR2',coalesce(attribute_2,'')),
		'TISSUETYPE',coalesce(tissue_type,'')),
		'+','\'),
		'_',' ') || '\', '(\\){2,}', '\', 'g')
	    ,category_cd
	    ,platform as platform
	    ,tissue_type
	    ,attribute_1 as attribute_1
	    ,attribute_2 as attribute_2
	    ,'LEAF'
	  from  tm_wz.wt_rna_node_values;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create leaf nodes in DEAPP wt_rna_nodes',rowCt,stepCt,'Done');

    if rowCt < 1 then
	perform tm_cz.cz_write_audit(jobId,databasename,procedurename,'Failed to load records in wt_rna_nodes - check platform(s)',0,stepCt,'ERROR');
	perform tm_cz.cz_end_audit (jobId,'FAIL');
	return 161;
    end if;

--	insert for platform node so platform concept can be populated
    begin
	insert into tm_wz.wt_rna_nodes
		    (leaf_node
		    ,category_cd
		    ,platform
		    ,tissue_type
		    ,attribute_1
		    ,attribute_2
		    ,node_type
		    )
	select
	    distinct topNode || regexp_replace(replace(replace(replace(replace(replace(replace(
		substr(category_cd,1,tm_cz.instr(category_cd,'PLATFORM')+8),
		'PLATFORM',title),
		'ATTR1',coalesce(attribute_1,'')),
		'ATTR2',coalesce(attribute_2,'')),
		'TISSUETYPE',coalesce(tissue_type,'')),
		'+', '\'),
		'_', ' ') || '\', '(\\){2,}', '\', 'g')
	    ,substr(category_cd,1,tm_cz.instr(category_cd,'PLATFORM')+8)
	    ,platform as platform
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'PLATFORM')+8),'TISSUETYPE') > 1 then tissue_type else null end as tissue_type
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'PLATFORM')+8),'ATTR1') > 1 then attribute_1 else null end as attribute_1
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'PLATFORM')+8),'ATTR2') > 1 then attribute_2 else null end as attribute_2
	    ,'PLATFORM'
	  from  tm_wz.wt_rna_node_values
	 where category_cd like '%PLATFORM%'
	   and (platform is not null
	       and platform::text <> '');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create platform nodes in wt_rna_nodes',rowCt,stepCt,'Done');

    --	insert for ATTR1 node so ATTR1 concept can be populated in sample_type_cd
    begin
	insert into tm_wz.wt_rna_nodes (
	    leaf_node
	    ,category_cd
	    ,platform
	    ,tissue_type
	    ,attribute_1
	    ,attribute_2
	    ,node_type
	)
	select
	    distinct topNode || regexp_replace(replace(replace(replace(replace(replace(replace(
		substr(category_cd,1,tm_cz.instr(category_cd,'ATTR1')+5),
		'PLATFORM',title),
		'ATTR1',coalesce(attribute_1,'')),
		'ATTR2',coalesce(attribute_2,'')),
		'TISSUETYPE',coalesce(tissue_type,'')),
		'+', '\'),
		'_', ' ') || '\', '(\\){2,}', '\', 'g')
	    ,substr(category_cd,1,tm_cz.instr(category_cd,'ATTR1')+5)
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR1')+5),'PLATFORM') > 1 then platform else null end as platform
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR1')+5),'TISSUETYPE') > 1 then tissue_type else null end as tissue_type
	    ,attribute_1 as attribute_1
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR1')+5),'ATTR2') > 1 then attribute_2 else null end as attribute_2
	    ,'ATTR1'
	  from  tm_wz.wt_rna_node_values
	 where category_cd like '%ATTR1%'
	   and (attribute_1 is NOT NULL
	       and attribute_1::text <> '');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create ATTR1 nodes in wt_rna_nodes',rowCt,stepCt,'Done');

    --	insert for ATTR2 node so ATTR2 concept can be populated in timepoint_cd
    begin
	insert into tm_wz.wt_rna_nodes
		    (leaf_node
		    ,category_cd
		    ,platform
		    ,tissue_type
		    ,attribute_1
		    ,attribute_2
		    ,node_type
		    )
	select
	    distinct topNode || regexp_replace(replace(replace(replace(replace(replace(replace(
		substr(category_cd,1,tm_cz.instr(category_cd,'ATTR2')+5),
		'PLATFORM',title),
		'ATTR1',coalesce(attribute_1,'')),
		'ATTR2',coalesce(attribute_2,'')),
		'TISSUETYPE',coalesce(tissue_type,'')),
		'+', '\'), '_', ' ') || '\', '(\\){2,}', '\', 'g')
	    ,substr(category_cd,1,tm_cz.instr(category_cd,'ATTR2')+5)
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR2')+5),'PLATFORM') > 1 then platform else null end as platform
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR2')+5),'TISSUETYPE') > 1 then tissue_type else null end as tissue_type
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'ATTR2')+5),'ATTR1') > 1 then attribute_1 else null end as attribute_1
	    ,attribute_2 as attribute_2
	    ,'ATTR2'
	  from  tm_wz.wt_rna_node_values
	 where category_cd like '%ATTR2%'
	   and (attribute_2 is NOT NULL
		and attribute_2::text <> '');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create ATTR2 nodes in wt_rna_nodes',rowCt,stepCt,'Done');

    --	insert for tissue_type node so tissue_type_cd can be populated
    begin
	insert into tm_wz.wt_rna_nodes (
	    leaf_node
	    ,category_cd
	    ,platform
	    ,tissue_type
	    ,attribute_1
	    ,attribute_2
	    ,node_type
	)
	select
	    distinct topNode || regexp_replace(replace(replace(replace(replace(replace(replace(
	    substr(category_cd,1,tm_cz.instr(category_cd,'TISSUETYPE')+10),
	    'PLATFORM',title),
	    'ATTR1',coalesce(attribute_1,'')),
	    'ATTR2',coalesce(attribute_2,'')),
	    'TISSUETYPE',coalesce(tissue_type,'')),
	    '+', '\'),
	    '_', ' ') || '\', '(\\){2,}', '\', 'g')
	    ,substr(category_cd,1,tm_cz.instr(category_cd,'TISSUETYPE')+10)
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'TISSUETYPE')+10),'PLATFORM') > 1 then platform else null end as platform
	    ,tissue_type as tissue_type
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'TISSUETYPE')+10),'ATTR1') > 1 then attribute_1 else null end as attribute_1
	    ,case when tm_cz.instr(substr(category_cd,1,tm_cz.instr(category_cd,'TISSUETYPE')+10),'ATTR2') > 1 then attribute_2 else null end as attribute_2
	    ,'TISSUETYPE'
	  from  tm_wz.wt_rna_node_values
	 where category_cd like '%TISSUETYPE%'
	   and (tissue_type is not null
	       and tissue_type::text <> '');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create TISSUETYPE nodes in wt_rna_nodes',rowCt,stepCt,'Done');

    begin
	update tm_wz.wt_rna_nodes
	   set node_name=tm_cz.parse_nth_value(leaf_node,length(leaf_node)-length(replace(leaf_node,'\','')),'\');
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated node_name in wt_rna_nodes',rowCt,stepCt,'Done');

    --	add leaf nodes for RNA_sequencing data  The cursor will only add nodes that do not already exist.

    for r_addNodes in addNodes loop

	--Add nodes for all types (ALSO DELETES EXISTING NODE)
	begin
	    select tm_cz.i2b2_add_node(TrialID, r_addNodes.leaf_node, r_addNodes.node_name, jobId) into rtnCd;
	    if(rtnCd <> 1) then
		stepCt := stepCt + 1;
            	tText := 'Failed to add leaf node '|| r_addNodes.leaf_node;
	    	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,0,stepCt,'Message');
	    	perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    	return -16;
    	    end if;
	    get diagnostics rowCt := ROW_COUNT;
	exception
	    when others then
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
	    --Handle errors.
		perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
		perform tm_cz.cz_end_audit (jobId, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	tText := 'Added Leaf Node: ' || r_addNodes.leaf_node || '  Name: ' || r_addNodes.node_name;

	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,rowCt,stepCt,'Done');

	select tm_cz.i2b2_fill_in_tree(TrialId, r_addNodes.leaf_node, jobId) into rtnCd;
	if(rtnCd <> 1) then
	    stepCt := stepCt + 1;
            tText := 'Failed to fill in tree '|| r_addNodes.leaf_node;
	    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    	end if;

    end loop;

    --	update concept_cd for nodes, this is done to make the next insert easier
    begin
	update tm_wz.wt_rna_nodes t
	   set concept_cd=(select c.concept_cd from i2b2demodata.concept_dimension c
	                    where c.concept_path = t.leaf_node
	   )
	 where exists
               (select 1 from i2b2demodata.concept_dimension x
	         where x.concept_path = t.leaf_node
	       )
	       and coalesce(t.concept_cd::text, '') = '';
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update wt_rna_nodes with newly created concept_cds',rowCt,stepCt,'Done');

    select nextval('deapp.seq_rna_partition_id') into partitionId;

    partitionName := 'deapp.de_subject_rna_data_' || partitionId::text;
    partitionIndx := 'de_subject_rna_data_' || partitionId::text;

    --Load the DE_SUBJECT_SAMPLE_MAPPING from wt_subject_RNA_sequencing_data

    --PATIENT_ID      = PATIENT_ID (SAME AS ID ON THE PATIENT_DIMENSION)
    --SITE_ID         = site_id
    --SUBJECT_ID      = subject_id
    --SUBJECT_TYPE    = NULL
    --CONCEPT_CODE    = from LEAF records in wt_rna_nodes
    --SAMPLE_TYPE    	= attribute_1
    --SAMPLE_TYPE_CD  = concept_cd from ATTR1 records in wt_rna_nodes
    --TRIAL_NAME      = TRIAL_NAME
    --TIMEPOINT		= attribute_2
    --TIMEPOINT_CD	= concept_cd from ATTR2 records in wt_rna_nodes
    --TISSUE_TYPE     = TISSUE_TYPE
    --TISSUE_TYPE_CD  = concept_cd from TISSUETYPE records in wt_rna_nodes
    --PLATFORM        = RNASEQCOG - this is required by ui code
    --PLATFORM_CD     = concept_cd from PLATFORM records in wt_rna_nodes
    --DATA_UID		= concatenation of concept_cd-patient_num
    --GPL_ID			= platform from wt_subject_rna_data
    --CATEGORY_CD		= category_cd that generated ontology
    --SAMPLE_ID		= id of sample (trial:S:[site_id]:subject_id:sample_cd) from patient_dimension, may be the same as patient_num
    --SAMPLE_CD		= sample_cd
    --SOURCE_CD		= sourceCd

    --ASSAY_ID        = generated by trigger

    begin
	insert into deapp.de_subject_sample_mapping(
	    partition_id
	    ,patient_id
	    ,site_id
	    ,subject_id
	    ,subject_type
	    ,concept_code
	    ,assay_id
	    ,sample_type
	    ,sample_type_cd
	    ,trial_name
	    ,timepoint
	    ,timepoint_cd
	    ,tissue_type
	    ,tissue_type_cd
	    ,platform
	    ,platform_cd
	    ,data_uid
	    ,gpl_id
	    ,sample_id
	    ,sample_cd
	    ,category_cd
	    ,source_cd
	    ,omic_source_study
	    ,omic_patient_id
	)
	select partitionId
	       ,t.patient_id
	       ,t.site_id
	       ,t.subject_id
	       ,t.subject_type
	       ,t.concept_code
	       ,nextval('deapp.seq_assay_id')
	       ,t.sample_type
	       ,t.sample_type_cd
	       ,t.trial_name
	       ,t.timepoint
	       ,t.timepoint_cd
	       ,t.tissue_type
	       ,t.tissue_type_cd
	       ,t.platform
	       ,t.platform_cd
	       ,t.data_uid
	       ,t.gpl_id
	       ,t.sample_id
	       ,t.sample_cd
	       ,t.category_cd
	       ,t.source_cd
	       ,t.omic_source_study
	       ,t.omic_patient_id
	  from (select
		    distinct b.patient_num as patient_id
		    ,a.site_id
		    ,a.subject_id
		    ,null as subject_type
		    ,ln.concept_cd as concept_code
		    ,a.tissue_type as tissue_type
		    ,ttp.concept_cd as tissue_type_cd
		    ,a.trial_name
		    ,a.attribute_2 as timepoint
		    ,a2.concept_cd as timepoint_cd
		    ,a.attribute_1 as sample_type
		    ,a1.concept_cd as sample_type_cd
		    ,'RNASEQCOG' as platform
		    ,pn.concept_cd as platform_cd
		    ,ln.concept_cd || '-' || b.patient_num::text as data_uid
		    ,a.platform as gpl_id
		    ,coalesce(sid.patient_num,b.patient_num) as sample_id
		    ,a.sample_cd
		    ,coalesce(a.category_cd,'Biomarker_Data+RNAseq+PLATFORM+ATTR1+ATTR2+TISSUETYPE') as category_cd
		    ,a.source_cd
		    ,TrialId as omic_source_study
		    ,b.patient_num as omic_patient_id
		  from tm_lz.lt_src_rna_subj_samp_map a
		    --Joining to Pat_dim to ensure the IDs match. If not I2B2 won't work.
			   inner join i2b2demodata.patient_dimension b
				   on regexp_replace(TrialID || ':' || coalesce(a.site_id,'') || ':' || a.subject_id,'(:){2,}', ':', 'g') = b.sourcesystem_cd
			   inner join tm_wz.wt_rna_nodes ln
				   on  a.platform = ln.platform
				   and a.category_cd = ln.category_cd
				   and coalesce(a.tissue_type,'@') = coalesce(ln.tissue_type,'@')
				   and coalesce(a.attribute_1,'@') = coalesce(ln.attribute_1,'@')
				   and coalesce(a.attribute_2,'@') = coalesce(ln.attribute_2,'@')
				   and ln.node_type = 'LEAF'
			   left outer join tm_wz.wt_rna_nodes pn
					      on a.platform = pn.platform
					      and a.category_cd like pn.category_cd || '%'
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'PLATFORM')+8),'TISSUETYPE') > 1 then a.tissue_type else '@' end = coalesce(pn.tissue_type,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'PLATFORM')+8),'ATTR1') > 1 then a.attribute_1 else '@' end = coalesce(pn.attribute_1,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'PLATFORM')+8),'ATTR2') > 1 then a.attribute_2 else '@' end = coalesce(pn.attribute_2,'@')
					      and pn.node_type = 'PLATFORM'
			   left outer join tm_wz.wt_rna_nodes ttp
					      on a.tissue_type = ttp.tissue_type
					      and a.category_cd like ttp.category_cd || '%'
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'TISSUETYPE')+10),'PLATFORM') > 1 then a.platform else '@' end = coalesce(ttp.platform,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'TISSUETYPE')+10),'ATTR1') > 1 then a.attribute_1 else '@' end = coalesce(ttp.attribute_1,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'TISSUETYPE')+10),'ATTR2') > 1 then a.attribute_2 else '@' end = coalesce(ttp.attribute_2,'@')
					      and ttp.node_type = 'TISSUETYPE'
			   left outer join tm_wz.wt_rna_nodes a1
					      on a.attribute_1 = a1.attribute_1
					      and a.category_cd like a1.category_cd || '%'
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR1')+5),'PLATFORM') > 1 then a.platform else '@' end = coalesce(a1.platform,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR1')+5),'TISSUETYPE') > 1 then a.tissue_type else '@' end = coalesce(a1.tissue_type,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR1')+5),'ATTR2') > 1 then a.attribute_2 else '@' end = coalesce(a1.attribute_2,'@')
					      and a1.node_type = 'ATTR1'
			   left outer join tm_wz.wt_rna_nodes a2
					      on a.attribute_2 = a2.attribute_2
					      and a.category_cd like a2.category_cd || '%'
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR2')+5),'PLATFORM') > 1 then a.platform else '@' end = coalesce(a2.platform,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR2')+5),'TISSUETYPE') > 1 then a.tissue_type else '@' end = coalesce(a2.tissue_type,'@')
					      and case when tm_cz.instr(substr(a.category_cd,1,tm_cz.instr(a.category_cd,'ATTR2')+5),'ATTR1') > 1 then a.attribute_1 else '@' end = coalesce(a2.attribute_1,'@')
					      and a2.node_type = 'ATTR2'
			   left outer join i2b2demodata.patient_dimension sid --mrna expression used inner join here
					      on regexp_replace(TrialID || ':' || coalesce(a.site_id,'') || ':' || a.subject_id,'(:){2,}', ':','g') = sid.sourcesystem_cd
		 where a.trial_name = TrialID
		   and a.source_cd = sourceCD
		   and ln.concept_cd IS NOT NULL
		  and not exists
			  (select 1 from deapp.de_subject_sample_mapping x
			   where a.trial_name = x.trial_name
			     and coalesce(a.source_cd,'STD') = x.source_cd
				 and x.platform = 'RNASEQCOG'
				 and coalesce(a.site_id,'') = coalesce(x.site_id,'')
				 and a.subject_id = x.subject_id
				 and a.sample_cd = x.sample_cd
				 )) t;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP de_subject_sample_mapping',rowCt,stepCt,'Done');

    --	Insert records for patients and samples into observation_fact
    begin
	insert into i2b2demodata.observation_fact (
	    patient_num
	    ,concept_cd
	    ,modifier_cd
	    ,valtype_cd
	    ,tval_char
	    ,sourcesystem_cd
	    ,start_date
	    ,import_date
	    ,valueflag_cd
	    ,provider_id
	    ,location_cd
	    ,units_cd
	    ,instance_num
	)
	select
	    distinct m.patient_id
	    ,m.concept_code
	    ,'@'
	    ,'T' -- Text data type
	    ,'E'  --Stands for Equals for Text Types
	    ,m.trial_name
	    ,'infinity'::timestamp
	    ,LOCALTIMESTAMP
	    ,'@'
	    ,'@'
	    ,'@'
	    ,'' -- no units available
	    ,1
	  from  deapp.de_subject_sample_mapping m
	 where m.trial_name = TrialID
	   and m.source_cd = sourceCD
	   and m.platform = 'RNASEQCOG';
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert patient facts into I2B2DEMODATA observation_fact',rowCt,stepCt,'Done');

    --	Insert sample facts
    begin
	insert into i2b2demodata.observation_fact (
	    patient_num
	    ,concept_cd
	    ,modifier_cd
	    ,valtype_cd
	    ,tval_char
	    ,sourcesystem_cd
	    ,start_date
	    ,import_date
	    ,valueflag_cd
	    ,provider_id
	    ,location_cd
	    ,units_cd
	    ,instance_num
	)
	select
	    distinct m.sample_id
	    ,m.concept_code
	    ,m.trial_name
	    ,'T' -- Text data type
	    ,'E'  --Stands for Equals for Text Types
	    ,m.trial_name
	    ,'infinity'::timestamp
	    ,LOCALTIMESTAMP
	    ,'@'
	    ,'@'
	    ,'@'
	    ,'' -- no units available
	    ,1
	  from  deapp.de_subject_sample_mapping m
	 where m.trial_name = TrialID
	   and m.source_cd = sourceCd
	   and m.platform = 'RNASEQCOG'
	   and m.patient_id != m.sample_id;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert sample facts into I2B2DEMODATA observation_fact',rowCt,stepCt,'Done');

    --Update I2b2 for correct data type

    begin
	update i2b2metadata.i2b2 t
	   set c_columndatatype = 'T'
	       , c_metadataxml = null
	       , c_visualattributes='FA'
	 where t.c_basecode in (select distinct x.concept_cd from tm_wz.wt_rna_nodes x);
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Initialize data_type and xml in i2b2',rowCt,stepCt,'Done');

    ---- update c_metadataxml in i2b2
    begin
	for ul in uploadI2b2 loop
	    update i2b2metadata.i2b2 n
	       SET c_columndatatype = 'T',
		--Static XML String
		   c_metadataxml =  ('<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis>'||
				     (select xmlelement(name "SeriesMeta",xmlforest(m.display_value as "Value",m.display_unit as "Unit",m.display_label as "DisplayName")) as hi
					from tm_lz.lt_src_rna_display_mapping m
				       where m.category_cd=ul.category_cd)||'</ValueMetadata>')
	     where n.c_fullname=
		   (select leaf_node
		      from tm_wz.wt_rna_nodes
		     where category_cd=ul.category_cd
		       and leaf_node=n.c_fullname);
        end loop;
        get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update c_columndatatype and c_metadataxml for numeric data types in I2B2METADATA i2b2',rowCt,stepCt,'Done');

    --UPDATE VISUAL ATTRIBUTES for Leaf Active (Default is folder)
    begin
	update i2b2metadata.i2b2 a
	   set c_visualattributes = 'LAH'
	 where a.c_basecode in (select distinct x.concept_code from deapp.de_subject_sample_mapping x
				 where x.trial_name = TrialId
				   and x.platform = 'RNASEQCOG'
				   and x.concept_code is not null);
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update visual attributes for leaf nodes in I2B2METADATA i2b2',rowCt,stepCt,'Done');

    begin
        update i2b2metadata.i2b2 a
	   set c_visualattributes='FAS'
         where a.c_fullname = substr(topNode,1,tm_cz.instr(topNode,'\',1,3));
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update visual attributes for study node in I2B2METADATA i2b2',rowCt,stepCt,'Done');

    if (dataType = 'R') then
        begin
            delete from tm_lz.lt_src_rna_data
	          where intensity_value::double precision < 0.0; -- allow zero, handle in zscore function
	    get diagnostics rowCt := ROW_COUNT;
            exception
	        when others then
	            errorNumber := SQLSTATE;
	            errorMessage := SQLERRM;
	        --Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
        end;
        stepCt := stepCt + 1;
        perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove unusable negative intensity_value from lt_src_rna_data for dataType R',rowCt,stepCt,'Done');
        begin
            update tm_lz.lt_src_rna_data
	          set intensity_value = '0.001' where intensity_value::double precision = 0.0; -- update zero as small number with a valid log
	    get diagnostics rowCt := ROW_COUNT;
            exception
	        when others then
	            errorNumber := SQLSTATE;
	            errorMessage := SQLERRM;
	        --Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
        end;
        stepCt := stepCt + 1;
        perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update zero intensity_value from lt_src_rna_data for dataType R',rowCt,stepCt,'Done');
    end if;

    begin
	insert into tm_cz.probeset_deapp
		    (probeset
		    ,platform
		    )
	select distinct s.probeset
			,m.platform
          from tm_lz.lt_src_rna_data s
               ,tm_lz.lt_src_rna_subj_samp_map m
         where s.trial_name=m.trial_name
           and s.expr_id=m.sample_cd
	   and not exists
	       (select 1 from tm_cz.probeset_deapp x
		 where m.platform = x.platform
		   and s.probeset = x.probeset);
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert new probesets into probeset_deapp',rowCt,stepCt,'Done');

    --Build concept Counts
    --Also marks any i2B2 records with no underlying data as Hidden, need to do at Trial level because there may be multiple platform and there is no longer
    -- a unique top-level node for RNA_sequencing data
    begin
	perform tm_cz.i2b2_create_concept_counts(TrialID, topNode ,jobId );
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create concept counts',rowCt,stepCt,'Done');

    --	delete each node that is hidden
    for r_delNodes in delNodes loop

	--	deletes hidden nodes for a trial one at a time
	begin
	    select tm_cz.i2b2_delete_1_node(r_delNodes.c_fullname,jobId) into rtnCd;
	    if(rtnCd <> 1) then
	        tText := 'Failed to delete node '|| r_delNodes.c_fullname;
	    	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,0,stepCt,'Message');
	    	perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    	return -16;
    	    end if;
	    get diagnostics rowCt := ROW_COUNT;
	exception
	    when others then
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
	    --Handle errors.
		perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
		perform tm_cz.cz_end_audit (jobId, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	tText := 'Deleted node: ' || r_delNodes.c_fullname;

	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,tText,rowCt,stepCt,'Done');

    end loop;

    --Reload Security: Inserts one record for every I2B2 record into the security table
    begin
	select tm_cz.i2b2_load_security_data(TrialID,jobId) into rtnCd;
    if(rtnCd <> 1) then
        stepCt := stepCt + 1;
        perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Failed to load security data',0,stepCt,'Message');
	perform tm_cz.cz_end_audit (jobId, 'FAIL');
	return -16;
    end if;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	--Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Load security data',rowCt,stepCt,'Done');

    --	tag data with probeset_id from reference.probeset_deapp

    EXECUTE ('truncate table tm_wz.wt_subject_rna_probeset');

    --	note: assay_id represents a unique subject/site/sample
    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wt_subject_rna_probeset
		    (probeset
		     ,intensity_value
		     ,assay_id
		     ,patient_id
		     ,trial_name
		    ) select md.probeset
			     ,avg(md.intensity_value::double precision)
			     ,sd.assay_id
			     ,sd.patient_id
			     ,TrialId as trial_name
			from tm_lz.lt_src_rna_data md
			inner join deapp.de_subject_sample_mapping sd
			     on md.expr_id = sd.sample_cd
		       where sd.platform = 'RNASEQCOG'
			 and sd.trial_name = TrialId
			 and sd.source_cd = sourceCd
--			 and sd.subject_id in (select subject_id from tm_lz.lt_src_rna_subj_samp_map) -- is this line needed? Not used in expression
		       group by md.probeset
			     ,sd.assay_id
		       	     ,sd.patient_id
--	LOOP
--	    raise notice 'explain: %', tExplain;
--	END LOOP
	;
	get diagnostics rowCt := ROW_COUNT;
    exception
	when others then
	    errorNumber := SQLSTATE;
	    errorMessage := SQLERRM;
	    --Handle errors.
	    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
	    perform tm_cz.cz_end_audit (jobId, 'FAIL');
	    return -16;
        end;
    pExists := rowCt;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into wt_subject_rna_probeset',rowCt,stepCt,'Done');

    --	insert into de_subject_rna_data when dataType is T (transformed)

    if dataType = 'T' then
	begin
	    insert into deapp.de_subject_rna_data
			(trial_source
			,probeset_id
			,assay_id
			,patient_id
			,trial_name
			,zscore
			)
	    select TrialId || ':' || sourceCd
		   ,probeset
		   ,assay_id
		   ,patient_id
		   ,trial_name
		   ,case when intensity_value < -2.5
		       then -2.5
		    when intensity_value > 2.5
			then 2.5
		    else intensity_value
		    end as zscore
	      from tm_wz.wt_subject_rna_probeset
	     where trial_name = TrialID;
	    get diagnostics rowCt := ROW_COUNT;
	exception
	    when others then
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
	    --Handle errors.
		perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
	    --End Proc
		perform tm_cz.cz_end_audit (jobId, 'FAIL');
		return -16;
	end;
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert transformed into DEAPP de_subject_rna_data',rowCt,stepCt,'Done');

    else

	--	Calculate ZScores and insert data into de_subject_rna_data.  The 'L' parameter indicates that the RNA_sequencing data will be selected from
	--	wt_subject_rna_probeset as part of a Load.

	if dataType = 'R' or dataType = 'L' then
	    begin
		select tm_cz.i2b2_rna_zscore_calc(TrialID, partitionName, partitionindx,partitionId,'L',jobId,dataType,logBase,sourceCD) into rtnCd;
		get diagnostics rowCt := ROW_COUNT;
	        stepCt := stepCt + 1;
	        if(rtnCd <> 1) then
	            perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Failed to calculate Z-Score',rowCt,stepCt,'Message');
	            perform tm_cz.cz_end_audit (jobId, 'FAIL');
	            return -16;
	        end if;
	        perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Calculate Z-Score',rowCt,stepCt,'Done');
	    exception
		when others then
		    errorNumber := SQLSTATE;
		    errorMessage := SQLERRM;
		--Handle errors.
		    perform tm_cz.cz_error_handler (jobId, procedureName, errorNumber, errorMessage);
		--End Proc
		    perform tm_cz.cz_end_audit (jobId, 'FAIL');
		    return -16;
	    end;
	end if;

    end if;

    ---Cleanup OVERALL JOB if this proc is being run standalone

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'End i2b2_process_rna_data',0,stepCt,'Done');

    if newJobFlag = 1 then
	perform tm_cz.cz_end_audit (jobId, 'SUCCESS');
    end if;

    return 1;
end;

$$;
