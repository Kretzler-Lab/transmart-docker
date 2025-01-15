--
-- Name: cta_results; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE cta_results (
    bio_assay_analysis_id int,
    search_keyword_id int,
    keyword character varying(400),
    bio_marker_id int,
    bio_marker_name character varying(200),
    gene_id character varying(100),
    probe_id character varying(100),
    fold_change double precision,
    preferred_pvalue double precision,
    organism character varying(100)
);

