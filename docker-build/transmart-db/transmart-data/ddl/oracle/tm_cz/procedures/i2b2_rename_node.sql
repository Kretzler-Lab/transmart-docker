--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_RENAME_NODE
--
CREATE OR REPLACE PROCEDURE TM_CZ.I2B2_RENAME_NODE (
    trial_id varchar2,
    old_node VARCHAR2,
    new_node VARCHAR2,
    currentJobID number:=null
)

AS

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

    --Audit variables
    newJobFlag INTEGER(1);
    databaseName VARCHAR(100);
    procedureName VARCHAR(100);
    jobID number(18,0);
    stepCt number(18,0);

BEGIN

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

    stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Start i2b2_rename_node',0,stepCt,'Done');

    if old_node != ''  and old_node != '%' and new_node != ''  and new_node != '%' then
	--	Update tm_concept_counts paths
	update i2b2metadata.tm_concept_counts cc
	set CONCEPT_PATH = replace(cc.concept_path, '\' || old_node || '\', '\' || new_node || '\'),
	parent_concept_path = replace(cc.parent_concept_path, '\' || old_node || '\', '\' || new_node || '\')
	where cc.concept_path in
	(select cd.concept_path from i2b2demodata.concept_dimension cd
	  where cd.sourcesystem_cd = trial_id
            and cd.concept_path like '%' || old_node || '%');
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update tm_concept_counts with new path',SQL%ROWCOUNT,stepCt,'Done');

	COMMIT;

	--Update path in i2b2_tags
	update i2b2metadata.i2b2_tags t
	   set path = replace(t.path, '\' || old_node || '\', '\' || new_node || '\')
	 where t.path in
	       (select cd.concept_path from i2b2demodata.concept_dimension cd
		 where cd.sourcesystem_cd = trial_id
		   and cd.concept_path like '%\' || old_node || '\%');
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update i2b2_tags with new path',SQL%ROWCOUNT,stepCt,'Done');

	COMMIT;

	--Update specific name
	--update concept_dimension
	--  set name_char = new_node
	--  where name_char = old_node
	--    and sourcesystem_cd = trial_id;

	--Update all paths
	update i2b2demodata.concept_dimension
	   set CONCEPT_PATH = replace(concept_path, '\' || old_node || '\', '\' || new_node || '\')
	       ,name_char=decode(name_char,old_node,new_node,name_char)
	 where
		sourcesystem_cd = trial_id
		and concept_path like '%\' || old_node || '\%';
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update concept_dimension with new path',SQL%ROWCOUNT,stepCt,'Done');

	COMMIT;

	--I2B2
	--Update specific name
	--update i2b2metadata.i2b2
	--  set c_name = new_node
	--  where c_name = old_node
	--    and c_fullname like '%' || trial_id || '%';

	--Update all paths, added updates to c_dimcode and c_tooltip instead of separate pass
	update i2b2metadata.i2b2
	   set c_fullname = replace(c_fullname, '\' || old_node || '\', '\' || new_node || '\')
	       ,c_dimcode = replace(c_dimcode, '\' || old_node || '\', '\' || new_node || '\')
	       ,c_tooltip = replace(c_tooltip, '\' || old_node || '\', '\' || new_node || '\')
	       ,c_name = decode(c_name,old_node,new_node,c_name)
	 where sourcesystem_cd = trial_id
               and c_fullname like '%\' || old_node || '\%';
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update i2b2 with new path',SQL%ROWCOUNT,stepCt,'Done');

	COMMIT;

	--Update i2b2_secure to match i2b2
	--update i2b2metadata.i2b2_secure
	--  set c_fullname = replace(c_fullname, old_node, new_node)
	--  	 ,c_dimcode = replace(c_dimcode, old_node, new_node)
	--	 ,c_tooltip = replace(c_tooltip, old_node, new_node)
	--  where
	--    c_fullname like '%' || trial_id || '%';
	--COMMIT;

	tm_cz.i2b2_load_security_data(jobID);

    END IF;
END;
/

