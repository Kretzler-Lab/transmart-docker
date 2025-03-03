-----------------------------------------------------------------------
--             DO NOT EDIT THIS FILE. IT IS AUTOGENERATED            --
-- Edit the original file in the macroed_functions directory instead --
-----------------------------------------------------------------------
-- Generated by Ora2Pg, the Oracle database Schema converter, version 11.4
-- Copyright 2000-2013 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=mydb.mydom.fr;sid=SIDNAME


CREATE OR REPLACE FUNCTION tm_cz.rwg_load_analysis_metadata (
	trialID                  text,
	i_study_data_category    text   DEFAULT 'Study',
	i_study_category_display text   DEFAULT null,
	currentJobID             bigint DEFAULT null,
	rtn_code                 OUT    bigint
)
RETURNS bigint AS $body$
DECLARE

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
  --Audit variables
	newJobFlag    smallint;
	databaseName  varchar(100);
	procedureName varchar(100);
	jobID         bigint;
	stepCt        bigint;
	rowCt         bigint;
	errorNumber   varchar;
	errorMessage  varchar;

	Dcount        integer;
	lcount        integer;
	analysisCount integer;
	resultCount   integer;
	innerRet      bigint;

BEGIN
	--Set Audit Parameters
	newJobFlag := 0; -- False (Default)
	jobID := currentJobID;
	select current_user INTO databaseName; --(sic)
	procedureName := 'rwg_load_analysis_metadata';

	--Audit JOB Initialization
	--If Job ID does not exist, then this is a single procedure run and we need to create it
	IF (coalesce(jobID::text, '') = '' OR jobID < 1)
		THEN
		newJobFlag := 1; -- True
		SELECT tm_cz.cz_start_audit(procedureName, databaseName) INTO jobID;
	END IF;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Start FUNCTION', 0, stepCt, 'Done');
	stepCt := 1;

	/*
	 * Before starting, ensure that the incoming analysis IDs match to the
	 * biomart.bio_assay_analysis name.
	 * If not, try to match using the short_desc. Update the analysis_name if
	 * this work; otherwise, quit
	 */
    /*
	 * NOTE: Due to a change in the curation/etl procedures, this step should no
	 * longer be needed.  The bio_assay_analysis_id is updated in
	 * TM_LZ.Rwg_Analysis at time of creation. A check is done, and if the IDs
	 * match, then this step is bypassed
	 */


	-- get the count of the incoming analysis data
	BEGIN
	SELECT count(*)
	INTO analysisCount
	FROM tm_lz.rwg_analysis
	WHERE study_id =  Upper(trialID);

	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Analysis count from TM_LZ.Rwg_Analysis =(see count)', analysisCount, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	--see how many of the analysees match by using the cohort analysis name
	BEGIN
	SELECT
		COUNT ( * )
		INTO resultCount
	FROM
		tm_lz.rwg_analysis analysis,
		biomart.bio_assay_analysis baa
	WHERE
		analysis.bio_assay_analysis_id = baa.bio_assay_analysis_id --bio_assay_analysis_id in 'TM_LZ.Rwg_Analysis analysis' should already exist
		AND UPPER ( analysis.study_id ) = UPPER ( trialID );

	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Join analysis.Cohorts to Baa.Analysis_Name, Analysis count =(see count)', resultCount, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	IF analysisCount != resultCount THEN
	  RAISE 'Analysis count mismatch' USING ERRCODE = 'AA001';
	END IF;


	BEGIN
	DELETE FROM Biomart.Bio_Analysis_Cohort_Xref WHERE upper(study_id) = upper(trialID);

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Delete existing records from Biomart.Bio_Analysis_Cohort_Xref', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	BEGIN
	DELETE FROM Biomart.Bio_Analysis_Attribute_Lineage Baal
	WHERE Baal.Bio_Analysis_Attribute_Id IN
	(SELECT DISTINCT Baa.Bio_Analysis_Attribute_Id
	FROM Biomart.Bio_Analysis_Attribute baa WHERE upper(study_id) = upper(trialID));

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Delete existing records from Biomart.Bio_Analysis_Attribute_Lineage', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	BEGIN
	DELETE FROM Biomart.Bio_Analysis_Attribute  WHERE upper(study_id) = upper(trialID);

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Delete existing records from Biomart.Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	/** Delete study from biomart.bio_assay_cohort table **/
	BEGIN
	DELETE FROM Biomart.Bio_Assay_Cohort WHERE upper(study_id) = upper(trialID);

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Delete existing records from Biomart.Bio_Assay_Cohort', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	/** Populate biomart.bio_assay_cohort table **/
	BEGIN
	INSERT INTO Biomart.Bio_Assay_Cohort (
		Study_Id,
		Cohort_Id,
		Disease,
		Sample_Type,
		Treatment,
		Organism,
		Pathology,
		Cohort_Title,
		Short_Desc,
		Long_Desc,
		Import_Date )
	SELECT
		Study_Id,
		Cohort_Id,
		Disease,
		Sample_Type,
		Treatment,
		Organism,
		Pathology,
		Cohort_Title,
		Short_Desc,
		Long_Desc,
		now()
	FROM
		tm_lz.rwg_cohorts
	WHERE
		UPPER ( Study_Id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert into Biomart.Bio_Assay_Cohort', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	SELECT coalesce(Max(Length(Regexp_Replace(analysis.Cohorts,'[^;]','g'))),0)+1
	INTO dcount
	FROM tm_lz.rwg_analysis analysis;

	FOR lcount IN 1 .. dcount
		LOOP

		BEGIN
		perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting Bio_Analysis_Cohort_Xref LOOP, pass: ',lcount,stepCt,'Done');
		INSERT INTO Biomart.Bio_Analysis_Cohort_Xref(
			Study_Id,
			Analysis_Cd,
			Cohort_Id,
			Bio_Assay_Analysis_Id
		)
		SELECT
			upper(analysis.Study_Id),
			analysis.Cohorts,
			trim(tm_cz.parse_nth_value(analysis.Cohorts,lcount,';')) AS cohort,
			baa.bio_assay_analysis_id
		FROM tm_lz.rwg_analysis analysis, biomart.bio_assay_analysis baa
		WHERE analysis.bio_assay_analysis_id= Baa.bio_assay_analysis_id
			AND Upper(Baa.Etl_Id) LIKE '%' || Upper(Trialid) || '%'
			AND Upper(analysis.Study_Id) LIKE '%' || Upper(Trialid) || '%'
			AND Trim(tm_cz.parse_nth_value(analysis.Cohorts,lcount,';')) IS NOT NULL;

		GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert COHORTS into  into Biomart.Bio_Analysis_Cohort_Xref', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;
	END LOOP;


	/*************************************/
	/** POPULATE Bio_Analysis_Attribute **/
	/*************************************/
	--	delete study from tm_cz.cz_rwg_invalid_terms 20121220 JEA
	BEGIN
	DELETE FROM tm_cz.cz_rwg_invalid_terms
	WHERE upper(study_id) = upper(trialID);

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Delete existing data from tm_cz.cz_rwg_invalid_terms', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	--	insert study as search_term term, sp will check if already exists
	SELECT rwg_add_search_term(upper(trialID),i_study_data_category,i_study_category_display,jobId) INTO innerRet;
	IF innerRet <> 0
		THEN
		errorNumber := '000000';
		errorMessage := 'RWG_ADD_SEARCH_TERM() failed. Arguments: ' ||
				upper(trialID) || ', ' || i_study_data_category ||
				', ' || i_study_category_display  || ', ' || jobId;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END IF;

	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert study as search_term', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;

	BEGIN
	-- sample_type: check for any records that do not have a match in the taxonomy
	INSERT INTO tm_cz.cz_rwg_invalid_terms(
		Study_Id,
		Category_Name,
		Term_Name)
	SELECT DISTINCT
		upper(Cohort.Study_Id),
		upper('sample_type'),
		cohort.sample_type
	FROM tm_lz.rwg_cohorts cohort
	WHERE upper(Cohort.Study_Id)=upper(trialID)
		AND NOT EXISTS
			(SELECT Upper(Tax.Term_Name) FROM Searchapp.Search_Taxonomy Tax
			 WHERE Upper(Cohort.sample_type) = Upper(Tax.Term_Name));

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'sample_type: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- sample_type: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute(
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd)
	SELECT DISTINCT
		upper(Cohort.Study_Id),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id, Upper('sample_type:' || Cohort.sample_type)
	FROM
		tm_lz.rwg_cohorts cohort,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE upper(Cohort.Cohort_Id) = upper(Xref.Cohort_Id)
		AND upper(Xref.Study_Id) = upper(Cohort.Study_Id)
		AND Upper(Cohort.Sample_Type) = Upper(Tax.Term_Name)
		AND Cohort.Study_Id =upper(trialID);

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert SAMPLE_TYPE into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- disease: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ),
		'disease',
		cohort.disease
	FROM
		tm_lz.rwg_cohorts cohort
	WHERE
		UPPER ( Cohort.Study_Id )
		= UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( Cohort.disease ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'disease: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- disease: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ) ,
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'disease:' || Cohort.disease )
	FROM
		tm_lz.rwg_cohorts cohort,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Cohort.Cohort_Id ) = UPPER ( Xref.Cohort_Id )
		AND UPPER ( Xref.Study_Id ) = UPPER ( Cohort.Study_Id )
		AND UPPER ( Cohort.Disease ) = UPPER ( Tax.Term_Name )
		AND UPPER ( cohort.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert disease into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- pathology: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ),
		'pathology',
		cohort.pathology
	FROM
		tm_lz.rwg_cohorts cohort
	where
		UPPER ( Cohort.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( Cohort.pathology ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'pathology: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- pathology: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'pathology:' || Cohort.pathology )
	FROM
		tm_lz.rwg_cohorts cohort,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Cohort.Cohort_Id ) = UPPER ( Xref.Cohort_Id )
		AND UPPER ( Xref.Study_Id ) = UPPER ( Cohort.Study_Id )
		AND UPPER ( Cohort.Pathology ) = UPPER ( Tax.Term_Name )
		AND UPPER ( cohort.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert pathology into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- LOOP FOR TREATMENT
	SELECT coalesce(Max(Length(Regexp_Replace(Cohort.Treatment,'[^;]', 'g'))),0)+1
	INTO Dcount
	FROM tm_lz.rwg_cohorts cohort
	WHERE upper(Cohort.Study_Id)=upper(trialID);
	FOR lcount IN 1 .. dcount
		LOOP
		stepCt := stepCt + 1;
		perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting COHORT TREATMENT LOOP, pass: ',lcount,stepCt,'Done');

		-- treatment: check for any records that do not have a match in the taxonomy
		BEGIN
		INSERT INTO tm_cz.cz_rwg_invalid_terms (
			Study_Id,
			Category_Name,
			Term_Name )
		SELECT
			DISTINCT UPPER ( Cohort.Study_Id ) ,
			'treatment',
			TRIM ( tm_cz.parse_nth_value ( cohort.treatment, lcount, ';' ) )
		FROM
			tm_lz.rwg_cohorts cohort
		WHERE
			UPPER ( Cohort.Study_Id ) = UPPER ( trialID )
			AND NOT EXISTS (
				SELECT
					UPPER ( Tax.Term_Name )
				FROM
					Searchapp.Search_Taxonomy Tax
				WHERE
					UPPER ( TRIM ( tm_cz.parse_nth_value ( cohort.treatment, lcount, ';' ) ) )
					= UPPER ( Tax.Term_Name ) )
			AND TRIM ( tm_cz.parse_nth_value ( cohort.treatment, lcount, ';' ) ) IS NOT NULL;

		-- treatment: insert terms into attribute table
		INSERT INTO biomart.bio_analysis_attribute (
			study_id,
			bio_assay_analysis_id,
			term_id,
			source_cd )
		SELECT DISTINCT
			UPPER ( cohort.study_id ) ,
			xref.bio_assay_analysis_id,
			tax.term_id,
			UPPER ( 'treatment:' || TRIM ( tm_cz.parse_nth_value ( cohort.treatment,
						lcount,
						';' ) ) )
		FROM
			tm_lz.rwg_cohorts cohort,
			biomart.bio_analysis_cohort_xref xref,
			searchapp.search_taxonomy tax
		WHERE
			UPPER ( cohort.cohort_id ) = UPPER ( xref.cohort_id )
			AND UPPER ( xref.study_id ) = UPPER ( cohort.study_id )
			AND UPPER ( TRIM ( tm_cz.parse_nth_value ( cohort.treatment, lcount, ';' ) ) )
				= UPPER ( tax.term_name )
			AND UPPER ( cohort.study_id ) = UPPER ( trialid );

		GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert treatment into Bio_Analysis_Attribute (LOOP)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	END LOOP;

	stepCt := stepCt + 1;
	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(Jobid,Databasename,Procedurename,'END TREATMENT LOOP',rowCt,stepCt,'Done');
	-- END TREATMENT LOOP

	-- organism: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ) ,
		'organism',
		Cohort.organism
	FROM
		tm_lz.rwg_cohorts cohort
	WHERE
		UPPER ( Cohort.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( Cohort.organism ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'organism: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- organism: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Cohort.Study_Id ),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'organism:' || Cohort.Organism )
	FROM
		TM_lz.rwg_cohorts cohort,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Cohort.Cohort_Id ) = UPPER ( Xref.Cohort_Id )
		AND UPPER ( Xref.Study_Id ) = UPPER ( Cohort.Study_Id )
		AND UPPER ( Cohort.Organism ) = UPPER ( Tax.Term_Name )
		AND UPPER ( cohort.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert organism into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- data_type: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( analysis.Study_Id ),
		'data_type',
		analysis.data_type
	FROM
		tm_lz.rwg_analysis analysis
	WHERE
		UPPER ( analysis.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( analysis.data_type ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'data_type: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- data_type: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT
		UPPER ( analysis.Study_Id ),
		Baa.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'data_type:' || analysis.Data_Type )
	FROM
		tm_lz.rwg_analysis analysis,
		searchapp.search_taxonomy tax,
		biomart.bio_assay_analysis baa
	WHERE
		UPPER ( analysis.Data_Type ) = UPPER ( Tax.Term_Name )
		AND analysis.bio_assay_analysis_id = Baa.bio_assay_analysis_id
		AND UPPER ( Baa.Etl_Id )
			LIKE '%' || UPPER ( analysis.Study_Id ) || '%'
		AND UPPER ( analysis.Study_Id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert data_type into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- platform: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		study_id,
		category_name,
		term_name )
	SELECT DISTINCT
		analysis.Study_Id,
		'platform',
		analysis.platform
	FROM
		tm_lz.rwg_analysis analysis
	WHERE
		UPPER ( analysis.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( analysis.platform ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'platform: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- platform: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT
		UPPER ( analysis.Study_Id ),
		Baa.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'platform:' || analysis.Platform )
	FROM
		tm_lz.rwg_analysis analysis,
		searchapp.search_taxonomy tax,
		biomart.bio_assay_analysis baa
	WHERE
		UPPER ( analysis.Platform ) = UPPER ( Tax.Term_Name )
		AND analysis.bio_assay_analysis_id = Baa.bio_assay_analysis_id
		AND UPPER ( Baa.Etl_Id )
			LIKE '%' || UPPER ( analysis.Study_Id ) || '%'
		AND UPPER ( analysis.Study_Id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert platform into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- LOOP FOR ANALYSIS TYPE
	SELECT coalesce(Max(Length(Regexp_Replace(analysis.Analysis_Type,'[^;]', 'g'))),0)+1
	INTO Dcount
	FROM tm_lz.rwg_analysis analysis
	WHERE upper(analysis.Study_Id)=upper(trialID);

	FOR Lcount IN 1 .. Dcount
		LOOP
		stepCt := stepCt + 1;
		perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Starting ANALYSIS_TYPE LOOP, pass: ',lcount,stepCt,'Done');

		-- Analysis_Type: check for any records that do not have a match in the taxonomy
		BEGIN
		INSERT INTO tm_cz.cz_rwg_invalid_terms (
			Study_Id,
			Category_Name,
			Term_Name )
		SELECT DISTINCT
			UPPER ( analysis.Study_Id ),
			'Analysis_Type',
			TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type, lcount, ';' ) )
		FROM
			tm_lz.rwg_analysis analysis
		WHERE
			UPPER ( analysis.Study_Id ) = UPPER ( trialID )
			AND NOT EXISTS (
				SELECT
					UPPER ( Tax.Term_Name )
				FROM
					Searchapp.Search_Taxonomy Tax
				WHERE
					UPPER ( TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type, Lcount, ';' ) ) )
						= UPPER ( Tax.Term_Name ) )
			AND TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type, Lcount, ';' ) ) IS NOT NULL;

		-- Analysis_Type: insert terms into attribute table
		INSERT INTO Biomart.Bio_Analysis_Attribute (
			Study_Id,
			Bio_Assay_Analysis_Id,
			Term_Id,
			Source_Cd )
		SELECT
			UPPER ( analysis.study_id ),
			baa.bio_assay_analysis_id,
			tax.term_id,
			UPPER ( 'ANALYSIS_TYPE:' || TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type,
						lcount,
						';' ) ) )
		FROM
			tm_lz.rwg_analysis analysis,
			searchapp.search_taxonomy tax,
			biomart.bio_assay_analysis baa
		WHERE
			UPPER ( TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type,
						Lcount,
						';' ) ) )
				= UPPER ( Tax.Term_Name )
			AND analysis.bio_assay_analysis_id = Baa.bio_assay_analysis_id
			AND UPPER ( Baa.Etl_Id )
				LIKE '%' || UPPER ( analysis.Study_Id ) || '%'
			AND UPPER ( analysis.Study_Id ) = UPPER ( Trialid )
			AND TRIM ( tm_cz.parse_nth_value ( analysis.Analysis_Type, Lcount, ';' ) ) IS NOT NULL;

		GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'LOOP: Insert ANALYSIS_TYPE into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;
	END LOOP;

	stepCt := stepCt + 1;
	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(Jobid,Databasename,Procedurename,'END ANALYSIS_TYPE LOOP',rowCt,stepCt,'Done');
	-- END ANALYSIS TYPE

	-- search_area: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( ext.Study_Id ),
		'search_area',
		ext.search_area
	FROM
		tm_lz.clinical_trial_metadata_ext ext
	WHERE
		UPPER ( ext.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( ext.search_area ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'search_area: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- search_area: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Ext.Study_Id ),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'search_area:' || Ext.search_area )
	FROM
		tm_lz.clinical_trial_metadata_ext ext,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Xref.Study_Id ) = UPPER ( ext.Study_Id )
		AND UPPER ( Ext.Search_Area ) = UPPER ( Tax.Term_Name )
		AND UPPER ( ext.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert search_area into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- data source: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( ext.Study_Id ),
		'DATA_SOURCE',
		ext.data_source
	FROM
		tm_lz.clinical_trial_metadata_ext ext
	WHERE
		UPPER ( ext.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( ext.data_source ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'data source: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- data source: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Ext.Study_Id ),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'DATA_SOURCE:' || Ext.data_source )
	FROM
		tm_lz.clinical_trial_metadata_ext ext,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Xref.Study_Id ) = UPPER ( ext.Study_Id )
		AND UPPER ( Ext.data_source ) = UPPER ( Tax.Term_Name )
		AND UPPER ( ext.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert DATA_SOURCE into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- study_design: check for any records that do not have a match in the taxonomy
	BEGIN
	INSERT INTO tm_cz.cz_rwg_invalid_terms (
		Study_Id,
		Category_Name,
		Term_Name )
	SELECT DISTINCT
		UPPER ( ext.Study_Id ),
		'study_design',
		ext.study_design
	FROM
		tm_lz.clinical_trial_metadata_ext ext
	WHERE
		UPPER ( ext.Study_Id ) = UPPER ( trialID )
		AND NOT EXISTS (
			SELECT
				UPPER ( Tax.Term_Name )
			FROM
				Searchapp.Search_Taxonomy Tax
			WHERE
				UPPER ( ext.experimental_design ) = UPPER ( Tax.Term_Name ) );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'study design: register invalid terms (with no match in the taxonomy)', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	-- study_design: insert terms into attribute table
	BEGIN
	INSERT INTO Biomart.Bio_Analysis_Attribute (
		Study_Id,
		Bio_Assay_Analysis_Id,
		Term_Id,
		Source_Cd )
	SELECT DISTINCT
		UPPER ( Ext.Study_Id ),
		Xref.Bio_Assay_Analysis_Id,
		Tax.Term_Id,
		UPPER ( 'study_design:' || Ext.experimental_design )
	FROM
		tm_lz.clinical_trial_metadata_ext ext,
		biomart.bio_analysis_cohort_xref xref,
		searchapp.search_taxonomy tax
	WHERE
		UPPER ( Xref.Study_Id ) = UPPER ( ext.Study_Id )
		AND UPPER ( ( CASE
					WHEN Ext.experimental_design = 'Clinical' THEN 'Clinical Trial'
					ELSE ext.experimental_design
				END ) )
			= UPPER ( Tax.Term_Name )
		AND UPPER ( ext.study_id ) = UPPER ( trialID );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert study_design into Bio_Analysis_Attribute', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;

	--	populate biomart.bio_analysis_attribute_lineage in one shot
	BEGIN
	INSERT INTO biomart.bio_analysis_attribute_lineage (
		bio_analysis_attribute_id,
		ancestor_term_id,
		ancestor_search_keyword_id )
	SELECT
		baa.bio_analysis_attribute_id,
		baa.term_id,
		st.search_keyword_id
	FROM
		biomart.bio_analysis_attribute baa,
		searchapp.search_taxonomy st
	WHERE
		UPPER ( baa.study_id ) = UPPER ( trialID )
		AND baa.term_id = st.term_id;

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Insert attribute links into bio_analysis_attribute_lineage', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;
	/* END populate */

	/*Update the 'analysis_update_date' in bio_assay_analysis (this date is used by solr for incremental updates*/
	BEGIN
	UPDATE BIOMART.bio_assay_analysis baa
	SET
		ANALYSIS_UPDATE_DATE = now()
	WHERE
		UPPER ( baa.etl_id ) LIKE UPPER ( trialID || '%' );

	GET DIAGNOSTICS rowCt := ROW_COUNT;
	perform tm_cz.cz_write_audit(jobId, databaseName, procedureName,
		'Update ANALYSIS_UPDATE_DATE with LOCALTIMESTAMP', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
	END;
	perform tm_cz.cz_write_audit(jobId,databaseName,procedureName,'End FUNCTION',0,stepCt,'Done');

	---Cleanup OVERALL JOB if this proc is being run standalone
	IF newJobFlag = 1
		THEN
		perform tm_cz.cz_end_audit (jobID, 'SUCCESS');
	END IF;
EXCEPTION
	WHEN SQLSTATE 'AA001' then
		stepCt := stepCt + 1;
		GET DIAGNOSTICS rowCt := ROW_COUNT;
		perform tm_cz.cz_write_audit(Jobid,Databasename,Procedurename,'ERR: Check for analysis in rwg_analysis not in biomart.bio_assay_analysis',rowCt,stepCt,'Done');
		--Handle errors.
		perform tm_cz.cz_error_handler (jobID, procedureName, SQLSTATE, SQLERRM);
		--End Proc
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := 16;
	WHEN OTHERS THEN
	errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		perform tm_cz.cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		perform tm_cz.cz_end_audit (jobID, 'FAIL');
		rtn_code := -16;
		RETURN;
END;

$body$
LANGUAGE PLPGSQL;

