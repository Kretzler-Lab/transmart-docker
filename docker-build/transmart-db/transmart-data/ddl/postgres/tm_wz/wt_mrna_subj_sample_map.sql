--
-- Name: wt_mrna_subj_sample_map; Type: TABLE; Schema: tm_wz; Owner: -
--
CREATE TABLE wt_mrna_subj_sample_map (
    trial_name character varying(100),
    site_id character varying(100),
    subject_id character varying(100),
    sample_cd character varying(100),
    platform character varying(100),
    tissue_type character varying(100),
    attribute_1 character varying(256),
    attribute_2 character varying(200),
    category_cd character varying(2000)
);

