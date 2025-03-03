--
-- Name: vw_faceted_search; Type: VIEW; Schema: biomart; Owner: -
--
CREATE VIEW biomart.vw_faceted_search AS
    SELECT ba.bio_assay_analysis_id AS analysis_id
	   , be.bio_experiment_id AS study
	   , be.bio_experiment_id AS study_id
	   , ba.analysis_type AS analyses
	   , ba.bio_assay_data_type AS data_type
	   , bplat.platform_accession AS platform
	   , bplat.platform_description
	   , bplat.platform_vendor
	   , baap.platform_name
	   , ('OBS:'::text || (bpobs.obs_code)::text) AS observation
	   , be.title AS study_title
	   , be.description AS study_description
	   , be.design AS study_design
	   , be.primary_investigator AS study_primary_inv
	   , be.contact_field AS study_contact_field
	   , be.overall_design AS study_overall_design
	   , be.institution AS study_institution
	   , be.accession AS study_accession
	   , be.country AS study_country
	   , be.biomarker_type AS study_biomarker_type
	   , be.target AS study_target
	   , be.access_type AS study_access_type
	   , ba.analysis_name
	   , ba.short_description AS analysis_description_s
	   , ba.long_description AS analysis_description_l
	   , ba.analysis_type
	   , ba.analyst_name AS analysis_analyst_name
	   , ba.analysis_method_cd AS analysis_method
	   , ba.bio_assay_data_type AS analysis_data_type
	   , ba.qa_criteria AS analysis_qa_criteria
	   , bae.model_name, bae.model_desc AS model_description
	   , bae.research_unit
	   , row_number() OVER (ORDER BY ba.bio_assay_analysis_id) AS facet_id
      FROM (((((((biomart.bio_assay_analysis ba
		  JOIN biomart.bio_experiment be
			  ON (((ba.etl_id)::text = (be.accession)::text)))
		  LEFT JOIN biomart.bio_assay_analysis_ext bae
			  ON ((bae.bio_assay_analysis_id = ba.bio_assay_analysis_id)))
		  LEFT JOIN biomart.bio_data_platform bdplat
			  ON ((ba.bio_assay_analysis_id = bdplat.bio_data_id)))
		  LEFT JOIN biomart.bio_assay_platform bplat
			  ON ((bdplat.bio_assay_platform_id = bplat.bio_assay_platform_id)))
		  LEFT JOIN biomart.bio_data_observation bdpobs
			  ON ((ba.bio_assay_analysis_id = bdpobs.bio_data_id)))
		  LEFT JOIN biomart.bio_observation bpobs
			  ON ((bdpobs.bio_observation_id = bpobs.bio_observation_id)))
		  LEFT JOIN biomart.bio_asy_analysis_pltfm baap
			  ON ((baap.bio_asy_analysis_pltfm_id = ba.bio_asy_analysis_pltfm_id)))
     WHERE (lower((be.bio_experiment_type)::text) = 'experiment'::text);

