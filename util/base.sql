CREATE DATABASE Helico;
-- \c Helico;

CREATE TABLE Obstacle (
    id SERIAL PRIMARY KEY,
    x INT,
    y INT,
    width INT,
    height INT
);
CREATE TABLE Arrival(
    id SERIAL PRIMARY KEY,
    x INT,
    y INT,
    taille INT
);

INSERT INTO Obstacle (x, y, width, height) VALUES (200, 100, 50, 700);
INSERT INTO Obstacle (x, y, width, height) VALUES (390, 100, 50, 730);
INSERT INTO Obstacle (x, y, width, height) VALUES (630, 75, 50, 730);

INSERT INTO Obstacle (x, y, width, height) VALUES (50, 500, 70, 10);
INSERT INTO Obstacle (x, y, width, height) VALUES (750, 650, 70, 10);




