-- ============================================================================
-- PHES-ODM v3.0.1 — MySQL / MariaDB schema
-- Generated from: odm_v3 LinkML schema + ODM_ERD_V3.0.1.pdf + dictionary-tables/ODM_parts.csv
-- Supersedes the stale V2-RC2 templates/ODM-mysql.sql (and src/lucid-mysql.sql).
-- Sibling of schema-postgres.sql — same tables/columns/constraints; differences from
-- that file are purely dialect mechanics, listed below. Read schema-postgres.sql's
-- design notes 1–5 first; they apply here unchanged.
--
-- DIALECT-SPECIFIC NOTES (vs. schema-postgres.sql):
--
-- A. Identifiers use backticks, not double quotes — MySQL only treats `"..."` as an
--    identifier under the non-default ANSI_QUOTES SQL mode, which this file doesn't
--    assume is set.
--
-- B. `DEFERRABLE INITIALLY DEFERRED` is dropped everywhere. MySQL/InnoDB has no
--    deferred constraint checking at all — every FK is checked immediately, always.
--    This matters for bulk-loading seed data with self-referencing FKs (parts,
--    calculations.pipelineID): the seed script must disable checking for the
--    duration of the load with `SET FOREIGN_KEY_CHECKS=0;` / `=1;` around it (a
--    session variable, not a schema-level setting — nothing to add here, it's the
--    seed file's problem to solve, noted for whoever writes it).
--
-- C. `TIMESTAMP` → `DATETIME`. MySQL's native TIMESTAMP type is tied to a ~1970–2038
--    range (it's stored as a Unix timestamp under the hood) and has automatic
--    on-update side effects in some configurations — neither is wanted for general
--    date/time storage. This isn't cosmetic: `samples.epiYear`/`measures.epiYear`
--    have a CHECK allowing 1900–3000, which native TIMESTAMP literally cannot
--    represent. DATETIME has no such range restriction.
--
-- D. `DOUBLE PRECISION` → `DOUBLE` (MySQL's canonical name; DOUBLE PRECISION is
--    accepted as a synonym but DOUBLE is what MySQL itself generates/documents).
--
-- E. Every CREATE TABLE gets `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
--    COLLATE=utf8mb4_unicode_ci` — InnoDB because MyISAM doesn't support foreign
--    keys at all, utf8mb4 because dictionary content includes non-ASCII characters
--    (µ, °, accented translations) and utf8mb4 is the only MySQL charset that's
--    genuinely full Unicode (plain "utf8" in MySQL is a legacy 3-byte encoding that
--    cannot represent all Unicode).
--
-- F. `CHECK` constraints (`chk_calculations_header`, the epiWeek/epiYear/collPer/
--    collNum/order range checks) are written identically to schema-postgres.sql, but
--    MySQL only *enforces* CHECK constraints from version 8.0.16 onward (MariaDB
--    since 10.2.1) — earlier MySQL versions parse and silently ignore them. If
--    you're targeting an older MySQL, these constraints exist as documentation only
--    and won't actually stop bad data.
--
-- G. `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY` after the fact IS supported by
--    MySQL/InnoDB (unlike SQLite), so the same "declare table, then bolt on the bulk
--    self-referencing FKs afterward" structure from schema-postgres.sql carries over
--    unchanged here — no need to inline them the way schema-sqlite.sql had to.
--
-- H. `index`/`order` are quoted with backticks below since both are reserved words
--    in MySQL (as they are in most SQL dialects) — this file backtick-quotes every
--    identifier uniformly rather than only the ones strictly required, precisely to
--    avoid this class of bug (schema-sqlite.sql had to be fixed for exactly this
--    after empirical testing caught it).
--
-- I. IMPORTANT when loading this file (or seed-mysql.sql) via the mysql/mariadb CLI:
--    pass `--default-character-set=utf8mb4` explicitly. Without it, the client can
--    negotiate a non-utf8mb4 connection charset (observed: silently defaults away
--    from utf8mb4 on at least one local MariaDB install) and misinterprets
--    multi-byte UTF-8 sequences already in the file, which surfaces as a confusing
--    "Data too long for column" error on ordinary-looking accented text (e.g.
--    countries.countryEndonym) — not an actual schema or data-length problem.
--    Confirmed empirically: identical file, same schema, zero errors once the
--    client charset flag is added.
-- ============================================================================


-- ============================================================================
-- SECTION 1: Dictionary look-up tables (green, per ERD)
-- ============================================================================

CREATE TABLE `languages` (
  `lang`            VARCHAR(30)  PRIMARY KEY,   -- ISO639-3 code
  `langFam`         VARCHAR(30)  NOT NULL,
  `langName`        VARCHAR(30)  NOT NULL,
  `natName`         VARCHAR(30)  NOT NULL,
  `iso6391`         VARCHAR(30)  NOT NULL,
  `iso6392T`        VARCHAR(30)  NOT NULL,
  `firstReleased`   VARCHAR(30)  NOT NULL,
  `lastUpdated`     VARCHAR(30)  NOT NULL,
  `changes`         VARCHAR(30),
  `notes`           VARCHAR(1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `countries` (
  `isoCode`         CHAR(2)      PRIMARY KEY,  -- ISO 3166-1 alpha-2
  `isoCodeX`        CHAR(3),     -- ISO 3166-1 alpha-3
  `numCode`         CHAR(3),     -- ISO 3166-1 numeric
  `tld`             VARCHAR(20)   NOT NULL,
  `nameEngl`        VARCHAR(75)  NOT NULL,
  `nameOfficial`    VARCHAR(200)  NOT NULL,
  `sovereignty`     VARCHAR(50)  NOT NULL,
  `countryExonym`   VARCHAR(75),
  `capitalExonym`   VARCHAR(150),
  `countryEndonym`  VARCHAR(200),
  `capitalEndonym`  TEXT,
  `langScript`      TEXT,
  `phone`           VARCHAR(75),
  `utc`             VARCHAR(75),
  `utcDST`          VARCHAR(75)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `zones` (
  `isoCode`  CHAR(2)      NOT NULL,
  `isoZone`  VARCHAR(6)   PRIMARY KEY,  -- ISO 3166-2
  `zoneName` VARCHAR(75)  NOT NULL,
  FOREIGN KEY (`isoCode`) REFERENCES `countries`(`isoCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- `parts` is the controlled vocabulary at the centre of the whole dictionary.
-- Every FK below marked "-> parts" is the "loose" categorical constraint from
-- schema-postgres.sql's design note 1; every FK marked "-> parts (partID reference
-- by convention)" is the semantic judgment call from design note 2.
--
-- CHARSET NOTE (MySQL-only issue, empirically discovered — see design note I below):
-- with ~107 columns, using utf8mb4 (4 bytes/char) on every VARCHAR blows past
-- InnoDB's ~8126-byte row-size limit even before counting the wide free-text
-- columns (confirmed against a live MariaDB 12.3 instance: fails even with
-- ROW_FORMAT=DYNAMIC, which only helps individually-large columns, not many
-- medium ones). Fix: columns that are provably ASCII-only by the dictionary's own
-- rules — partID cross-references (partID must match `^[a-z][a-zA-Z0-9]*$`),
-- version strings ("3.0.1"), and table-membership role codes ("input"/"header"/
-- "pK"/"fK") — get an explicit `CHARACTER SET ascii` instead of inheriting the
-- table's utf8mb4 default. Genuinely free-text/translatable columns (label,
-- changes, partInstr, ontologyRef, refLink) keep utf8mb4, since those can
-- legitimately hold non-ASCII characters (e.g. "Micro-litres" contains µ).
-- `partDesc` additionally moves from VARCHAR(1000) to TEXT, since InnoDB stores
-- TEXT off-page (removing it from the inline row-size calculation almost
-- entirely) — matching how schema-postgres.sql/schema-sqlite.sql already
-- oversize free-text columns like this (see e.g. geoWKT, sourceCode).
CREATE TABLE `parts` (
  `partID`          VARCHAR(30)   CHARACTER SET ascii PRIMARY KEY,
  `partLabel`       TEXT   NOT NULL,   -- CSV column is "partLabel", not "label" — see conversation
  `partType`        VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK added below (self-ref)
  `partDesc`        TEXT          NOT NULL,   -- free text; TEXT not VARCHAR(1000), see charset note
  `partInstr`       TEXT,             -- free text
  `domain`          VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (domains enum ∪ missingness)
  `specimenSet`     VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (partID reference by convention)
  `compartmentSet`  VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (partID reference by convention)
  `group`           VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (groups enum ∪ missingness)
  `class`           VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (classes enum ∪ missingness)
  `nomenclature`    VARCHAR(30)   CHARACTER SET ascii,            -- FK -> parts (nomenclatures enum ∪ missingness)
  `ontologyRef`     VARCHAR(200),             -- free text (external ontology URL)
  `latExp`          VARCHAR(30),              -- free text (LaTeX expression)
  `mmaSet`          VARCHAR(30)   CHARACTER SET ascii,            -- FK -> parts (mmaSets enum ∪ missingness)
  `unitSet`         VARCHAR(30)   CHARACTER SET ascii,            -- FK -> parts (partID reference by convention)
  `aggregationScale` VARCHAR(30)  CHARACTER SET ascii,            -- FK -> parts (aggregationScales enum ∪ missingness)
  `aggregationSet`  VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (aggregationSets enum ∪ missingness)
  `qualityIndSet`   VARCHAR(30)   CHARACTER SET ascii,            -- FK -> parts (partID reference by convention)
  `missingnessSet`  VARCHAR(30)   CHARACTER SET ascii,            -- FK -> parts (missingnessSets enum ∪ missingness)
  `status`          VARCHAR(30)   CHARACTER SET ascii NOT NULL,   -- FK -> parts (statusSet enum)
  `firstReleased`   VARCHAR(30)   CHARACTER SET ascii NOT NULL,
  `lastUpdated`     VARCHAR(30)   CHARACTER SET ascii NOT NULL,
  `changes`         TEXT,

  -- Table-membership triplets: <table>/<table>Required/<table>Order, one per
  -- reportable table this part can appear in as a column ('input'/'header'/'pK'/'fK').
  -- All CHARACTER SET ascii — role codes are a small fixed vocabulary, never free text.
  `protocolSteps` VARCHAR(30) CHARACTER SET ascii, `protocolStepsRequired` VARCHAR(30) CHARACTER SET ascii, `protocolStepsOrder` INTEGER,
  `protocolRelationships` VARCHAR(30) CHARACTER SET ascii, `protocolRelationshipsRequired` VARCHAR(30) CHARACTER SET ascii, `protocolRelationshipsOrder` INTEGER,
  `measures` VARCHAR(30) CHARACTER SET ascii, `measuresRequired` VARCHAR(30) CHARACTER SET ascii, `measuresOrder` INTEGER,
  `measureSets` VARCHAR(30) CHARACTER SET ascii, `measureSetsOrder` INTEGER, `measureSetsRequired` VARCHAR(30) CHARACTER SET ascii,
  `datasets` VARCHAR(30) CHARACTER SET ascii, `datasetsRequired` VARCHAR(30) CHARACTER SET ascii, `datasetsOrder` INTEGER,
  `sites` VARCHAR(30) CHARACTER SET ascii, `sitesRequired` VARCHAR(30) CHARACTER SET ascii, `sitesOrder` INTEGER,
  `samples` VARCHAR(30) CHARACTER SET ascii, `samplesRequired` VARCHAR(30) CHARACTER SET ascii, `samplesOrder` INTEGER,
  `addresses` VARCHAR(30) CHARACTER SET ascii, `addressesRequired` VARCHAR(30) CHARACTER SET ascii, `addressesOrder` INTEGER,
  `contacts` VARCHAR(30) CHARACTER SET ascii, `contactsRequired` VARCHAR(30) CHARACTER SET ascii, `contactsOrder` INTEGER,
  `organizations` VARCHAR(30) CHARACTER SET ascii, `organizationsRequired` VARCHAR(30) CHARACTER SET ascii, `organizationsOrder` INTEGER,
  `phActions` VARCHAR(30) CHARACTER SET ascii, `phActionsRequired` VARCHAR(30) CHARACTER SET ascii, `phActionsOrder` INTEGER,
  `calculations` VARCHAR(30) CHARACTER SET ascii, `calculationsRequired` VARCHAR(30) CHARACTER SET ascii, `calculationsOrder` INTEGER,
  `instruments` VARCHAR(30) CHARACTER SET ascii, `instrumentsRequired` VARCHAR(30) CHARACTER SET ascii, `instrumentsOrder` INTEGER,
  `polygonRelationships` VARCHAR(30) CHARACTER SET ascii, `polygonRelationshipsRequired` VARCHAR(30) CHARACTER SET ascii, `polygonRelationshipsOrder` INTEGER,
  `polygons` VARCHAR(30) CHARACTER SET ascii, `polygonsRequired` VARCHAR(30) CHARACTER SET ascii, `polygonsOrder` INTEGER,
  `accessions` VARCHAR(30) CHARACTER SET ascii, `accessionsRequired` VARCHAR(30) CHARACTER SET ascii, `accessionsOrder` INTEGER,
  `languages` VARCHAR(30) CHARACTER SET ascii, `languagesRequired` VARCHAR(30) CHARACTER SET ascii, `languagesOrder` INTEGER,
  `translations` VARCHAR(30) CHARACTER SET ascii, `translationsRequired` VARCHAR(30) CHARACTER SET ascii, `translationsOrder` INTEGER,
  `parts` VARCHAR(30) CHARACTER SET ascii, `partsRequired` VARCHAR(30) CHARACTER SET ascii, `partsOrder` INTEGER,
  `sets` VARCHAR(30) CHARACTER SET ascii, `setsRequired` VARCHAR(30) CHARACTER SET ascii, `setsOrder` INTEGER,
  `qualityReports` VARCHAR(30) CHARACTER SET ascii, `qualityReportsRequired` VARCHAR(30) CHARACTER SET ascii, `qualityReportsOrder` INTEGER,
  `sampleRelationships` VARCHAR(30) CHARACTER SET ascii, `sampleRelationshipsRequired` VARCHAR(30) CHARACTER SET ascii, `sampleRelationshipsOrder` INTEGER,
  `protocols` VARCHAR(30) CHARACTER SET ascii, `protocolsRequired` VARCHAR(30) CHARACTER SET ascii, `protocolsOrder` INTEGER,
  `countries` VARCHAR(30) CHARACTER SET ascii, `countriesRequired` VARCHAR(30) CHARACTER SET ascii, `countriesOrder` INTEGER,
  `zones` VARCHAR(30) CHARACTER SET ascii, `zonesRequired` VARCHAR(30) CHARACTER SET ascii, `zonesOrder` INTEGER,
  `wideNames` VARCHAR(30) CHARACTER SET ascii, `wideNamesRequired` VARCHAR(30) CHARACTER SET ascii, `wideNamesOrder` INTEGER,

  `refLink`   VARCHAR(255),               -- free text
  `dataType` VARCHAR(30)    CHARACTER SET ascii NOT NULL,  -- FK -> parts (dataTypes enum); CSV column is "dataType" (singular)
  `minValue`  VARCHAR(30)   CHARACTER SET ascii,           -- numeric-as-string, "seeUnitVal" etc. — ASCII by construction
  `maxValue`  VARCHAR(30)   CHARACTER SET ascii,
  `minLength` INTEGER,
  `maxLength` INTEGER
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Self-referencing FKs added after the table exists (avoids ordering issues in DDL;
-- see design note G — MySQL, unlike SQLite, supports this).
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_partType`      FOREIGN KEY (`partType`)         REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_domain`        FOREIGN KEY (`domain`)           REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_specimenSet`   FOREIGN KEY (`specimenSet`)      REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_compartmentSet` FOREIGN KEY (`compartmentSet`)  REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_group`         FOREIGN KEY (`group`)            REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_class`         FOREIGN KEY (`class`)            REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_nomenclature`  FOREIGN KEY (`nomenclature`)     REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_mmaSet`        FOREIGN KEY (`mmaSet`)           REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_unitSet`       FOREIGN KEY (`unitSet`)          REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_aggScale`      FOREIGN KEY (`aggregationScale`) REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_aggSet`        FOREIGN KEY (`aggregationSet`)   REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_qualIndSet`    FOREIGN KEY (`qualityIndSet`)    REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_missingSet`    FOREIGN KEY (`missingnessSet`)   REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_status`        FOREIGN KEY (`status`)           REFERENCES `parts`(`partID`);
ALTER TABLE `parts` ADD CONSTRAINT `fk_parts_dataType`      FOREIGN KEY (`dataType`)         REFERENCES `parts`(`partID`);

CREATE INDEX `idx_parts_partType` ON `parts`(`partType`);
CREATE INDEX `idx_parts_domain`   ON `parts`(`domain`);
CREATE INDEX `idx_parts_group`    ON `parts`(`group`);
CREATE INDEX `idx_parts_class`    ON `parts`(`class`);

-- `sets` maps parts into named groups (unit sets, mma/category sets, etc.).
-- setID and partID both reference parts(partID); setType is documentation-only
-- (mirrors the referenced setID's own partType) rather than a separate FK target.
CREATE TABLE `sets` (
  `setCompID`     VARCHAR(60)  PRIMARY KEY,             -- computed: setID || '_' || partID
  `setID`         VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `setType`       VARCHAR(30)  NOT NULL,                -- documentation only, see note above
  `partID`        VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `label`         VARCHAR(150)  NOT NULL,                -- denormalized copy of parts.label at write time
  `enumeration`   INTEGER      NOT NULL,
  `status`        VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `firstReleased` VARCHAR(30)  NOT NULL,
  `lastUpdated`   VARCHAR(30)  NOT NULL,
  `changes`       VARCHAR(50),
  `notes`         VARCHAR(1000),
  FOREIGN KEY (`setID`)  REFERENCES `parts`(`partID`),
  FOREIGN KEY (`partID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`status`) REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_sets_setID`  ON `sets`(`setID`);
CREATE INDEX `idx_sets_partID` ON `sets`(`partID`);

CREATE TABLE `translations` (
  `translationID` VARCHAR(50)   PRIMARY KEY,
  `lang`          VARCHAR(30)   NOT NULL,
  `partID`        VARCHAR(30) CHARACTER SET ascii   NOT NULL,
  `partLabel`     TEXT   NOT NULL,   -- free text (translated); CSV column is "partLabel", not "label"
  `partDesc`      VARCHAR(1000) NOT NULL,   -- free text (translated)
  `partInstr`     TEXT,             -- free text (translated)
  `firstReleased` VARCHAR(30)   NOT NULL,
  `lastUpdated`   VARCHAR(30)   NOT NULL,
  `changes`       TEXT,
  `notes`         VARCHAR(1000),
  FOREIGN KEY (`lang`)   REFERENCES `languages`(`lang`),
  FOREIGN KEY (`partID`) REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_translations_partID` ON `translations`(`partID`);
CREATE INDEX `idx_translations_lang`   ON `translations`(`lang`);

-- wideNames rows are keyed by their own synthetic wideName, not by parts — the
-- *Name/*Input column pairs each reference a part loosely (by convention, per
-- schema-postgres.sql design note 2) but the LinkML doesn't range-type them as
-- parts, so they're left unconstrained here to match; add FKs later if you want
-- them enforced.
CREATE TABLE `wideNames` (
  `wideName`         VARCHAR(100)   PRIMARY KEY,
  `label`            VARCHAR(100)   NOT NULL,
  `charLength`       VARCHAR(30),
  `description`      VARCHAR(1000) NOT NULL,   -- free text; CSV column is "description", not "descr"
  `source`           VARCHAR(30)   NOT NULL,
  `wideMeasure`      VARCHAR(60),
  `wideProtocol`     VARCHAR(30),
  `wideAttribute`    VARCHAR(30),
  `wideNameType`     VARCHAR(30),
  `reportTableName`  VARCHAR(30),
  `reportTableInput` VARCHAR(30),
  `partTypeName`     VARCHAR(30),
  `partTypeInput`    VARCHAR(30),
  `compartmentName`  VARCHAR(30),
  `compartmentInput` VARCHAR(30),
  `specimenName`     VARCHAR(30),
  `specimenInput`    VARCHAR(30),
  `fractionName`     VARCHAR(60),
  `fractionInput`    VARCHAR(30),
  `measureName`      VARCHAR(60),
  `measureInput`     VARCHAR(100),
  `methodName`       VARCHAR(30),
  `methodInput`      VARCHAR(30),
  `unitName`         VARCHAR(30),
  `unitInput`        VARCHAR(30),
  `aggregationName`  VARCHAR(60),
  `aggregationInput` VARCHAR(30),
  `index`            VARCHAR(50),             -- free text, any_of[string, genMissingnessSet]
  `attributeName`    VARCHAR(60),
  `attributeInput`   VARCHAR(30),
  `tag`              VARCHAR(10)   -- sparse boolean-ish flag column found in the live CSV
                                     -- during seed generation, missing from the initial
                                     -- LinkML-derived schema — only 4/131 rows populated ('1')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 2: Program-description tables (yellow, per ERD)
-- ============================================================================

CREATE TABLE `addresses` (
  `addressID`    VARCHAR(30)  PRIMARY KEY,
  `addL1`        VARCHAR(30)  NOT NULL,
  `addL2`        VARCHAR(30),
  `city`         VARCHAR(30)  NOT NULL,
  `stateProvReg` VARCHAR(30)  NOT NULL,
  `pCode`        VARCHAR(30),
  `country`      VARCHAR(30)  NOT NULL,
  `lastEdited`   DATETIME,
  `notes`        VARCHAR(1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `organizations` (
  `organizationID` VARCHAR(100) PRIMARY KEY,
  `name`           VARCHAR(30),
  `descr`          VARCHAR(1000),
  `addressID`      VARCHAR(30)  NOT NULL,
  `orgType`        VARCHAR(30) CHARACTER SET ascii,
  `orgLevel`       VARCHAR(30) CHARACTER SET ascii,
  `orgSector`      VARCHAR(30) CHARACTER SET ascii,
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`addressID`) REFERENCES `addresses`(`addressID`),
  FOREIGN KEY (`orgType`)   REFERENCES `parts`(`partID`),
  FOREIGN KEY (`orgLevel`)  REFERENCES `parts`(`partID`),
  FOREIGN KEY (`orgSector`) REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `contacts` (
  `contactID`      VARCHAR(30)  PRIMARY KEY,
  `organizationID` VARCHAR(100),
  `firstName`      VARCHAR(30),
  `lastName`       VARCHAR(30),
  `email`          VARCHAR(100) NOT NULL,
  `coPhone`        VARCHAR(30),
  `role`           VARCHAR(30),
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- funderCont/custodyCont/funderID/custodyID: LinkML types these as generic strings,
-- but per their own descriptions they hold contact/organization IDs ("Use Contact ID
-- to populate this field" / "Use Organization ID to populate this field") — FK'd per
-- maintainer decision, overriding the LinkML's loose literal typing.
CREATE TABLE `datasets` (
  `parDatasetID`   VARCHAR(30),
  `datasetID`      VARCHAR(30)  PRIMARY KEY,
  `datasetDate`    DATETIME,
  `name`           VARCHAR(30),
  `license`        VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `descr`          VARCHAR(1000),
  `refLink`        VARCHAR(255),
  `lang`           VARCHAR(30),
  `funderCont`     VARCHAR(30),
  `custodyCont`    VARCHAR(30),
  `funderID`       VARCHAR(100),  -- widened to match organizationID's declared length
  `custodyID`      VARCHAR(100) NOT NULL,
  `originalFormat` VARCHAR(30) CHARACTER SET ascii,
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`parDatasetID`)   REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`license`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`lang`)           REFERENCES `languages`(`lang`),
  FOREIGN KEY (`funderCont`)     REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`custodyCont`)    REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`funderID`)       REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`custodyID`)      REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`originalFormat`) REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `instruments` (
  `instrumentID` VARCHAR(30)  PRIMARY KEY,
  `name`         VARCHAR(30),
  `model`        VARCHAR(100) NOT NULL,
  `manufacturer` VARCHAR(100),
  `descr`        VARCHAR(1000),
  `refLink`      VARCHAR(255),
  `insType`      VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `insTypeOth`   VARCHAR(1000),
  `index`        VARCHAR(50),
  `lastEdited`   DATETIME,
  `notes`        VARCHAR(1000),
  FOREIGN KEY (`insType`) REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `protocols` (
  `sourceProtocol`  VARCHAR(30),
  `protocolID`      VARCHAR(30)  PRIMARY KEY,
  `name`            VARCHAR(30),
  `summ`            VARCHAR(1000),
  `refLink`         VARCHAR(255),
  `organizationID`  VARCHAR(100),
  `contactID`       VARCHAR(30),
  `protocolVersion` INTEGER,
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`sourceProtocol`)  REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`organizationID`)  REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)       REFERENCES `contacts`(`contactID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `protocolSteps` (
  `stepID`         VARCHAR(30)  PRIMARY KEY,
  `method`         VARCHAR(30) CHARACTER SET ascii,
  `measure`        VARCHAR(100) CHARACTER SET ascii,
  `summ`           VARCHAR(1000),
  `sourceStep`     VARCHAR(30),
  `stepVer`        VARCHAR(50),
  `refLink`        VARCHAR(255),
  `organizationID` VARCHAR(100),
  `contactID`      VARCHAR(30),
  `instrumentID`   VARCHAR(30),
  `value`          VARCHAR(100),
  `unit`           VARCHAR(30) CHARACTER SET ascii,
  `aggregation`    VARCHAR(30) CHARACTER SET ascii,
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`method`)         REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measure`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`sourceStep`)     REFERENCES `protocolSteps`(`stepID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)      REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`instrumentID`)   REFERENCES `instruments`(`instrumentID`),
  FOREIGN KEY (`unit`)           REFERENCES `parts`(`partID`),
  FOREIGN KEY (`aggregation`)    REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `protocolRelationships` (
  `protocolRelationshipsID` VARCHAR(50) PRIMARY KEY,
  `protocolIDContainer`     VARCHAR(30) NOT NULL,
  `protocolIDObj`           VARCHAR(30),
  `stepIDObj`               VARCHAR(30),
  `relationshipID`          VARCHAR(30) CHARACTER SET ascii NOT NULL,
  `protocolIDSub`           VARCHAR(30),
  `stepIDSub`               VARCHAR(30),
  `lastEdited`              DATETIME,
  `notes`                   VARCHAR(1000),
  FOREIGN KEY (`protocolIDContainer`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`protocolIDObj`)       REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`stepIDObj`)           REFERENCES `protocolSteps`(`stepID`),
  FOREIGN KEY (`relationshipID`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`protocolIDSub`)       REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`stepIDSub`)           REFERENCES `protocolSteps`(`stepID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `polygons` (
  `polygonID`      VARCHAR(30)  PRIMARY KEY,
  `datasetID`      VARCHAR(30),
  `name`           VARCHAR(30),
  `descr`          VARCHAR(1000),
  `geoType`        VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `geoEPSG`        DOUBLE       NOT NULL,
  `geoWKT`         TEXT         NOT NULL,  -- source LinkML's pattern caps this at 63 chars
                                            -- ("^.{0,63}$"), too short for realistic WKT
                                            -- geometry text — widened to TEXT per maintainer
                                            -- decision, deliberately overriding that bound.
  `fileLocation`   TEXT,
  `refLink`        VARCHAR(255),
  `organizationID` VARCHAR(100),
  `contactID`      VARCHAR(30),
  `poLic`          VARCHAR(50) CHARACTER SET ascii,
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`datasetID`)      REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`geoType`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)      REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`poLic`)          REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `polygonRelationships` (
  `polygonRelID`      VARCHAR(50) PRIMARY KEY,
  `polygonIDSubject`  VARCHAR(50) NOT NULL,
  `relationshipID`    VARCHAR(30) CHARACTER SET ascii,
  `polygonIDObject`   VARCHAR(50) NOT NULL,
  `lastEdited`        DATETIME,
  `notes`             VARCHAR(1000),
  FOREIGN KEY (`polygonIDSubject`) REFERENCES `polygons`(`polygonID`),
  FOREIGN KEY (`relationshipID`)   REFERENCES `parts`(`partID`),
  FOREIGN KEY (`polygonIDObject`)  REFERENCES `polygons`(`polygonID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SECTION 3: Results tables (blue, per ERD)
-- ============================================================================

CREATE TABLE `sites` (
  `parSiteID`      VARCHAR(30),
  `siteID`         VARCHAR(30)  PRIMARY KEY,
  `datasetID`      VARCHAR(30),
  `polygonID`      VARCHAR(30),
  `siteType`       VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `sampleShed`     VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `siteLevel`      VARCHAR(30) CHARACTER SET ascii,
  `addressID`      VARCHAR(30),
  `organizationID` VARCHAR(100),
  `contactID`      VARCHAR(30)  NOT NULL,
  `name`           VARCHAR(30),
  `descr`          VARCHAR(1000),
  `repOrg1`        VARCHAR(30),
  `repOrg2`        VARCHAR(30),
  `healthRegion`   VARCHAR(30),
  `geoLat`         DOUBLE,
  `geoLong`        DOUBLE,
  `geoEPSG`        VARCHAR(30),
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`parSiteID`)      REFERENCES `sites`(`siteID`),
  FOREIGN KEY (`datasetID`)      REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`polygonID`)      REFERENCES `polygons`(`polygonID`),
  FOREIGN KEY (`siteType`)       REFERENCES `parts`(`partID`),
  FOREIGN KEY (`sampleShed`)     REFERENCES `parts`(`partID`),
  FOREIGN KEY (`siteLevel`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`addressID`)      REFERENCES `addresses`(`addressID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)      REFERENCES `contacts`(`contactID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `samples` (
  `sampleID`       VARCHAR(30)  PRIMARY KEY,
  `protocolID`     VARCHAR(30),
  `organizationID` VARCHAR(100),
  `contactID`      VARCHAR(30),
  `siteID`         VARCHAR(30)  NOT NULL,
  `purpose`        VARCHAR(30) CHARACTER SET ascii,
  `saMaterial`     VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `datasetID`      VARCHAR(30),
  `origin`         VARCHAR(30) CHARACTER SET ascii,
  `repType`        VARCHAR(30) CHARACTER SET ascii,
  `collType`       VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `collPer`        DOUBLE       NOT NULL,
  `collNum`        INTEGER      NOT NULL,
  `pooled`         VARCHAR(30) CHARACTER SET ascii,
  `collDT`         DATETIME     NOT NULL,
  `collDTStart`    DATETIME,
  `collDTEnd`      DATETIME,
  `collDate`       DATE,
  `collAppxT`      VARCHAR(50) CHARACTER SET ascii,
  `epiWeekStart`   DATE,
  `epiWeek`        INTEGER,
  `epiYear`        INTEGER,
  `sentDate`       DATETIME,
  `recDate`        DATETIME,
  `reportable`     VARCHAR(30) CHARACTER SET ascii,
  `lastEdited`     DATETIME,
  `notes`          VARCHAR(1000),
  FOREIGN KEY (`protocolID`)     REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)      REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`siteID`)         REFERENCES `sites`(`siteID`),
  FOREIGN KEY (`purpose`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`saMaterial`)     REFERENCES `parts`(`partID`),
  FOREIGN KEY (`datasetID`)      REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`origin`)         REFERENCES `parts`(`partID`),
  FOREIGN KEY (`repType`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`collType`)       REFERENCES `parts`(`partID`),
  FOREIGN KEY (`pooled`)         REFERENCES `parts`(`partID`),
  FOREIGN KEY (`collAppxT`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`reportable`)     REFERENCES `parts`(`partID`),
  CONSTRAINT `chk_samples_collPer` CHECK (`collPer` >= 1),
  CONSTRAINT `chk_samples_collNum` CHECK (`collNum` >= 1),
  CONSTRAINT `chk_samples_epiWeek` CHECK (`epiWeek` IS NULL OR `epiWeek` BETWEEN 1 AND 52),
  CONSTRAINT `chk_samples_epiYear` CHECK (`epiYear` IS NULL OR `epiYear` BETWEEN 1900 AND 3000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sampleRelationships` (
  `sampleRelationshipsID` VARCHAR(50) PRIMARY KEY,
  `sampleIDSubject`       VARCHAR(30) NOT NULL,
  `relationshipID`        VARCHAR(30) CHARACTER SET ascii NOT NULL,
  `sampleIDObject`        VARCHAR(30) NOT NULL,
  `lastEdited`            DATETIME,
  `notes`                 VARCHAR(1000),
  FOREIGN KEY (`sampleIDSubject`) REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`relationshipID`)  REFERENCES `parts`(`partID`),
  FOREIGN KEY (`sampleIDObject`)  REFERENCES `samples`(`sampleID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `measureSets` (
  `measureSetRepID` VARCHAR(30) PRIMARY KEY,
  `protocolID`      VARCHAR(30),
  `name`            VARCHAR(30),
  `organizationID`  VARCHAR(100),
  `contactID`       VARCHAR(30),
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`protocolID`)     REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)      REFERENCES `contacts`(`contactID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- pipelineID/calculationID resolution follows the fix proposed in
-- https://odm.discourse.group/t/pipelineid-primary-key-x-foreign-key-issues/200 :
-- calculationID is the sole PK; pipelineID is redefined as an FK to calculationID
-- rather than a plain shared (non-unique) grouping label. Each pipeline gets one
-- "header" row — calcType='pipelineHeader', treatmentID NULL — whose own
-- calculationID is the value every row in that pipeline (including the header
-- itself) uses as pipelineID. That makes pipelineID a normal self-referencing FK
-- (valid target: calculationID is unique), and lets measures.pipelineID FK
-- straight into this table instead of being unconstrained.
-- NOTE: 'pipelineHeader' does not yet exist as a partID under calcTypeSet in the
-- live ODM_parts.csv — it needs to be added (via add-odm-part) before any header
-- row can actually be inserted under the loose FK on calcType.
CREATE TABLE `calculations` (
  `calculationID` VARCHAR(30) PRIMARY KEY,
  `pipelineID`    VARCHAR(30) NOT NULL,  -- FK added below (self-ref to calculationID)
  `treatmentID`   VARCHAR(30),           -- nullable: NULL only on the pipeline's header row
  `name`          VARCHAR(30),
  `calcType`      VARCHAR(30) CHARACTER SET ascii,
  `standard`      VARCHAR(30) CHARACTER SET ascii,
  `summary`       TEXT,
  `order`         INTEGER,
  `equation`      VARCHAR(300),
  `refLink`       VARCHAR(255),
  `sourceCode`    TEXT,
  `lastEdited`    DATETIME,
  `notes`         VARCHAR(1000),
  FOREIGN KEY (`calcType`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`standard`) REFERENCES `parts`(`partID`),
  CONSTRAINT `chk_calculations_order` CHECK (`order` IS NULL OR `order` BETWEEN 0 AND 100),
  -- CASE WHEN guarantees this always evaluates to TRUE/FALSE, never NULL. An
  -- earlier OR-based version was caught by empirical testing (against a live
  -- MariaDB 12.3 instance) to silently accept calcType=NULL AND treatmentID=NULL:
  -- that expression evaluated to NULL rather than FALSE for that combination, and
  -- SQL's CHECK treats a NULL result as "satisfied," not "violated" — a real logic
  -- bug, not a portability nitpick. COALESCE(...,'') makes the branch condition
  -- itself NULL-safe too, so calcType=NULL correctly routes to the ELSE branch as
  -- originally intended. Requires MySQL 8.0.16+/MariaDB 10.2.1+ to actually be
  -- enforced at all — see design note F.
  CONSTRAINT `chk_calculations_header` CHECK (
    CASE WHEN COALESCE(`calcType`, '') = 'pipelineHeader'
         THEN `treatmentID` IS NULL
         ELSE `treatmentID` IS NOT NULL
    END
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `calculations` ADD CONSTRAINT `fk_calculations_pipelineID`
  FOREIGN KEY (`pipelineID`) REFERENCES `calculations`(`calculationID`);

CREATE INDEX `idx_calculations_pipelineID` ON `calculations`(`pipelineID`);

CREATE TABLE `measures` (
  `measureRepID`    VARCHAR(30) PRIMARY KEY,
  `protocolID`      VARCHAR(30),
  `sampleID`        VARCHAR(30) NOT NULL,
  `purpose`         VARCHAR(30) CHARACTER SET ascii,
  `polygonID`       VARCHAR(30),
  `siteID`          VARCHAR(30),
  `datasetID`       VARCHAR(30),
  `measureSetRepID` VARCHAR(30),
  `name`            VARCHAR(30),
  `aDateStart`      DATETIME,
  `aDateEnd`        DATETIME    NOT NULL,
  `epiWeekStart`    DATE,
  `epiWeek`         INTEGER,
  `epiYear`         INTEGER,
  `relDateStart`    DATETIME,
  `relDateEnd`      DATETIME,
  `reportDate`      DATETIME,
  `compartment`     VARCHAR(30) CHARACTER SET ascii,
  `specimen`        VARCHAR(30) CHARACTER SET ascii NOT NULL,
  `fraction`        VARCHAR(30) CHARACTER SET ascii,
  `group`           VARCHAR(30) CHARACTER SET ascii,
  `class`           VARCHAR(30) CHARACTER SET ascii,
  `measure`         VARCHAR(100) CHARACTER SET ascii NOT NULL,
  `value`           VARCHAR(100) NOT NULL,
  `unit`            VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `aggregation`     VARCHAR(30) CHARACTER SET ascii  NOT NULL,
  `valTreat`        VARCHAR(30) CHARACTER SET ascii,
  `pipelineID`      VARCHAR(30),  -- pipelineID values are calculationIDs of pipeline
                                   -- "header" rows, see calculations table comment.
  `nomenclature`    VARCHAR(30) CHARACTER SET ascii,
  `index`           VARCHAR(50),
  `measureLic`      VARCHAR(30) CHARACTER SET ascii,
  `reportable`      VARCHAR(30) CHARACTER SET ascii,
  `organizationID`  VARCHAR(100),
  `contactID`       VARCHAR(30),
  `refLink`         VARCHAR(255),
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`protocolID`)      REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`sampleID`)        REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`purpose`)         REFERENCES `parts`(`partID`),
  FOREIGN KEY (`polygonID`)       REFERENCES `polygons`(`polygonID`),
  FOREIGN KEY (`siteID`)          REFERENCES `sites`(`siteID`),
  FOREIGN KEY (`datasetID`)       REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`compartment`)     REFERENCES `parts`(`partID`),
  FOREIGN KEY (`specimen`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`fraction`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`group`)           REFERENCES `parts`(`partID`),
  FOREIGN KEY (`class`)           REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measure`)         REFERENCES `parts`(`partID`),
  FOREIGN KEY (`unit`)            REFERENCES `parts`(`partID`),
  FOREIGN KEY (`aggregation`)     REFERENCES `parts`(`partID`),
  FOREIGN KEY (`valTreat`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`pipelineID`)      REFERENCES `calculations`(`calculationID`),
  FOREIGN KEY (`nomenclature`)    REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measureLic`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`reportable`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`organizationID`)  REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`contactID`)       REFERENCES `contacts`(`contactID`),
  CONSTRAINT `chk_measures_epiWeek` CHECK (`epiWeek` IS NULL OR `epiWeek` BETWEEN 1 AND 52),
  CONSTRAINT `chk_measures_epiYear` CHECK (`epiYear` IS NULL OR `epiYear` BETWEEN 1900 AND 3000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_measures_sampleID`   ON `measures`(`sampleID`);
CREATE INDEX `idx_measures_measure`    ON `measures`(`measure`);
CREATE INDEX `idx_measures_siteID`     ON `measures`(`siteID`);
CREATE INDEX `idx_measures_pipelineID` ON `measures`(`pipelineID`);

CREATE TABLE `qualityReports` (
  `qualityReportID` VARCHAR(30) PRIMARY KEY,
  `measureRepID`    VARCHAR(30),
  `sampleID`        VARCHAR(30),
  `measureSetRepID` VARCHAR(30),
  `qualityFlag`     VARCHAR(30) CHARACTER SET ascii NOT NULL,
  `severity`        VARCHAR(30) CHARACTER SET ascii,
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`measureRepID`)    REFERENCES `measures`(`measureRepID`),
  FOREIGN KEY (`sampleID`)        REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`qualityFlag`)     REFERENCES `parts`(`partID`),
  FOREIGN KEY (`severity`)        REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `accessions` (
  `accessIndexID`   VARCHAR(30) PRIMARY KEY,
  `measureRepID`    VARCHAR(30),
  `measureSetRepID` VARCHAR(30),
  `phActionID`      VARCHAR(30),  -- FK added after phActions is created
  `dataHost`        VARCHAR(50) CHARACTER SET ascii NOT NULL,
  `organizationID`  VARCHAR(100),
  `accessNum`       VARCHAR(50) NOT NULL,
  `hostVersion`     VARCHAR(50),
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`measureRepID`)    REFERENCES `measures`(`measureRepID`),
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`dataHost`)        REFERENCES `parts`(`partID`),
  FOREIGN KEY (`organizationID`)  REFERENCES `organizations`(`organizationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `phActions` (
  `actionGrpID`     VARCHAR(30),
  `phActionID`      VARCHAR(30) PRIMARY KEY,
  `measureRepID`    VARCHAR(30),
  `measureSetRepID` VARCHAR(30),
  `organizationID`  VARCHAR(100),
  `siteID`          VARCHAR(30),
  `actionType`      VARCHAR(50) CHARACTER SET ascii,
  `action`          VARCHAR(50) CHARACTER SET ascii,
  `threatTarget`    VARCHAR(50) CHARACTER SET ascii,
  `actionDT`        DATETIME,
  `relDateStart`    DATETIME,
  `relDateEnd`      DATETIME,
  `lastEdited`      DATETIME,
  `notes`           VARCHAR(1000),
  FOREIGN KEY (`measureRepID`)    REFERENCES `measures`(`measureRepID`),
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`organizationID`)  REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`siteID`)          REFERENCES `sites`(`siteID`),
  FOREIGN KEY (`actionType`)      REFERENCES `parts`(`partID`),
  FOREIGN KEY (`action`)          REFERENCES `parts`(`partID`),
  FOREIGN KEY (`threatTarget`)    REFERENCES `parts`(`partID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `accessions` ADD CONSTRAINT `fk_accessions_phAction`
  FOREIGN KEY (`phActionID`) REFERENCES `phActions`(`phActionID`);


-- ============================================================================
-- End of schema. See seed-mysql.sql (once approved) for the ~18k rows of
-- reference-table data (parts, sets, translations, languages, wideNames,
-- countries, zones) — that file's preamble will need
-- `SET FOREIGN_KEY_CHECKS=0;` / `SET FOREIGN_KEY_CHECKS=1;` around the bulk load
-- per design note B above.
-- ============================================================================
