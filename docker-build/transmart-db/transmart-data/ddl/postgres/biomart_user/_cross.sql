--
-- Name: browse_analyses_view; Type: VIEW; Schema: biomart_user; Owner: -
--
CREATE VIEW browse_analyses_view AS
    SELECT fd.unique_id AS id
	   ,baa.analysis_name AS title
	   ,baa.long_description AS description
	   ,string_agg((bap.platform_type)::text, '|'::text ORDER BY (bap.platform_type)::text) AS measurement_type
	   ,string_agg((bap.platform_name)::text, '|'::text ORDER BY (bap.platform_name)::text) AS platform_name
	   ,string_agg((bap.platform_vendor)::text, '|'::text ORDER BY (bap.platform_vendor)::text) AS vendor
	   ,string_agg((bap.platform_technology)::text, '|'::text ORDER BY (bap.platform_technology)::text) AS technology
      FROM (((((((biomart.bio_assay_analysis baa
		  JOIN biomart.bio_data_uid bd
			  ON ((baa.bio_assay_analysis_id = bd.bio_data_id)))
		  JOIN fmapp.fm_folder_association fa
			  ON (((fa.object_uid)::text = (bd.unique_id)::text)))
		  JOIN fmapp.fm_data_uid fd
			  ON ((fa.folder_id = fd.fm_data_id)))
		  JOIN fmapp.fm_folder ff
			  ON ((ff.folder_id = fa.folder_id)))
		  LEFT JOIN amapp.am_tag_association ata
			  ON (((fd.unique_id)::text = (ata.subject_uid)::text)))
		  LEFT JOIN biomart.bio_data_uid bdu
			  ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
		  LEFT JOIN biomart.bio_assay_platform bap
			  ON ((bap.bio_assay_platform_id = bdu.bio_data_id)))
     WHERE (((ata.object_type)::text = 'BIO_ASSAY_PLATFORM'::text)
	    AND ff.active_ind)
     GROUP BY fd.unique_id, baa.analysis_name, baa.long_description;

--
-- Name: browse_folders_view; Type: VIEW; Schema: biomart_user; Owner: -
--
CREATE VIEW browse_folders_view AS
    SELECT fd.unique_id AS id
	   ,f.folder_name AS title
	   ,f.description
	   ,string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS file_type
      FROM ((fmapp.fm_folder f
	     JOIN fmapp.fm_data_uid fd
		     ON ((f.folder_id = fd.fm_data_id)))
	     LEFT JOIN amapp.am_tag_association ata
		     ON (((fd.unique_id)::text = (ata.subject_uid)::text)))
     WHERE (((((f.folder_type)::text = 'FOLDER'::text)
	      AND f.active_ind)
	      AND ((ata.object_type)::text = 'BIO_CONCEPT_CODE'::text))
	      AND ((ata.object_uid)::text ~~ 'FILE_TYPE%'::text))
     GROUP BY fd.unique_id, f.folder_name, f.description;

--
-- Name: browse_assays_view; Type: VIEW; Schema: biomart_user; Owner: -
--
CREATE VIEW browse_assays_view AS
    SELECT DISTINCT fd.unique_id AS id
		    ,f.folder_name AS title
		    ,f.description
		    ,string_agg((bap.platform_type)::text, '|'::text ORDER BY (bap.platform_type)::text) AS measurement_type
		    ,string_agg((bap.platform_name)::text, '|'::text ORDER BY (bap.platform_name)::text) AS platform_name
		    ,string_agg((bap.platform_vendor)::text, '|'::text ORDER BY (bap.platform_vendor)::text) AS vendor
		    ,string_agg((bap.platform_technology)::text, '|'::text ORDER BY (bap.platform_technology)::text) AS technology
		    ,bio_markers_gene.object_uids AS gene
		    ,bio_markers_mirna.object_uids AS mirna
		    ,biomarker_types.object_uids AS biomarker_type
		    ,biosource.object_uids AS biosource
      FROM ((((((((fmapp.fm_folder f
		   JOIN fmapp.fm_data_uid fd ON ((f.folder_id = fd.fm_data_id)))
		   LEFT JOIN amapp.am_tag_association ata
			   ON ((((fd.unique_id)::text = (ata.subject_uid)::text)
				AND ((ata.object_type)::text = 'BIO_ASSAY_PLATFORM'::text))))
		   LEFT JOIN biomart.bio_data_uid bdu
			   ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
		   LEFT JOIN biomart.bio_assay_platform bap
			   ON ((bap.bio_assay_platform_id = bdu.bio_data_id)))
		   LEFT JOIN
		   (SELECT fdu.unique_id AS id
			   , string_agg((ata_1.object_uid)::text, '|'::text ORDER BY (ata_1.object_uid)::text) AS object_uids
		      FROM ((fmapp.fm_folder ff
			     JOIN fmapp.fm_data_uid fdu
				     ON ((ff.folder_id = fdu.fm_data_id)))
			     JOIN amapp.am_tag_association ata_1
				     ON (((fdu.unique_id)::text = (ata_1.subject_uid)::text)))
		     WHERE (((ata_1.object_type)::text = 'BIO_MARKER'::text)
			    AND (substr(ata_1.object_uid, 1, instr( ata_1.object_uid, ':' ) - 1 ) = 'GENE'::text)
			    AND ((ff.folder_type)::text = 'ASSAY'::text))
		     GROUP BY fdu.unique_id) bio_markers_gene
			   ON (((bio_markers_gene.id)::text = (fd.unique_id)::text)))
		     LEFT JOIN
		     (SELECT fdu.unique_id AS id
			     , string_agg((ata_1.object_uid)::text, '|'::text ORDER BY (ata_1.object_uid)::text) AS object_uids
			FROM ((fmapp.fm_folder ff
			       JOIN fmapp.fm_data_uid fdu
				       ON ((ff.folder_id = fdu.fm_data_id)))
			       JOIN amapp.am_tag_association ata_1
				       ON (((fdu.unique_id)::text = (ata_1.subject_uid)::text)))
		       WHERE (((ata_1.object_type)::text = 'BIO_MARKER'::text)
			      AND (substr(ata_1.object_uid, 1, instr( ata_1.object_uid, ':' ) - 1 ) = 'MIRNA'::text)
			      AND ((ff.folder_type)::text = 'ASSAY'::text))
		       GROUP BY fdu.unique_id) bio_markers_mirna
			     ON (((bio_markers_mirna.id)::text = (fd.unique_id)::text)))
		       LEFT JOIN
		       (SELECT fdu.unique_id AS id
			       , string_agg((ata_1.object_uid)::text, '|'::text ORDER BY (ata_1.object_uid)::text) AS object_uids
			  FROM ((fmapp.fm_folder ff
				 JOIN fmapp.fm_data_uid fdu
					 ON ((ff.folder_id = fdu.fm_data_id)))
				 JOIN amapp.am_tag_association ata_1
					 ON (((fdu.unique_id)::text = (ata_1.subject_uid)::text)))
			 WHERE (((ata_1.object_type)::text = 'BIOSOURCE'::text)
				AND ((ff.folder_type)::text = 'ASSAY'::text))
			 GROUP BY fdu.unique_id) biosource
			       ON (((biosource.id)::text = (fd.unique_id)::text)))
			 LEFT JOIN
			 (SELECT fdu.unique_id AS id
				 ,string_agg((ata_1.object_uid)::text, '|'::text ORDER BY (ata_1.object_uid)::text) AS object_uids
			    FROM (((fmapp.fm_folder ff
				    JOIN fmapp.fm_data_uid fdu
					    ON ((ff.folder_id = fdu.fm_data_id)))
				    JOIN amapp.am_tag_association ata_1
					    ON (((fdu.unique_id)::text = (ata_1.subject_uid)::text)))
				    JOIN amapp.am_tag_item ati
					    ON ((ata_1.tag_item_id = ati.tag_item_id)))
			   WHERE ((((ata_1.object_type)::text = 'BIO_CONCEPT_CODE'::text)
				   AND ((ati.code_type_name)::text = 'ASSAY_BIOMARKER_TYPE'::text))
				   AND ((ff.folder_type)::text = 'ASSAY'::text))
			   GROUP BY fdu.unique_id) biomarker_types
				 ON (((biomarker_types.id)::text = (fd.unique_id)::text)))
     WHERE (((f.folder_type)::text = 'ASSAY'::text)
	    AND f.active_ind)
     GROUP BY fd.unique_id, f.folder_name, f.description, bio_markers_gene.object_uids, bio_markers_mirna.object_uids, biosource.object_uids, biomarker_types.object_uids;

--
-- Name: browse_programs_view; Type: VIEW; Schema: biomart_user; Owner: -
--
CREATE VIEW browse_programs_view AS
    SELECT fd.unique_id AS id
	   ,f.folder_name AS title
	   ,f.description
	   ,diseases.object_uids AS disease
	   ,observations.object_uids AS observation
	   ,pathways.object_uids AS pathway
	   ,genes.object_uids AS gene
	   ,therapeutic_domains.object_uids AS therapeutic_domain
	   ,institutions.object_uids AS institution
	   ,targets.object_uids AS target
      FROM ((((((((fmapp.fm_folder f
		   JOIN fmapp.fm_data_uid fd
			   ON ((f.folder_id = fd.fm_data_id)))
		   LEFT JOIN
		   (SELECT fdu.unique_id AS id
			   , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
		      FROM ((((fmapp.fm_folder ff
			       JOIN fmapp.fm_data_uid fdu
				       ON ((ff.folder_id = fdu.fm_data_id)))
			       JOIN amapp.am_tag_association ata
				       ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
			       JOIN biomart.bio_data_uid bdu
				       ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
			       JOIN biomart.bio_disease bd
				       ON ((bd.bio_disease_id = bdu.bio_data_id)))
		     WHERE (((ata.object_type)::text = ANY (ARRAY[('BIO_DISEASE'::character varying)::text, ('PROGRAM_TARGET'::character varying)::text]))
			    AND ((ff.folder_type)::text = 'PROGRAM'::text))
		     GROUP BY fdu.unique_id) diseases
			   ON (((diseases.id)::text = (fd.unique_id)::text)))
		     LEFT JOIN
		     (SELECT fdu.unique_id AS id
			     ,string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			FROM ((((fmapp.fm_folder ff
				 JOIN fmapp.fm_data_uid fdu
					 ON ((ff.folder_id = fdu.fm_data_id)))
				 JOIN amapp.am_tag_association ata
					 ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				 JOIN biomart.bio_data_uid bdu
					 ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
				 JOIN biomart.bio_observation bo
					 ON ((bo.bio_observation_id = bdu.bio_data_id)))
		       WHERE (((ata.object_type)::text = ANY (ARRAY[('BIO_OBSERVATION'::character varying)::text, ('PROGRAM_TARGET'::character varying)::text]))
			      AND ((ff.folder_type)::text = 'PROGRAM'::text))
		       GROUP BY fdu.unique_id) observations
			     ON (((observations.id)::text = (fd.unique_id)::text)))
		       LEFT JOIN
		       (SELECT fdu.unique_id AS id
			       , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			  FROM ((((fmapp.fm_folder ff
				   JOIN fmapp.fm_data_uid fdu
					   ON ((ff.folder_id = fdu.fm_data_id)))
				   JOIN amapp.am_tag_association ata
					   ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				   JOIN biomart.bio_data_uid bdu
					   ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
				   JOIN biomart.bio_marker bm
					   ON ((bm.bio_marker_id = bdu.bio_data_id)))
			 WHERE ((((bm.bio_marker_type)::text = 'PATHWAY'::text)
				 AND (((ata.object_type)::text = 'BIO_MARKER'::text)
				      OR ((ata.object_type)::text = 'PROGRAM_TARGET'::text)))
				      AND ((ff.folder_type)::text = 'PROGRAM'::text))
			 GROUP BY fdu.unique_id) pathways
			       ON (((pathways.id)::text = (fd.unique_id)::text)))
			 LEFT JOIN
			 (SELECT fdu.unique_id AS id
				 ,string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			    FROM ((((fmapp.fm_folder ff
				     JOIN fmapp.fm_data_uid fdu
					     ON ((ff.folder_id = fdu.fm_data_id)))
				     JOIN amapp.am_tag_association ata
					     ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				     JOIN biomart.bio_data_uid bdu
					     ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
				     JOIN biomart.bio_marker bm
					     ON ((bm.bio_marker_id = bdu.bio_data_id)))
			   WHERE ((((bm.bio_marker_type)::text = 'GENE'::text)
				   AND (((ata.object_type)::text = 'BIO_MARKER'::text)
					OR ((ata.object_type)::text = 'PROGRAM_TARGET'::text)))
					AND ((ff.folder_type)::text = 'PROGRAM'::text))
			   GROUP BY fdu.unique_id) genes
				 ON (((genes.id)::text = (fd.unique_id)::text)))
			   LEFT JOIN
			   (SELECT fdu.unique_id AS id
				   ,string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			      FROM (((((fmapp.fm_folder ff
					JOIN fmapp.fm_data_uid fdu
						ON ((ff.folder_id = fdu.fm_data_id)))
					JOIN amapp.am_tag_association ata
						ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
					JOIN amapp.am_tag_item ati
						ON ((ata.tag_item_id = ati.tag_item_id)))
					JOIN biomart.bio_data_uid bdu
						ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
					JOIN biomart.bio_concept_code bcc
						ON ((bcc.bio_concept_code_id = bdu.bio_data_id)))
			     WHERE ((((ata.object_type)::text = ANY (ARRAY[('BIO_CONCEPT_CODE'::character varying)::text, ('PROGRAM_TARGET'::character varying)::text]))
				     AND ((ff.folder_type)::text = 'PROGRAM'::text))
				     AND ((ati.code_type_name)::text = 'THERAPEUTIC_DOMAIN'::text))
			     GROUP BY fdu.unique_id) therapeutic_domains
				   ON (((therapeutic_domains.id)::text = (fd.unique_id)::text)))
			     LEFT JOIN
			     (SELECT fdu.unique_id AS id
				     ,string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
				FROM (((((fmapp.fm_folder ff
					  JOIN fmapp.fm_data_uid fdu
						  ON ((ff.folder_id = fdu.fm_data_id)))
					  JOIN amapp.am_tag_association ata
						  ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
					  JOIN amapp.am_tag_item ati
						  ON ((ata.tag_item_id = ati.tag_item_id)))
					  JOIN biomart.bio_data_uid bdu
						  ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
					  JOIN biomart.bio_concept_code bcc
						  ON ((bcc.bio_concept_code_id = bdu.bio_data_id)))
			       WHERE ((((ata.object_type)::text = ANY (ARRAY[('BIO_CONCEPT_CODE'::character varying)::text, ('PROGRAM_TARGET'::character varying)::text]))
				       AND ((ff.folder_type)::text = 'PROGRAM'::text))
				       AND ((ati.code_type_name)::text = 'PROGRAM_INSTITUTION'::text))
			       GROUP BY fdu.unique_id) institutions
				     ON (((institutions.id)::text = (fd.unique_id)::text)))
				     LEFT JOIN
				     (SELECT fdu.unique_id AS id
					     , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
				  FROM (((((fmapp.fm_folder ff
					    JOIN fmapp.fm_data_uid fdu
						    ON ((ff.folder_id = fdu.fm_data_id)))
					    JOIN amapp.am_tag_association ata
						    ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
					    JOIN amapp.am_tag_item ati
						    ON ((ata.tag_item_id = ati.tag_item_id)))
					    JOIN biomart.bio_data_uid bdu
						    ON (((bdu.unique_id)::text = (ata.object_uid)::text)))
					    JOIN biomart.bio_concept_code bcc
						    ON ((bcc.bio_concept_code_id = bdu.bio_data_id)))
				       WHERE ((((ata.object_type)::text = ANY (ARRAY[('BIO_CONCEPT_CODE'::character varying)::text, ('PROGRAM_TARGET'::character varying)::text]))
					       AND ((ff.folder_type)::text = 'PROGRAM'::text))
					       AND ((ati.code_type_name)::text = 'PROGRAM_TARGET_PATHWAY_PHENOTYPE'::text))
				       GROUP BY fdu.unique_id) targets ON (((targets.id)::text = (fd.unique_id)::text)))
     WHERE (((f.folder_type)::text = 'PROGRAM'::text)
	    AND f.active_ind);

--
-- Name: browse_studies_view; Type: VIEW; Schema: biomart_user; Owner: -
--
CREATE VIEW browse_studies_view AS
    SELECT fd.unique_id AS id
	   ,exp.title
	   ,exp.description
	   ,exp.design
	   ,exp.biomarker_type
	   ,exp.access_type
	   ,exp.accession
	   ,exp.institution
	   ,exp.country
	   ,diseases.object_uids AS disease
	   ,compounds.object_uids AS compound
	   ,study_objectives.object_uids AS study_objective
	   ,species.object_uids AS organism
	   ,phases.object_uids AS study_phase
      FROM (((((((((biomart.bio_experiment exp
		    JOIN biomart.bio_data_uid bd
			    ON ((exp.bio_experiment_id = bd.bio_data_id)))
		    JOIN fmapp.fm_folder_association fa
			    ON (((fa.object_uid)::text = (bd.unique_id)::text)))
		    JOIN fmapp.fm_data_uid fd
			    ON ((fa.folder_id = fd.fm_data_id)))
		    JOIN fmapp.fm_folder ff
			    ON ((ff.folder_id = fa.folder_id)))
		    LEFT JOIN
		    (SELECT fdu.unique_id AS id
			    , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
		       FROM ((fmapp.fm_folder_association ffa
			      JOIN fmapp.fm_data_uid fdu
				      ON ((ffa.folder_id = fdu.fm_data_id)))
			      JOIN amapp.am_tag_association ata
				      ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
		      WHERE ((ata.object_type)::text = 'BIO_DISEASE'::text)
		      GROUP BY fdu.unique_id) diseases
			    ON (((diseases.id)::text = (fd.unique_id)::text)))
		      LEFT JOIN
		      (SELECT fdu.unique_id AS id
			      , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			 FROM ((fmapp.fm_folder_association ffa
				JOIN fmapp.fm_data_uid fdu
					ON ((ffa.folder_id = fdu.fm_data_id)))
				JOIN amapp.am_tag_association ata
					ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
			WHERE ((ata.object_type)::text = 'BIO_COMPOUND'::text)
			GROUP BY fdu.unique_id) compounds
			      ON (((compounds.id)::text = (fd.unique_id)::text)))
			LEFT JOIN
			(SELECT fdu.unique_id AS id
				, string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			   FROM (((fmapp.fm_folder_association ffa
				   JOIN fmapp.fm_data_uid fdu
					   ON ((ffa.folder_id = fdu.fm_data_id)))
				   JOIN amapp.am_tag_association ata
					   ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				   JOIN amapp.am_tag_item ati
					   ON ((ata.tag_item_id = ati.tag_item_id)))
			  WHERE (((ata.object_type)::text = 'BIO_CONCEPT_CODE'::text)
				 AND ((ati.code_type_name)::text = 'STUDY_OBJECTIVE'::text))
			  GROUP BY fdu.unique_id) study_objectives
				ON (((study_objectives.id)::text = (fd.unique_id)::text)))
			  LEFT JOIN
			  (SELECT fdu.unique_id AS id
				  , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			     FROM (((fmapp.fm_folder_association ffa
				     JOIN fmapp.fm_data_uid fdu
					     ON ((ffa.folder_id = fdu.fm_data_id)))
				     JOIN amapp.am_tag_association ata
					     ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				     JOIN amapp.am_tag_item ati
					     ON ((ata.tag_item_id = ati.tag_item_id)))
			    WHERE (((ata.object_type)::text = 'BIO_CONCEPT_CODE'::text)
				   AND ((ati.code_type_name)::text = 'SPECIES'::text))
			    GROUP BY fdu.unique_id) species
				  ON (((species.id)::text = (fd.unique_id)::text)))
			    LEFT JOIN
			    (SELECT fdu.unique_id AS id
				    , string_agg((ata.object_uid)::text, '|'::text ORDER BY (ata.object_uid)::text) AS object_uids
			       FROM (((fmapp.fm_folder_association ffa
				       JOIN fmapp.fm_data_uid fdu
					       ON ((ffa.folder_id = fdu.fm_data_id)))
				       JOIN amapp.am_tag_association ata
					       ON (((fdu.unique_id)::text = (ata.subject_uid)::text)))
				       JOIN amapp.am_tag_item ati
					       ON ((ata.tag_item_id = ati.tag_item_id)))
			      WHERE (((ata.object_type)::text = 'BIO_CONCEPT_CODE'::text)
				     AND ((ati.code_type_name)::text = 'STUDY_PHASE'::text))
			      GROUP BY fdu.unique_id) phases
				    ON (((phases.id)::text = (fd.unique_id)::text)))
     WHERE ff.active_ind;


SET default_with_oids = false;

