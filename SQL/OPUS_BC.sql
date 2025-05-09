CREATE DATABASE OPUS_BC;
USE OPUS_BC;

CREATE TABLE Patients (
P_ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
First_Name VARCHAR(50) NOT NULL,
Middle_Name VARCHAR(50) NULL DEFAULT '-',
Last_Name VARCHAR(50) NOT NULL ,
Sex ENUM("F","M"),
Date_Of_Birth DATE,
PESEL CHAR(11) NOT NULL,
UNIQUE (PESEL)
);

CREATE TABLE P_Address(
P_ID INT NOT NULL, 
Street VARCHAR(50) NOT NULL,
Building_No INT NOT NULL,
Flat_No INT,
City VARCHAR(30) NOT NULL,
State CHAR(2) NULL DEFAULT '-',
Zip_Code VARCHAR(6) NOT NULL ,
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID)
);

CREATE TABLE P_Contact(
P_ID INT NOT NULL, 
Cell_Phone1 CHAR(9) NOT NULL,
Cell_Phone2 VARCHAR(15) NULL DEFAULT '-',
Add_Phone VARCHAR(15) NULL DEFAULT '-',
Email_Address1 VARCHAR(30) NOT NULL,
Email_Address2 VARCHAR(30) NULL DEFAULT '-',
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID),
UNIQUE (Cell_Phone1)
);

CREATE TABLE Nurse(
N_ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
N_First_Name VARCHAR(50) NOT NULL,
N_Middle_Name VARCHAR(50) NULL DEFAULT '-',
N_Last_Name VARCHAR(50) NOT NULL,
N_Office_No INT NOT NULL
);

CREATE TABLE Sampling(
Sample_ID VARCHAR(10) NOT NULL PRIMARY KEY, 
P_ID INT NOT NULL, 
Sampling_Date DATE NOT NULL,
Sampling_Time TIME NOT NULL,
N_ID INT NOT NULL, 
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID),
FOREIGN KEY(N_ID) REFERENCES Nurse(N_ID)
);

CREATE TABLE Doctor(
D_ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
D_First_Name VARCHAR(50) NOT NULL,
D_Middle_NAME VARCHAR(50) NULL DEFAULT '-',
D_Last_Name VARCHAR(50) NOT NULL,
D_Office_No INT NOT NULL
);

CREATE TABLE Therapy(
P_ID INT NOT NULL, 
D_ID INT NOT NULL, 
Start_Date DATE NOT NULL,
C_Stage ENUM('S1', 'S2', 'S3', 'S4') NOT NULL,
Therapy_Type VARCHAR(100) NOT NULL,
Name_Of_Drug VARCHAR(30) NULL DEFAULT '-',
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID),
FOREIGN KEY(D_ID) REFERENCES Doctor(D_ID)
);

CREATE TABLE Sample_Handler(
H_ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
H_First_Name VARCHAR(50) NOT NULL,
H_Middle_Name VARCHAR(50) NULL DEFAULT '-',
H_Last_Name VARCHAR(50) NOT NULL
);

CREATE TABLE Liquid_Biopsy(
Sample_ID VARCHAR(10) NOT NULL, 
H_ID INT NOT NULL, 
Blood_Collection_No ENUM("BC1","BC2","BC3") NOT NULL,
Blood_Volume_Ml FLOAT NOT NULL,
Plasma_Volume_Ml FLOAT NOT NULL,
PMNC ENUM("YES", "NO") NOT NULL,
PBMC_Mln_Ml FLOAT NOT NULL,
CTCs_No INT NULL DEFAULT 0,
FOREIGN KEY(Sample_ID)REFERENCES Sampling(Sample_ID),
FOREIGN KEY(H_ID) REFERENCES Sample_Handler(H_ID)
);

CREATE TABLE Morphology(
P_ID INT NOT NULL, 
Date_Time_Of_Test TIMESTAMP NOT NULL,
Leu FLOAT NOT NULL,
Neu FLOAT NOT NULL,
Lym FLOAT NOT NULL,
Mon FLOAT NOT NULL,
Eos FLOAT NOT NULL,
Bas FLOAT NOT NULL,
PLT INT NOT NULL,
RBC FLOAT NOT NULL,
Normal_Range ENUM("YES", "NO"),
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID)
);

INSERT INTO Patients
(First_Name, Middle_Name, Last_Name, Sex, Date_Of_Birth, PESEL)
VALUES
('Mary', 'Anna', 'Brown', 'F', '1964-11-21', '64112107543'),
('Patricia', NULL, 'Smith', 'F', '1983-04-12', '83041298769'),
('Linda', 'Virginia', 'Williams', 'F', '1964-08-23', '64082365439'),
('Barbara', 'Debra', 'Miller', 'F', '1978-12-03', '78120312123'),
('Elizabeth', NULL, 'Jackson', 'F', '1967-04-18', '67041802029'),
('Jennifer', 'Carolyn', 'Martin', 'F', '1988-11-24', '88112487633'),
('Susan', 'Amy', 'Moore', 'F', '1959-12-30', '59123095463'),
('Barbara', 'Martha', 'Taylor', 'F', '1963-07-24', '63072402329'),
('Linda', 'Anna', 'Lewis', 'F', '1992-10-08', '92100832349'),
('Joseph', 'Anthony', 'Hunt', 'M', '1973-06-14', '73061467684'),
('Dorothy', 'Shirley', 'Walker', 'F', '1964-05-29', '64052946765'),
('Helen', NULL, 'Phillips', 'F', '1982-02-13','82021389945');

INSERT INTO P_Address
(P_ID, Street, Building_No, Flat_No, City, State, Zip_Code)
VALUES
(1, 'Park Lane', 7, 12, 'New York', 'NY', '10001'),
(2, 'London Road', 57, 7, 'Duluth', 'MN', '55802'),
(3, 'Main Street', 102, 38, 'Window Rock', 'AZ', '86515'),
(4, 'Victoria Road', 1, 3, 'Jacksonville', 'NC', '28546'),
(5, 'Manor Road', 25, NULL, 'Austin', 'TX', '73301'),
(6, 'Green Lane Road', 74, 5, 'Green Lane', 'PA', '18054'),
(7, 'Main Street', 10, 15, 'Dysart', 'PA', '16636'),
(8, 'Manor Road', 64, NULL, 'Austin', 'TX', '78660'),
(9, 'Park Avenue', 23, 6, 'New York', 'NY', '10172'),
(10, 'Queens Road', 11, 2, 'Los Angeles', 'CA', '90069'),
(11, 'Mill Lane', 19, NULL, 'Foster', 'VA', '23056'),
(12, 'Alexander Road', 3, 2, 'West Windsor Township', 'NJ', '08540');

INSERT INTO P_Contact
(P_ID, Cell_Phone1, Cell_Phone2, Add_Phone, Email_Address1, Email_Address2)
VALUES
(1, '123987456', NULL, NULL, 'm.brown64@gmail.com', NULL),
(2, '635490283', '763524718', NULL, 'p.smith667@gmail.com', NULL),
(3, '823716253', NULL, NULL, 'linda.v.williams@gmail.com', 'l.williams64@yahoo.com'),
(4, '192384756', '172693847', '192837152', 'b.d.miller78@gmail.com', NULL),
(5, '948577263', NULL, NULL, 'e.jackson67@yahoo.com', 'Elizabeth_jackson667@gmail.com'),
(6, '155247389', '365477283', NULL, 'jenn.c.martin88@gmail.com', NULL),
(7, '777345226', NULL, NULL, 'susan.a.moore_59@gmail.com', 'SMoore.dec59@yahoo.com'),
(8, '883744756', '009837265', NULL, '.m.taylor@yahoo.com', NULL),
(9, '118277365', NULL, NULL, 'Li.a.levis992@gmail.com', 'vis.a.vis92@yahoo.com'),
(10, '883655238', NULL, NULL, 'Joseph.a.hunt@gmail.com', NULL),
(11, '228736545', '099828376', '112536748', 'Do.shi.wa64@yahoo.com', NULL),
(12, '877336527', NULL, NULL, 'helen_phillips82@gmail.com', 'h.philips82@yahoo.com');

INSERT INTO Nurse
(N_First_Name, N_Middle_Name, N_Last_Name, N_Office_No)
VALUES
('Rebecca', NULL, 'Davis', 135),
('Sharon', 'Mary', 'Garcia', 135),
('Emily', 'Nancy', 'Anderson', 134);

INSERT INTO Sampling
(Sample_ID, P_ID, Sampling_Date, Sampling_Time, N_ID)
VALUES
('OBC1', 1, '2023-12-21', '07:20:00', 2),
('OBC2', 2, '2023-12-22', '08:00:00', 2),
('OBC3', 3, '2024-01-05', '08:05:00', 3),
('OBC4', 4, '2024-01-06', '07:35:00', 2),
('OBC5', 5, '2024-01-08', '08:00:00', 1),
('OBC6', 6, '2024-01-12', '08:45:00', 2),
('OBC7', 7, '2024-01-24', '07:20:00', 1),
('OBC8', 8, '2024-01-27', '08:00:00', 1),
('OBC9', 9, '2024-02-13', '08:50:00', 2),
('OBC10', 10, '2024-02-22', '07:35:00', 3),
('OBC11', 11, '2024-03-01', '07:30:00', 2),
('OBC1_2', 1, '2024-03-12', '08:45:00', 2),
('OBC12', 12, '2024-03-18', '09:00:00', 1),
('OBC2_2', 2, '2024-03-19', '07:45:00', 3),
('OBC4_2', 4, '2024-03-30', '08:05:00', 3);

INSERT INTO Doctor
(D_First_Name, D_Middle_NAME, D_Last_Name, D_Office_No)
VALUES
('Charles', 'David', 'Gupta', 210),
('Elizabeth', NULL, 'Wang', 211);

INSERT INTO Therapy
(P_ID, D_ID, Start_Date, C_Stage, Therapy_Type, Name_Of_Drug)
VALUES
(1, 1, '2023-12-23', 'S2', 'chemotherapy', 'doxorubicin'),
(2, 1, '2023-12-23', 'S1', 'chemotherapy', 'paclitaxel'),
(3, 2, '2024-01-07', 'S2', 'surgery', NULL),
(4, 1, '2024-01-11', 'S3', 'chemotherapy', 'doxorubicin'),
(5, 2, '2024-01-13', 'S1', 'chemotherapy', 'cisplatin'),
(6, 1, '2024-01-17', 'S2', 'chemotherapy', 'fluorouracil'),
(7, 1, '2024-01-27', 'S2', 'surgery', NULL),
(8, 2, '2024-02-01', 'S1', 'chemotherapy', 'cisplatin'),
(9, 2, '2024-02-16', 'S1', 'immunotherapy', 'pembrolizumab'),
(10, 2, '2024-02-23', 'S3', 'chemotherapy', 'doxorubicin'),
(11, 1, '2024-03-02', 'S4', 'chemotherapy + immunotherapy', 'doxorubicin + pembrolizumab'),
(12, 1, '2024-03-21', 'S1', 'chemotherapy', 'cisplatin');

INSERT INTO Sample_Handler
(H_First_Name, H_Middle_Name, H_Last_Name)
VALUES
('Susan', 'Ashley', 'Tomphson'),
('Kimberly', NULL, 'Thomas'),
('Margaret', 'Sarah', 'Jones'),
('Michelle', 'Donna', 'Robinson');

INSERT INTO Liquid_Biopsy
(Sample_ID, H_ID , Blood_Collection_No, Blood_Volume_Ml, Plasma_Volume_Ml, PMNC, PBMC_Mln_Ml, CTCs_No)
VALUES
('OBC1', 1, 'BC1', 12.5, 3, 'YES', 1.32, 1),
('OBC2', 1, 'BC1', 10.5, 2.5, 'YES', 1.89, 2),
('OBC3', 1, 'BC1', 11, 2.7, 'YES',  1.72, 0),
('OBC4', 2, 'BC1', 12, 3, 'YES', 1.28,  2),
('OBC5', 1, 'BC1', 12, 2.8, 'YES', 2.1,  0),
('OBC6', 1, 'BC1', 11.5, 2.5, 'YES', 1.45,  1),
('OBC7', 3, 'BC1', 11, 2.4, 'YES', 1.56, 1),
('OBC8', 4, 'BC1', 10.7, 2.6, 'YES', 1.81,  1),
('OBC9', 4, 'BC1', 10.5, 2.5, 'YES', 1.38, 0),
('OBC10', 1, 'BC1', 11, 2.3, 'YES', 1.42, 0),
('OBC11', 1, 'BC1', 12.5, 2.3, 'YES', 1.79, 2),
('OBC1_2', 1, 'BC2', 10, 1.8, 'NO', 1.67, 2),
('OBC12', 2, 'BC1', 12.5, 2.4, 'YES', 1.55, 1),
('OBC2_2', 2, 'BC2', 10, 1.9, 'NO', 2.1, 3),
('OBC4_2', 4, 'BC2', 10, 1.5, 'NO', 1.26, 3);

INSERT INTO Morphology
(P_ID, Date_Time_Of_Test, Leu, Neu, Lym, Mon, Eos, Bas, PLT, RBC, Normal_Range)
VALUES
(1, '2023-12-21 12:32:00', 5.87, 2.38, 1.30, 0.32, 1.2, 0.5, 289, 4.0, 'YES'),
(2, '2023-12-22 12:17:00', 9.58, 5.12, 2.15, 0.48, 3.4, 1.0, 315, 5.5, 'NO'),
(3, '2024-01-05 13:37:00', 2.11, 1.79, 1.23, 0.25, 0.5, 0.3, 120, 3.1, 'NO'),
(4, '2024-01-06 12:07:00', 4.12, 4.28, 2.03, 0.47, 1.9, 0.2, 137, 3.2, 'YES'),
(5, '2024-01-08 11:58:00', 10.03, 6.04, 3.42, 0.90, 6.5, 1.2, 276, 3.0, 'NO'),
(6, '2024-01-12 13:45:00', 8.72, 4.99, 3.18, 0.51, 5.8, 1.1, 213, 3.0, 'NO'),
(7, '2024-01-24 11:28:00', 3.13, 1.56, 1.31, 0.32, 0.7, 0.6, 380, 3.2, 'NO'),
(8, '2024-01-27 12:19:00', 9.12, 2.13, 2.46, 0.45, 3.2, 0.5, 373, 4.1, 'YES'),
(9, '2024-02-13 14:05:00', 11.03, 6.07, 3.52, 0.78, 5.6, 0.8, 138, 3.1, 'NO'),
(10, '2024-02-22 12:00:00', 3.99, 3.76, 1.78, 0.81, 2.1,  0.5, 280, 5.0, 'YES'),
(11, '2024-03-01 12:39:00', 7.89, 4.14, 2.11, 0.76, 4.6, 1.1, 222, 2.9, 'NO'),
(1, '2024-03-12 13:48:00', 9.99, 5.29, 1.99, 0.44, 5.3, 0.6, 111, 3.0, 'NO' ),
(12, '2024-03-18 14:12:00', 8.03, 4.18, 1.88, 0.39, 4.9, 0.7, 147, 3.2, 'YES'),
(2, '2024-03-19 12:51:00', 6.77, 3.33, 1.32,  0.37, 5.5, 0.3, 300, 3.3, 'YES'),
(4, '2024-03-30 13:03:00', 4.65, 2.01, 1.27, 0.27, 2.1, 0.2, 177, 3.1, 'NO');

-- Patients age form date of birth
SELECT *, DATE_FORMAT(FROM_DAYS(DATEDIFF(NOW(), Date_Of_Birth)), '%Y') 
 + 0 AS Age
 FROM Patients;
 
-- ALTER TABLE Patients
-- ADD Age INT;

-- UPDATE Patients
-- SET Age = DATE_FORMAT(FROM_DAYS(DATEDIFF(NOW(), Date_Of_Birth)), '%Y') + 0;

-- Data of personnel associated with each patient
SELECT
First_Name AS Patient_Name, Last_Name AS Patient_Surname, 
D_First_Name AS Doctor_Name, D_Last_Name AS Doctor_Surname, 
N_First_Name AS Nurse_Name, N_Last_Name AS Nurse_Surname, 
H_First_Name AS LabTech_Name, H_Last_Name AS LabTech_Surname
FROM
Sampling S
JOIN
Nurse N ON S.N_ID = N.N_ID
JOIN 
Patients P ON S.P_ID = P.P_ID
JOIN 
Therapy T ON P.P_ID = T.P_ID
JOIN 
Doctor D ON T.D_ID = D.D_ID
JOIN 
Liquid_Biopsy L ON S.Sample_ID = L.Sample_ID 
JOIN 
Sample_Handler H ON L.H_ID = H.H_ID
ORDER BY P.P_ID;

-- Comparison of patients' morphology results after the second blood draw
SELECT M.P_ID
FROM Morphology M
GROUP BY P_ID
HAVING COUNT(*) > 1;

SELECT a.*
FROM Morphology a
JOIN (SELECT P_ID, COUNT(*)
FROM Morphology
GROUP BY P_ID
HAVING COUNT(*) > 1 ) b
ON a.P_ID = b.P_ID
ORDER BY P_ID;

-- Number of CTCs and tumor stage for each female patient
SELECT P.P_ID AS Patient_ID, CTCs_No, C_Stage AS Cancer_Stage
FROM
Therapy T
JOIN
Sampling S ON T.P_ID = S.P_ID
JOIN 
Liquid_Biopsy L ON S.Sample_ID = L.Sample_ID
JOIN 
Patients P ON P.P_ID = T.P_ID AND P.P_ID = S.P_ID
WHERE
P.Sex = 'F'
ORDER BY P.P_ID;

-- Search for decreased or increased morphotic components in morphology results (e.g. neutrophils and leukocytes)
DELIMITER $$
CREATE FUNCTION Morphology_Range(
    Value FLOAT,
    Min_Value FLOAT,
    Max_Value FLOAT
)
RETURNS VARCHAR(1)
DETERMINISTIC
BEGIN
    DECLARE Result VARCHAR(1);
    
    IF (Value >= Min_Value AND 
		Value <= Max_Value) THEN
		SET Result = '-';
	ELSEIF Value < Min_Value THEN
		SET Result = '↓';
	ELSEIF Value > Max_Value THEN
		SET Result = '↑';
	END IF;
    
		RETURN Result;
END$$

DELIMITER ;

SELECT M.P_ID, Morphology_Range(Neu, 1.78, 6.04)
FROM Morphology M
ORDER BY M.P_ID;

SELECT M.P_ID, Morphology_Range(Leu, 3.98, 10.04)
FROM Morphology M
ORDER BY M.P_ID;

-- Inserting new patient data into a table
DELIMITER $$
CREATE PROCEDURE Insert_Patient_Data(
IN First_Name VARCHAR(50), 
IN Middle_Name VARCHAR(50),
IN Last_Name VARCHAR(50),
IN Sex ENUM("F","M"),
IN Date_Od_Birth DATE,
IN PESEL CHAR(11))
BEGIN

INSERT INTO Patients(First_Name, Middle_Name, Last_Name, Sex, Date_Of_Birth, PESEL)
VALUES (First_Name, Middle_Name, Last_Name, Sex, Date_Of_Birth, PESEL);
END$$
DELIMITER ;

CALL Insert_Patient_Data ('Joanna', 'Maria', 'Kowalska', 'F', '1990-02-23', '90022398675');

-- Archiving of morphology results
CREATE TABLE Morphology_Archives(
P_ID INT NOT NULL, 
Date_Time_Of_Test TIMESTAMP NOT NULL,
Leu FLOAT NOT NULL,
Neu FLOAT NOT NULL,
Lym FLOAT NOT NULL,
Mon FLOAT NOT NULL,
Eos FLOAT NOT NULL,
Bas FLOAT NOT NULL,
PLT INT NOT NULL,
RBC FLOAT NOT NULL,
Normal_Range ENUM("YES", "NO"),
Deleted_At TIMESTAMP DEFAULT NOW(),
FOREIGN KEY(P_ID) REFERENCES Patients(P_ID)
);


DELIMITER $$

CREATE TRIGGER Before_Morphology_Delete
BEFORE DELETE
ON Morphology FOR EACH ROW
BEGIN
    INSERT INTO Morphology_Archives(P_ID, Date_Time_Of_Test, Leu, Neu, Lym, Mon, Eos, Bas, PLT, RBC, Normal_Range)
    VALUES(OLD.P_ID, OLD.Date_Time_Of_Test, OLD.Leu, OLD.Neu, OLD.Lym, OLD.Mon, OLD.Eos, OLD.Bas, OLD.PLT, OLD.RBC, OLD.Normal_Range);
END$$ 
DELIMITER ;

INSERT INTO Morphology
(P_ID, Date_Time_Of_Test, Leu, Neu, Lym, Mon, Eos, Bas, PLT, RBC, Normal_Range)
VALUES
(13, '2023-12-21 12:32:00', 5.55, 2.33, 1.40, 0.31, 1.2, 0.7, 133, 4.0, 'YES');


DELETE FROM Morphology WHERE P_ID = 13;

SELECT * FROM Morphology_Archives;


