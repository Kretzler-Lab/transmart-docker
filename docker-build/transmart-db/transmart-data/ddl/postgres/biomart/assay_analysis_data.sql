--
-- Name: assay_analysis_data; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE assay_analysis_data (
    bio_asy_analysis_data_id int NOT NULL,
    bio_experiment_id int,
    bio_assay_platform_id int,
    bio_assay_analysis_id int,
    bio_assay_feature_group_id int,
    feature_group_name character varying(100),
    tea_normalized_pvalue double precision,
    fold_change_ratio int,
    raw_pvalue double precision,
    adjusted_pvalue double precision,
    preferred_pvalue double precision
);

--
-- Name: assay_analysis_data_pk; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY assay_analysis_data
    ADD CONSTRAINT assay_analysis_data_pk PRIMARY KEY (bio_asy_analysis_data_id);

