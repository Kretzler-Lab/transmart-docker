--
-- Name: i2b2_load_clinical_data(character varying, character varying, character varying, character varying, numeric); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_clinical_data(trial_id character varying, top_node character varying, secure_study character varying DEFAULT 'N'::character varying, highlight_study character varying DEFAULT 'N'::character varying, currentjobid numeric DEFAULT 0) RETURNS numeric
  LANGUAGE plpgsql SECURITY DEFINER
AS $$
    /*************************************************************************
     * Copyright 2008-2012 Janssen Research & Development, LLC.
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
    declare

    --Audit variables
    newJobFlag		integer;
    databaseName 	VARCHAR(100);
    procedureName	VARCHAR(100);
    jobID 		numeric(18,0);
    stepCt		numeric(18,0);
    rowCt		numeric(18,0);
    thisRowCt		numeric(18,0);
    errorNumber		character varying;
    errorMessage	character varying;

    topNode		varchar(2000);
    topNodeEscaped	varchar(2000);
    topLevel		numeric(10,0);
    topHlevel		numeric(10,0);
    root_node		varchar(2000);
    root_level		integer;
    study_name		varchar(2000);
    TrialID		varchar(100);
    secureStudy		varchar(200);
    etlDate		timestamp;
    tPath		varchar(2000);
    pCount		integer;
    pExists		integer;
    rtnCode		integer;
    tText		varchar(2000);
    rtnCd		integer;
    maxLen		integer;
    factLen		integer;
    tExplain 		text;

    --	cursor to define the path for delete_one_node  this will delete any nodes that are hidden after i2b2_create_concept_counts

    delNodes CURSOR is
		 select distinct c_fullname
		 from  i2b2metadata.i2b2
		 where c_fullname like topNodeEscaped || '%' escape '`'
		 and substr(c_visualattributes,2,1) = 'H';

    --	cursor to determine if any leaf nodes exist in i2b2 that are not used in this reload (node changes from text to numeric or numeric to text)

    delUnusedLeaf cursor is
		      select l.c_fullname
		      from i2b2metadata.i2b2 l
		      where l.c_visualattributes like 'L%'
		      and l.c_fullname like topNodeEscaped || '%' escape '`'
		      and l.c_fullname not in
		      (select t.leaf_node
			 from tm_wz.wt_trial_nodes t
			union
		       select m.c_fullname
			 from deapp.de_subject_sample_mapping sm
			      ,i2b2metadata.i2b2 m
			where sm.trial_name = TrialID
			  and sm.concept_code = m.c_basecode
			  and m.c_visualattributes like 'L%');

    -- added by Cognizant for requirement 3 and 4 under #1
    uploadI2b2 cursor is
		      select category_cd,display_value,display_label,display_unit
		        from tm_lz.lt_src_display_mapping
		    group by category_cd,display_value,display_label,display_unit;

begin

    TrialID := upper(trial_id);
    secureStudy := upper(secure_study);
    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;

    databaseName := 'tm_cz';
    procedureName := 'i2b2_load_clinical_data';

    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Start i2b2_load_clinical_data ',0,stepCt,'Done');

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it

    if(jobID IS NULL or jobID < 1) then
	newJobFlag := 1; -- True
	select tm_cz.cz_start_audit (procedureName, databaseName) into jobID;
    end if;

    stepCt := 0;
    stepCt := stepCt + 1;
    tText := 'Start i2b2_load_clinical_data for ' || TrialID;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Done');

    if (secureStudy not in ('Y','N') ) then
	secureStudy := 'Y';
    end if;

    topNode := regexp_replace('\' || top_node || '\','(\\){2,}', '\', 'g');
    topNodeEscaped := replace(topNode, '_', '`_');

    --	figure out how many nodes (folders) are at study name and above
    --	\Public Studies\Clinical Studies\Pancreatic_Cancer_Smith_GSE22780\: topLevel = 4, so there are 3 nodes
    --	\Public Studies\GSE12345\: topLevel = 3, so there are 2 nodes

    select length(topNode)-length(replace(topNode,'\','')) into topLevel;

    if topLevel < 3 then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Path specified in top_node must contain at least 2 nodes',0,stepCt,'Msg');
	perform tm_cz.cz_error_handler (jobID, procedureName, '-1', 'Application raised error');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    -- SKIP: the lz_src_clinical_data table is never used
    --	delete any existing data from lz_src_clinical_data and load new data
--    begin
--	delete from tm_lz.lz_src_clinical_data
--	 where study_id = TrialID;
--	get diagnostics rowCt := ROW_COUNT;
--    exception
--	when others then
--	    errorNumber := SQLSTATE;
--	    errorMessage := SQLERRM;
--	--Handle errors.
--	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
--	--End Proc
--	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
--	    return -16;
--    end;
--    stepCt := stepCt + 1;
--    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete existing data from lz_src_clinical_data',rowCt,stepCt,'Done');
--
--    begin
-- --    for tExplain in
-- --    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
--	insert into tm_lz.lz_src_clinical_data
--		    (study_id
--		    ,site_id
--		    ,subject_id
--		    ,visit_name
--		    ,data_label
--		    ,modifier_cd
--		    ,data_value
--		    ,units_cd
--		    ,date_timestamp
--		    ,category_cd
--		    ,etl_job_id
--		    ,etl_date
--		    ,ctrl_vocab_code)
--	select study_id
--	       ,site_id
--	       ,subject_id
--	       ,visit_name
--	       ,data_label
--               ,modifier_cd
--	       ,data_value
--               ,units_cd
--               ,date_timestamp
--	       ,category_cd
--	       ,jobID
--	       ,etlDate
--	       ,ctrl_vocab_code
--	  from tm_lz.lt_src_clinical_data
-- --	LOOP
-- --	    raise notice 'explain: %', tExplain;
-- --	END LOOP
--	;
--	get diagnostics rowCt := ROW_COUNT;
--    exception
--	when others then
--	    errorNumber := SQLSTATE;
--	    errorMessage := SQLERRM;
--	--Handle errors.
--	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
--	--End Proc
--	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
--	    return -16;
--    end;
--    stepCt := stepCt + 1;
--    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert data into lz_src_clinical_data',rowCt,stepCt,'Done');

    --	truncate tm_wz.wrk_clinical_data and load data from external file

    execute ('truncate table tm_wz.wrk_clinical_data');

    --	insert data from lt_src_clinical_data to tm_wz.wrk_clinical_data

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wrk_clinical_data (
	    study_id
	    ,site_id
	    ,subject_id
	    ,visit_name
	    ,data_label
	    ,modifier_cd
	    ,data_value
	    ,units_cd
	    ,date_timestamp
	    ,category_cd
	    ,ctrl_vocab_code
	)
	select study_id
	       ,site_id
	       ,subject_id
	       ,visit_name
	       ,data_label
               ,modifier_cd
	       ,data_value
               ,units_cd
               ,date_timestamp
	       ,category_cd
	       ,ctrl_vocab_code
	  from tm_lz.lt_src_clinical_data
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Load lt_src_clinical_data to work table',rowCt,stepCt,'Done');

    -- Get root_node from topNode

    select tm_cz.parse_nth_value(topNode, 2, '\') into root_node;

    select count(*) into pExists
      from i2b2metadata.table_access
     where c_name = root_node;

    select count(*) into pCount
      from i2b2metadata.i2b2
     where c_name = root_node;

    if pExists = 0 or pCount = 0 then
	perform tm_cz.i2b2_add_root_node(root_node, jobID);
    end if;

    select c_hlevel into root_level
      from i2b2metadata.table_access
     where c_name = root_node;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Fetch root node "' || root_node ||'" and root_level ' || root_level::text,rowCt,stepCt,'Done');

    -- Get study name from topNode

    select tm_cz.parse_nth_value(topNode, topLevel, '\') into study_name;

    --	Add any upper level nodes as needed

    tPath := regexp_replace(replace(top_node,study_name,''),'(\\){2,}', '\', 'g');
    select length(tPath) - length(replace(tPath,'\','')) into pCount;

    if pCount > 2 then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Adding upper-level nodes',0,stepCt,'Done');
	select tm_cz.i2b2_fill_in_tree(null, tPath, jobID) into rtnCd;
	if(rtnCd <> 1) then
	    tText := 'Failed to fill in tree '|| tPath;
	    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
        end if;
    end if;

    select count(*) into pExists
      from i2b2metadata.i2b2
     where c_fullname = topNode;

    --	add top node for study

    if pExists = 0 then
	select tm_cz.i2b2_add_node(TrialID, topNode, study_name, jobID) into rtnCd;
	stepCt := stepCt + 1;
	if(rtnCd <> 1) then
            tText := 'Failed to add leaf node '|| topNode;
	    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
        end if;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Adding top node for study',0,stepCt,'Done');
    end if;

    --	Set data_type, category_path, sourcesystem_cd, usubjid and uencid
    --	category_path: change underscore to space, multi backslash to \, \ to +
    --	sourcesystem_cd: TrialID:subject_id replace double colon with single
    --	usubjid: TrialID:site_id:subject_id replace double colon with single
    --	uencid: TrialID:site_id:subject_id:visit_name replace multiple colon with single

    update tm_wz.wrk_clinical_data
       set data_type = 'T'
	   ,category_path = regexp_replace(regexp_replace(replace(category_cd,'_',' '),'([^\\])\+','\1\','g'),'\\\+','+','g')
	   ,sourcesystem_cd = concat_ws(':',TrialID,subject_id)
	   ,usubjid = concat_ws(':',TrialID,site_id,subject_id)
	   ,uencid = concat_ws(':',TrialID,site_id,subject_id,visit_name)
--	   ,sourcesystem_cd = replace(TrialID || ':' || subject_id,
--				     '::', ':')
--	   ,usubjid = replace(TrialID || ':' || coalesce(site_id,'') || ':' || subject_id,
--				     '::', ':')
--	   ,uencid = regexp_replace(TrialID || ':' || coalesce(site_id,'') || ':' || subject_id || ':' || coalesce(visit_name,''),
--				     '(:){2,}', ':', 'g')
	;
    get diagnostics rowCt := ROW_COUNT;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set columns in tm_wz.wrk_clinical_data',rowCt,stepCt,'Done');

    --	Delete rows where data_value is null

    begin
	delete from tm_wz.wrk_clinical_data
	 where data_value is null;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete null data_values in tm_wz.wrk_clinical_data',rowCt,stepCt,'Done');

    --Remove Invalid pipes in the data values.
    --RULE: If Pipe is last or first, delete it
    --If it is in the middle replace with a dash

    begin
	update tm_wz.wrk_clinical_data
	   set data_value = replace(trim('|' from data_value), '|', '-')
	 where data_value like '%|%';
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Remove pipes in data_value',rowCt,stepCt,'Done');

    --Remove invalid Parens in the data
    --They have appeared as empty pairs or only single ones.

    begin
	update tm_wz.wrk_clinical_data
	   set data_value = replace(data_value,'(', '')
	 where data_value like '%()%'
	       or data_value like '%( )%'
	       or (data_value like '%(%' and data_value NOT like '%)%');
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Remove empty parentheses 1',rowCt,stepCt,'Done');

    begin
	update tm_wz.wrk_clinical_data
	   set data_value = replace(data_value,')', '')
	 where data_value like '%()%'
	       or data_value like '%( )%'
	       or (data_value like '%)%' and data_value NOT like '%(%');
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Remove empty parentheses 2',rowCt,stepCt,'Done');

    --Replace the Pipes with Commas in the data_label column
    begin
	update tm_wz.wrk_clinical_data
	   set data_label = replace (data_label, '|', ',')
	 where data_label like '%|%';
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Replace pipes with comma in data_label',rowCt,stepCt,'Done');

    --	set visit_name to null when there's only a single visit_name for the category

    begin
	update tm_wz.wrk_clinical_data tpm
	   set visit_name=null
	 where (tpm.category_cd) in
	       (select x.category_cd
		  from tm_wz.wrk_clinical_data x
		 group by x.category_cd
		having count(distinct upper(x.visit_name)) = 1);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set single visit_name to null',rowCt,stepCt,'Done');

    --	set data_label to null when it duplicates the last part of the category_path
    --	Remove data_label from last part of category_path when they are the same

    begin
	update tm_wz.wrk_clinical_data tpm
	   set category_path=substr(tpm.category_path,1,tm_cz.instr(tpm.category_path,'\',-2,1)-1)
	       ,category_cd=substr(tpm.category_cd,1,tm_cz.instr(tpm.category_cd,'+',-2,1)-1)
	 where tm_cz.instr(tpm.category_path,'\',-1,1) > 0 and (tpm.category_cd, tpm.data_label) in
	       (select distinct t.category_cd
				,t.data_label
		  from tm_wz.wrk_clinical_data t
		 where upper(substr(t.category_path,tm_cz.instr(t.category_path,'\',-1,1)+1,length(t.category_path)-tm_cz.instr(t.category_path,'\',-1,1)))
		       = upper(t.data_label)
		   and t.data_label is not null)
	       and tpm.data_label is not null;
	get diagnostics rowCt := ROW_COUNT;
	stepCt := stepCt + 1;
    	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Remove data_label from last part of category_path if they are the same',rowCt,stepCt,'Done');

	update tm_wz.wrk_clinical_data tpm
	   set data_label = null
	 where tm_cz.instr(tpm.category_path,'\',-1,1) = 0 and (tpm.category_cd, tpm.data_label) in
               (select distinct t.category_cd
				,t.data_label
		  from tm_wz.wrk_clinical_data t
		 where upper(substr(t.category_path,tm_cz.instr(t.category_path,'\',-1,1)+1,length(t.category_path)-tm_cz.instr(t.category_path,'\',-1,1)))
                       = upper(t.data_label)
		   and t.data_label is not null)
               and tpm.data_label is not null;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set data_label to null when found in category_path',rowCt,stepCt,'Done');

    --	set visit_name to null if same as data_label

    begin
	update tm_wz.wrk_clinical_data t
	   set visit_name=null
	 where (t.category_cd, t.visit_name, t.data_label) in
	       (select distinct tpm.category_cd
				,tpm.visit_name
				,tpm.data_label
		  from tm_wz.wrk_clinical_data tpm
		 where tpm.visit_name = tpm.data_label);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set visit_name to null when found in data_label',rowCt,stepCt,'Done');

    --	set visit_name to null if same as data_value

    begin
	update tm_wz.wrk_clinical_data t
	   set visit_name=null
	 where (t.category_cd, t.visit_name, t.data_value) in
	       (select distinct tpm.category_cd
				,tpm.visit_name
				,tpm.data_value
		  from tm_wz.wrk_clinical_data tpm
		 where tpm.visit_name = tpm.data_value);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set visit_name to null when found in data_value',rowCt,stepCt,'Done');

    --	set visit_name to null if only DATALABEL in category_cd

    begin
	update tm_wz.wrk_clinical_data t
	   set visit_name=null
	 where t.category_cd like '%DATALABEL%'
	       and t.category_cd not like '%VISITNAME%';
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set visit_name to null when only DATALABEL in category_cd',rowCt,stepCt,'Done');

    --	change any % to Pct and & and + to ' and ' and _ to space in data_label only

    begin
	update tm_wz.wrk_clinical_data
	   set data_label=replace(regexp_replace(regexp_replace(replace(replace(data_label,'%',' Pct'),'&',' and '),'([^\\])\+','\1 and ','g'),'\\\+','+','g'),'_',' ')
	       ,data_value=replace(replace(replace(data_value,'%',' Pct'),'&',' and '),'+',' and ')
	       ,category_cd=replace(replace(category_cd,'%',' Pct'),'&',' and ')
	       ,category_path=replace(replace(category_path,'%',' Pct'),'&',' and ');
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

    --Trim trailing and leading spaces as well as remove any double spaces, remove space from before comma, remove trailing comma

    begin
	update tm_wz.wrk_clinical_data
	   set data_label  = trim(trailing ',' from trim(replace(replace(data_label,'  ', ' '),' ,',','))),
	       data_value  = trim(trailing ',' from trim(replace(replace(data_value,'  ', ' '),' ,',','))),
	    --	   sample_type = trim(trailing ',' from trim(replace(replace(sample_type,'  ', ' '),' ,',','))),
	       visit_name  = trim(trailing ',' from trim(replace(replace(visit_name,'  ', ' '),' ,',',')))
	;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Remove leading, trailing, double spaces from data_label data_value visit_name',rowCt,stepCt,'Done');

    --1. DETERMINE THE DATA_TYPES OF THE FIELDS
    --	replaced cursor with update, used temp table to store category_cd/data_label because correlated subquery ran too long

    execute ('truncate table tm_wz.wt_num_data_types');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wt_num_data_types (
	    category_cd
	    ,data_label
	    ,visit_name
	)
	select category_cd
               ,data_label
               ,visit_name
	  from tm_wz.wrk_clinical_data
	 where data_value is not null
	 group by category_cd
		  ,data_label
		  ,visit_name
	having sum(tm_cz.is_numeric(data_value)) = 0
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert numeric data into WZ wt_num_data_types',rowCt,stepCt,'Done');

    --	Check if any duplicate records of key columns (site_id, subject_id, visit_name, data_label, category_cd) for numeric data
    --	exist.  Raise error if yes

    execute ('truncate table tm_wz.wt_clinical_data_dups');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wt_clinical_data_dups (
	    site_id
	    ,subject_id
	    ,visit_name
	    ,data_label
	    ,category_cd
	    ,modifier_cd
	)
	select w.site_id
	       ,w.subject_id
	       ,w.visit_name
	       ,w.data_label
	       ,w.category_cd
	       ,w.modifier_cd
	  from tm_wz.wrk_clinical_data w
	 where exists
	       (select 1 from tm_wz.wt_num_data_types t
		 where coalesce(w.category_cd,'@') = coalesce(t.category_cd,'@')
		   and coalesce(w.data_label,'@') = coalesce(t.data_label,'@')
		   and coalesce(w.visit_name,'@') = coalesce(t.visit_name,'@')
	       )
	 group by w.site_id, w.subject_id, w.visit_name, w.data_label, w.category_cd, w.modifier_cd
	having count(*) > 1
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Check for duplicate key columns',rowCt,stepCt,'Done');

    if rowCt > 0 then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Duplicate values found in key columns',rowCt,stepCt,'Msg');
	perform tm_cz.cz_error_handler (jobID, procedureName, '-1', 'Application raised error');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    --	check for multiple visit_names for category_cd, data_label, data_value

    select max(case when x.null_ct > 0 and x.non_null_ct > 0
	then 1 else 0 end) into pCount
      from (select category_cd, data_label, data_value
		   ,sum(case when visit_name is null then 1 else 0 end) as null_ct
		   ,sum(case when visit_name is null then 0 else 1 end) as non_null_ct
	      from tm_lz.lt_src_clinical_data
	     where (category_cd like '%VISITNAME%' or
		    category_cd not like '%DATALABEL%')
	     group by category_cd, data_label, data_value) x;
    get diagnostics rowCt := ROW_COUNT;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Check for multiple visit_names for category/label/value ',rowCt,stepCt,'Done');

    if pCount > 0 then
	stepCt := stepCt + 1;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Multiple visit names for category/label/value',0,stepCt,'Msg');
	perform tm_cz.cz_error_handler (jobID, procedureName, '-1', 'Application raised error');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    begin
	update tm_wz.wrk_clinical_data t
	   set data_type='N'
	       ,dval_char='E'
	       ,dval_num=data_value::numeric
	 where exists
	       (select 1 from tm_wz.wt_num_data_types x
		 where coalesce(t.category_cd,'@') = coalesce(x.category_cd,'@')
		   and coalesce(t.data_label,'**NULL**') = coalesce(x.data_label,'**NULL**')
		   and coalesce(t.visit_name,'**NULL**') = coalesce(x.visit_name,'**NULL**')
	       );
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Updated data_type flag for numeric data_types',rowCt,stepCt,'Done');

    begin
	update tm_wz.wrk_clinical_data t
	   set dval_char=data_value
	       ,dval_num=NULL
	 where data_type = 'T';
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Updated data_type flag for text data_types',rowCt,stepCt,'Done');

    -- Check all text data values will fit in observation_fact

    select character_maximum_length from information_schema.columns
     where table_schema = 'i2b2demodata'
       and table_name = 'observation_fact'
       and column_name = 'tval_char'
       into factLen;

    raise NOTICE 'observation_fact tval_char size %', factLen;

--    select max(length(dval_char)) from tm_wz.wrk_clinical_data where data_type = 'T' into maxLen;
    select max(length(dval_char)) from tm_wz.wrk_clinical_data into maxLen;

    if(maxLen is NULL) then
    	maxLen := 0;
    end if;

    raise NOTICE 'wrk_clinical_data max dval_char length %', maxLen;

    stepCt := stepCt + 1;
    if (maxLen > factLen) then
        tText := 'tm_wz.wrk_clinical data has records with dval_char ' || maxLen || ' longer than observation_fact max ' || factLen || ' bytes';
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Msg');
	perform tm_cz.cz_error_handler (jobID, procedureName, '-1', 'Application raised error');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    tText := 'Check tm_wz.wrk_clinical data max record length in column dval_char ' || maxLen || ' within observation_fact max ' || factLen || ' bytes';

    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Done');

    -- Build all needed leaf nodes in one pass for both numeric and text nodes

    execute ('truncate table tm_wz.wt_trial_nodes');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wt_trial_nodes (
	    leaf_node
	    ,category_cd
	    ,visit_name
	    ,data_label
	    ,data_value
	    ,data_type
	)
	select DISTINCT
	    Case
	    --	Text data_type (default node)
		When a.data_type = 'T'
		then case when a.category_path like '%DATALABEL%' and a.category_path like '%VISITNAME%'
		then regexp_replace(topNode || replace(replace(coalesce(a.category_path,''),'DATALABEL',coalesce(a.data_label,'')),'VISITNAME',coalesce(a.visit_name,'')) || '\' || coalesce(a.data_value,'') || '\','(\\){2,}', '\', 'g')
		when a.category_path like '%DATALABEL%'
		then regexp_replace(topNode || replace(coalesce(a.category_path,''),'DATALABEL',coalesce(a.data_label,'')) || '\' || coalesce(a.data_value,'') || '\','(\\){2,}', '\', 'g')
		else regexp_replace(topNode || coalesce(a.category_path,'') ||
				    '\'  || coalesce(a.data_label,'') || '\' || coalesce(a.data_value,'') || '\' || coalesce(a.visit_name,'') || '\',
				    '(\\){2,}', '\', 'g')
		end
	    --	else is numeric data_type and default_node
		else case when a.category_path like '%DATALABEL%' and a.category_path like '%VISITNAME%'
		then regexp_replace(topNode || replace(replace(coalesce(a.category_path,''),'DATALABEL',coalesce(a.data_label,'')),'VISITNAME',coalesce(a.visit_name,'')) || '\','(\\){2,}', '\', 'g')
		when a.category_path like '%DATALABEL%'
		then regexp_replace(topNode || replace(coalesce(a.category_path,''),'DATALABEL',coalesce(a.data_label,'')) || '\','(\\){2,}', '\', 'g')
		else regexp_replace(topNode || coalesce(a.category_path,'') ||
				    '\'  || coalesce(a.data_label,'') || '\' || coalesce(a.visit_name,'') || '\',
				    '(\\){2,}', '\', 'g')
		end
		end as leaf_node
	    ,a.category_cd
	    ,a.visit_name
	    ,a.data_label
	    ,case when a.data_type = 'T' then a.data_value else null end as data_value
	    ,a.data_type
	  from  tm_wz.wrk_clinical_data a
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Create leaf nodes for trial',rowCt,stepCt,'Done');

    --	set node_name

    begin
	update tm_wz.wt_trial_nodes
	   set node_name=tm_cz.parse_nth_value(leaf_node,length(leaf_node)-length(replace(leaf_node,'\','')),'\');
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Updated node name for leaf nodes',rowCt,stepCt,'Done');

    execute ('truncate table tm_wz.wt_subject_info');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into tm_wz.wt_subject_info (
	    usubjid
	    ,sourcesystem_cd
	    ,age_in_years_num
	    ,sex_cd
	    ,race_cd
	)
	select a.usubjid
	       ,a.sourcesystem_cd
	       ,max(case when upper(a.data_label) = 'AGE'
		   then case when tm_cz.is_numeric(a.data_value) = 1 then null else round(a.data_value::numeric) end
		    when upper(a.data_label) like '%(AGE)'
			then case when tm_cz.is_numeric(a.data_value) = 1 then null else round(a.data_value::numeric) end
		    else null::integer end) as age
	       ,max(case when upper(a.data_label) = 'SEX' then a.data_value
		    when upper(a.data_label) like '%(SEX)' then a.data_value
		    when upper(a.data_label) = 'GENDER' then a.data_value
		    else null end) as sex
	       ,max(case when upper(a.data_label) = 'RACE' then a.data_value
		    when upper(a.data_label) like '%(RACE)' then a.data_value
		    else null end) as race
	  from tm_wz.wrk_clinical_data a
	 group by a.sourcesystem_cd, a.usubjid
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert subject information into temp table',rowCt,stepCt,'Done');

    --	insert/update subjects in patient_mapping

    --	Delete dropped subjects from patient_mapping if they do not exist in de_subject_sample_mapping

    begin
	delete from i2b2demodata.patient_mapping
	 where sourcesystem_cd in
	       (select distinct pm.sourcesystem_cd from i2b2demodata.patient_mapping pm
		 where pm.sourcesystem_cd like TrialID || ':%'
		except
		select distinct cd.sourcesystem_cd from tm_wz.wt_subject_info cd)
	       and patient_num not in
	       (select distinct sm.patient_id from deapp.de_subject_sample_mapping sm);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete dropped subjects from patient_mapping',rowCt,stepCt,'Done');

    --	update patients with changed information (e.g. subject_id may have changed)

    begin
	with nsi as (select distinct t.usubjid, t.subject_id, t.sourcesystem_cd from tm_wz.wrk_clinical_data t)
		update i2b2demodata.patient_mapping pm
		set patient_ide = nsi.usubjid
		,patient_ide_source = 'transmart'
		,patient_ide_status = 'A' -- assumes patients are alive
		,project_id = TrialID
		,update_date = current_timestamp
		from nsi
		where pm.sourcesystem_cd = nsi.sourcesystem_cd;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Update subjects with changed demographics in patient_mapping',rowCt,stepCt,'Done');

    --	insert new subjects into patient_mapping, generating new patient_num

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into i2b2demodata.patient_mapping (
	    patient_num
	    ,patient_ide
	    ,patient_ide_source
	    ,patient_ide_status
	    ,project_id
	    ,upload_date
	    ,update_date
	    ,download_date
	    ,import_date
	    ,sourcesystem_cd
	)
	select nextval('i2b2demodata.seq_patient_num')
	       ,t.usubjid
	       ,'transmart'
	       ,'A'		-- assume patients are alive unless otherwise stated
	       ,TrialId
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,t.sourcesystem_cd
	  from tm_wz.wt_subject_info t
	 where t.usubjid in
	       (select distinct si.usubjid from tm_wz.wt_subject_info si
		except
		select distinct pm.patient_ide from i2b2demodata.patient_mapping pm
		 where pm.patient_ide like TrialID || ':%')
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert new subjects into patient_mapping',rowCt,stepCt,'Done');

    --	insert/update encounters in encounter_mapping

    --	Delete dropped encounters from encounter_mapping

    begin
	delete from i2b2demodata.encounter_mapping
	 where sourcesystem_cd in
	       (select distinct em.sourcesystem_cd from i2b2demodata.encounter_mapping em
		 where em.sourcesystem_cd like TrialID || ':%'
		except
		select distinct cd.sourcesystem_cd from tm_wz.wt_subject_info cd)
	       and patient_ide not in
	       (select pm.patient_ide from i2b2demodata.patient_mapping pm, deapp.de_subject_sample_mapping sm where pm.patient_num = sm.patient_id);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete dropped encounters from encounter_mapping',rowCt,stepCt,'Done');

    --	update encounters with changed information

    begin
	with nsi as (select distinct t.uencid, t.usubjid, t.sourcesystem_cd from tm_wz.wrk_clinical_data t)
		update i2b2demodata.encounter_mapping em
		set encounter_ide_source = 'transmart'
		,patient_ide_source = 'transmart'
		,project_id = TrialID
		,patient_ide = nsi.usubjid
		,update_date = current_timestamp
		from nsi
		where em.sourcesystem_cd = nsi.sourcesystem_cd
		  and em.encounter_ide = nsi.uencid;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Update encounters with changed values in encounter_mapping',rowCt,stepCt,'Done');

    --	insert new encounters into encounter_mapping, generating new encounter_num

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into i2b2demodata.encounter_mapping (
	    encounter_num
	    ,encounter_ide
	    ,encounter_ide_source
	    ,encounter_ide_status
	    ,project_id
	    ,patient_ide
	    ,patient_ide_source
	    ,upload_date
	    ,update_date
	    ,download_date
	    ,import_date
	    ,sourcesystem_cd
	)
	select nextval('i2b2demodata.seq_encounter_num')
	       ,t.uencid
	       ,'transmart'
	       ,'A'		-- assume patient is alive at encounter time
	       ,TrialId
	       ,t.usubjid
	       ,'transmart'
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,t.sourcesystem_cd
	from (select distinct cd.uencid, cd.usubjid, cd.sourcesystem_cd from tm_wz.wrk_clinical_data cd
	       where cd.uencid in
	             (select distinct cd.uencid from tm_wz.wrk_clinical_data cd
		      except
		      select distinct em.encounter_ide from i2b2demodata.encounter_mapping em
		       where em.encounter_ide like TrialID || ':%')) t
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert new subjects into encounter_mapping',rowCt,stepCt,'Done');

    --	insert/update subjects in patient_dimension

    --	Delete dropped subjects from patient_dimension if they do not exist in de_subject_sample_mapping

    begin
	delete from i2b2demodata.patient_dimension
	 where sourcesystem_cd in
	       (select distinct pd.sourcesystem_cd from i2b2demodata.patient_dimension pd
		 where pd.sourcesystem_cd like TrialID || ':%'
		except
		select distinct cd.usubjid from tm_wz.wrk_clinical_data cd)
	       and patient_num not in
	       (select distinct sm.patient_id from deapp.de_subject_sample_mapping sm);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete dropped subjects from patient_dimension',rowCt,stepCt,'Done');

    --	update patients with changed information

    begin
	with nsi as (select t.usubjid, t.sex_cd, t.age_in_years_num, t.race_cd from tm_wz.wt_subject_info t)
		update i2b2demodata.patient_dimension
		set sex_cd=nsi.sex_cd
		,age_in_years_num=nsi.age_in_years_num
		,race_cd=nsi.race_cd
		from nsi
		where sourcesystem_cd = nsi.usubjid;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Update subjects with changed demographics in patient_dimension',rowCt,stepCt,'Done');

    --	insert new subjects into patient_dimension

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
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
	select pm.patient_num
	       ,t.sex_cd
	       ,t.age_in_years_num
	       ,t.race_cd
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,t.usubjid
	  from tm_wz.wt_subject_info t,
	  i2b2demodata.patient_mapping pm
	 where t.usubjid = pm.patient_ide
	       and t.usubjid in
	       (select distinct cd.usubjid from tm_wz.wt_subject_info cd
		except
		select distinct pd.sourcesystem_cd from i2b2demodata.patient_dimension pd
		 where pd.sourcesystem_cd like TrialID || ':%')
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert new subjects into patient_dimension',rowCt,stepCt,'Done');

    --	delete leaf nodes that will not be reused, if any

    for r_delUnusedLeaf in delUnusedLeaf loop

	--	deletes unused leaf nodes for a trial one at a time

	select tm_cz.i2b2_delete_1_node(r_delUnusedLeaf.c_fullname,jobID) into rtnCd;
	stepCt := stepCt + 1;
	if(rtnCd <> 1) then
	    tText := 'Failed to delete node '|| r_delUnusedLeaf.c_fullname;
	    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
        end if;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Deleted unused leaf node: ' || r_delUnusedLeaf.c_fullname,1,stepCt,'Done');

    end loop;

    --	bulk insert leaf nodes
    begin
	with ncd as (select t.leaf_node, t.node_name from tm_wz.wt_trial_nodes t)
		update i2b2demodata.concept_dimension
		set name_char=ncd.node_name
		from ncd
		where concept_path = ncd.leaf_node;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Update name_char in concept_dimension for changed names',rowCt,stepCt,'Done');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into i2b2demodata.concept_dimension (
	    concept_cd
	    ,concept_path
	    ,name_char
	    ,update_date
	    ,download_date
	    ,import_date
	    ,sourcesystem_cd
	)
	select 'TM' || cast(nextval('i2b2demodata.concept_id') as varchar)
	       ,x.leaf_node
	       ,x.node_name
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,TrialID
	  from (select distinct c.leaf_node
				,c.node_name::text as node_name
		  from tm_wz.wt_trial_nodes c
		 where not exists
		       (select 1 from i2b2demodata.concept_dimension x
			 where c.leaf_node = x.concept_path)
	  ) x
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Inserted new leaf nodes into I2B2DEMODATA concept_dimension',rowCt,stepCt,'Done');

    --	update i2b2 with name, data_type and xml for leaf nodes
    begin
	with ncd as (select t.leaf_node, t.node_name, t.data_type from tm_wz.wt_trial_nodes t)
		update i2b2metadata.i2b2
		set c_name=ncd.node_name
		,c_columndatatype='T'
		,c_metadataxml=case when ncd.data_type = 'T'
		    then null
		    else '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>'
		    end
		from ncd
		where c_fullname = ncd.leaf_node;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Updated name and data type in i2b2 if changed',rowCt,stepCt,'Done');

    begin
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	insert into i2b2metadata.i2b2 (
	    c_hlevel
	    ,c_fullname
	    ,c_name
	    ,c_visualattributes
	    ,c_synonym_cd
	    ,c_facttablecolumn
	    ,c_tablename
	    ,c_columnname
	    ,c_dimcode
	    ,c_tooltip
	    ,update_date
	    ,download_date
	    ,import_date
	    ,sourcesystem_cd
	    ,c_basecode
	    ,c_operator
	    ,c_columndatatype
	    ,c_comment
	    ,m_applied_path
	    ,c_metadataxml
	)
	select (length(c.concept_path) - coalesce(length(replace(c.concept_path, '\','')),0)) / length('\') - 2 + root_level
	       ,c.concept_path
	       ,c.name_char
	       ,'LA'
	       ,'N'
	       ,'CONCEPT_CD'
	       ,'CONCEPT_DIMENSION'
	       ,'CONCEPT_PATH'
	       ,c.concept_path
	       ,c.concept_path
	       ,current_timestamp
	       ,current_timestamp
	       ,current_timestamp
	       ,c.sourcesystem_cd
	       ,c.concept_cd
	       ,'LIKE'
	       ,'T'
	       ,'trial:' || TrialID
	       ,'@'
	       ,case when t.data_type = 'T' then null
		    else '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>'
		end
	  from i2b2demodata.concept_dimension c
	       ,tm_wz.wt_trial_nodes t
	 where c.concept_path = t.leaf_node
	   and not exists
	       (select 1 from i2b2metadata.i2b2 x
		 where c.concept_path = x.c_fullname)
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
	    perform tm_cz.cz_error_handler (jobID, procedureName, errorNumber, errorMessage);
	--End Proc
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
    end;
    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Inserted leaf nodes into I2B2METADATA i2b2',rowCt,stepCt,'Done');

    begin
	for ul in uploadI2b2 loop
	    update i2b2metadata.i2b2 n
	        --Static XML String
	       set c_metadataxml =  ('<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis>'||
		 (select xmlelement(name "SeriesMeta",xmlforest(m.display_value as "Value",m.display_unit as "Unit",m.display_label as "DisplayName")) as hi
		    from tm_lz.lt_src_display_mapping m
		   where (m.category_cd||m.display_label)=(ul.category_cd||ul.display_label))||'</ValueMetadata>')
	     where n.c_fullname in
		   (select leaf_node
		      from tm_wz.wt_trial_nodes
		     where (((category_cd||'+'||replace(data_label,'PCT','%'))||node_name)=(ul.category_cd||ul.display_label)
			    or (category_cd||node_name)=(ul.category_cd||ul.display_label)) and leaf_node=n.c_fullname);
        end loop;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Updated I2B2 for metadataXML',rowCt,stepCt,'Done');


    --	delete from observation_fact all concept_cds for trial that are clinical data, exclude concept_cds from biomarker data

    begin
	delete from i2b2demodata.observation_fact f
	 where f.sourcesystem_cd = TrialID
	       and f.concept_cd not in
	       (select distinct concept_code as concept_cd from deapp.de_subject_sample_mapping
		 where trial_name = TrialID
		   and concept_code is not null
		 union
		select distinct platform_cd as concept_cd from deapp.de_subject_sample_mapping
		 where trial_name = TrialID
		   and platform_cd is not null
		 union
		select distinct sample_type_cd as concept_cd from deapp.de_subject_sample_mapping
		 where trial_name = TrialID
		   and sample_type_cd is not null
		 union
		select distinct tissue_type_cd as concept_cd from deapp.de_subject_sample_mapping
		 where trial_name = TrialID
		   and tissue_type_cd is not null
		 union
		select distinct timepoint_cd as concept_cd from deapp.de_subject_sample_mapping
		 where trial_name = TrialID
		   and timepoint_cd is not null
		 union
		select distinct concept_cd as concept_cd from deapp.de_subject_snp_dataset
		 where trial_name = TrialID
		   and concept_cd is not null);
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Delete clinical data for study from observation_fact',rowCt,stepCt,'Done');

    --Insert into observation_fact

    begin
	rowCt = 0;
--    for tExplain in
--    EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
	    insert into i2b2demodata.observation_fact (
		encounter_num
		,patient_num
		,concept_cd
		,start_date
		,modifier_cd
		,valtype_cd
		,tval_char
		,nval_num
		,units_cd
		,sourcesystem_cd
		,import_date
		,valueflag_cd
		,provider_id
		,location_cd
		,instance_num
	    )
	    select em.encounter_num
		   ,pm.patient_num
		   ,i.c_basecode
		   ,coalesce(a.date_timestamp, 'infinity')
		   ,coalesce(a.modifier_cd, '@')
		   ,a.data_type
		   ,a.dval_char
		   ,a.dval_num
                   ,a.units_cd
		   ,a.study_id
		   ,current_timestamp
		   ,'@'
		   ,'@'
		   ,'@'
                   ,1
	      from tm_wz.wrk_clinical_data a
		   ,i2b2demodata.encounter_mapping em
		   ,i2b2demodata.patient_mapping pm
		   ,tm_wz.wt_trial_nodes t
		   ,i2b2metadata.i2b2 i
	     where a.usubjid = pm.patient_ide  --TrialID:siteId:subjid
	       and a.uencid = em.encounter_ide --TrialID:encounter_num
	       and a.study_id = i.sourcesystem_cd --TrialID
	       and coalesce(a.category_cd,'@') = coalesce(t.category_cd,'@')
	       and t.leaf_node = i.c_fullname
	       and coalesce(a.data_label,'**NULL**') = coalesce(t.data_label,'**NULL**')
	       and coalesce(a.visit_name,'**NULL**') = coalesce(t.visit_name,'**NULL**')
	       and case when a.data_type = 'T' then a.data_value else '**NULL**' end = coalesce(t.data_value,'**NULL**')
	       and not exists		-- don't insert if lower level node exists
		   (select 1 from tm_wz.wt_trial_nodes x
		     where (substr(x.leaf_node, 1, tm_cz.instr(x.leaf_node, '\', -2))) = t.leaf_node)
	       and a.data_value is not null
--	LOOP
--	    raise notice 'explain: %', tExplain;
--	END LOOP
	;
get diagnostics thisRowCt := ROW_COUNT;
	    rowCt := rowCt + thisRowCt;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Insert trial into I2B2DEMODATA observation_fact',rowCt,stepCt,'Done');

    -- insert any missing nodes in the hierarchy now,
    -- so we can check parent and be sure of a match
    select tm_cz.i2b2_fill_in_tree(TrialID, topNodeEscaped, jobID) into rtnCd;
    if(rtnCd <> 1) then
        tText := 'Failed to fill in tree '|| topNode;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Message');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    --	update c_visualattributes for all nodes in study, done to pick up any node that changed c_columndatatype

    begin
	with upd as
		(with nodes as
			 (select c_fullname as fullname
				 ,ltrim(SUBSTR(p.c_fullname, 1,tm_cz.instr(p.c_fullname, '\',-1,2))) as parent
			    from i2b2metadata.i2b2 p
			   where p.c_fullname like topNodeEscaped || '%' escape '`')
		select n.fullname as node, 0 as nbr_children from nodes n
		 where not exists (select * from nodes p where p.parent = n.fullname)
		 union all
		select p.parent as node,
		       count(distinct n.fullname) as nbr_children
		  from nodes n, nodes p
		 where p.parent = n.fullname
		 group by node)
		update i2b2metadata.i2b2 b
		set c_visualattributes=case when upd.nbr_children = 0
		    then 'L' || substr(b.c_visualattributes,2,2)
		    else 'F' || substr(b.c_visualattributes,2,1) ||
		        case when upd.node = topNode
		            then case when highlight_study = 'Y' then 'J' else 'S' end
		            else substr(b.c_visualattributes,3,1) end
		    end
		,c_columndatatype=case when upd.nbr_children > 0 then 'T' else b.c_columndatatype end
		from upd
		where b.c_fullname = upd.node;
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
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Set c_visualattributes in i2b2',rowCt,stepCt,'Done');

    -- final procs

    select tm_cz.load_tm_trial_nodes(TrialID,topNode,jobID,true) into rtnCd;

    if(rtnCd <> 1) then
        stepCt := stepCt + 1;
        perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Failed to load tm_trial_nodes',0,stepCt,'Message');
        perform tm_cz.cz_end_audit (jobID, 'FAIL');
        return -16;
    end if;

    perform tm_cz.i2b2_create_concept_counts(TrialID, topNode, jobID);

    --	delete each node that is hidden after create concept counts

    for r_delNodes in delNodes loop

	--	deletes hidden nodes for a trial one at a time

	select tm_cz.i2b2_delete_1_node(r_delNodes.c_fullname,jobID) into rtnCd;
	stepCt := stepCt + 1;
	if(rtnCd <> 1) then
	    tText := 'Failed to delete node '|| r_delNodes.c_fullname;
	    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,0,stepCt,'Message');
	    perform tm_cz.cz_end_audit (jobID, 'FAIL');
	    return -16;
        end if;
	tText := 'Deleted hidden node: ' || r_delNodes.c_fullname;
	perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,tText,rowCt,stepCt,'Done');

    end loop;

    topHlevel := topLevel - 2 + root_level;
    perform tm_cz.i2b2_create_security_for_trial(TrialID, secureStudy, topHlevel, jobID);
    select tm_cz.i2b2_load_security_data(TrialID,jobID) into rtnCd;

    if(rtnCd <> 1) then
       stepCt := stepCt + 1;
       perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'Failed to load security data',0,stepCt,'Message');
	perform tm_cz.cz_end_audit (jobID, 'FAIL');
	return -16;
    end if;

    stepCt := stepCt + 1;
    perform tm_cz.cz_write_audit(jobID,databaseName,procedureName,'End i2b2_load_clinical_data',0,stepCt,'Done');

    ---Cleanup OVERALL JOB if this proc is being run standalone
    if newJobFlag = 1 then
	perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
    end if;

    return 1;
end;

$$;
