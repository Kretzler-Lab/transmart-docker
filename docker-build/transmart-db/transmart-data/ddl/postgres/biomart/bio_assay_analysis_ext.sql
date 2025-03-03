--
-- Name: bio_assay_analysis_ext; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay_analysis_ext (
    bio_assay_analysis_ext_id int NOT NULL,
    bio_assay_analysis_id int NOT NULL,
    vendor character varying(500),
    vendor_type character varying(500),
    genome_version character varying(500),
    tissue character varying(500),
    cell_type character varying(500),
    population character varying(500),
    research_unit character varying(500),
    sample_size character varying(500),
    model_name character varying(100),
    model_desc character varying(500),
    sensitive_flag int,
    sensitive_desc character varying(500)
);

--
-- Name: bio_assay_analysis_ext_idx1; Type: INDEX; Schema: biomart; Owner: -
--
CREATE INDEX bio_assay_analysis_ext_idx1 ON bio_assay_analysis_ext USING btree (bio_assay_analysis_id);
