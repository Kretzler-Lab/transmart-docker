--
-- Name: search_taxonomy; Type: TABLE; Schema: searchapp; Owner: -
--
CREATE TABLE search_taxonomy (
    term_id int NOT NULL,
    term_name character varying(900) NOT NULL,
    source_cd character varying(900),
    import_date timestamp DEFAULT now(),
    search_keyword_id int
);

--
-- Name: search_taxonomy_pk; Type: CONSTRAINT; Schema: searchapp; Owner: -
--
ALTER TABLE ONLY search_taxonomy
    ADD CONSTRAINT search_taxonomy_pk PRIMARY KEY (term_id);

--
-- Name: tf_trg_search_taxonomy_term_id(); Type: FUNCTION; Schema: searchapp; Owner: -
--
CREATE FUNCTION tf_trg_search_taxonomy_term_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.term_id is null then
	select nextval('searchapp.seq_search_data_id') into new.term_id;
    end if;
    return new;
end;
$$;

--
-- Name: trg_search_taxonomy_term_id; Type: TRIGGER; Schema: searchapp; Owner: -
--
CREATE TRIGGER trg_search_taxonomy_term_id BEFORE INSERT ON search_taxonomy FOR EACH ROW EXECUTE PROCEDURE tf_trg_search_taxonomy_term_id();

--
-- Name: fk_search_tax_search_keyword; Type: FK CONSTRAINT; Schema: searchapp; Owner: -
--
ALTER TABLE ONLY search_taxonomy
    ADD CONSTRAINT fk_search_tax_search_keyword FOREIGN KEY (search_keyword_id) REFERENCES search_keyword(search_keyword_id);

