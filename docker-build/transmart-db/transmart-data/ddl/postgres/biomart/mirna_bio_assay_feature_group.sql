--
-- Name: mirna_bio_assay_feature_group; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE mirna_bio_assay_feature_group (
    bio_assay_feature_group_id int DEFAULT nextval('biomart.seq_bio_data_id') NOT NULL,
    feature_group_name character varying(100) NOT NULL,
    feature_group_type character varying(50) NOT NULL
);

--
-- Name: mirna_bio_asy_feature_grp_pk; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY mirna_bio_assay_feature_group
    ADD CONSTRAINT mirna_bio_asy_feature_grp_pk PRIMARY KEY (bio_assay_feature_group_id);

