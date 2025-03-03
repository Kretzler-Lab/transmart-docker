--
-- Name: bio_assay; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay (
    bio_assay_id int NOT NULL,
    etl_id character varying(100) NOT NULL,
    study character varying(200),
    protocol character varying(200),
    description text,
    sample_type character varying(100),
    experiment_id int NOT NULL,
    test_date timestamp,
    sample_receive_date timestamp,
    requestor character varying(200),
    bio_assay_type character varying(200) NOT NULL,
    bio_assay_platform_id int,
    biosource character varying(200),
    measurement_type character varying(200),
    technology character varying(200),
    vendor character varying(200),
    platform_design character varying(200),
    biomarkers_studied character varying(200),
    biomarkers_type character varying(200)
);

--
-- Name: bio_assay_pk; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay
    ADD CONSTRAINT bio_assay_pk PRIMARY KEY (bio_assay_id);

--
-- Name: tf_trg_bio_assay_id(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION tf_trg_bio_assay_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.bio_assay_id is null then
        select nextval('biomart.seq_bio_data_id') into new.bio_assay_id ;
    end if;
    return new;
end;
$$;

--
-- Name: trg_bio_assay_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_assay_id BEFORE INSERT ON bio_assay FOR EACH ROW EXECUTE PROCEDURE tf_trg_bio_assay_id();

--
-- Name: bio_asy_asy_pfm_fk; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay
    ADD CONSTRAINT bio_asy_asy_pfm_fk FOREIGN KEY (bio_assay_platform_id) REFERENCES bio_assay_platform(bio_assay_platform_id);

--
-- Name: dataset_experiment_fk; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay
    ADD CONSTRAINT dataset_experiment_fk FOREIGN KEY (experiment_id) REFERENCES bio_experiment(bio_experiment_id);

