CREATE DATABASE Sportana;
\c sportana;

CREATE TABLE IF NOT EXISTS Users (
login VARCHAR(50),
emailSuffix VARCHAR(25),
password VARCHAR(50) NOT NULL,
firstName VARCHAR(50),
lastName VARCHAR(50),
city VARCHAR(50),
birthday DATE,
isActive BOOLEAN DEFAULT TRUE,
numNotifications INT,
auth VARCHAR(100) UNIQUE,
friendliness REAL,
timeliness REAL,
skillLevel REAL,
profilePicture VARCHAR(500),
PRIMARY KEY(login)
);

CREATE TABLE IF NOT EXISTS Friends (
userA VARCHAR(50),
userB VARCHAR(50),
PRIMARY KEY (userA, userB),
FOREIGN KEY (userA)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (userB)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Ratings(
userRated VARCHAR(50),
rater VARCHAR(50),
friendliness REAL,
timeliness REAL,
skillLevel REAL,
PRIMARY KEY (userRated, rater),
FOREIGN KEY (userRated)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY(rater)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Sport(
sport VARCHAR(50),
imageURL VARCHAR(500),
PRIMARY KEY (sport)
);

CREATE TABLE IF NOT EXISTS FavoriteSports(
login VARCHAR(50),
sport VARCHAR(50),
PRIMARY KEY (login, sport),
FOREIGN KEY (login)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (sport)
REFERENCES Sport(sport)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Game(
creator VARCHAR(50),
gameID INT,
gameDate DATE,
gameStart TIME,
gameEnd TIME,
sport VARCHAR(50),
location VARCHAR(100),
numParticipants INT,
minPlayers INT,
maxPlayers INT,
reservedSpots INT,
minAge INT,
maxAge INT,
isPublic BOOLEAN,
isCompetitive BOOLEAN,
PRIMARY KEY (creator, gameID),
FOREIGN KEY (creator)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (sport)
REFERENCES Sport(sport)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Participant(
login VARCHAR(50),
creator VARCHAR(50),
gameID INT,
status INT, -- 0: going, 1: queued, 2: no response
numUnreadNotifications INT,
PRIMARY KEY (login, creator, gameID),
FOREIGN KEY (login)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (creator, gameID)
REFERENCES Game(creator, gameID)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Notifications(
userTo VARCHAR(50),
userFrom VARCHAR(50) NOT NULL,
nid INT,
type INT, -- 0: friend, 1: game, 2: queue, 3: game reminder
timeSent TIMESTAMP,
creator VARCHAR(50),
gameID INT,
PRIMARY KEY (userTo, nid),
FOREIGN KEY (userTo)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (userFrom)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (creator, gameID)
REFERENCES Game(creator, gameID)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS GameWallPost(
userPosting VARCHAR(50),
gameCreator VARCHAR(50),
gameID INT,
pid INT,
post VARCHAR(500),
PRIMARY KEY(gameCreator, gameID, userPosting, pid),
FOREIGN KEY (gameCreator, gameID)
REFERENCES Game(creator, gameID)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (userPosting)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Queue(
login VARCHAR(50),
sport VARCHAR(50),
minAge INT,
maxAge INT,
location VARCHAR(100),
PRIMARY KEY(login, sport),
FOREIGN KEY (login)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (sport)
REFERENCES Sport(sport)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS SearchProfile(
login VARCHAR(50),
sport VARCHAR(50),
minAge INT,
maxAge INT,
location VARCHAR(100),
pid SERIAL,
PRIMARY KEY (login, pid),
FOREIGN KEY (login)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE,
FOREIGN KEY (sport)
REFERENCES Sport(sport)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Times(
login VARCHAR(50),
dateAvailable DATE,
startTime TIME,
endTime TIME,
PRIMARY KEY(login, dateAvailable, startTime, endTime),
FOREIGN KEY (login)
REFERENCES Users(login)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION update_gameID()
	RETURNS TRIGGER AS $$
	DECLARE
		x int8;
	BEGIN
		x := (SELECT max(gameID) FROM Game WHERE Game.creator = NEW.creator);
		IF (x > 0) THEN
	   		NEW.gameID = 1 + x;
		ELSE
	   		NEW.gameID = 1;
		END IF;	   
		RETURN NEW;
	END;
	$$ language 'plpgsql';
	
CREATE OR REPLACE FUNCTION update_gameWallPostID()
	RETURNS TRIGGER AS $$
	DECLARE
		x int8;
	BEGIN
		x := (SELECT max(pid) FROM GameWallPost WHERE GameWallPost.userPosting = NEW.userPosting);
		IF (x > 0) THEN
	   		NEW.pid = 1 + x;
		ELSE
	  	 	NEW.pid = 1;
		END IF;	   
	   	RETURN NEW;
	END;
	$$ language 'plpgsql';
	
CREATE OR REPLACE FUNCTION update_notificationID()
	RETURNS TRIGGER AS $$
	DECLARE
		x int8;
	BEGIN
		x := (SELECT max(nid) FROM Notifications WHERE Notifications.userTo = NEW.userTo);
		IF (x > 0) THEN
	   		NEW.nid = 1 + x;
		ELSE
	   		NEW.nid = 1;
		END IF;	   
	   		RETURN NEW;
	END;
	$$ language 'plpgsql';	  	
	
CREATE OR REPLACE FUNCTION update_notifications()
	RETURNS TRIGGER AS $$
	BEGIN
		UPDATE Users
		SET numNotifications = numNotifications + 1
		WHERE (login = NEW.userTo);
		RETURN NEW;
	END;
	$$ language 'plpgsql';		

CREATE OR REPLACE FUNCTION update_friendliness_timeliness_skillLevel()
	RETURNS TRIGGER AS $$
	BEGIN
		UPDATE Users
		SET friendliness=(SELECT AVG(friendliness) FROM Ratings WHERE (userRated = NEW.userRated)),
		timeliness=(SELECT AVG(timeliness) FROM Ratings WHERE (userRated = NEW.userRated)),
		skillLevel=(SELECT AVG(skillLevel) FROM Ratings WHERE (userRated = NEW.userRated))
		WHERE (Users.login=NEW.userRated);
		RETURN NEW;
	END;
	$$ language 'plpgsql';
	

CREATE OR REPLACE FUNCTION update_number_participants()
	RETURNS TRIGGER AS $$
	BEGIN
		UPDATE Game
		SET numParticipants = numParticipants + 1
		WHERE (creator = NEW.creator) AND (gameID = NEW.gameID);
		RETURN NEW;
	END;
	$$ language 'plpgsql';	
			
CREATE OR REPLACE FUNCTION update_unread_posts()
	RETURNS TRIGGER AS $$
	BEGIN
		UPDATE Participant
		SET numUnreadNotifications = numUnreadNotifications + 1
		WHERE (creator = NEW.gameCreator) AND (gameID = NEW.gameID);
		RETURN NEW;
	END;
	$$ language 'plpgsql';	
	
CREATE TRIGGER update_notifications
	BEFORE INSERT ON Notifications
	FOR EACH ROW
	EXECUTE PROCEDURE update_notifications();  

CREATE TRIGGER update_friendliness_timeliness_skillLevel
	AFTER INSERT ON Ratings
	FOR EACH ROW
	EXECUTE PROCEDURE update_friendliness_timeliness_skillLevel();  

CREATE TRIGGER update_unread_posts
	BEFORE INSERT ON GameWallPost
	FOR EACH ROW
	EXECUTE PROCEDURE update_unread_posts();  

CREATE TRIGGER update_number_participants
	BEFORE INSERT ON Participant
	FOR EACH ROW
	EXECUTE PROCEDURE update_number_participants();  

CREATE TRIGGER auto_increment_gameID
	BEFORE INSERT ON Game
	FOR EACH ROW
	EXECUTE PROCEDURE update_gameID();         

CREATE TRIGGER auto_increment_gameWallPostID
	BEFORE INSERT ON GameWallPost
	FOR EACH ROW
	EXECUTE PROCEDURE update_gameWallPostID();  
	
CREATE TRIGGER auto_increment_notificationID
	BEFORE INSERT ON Notifications
	FOR EACH ROW
	EXECUTE PROCEDURE update_notificationID();  	