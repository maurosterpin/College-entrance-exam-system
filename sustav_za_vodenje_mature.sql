DROP DATABASE IF EXISTS sustav_za_vodjenje_drzavne_mature;
CREATE DATABASE sustav_za_vodjenje_drzavne_mature;
USE sustav_za_vodjenje_drzavne_mature;

CREATE TABLE grad (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
naziv VARCHAR(50) NOT NULL,
postanski_broj INTEGER NOT NULL UNIQUE
);

CREATE TABLE skola (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
naziv VARCHAR(100) NOT NULL,
broj_mjesta INTEGER NOT NULL,
id_grad INTEGER NOT NULL,
FOREIGN KEY (id_grad) REFERENCES grad (id),
CONSTRAINT ogranicenja_broja CHECK (broj_mjesta > 20 AND broj_mjesta < 1500)
);

CREATE TABLE predmet (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
naziv VARCHAR(50) NOT NULL,
obavezan_izborni VARCHAR(8) DEFAULT 'izborni'
);

CREATE TABLE razina (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
naziv VARCHAR(20) NOT NULL
);

CREATE TABLE ucenik (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
ime VARCHAR(50) NOT NULL,
prezime VARCHAR(50) NOT NULL,
oib VARCHAR(11) NOT NULL UNIQUE,
datum_rodjenja DATE NOT NULL,
spol CHAR(1) NOT NULL,
id_grad INTEGER NOT NULL,
id_skola INTEGER NOT NULL,
email VARCHAR(100) NOT NULL,
FOREIGN KEY (id_grad) REFERENCES grad (id),
FOREIGN KEY (id_skola) REFERENCES skola (id),
CHECK(LENGTH(oib) = 11)
);

CREATE TABLE voditelj (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
ime VARCHAR(50) NOT NULL,
prezime VARCHAR(50) NOT NULL,
oib VARCHAR(11) NOT NULL UNIQUE,
id_grad INTEGER NOT NULL,
email VARCHAR(100),
FOREIGN KEY (id_grad) REFERENCES grad (id),
CHECK(LENGTH(oib) = 11)
);

CREATE TABLE termin_ispita (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
vrsta_roka VARCHAR(50) NOT NULL,
datum_ispita DATE NOT NULL
);

CREATE TABLE vrijeme (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
duljina_trajanja INTEGER NOT NULL,
pocetak TIME NOT NULL
);

CREATE TABLE matura (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
id_predmet INTEGER NOT NULL,
id_termin_ispita INTEGER NOT NULL,
id_vrijeme INTEGER NOT NULL,
id_razina INTEGER NOT NULL,
opis VARCHAR(5) DEFAULT 'test',
FOREIGN KEY (id_predmet) REFERENCES predmet (id),
FOREIGN KEY (id_termin_ispita) REFERENCES termin_ispita (id),
FOREIGN KEY (id_vrijeme) REFERENCES vrijeme (id),
FOREIGN KEY (id_razina) REFERENCES razina (id)
);

CREATE TABLE ocjenjivac (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
ime VARCHAR(50) NOT NULL,
prezime VARCHAR(50) NOT NULL,
oib VARCHAR(11) NOT NULL UNIQUE,
id_grad INTEGER NOT NULL,
email VARCHAR(100),
FOREIGN KEY (id_grad) REFERENCES grad (id),
CHECK(LENGTH(oib) = 11)
);

CREATE TABLE ocjena_na_maturi (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
ocjena INTEGER,
broj_bodova DECIMAL(5,2),
id_matura INTEGER NOT NULL,
id_ucenik INTEGER NOT NULL,
id_ocjenjivac INTEGER,
ocjenjeno VARCHAR(15),
FOREIGN KEY (id_matura) REFERENCES matura (id),
FOREIGN KEY (id_ucenik) REFERENCES ucenik (id),
FOREIGN KEY (id_ocjenjivac) REFERENCES ocjenjivac (id),
UNIQUE(id_ucenik, id_matura)
);

CREATE TABLE prigovor (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
tema_prigovora VARCHAR(30) NOT NULL,
opis_prigovora VARCHAR(200) NOT NULL,
id_ocjena_na_maturi INTEGER NOT NULL,
FOREIGN KEY (id_ocjena_na_maturi) REFERENCES ocjena_na_maturi (id)
);

CREATE TABLE edukacija_termin (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
termin_edukacije DATETIME NOT NULL,
id_predmet INTEGER NOT NULL,
FOREIGN KEY (id_predmet) REFERENCES predmet (id) 
);

CREATE TABLE edukacija (
id INTEGER PRIMARY KEY AUTO_INCREMENT,
id_ocjenjivac INTEGER NOT NULL,
id_edukacija_termin INTEGER NOT NULL,
FOREIGN KEY (id_edukacija_termin) REFERENCES edukacija_termin (id),
FOREIGN KEY (id_ocjenjivac) REFERENCES ocjenjivac (id)
);

-- OKIDAČI
-- Nije moguće pisati ispite u školi koja ima manje od 20 ili više od 1500 mjesta
DELIMITER //
CREATE TRIGGER bi_skola
 BEFORE INSERT ON skola
 FOR EACH ROW
BEGIN
 IF new.broj_mjesta < 20 THEN
 SET new.broj_mjesta = 20;
 END IF;
 IF new.broj_mjesta > 1500 THEN 
 SET new.broj_mjesta = 1500;
 END IF;
END//
DELIMITER ;

-- Termin izvođenja ispita ne može biti prije završetka nastave u školskoj godini
DELIMITER //
CREATE TRIGGER ai_termin_ispita
 AFTER INSERT ON termin_ispita
 FOR EACH ROW
BEGIN
 IF new.datum_ispita < STR_TO_DATE('30.05.2022.', '%d.%m.%Y.') THEN
 SIGNAL SQLSTATE '40000'
 SET MESSAGE_TEXT = 'Ne možeš staviti željeni datum izvođenja ispita!';
 END IF; 
END//
DELIMITER ;

-- Datum izvođenja edukacije nije moguće promijeniti
DELIMITER //
CREATE TRIGGER bu_edukacija_termin
 BEFORE UPDATE ON edukacija_termin
 FOR EACH ROW
BEGIN
 IF new.termin_edukacije != old.termin_edukacije THEN
 SET new.termin_edukacije = old.termin_edukacije;
 END IF;
END//
DELIMITER ;

-- Ako ocjena nije unesena u opis se unosi da ispit još nije ocjenjen
DELIMITER //
CREATE TRIGGER bi_ocjena_na_maturi
 BEFORE INSERT ON ocjena_na_maturi
 FOR EACH ROW
BEGIN
 IF new.ocjena = NULL THEN
 SET new.ocjenjeno = 'Nije ocjenjeno';
 END IF;
END//
DELIMITER ;

-- Određivanje ocjene prema broju bodova na nekom ispitu
DELIMITER //
CREATE TRIGGER bi_ocjena_na_maturi_
 BEFORE INSERT ON ocjena_na_maturi
 FOR EACH ROW
BEGIN
 IF new.broj_bodova BETWEEN 0 AND 36.99 THEN
 SET new.ocjena = 1;
 ELSEIF new.broj_bodova BETWEEN 37.00 AND 52.99 THEN
 SET new.ocjena = 2;
 ELSEIF new.broj_bodova BETWEEN 53.00 AND 69.99 THEN
 SET new.ocjena = 3;
 ELSEIF new.broj_bodova BETWEEN 70.00 AND 81.99 THEN
 SET new.ocjena = 4;
 ELSEIF new.broj_bodova BETWEEN 82.00 AND 100.00 THEN
 SET new.ocjena = 5;
 ELSE 
  SET new.ocjena = NULL;
 END IF;
END//
DELIMITER ;

-- Određivanje ocjene prema broju bodova na nekom ispitu
DELIMITER //
CREATE TRIGGER bu_ocjena_na_maturi_
 BEFORE UPDATE ON ocjena_na_maturi
 FOR EACH ROW
BEGIN
 IF new.broj_bodova BETWEEN 0 AND 36.99 THEN
 SET new.ocjena = 1;
 ELSEIF new.broj_bodova BETWEEN 37.00 AND 52.99 THEN
 SET new.ocjena = 2;
 ELSEIF new.broj_bodova BETWEEN 53.00 AND 69.99 THEN
 SET new.ocjena = 3;
 ELSEIF new.broj_bodova BETWEEN 70.00 AND 81.99 THEN
 SET new.ocjena = 4;
 ELSEIF new.broj_bodova BETWEEN 82.00 AND 100.00 THEN
 SET new.ocjena = 5;
 ELSE 
  SET new.ocjena = NULL;
 END IF;
END//
DELIMITER ;

-- Pri brisanju ucenika se ocjena_na_maturi brise
DELIMITER //
CREATE TRIGGER bd_ucenik
 BEFORE DELETE ON ucenik
 FOR EACH ROW
BEGIN
 DELETE FROM ocjena_na_maturi WHERE id_ucenik = old.id;
END//
DELIMITER ;

-- Provjerava postoji li osoba s odredenim oib-om
DROP PROCEDURE IF EXISTS postoji_li_oib;
DELIMITER //
CREATE PROCEDURE postoji_li_oib (IN p_oib CHAR(11), OUT rez INTEGER)
BEGIN
 DECLARE temp CHAR(11);
 DECLARE brojac INTEGER DEFAULT 0;
 DECLARE temp_rez INTEGER DEFAULT 0;
 
 DECLARE cur CURSOR FOR
	SELECT oib FROM ucenik;
 DECLARE cur2 CURSOR FOR
	SELECT oib FROM voditelj;
  DECLARE cur3 CURSOR FOR
	SELECT oib FROM ocjenjivac;
 DECLARE EXIT HANDLER
		FOR NOT FOUND SET temp_rez = 0;
 OPEN cur;
 OPEN cur2;
 OPEN cur3;
  petlja: LOOP
    FETCH cur INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
     FETCH cur2 INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
    FETCH cur3 INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
 END LOOP petlja;
 
 CLOSE cur;
 CLOSE cur2;
 CLOSE cur3;
END //
DELIMITER ;

-- Kod unosa provjerava nalazi li se oib u ikojoj drugoj tablici
/*DELIMITER //
CREATE TRIGGER bi_ucenik
 BEFORE INSERT ON ucenik
 FOR EACH ROW
BEGIN
 DECLARE rez INTEGER;
 CALL postoji_li_oib (new.oib, @rez);
 SELECT @rez INTO rez;
 IF rez = 1 THEN
	SIGNAL SQLSTATE '40001'
	SET MESSAGE_TEXT = 'oib vec postoji';
 END IF;
END//
DELIMITER ;*/

INSERT INTO grad VALUES
(NULL, 'Pula', 52100),
(NULL, 'Rovinj', 52210),
(NULL, 'Poreč',	52440),
(NULL, 'Vodnjan', 52215),
(NULL, 'Pazin',	52000),
(NULL, 'Rijeka', 51000),
(NULL, 'Delnice', 51300),
(NULL, 'Umag', 52470),
(NULL, 'Opatija', 51410),
(NULL, 'Novigrad', 52466),
(NULL, 'Zagreb', 10000),
(NULL, 'Osijek', 31000),
(NULL, 'Split',	21000),
(NULL, 'Dubrovnik', 20000),
(NULL, 'Knin', 22300),
(NULL, 'Šibenik', 22000),
(NULL, 'Vukovar', 32000),
(NULL, 'Bjelovar', 43000),
(NULL, 'Zadar',	23000),
(NULL, 'Požega', 34000),
(NULL, 'Slavonski Brod', 35000),
(NULL, 'Karlovac', 47000),
(NULL, 'Virovitica', 33000),
(NULL, 'Ogulin', 47300),
(NULL, 'Varaždin',	42000),
(NULL, 'Sisak',	44000),
(NULL, 'Čakovec', 40000),
(NULL, 'Buzet',	52420),
(NULL, 'Trogir', 21220),
(NULL, 'Makarska', 21300);

INSERT INTO skola VALUES 
(NULL, 'Gimnazija Pula', 100, 1),
(NULL, 'Srednja škola Zvane Črnje Rovinj', 145, 2),
(NULL, 'Srednja škola Mate Balote', 200, 3),
(NULL, 'Gimnazija Josipa Slavenskog Čakovec', 210, 27),
(NULL, 'Agronomska škola Zagreb', 150, 11),
(NULL, 'Strukovna škola Virovitica', 167, 23),
(NULL, 'Tehnička škola Nikole Teste', 173, 17),
(NULL, 'Obrtnička škola Gojka Matune Zadar', 175, 19),
(NULL, 'Obrtnička škola Gojka Matune Zadar', 180, 13),
(NULL, 'Srednja medicinska škola', 235, 21),
(NULL, 'Ekonomska škola Sisak', 343, 26),
(NULL, 'Strojarska i prometna škola', 152, 25),
(NULL, 'Hotelijersko-turistička škola u Zagrebu', 156, 11),
(NULL, 'Srednja škola Ivana Lucića Trogir', 200, 29),
(NULL, 'Srednja strukovna škola Šibenik', 1200, 16),
(NULL, 'Gimnazija Osijek', 220, 12),
(NULL, 'Medicinska škola Osijek', 300, 12),
(NULL, 'Strojarska tehnička škola Osijek', 200, 12),
(NULL, 'Gimnazija i strukovna škola Jurja Dobrile Pazin', 140, 5),
(NULL, 'Klasična gimnazija Pazin', 200, 5),
(NULL, 'Škola za odgoj i obrazovanje Pula', 150, 1),
(NULL, 'Škola za turizam, ugostiteljstvo i trgovinu', 300, 1),
(NULL, 'Industrijsko - obrtnička škola Pula', 250, 1),
(NULL, 'Škola primijenjenih umjetnosti i dizajna Pula', 900, 1),
(NULL, 'Strojarska škola za industrijska i obrtnička zanimanja', 400, 6),
(NULL, 'Srednja škola za elektrotehniku i računalstvo', 303, 6),
(NULL, 'Tehnička škola Rijeka', 256, 6),
(NULL, 'Srednja škola Andrije Ljudevita Adamića', 340, 6),
(NULL, 'Medicinska škola Dubrovnik', 164, 14),
(NULL, 'Gimnazija Dubrovnik', 255, 14);

INSERT INTO predmet VALUES
(NULL,	'Hrvatski', 'obavezan'),
(NULL,	'Engleski', 'obavezan'),
(NULL,	'Matematika', 'obavezan'),
(NULL,	'Francuski jezik', 'obavezan'),
(NULL,	'Njemački jezik', 'obavezan'),
(NULL,	'Španjolski jezik',	'obavezan'),
(NULL,	'Talijanski jezik',	'obavezan'),
(NULL,	'Grčki jezik', 'obavezan'),
(NULL,	'Latinski jezik', 'obavezan'),
(NULL,	'Biologija', 'izborni'),
(NULL,	'Etika', 'izborni'),
(NULL,	'Filozofija', 'izborni'),
(NULL,	'Fizika', 'izborni'),
(NULL,	'Geografija', 'izborni'),
(NULL,	'Glazbena umjetnost', 'izborni'),
(NULL,	'Informatika', 'izborni'),
(NULL,	'Kemija', 'izborni'),
(NULL,	'Likovna umjetnost', 'izborni'),
(NULL,	'Logika', 'izborni'),
(NULL,	'Politika i gospodarstvo', 'izborni'),
(NULL,	'Povijest', 'izborni'),
(NULL,	'Psihologija', 'izborni'),
(NULL,	'Socijologija',	'izborni'),
(NULL,  'Vjeronauk', 'izborni');

INSERT INTO razina VALUES
(NULL, 'A'),
(NULL, 'B'),
(NULL, 'jedna_razina');

INSERT INTO ucenik VALUES
(NULL, 'Luka', 'Vuković', '66527714272', STR_TO_DATE('02.03.2003.', '%d.%m.%Y.'),'m', 2, 2, 'Luka@student.hr'),
(NULL, 'Mia', 'Babić', '45714272641', STR_TO_DATE('01.09.2003.', '%d.%m.%Y.'),'ž', 1, 1, 'Mia@student.hr'),
(NULL, 'Sara', 'Novak', '87726410619', STR_TO_DATE('02.09.2001.', '%d.%m.%Y.'),'ž', 3, 3, 'Sara@student.hr'),
(NULL, 'Lana', 'Lazarić', '75482958841', STR_TO_DATE('15.09.2003.', '%d.%m.%Y.'),'ž', 1, 21, 'Lana@student.hr'),
(NULL, 'Marko', 'Marković', '86945032811', STR_TO_DATE('27.08.2003.', '%d.%m.%Y.'),'m', 12, 18, 'Marko@student.hr'),
(NULL, 'Ivan', 'Mazin', '65748890988', STR_TO_DATE('15.09.2001.', '%d.%m.%Y.'),'m', 14, 30, 'Ivan@student.hr'),
(NULL, 'Matej', 'Marić', '54578923310', STR_TO_DATE('27.03.2003.', '%d.%m.%Y.'),'m', 16, 15, 'Matej@student.hr'),
(NULL, 'Klara', 'Klarić', '09788655456', STR_TO_DATE('01.11.2003.', '%d.%m.%Y.'),'ž', 17, 7, 'Klara@student.hr'),
(NULL, 'Denis', 'Vukić', '23433567981', STR_TO_DATE('22.07.2002.', '%d.%m.%Y.'),'m', 21, 10, 'Denis@student.hr'),
(NULL, 'Petar', 'Perin', '09885766442',	STR_TO_DATE('15.03.2003.', '%d.%m.%Y.'),'m', 13, 9, 'Petar@student.hr'),
(NULL, 'Robert', 'Josin', '99878854563', STR_TO_DATE('30.08.2003.', '%d.%m.%Y.'),'m', 19, 8, 'Robert@student.hr'),
(NULL, 'Zoran', 'Budić', '87756673552', STR_TO_DATE('15.04.2003.', '%d.%m.%Y.'),'m', 1, 24, 'Luka@student.hr'),
(NULL, 'Maja', 'Borin', '55466378821', STR_TO_DATE('12.02.2003.', '%d.%m.%Y.'),'ž', 25, 12, 'Zoran@student.hr'),
(NULL, 'Ana', 'Slaje',	'56447883213', STR_TO_DATE('01.12.2003.', '%d.%m.%Y.'),'ž', 5, 20, 'Ana@student.hr'),
(NULL, 'Lucija', 'Maksin', '90988557462', STR_TO_DATE('31.07.2003.', '%d.%m.%Y.'),'ž', 29, 14, 'Lucija@student.hr'),
(NULL, 'Milomirka', 'Rupnik', '44249045060', STR_TO_DATE('25.06.2001.', '%d.%m.%Y.'),'ž', 14, 30, 'Milomirka@student.hr'),
(NULL, 'Ivan', 'Paligorić', '03444862707', STR_TO_DATE('27.06.2003.', '%d.%m.%Y.'),'m', 14, 30, 'Ivan2@student.hr'),
(NULL, 'Aramis', 'Baltorić', '08037045080', STR_TO_DATE('11.02.2003.', '%d.%m.%Y.'),'m', 14, 29, 'Aramis@student.hr'),
(NULL, 'Federica', 'Granjaš', '42477679484', STR_TO_DATE('27.03.1999.', '%d.%m.%Y.'),'ž', 6, 28, 'Federica@student.hr'),
(NULL, 'Goran', 'Šenica', '58103424308', STR_TO_DATE('01.01.1995.', '%d.%m.%Y.'),'m', 6, 27, 'Goran@student.hr'),
(NULL, 'Bruno', 'Črnja', '14705163711', STR_TO_DATE('22.05.2003.', '%d.%m.%Y.'),'m', 2, 2, 'Bruno@student.hr'),
(NULL, 'Enesa', 'Gazetić', '76640979495', STR_TO_DATE('15.07.2003.', '%d.%m.%Y.'),'ž', 3, 3, 'Enesa@student.hr'),
(NULL, 'Ecija', 'Konjačić', '41891893041', STR_TO_DATE('20.08.2003.', '%d.%m.%Y.'),'ž', 27, 4, 'Ecija@student.hr'),
(NULL, 'Matejka', 'Dornjak', '47227071181', STR_TO_DATE('15.03.2003.', '%d.%m.%Y.'),'ž', 23, 6, 'Matejka@student.hr'),
(NULL, 'Ivan', 'Moler', '57867309045', STR_TO_DATE('27.06.2003.', '%d.%m.%Y.'),'m', 19, 8, 'Ivan2@student.hr'),
(NULL, 'Kojo', 'Lehpamer', '24602123495', STR_TO_DATE('21.02.2004.', '%d.%m.%Y.'),'m', 19, 8, 'Kojo@student.hr'),
(NULL, 'William', 'Petrašević', '68348318639', STR_TO_DATE('20.03.1998.', '%d.%m.%Y.'),'m', 16, 15, 'William@student.hr'),
(NULL, 'Iso', 'Gradinjan', '34962190804', STR_TO_DATE('01.03.1999.', '%d.%m.%Y.'),'m', 12, 16, 'Iso@student.hr'),
(NULL, 'Dženi', 'Čorvila', '98366138428', STR_TO_DATE('16.06.2003.', '%d.%m.%Y.'),'ž', 12, 17, 'Dženi@student.hr'),
(NULL, 'Mikaela', 'Vernić', '16452337546', STR_TO_DATE('05.07.2003.', '%d.%m.%Y.'),'ž', 5, 19, 'Mikaela@student.hr'),
(NULL, 'Antonio', 'Petković', '67834823699', STR_TO_DATE('20.09.2003.', '%d.%m.%Y.'),'m', 1, 1, 'Antonio@student.hr'),
(NULL, 'Isabella', 'Mošnjan', '34962102637', STR_TO_DATE('17.01.2004.', '%d.%m.%Y.'),'ž', 5, 1, 'Isabella@student.hr'),
(NULL, 'Ana', 'Čorluka', '98291103458', STR_TO_DATE('02.07.2002.', '%d.%m.%Y.'),'ž', 7, 17, 'Ana@student.hr'),
(NULL, 'Milana', 'Brajković', '01538468476', STR_TO_DATE('23.09.2003.', '%d.%m.%Y.'),'ž', 6, 19, 'Milana@student.hr');

INSERT INTO voditelj VALUES 
(NULL, 'Ivan', 'Babić', '45385016375', 1, 'Ivan@voditelj.hr'),
(NULL, 'Dora', 'Horvat', '77915781552', 2, 'Dora@voditelj.hr'),
(NULL, 'Zlatko', 'Boras', '65453221654', 5, 'Zlatko@voditelj.hr'),
(NULL, 'Kristijan', 'Kuhar', '87996754372', 8, 'Kristijan@voditelj.hr'),
(NULL, 'Gabrijel', 'Zobin', '87764932812', 7, 'Gabrijel@voditelj.hr'),
(NULL, 'Oliver', 'Tadić', '99467555821', 6, 'Oliver@voditelj.hr'),
(NULL, 'Darko', 'Papić', '86958847361', 7, 'Darko@voditelj.hr'),
(NULL, 'Petar', 'Šipić', '86775647382', 9, 'Petar@voditelj.hr'),
(NULL, 'Maja', 'Vorin', '96559674621', 11, 'Maja@voditelj.hr'),
(NULL, 'Alan', 'Asić', '44563728192', 13, 'Alan@voditelj.hr'),
(NULL, 'Luka', 'Lukin', '08675849301', 14, 'Luka@voditelj.hr'),
(NULL, 'Ana', 'Popović', '86759468921', 12, 'Ana@voditelj.hr'),
(NULL, 'Marina', 'Makić', '98564657843', 15, 'Marina@voditelj.hr'),
(NULL, 'Rene', 'Barić', '96785948372', 4, 'Rene@voditelj.hr'),
(NULL, 'Andrea', 'Seni', '30483950394', 10, 'Andrea@voditelj.hr'),
(NULL, 'Emil', 'Mihaljević', '24058464418', 16, 'Emil@voditelj.hr'),
(NULL, 'Spomenka', 'Kolar', '32492209097', 17, 'Spomenka@voditelj.hr'),
(NULL, 'Kristian', 'Pavlović', '39192699022', 18, 'Kristian@voditelj.hr'),
(NULL, 'Ljerka', 'Babić', '46649363072', 19, 'Ljerka@voditelj.hr'),
(NULL, 'Sonja', 'Popović', '37323540253', 20, 'Sonja@voditelj.hr'),
(NULL, 'Jozo', 'Klobučar', '51416713198', 21, 'Jozo@voditelj.hr'),
(NULL, 'Andrea', 'Popović', '56136927210', 22, 'Andrea@voditelj.hr'),
(NULL, 'Marko', 'Kovač', '97263487467', 23, 'Marko@voditelj.hr'),
(NULL, 'Anđelka', 'Vidaković', '27526016014', 24, 'Anđelka@voditelj.hr'),
(NULL, 'Dušanka', 'Jurišić', '93644406937', 25, 'Dušanka@voditelj.hr'),
(NULL, 'Prvan', 'Lovrić', '24965724361', 26, 'Prvan@voditelj.hr'),
(NULL, 'Petra', 'Grubišić', '58578431652', 27, 'Petra@voditelj.hr'),
(NULL, 'Tereza', 'Milić', '49583103687', 28, 'Tereza@voditelj.hr'),
(NULL, 'Miroslava', 'Živković', '69400922008', 29, 'Miroslava@voditelj.hr'),
(NULL, 'Jan', 'Pranjić', '13817370526', 30, 'Jan@voditelj.hr'),
(NULL, 'Pejo', 'Matijević', '72718659989', 26, 'Pejo@voditelj.hr'),
(NULL, 'Zvonimira', 'Šarić', '69815253055', 25, 'Zvonimira@voditelj.hr'),
(NULL, 'Damjan', 'Šimunović', '64498184250', 14, 'Damjan@voditelj.hr'),
(NULL, 'Stjepan', 'Blažević', '19087543398', 30, 'Stjepan@voditelj.hr'),
(NULL, 'Patrik', 'Pavić', '84750091252', 26, 'Patrik@voditelj.hr'),
(NULL, 'Ema', 'Anić', '15012228538', 14, 'Ema@voditelj.hr'),
(NULL, 'Nevenka', 'Jovanović', '28228907041', 15, 'Nevenka@voditelj.hr'),
(NULL, 'Tomislav', 'Jelić', '83173910083', 3, 'Tomislav@voditelj.hr'),
(NULL, 'Nedjeljko', 'Janković', '88382001689', 30, 'Nedjeljko@voditelj.hr'),
(NULL, 'Borislav', 'Jurić', '42770771434', 21, 'Borislav@voditelj.hr');

INSERT INTO termin_ispita VALUES 
(NULL, 'ljetni rok', STR_TO_DATE('31.05.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('01.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('02.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('03.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('06.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('07.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('08.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('09.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('10.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('13.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('14.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('15.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('23.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('24.06.2022.', '%d.%m.%Y.')),
(NULL, 'ljetni rok', STR_TO_DATE('27.06.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('17.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('18.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('19.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('22.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('23.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('24.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('25.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('26.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('29.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('30.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('31.08.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('01.09.2022.', '%d.%m.%Y.')),
(NULL, 'jesenji rok', STR_TO_DATE('02.09.2022.', '%d.%m.%Y.'));

INSERT INTO vrijeme VALUES
(NULL,	70,	'14:00:00'),
(NULL,	80,	'09:00:00'),
(NULL,	90,	'09:00:00'),
(NULL,	90, '14:00:00'),
(NULL,	100, '09:00:00'),
(NULL,	100, '14:00:00'),
(NULL,	105, '09:00:00'),
(NULL,	120, '09:00:00'),
(NULL,	135, '14:00:00'),
(NULL,	150, '09:00:00'),
(NULL,	150, '14:00:00'),
(NULL,	160, '09:00:00'),
(NULL,	180, '09:00:00');

INSERT INTO matura VALUES
(NULL, 1, 13, 5, 1, 'test'),
(NULL, 1, 13, 5, 2, 'esej'),
(NULL, 1, 14, 12, 1, 'esej'),
(NULL, 1, 14, 12, 2, 'test'),
(NULL, 2, 3, 13, 1, 'test'),
(NULL, 2, 3, 13, 2,	'test'),
(NULL, 2, 18, 13, 1, 'test'),
(NULL, 2, 18, 13, 2, 'test'),
(NULL, 3, 5, 13, 1, 'test'),
(NULL, 3, 5, 10, 2, 'test'),
(NULL, 3, 21, 13, 1, 'test'),
(NULL, 3, 21, 10, 2, 'test'),
(NULL, 4, 22, 11, 1, 'test'),
(NULL, 4, 22, 6, 2,	'test'),
(NULL, 5, 4, 10, 1,	'test'),
(NULL, 5, 4, 8, 2, 'test'),
(NULL, 6, 5, 11, 1,	'test'),
(NULL, 6, 5, 6, 2, 'test'),
(NULL, 7, 1, 5, 1, 'test'),
(NULL, 7, 6, 13, 1,	'esej'),
(NULL, 7, 6, 13, 2,	'esej'),
(NULL, 7, 1, 5, 2, 'test'),
(NULL, 8, 1, 4,	3, 'test'),
(NULL, 9, 2, 9,	1, 'test'),
(NULL, 9, 2, 6,	2, 'test'),
(NULL, 10, 5, 10, 3, 'test'),
(NULL, 11, 4, 11, 3, 'test'),
(NULL, 12, 23, 11, 3, 'test'),
(NULL, 13, 23, 13, 3, 'test'),
(NULL, 14, 6, 4, 3,	'test'),
(NULL, 15, 27, 4, 3, 'test'),
(NULL, 16, 18, 5, 3, 'test'),
(NULL, 17, 26, 13, 3, 'test'),
(NULL, 18, 26, 9, 3, 'test'),
(NULL, 19, 19, 11, 3, 'test'),
(NULL, 20, 7, 3, 3,	'test'),
(NULL, 21, 28, 9, 3, 'test'),
(NULL, 22, 28, 3, 3, 'test'),
(NULL, 23, 20, 4, 3, 'test'),
(NULL, 24, 4, 1, 3,	'test');

INSERT INTO ocjenjivac VALUES
(NULL, 'Ivana',	'Novak', '64358318963',	1, 'Ivana@ocjenjivac.hr'),
(NULL, 'Ranko',	'Sokić', '23176897432',	2, 'Ranko@ocjenjivac.hr'),
(NULL, 'Daniel', 'Ridič', '45364572845', 9, 'Daniel@ocjenjivac.hr'),
(NULL, 'Alen', 'Perin', '54534678767', 15, 'Alen@ocjenjivac.hr'),
(NULL, 'Marjan', 'Robik', '88943526453', 14, 'Marjan@ocjenjivac.hr'),
(NULL, 'Marko', 'Sjedić', '00854768594', 12, 'Marko@ocjenjivac.hr'),
(NULL, 'Ivan', 'Ladič', '47586767432', 6, 'Ivan@ocjenjivac.hr'),
(NULL, 'Rajan',	'Korin', '09897098643', 5, 'Rajan@ocjenjivac.hr'),
(NULL, 'Filip',	'Abel', '76564837213', 7, 'Filip@ocjenjivac.hr'),
(NULL, 'Mato',  'Satić', '87675856435', 3, 'Mato@ocjenjivac.hr'),
(NULL, 'Marina', 'Seda', '76322345361', 4, 'Marina@ocjenjivac.hr'),
(NULL, 'Klaudija', 'Burek', '16453789210', 8, 'Klaudija@ocjenjivac.hr'),
(NULL, 'Klara', 'Nukič', '65746583922', 5, 'Klara@ocjenjivac.hr'),
(NULL, 'Marija', 'Bibin', '75867564352', 13, 'Marija@ocjenjivac.hr'),
(NULL, 'Jasna', 'Resto', '09076853741', 10, 'Jasna@ocjenjivac.hr'),
(NULL, 'Doris', 'Katić', '12207840856', 16, 'Doris@ocjenjivac.hr'),
(NULL, 'Bratislav', 'Jakšić', '02062894265', 17, 'Bratislav@ocjenjivac.hr'),
(NULL, 'Bogoljub', 'Kolar',	'53674478572', 18, 'Bogoljub@ocjenjivac.hr'),
(NULL, 'Živko', 'Topić', '14721088809', 19, 'Živko@ocjenjivac.hr'),
(NULL, 'Dinko', 'Pranjić', '94951701977', 20, 'Dinko@ocjenjivac.hr'),
(NULL, 'Svjetlana', 'Radić','74848045754', 21, 'Svjetlana@ocjenjivac.hr'),
(NULL, 'Katarina', 'Katić',	'55738476236', 22, 'Katarina@ocjenjivac.hr'),
(NULL, 'Miodrag', 'Kos', '63042045615', 23, 'Miodrag@ocjenjivac.hr'),
(NULL, 'Strahimir', 'Šimunović', '10706611759', 24, 'Strahimir@ocjenjivac.hr'),
(NULL, 'Veselko', 'Dujmović', '75258757626', 25, 'Veselko@ocjenjivac.hr'),
(NULL, 'Valentina', 'Jozić', '71735735559', 26, 'Valentina@ocjenjivac.hr'),
(NULL, 'Nikolina', 'Božić',	'13229845369', 27, 'Nikolina@ocjenjivac.hr'),
(NULL, 'Joško', 'Kos', '61991347220', 28, 'Joško@ocjenjivac.hr'),
(NULL, 'Mila', 'Jelić', '40719662648', 29, 'Mila@ocjenjivac.hr'),
(NULL, 'Tina', 'Lukić',	'10495315231', 30, 'Tina@ocjenjivac.hr');

INSERT INTO ocjena_na_maturi VALUES
(NULL, NULL, 35.00, 1, 8, 1, 'Ocjenjeno je'),
(NULL, NULL, NULL, 7, 5, 2, NULL),
(NULL, NULL, 47.12, 12, 27, 2, 'Ocjenjeno je'),
(NULL, NULL, 39.00, 23, 2, 2, 'Ocjenjeno je'),
(NULL, NULL, 78.98, 23, 14, 24, 'Ocjenjeno je'),
(NULL, NULL, 44.65, 23, 17, 24, 'Ocjenjeno je'),
(NULL, NULL, 65.20, 15, 1, 1, 'Ocjenjeno je'),
(NULL, NULL, 55.99, 9, 30, 8, 'Ocjenjeno je'),
(NULL, NULL, 95.84, 8, 29, 27, 'Ocjenjeno je'),
(NULL, NULL, 39.66, 1, 4, 1, 'Ocjenjeno je'),
(NULL, NULL, 87.66, 7, 12, 2, 'Ocjenjeno je'),
(NULL, NULL, 54.78, 9, 4, 8, 'Ocjenjeno je'),
(NULL, NULL, NULL, 14, 2, 15, NULL),
(NULL, NULL, 67.88, 1, 25, 1, 'Ocjenjeno je'),
(NULL, NULL, 25.25, 25, 30, 24, 'Ocjenjeno je'),
(NULL, NULL, 78.00, 27, 24, 24, 'Ocjenjeno je'),
(NULL, NULL, 25.34, 9, 15, 12, 'Ocjenjeno je'),
(NULL, NULL, 97.00, 20, 1, 21, 'Ocjenjeno je'),
(NULL, NULL, 65.35, 22, 15, 21, 'Ocjenjeno je'),
(NULL, NULL, 29.00, 18, 2,18, 'Ocjenjeno je'),
(NULL, NULL, 46.00, 4, 18, 17, 'Ocjenjeno je'),
(NULL, NULL, NULL, 6, 2, 17, NULL),
(NULL, NULL, 46.50, 5, 18, 28, 'Ocjenjeno je'),
(NULL, NULL, 67.98, 6, 11, 17, 'Ocjenjeno je'),
(NULL, NULL, 33.00, 7, 2, 2, 'Ocjenjeno je'),
(NULL, NULL, 85.75, 8, 22, 27, 'Ocjenjeno je'),
(NULL, NULL, 36.00, 9, 24, 12, 'Ocjenjeno je'),
(NULL, NULL, 58.69, 19, 22, 10, 'Ocjenjeno je'),
(NULL, NULL, NULL, 30, 7, 29, NULL),
(NULL, NULL, 79.00, 7, 4, 2, 'Ocjenjeno je'),
(NULL, NULL, 89.00, 24, 28, 25, 'Ocjenjeno je'),
(NULL, NULL, 22.95, 30, 3, 29, 'Ocjenjeno je'),
(NULL, NULL, 16.00, 12, 23, 2, 'Ocjenjeno je'),
(NULL, NULL, NULL, 13, 15, 3, NULL);

INSERT INTO prigovor VALUES
(NULL, 'Pogrešna ocjena', 'Uz broj bodova koji imam treba biti druga ocjena, došlo je do greške', 3),
(NULL, 'Priznavanje zadatka ', 'Je li mi je priznat 5. zadatak? ', 15),
(NULL, 'Pogreška', 'Možete li mi reći gdje sam sve napravio pogrešku?', 23),
(NULL, 'Oduzimanje bodova', 'Da li ste mi oduzeli bodove jer je esej predugačak ili?', 7),
(NULL, 'Dvosmislen zadatak' , 'Zadatak 15  sam shvatio na pogrešan način, da li postoji mogućnost da ipak dobijem bodove?', 18),
(NULL, 'Ispravak pogreške', 'Nisam vidjela da je kod ispravka potreban i potpis, može li mi ipak priznati zadatak?', 13),
(NULL, 'Pogreške', 'Želim znati gdje su mi bile pogreške, kako to da napravim?', 19),
(NULL, 'Obrazloženje', 'Možete li obrazložiti ocjenu, smatram da je bolje urađeno.', 9),
(NULL, 'Pregled testa', 'Kome se obratiti kako bih mogla vidjeti svoje greške?', 1),
(NULL, 'Upit', 'Postoji li mogućnost da je još neki odgovor točan a nije naveden u testu?', 22),
(NULL, 'Procent', 'Koji procent je za koju ocjenu? Ne mogu pronaći na sajtu.', 12),
(NULL, 'Priznavanje zadatka', 'Mogu li dobiti pojašnjenje zašto nemam makimum u 28. zadatku iako je točan?', 11),
(NULL, 'Ocjenjivač', 'Tko je ocjenio moju maturu, mislim da su napravili neku pogrešku.', 20),
(NULL, 'Varanje', 'Radi varanja su me izbacili sa ispita, postoji li nekakva zabrana za pisanje na idućem roku?', 9),
(NULL, 'Pisanje odgovora', 'Postoji li mogućnost da mi se prihvate odgovori pisani olovkom?', 6);

INSERT INTO edukacija_termin VALUES
(NULL, ('2022-02-09.' '09:00:00'), 1),
(NULL, ('2022-02-12.' '09:00:00'), 2),
(NULL, ('2022-02.05.' '09:00:00'), 3),
(NULL, ('2022-02.11.' '09:00:00'), 4),
(NULL, ('2022-02.13.' '09:00:00'), 5),
(NULL, ('2022-02.02.' '09:00:00.'), 6),
(NULL, ('2022-02.11.' '12:00:00'), 7),
(NULL, ('2022-02.05.' '12:00:00'), 8),
(NULL, ('2022-02-07.' '09:00:00'), 9),
(NULL, ('2022-02-15.' '09:00:00'), 10),
(NULL, ('2022-02-03.' '09:00:00'), 11),
(NULL, ('2022-01-29.' '09:00:00'), 12),
(NULL, ('2022-01-27.' '09:00:00'), 13),
(NULL, ('2022-02-17.' '09:00:00'), 14),
(NULL, ('2022-02-10.' '09:00:00'), 15),
(NULL, ('2022-01-27.' '12:00:00'), 16),
(NULL, ('2022-01-29.' '12:00:00'), 17),
(NULL, ('2022-02-12.' '12:00:00'), 18),
(NULL, ('2022-02-13.' '12:00:00'), 19),
(NULL, ('2022-02-06.' '09:00:00'), 20),
(NULL, ('2022-02-09.' '12:00:00'), 21),
(NULL, ('2022-02-12.' '15:00:00'), 22),
(NULL, ('2022-02-09.' '15:00:00'), 23),
(NULL, ('2022-02-13.' '15:00:00'), 24);

INSERT INTO edukacija VALUES 
(NULL, 1, 1),
(NULL, 2, 2),
(NULL, 3, 3),
(NULL, 4, 4),
(NULL, 5, 5),
(NULL, 6, 6),
(NULL, 7, 7),
(NULL, 8, 8),
(NULL, 9, 9),
(NULL, 10, 10),
(NULL, 11, 11),
(NULL, 12, 12),
(NULL, 13, 13),
(NULL, 14, 14),
(NULL, 15, 15),
(NULL, 16, 16),
(NULL, 17, 17),
(NULL, 18, 18),
(NULL, 19, 19),
(NULL, 20, 20),
(NULL, 21, 21),
(NULL, 22, 22),
(NULL, 23, 23),
(NULL, 24, 24),
(NULL, 25, 1),
(NULL, 26, 2),
(NULL, 27, 3),
(NULL, 28, 4),
(NULL, 29, 5),
(NULL, 30, 6);

DROP PROCEDURE IF EXISTS postoji_li_oib;
-- Provjerava postoji li osoba s odredenim oib-om
DELIMITER //
CREATE PROCEDURE postoji_li_oib (IN p_oib CHAR(11), OUT rez INTEGER)
BEGIN
 DECLARE temp CHAR(11);
 DECLARE brojac INTEGER DEFAULT 0;
 DECLARE temp_rez INTEGER DEFAULT 0;
 
 DECLARE cur CURSOR FOR
	SELECT oib FROM ucenik;
 DECLARE cur2 CURSOR FOR
	SELECT oib FROM voditelj;
  DECLARE cur3 CURSOR FOR
	SELECT oib FROM ocjenjivac;
 DECLARE EXIT HANDLER
		FOR NOT FOUND SET temp_rez = 0;
 OPEN cur;
 OPEN cur2;
 OPEN cur3;
  petlja: LOOP
    FETCH cur INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
     FETCH cur2 INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
    FETCH cur3 INTO temp;
     IF temp = p_oib THEN 
		SET rez = 1;
	 END IF;
 END LOOP petlja;
 
 CLOSE cur;
 CLOSE cur2;
 CLOSE cur3;
END //
DELIMITER ;
CALL postoji_li_oib ('10495315231',@rez);
SELECT @rez FROM DUAL;
DROP PROCEDURE postoji_li_oib;

-- Ako su svi pristupnici rođeni 2003. godine u izlaznu varijablu spremiti vrijednost 'DA' u suprotnom će spremiti vijrednost 'NE'
DELIMITER //
CREATE PROCEDURE rodjenje(OUT rezultat VARCHAR(2))
BEGIN
 DECLARE a INTEGER;
 DECLARE b INTEGER;
 SELECT COUNT(*) INTO a FROM ucenik WHERE datum_rodjenja >= (STR_TO_DATE('01.01.2003.', '%d.%m.%Y.'));
 SELECT COUNT(*) INTO b FROM ucenik;
 IF a = b THEN 
	SET rezultat = "DA";
 ELSE 
	SET rezultat = "NE";
 END IF;
END //
DELIMITER ;
CALL rodjenje(@rezultat);
SELECT @rezultat FROM DUAL;

-- Prikaz svih predmeta koji pripadaju jednoj od dvije skupine (izborni/obavezni)
DELIMITER //
CREATE PROCEDURE obavezi_izborni_predmeti(IN izbor VARCHAR(20), OUT predmeti VARCHAR(4000))
BEGIN
 DECLARE predm VARCHAR(100) DEFAULT "";
 DECLARE cur CURSOR FOR
  SELECT naziv FROM predmet WHERE obavezan_izborni = izbor;
 DECLARE EXIT HANDLER
  FOR NOT FOUND SET predmeti = CONCAT("Predmeti",": ",predmeti);
 SET predmeti = "";
 OPEN cur;
  petlja: LOOP
	FETCH cur INTO predm;
	SET predmeti = CONCAT(predm,", ",predmeti);
  END LOOP petlja;
 CLOSE cur;
END //
DELIMITER ;
CALL obavezi_izborni_predmeti('obavezan', @predmeti);
SELECT @predmeti;

-- Spremiti broj ucenika koji imaju isto ime kao ocjenjivač a ime je definirano parametrom p_ime, ako nema takvih učenika u varijablu se sprema vrijednost -1
DELIMITER //
CREATE PROCEDURE ime(IN p_ime VARCHAR(20), OUT rez INTEGER)
BEGIN
 DECLARE a INTEGER DEFAULT 0;
 SELECT COUNT(*) INTO a FROM ucenik WHERE ime = p_ime AND ime IN (SELECT ime FROM ocjenjivac);
 IF a>0 THEN 
	SET rez=a;
 ELSE 
	SET rez=-1;
 END IF;
END //
DELIMITER ;
CALL ime('Hana',@rez);
SELECT @rez FROM DUAL;
CALL ime('Ivan',@rez1);
SELECT @rez1 FROM DUAL;

-- Provjera da li svi učenici imaju OIB duljine 11, pri tome u izlaznu varijablu sprema odgovor na isto pitanje
DELIMITER //
CREATE PROCEDURE provjera_oib (OUT rez VARCHAR(100))
BEGIN
 DECLARE brojac INTEGER;
 DECLARE br INTEGER;
 SELECT COUNT(*) INTO brojac FROM ucenik WHERE LENGTH(oib) = 11;
 SELECT COUNT(*) INTO br FROM ucenik;
 IF brojac = br THEN 
	SET rez = "Svi OIB-i su duljine 11";
 ELSE 
	SET rez = "Nisu svi OIB-i duljine 11";
 END IF;
END //
DELIMITER ;
CALL provjera_oib(@rezu);
SELECT @rezu FROM DUAL;

--  Povećaj vrijeme trajanja ispita za zadani broj minuta
DELIMITER //
CREATE PROCEDURE povecaj(IN minuti INTEGER)
BEGIN
 UPDATE vrijeme SET duljina_trajanja = duljina_trajanja + minuti;
END //
DELIMITER ;
SELECT * FROM vrijeme;
CALL povecaj(15);
SELECT * FROM vrijeme;

-- Pomoću procedure prikazati koliko je matura ocjenjeno s ocjenom 1 a koliko s ocjenom 5
DELIMITER //
CREATE PROCEDURE broj_najmanjih_najvecih(OUT min_broj INTEGER, OUT max_broj INTEGER)
BEGIN
 SELECT COUNT(id) INTO min_broj FROM ocjena_na_maturi WHERE ocjena = 1;
 SELECT COUNT(id) INTO max_broj FROM ocjena_na_maturi WHERE ocjena = 5;
END //
DELIMITER ;
CALL broj_najmanjih_najvecih(@min_broj, @max_broj);
SELECT @min_broj, @max_broj FROM DUAL;

-- Prikazati datum rođenja najstarijeg/-e učenika/-ce i najmlađeg/-e učenika/-ce
DELIMITER //
CREATE PROCEDURE dohvati_najmladjeg_najstarijeg(OUT min_rodjenje DATE, OUT max_rodjenje DATE)
BEGIN
 DECLARE cur CURSOR FOR
 SELECT MIN(datum_rodjenja), MAX(datum_rodjenja) FROM ucenik;
 OPEN cur;
 FETCH cur INTO min_rodjenje, max_rodjenje;
 CLOSE cur;
END //
DELIMITER ;
CALL dohvati_najmladjeg_najstarijeg(@min_rodjenje, @max_rodjenje);
SELECT @min_rodjenje, @max_rodjenje FROM DUAL;

-- Odredi koliko voditelja dolazi iz gradova čiji je poštanski broj veći od zadanog
DELIMITER //
CREATE PROCEDURE broj_dolazecih(IN p_broj INTEGER,
OUT brojac INTEGER)
BEGIN
 SELECT COUNT(voditelj.id) INTO brojac FROM voditelj 
	INNER JOIN grad ON voditelj.id_grad=grad.id 
    WHERE grad.postanski_broj > p_broj;
END //
DELIMITER ;
CALL broj_dolazecih(35000, @dolazeci);
SELECT @dolazeci FROM DUAL;

-- Prikazati broj dana koji preostaje do nekog ispita koji pripada kategoriji 'test' i naziv mu je određen ulaznim parametrom 
DELIMITER //
CREATE PROCEDURE dani(IN pred VARCHAR(20), OUT broj_dana INTEGER)
BEGIN
 DECLARE datum DATE;
 SELECT DISTINCT(t.datum_ispita) INTO datum FROM termin_ispita AS t 
	INNER JOIN matura ON matura.id_termin_ispita = t.id 
	INNER JOIN predmet ON predmet.id = matura.id_predmet
    WHERE predmet.naziv = pred AND opis = 'test';
 SET broj_dana = DATEDIFF(datum, DATE(NOW())); 
END //
DELIMITER ;
CALL dani('Biologija', @bb);
SELECT @bb FROM DUAL;

-- Izračun prosječne ocjene učenika is pojedinog grada
DELIMITER //
CREATE PROCEDURE prosjecna_ocjena_grad(IN p_id_grad INTEGER, OUT rez INTEGER)
BEGIN
 DECLARE brojac INTEGER DEFAULT 0;
 DECLARE suma INTEGER DEFAULT 0;
 DECLARE temp INTEGER;
 DECLARE cur CURSOR FOR
  SELECT ocjena_na_maturi.ocjena FROM ocjena_na_maturi 
	INNER JOIN ucenik ON ucenik.id = ocjena_na_maturi.id_ucenik 
    INNER JOIN grad ON grad.id = ucenik.id_grad 
    WHERE grad.id = p_id_grad;
 DECLARE EXIT HANDLER
    FOR NOT FOUND SET rez = suma/brojac;
 OPEN cur;
 petlja: LOOP
    FETCH cur INTO temp;
    SET suma = suma + temp;
    SET brojac = brojac + 1;
 END LOOP petlja;
 CLOSE CUR;
END //
DELIMITER ;
CALL prosjecna_ocjena_grad(5, @rez);
SELECT @rez FROM DUAL;

-- Prikaz koliko školi ima u gradu koji je zadan parametrom p_grad i koliko ima mogućih mjesta za pisanje u tom gradu
DELIMITER //
CREATE PROCEDURE broj_skola_mjesta(IN p_grad VARCHAR(20), OUT broj_s INTEGER, OUT broj_m INTEGER)
BEGIN
 SELECT COUNT(skola.id), SUM(broj_mjesta) INTO broj_s, broj_m FROM skola 
	INNER JOIN grad ON grad.id = skola.id_grad 
    WHERE p_grad= grad.naziv 
    GROUP BY grad.id;
 END //
DELIMITER ;
CALL broj_skola_mjesta('Pula', @skole, @mjesta);
SELECT @skole, @mjesta FROM DUAL;

-- Za ulaznu varijablu određuje da li je ispit prošao ili nije ali samo ako je u pitanju jedan od izbornih predmeta
DELIMITER //
CREATE PROCEDURE proslo(IN pred VARCHAR(20), OUT gotovo VARCHAR(25))
BEGIN
 DECLARE datum DATE;
 SELECT t.datum_ispita INTO datum FROM termin_ispita AS t 
	INNER JOIN matura ON matura.id_termin_ispita = t.id 
	INNER JOIN predmet ON predmet.id = matura.id_predmet 
    WHERE predmet.naziv = pred AND matura.id_razina = 3;
  IF datum < DATE(NOW()) THEN 
	SET gotovo = 'Ispit je prošao'; 
  ELSE 
	SET gotovo = 'Ispit još nije prošao';
  END IF;
END //
DELIMITER ;
CALL proslo('Geografija', @gotovo);
SELECT @gotovo FROM DUAL;

-- Izračun broja učenika s određenom ocjenom iz određenog grada
DELIMITER //
CREATE PROCEDURE broj_ucenika_ocjena_grad(IN p_ocjena INTEGER, IN p_id_grad INTEGER, OUT rez INTEGER)
BEGIN
 DECLARE brojac INTEGER DEFAULT 0;
 DECLARE temp INTEGER;
 DECLARE cur CURSOR FOR
	SELECT ocjena_na_maturi.ocjena FROM ocjena_na_maturi INNER JOIN ucenik ON ucenik.id = ocjena_na_maturi.id_ucenik INNER JOIN grad ON grad.id = ucenik.id_grad WHERE grad.id = p_id_grad AND ocjena = p_ocjena;
 DECLARE EXIT HANDLER
    FOR NOT FOUND SET rez = brojac;
 OPEN cur;
 petlja: LOOP
    FETCH cur INTO temp;
    SET brojac = brojac + 1;
 END LOOP petlja;
 CLOSE cur;
END //
DELIMITER ;
CALL broj_ucenika_ocjena_grad(1, 1, @rez);
SELECT @rez FROM DUAL;

-- Prosjecan broj bodova svih ucenika na maturi
DELIMITER //
CREATE PROCEDURE avg_broj_bodova_na_maturi (OUT rez DECIMAL(10, 2))
BEGIN
	DECLARE temp DECIMAL(5,2);
    DECLARE brojac INTEGER DEFAULT 0;
     DECLARE suma FLOAT DEFAULT 0;
    DECLARE cur CURSOR FOR	
		SELECT broj_bodova FROM ocjena_na_maturi WHERE broj_bodova IS NOT NULL;
	DECLARE EXIT HANDLER
		FOR NOT FOUND SET rez = suma/brojac;
	OPEN cur;
	petlja: LOOP
		FETCH cur INTO temp;
        SET suma = suma + temp;
		SET brojac = brojac + 1;
    END LOOP petlja;
    CLOSE cur;
END //
DELIMITER ;
CALL avg_broj_bodova_na_maturi(@rez);
SELECT @rez FROM DUAL;

-- Prosjek odredenog ucenika na maturi
DELIMITER //
CREATE PROCEDURE prosjek_ucenika_na_maturi (IN p_id_ucenik INTEGER ,OUT rez DECIMAL (10, 1))
BEGIN
	DECLARE temp INTEGER;
    DECLARE brojac INTEGER DEFAULT 0;
	DECLARE suma INTEGER DEFAULT 0;
    DECLARE cur CURSOR FOR	
		SELECT ocjena FROM ocjena_na_maturi WHERE id_ucenik = p_id_ucenik AND ocjena IS NOT NULL;
	DECLARE EXIT HANDLER
		FOR NOT FOUND SET rez = suma/brojac;
	OPEN cur;
	petlja: LOOP
		FETCH cur INTO temp;
        SET suma = suma + temp;
		SET brojac = brojac + 1;
    END LOOP petlja;
    CLOSE cur;
END //
DELIMITER ;
CALL prosjek_ucenika_na_maturi(4, @rez);
SELECT @rez FROM DUAL;
SELECT * FROM ocjena_na_maturi, matura WHERE id_matura = matura.id;
-- Prosjecan broj bodova svih ucenika iz odredenog predmeta
DELIMITER //
CREATE PROCEDURE prosjek_bodova_predmeta_na_maturi (IN p_id_predmet VARCHAR(50) ,OUT rez DECIMAL (10, 2))
BEGIN
	DECLARE temp DECIMAL(10,2);
    DECLARE brojac INTEGER DEFAULT 0;
     DECLARE suma FLOAT DEFAULT 0;
    DECLARE cur CURSOR FOR	
		SELECT broj_bodova FROM ocjena_na_maturi, matura, predmet WHERE id_matura = matura.id AND broj_bodova IS NOT NULL AND id_predmet = predmet.id AND predmet.naziv = p_id_predmet;
	DECLARE EXIT HANDLER
		FOR NOT FOUND SET rez = suma/brojac;
	OPEN cur;
	petlja: LOOP
		FETCH cur INTO temp;
        SET suma = suma + temp;
		SET brojac = brojac + 1;
    END LOOP petlja;
    CLOSE cur;
END //
DELIMITER ;
CALL prosjek_bodova_predmeta_na_maturi('Hrvatski', @rez);
SELECT @rez FROM DUAL;

-- Prikaži prosjek ocjena po spolu
DELIMITER //
CREATE PROCEDURE prosjek_ocjena_spol (IN p_spol CHAR(1), OUT rez INTEGER)
BEGIN
	DECLARE temp INTEGER;
    DECLARE brojac INTEGER DEFAULT 0;
	DECLARE suma INTEGER DEFAULT 0;
    DECLARE cur CURSOR FOR	
		SELECT ocjena FROM ocjena_na_maturi, ucenik WHERE id_ucenik = ucenik.id AND ocjena IS NOT NULL AND ucenik.spol = p_spol;
	DECLARE EXIT HANDLER
		FOR NOT FOUND SET rez = suma/brojac;
	OPEN cur;
	petlja: LOOP
		FETCH cur INTO temp;
        SET suma = suma + temp;
		SET brojac = brojac + 1;
    END LOOP petlja;
    CLOSE cur;
END //
DELIMITER ;
CALL prosjek_ocjena_spol('m', @rez);
SELECT @rez FROM DUAL;

-- POGLEDI
-- Prikaži prosjek ocjena na svim predmetima ukupno 
CREATE VIEW prosjecna_ocjena AS 
	SELECT AVG(ocjena), COUNT(ocjena) AS ukupan_broj_ocjena 
		FROM ocjena_na_maturi;
SELECT * FROM prosjecna_ocjena;
        
-- Prikaži sve gradove i broj škola u tim gradovima
CREATE VIEW broj_skola AS
	SELECT g.naziv, COUNT(g.id) AS br_škola 
		FROM skola AS s 
        INNER JOIN grad AS g ON g.id = s.id_grad 
        GROUP BY g.id;
SELECT * FROM broj_skola;

-- Prikaži temu i opis prigovora za predmete koji imaju nekakav prigovor
CREATE VIEW prigovori_za_predmete AS 
	SELECT p.tema_prigovora, p.opis_prigovora, pr.naziv 
		FROM prigovor AS p
		INNER JOIN ocjena_na_maturi AS onm ON onm.id=p.id_ocjena_na_maturi
		INNER JOIN matura AS m ON m.id = onm.id_matura
		INNER JOIN predmet AS pr ON pr.id =m.id_predmet 
        ORDER BY tema_prigovora ASC;
SELECT * FROM prigovori_za_predmete;
		
-- Prikaži sve učenike koje su iznad prosjeka rješili maturu poredani od najveće ocjena prema manjima
CREATE VIEW iznad_prosjeka AS
	SELECT u.ime, u.prezime, onm.ocjena 
		FROM ocjena_na_maturi AS onm
		INNER JOIN ucenik AS u ON u.id =onm.id_ucenik
		WHERE ocjena > (SELECT AVG(ocjena) AS prosjecno FROM ocjena_na_maturi)
        ORDER BY ocjena DESC;
SELECT * FROM iznad_prosjeka;
        
-- Prikaži ocjenjivače koji su išli na neku od edukacija
CREATE VIEW ocjenjivaci AS 
	SELECT ocjenjivac.* 
		FROM ocjenjivac 
		INNER JOIN edukacija ON ocjenjivac.id = edukacija.id_ocjenjivac;
SELECT * FROM ocjenjivaci;

-- Prikaži koliko je ocjena zastupljena u odnosu na broj ocjenjenih matura
CREATE VIEW zastupljenost_ocjene AS 
	SELECT ocjena, COUNT(ocjena)/(SELECT COUNT(id) FROM ocjena_na_maturi WHERE ocjenjeno LIKE 'Ocjenjeno je')*100 AS procent_zastupljenosti 
		FROM ocjena_na_maturi 
        WHERE ocjenjeno LIKE 'Ocjenjeno je' 
        GROUP BY ocjena;
SELECT * FROM zastupljenost_ocjene;

-- UPITI    
-- Pronađi sve osobe koje imaju barem 20 godina i pišu maturu
SELECT * FROM ucenik 
	WHERE datum_rodjenja < DATE(NOW() - INTERVAL 20 YEAR);

-- Prikaži sve učenike koji imaju prigovor te ocjenu koju su dobili na maturi
SELECT u.id, u.ime, u.prezime, onm.ocjena FROM ucenik AS u
	INNER JOIN ocjena_na_maturi AS onm ON onm.id_ucenik = u.id
	WHERE onm.ocjena IN
	(SELECT p.id FROM prigovor AS p);
    
-- Prikaži sve ocjenjivače i broj matura koje su pregledali
SELECT ime, prezime, COUNT(o.id) AS pregleda FROM ocjenjivac AS o
    INNER JOIN ocjena_na_maturi AS ocjena ON o.id = ocjena.id_ocjenjivac
    GROUP BY o.id;  

-- Prikaži iz kojeg grada dolazi najviše voditelja
SELECT g.naziv, COUNT(v.id) AS broj_voditelja FROM voditelj AS v
    INNER JOIN grad AS g ON v.id_grad=g.id
    GROUP BY g.id 
    ORDER BY broj_voditelja DESC LIMIT 1;

-- Prikaži sve učenike koji su 2001 godište sortirano prema prezimenu uzlazno
SELECT ucenik.* FROM ucenik 
	INNER JOIN skola ON ucenik.id_skola = skola.id 
	WHERE YEAR(datum_rodjenja) = '2001'
	ORDER BY prezime ASC;

-- Prikaži sve predmete i datum njihovog pisanja koji se nalazi na 'letnjem roku'
SELECT predmet.naziv, ti.datum_ispita FROM matura 
    INNER JOIN  termin_ispita AS ti ON matura.id_termin_ispita = ti.id
    INNER JOIN predmet ON predmet.id = matura.id_predmet
    WHERE vrsta_roka = 'ljetni rok'
    GROUP BY predmet.id;
    
-- Prikaži sve učenike s njihovom ocjenom na svakom izbornom predmetu koji su pisali
SELECT u.ime, u.prezime, onm.ocjena, p.naziv FROM ocjena_na_maturi AS onm
	INNER JOIN ucenik AS u ON u.id = onm.id_ucenik
	INNER JOIN matura AS m ON m.id = onm.id_matura
	INNER JOIN predmet AS p ON p.id = m.id_predmet
	WHERE m.id_razina = 3
	ORDER BY prezime DESC;

-- Prikaži sve škole koje imaju više od 200 mjesta za pisanje mature
SELECT skola.naziv, grad.naziv AS grad, skola.broj_mjesta FROM skola, grad
	WHERE broj_mjesta >= 200 AND grad.id = skola.id_grad;

-- Prikaži sve učenike koji su odlično rješili neki ispit te iz kog predemeta je ta ocjena
SELECT u.ime,u.prezime, onm.ocjena, p.naziv FROM ocjena_na_maturi AS onm
	INNER JOIN ucenik AS u ON u.id = onm.id_ucenik
	INNER JOIN matura AS m ON m.id = onm.id_matura
	INNER JOIN predmet AS p ON p.id = m.id_predmet
	WHERE onm.ocjena = 5
	ORDER BY prezime ASC;
    
-- Prikaži sve termine edukacije, predmete te koji ocjenjivači su im prisustvovali
SELECT et.termin_edukacije, p.naziv, CONCAT(o.ime," ",o.prezime) AS ime_i_prezime FROM edukacija AS e
    INNER JOIN edukacija_termin AS et ON et.id = e.id_edukacija_termin
    INNER JOIN predmet AS p ON p.id = et.id_predmet
    INNER JOIN ocjenjivac AS o ON o.id=e.id_ocjenjivac
    GROUP BY et.id;

 -- Prikaži sve predmete gdje piše duljina trajanja ispišite datum, opis i vrstu roka ispita
SELECT p.naziv, v.duljina_trajanja, ti.datum_ispita, m.opis, vrsta_roka FROM matura AS m
	INNER JOIN termin_ispita AS ti ON ti.id = m.id_termin_ispita
	INNER JOIN vrijeme AS v ON v.id = m.id_vrijeme
	INNER JOIN predmet AS p ON p.id = m.id_predmet
	GROUP BY p.id;
        
 -- Prikaži sve učenike i mjesto gdje pisu maturu
 SELECT CONCAT(u.ime," ",u.prezime) AS ime_i_prezime, skola.naziv, CONCAT(g.naziv," ",g.postanski_broj) AS grad FROM ucenik AS u
	INNER JOIN skola ON skola.id=u.id_skola
	INNER JOIN grad AS g ON g.id=u.id_grad
	ORDER BY u.prezime ASC;
