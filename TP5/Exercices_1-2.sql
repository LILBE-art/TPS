-- ============================================================
--  TP n°5 : Transactions & Contrôle de concurrence
--  Oracle APEX - SQL Workshop > SQL Commands
--  Remarque : TRANSACTION est un mot réservé Oracle,
--             on utilise "transaction_tp" comme nom de table.
-- ============================================================


-- ============================================================
--  EXERCICE 1 : Atomicité d'une transaction
-- ============================================================

-- ------------------------------------------------------------
--  INIT : désactiver l'autocommit (à exécuter dans chaque session)
-- ------------------------------------------------------------
SET AUTOCOMMIT OFF;


-- ------------------------------------------------------------
--  Q1 : Créer la table (Session S1)
-- ------------------------------------------------------------
CREATE TABLE transaction_tp (
    idTransaction  VARCHAR2(44),
    valTransaction NUMBER(10)
);


-- ------------------------------------------------------------
--  Q2 : Insérer, modifier, supprimer puis ROLLBACK (Session S2)
-- ------------------------------------------------------------
INSERT INTO transaction_tp VALUES ('T001', 100);
INSERT INTO transaction_tp VALUES ('T002', 200);
INSERT INTO transaction_tp VALUES ('T003', 300);

UPDATE transaction_tp
SET    valTransaction = 999
WHERE  idTransaction  = 'T001';

DELETE FROM transaction_tp
WHERE  idTransaction  = 'T003';

-- Annuler toutes les modifications
ROLLBACK;

-- Vérification : la table doit être vide
SELECT * FROM transaction_tp;


-- ------------------------------------------------------------
--  Q3 : Insérer sans COMMIT puis fermer la session (S2)
--       → Oracle effectue un ROLLBACK implicite à la fermeture
-- ------------------------------------------------------------
INSERT INTO transaction_tp VALUES ('T010', 500);
INSERT INTO transaction_tp VALUES ('T011', 600);
-- Fermer l'onglet APEX sans COMMIT ni ROLLBACK

-- Vérifier depuis S1 : table vide (rollback implicite)
SELECT * FROM transaction_tp;


-- ------------------------------------------------------------
--  Q4 : Fermeture brutale sans COMMIT (Session S1)
--       → Les données ne sont PAS préservées
-- ------------------------------------------------------------
INSERT INTO transaction_tp VALUES ('T020', 777);
-- Fermer brutalement le navigateur / l'onglet

-- Après reconnexion : vérifier
SELECT * FROM transaction_tp;
-- Résultat : table vide → durabilité seulement après COMMIT


-- ------------------------------------------------------------
--  Q5 : DDL force un COMMIT implicite
--       Un ROLLBACK après un DDL (ALTER, CREATE, DROP…) est sans effet
-- ------------------------------------------------------------
INSERT INTO transaction_tp VALUES ('T030', 111);
INSERT INTO transaction_tp VALUES ('T031', 222);

-- Le DDL ci-dessous émet un COMMIT implicite AVANT et APRÈS son exécution
ALTER TABLE transaction_tp ADD val2transaction NUMBER(10);

-- Tentative de ROLLBACK : sans effet, les lignes T030/T031 sont déjà validées
ROLLBACK;

SELECT * FROM transaction_tp;
-- Résultat : T030 et T031 sont présentes malgré le ROLLBACK


-- ------------------------------------------------------------
--  Q6 : Conclusion (résumé commenté)
-- ------------------------------------------------------------
/*
  SESSION    : connexion active entre un utilisateur et la base.
               Dans APEX, un onglet SQL Commands = une session.
               Une session peut enchaîner plusieurs transactions.

  TRANSACTION: unité de travail logique (suite de DML).
               Commence implicitement après un COMMIT/ROLLBACK.
               Propriétés ACID :
                 A - Atomicité  : tout ou rien
                 C - Cohérence  : état valide garanti
                 I - Isolation  : transactions indépendantes
                 D - Durabilité : COMMIT = permanent

  COMMIT     : valide définitivement les modifications.
               Données durables et visibles par les autres sessions.
               Impossible à annuler.

  ROLLBACK   : annule toutes les modifications depuis le dernier COMMIT.
               Sans effet après un COMMIT ou un DDL.

  DDL (ALTER, CREATE, DROP…) : provoque un COMMIT implicite.
*/


-- ============================================================
--  EXERCICE 2 : Transactions concurrentes
-- ============================================================

-- ------------------------------------------------------------
--  SETUP : créer les tables et insérer les données initiales
--          (niveau d'isolation par défaut = READ COMMITTED)
-- ------------------------------------------------------------
DROP TABLE client CASCADE CONSTRAINTS;
DROP TABLE vol    CASCADE CONSTRAINTS;

CREATE TABLE vol (
    idVol                 VARCHAR2(44),
    capaciteVol           NUMBER(10),
    nbrPlacesReserveesVol NUMBER(10)
);

CREATE TABLE client (
    idClient                 VARCHAR2(44),
    prenomClient             VARCHAR2(50),
    nbrPlacesReserveesClient NUMBER(10)
);

INSERT INTO vol    VALUES ('V001', 10, 0);
INSERT INTO client VALUES ('C1', 'Alice', 0);
INSERT INTO client VALUES ('C2', 'Bob',   0);
COMMIT;


-- ------------------------------------------------------------
--  PARTIE 1 : Isolation READ COMMITTED
--             T1 réserve 2 billets pour C1 → ne pas committer
--             T2 observe : voit encore 0 (isolation)
-- ------------------------------------------------------------

-- === Session S1 (T1) ===
UPDATE vol    SET nbrPlacesReserveesVol      = nbrPlacesReserveesVol      + 2 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient   = nbrPlacesReserveesClient   + 2 WHERE idClient = 'C1';
-- NE PAS COMMITTER ICI

-- === Session S2 (T2) : pendant ce temps ===
SELECT nbrPlacesReserveesVol      FROM vol    WHERE idVol    = 'V001'; -- voit 0
SELECT nbrPlacesReserveesClient   FROM client WHERE idClient = 'C1';   -- voit 0
-- → Isolation : T2 ne voit pas les modifications non validées de T1


-- ------------------------------------------------------------
--  PARTIE 2 : ROLLBACK puis COMMIT — durabilité
-- ------------------------------------------------------------

-- === Session S1 : ROLLBACK de T1 ===
ROLLBACK;
-- T2 voit toujours 0 → comme si T1 n'avait jamais existé

-- === Session S1 : refaire T1 et COMMITTER ===
UPDATE vol    SET nbrPlacesReserveesVol    = nbrPlacesReserveesVol    + 2 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient = nbrPlacesReserveesClient + 2 WHERE idClient = 'C1';
COMMIT;

-- ROLLBACK après COMMIT = sans effet (durabilité)
ROLLBACK;

-- === Session S2 : maintenant T2 voit les données de T1 (READ COMMITTED) ===
SELECT * FROM vol;
SELECT * FROM client;


-- ------------------------------------------------------------
--  REMISE À ZÉRO avant la suite
-- ------------------------------------------------------------
UPDATE vol    SET nbrPlacesReserveesVol    = 0 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient = 0 WHERE idClient = 'C1';
UPDATE client SET nbrPlacesReserveesClient = 0 WHERE idClient = 'C2';
COMMIT;


-- ------------------------------------------------------------
--  PARTIE 3 : Mises à jour perdues (Lost Update)
--             Isolation incomplète → incohérence
--             Exécuter T1 et T2 en ALTERNANCE dans deux sessions
-- ------------------------------------------------------------

-- Ordre d'exécution à respecter :
-- Étape 1 : S1 lit les données
-- Étape 2 : S2 lit les données
-- Étape 3 : S1 met à jour et committe
-- Étape 4 : S2 met à jour et committe (écrase le résultat de S1 !)

-- === ÉTAPE 1 — Session S1 (T1) : lire ===
SELECT nbrPlacesReserveesVol    FROM vol    WHERE idVol    = 'V001'; -- résultat : 0
SELECT nbrPlacesReserveesClient FROM client WHERE idClient = 'C1';   -- résultat : 0

-- === ÉTAPE 2 — Session S2 (T2) : lire ===
SELECT nbrPlacesReserveesVol    FROM vol    WHERE idVol    = 'V001'; -- résultat : 0
SELECT nbrPlacesReserveesClient FROM client WHERE idClient = 'C2';   -- résultat : 0

-- === ÉTAPE 3 — Session S1 (T1) : mettre à jour et valider ===
UPDATE vol    SET nbrPlacesReserveesVol    = 0 + 2 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient = 0 + 2 WHERE idClient = 'C1';
COMMIT;
-- vol.nbrPlacesReserveesVol = 2 après T1

-- === ÉTAPE 4 — Session S2 (T2) : mettre à jour et valider ===
-- T2 avait lu 0 à l'étape 2 → elle écrase la valeur de T1 !
UPDATE vol    SET nbrPlacesReserveesVol    = 0 + 3 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient = 0 + 3 WHERE idClient = 'C2';
COMMIT;

-- Vérification de l'incohérence
SELECT * FROM vol;    -- nbrPlacesReserveesVol = 3 au lieu de 5 → mise à jour perdue !
SELECT * FROM client; -- C1=2, C2=3 → 5 billets côté clients, seulement 3 côté vol


-- ------------------------------------------------------------
--  REMISE À ZÉRO avant isolation SERIALIZABLE
-- ------------------------------------------------------------
UPDATE vol    SET nbrPlacesReserveesVol    = 0 WHERE idVol    = 'V001';
UPDATE client SET nbrPlacesReserveesClient = 0 WHERE idClient = 'C1';
UPDATE client SET nbrPlacesReserveesClient = 0 WHERE idClient = 'C2';
COMMIT;


-- ------------------------------------------------------------
--  PARTIE 4 : Isolation SERIALIZABLE — cohérence complète
--             Une des deux transactions sera rejetée (ORA-08177)
--             Exécuter dans chaque session avant de commencer
-- ------------------------------------------------------------

-- === Dans S1 ET S2 : définir le niveau d'isolation ===
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Rejouer ensuite exactement le même scénario par étapes (1 à 4 ci-dessus)
-- → Oracle lèvera ORA-08177 sur T2 à l'étape 4 car les données
--   lues par T2 ont été modifiées par T1 entre-temps.
-- → La base reste cohérente : nbrPlacesReserveesVol = 2


-- ------------------------------------------------------------
--  PARTIE 5 : Reproduire r1(d) w2(d) w2(d') C2 w1(d') C1
--             Vérifier si Oracle applique le verrouillage 2 phases
-- ------------------------------------------------------------

-- === Session S1 (T1) : lire d ===
SELECT nbrPlacesReserveesVol FROM vol WHERE idVol = 'V001'; -- r1(d)

-- === Session S2 (T2) : écrire d puis d' et committer ===
UPDATE vol SET nbrPlacesReserveesVol = 5 WHERE idVol = 'V001'; -- w2(d)
UPDATE vol SET nbrPlacesReserveesVol = 7 WHERE idVol = 'V001'; -- w2(d')
COMMIT;                                                          -- C2

-- === Session S1 (T1) : tenter d'écrire d' ===
-- En SERIALIZABLE : ORA-08177 → T1 rejetée (comportement différent du V2PL vu en cours)
-- En READ COMMITTED : T1 réussit → pas de verrouillage 2 phases strict
UPDATE vol SET nbrPlacesReserveesVol = 9 WHERE idVol = 'V001'; -- w1(d')
COMMIT;                                                          -- C1

SELECT * FROM vol;

/*
  CONCLUSION EXERCICE 2 :
  Oracle n'implémente PAS le verrouillage à deux phases (2PL) classique.
  Il utilise la MVCC (Multi-Version Concurrency Control) :
  - En READ COMMITTED : chaque lecture voit la dernière version committée
    → mises à jour perdues possibles (isolation incomplète).
  - En SERIALIZABLE   : chaque transaction voit un snapshot au moment
    de son démarrage → toute modification concurrente entraîne ORA-08177.
  L'algorithme Oracle est donc basé sur les snapshots (MVCC),
  non sur le verrouillage pessimiste à deux phases du cours.
*/