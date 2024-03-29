--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: global_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE global_settings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    identifier text NOT NULL,
    value_boolean boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: global_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: global_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE global_settings_id_seq OWNED BY global_settings.id;


--
-- Name: que_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE que_jobs (
    priority smallint DEFAULT 100 NOT NULL,
    run_at timestamp with time zone DEFAULT now() NOT NULL,
    job_id bigint NOT NULL,
    job_class text NOT NULL,
    args json DEFAULT '[]'::json NOT NULL,
    error_count integer DEFAULT 0 NOT NULL,
    last_error text,
    queue text DEFAULT ''::text NOT NULL
);


--
-- Name: TABLE que_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE que_jobs IS '3';


--
-- Name: que_jobs_job_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE que_jobs_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: que_jobs_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE que_jobs_job_id_seq OWNED BY que_jobs.job_id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: staff_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE staff_members (
    id integer NOT NULL,
    name text,
    email citext,
    phone text,
    job_title text,
    location text,
    department text,
    sub_department text,
    row_html text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disappeared_at timestamp without time zone
);


--
-- Name: staff_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE staff_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE staff_members_id_seq OWNED BY staff_members.id;


--
-- Name: sync_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sync_attempts (
    id integer NOT NULL,
    user_id integer,
    error_message text,
    events_created integer DEFAULT 0 NOT NULL,
    events_deleted integer DEFAULT 0 NOT NULL,
    started_at timestamp without time zone NOT NULL,
    finished_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    triggered_manually boolean DEFAULT true NOT NULL,
    events_updated integer DEFAULT 0 NOT NULL
);


--
-- Name: sync_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sync_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sync_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sync_attempts_id_seq OWNED BY sync_attempts.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    google_uid text,
    auth_hash jsonb DEFAULT '{}'::jsonb NOT NULL,
    oauth_refresh_token text,
    oauth_access_token text,
    oauth_access_token_expires_at timestamp without time zone,
    my_tcd_username text,
    my_tcd_last_attempt_at timestamp without time zone,
    my_tcd_login_success boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    encrypted_my_tcd_password text,
    encrypted_my_tcd_password_iv text,
    invited_by_user_id integer,
    joined_at timestamp without time zone,
    email text NOT NULL,
    auto_sync_enabled boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    invite_email_at timestamp without time zone,
    blocked_as_staff_member boolean,
    exam_page_student_number text,
    exam_page_student_name text,
    exam_page_student_course_year text,
    exam_page_course text,
    last_user_agent text,
    last_login_at timestamp without time zone,
    id_code text
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: global_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY global_settings ALTER COLUMN id SET DEFAULT nextval('global_settings_id_seq'::regclass);


--
-- Name: que_jobs job_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY que_jobs ALTER COLUMN job_id SET DEFAULT nextval('que_jobs_job_id_seq'::regclass);


--
-- Name: staff_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY staff_members ALTER COLUMN id SET DEFAULT nextval('staff_members_id_seq'::regclass);


--
-- Name: sync_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sync_attempts ALTER COLUMN id SET DEFAULT nextval('sync_attempts_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: global_settings global_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY global_settings
    ADD CONSTRAINT global_settings_pkey PRIMARY KEY (id);


--
-- Name: que_jobs que_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY que_jobs
    ADD CONSTRAINT que_jobs_pkey PRIMARY KEY (queue, priority, run_at, job_id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: staff_members staff_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY staff_members
    ADD CONSTRAINT staff_members_pkey PRIMARY KEY (id);


--
-- Name: sync_attempts sync_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sync_attempts
    ADD CONSTRAINT sync_attempts_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_global_settings_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_global_settings_on_identifier ON global_settings USING btree (identifier);


--
-- Name: index_staff_members_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_members_on_email ON staff_members USING btree (email);


--
-- Name: index_sync_attempts_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_attempts_on_finished_at ON sync_attempts USING btree (finished_at);


--
-- Name: index_sync_attempts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sync_attempts_on_user_id ON sync_attempts USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_google_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_google_uid ON users USING btree (google_uid);


--
-- Name: index_users_on_id_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_id_code ON users USING btree (id_code);


--
-- Name: que_jobs_args_0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_jobs_args_0 ON que_jobs USING btree (((args ->> 0)));


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160927143053'),
('20161018113229'),
('20161018224616'),
('20161019214527'),
('20161020230639'),
('20161022004528'),
('20161022005041'),
('20161023100135'),
('20161026073219'),
('20170203000827'),
('20170203011649'),
('20170203013416'),
('20170213172139'),
('20170221010100'),
('20170308174615'),
('20170330010747'),
('20171025192909'),
('20171130134323'),
('20180205234437');


