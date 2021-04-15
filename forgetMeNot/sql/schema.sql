PRAGMA foreign_keys = ON;

CREATE TABLE speakers(
speakerID INT NOT NULL,
fullname VARCHAR(40) NOT NULL,
relationship VARCHAR(40) NOT NULL,
photo BLOB,
PRIMARY KEY(speakerID)
);


