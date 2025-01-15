--
-- Name: lt_protein_annotation; Type: TABLE; Schema: tm_lz; Owner: -
--
CREATE TABLE lt_protein_annotation (
    gpl_id character varying(50),
    peptide character varying(200),
    uniprot_id character varying(200),
    biomarker_id int,
    organism character varying(100)
);

