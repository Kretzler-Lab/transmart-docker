--
-- Name: de_snp_data_by_probe; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE de_snp_data_by_probe (
    snp_data_by_probe_id int NOT NULL,
    probe_id int,
    probe_name character varying(255),
    snp_id int,
    snp_name character varying(255),
    trial_name character varying(100),
    data_by_probe text
);

--
-- Name: de_snp_data_by_probe_pk; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_snp_data_by_probe
    ADD CONSTRAINT de_snp_data_by_probe_pk PRIMARY KEY (snp_data_by_probe_id);

--
-- Name: tf_trg_snp_data_by_probe_id(); Type: FUNCTION; Schema: deapp; Owner: -
--
CREATE FUNCTION tf_trg_snp_data_by_probe_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.snp_data_by_probe_id is null then
        select nextval('deapp.seq_data_id') into new.snp_data_by_probe_id ;
    end if;
    return new;
end;
$$;

--
-- Name: trg_snp_data_by_probe_id; Type: TRIGGER; Schema: deapp; Owner: -
--
CREATE TRIGGER trg_snp_data_by_probe_id BEFORE INSERT ON de_snp_data_by_probe FOR EACH ROW EXECUTE PROCEDURE tf_trg_snp_data_by_probe_id();

--
-- Name: fk_snp_by_probe_probe_id; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_snp_data_by_probe
    ADD CONSTRAINT fk_snp_by_probe_probe_id FOREIGN KEY (probe_id) REFERENCES de_snp_probe(snp_probe_id);

--
-- Name: fk_snp_by_probe_snp_id; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_snp_data_by_probe
    ADD CONSTRAINT fk_snp_by_probe_snp_id FOREIGN KEY (snp_id) REFERENCES de_snp_info(snp_info_id);

