--
-- Name: bio_assay_analysis_data_new; Type: TABLE; Schema: tm_wz; Owner: -
--
CREATE TABLE bio_assay_analysis_data_new (
    bio_asy_analysis_data_id int,
    fold_change_ratio int,
    raw_pvalue double precision,
    adjusted_pvalue double precision,
    r_value double precision,
    rho_value double precision,
    bio_assay_analysis_id int,
    adjusted_p_value_code character varying(100),
    feature_group_name character varying(100),
    bio_experiment_id int,
    bio_assay_platform_id int,
    etl_id character varying(100),
    preferred_pvalue double precision,
    cut_value double precision,
    results_value character varying(100),
    numeric_value double precision,
    numeric_value_code character varying(50),
    tea_normalized_pvalue double precision,
    bio_assay_feature_group_id int,
    lsmean1 double precision,
    lsmean2 double precision
);

