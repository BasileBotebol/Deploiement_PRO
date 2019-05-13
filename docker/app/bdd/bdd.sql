PGDMP         (                w        	   BD_Budget    11.2    11.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    17354 	   BD_Budget    DATABASE     �   CREATE DATABASE "BD_Budget" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'French_Switzerland.1252' LC_CTYPE = 'French_Switzerland.1252';
    DROP DATABASE "BD_Budget";
             postgres    false            �            1255    17355 $   add_sous_cat_perso(integer, integer) 	   PROCEDURE     �   CREATE PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer)
    LANGUAGE sql
    AS $$INSERT INTO public.sous_categories_personnelles (utilisateur_id, sous_categorie_id)
VALUES (user_id, sous_cat_id);
$$;
 P   DROP PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer);
       public       postgres    false            �            1255    17356    modifSoldeExpense()    FUNCTION     e  CREATE FUNCTION public."modifSoldeExpense"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE public.utilisateur AS util
SET solde = solde - NEW.valeur
FROM public.modele_transaction AS mt 
WHERE NEW.modele_transaction_id = mt.modele_transaction_id AND mt.type_transaction_id = 1 AND mt.utilisateur_id = util.utilisateur_id;
RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public."modifSoldeExpense"();
       public       postgres    false            �           0    0    FUNCTION "modifSoldeExpense"()    COMMENT     n   COMMENT ON FUNCTION public."modifSoldeExpense"() IS 'Modifie le solde de l''utilisateur lors d''une depense';
            public       postgres    false    226            �            1255    17357    modifSoldeIncome()    FUNCTION     d  CREATE FUNCTION public."modifSoldeIncome"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE public.utilisateur as util
SET solde = solde + NEW.valeur
FROM public.modele_transaction AS mt 
WHERE NEW.modele_transaction_id = mt.modele_transaction_id AND mt.type_transaction_id = 2 AND mt.utilisateur_id = util.utilisateur_id;
RETURN NEW;
END;
$$;
 +   DROP FUNCTION public."modifSoldeIncome"();
       public       postgres    false            �           0    0    FUNCTION "modifSoldeIncome"()    COMMENT     r   COMMENT ON FUNCTION public."modifSoldeIncome"() IS 'Modifie le solde de l''utilisateur quand un revenu est cree';
            public       postgres    false    227            �            1255    17358    transactionCreation()    FUNCTION     ^  CREATE FUNCTION public."transactionCreation"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	solde_timestamp NUMERIC(10,2);
BEGIN
SELECT solde FROM public.utilisateur WHERE NEW.utilisateur_id = utilisateur_id INTO solde_timestamp;
IF NEW.type_transaction_id = 1
	THEN solde_timestamp = solde_timestamp - NEW.valeur;
	END IF;
IF NEW.type_transaction_id = 2
	THEN solde_timestamp = solde_timestamp + NEW.valeur;
	END IF;
INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
VALUES(NEW.valeur, NOW(), NEW.modele_transaction_id, solde_timestamp);
RETURN NEW;
END;
$$;
 .   DROP FUNCTION public."transactionCreation"();
       public       postgres    false            �           0    0     FUNCTION "transactionCreation"()    COMMENT     `   COMMENT ON FUNCTION public."transactionCreation"() IS 'Creates a transaction when date is now';
            public       postgres    false    228            �           0    0     FUNCTION "transactionCreation"()    ACL     E   REVOKE ALL ON FUNCTION public."transactionCreation"() FROM postgres;
            public       postgres    false    228            �            1259    17359 	   categorie    TABLE     �   CREATE TABLE public.categorie (
    categorie_id integer NOT NULL,
    nom character varying(50) NOT NULL,
    couleur smallint
);
    DROP TABLE public.categorie;
       public         postgres    false            �            1259    17362    Categorie_categorie_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Categorie_categorie_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public."Categorie_categorie_id_seq";
       public       postgres    false    196            �           0    0    Categorie_categorie_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public."Categorie_categorie_id_seq" OWNED BY public.categorie.categorie_id;
            public       postgres    false    197            �            1259    17364    limite    TABLE       CREATE TABLE public.limite (
    limite_id integer NOT NULL,
    date date NOT NULL,
    valeur numeric(10,2) NOT NULL,
    utilisateur_id integer NOT NULL,
    recurence_id integer NOT NULL,
    sous_categorie_id integer,
    categorie_id integer NOT NULL
);
    DROP TABLE public.limite;
       public         postgres    false            �            1259    17367    Limite_limite_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Limite_limite_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public."Limite_limite_id_seq";
       public       postgres    false    198            �           0    0    Limite_limite_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public."Limite_limite_id_seq" OWNED BY public.limite.limite_id;
            public       postgres    false    199            �            1259    17369    modele_transaction    TABLE     3  CREATE TABLE public.modele_transaction (
    modele_transaction_id integer NOT NULL,
    valeur numeric(10,2) NOT NULL,
    date date NOT NULL,
    note text,
    utilisateur_id integer NOT NULL,
    sous_categorie_id integer NOT NULL,
    type_transaction_id integer NOT NULL,
    recurrence_id integer
);
 &   DROP TABLE public.modele_transaction;
       public         postgres    false            �            1259    17375 ,   Modele_transaction_modele_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Modele_transaction_modele_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 E   DROP SEQUENCE public."Modele_transaction_modele_transaction_id_seq";
       public       postgres    false    200            �           0    0 ,   Modele_transaction_modele_transaction_id_seq    SEQUENCE OWNED BY        ALTER SEQUENCE public."Modele_transaction_modele_transaction_id_seq" OWNED BY public.modele_transaction.modele_transaction_id;
            public       postgres    false    201            �            1259    17377    notification    TABLE     �   CREATE TABLE public.notification (
    notification_id integer NOT NULL,
    titre character varying(30) NOT NULL,
    message character varying,
    utilisateur_id integer NOT NULL
);
     DROP TABLE public.notification;
       public         postgres    false            �            1259    17383     Notification_notification_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Notification_notification_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public."Notification_notification_id_seq";
       public       postgres    false    202            �           0    0     Notification_notification_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public."Notification_notification_id_seq" OWNED BY public.notification.notification_id;
            public       postgres    false    203            �            1259    17385    options    TABLE     d   CREATE TABLE public.options (
    options_id integer NOT NULL,
    rappel_email boolean NOT NULL
);
    DROP TABLE public.options;
       public         postgres    false            �            1259    17388    Options_options_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Options_options_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public."Options_options_id_seq";
       public       postgres    false    204            �           0    0    Options_options_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public."Options_options_id_seq" OWNED BY public.options.options_id;
            public       postgres    false    205            �            1259    17390    pays    TABLE     c   CREATE TABLE public.pays (
    pays_id integer NOT NULL,
    nom character varying(50) NOT NULL
);
    DROP TABLE public.pays;
       public         postgres    false            �            1259    17393    Pays_pays_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Pays_pays_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public."Pays_pays_id_seq";
       public       postgres    false    206            �           0    0    Pays_pays_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public."Pays_pays_id_seq" OWNED BY public.pays.pays_id;
            public       postgres    false    207            �            1259    17395 	   recurence    TABLE     u   CREATE TABLE public.recurence (
    recurence_id integer NOT NULL,
    periodicite character varying(20) NOT NULL
);
    DROP TABLE public.recurence;
       public         postgres    false            �            1259    17398    Recurence_recurence_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Recurence_recurence_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public."Recurence_recurence_id_seq";
       public       postgres    false    208            �           0    0    Recurence_recurence_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public."Recurence_recurence_id_seq" OWNED BY public.recurence.recurence_id;
            public       postgres    false    209            �            1259    17400    sous_categorie    TABLE     �   CREATE TABLE public.sous_categorie (
    sous_categorie_id integer NOT NULL,
    nom character varying(70) NOT NULL,
    categorie_id integer NOT NULL,
    is_global boolean NOT NULL
);
 "   DROP TABLE public.sous_categorie;
       public         postgres    false            �            1259    17403 $   Sous_categorie_sous_categorie_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Sous_categorie_sous_categorie_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public."Sous_categorie_sous_categorie_id_seq";
       public       postgres    false    210            �           0    0 $   Sous_categorie_sous_categorie_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public."Sous_categorie_sous_categorie_id_seq" OWNED BY public.sous_categorie.sous_categorie_id;
            public       postgres    false    211            �            1259    17405    statut    TABLE     g   CREATE TABLE public.statut (
    statut_id integer NOT NULL,
    nom character varying(30) NOT NULL
);
    DROP TABLE public.statut;
       public         postgres    false            �            1259    17408    Statut_statut_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Statut_statut_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public."Statut_statut_id_seq";
       public       postgres    false    212            �           0    0    Statut_statut_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public."Statut_statut_id_seq" OWNED BY public.statut.statut_id;
            public       postgres    false    213            �            1259    17410    transaction    TABLE     �   CREATE TABLE public.transaction (
    transaction_id integer NOT NULL,
    valeur numeric(10,2) NOT NULL,
    date date NOT NULL,
    modele_transaction_id integer NOT NULL,
    timestamp_solde numeric(10,2) NOT NULL
);
    DROP TABLE public.transaction;
       public         postgres    false            �            1259    17413    Transaction_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Transaction_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public."Transaction_transaction_id_seq";
       public       postgres    false    214            �           0    0    Transaction_transaction_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public."Transaction_transaction_id_seq" OWNED BY public.transaction.transaction_id;
            public       postgres    false    215            �            1259    17415    type_transaction    TABLE     |   CREATE TABLE public.type_transaction (
    type_transaction_id integer NOT NULL,
    type character varying(20) NOT NULL
);
 $   DROP TABLE public.type_transaction;
       public         postgres    false            �            1259    17418 (   Type_transaction_type_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Type_transaction_type_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 A   DROP SEQUENCE public."Type_transaction_type_transaction_id_seq";
       public       postgres    false    216            �           0    0 (   Type_transaction_type_transaction_id_seq    SEQUENCE OWNED BY     w   ALTER SEQUENCE public."Type_transaction_type_transaction_id_seq" OWNED BY public.type_transaction.type_transaction_id;
            public       postgres    false    217            �            1259    17420    utilisateur    TABLE       CREATE TABLE public.utilisateur (
    utilisateur_id integer NOT NULL,
    prenom character varying(30) NOT NULL,
    nom character varying(30) NOT NULL,
    email character varying(50) NOT NULL,
    pseudo character varying(20) NOT NULL,
    mdp character varying(60) NOT NULL,
    genre boolean,
    anniversaire date NOT NULL,
    cree_a timestamp without time zone DEFAULT now(),
    droit_id integer NOT NULL,
    statut_id integer,
    pays_id integer,
    options_id integer NOT NULL,
    solde numeric(10,2) NOT NULL
);
    DROP TABLE public.utilisateur;
       public         postgres    false            �            1259    17424    Utilisateur_utilisateur_id_seq    SEQUENCE     �   CREATE SEQUENCE public."Utilisateur_utilisateur_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public."Utilisateur_utilisateur_id_seq";
       public       postgres    false    218            �           0    0    Utilisateur_utilisateur_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public."Utilisateur_utilisateur_id_seq" OWNED BY public.utilisateur.utilisateur_id;
            public       postgres    false    219            �            1259    17426    droit    TABLE     e   CREATE TABLE public.droit (
    droit_id integer NOT NULL,
    nom character varying(20) NOT NULL
);
    DROP TABLE public.droit;
       public         postgres    false            �            1259    17429    droit_droit_id_seq    SEQUENCE     �   CREATE SEQUENCE public.droit_droit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.droit_droit_id_seq;
       public       postgres    false    220            �           0    0    droit_droit_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.droit_droit_id_seq OWNED BY public.droit.droit_id;
            public       postgres    false    221            �            1259    17431    sous_categories_personnelles    TABLE     �   CREATE TABLE public.sous_categories_personnelles (
    sous_categorie_id integer NOT NULL,
    utilisateur_id integer NOT NULL
);
 0   DROP TABLE public.sous_categories_personnelles;
       public         postgres    false            �            1259    17434    test    TABLE     K   CREATE TABLE public.test (
    testt integer NOT NULL,
    swag integer
);
    DROP TABLE public.test;
       public         postgres    false            �            1259    17437    test_testt_seq    SEQUENCE     �   CREATE SEQUENCE public.test_testt_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.test_testt_seq;
       public       postgres    false    223            �           0    0    test_testt_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.test_testt_seq OWNED BY public.test.testt;
            public       postgres    false    224            �
           2604    17439    categorie categorie_id    DEFAULT     �   ALTER TABLE ONLY public.categorie ALTER COLUMN categorie_id SET DEFAULT nextval('public."Categorie_categorie_id_seq"'::regclass);
 E   ALTER TABLE public.categorie ALTER COLUMN categorie_id DROP DEFAULT;
       public       postgres    false    197    196            �
           2604    17440    droit droit_id    DEFAULT     p   ALTER TABLE ONLY public.droit ALTER COLUMN droit_id SET DEFAULT nextval('public.droit_droit_id_seq'::regclass);
 =   ALTER TABLE public.droit ALTER COLUMN droit_id DROP DEFAULT;
       public       postgres    false    221    220            �
           2604    17441    limite limite_id    DEFAULT     v   ALTER TABLE ONLY public.limite ALTER COLUMN limite_id SET DEFAULT nextval('public."Limite_limite_id_seq"'::regclass);
 ?   ALTER TABLE public.limite ALTER COLUMN limite_id DROP DEFAULT;
       public       postgres    false    199    198            �
           2604    17442 (   modele_transaction modele_transaction_id    DEFAULT     �   ALTER TABLE ONLY public.modele_transaction ALTER COLUMN modele_transaction_id SET DEFAULT nextval('public."Modele_transaction_modele_transaction_id_seq"'::regclass);
 W   ALTER TABLE public.modele_transaction ALTER COLUMN modele_transaction_id DROP DEFAULT;
       public       postgres    false    201    200            �
           2604    17443    notification notification_id    DEFAULT     �   ALTER TABLE ONLY public.notification ALTER COLUMN notification_id SET DEFAULT nextval('public."Notification_notification_id_seq"'::regclass);
 K   ALTER TABLE public.notification ALTER COLUMN notification_id DROP DEFAULT;
       public       postgres    false    203    202            �
           2604    17444    options options_id    DEFAULT     z   ALTER TABLE ONLY public.options ALTER COLUMN options_id SET DEFAULT nextval('public."Options_options_id_seq"'::regclass);
 A   ALTER TABLE public.options ALTER COLUMN options_id DROP DEFAULT;
       public       postgres    false    205    204            �
           2604    17445    pays pays_id    DEFAULT     n   ALTER TABLE ONLY public.pays ALTER COLUMN pays_id SET DEFAULT nextval('public."Pays_pays_id_seq"'::regclass);
 ;   ALTER TABLE public.pays ALTER COLUMN pays_id DROP DEFAULT;
       public       postgres    false    207    206            �
           2604    17446    recurence recurence_id    DEFAULT     �   ALTER TABLE ONLY public.recurence ALTER COLUMN recurence_id SET DEFAULT nextval('public."Recurence_recurence_id_seq"'::regclass);
 E   ALTER TABLE public.recurence ALTER COLUMN recurence_id DROP DEFAULT;
       public       postgres    false    209    208            �
           2604    17447     sous_categorie sous_categorie_id    DEFAULT     �   ALTER TABLE ONLY public.sous_categorie ALTER COLUMN sous_categorie_id SET DEFAULT nextval('public."Sous_categorie_sous_categorie_id_seq"'::regclass);
 O   ALTER TABLE public.sous_categorie ALTER COLUMN sous_categorie_id DROP DEFAULT;
       public       postgres    false    211    210            �
           2604    17448    statut statut_id    DEFAULT     v   ALTER TABLE ONLY public.statut ALTER COLUMN statut_id SET DEFAULT nextval('public."Statut_statut_id_seq"'::regclass);
 ?   ALTER TABLE public.statut ALTER COLUMN statut_id DROP DEFAULT;
       public       postgres    false    213    212            �
           2604    17449 
   test testt    DEFAULT     h   ALTER TABLE ONLY public.test ALTER COLUMN testt SET DEFAULT nextval('public.test_testt_seq'::regclass);
 9   ALTER TABLE public.test ALTER COLUMN testt DROP DEFAULT;
       public       postgres    false    224    223            �
           2604    17450    transaction transaction_id    DEFAULT     �   ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public."Transaction_transaction_id_seq"'::regclass);
 I   ALTER TABLE public.transaction ALTER COLUMN transaction_id DROP DEFAULT;
       public       postgres    false    215    214            �
           2604    17451 $   type_transaction type_transaction_id    DEFAULT     �   ALTER TABLE ONLY public.type_transaction ALTER COLUMN type_transaction_id SET DEFAULT nextval('public."Type_transaction_type_transaction_id_seq"'::regclass);
 S   ALTER TABLE public.type_transaction ALTER COLUMN type_transaction_id DROP DEFAULT;
       public       postgres    false    217    216            �
           2604    17452    utilisateur utilisateur_id    DEFAULT     �   ALTER TABLE ONLY public.utilisateur ALTER COLUMN utilisateur_id SET DEFAULT nextval('public."Utilisateur_utilisateur_id_seq"'::regclass);
 I   ALTER TABLE public.utilisateur ALTER COLUMN utilisateur_id DROP DEFAULT;
       public       postgres    false    219    218            �          0    17359 	   categorie 
   TABLE DATA               ?   COPY public.categorie (categorie_id, nom, couleur) FROM stdin;
    public       postgres    false    196   R�       �          0    17426    droit 
   TABLE DATA               .   COPY public.droit (droit_id, nom) FROM stdin;
    public       postgres    false    220   [�       �          0    17364    limite 
   TABLE DATA               x   COPY public.limite (limite_id, date, valeur, utilisateur_id, recurence_id, sous_categorie_id, categorie_id) FROM stdin;
    public       postgres    false    198   ��       �          0    17369    modele_transaction 
   TABLE DATA               �   COPY public.modele_transaction (modele_transaction_id, valeur, date, note, utilisateur_id, sous_categorie_id, type_transaction_id, recurrence_id) FROM stdin;
    public       postgres    false    200   ��       �          0    17377    notification 
   TABLE DATA               W   COPY public.notification (notification_id, titre, message, utilisateur_id) FROM stdin;
    public       postgres    false    202   ��       �          0    17385    options 
   TABLE DATA               ;   COPY public.options (options_id, rappel_email) FROM stdin;
    public       postgres    false    204   ��       �          0    17390    pays 
   TABLE DATA               ,   COPY public.pays (pays_id, nom) FROM stdin;
    public       postgres    false    206   ұ       �          0    17395 	   recurence 
   TABLE DATA               >   COPY public.recurence (recurence_id, periodicite) FROM stdin;
    public       postgres    false    208   �       �          0    17400    sous_categorie 
   TABLE DATA               Y   COPY public.sous_categorie (sous_categorie_id, nom, categorie_id, is_global) FROM stdin;
    public       postgres    false    210   _�       �          0    17431    sous_categories_personnelles 
   TABLE DATA               Y   COPY public.sous_categories_personnelles (sous_categorie_id, utilisateur_id) FROM stdin;
    public       postgres    false    222   �       �          0    17405    statut 
   TABLE DATA               0   COPY public.statut (statut_id, nom) FROM stdin;
    public       postgres    false    212   0�       �          0    17434    test 
   TABLE DATA               +   COPY public.test (testt, swag) FROM stdin;
    public       postgres    false    223   k�       �          0    17410    transaction 
   TABLE DATA               k   COPY public.transaction (transaction_id, valeur, date, modele_transaction_id, timestamp_solde) FROM stdin;
    public       postgres    false    214   ��       �          0    17415    type_transaction 
   TABLE DATA               E   COPY public.type_transaction (type_transaction_id, type) FROM stdin;
    public       postgres    false    216   �       �          0    17420    utilisateur 
   TABLE DATA               �   COPY public.utilisateur (utilisateur_id, prenom, nom, email, pseudo, mdp, genre, anniversaire, cree_a, droit_id, statut_id, pays_id, options_id, solde) FROM stdin;
    public       postgres    false    218   2�       �           0    0    Categorie_categorie_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public."Categorie_categorie_id_seq"', 17, true);
            public       postgres    false    197            �           0    0    Limite_limite_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public."Limite_limite_id_seq"', 1, false);
            public       postgres    false    199            �           0    0 ,   Modele_transaction_modele_transaction_id_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public."Modele_transaction_modele_transaction_id_seq"', 45, true);
            public       postgres    false    201            �           0    0     Notification_notification_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public."Notification_notification_id_seq"', 1, false);
            public       postgres    false    203            �           0    0    Options_options_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public."Options_options_id_seq"', 3, true);
            public       postgres    false    205            �           0    0    Pays_pays_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public."Pays_pays_id_seq"', 2, true);
            public       postgres    false    207            �           0    0    Recurence_recurence_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public."Recurence_recurence_id_seq"', 6, true);
            public       postgres    false    209            �           0    0 $   Sous_categorie_sous_categorie_id_seq    SEQUENCE SET     V   SELECT pg_catalog.setval('public."Sous_categorie_sous_categorie_id_seq"', 100, true);
            public       postgres    false    211            �           0    0    Statut_statut_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public."Statut_statut_id_seq"', 3, true);
            public       postgres    false    213            �           0    0    Transaction_transaction_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public."Transaction_transaction_id_seq"', 32, true);
            public       postgres    false    215            �           0    0 (   Type_transaction_type_transaction_id_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public."Type_transaction_type_transaction_id_seq"', 2, true);
            public       postgres    false    217            �           0    0    Utilisateur_utilisateur_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public."Utilisateur_utilisateur_id_seq"', 8, true);
            public       postgres    false    219            �           0    0    droit_droit_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.droit_droit_id_seq', 3, true);
            public       postgres    false    221            �           0    0    test_testt_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.test_testt_seq', 2, true);
            public       postgres    false    224            �
           2606    17454    categorie Categorie_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "Categorie_pkey" PRIMARY KEY (categorie_id);
 D   ALTER TABLE ONLY public.categorie DROP CONSTRAINT "Categorie_pkey";
       public         postgres    false    196            �
           2606    17456    limite Limite_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.limite
    ADD CONSTRAINT "Limite_pkey" PRIMARY KEY (limite_id);
 >   ALTER TABLE ONLY public.limite DROP CONSTRAINT "Limite_pkey";
       public         postgres    false    198            �
           2606    17458 *   modele_transaction Modele_transaction_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT "Modele_transaction_pkey" PRIMARY KEY (modele_transaction_id);
 V   ALTER TABLE ONLY public.modele_transaction DROP CONSTRAINT "Modele_transaction_pkey";
       public         postgres    false    200            �
           2606    17460    notification Notification_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "Notification_pkey" PRIMARY KEY (notification_id);
 J   ALTER TABLE ONLY public.notification DROP CONSTRAINT "Notification_pkey";
       public         postgres    false    202            �
           2606    17462    options Options_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.options
    ADD CONSTRAINT "Options_pkey" PRIMARY KEY (options_id);
 @   ALTER TABLE ONLY public.options DROP CONSTRAINT "Options_pkey";
       public         postgres    false    204            �
           2606    17464    pays Pays_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "Pays_pkey" PRIMARY KEY (pays_id);
 :   ALTER TABLE ONLY public.pays DROP CONSTRAINT "Pays_pkey";
       public         postgres    false    206            �
           2606    17466    recurence Recurence_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "Recurence_pkey" PRIMARY KEY (recurence_id);
 D   ALTER TABLE ONLY public.recurence DROP CONSTRAINT "Recurence_pkey";
       public         postgres    false    208            �
           2606    17468 "   sous_categorie Sous-categorie_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "Sous-categorie_pkey" PRIMARY KEY (sous_categorie_id);
 N   ALTER TABLE ONLY public.sous_categorie DROP CONSTRAINT "Sous-categorie_pkey";
       public         postgres    false    210            �
           2606    17470    statut Statut_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "Statut_pkey" PRIMARY KEY (statut_id);
 >   ALTER TABLE ONLY public.statut DROP CONSTRAINT "Statut_pkey";
       public         postgres    false    212                       2606    17472    transaction Transaction_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT "Transaction_pkey" PRIMARY KEY (transaction_id);
 H   ALTER TABLE ONLY public.transaction DROP CONSTRAINT "Transaction_pkey";
       public         postgres    false    214                       2606    17474 &   type_transaction Type_transaction_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "Type_transaction_pkey" PRIMARY KEY (type_transaction_id);
 R   ALTER TABLE ONLY public.type_transaction DROP CONSTRAINT "Type_transaction_pkey";
       public         postgres    false    216                       2606    17476    utilisateur Utilisateur_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "Utilisateur_pkey" PRIMARY KEY (utilisateur_id);
 H   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT "Utilisateur_pkey";
       public         postgres    false    218                       2606    17478    droit droit_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.droit
    ADD CONSTRAINT droit_pkey PRIMARY KEY (droit_id);
 :   ALTER TABLE ONLY public.droit DROP CONSTRAINT droit_pkey;
       public         postgres    false    220            	           2606    17480    utilisateur emailUnique 
   CONSTRAINT     U   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "emailUnique" UNIQUE (email);
 C   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT "emailUnique";
       public         postgres    false    218            �
           2606    17482    categorie nomCategorieUnique 
   CONSTRAINT     X   ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "nomCategorieUnique" UNIQUE (nom);
 H   ALTER TABLE ONLY public.categorie DROP CONSTRAINT "nomCategorieUnique";
       public         postgres    false    196                       2606    17484    droit nomDroitUnique 
   CONSTRAINT     P   ALTER TABLE ONLY public.droit
    ADD CONSTRAINT "nomDroitUnique" UNIQUE (nom);
 @   ALTER TABLE ONLY public.droit DROP CONSTRAINT "nomDroitUnique";
       public         postgres    false    220            �
           2606    17486 #   sous_categorie nomEtIdUniqueSousCat 
   CONSTRAINT     m   ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "nomEtIdUniqueSousCat" UNIQUE (nom, categorie_id);
 O   ALTER TABLE ONLY public.sous_categorie DROP CONSTRAINT "nomEtIdUniqueSousCat";
       public         postgres    false    210    210            �
           2606    17488    pays nomPaysUnique 
   CONSTRAINT     N   ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "nomPaysUnique" UNIQUE (nom);
 >   ALTER TABLE ONLY public.pays DROP CONSTRAINT "nomPaysUnique";
       public         postgres    false    206            �
           2606    17490    statut nomStatutUnique 
   CONSTRAINT     R   ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "nomStatutUnique" UNIQUE (nom);
 B   ALTER TABLE ONLY public.statut DROP CONSTRAINT "nomStatutUnique";
       public         postgres    false    212            �
           2606    17492    recurence periodiciteUnique 
   CONSTRAINT     _   ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "periodiciteUnique" UNIQUE (periodicite);
 G   ALTER TABLE ONLY public.recurence DROP CONSTRAINT "periodiciteUnique";
       public         postgres    false    208                       2606    17494    utilisateur pseudoUnique 
   CONSTRAINT     W   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "pseudoUnique" UNIQUE (pseudo);
 D   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT "pseudoUnique";
       public         postgres    false    218                       2606    17496    test test_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (testt);
 8   ALTER TABLE ONLY public.test DROP CONSTRAINT test_pkey;
       public         postgres    false    223                       2606    17498 &   type_transaction typeTransactionUnique 
   CONSTRAINT     c   ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "typeTransactionUnique" UNIQUE (type);
 R   ALTER TABLE ONLY public.type_transaction DROP CONSTRAINT "typeTransactionUnique";
       public         postgres    false    216            #           2620    17499 $   modele_transaction createTransaction    TRIGGER     �   CREATE TRIGGER "createTransaction" AFTER INSERT ON public.modele_transaction FOR EACH ROW WHEN ((new.date = CURRENT_DATE)) EXECUTE PROCEDURE public."transactionCreation"();
 ?   DROP TRIGGER "createTransaction" ON public.modele_transaction;
       public       postgres    false    228    200    200            $           2620    17500    transaction soldeModifExpense    TRIGGER     �   CREATE TRIGGER "soldeModifExpense" BEFORE INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeExpense"();
 8   DROP TRIGGER "soldeModifExpense" ON public.transaction;
       public       postgres    false    214    226            %           2620    17501    transaction soldeModifIncome    TRIGGER     �   CREATE TRIGGER "soldeModifIncome" AFTER INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeIncome"();
 7   DROP TRIGGER "soldeModifIncome" ON public.transaction;
       public       postgres    false    227    214                       2606    17502    sous_categorie categorie_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;
 E   ALTER TABLE ONLY public.sous_categorie DROP CONSTRAINT categorie_id;
       public       postgres    false    196    2789    210                       2606    17507    limite categorie_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.limite
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id);
 =   ALTER TABLE ONLY public.limite DROP CONSTRAINT categorie_id;
       public       postgres    false    2789    196    198                       2606    17512    utilisateur droit_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT droit_id FOREIGN KEY (droit_id) REFERENCES public.droit(droit_id) ON UPDATE CASCADE ON DELETE CASCADE;
 >   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT droit_id;
       public       postgres    false    218    220    2829                       2606    17517 !   transaction modele_transaction_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT modele_transaction_id FOREIGN KEY (modele_transaction_id) REFERENCES public.modele_transaction(modele_transaction_id) ON UPDATE CASCADE;
 K   ALTER TABLE ONLY public.transaction DROP CONSTRAINT modele_transaction_id;
       public       postgres    false    200    2795    214                       2606    17522    utilisateur options_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT options_id FOREIGN KEY (options_id) REFERENCES public.options(options_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 @   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT options_id;
       public       postgres    false    2799    218    204                       2606    17527    utilisateur pays_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT pays_id FOREIGN KEY (pays_id) REFERENCES public.pays(pays_id) ON UPDATE CASCADE ON DELETE SET NULL;
 =   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT pays_id;
       public       postgres    false    2801    206    218                       2606    17532    limite recurence_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.limite
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 =   ALTER TABLE ONLY public.limite DROP CONSTRAINT recurence_id;
       public       postgres    false    208    2805    198                       2606    17537    modele_transaction recurence_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurrence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE SET NULL;
 I   ALTER TABLE ONLY public.modele_transaction DROP CONSTRAINT recurence_id;
       public       postgres    false    200    2805    208                       2606    17542    limite sous_categorie_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.limite
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.limite DROP CONSTRAINT sous_categorie_id;
       public       postgres    false    198    2809    210                       2606    17547 $   modele_transaction sous_categorie_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;
 N   ALTER TABLE ONLY public.modele_transaction DROP CONSTRAINT sous_categorie_id;
       public       postgres    false    200    2809    210            !           2606    17552 1   sous_categories_personnelles sous_categorie_id_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT sous_categorie_id_fk FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.sous_categories_personnelles DROP CONSTRAINT sous_categorie_id_fk;
       public       postgres    false    222    2809    210                        2606    17557    utilisateur statut_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT statut_id FOREIGN KEY (statut_id) REFERENCES public.statut(statut_id) ON UPDATE CASCADE ON DELETE SET NULL;
 ?   ALTER TABLE ONLY public.utilisateur DROP CONSTRAINT statut_id;
       public       postgres    false    218    2813    212                       2606    17562 &   modele_transaction type_transaction_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT type_transaction_id FOREIGN KEY (type_transaction_id) REFERENCES public.type_transaction(type_transaction_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.modele_transaction DROP CONSTRAINT type_transaction_id;
       public       postgres    false    216    2819    200                       2606    17567    notification utilisateur_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.notification
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.notification DROP CONSTRAINT utilisateur_id;
       public       postgres    false    218    202    2823                       2606    17572    limite utilisateur_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.limite
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public.limite DROP CONSTRAINT utilisateur_id;
       public       postgres    false    218    198    2823                       2606    17577 !   modele_transaction utilisateur_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.modele_transaction DROP CONSTRAINT utilisateur_id;
       public       postgres    false    2823    218    200            "           2606    17582 .   sous_categories_personnelles utilisateur_id_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT utilisateur_id_fk FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id);
 X   ALTER TABLE ONLY public.sous_categories_personnelles DROP CONSTRAINT utilisateur_id_fk;
       public       postgres    false    2823    218    222            �   �   x�=PAN1<{_�(�m��#�= �8�m�%�Ɖ�l%��;?�ǰ�-c�'3s�f44"�����62ߺ;x\R��	�ᰁwL��� ��	R��	�dQ7kx(Z
6�/���#{"�禸�C�d}�*o6c��رi����)q�1)���s��$�I���5�Սزl�(ԓ-f�J�B#��B�i���Ŀ��A��d�D�k���4��N��{qV���j�줼3Ң�x�u�/n      �   0   x�3�tL����2�-���,N,I--�2�t��+N���I-����� ��      �      x������ � �      �   �   x����
�0�瓧����
N]�ѥ`�?3���B�%7p�s��r������锪�r��N�qΠ�.���	�!���:���=����
a�d��``��3����1�mBpt�}��f, �^r�}�{y����֨�����9��Oy�9�^�0�C�vch�W��/�sى���
,:M��������ͺp      �      x������ � �      �      x�3�L�2�,����� �      �   "  x�mW�r�8=_�[��B$��Gywɲ5�쎮�K��E�HBRK_?/A-�D_�D@&ry/��Ǫ�Z7-�2�r��X��l��dꕲPĸ��Q̩2$�ؗkI� �LI2�z�(�:��.]N2ヲKҿ`'쉱])l�I�����T�@ucqEU�ȰϢ%������\5�a�V�=G�mQn�?W�\iW�0�h+v!ꉫ��w��ʔz�cQ����eje��W��mv�20n���)�QFp��A�2�-}P2�V��)��:׈�K��w�,���e���)Me��=����wmW���ZW+ܐuMC%U2��\(��tOuEV���as�e�g���⚪��y�ee��e<�\B'�6*xW6W2N��Wt���Hr�?|�e?s��'�ר�H\��~�_]*�ﳀ��bAz�`��(0d��><0�i�M�W��}1	�8FK8݇C��EJ=1��i[%�xU�,u���-TpmP{r�7�2�%�np���,.��1���6h����}��Y���[���7��;��8�,\`5*s�7�����PܘJ�|�0:����0��C�Z9���Tn��@��v�zш��ӵ�%Cq��l��p$nQ1�Չ�mZ��?L�Y�Ώ��(׼��;��"�W���<ǯ�α�i<�?w�������܈��˝qg�Δ!���5w�htR�L��U?G�I�m*{��p[*n~�%��e���D�&�8:,�:_I,^��m�ʃ����/ݖ�q̢�!�}�.%Cq���g��LFb��^KĽU
�HR/u�M{���dL��m�L#^U2���U�S���%,�A�g��P<\�#�Ȟ"�c?�nLM�%�i"޹r�k��y��e��S��2�z�X��*� �!G�1S��B��,�.�ao �V��9�D����P@�a�tS��T	1�-�0�6�
�?�F[M(~ ���C����� �	h]x~	�?�ͽ8U�y�P|jٙ2�R��|qob��C`�?i1q;�b*&{��:s@�'2�+��)O
�g�@�1ma �8�n=)�œ^z�����`li�?T����V1Y��t[8ϩ!��������"u��)eS1�[N+j2�e����vb�Ž�P�\o�(!p�2`���!Y���Oɡ:���n��q���` ?Ez1d4� =5en���yS۠�1�Oљ?_́�{ ��8��g���_�@YAJų�
����.��eɯď-CrV����{��T�q5@���SQW�@�g��%�%X���R�I�<���6����S�(��U;B��!v�5e"��ܾ!p���-0�wnLuml���r����/�T���^���U��X�T���Ў�D�������	fp��c)��/��B���{=^ �)N �}�֛v�r��L�i�+��m�z`�Ov+�`���ە�T�׌�B����w�V!0~�m*���b���՚{��j��6�q��Q���#D�;�b���ňV*��b�۶�h�����?JW��F�mO.�n�m�Q��Ca���L���5�'��H��8L�s_�u��9@fa��ԙE���9�\{�`� ����#�b��Y���a��#
�
 �! ��aty�Kt��_�ЪE�!��~�@s�������H��Ւ�;����������'���H_�F��/�A:!���g�Ö��`;��ჰW�Q��8�gc��|�4��v�=t��5��s�t�yF����_�X�xcQ��>���`n���V\�Xc���`�|�9u~-̒���ԋ��m���0r�%(�Ə�=�v�0��X�ω�	�+�����2���+����/�����t�3����r+���/��?�W��]�7-���@n*�Rfm��g ��/.��O�A��������u_k�8��Q��Y�"������;���fa#�'�Iw�s��M�_�e�a�Rf�o�����M`a|����]J�?
�{�      �   K   x�3�t��+M��2�,�/�L�L��2�)��M-.)�ʘq��9F���y� Ɯ�I)���)��E�\1z\\\ ���      �   �  x��V�r�6>�O����#�_G�I���O�ɩ�$�$�  ���tz�z����- Rrܟ���.�����ȧS���nY�f�*gw�I�L�Liߟl��w��1�؟WV:��p�vε�k!�R�����ָ�G]ݟ4?�pg��Z��3q��~YC���Z�����TRx��Bdu��2y���^�]���Uג��o3IZןd���e��S,��!�{���^IM��?5�§�Q�a�>%F&�)T���-{�zU��|�T:�S�Zu�Fy���h^e��t�?���>�f��5Z}i��YI�r.|:Z�ٮ
%!�W�vF��ከ�iy}|:�����z�T<���˳1UI	O�\%�?�خAY$%��j�v��e�m�e���{<D�jD���ZUU�d�vZ�ԧg���VQ7�^�$�]�-9hh,CP8i;���P� ��'`8����6_���d�`��Y�"���xVF�%��n#P���\�
�6��n�M��bo��Ǧ�GA�n��5{ J�bl� �ƚ=B���U
rC4H=�	�!T�*	c���j�~�%C� %%���G^p��ZA����S!����//+� ��<��y�iy�;M��ͣh����4��{�ߧ��[��z*H�B��ռ⥒�M
	h+2޲��T*���l1eϿȖR``�:�>�(�+���E�gyCi�ٷ� ��� dE���B��#�E�,�ѴE���&MAb̂Zb�a�ċ%�{:*Ѣ���(߷` o���L�\]pq7܉�5Jg� �l I�܂]���-Qjr�ab^aPoύ�|'ڦ�cb�٤��=.��Nr��!����8�~�DԌ �Ui�3���l/eҡ����FﴗVˀR�"ܱ//����2�V�RvT/� ����۹+�g�Z�VG��Fl�v���
��ǳI�:��۬Se
�yӠ뱪7��(n8a	
�#�"ho.�yA��.r��N�r0Y�<pk#9����;
63v���q	�{N�I�}"<��.-�=�j?�?c�~iUQ@���&�T�Q�����ZK�C�� ���*��y�>�؁=u#��{��-{�0�G�2Z�7ss��n@on�(�2�]���*l���.0GF����@E|��OI�p5�AS7��)�k��?�A�gӕe��$��P��� � ]��s�p�{��P
@��4DXֽ�x%�Ǳ@���-��E�P>�m�1>�7��ae�)��<�����^�d����`��$35\^�H�<A\���n6��y\�K�Yo�p���0$���և@�����x;=�ac���h:���A�Vuc��$�xPl��ԗty6���Y*I�@w��4�Ʀ���X� .������r�����U�����I
�?�"���i<��_�������      �      x������ � �      �   +   x�3�t-)M�L�+�2�N�I,�<��˘ӱ��(�+F��� ��
      �      x�3�4�2�4����� ��      �   a   x�m��� ���K�-�t�9J�E>��@e"ᴦeA��f_*^ܠ1�ڵp�o���up;�C�τq����������@�����I"�f�*�      �   !   x�3�tI-H�+N�2�J-K�+M����� _��      �   �  x�]�K��0�s�s�J&�'EK]]X�����&"t��/:N�����ݧ_�C�ʥl��>~Mڣ�D!�J���'蒦�Qw;H����b�����˰��ڏ�i�l�7&�#�#���䍏�0 ;���P[�Q�X/��q	��6-L�?��ޞP��EΫ*�`V�+pz�P>�^��T�$0�@P�S�J�D���ؼ�+4t�(��+�uT��z'q���Fa9D3[��t��U�I�1�K��I1q�-� ���I-��{�)�X��)D�;�ƅ*+����evr��"��oǹ�Y�ш���I�᧠��l.I36��$����P��"$�	�5b��*D]B��t�4����� e'��\�?+(jq�W��M��2�!���S��r��{��q1[����J0�F��Ș��POG����ڬtW�\��i#�:�_�w�F��;��o��'     