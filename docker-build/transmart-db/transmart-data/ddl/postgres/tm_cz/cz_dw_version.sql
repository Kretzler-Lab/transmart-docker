--
-- Name: cz_dw_version; Type: TABLE; Schema: tm_cz; Owner: -
--
CREATE TABLE cz_dw_version (
    dw_version_id int NOT NULL,
    version_name character varying(200),
    release_date timestamp,
    create_date timestamp,
    created_by int,
    is_current character(1)
);

--
-- Name: cz_dw_version_pk; Type: CONSTRAINT; Schema: tm_cz; Owner: -
--
ALTER TABLE ONLY cz_dw_version
    ADD CONSTRAINT cz_dw_version_pk PRIMARY KEY (dw_version_id);

--
-- Name: tf_trg_cz_dw_version_id(); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE FUNCTION tf_trg_cz_dw_version_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.dw_version_id is null then
	select nextval('tm_cz.seq_cz_dw_version_id') into new.dw_version_id ;
    end if;

    return new;
end;
$$;

--
-- Name: trg_cz_dw_version_id; Type: TRIGGER; Schema: tm_cz; Owner: -
--
CREATE TRIGGER trg_cz_dw_version_id BEFORE INSERT ON cz_dw_version FOR EACH ROW EXECUTE PROCEDURE tf_trg_cz_dw_version_id();

--
-- Name: seq_cz_dw_version_id; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE seq_cz_dw_version_id
    START WITH 41
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 2;

