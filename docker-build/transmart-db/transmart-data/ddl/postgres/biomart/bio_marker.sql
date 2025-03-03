--
-- Name: bio_marker; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_marker (
    bio_marker_id int NOT NULL,
    bio_marker_name character varying(200),
    bio_marker_description character varying(1000),
    organism character varying(100),
    primary_source_code character varying(200),
    primary_external_id character varying(200),
    bio_marker_type character varying(200) NOT NULL
);

--
-- Name: bio_marker_pk; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_marker
    ADD CONSTRAINT bio_marker_pk PRIMARY KEY (bio_marker_id);

--
-- Name: biomarker_uk; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_marker
    ADD CONSTRAINT biomarker_uk UNIQUE (organism, primary_external_id);

--
-- Name: bio_mkr_ext_id; Type: INDEX; Schema: biomart; Owner: -
--
CREATE INDEX bio_mkr_ext_id ON bio_marker USING btree (primary_external_id);

--
-- Name: bio_mkr_type_idx; Type: INDEX; Schema: biomart; Owner: -
--
CREATE INDEX bio_mkr_type_idx ON bio_marker USING btree (bio_marker_type);

--
-- Name: tf_trg_bio_marker_id(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION tf_trg_bio_marker_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.bio_marker_id is null then
        select nextval('biomart.seq_bio_data_id') into new.bio_marker_id ;
    end if;
    return new;
end;
$$;

--
-- Name: trg_bio_marker_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_marker_id BEFORE INSERT ON bio_marker FOR EACH ROW EXECUTE PROCEDURE tf_trg_bio_marker_id();

