--
-- Name: search_auth_user; Type: TABLE; Schema: searchapp; Owner: -
--
CREATE TABLE search_auth_user (
    id int NOT NULL,
    email character varying(255),
    email_show boolean,
    passwd character varying(255),
    user_real_name character varying(255),
    username character varying(255),
    federated_id character varying(255),
    change_passwd boolean,
    login_attempt_count int DEFAULT 0
);

--
-- Name: sau_fed_id_key; Type: CONSTRAINT; Schema: searchapp; Owner: -
--
ALTER TABLE ONLY search_auth_user
    ADD CONSTRAINT sau_fed_id_key UNIQUE (federated_id);

--
-- Name: search_auth_user_pk; Type: CONSTRAINT; Schema: searchapp; Owner: -
--
ALTER TABLE ONLY search_auth_user
    ADD CONSTRAINT search_auth_user_pk PRIMARY KEY (id);

--
-- Name: sh_auth_user_id_fk; Type: FK CONSTRAINT; Schema: searchapp; Owner: -
--
ALTER TABLE ONLY search_auth_user
    ADD CONSTRAINT sh_auth_user_id_fk FOREIGN KEY (id) REFERENCES search_auth_principal(id);

