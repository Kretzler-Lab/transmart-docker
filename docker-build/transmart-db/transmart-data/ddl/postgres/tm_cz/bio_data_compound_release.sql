--
-- Name: bio_data_compound_release; Type: TABLE; Schema: tm_cz; Owner: -
--
CREATE TABLE bio_data_compound_release (
    bio_data_id int NOT NULL,
    bio_compound_id int NOT NULL,
    etl_source character varying(100),
    release_study character varying(100)
);

