
CREATE EXCEPTION gd_e_nofolder 'There is no any folder';

CREATE DOMAIN daddrcontacttype
  AS SMALLINT NOT NULL;

CREATE TABLE gd_contact
(
  id            dintkey,


  /* ����� (�������) �������. ������������ ����� �������������� */
  /* ��� ������ ���������� ������, ���� ������ � ������ */
  /* ��������� � ������ �������� */
  lb            dlb,
  rb            drb,          /* ������ (������) ������� */

  parent        dparent,
  contacttype   daddrcontacttype, /* 0 - �����, 1 - ������, 2 - �������, 3 - ������, 4 - �������������, 5 - ����        */
                              /*
                                ��� ������� department
                                100 - ����������� �����������
                                101 - �������������� ������
                                102 - ���������� ������
                                103 - ������� �������������� �����
                               */

  name          dname,        /* ��� ��� ������                                                           */
  address       dtext60,      /* �����                                                                    */
  district      dtext20,
  city          dtext20,      /* �����                                                                    */
  region        dtext20,      /* ��������                                                                 */
  ZIP           dtext20,      /* ������                                                                   */
  country       dtext20,      /* �����                                                                   */
  placekey      dforeignkey,
  note          dblobtext80_1251, /* ��������                                                                 */
  externalkey   dforeignkey,
  email         dtext60,
  url           dtext40,
  pobox         dtext40,
  phone         dtext40,
  fax           dtext40,
  
  lat           dlat,
  lon           dlon,

  creatorkey    dforeignkey,
  creationdate  dcreationdate,

  editorkey     dforeignkey,
  editiondate   deditiondate,

  afull         dsecurity,
  achag         dsecurity,
  aview         dsecurity,

  disabled      ddisabled,
  reserved      dreserved
);

COMMIT;

ALTER TABLE gd_contact ADD CONSTRAINT gd_pk_contact
  PRIMARY KEY (id);

/* ��� ���������� �������� �������, �������� � ��� ������ */
ALTER TABLE gd_contact ADD CONSTRAINT gd_fk_contract_parent
  FOREIGN KEY (parent) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE gd_contact ADD CONSTRAINT gd_fk_contact_placekey
  FOREIGN KEY (placekey) REFERENCES gd_place (id)
  ON UPDATE CASCADE;

ALTER TABLE gd_contact ADD CONSTRAINT gd_chk_contact_contacttype
  CHECK(contacttype IN (0, 1, 2, 3, 4, 5, 100, 101, 102, 103));

ALTER TABLE gd_contact ADD CONSTRAINT gd_chk_contact_parent
  CHECK((contacttype IN (0, 1)) OR (NOT (parent IS NULL)));

ALTER TABLE gd_user ADD CONSTRAINT gd_fk_user_contactkey
  FOREIGN KEY (contactkey) REFERENCES gd_contact (id)
  ON UPDATE CASCADE;

ALTER TABLE gd_contact ADD CONSTRAINT gd_fk_contact_editorkey
  FOREIGN KEY (editorkey) REFERENCES gd_contact(id) 
  ON UPDATE CASCADE;

ALTER TABLE gd_contact ADD CONSTRAINT gd_fk_contact_creatorkey
  FOREIGN KEY (creatorkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE;
  
CREATE ASC INDEX gd_x_contact_name ON gd_contact (name);

COMMIT;

CREATE TABLE gd_people
(
  contactkey     dintkey,
  firstname      dtext20,      /* ���                                                            */
  surname        dtext20 NOT NULL,/* ��������                                                      */
  middlename     dtext20,      /* ��� �� ������                                                  */
  nickname       dtext20,      /* �������� ���                                                   */
  rank           dtext20,      /* ������                                                         */

  /* ������ �������� */
  hplacekey      dforeignkey,
  haddress       dtext60,     /* �����                                                          */
  hcity          dtext20,     /* �����                                                          */
  hregion        dtext20,     /* ��������                                                       */
  hZIP           dtext20,     /* ������                                                         */
  hcountry       dtext20,     /* �����                                                         */
  hdistrict      dtext20,
  hphone         dtext20,

  /* �������� �������� */
  wcompanykey    dforeignkey,
  wcompanyname   dtext60,     /* ��������                                                       */
  wdepartment    dtext20,     /* ���������������                                                */
  wpositionkey   dforeignkey,

  /* ������������ �������� */
  spouse         dtext20,     /* ������/�������                                                 */
  children       dtext20,     /* �����                                                         */
  sex            dgender,     /* ���                                                            */
  birthday       ddate,        /* ���� �����������                                               */

  /* ���������� �������� */
  passportnumber dtext40,     /* ����� �������� */
  /*passportdate   ddate,*/       /* ??? */
  passportexpdate ddate,      /* ����� ������� �������� */
  passportissdate ddate,      /* ���� ������ */
  passportissuer dtext40,     /* ��� ���� */
  passportisscity dtext20,    /* ��� ��������� */
  personalnumber dtext40,     /* ����������� ����� */

  /*�����*/

  /* ���������� ���������� */
  visitcard      dBMP,        /* ³����� ������                                                */
  photo          dBMP         /* ����                                                           */
);

ALTER TABLE gd_people
  ADD CONSTRAINT gd_pk_people PRIMARY KEY (contactkey);

ALTER TABLE gd_people ADD CONSTRAINT gd_fk_people_contactkey
  FOREIGN KEY (contactkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

/* ��� ���������� �������� �� ���� ����������� ������� */
/* ������ ��������� -- �������� ����� �������� � ��   */
ALTER TABLE gd_people ADD CONSTRAINT gd_fk_people_companykey
  FOREIGN KEY (wcompanykey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;

ALTER TABLE gd_people ADD CONSTRAINT gd_fk_people_positionkey
  FOREIGN KEY (wpositionkey) REFERENCES wg_position(id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;

ALTER TABLE gd_people ADD CONSTRAINT gd_fk_people_hplacekey
  FOREIGN KEY (hplacekey) REFERENCES gd_place(id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;

COMMIT;

SET TERM ^ ;

CREATE TRIGGER gd_bi_people FOR gd_people
  BEFORE INSERT
  POSITION 0
AS
BEGIN
  NEW.rank = NULL;
  SELECT SUBSTRING(name FROM 1 FOR 20) FROM wg_position WHERE id = NEW.wpositionkey
    INTO NEW.rank;

  IF (NOT NEW.wcompanykey IS NULL) THEN
  BEGIN
    SELECT name FROM gd_contact WHERE id = NEW.wcompanykey
      INTO NEW.wcompanyname;
  END
END
^

CREATE TRIGGER gd_bu_people FOR gd_people
  BEFORE UPDATE
  POSITION 0
AS
BEGIN
  NEW.rank = NULL;
  SELECT SUBSTRING(name FROM 1 FOR 20) FROM wg_position WHERE id = NEW.wpositionkey
    INTO NEW.rank;

  IF (NOT NEW.wcompanykey IS NULL) THEN
  BEGIN
    SELECT name FROM gd_contact WHERE id = NEW.wcompanykey
      INTO NEW.wcompanyname;
  END
END
^

CREATE OR ALTER TRIGGER gd_biu_people_pn FOR gd_people
  ACTIVE
  BEFORE INSERT OR UPDATE
  POSITION 32000
AS
BEGIN
  IF (CHAR_LENGTH(NEW.personalnumber) > 0
    AND (INSERTING OR NEW.personalnumber IS DISTINCT FROM OLD.personalnumber)) THEN
  BEGIN
    NEW.personalnumber = UPPER(TRIM(NEW.personalnumber));
    NEW.personalnumber =
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(
                            NEW.personalnumber,
                            '�', 'X'),
                          '�', 'T'),
                        '�', 'C'),
                      '�', 'P'),
                    '�', 'O'),
                  '�', 'H'),
                '�', 'M'),
              '�', 'K'),
            '�', 'E'),
          '�', 'A'),
        '�', 'B');
  END
  
  IF (CHAR_LENGTH(NEW.passportnumber) > 0
    AND (INSERTING OR NEW.passportnumber IS DISTINCT FROM OLD.passportnumber)) THEN
  BEGIN
    NEW.passportnumber = UPPER(TRIM(NEW.passportnumber));
    NEW.passportnumber =
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(
                            NEW.passportnumber,
                            '�', 'X'),
                          '�', 'T'),
                        '�', 'C'),
                      '�', 'P'),
                    '�', 'O'),
                  '�', 'H'),
                '�', 'M'),
              '�', 'K'),
            '�', 'E'),
          '�', 'A'),
        '�', 'B');
  END
END
^

SET TERM ; ^

COMMIT;

CREATE TABLE gd_employee 
(
  contactkey        dintkey,
  
  CONSTRAINT gd_pk_employee PRIMARY KEY (contactkey),
  CONSTRAINT gd_fk_employee_contactkey FOREIGN KEY (contactkey)
    REFERENCES gd_people (contactkey)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE gd_company
(
  contactkey        dintkey,     /* �������  */
  companyaccountkey dforeignkey, /* ��������� ���� */
  headcompany       dforeignkey, /* �������� �������� */
  /* ���?��� ���� ������ ��������� ����� */
  fullname          dtext180,    /* ������ ����������� */
  companytype       dtext20,     /* ��� �������� */
  directorkey       dforeignkey,
  chiefaccountantkey dforeignkey,
  logo              dBMP         /* ������� */
);

ALTER TABLE gd_company
  ADD CONSTRAINT gd_pk_company PRIMARY KEY (contactkey);

ALTER TABLE gd_company ADD CONSTRAINT gd_fk_company_contactkey
  FOREIGN KEY (contactkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE gd_company ADD CONSTRAINT gd_fk_company_headcompany
  FOREIGN KEY (headcompany) REFERENCES gd_company(contactkey)
  ON UPDATE CASCADE;

ALTER TABLE gd_company ADD CONSTRAINT gd_fk_company_directorkey
  FOREIGN KEY (directorkey) REFERENCES gd_people(contactkey)
  ON UPDATE CASCADE;

ALTER TABLE gd_company ADD CONSTRAINT gd_fk_company_chiefacckey
  FOREIGN KEY (chiefaccountantkey) REFERENCES gd_people(contactkey)
  ON UPDATE CASCADE;

ALTER TABLE gd_currrate ADD CONSTRAINT gd_fk3_currrate
  FOREIGN KEY (regulatorkey) REFERENCES gd_company (contactkey) ON UPDATE CASCADE;      

CREATE TABLE gd_companycode
(
  companykey    dintkey,
  legalnumber   dtext20,
  taxid         dtext20,
  okulp         dtext20,
  okpo          dtext20,
  oknh          dtext20,
  soato         dtext20,
  soou          dtext20,
  licence       dtext40
);

ALTER TABLE gd_companycode
  ADD CONSTRAINT gd_pk_companycode PRIMARY KEY (companykey);

/* ���� -- ���������� ���������� ��� ��������, ����, ��� */
/* ���������� �������� ������ � ����                     */
ALTER TABLE gd_companycode ADD CONSTRAINT gd_fk_companycode_contackey
  FOREIGN KEY (companykey) REFERENCES gd_company(contactkey)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

CREATE TABLE gd_bank
(
  bankkey     dintkey,      /*                           */
  bankcode    dtext20 NOT NULL,
  bankbranch  dtext20,
  bankMFO     dtext20,
  SWIFT       dtext20,
  
  oldbankcode dtext20,
  oldbankMFO  dtext20
);

COMMIT;

ALTER TABLE gd_bank ADD CONSTRAINT gd_pk_bank
  PRIMARY KEY (bankkey);

ALTER TABLE gd_bank ADD CONSTRAINT gd_fk_bank_bankkey
  FOREIGN KEY (bankkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

CREATE INDEX gd_x_bank_bankcode
  ON gd_bank (bankcode);
  
SET TERM ^ ;

CREATE OR ALTER TRIGGER gd_biu_bank FOR gd_bank
  ACTIVE
  BEFORE INSERT OR UPDATE
  POSITION 32000
AS
  DECLARE VARIABLE d_name VARCHAR(60);
  DECLARE VARIABLE d_id DFOREIGNKEY;
BEGIN
  IF (INSERTING OR NEW.bankcode <> OLD.bankcode) THEN
  BEGIN
    NEW.bankMFO = NEW.bankcode;
    NEW.SWIFT = NEW.bankcode;    
  END ELSE
  BEGIN
    IF (NEW.bankMFO IS NOT NULL AND NEW.bankMFO IS DISTINCT FROM OLD.bankMFO) THEN
    BEGIN
      NEW.bankcode = NEW.bankMFO;
      NEW.SWIFT = NEW.bankMFO;
    END ELSE
    BEGIN
      IF (NEW.SWIFT IS NOT NULL AND NEW.SWIFT IS DISTINCT FROM OLD.SWIFT) THEN
      BEGIN
        NEW.bankcode = NEW.SWIFT;
        NEW.bankMFO = NEW.SWIFT;
      END
    END
  END    

  /* IF (NOT (NEW.bankcode SIMILAR TO '[A-Z]{6}([A-Z0-9]{2}|[A-Z0-9]{5})')) THEN
    EXCEPTION gd_e_exception '�������� ������ BIC "' || NEW.bankcode || '"'; */
    
  FOR
    SELECT c.id, c.name 
    FROM gd_contact c JOIN gd_bank b ON b.bankkey = c.id    
    WHERE b.bankkey <> NEW.bankkey AND b.bankcode = NEW.bankcode
      AND b.bankbranch IS NOT DISTINCT FROM NEW.bankbranch
    INTO :d_id, :d_name
  DO     
    EXCEPTION gd_e_exception '����������� BIC � ����� "' || :d_name || '", ��=' || :d_id;
END
^  

SET TERM ; ^

COMMIT;

/* ���� ������*/
CREATE TABLE GD_COMPACCTYPE
(
  id          dintkey,
  name        dname,
  editiondate deditiondate
);

COMMIT;

ALTER TABLE gd_compacctype ADD CONSTRAINT gd_pk_compacctype_id
  PRIMARY KEY (id);

COMMIT;

SET TERM ^ ;

CREATE TRIGGER gd_bi_compacctype FOR gd_compacctype
  BEFORE INSERT
  POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = GEN_ID(gd_g_unique, 1) + GEN_ID(gd_g_offset, 0);
END
^

SET TERM ; ^

CREATE TABLE gd_companyaccount
(
  id             dintkey,            /* ��������� �������������                   */
  companykey     dmasterkey,         /* ��������, ���� �������� �������           */
  bankkey        dintkey,            /* �������� �� ����                          */
  payername      dtext60,            /* ����� ������ ��� ��������� ���������    */
  account        dbankaccount NOT NULL,       /* �������                                   */
  currkey        dforeignkey,        /* ������, � ���� ������� �������            */
  accounttypekey dforeignkey,        /* ��� ���� ������� (��������, ������...)   */
  disabled       dboolean DEFAULT 0,

  accounttype    dtext20,            /* ��� ������������� � ���������� �������    */
  
  oldaccount     dbankaccount,
  iban           dbankaccount,
  
  editiondate    deditiondate
);

ALTER TABLE gd_companyaccount ADD CONSTRAINT gd_pk_companyaccount
  PRIMARY KEY (id);

ALTER TABLE gd_companyaccount ADD CONSTRAINT gd_fk_companyaccount_bankkey
  FOREIGN KEY (bankkey) REFERENCES gd_bank(bankkey);

ALTER TABLE gd_companyaccount ADD CONSTRAINT gd_fk_companyaccount_currkey
  FOREIGN KEY (currkey) REFERENCES gd_curr(id)
  ON UPDATE CASCADE;

ALTER TABLE gd_companyaccount ADD CONSTRAINT gd_fk_companyaccount_acctypekey
  FOREIGN KEY (accounttypekey) REFERENCES gd_compacctype(id)
  ON UPDATE CASCADE;

/* ������ -- ���������� ���������� ��� ��������, ����, ��� */
/* ���������� �������� ������ � ����                        */
ALTER TABLE gd_companyaccount ADD CONSTRAINT gd_fk_companyaccount_companykey
  FOREIGN KEY (companykey) REFERENCES gd_company(contactkey)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

ALTER TABLE gd_company ADD CONSTRAINT gd_fk_company_companyaccountkey
  FOREIGN KEY (companyaccountkey) REFERENCES gd_companyaccount(id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;
  
SET TERM ^ ;

CREATE OR ALTER TRIGGER gd_biu_companyaccount FOR gd_companyaccount
  ACTIVE
  BEFORE INSERT OR UPDATE
  POSITION 30000
AS
  DECLARE VARIABLE hc DFOREIGNKEY = NULL;
  DECLARE VARIABLE c_id DFOREIGNKEY = NULL;
  DECLARE VARIABLE c_name dtext180 = NULL;
BEGIN
  IF (INSERTING OR NEW.account <> OLD.account) THEN
  BEGIN    
    /* IF (NOT (NEW.account SIMILAR TO '[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{4}[A-Z0-9]{16}')) THEN
      EXCEPTION gd_e_exception '�������� ������ IBAN "' || NEW.account || '"'; */
      
    NEW.iban = NEW.account;

    SELECT
      co.headcompany
    FROM
      gd_company co
    WHERE
      co.contactkey = NEW.companykey
    INTO
      :hc;    
      
    FOR      
      SELECT
        co.contactkey, co.fullname
      FROM 
        gd_company co JOIN gd_companyaccount acc ON acc.companykey = co.contactkey
      WHERE
        acc.account = NEW.account
        AND
        acc.id <> NEW.id
        AND
        (
          (:hc IS NULL)
          OR
          (co.headcompany IS DISTINCT FROM :hc)
        )
      INTO :c_id, :c_name
    DO      
      EXCEPTION gd_e_exception '����������� IBAN � ����������� "' || :c_name || '", ��=' || :c_id;           
  END    
END
^  

SET TERM ; ^

COMMIT;

CREATE TABLE gd_contactlist
(
  groupkey      dintkey,
  contactkey    dintkey,
  reserved      dinteger

);

COMMIT;

ALTER TABLE gd_contactlist
  ADD CONSTRAINT gd_pk_contactlist PRIMARY KEY (groupkey, contactkey);

ALTER TABLE gd_contactlist ADD CONSTRAINT gd_fk_contract_contactlist
  FOREIGN KEY (contactkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

/* ��� ���������� ������ -- ������ � ��� ����� �������� � �� */
ALTER TABLE gd_contactlist ADD CONSTRAINT gd_fk_group_contactlist
  FOREIGN KEY (groupkey) REFERENCES gd_contact(id)
  ON UPDATE CASCADE
  ON DELETE CASCADE;

COMMIT;

/* ����� ���������, �������� � ������ ��������� */

CREATE OR ALTER VIEW GD_V_CONTACTLIST
(
  ID, CONTACTNAME, CONTACTTYPE,
  GROUPNAME, GROUPID, GROUPLB, GROUPRB, GROUPTYPE
) AS
SELECT
  P.ID, P.NAME, P.CONTACTTYPE, C.NAME, C.ID, C.LB, C.RB, C.CONTACTTYPE

FROM
  GD_CONTACT C
    JOIN GD_CONTACTLIST CL ON (C.ID = CL.CONTACTKEY)
    JOIN GD_CONTACT P ON (CL.GROUPKEY = P.ID)

GROUP BY
  P.ID, P.NAME, P.CONTACTTYPE, C.NAME, C.ID, C.LB, C.RB, C.CONTACTTYPE
;

COMMIT;


SET TERM ^ ;


CREATE PROCEDURE gd_p_SetCompanyToPeople(Department DFOREIGNKEY)
AS
  DECLARE VARIABLE companykey DFOREIGNKEY;
BEGIN

  SELECT MIN(comp.id)
    FROM gd_contact comp,
         gd_contact dep
    WHERE dep.id = :Department AND comp.lb <= dep.lb AND
      comp.rb >= dep.rb AND comp.contacttype = 3 INTO :companykey;

  IF (:COMPANYKEY IS NOT NULL) THEN
    UPDATE gd_people p
    SET wcompanykey = :companykey
    WHERE contactkey in
    (SELECT contactkey FROM gd_contactlist cl WHERE groupkey = :Department)
    AND (p.wcompanykey IS NULL);

END
^


CREATE TRIGGER gd_bi_companyaccount FOR gd_companyaccount
  BEFORE INSERT
  POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = GEN_ID(gd_g_unique, 1) + GEN_ID(gd_g_offset, 0);
END
^

CREATE EXCEPTION gd_e_invalid_contact_parent 'Invalid contact parent'
^

CREATE OR ALTER TRIGGER gd_bi_contact FOR gd_contact
  BEFORE INSERT
  POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL) THEN
    NEW.id = GEN_ID(gd_g_unique, 1) + GEN_ID(gd_g_offset, 0);

  IF (NEW.name IS NULL) THEN
    NEW.name = '<' || NEW.id || '>';

  IF (NEW.CONTACTTYPE = 0 OR NEW.CONTACTTYPE = 4) THEN
    RDB$SET_CONTEXT('USER_TRANSACTION', 'LBRB_DELTA', '100');
  ELSE
    RDB$SET_CONTEXT('USER_TRANSACTION', 'LBRB_DELTA', '1');
END
^

/*

  ��� ������� ���������� �������� ������ ��������
  ��� ���.

*/

CREATE EXCEPTION gd_e_cannot_change_contact_type 'Can not change contact type'
^

CREATE TRIGGER gd_bu_contact_3 FOR gd_contact
  BEFORE UPDATE
  POSITION 3
AS
BEGIN
  IF (NEW.contacttype <> OLD.contacttype) THEN
  BEGIN
    EXCEPTION gd_e_cannot_change_contact_type;
  END
END
^

CREATE EXCEPTION gd_e_invalid_contact_type 'Invalid contact type'
^

CREATE TRIGGER gd_bi_company_1000 FOR gd_company
  BEFORE INSERT
  POSITION 1000
AS
BEGIN
  IF (EXISTS(SELECT contacttype FROM gd_contact WHERE id=NEW.contactkey AND contacttype<3)) THEN
  BEGIN
    EXCEPTION gd_e_invalid_contact_type;
  END
END
^

/*
 *  �� ������� ��������� �� ����� ���������� � ������
 *  ���������. !!!
 *
 */

CREATE PROCEDURE gd_p_getfolderelement(parent DFOREIGNKEY)
RETURNS
(
  id          DFOREIGNKEY,
  contacttype INTEGER,
  name        VARCHAR(60),
  phone       VARCHAR(60),
  address     VARCHAR(60),
  email       VARCHAR(60),

  afull       INTEGER,
  achag       INTEGER,
  aview       INTEGER
)
AS
  DECLARE VARIABLE N DFOREIGNKEY;
BEGIN
  FOR SELECT id, contacttype, name, phone, address, email, afull, achag, aview
    FROM gd_contact
    WHERE parent = :parent
    ORDER BY name
    INTO :id, :contacttype, :name, :phone, :address, :email, :afull, :achag, :aview DO
  BEGIN
    IF (:contacttype = 0) THEN
    BEGIN
      N = :ID;
      FOR
        SELECT id, contacttype, name, phone, address, email, afull, achag, aview
          FROM gd_p_getfolderelement(:N)
          INTO :id, :contacttype, :name, :phone, :address, :email, :afull, :achag, :aview
      DO
        SUSPEND;
    END
    ELSE
      SUSPEND;
  END
END
^

SET TERM ; ^

/* ������ ������ ����������� �������� � �������� � ��� �������� */

CREATE TABLE gd_holding (
  holdingkey dintkey,
  companykey dintkey
);

ALTER TABLE gd_holding ADD CONSTRAINT gd_pk_holding
  PRIMARY KEY (holdingkey, companykey);

ALTER TABLE gd_holding ADD  CONSTRAINT gd_fk_holding_companykey
  FOREIGN KEY (companykey) REFERENCES gd_company (contactkey)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE gd_holding ADD  CONSTRAINT gd_fk_holding_holdingkey
  FOREIGN KEY (holdingkey) REFERENCES gd_company (contactkey)
  ON DELETE CASCADE ON UPDATE CASCADE;

COMMIT;

CREATE OR ALTER VIEW GD_V_COMPANY(
    ID,
    COMPNAME,
    COMPFULLNAME,
    COMPANYTYPE,
    COMPLB,
    COMPRB,
    AFULL,
    ACHAG,
    AVIEW,
    ADDRESS,
    CITY,
    COUNTRY,
    PHONE,
    FAX,
    ACCOUNT,
    BANKCODE,
    BANKMFO,
    BANKNAME,
    BANKADDRESS,
    BANKCITY,
    BANKCOUNTRY,
    TAXID,
    OKULP,
    OKPO,
    LICENCE,
    OKNH,
    SOATO,
    SOOU)
AS
SELECT
  C.ID, C.NAME, COMP.FULLNAME, COMP.COMPANYTYPE, 
  C.LB, C.RB, C.AFULL, C.ACHAG, C.AVIEW,
  C.ADDRESS, C.CITY, C.COUNTRY, C.PHONE, C.FAX,
  AC.ACCOUNT, BANK.BANKCODE, BANK.BANKMFO,
  BANKC.NAME, BANKC.ADDRESS, BANKC.CITY, BANKC.COUNTRY,
  CC.TAXID, CC.OKULP, CC.OKPO, CC.LICENCE, CC.OKNH, CC.SOATO, CC.SOOU

FROM
    GD_CONTACT C
    JOIN GD_COMPANY COMP ON (COMP.CONTACTKEY = C.ID)
    LEFT JOIN GD_COMPANYACCOUNT AC ON COMP.COMPANYACCOUNTKEY = AC.ID
    LEFT JOIN GD_BANK BANK ON AC.BANKKEY = BANK.BANKKEY
    LEFT JOIN GD_COMPANYCODE CC ON COMP.CONTACTKEY = CC.COMPANYKEY
    LEFT JOIN GD_CONTACT BANKC ON BANK.BANKKEY = BANKC.ID
;

COMMIT;