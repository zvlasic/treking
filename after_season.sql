--
-- PostgreSQL database dump
--

\restrict 2tO5yCdRxqibUfD1gitkafshLVuoVZqq8GVPPkfd8ksBSzA2WOMSyCWWdZXHUZL

-- Dumped from database version 18.3 (Homebrew)
-- Dumped by pg_dump version 18.4 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender AS ENUM (
    'm',
    'f'
);


ALTER TYPE public.gender OWNER TO postgres;

--
-- Name: race_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.race_category AS ENUM (
    'active',
    'challenger',
    'marathon',
    'ultra'
);


ALTER TYPE public.race_category OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: races; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.races (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    date date NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.races OWNER TO postgres;

--
-- Name: results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.results (
    id uuid NOT NULL,
    runner_id uuid NOT NULL,
    race_id uuid NOT NULL,
    "position" integer,
    category public.race_category,
    dnf boolean DEFAULT false,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    points integer
);


ALTER TABLE public.results OWNER TO postgres;

--
-- Name: runners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.runners (
    id uuid NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    birth_year integer,
    country character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    gender public.gender
);


ALTER TABLE public.runners OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Data for Name: races; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.races (id, name, date, inserted_at, updated_at) FROM stdin;
\.


--
-- Data for Name: results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.results (id, runner_id, race_id, "position", category, dnf, inserted_at, updated_at, points) FROM stdin;
\.


--
-- Data for Name: runners; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.runners (id, first_name, last_name, birth_year, country, inserted_at, updated_at, gender) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, inserted_at) FROM stdin;
20231212091217	2025-11-03 08:05:57
20231212091221	2025-11-03 08:05:57
20231212091226	2025-11-03 08:05:57
20231213123240	2025-11-03 08:05:57
20231219100702	2025-11-03 08:05:57
\.


--
-- Name: races races_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.races
    ADD CONSTRAINT races_pkey PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: runners runners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.runners
    ADD CONSTRAINT runners_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: results_runner_id_race_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX results_runner_id_race_id_index ON public.results USING btree (runner_id, race_id);


--
-- Name: results results_race_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_race_id_fkey FOREIGN KEY (race_id) REFERENCES public.races(id) ON DELETE CASCADE;


--
-- Name: results results_runner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_runner_id_fkey FOREIGN KEY (runner_id) REFERENCES public.runners(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 2tO5yCdRxqibUfD1gitkafshLVuoVZqq8GVPPkfd8ksBSzA2WOMSyCWWdZXHUZL

