-- create table
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

-- EDA
SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;

SELECT COUNT(DISTINCT album) FROM spotify;

SELECT DISTINCT album_type FROM spotify;

SELECT MAX(duration_min) FROM spotify;

SELECT MIN(duration_min) FROM spotify;

SELECT * FROM spotify
WHERE duration_min = 0;

DELETE FROM spotify
WHERE duration_min = 0;

SELECT DISTINCT channel FROM spotify;

SELECT DISTINCT most_played_on FROM spotify;

-- -------------------------------------------
-- Data Analysis
-- -------------------------------------------

-- Names of all tracks that have more than 1 Billion streams.

SELECT track FROM spotify
WHERE stream > 1000000000;

-- List all albums along with their respective artists

SELECT DISTINCT album, artist
FROM spotify 
ORDER BY album;

-- Total number of comments for tracks where licensed = TRUE

SELECT SUM(Comments) AS total_comments FROM spotify
WHERE licensed = 'TRUE';

-- Find all track that belong to album type single.

SELECT * FROM spotify
WHERE album_type = 'single';

-- Count total number of tracks by each artist

SELECT artist, COUNT(track) AS total_number_of_tracks
FROM spotify
GROUP BY artist
ORDER BY total_number_of_tracks DESC;

-- Calculate average danceability of tracks in each album

SELECT album, AVG(danceability) AS avg_danceability
FROM spotify
GROUP BY album
ORDER BY avg_danceability DESC;

-- Top 5 tracks with highest energy values

SELECT track, AVG(energy) AS max_energy 
FROM spotify
GROUP BY track
ORDER BY max_energy DESC
LIMIT 5;

-- List all tracks along with total views and likes where official_video = TRUE

SELECT track, AVG(views) AS total_views, AVG(likes) AS total_likes
FROM spotify
WHERE official_video = 'TRUE'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Top 5 most viewed tracks

SELECT DISTINCT track, AVG(views) AS views FROM spotify
GROUP BY track
ORDER BY views DESC
LIMIT 5;

-- Calculate total views of all associated tracks for each album

SELECT album, track, AVG(views) AS total_views
FROM spotify
GROUP BY 1,2
ORDER BY 3 DESC;

-- Retrieve the track names that have been streamed on spotify more than YouTube.

SELECT * FROM
(SELECT track, 
	COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) as stream_on_spotify, 
	COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) as stream_on_youtube
FROM spotify
GROUP BY 1
) AS data
WHERE stream_on_spotify > stream_on_youtube
	AND stream_on_youtube <> 0;

-- Find top 3 most viewed tracks for each artist using window function

WITH ranking_artist
AS
(SELECT artist, track, SUM(views) AS total_views,
	DENSE_RANK() OVER(PARTITION BY artist ORDER BY SUM(views) DESC) as rank
FROM spotify
GROUP BY 1, 2
ORDER BY 1, 3 DESC
)
SELECT * FROM ranking_artist
WHERE rank <= 3;

-- Write query to find tarcks where the liveness score is above average

SELECT track, artist, liveness FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify);

-- Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.

WITH energy_levels
AS
(SELECT album, MAX(energy) AS max_energy, MIN(energy) AS min_energy 
FROM spotify
GROUP BY album
)
SELECT album, max_energy - min_energy as energy_diff
FROM energy_levels
ORDER BY energy_diff DESC;


-- Find tracks where the energy-to-liveness ratio is greater than 1.2

SELECT track, (energy/liveness) as ratio
FROM spotify
WHERE (energy/liveness) > 1.2
ORDER BY 2 DESC;

-- OR

WITH calculated_ratio AS
(SELECT track, energy/liveness as energy_to_liveliness_ratio FROM spotify)

SELECT * FROM calculated_ratio
WHERE energy_to_liveliness_ratio > 1.2
ORDER BY 2 DESC;

-- Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.

SELECT artist, track, views, likes, SUM(likes) 
OVER(PARTITION BY track ORDER BY views DESC) as total_likes
FROM spotify
ORDER BY views DESC;


-- -------------------------------------
-- Query Optimization
-- -------------------------------------

EXPLAIN ANALYZE -- et 9.087ms pt 0.158ms
SELECT artist, track, views
FROM spotify
WHERE artist = 'Gorillaz'
	AND
	most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;


CREATE INDEX artist_index on spotify(artist); 
