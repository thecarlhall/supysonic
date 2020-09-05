CREATE TABLE IF NOT EXISTS folder (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    root BOOLEAN NOT NULL,
    name VARCHAR(256) NOT NULL,
    path VARCHAR(4096) NOT NULL,
    path_hash BINARY(20) UNIQUE NOT NULL,
    created DATETIME NOT NULL,
    cover_art VARCHAR(256),
    last_scan INTEGER NOT NULL,
    parent_id INTEGER REFERENCES folder(id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_folder_parent_id_fk ON folder(parent_id);

CREATE TABLE IF NOT EXISTS artist (
    id BINARY(16) PRIMARY KEY,
    name VARCHAR(256) NOT NULL
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS album (
    id BINARY(16) PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    artist_id BINARY(16) NOT NULL REFERENCES artist(id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_album_artist_id_fk ON album(artist_id);

CREATE TABLE IF NOT EXISTS track (
    id BINARY(16) PRIMARY KEY,
    disc INTEGER NOT NULL,
    number INTEGER NOT NULL,
    title VARCHAR(256) NOT NULL,
    year INTEGER,
    genre VARCHAR(256),
    duration INTEGER NOT NULL,
    has_art BOOLEAN NOT NULL DEFAULT false,
    album_id BINARY(16) NOT NULL REFERENCES album(id),
    artist_id BINARY(16) NOT NULL REFERENCES artist(id),
    bitrate INTEGER NOT NULL,
    path VARCHAR(4096) NOT NULL,
    path_hash BINARY(20) UNIQUE NOT NULL,
    created DATETIME NOT NULL,
    last_modification INTEGER NOT NULL,
    play_count INTEGER NOT NULL,
    last_play DATETIME,
    root_folder_id INTEGER NOT NULL REFERENCES folder(id),
    folder_id INTEGER NOT NULL REFERENCES folder(id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_track_album_id_fk ON track(album_id);
CREATE INDEX index_track_artist_id_fk ON track(artist_id);
CREATE INDEX index_track_folder_id_fk ON track(folder_id);
CREATE INDEX index_track_root_folder_id_fk ON track(root_folder_id);

CREATE TABLE IF NOT EXISTS user (
    id BINARY(16) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    mail VARCHAR(256),
    password CHAR(40) NOT NULL,
    salt CHAR(6) NOT NULL,
    admin BOOLEAN NOT NULL,
    jukebox BOOLEAN NOT NULL,
    podcast BOOLEAN NOT NULL,
    lastfm_session CHAR(32),
    lastfm_status BOOLEAN NOT NULL,
    last_play_id BINARY(16) REFERENCES track(id),
    last_play_date DATETIME
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_user_last_play_id_fk ON user(last_play_id);

CREATE TABLE IF NOT EXISTS client_prefs (
    user_id BINARY(16) NOT NULL,
    client_name VARCHAR(32) NOT NULL,
    format VARCHAR(8),
    bitrate INTEGER,
    PRIMARY KEY (user_id, client_name)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS starred_folder (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    starred_id INTEGER NOT NULL REFERENCES folder(id),
    date DATETIME NOT NULL,
    PRIMARY KEY (user_id, starred_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_starred_folder_user_id_fk ON starred_folder(user_id);
CREATE INDEX index_starred_folder_starred_id_fk ON starred_folder(starred_id);

CREATE TABLE IF NOT EXISTS starred_artist (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    starred_id BINARY(16) NOT NULL REFERENCES artist(id),
    date DATETIME NOT NULL,
    PRIMARY KEY (user_id, starred_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_starred_artist_user_id_fk ON starred_artist(user_id);
CREATE INDEX index_starred_artist_starred_id_fk ON starred_artist(starred_id);

CREATE TABLE IF NOT EXISTS starred_album (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    starred_id BINARY(16) NOT NULL REFERENCES album(id),
    date DATETIME NOT NULL,
    PRIMARY KEY (user_id, starred_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_starred_album_user_id_fk ON starred_album(user_id);
CREATE INDEX index_starred_album_starred_id_fk ON starred_album(starred_id);

CREATE TABLE IF NOT EXISTS starred_track (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    starred_id BINARY(16) NOT NULL REFERENCES track(id),
    date DATETIME NOT NULL,
    PRIMARY KEY (user_id, starred_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_starred_track_user_id_fk ON starred_track(user_id);
CREATE INDEX index_starred_track_starred_id_fk ON starred_track(starred_id);

CREATE TABLE IF NOT EXISTS rating_folder (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    rated_id INTEGER NOT NULL REFERENCES folder(id),
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    PRIMARY KEY (user_id, rated_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_rating_folder_user_id_fk ON rating_folder(user_id);
CREATE INDEX index_rating_folder_rated_id_fk ON rating_folder(rated_id);

CREATE TABLE IF NOT EXISTS rating_track (
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    rated_id BINARY(16) NOT NULL REFERENCES track(id),
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    PRIMARY KEY (user_id, rated_id)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_rating_track_user_id_fk ON rating_track(user_id);
CREATE INDEX index_rating_track_rated_id_fk ON rating_track(rated_id);

CREATE TABLE IF NOT EXISTS chat_message (
    id BINARY(16) PRIMARY KEY,
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    time INTEGER NOT NULL,
    message VARCHAR(512) NOT NULL
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_chat_message_user_id_fk ON chat_message(user_id);

CREATE TABLE IF NOT EXISTS playlist (
    id BINARY(16) PRIMARY KEY,
    user_id BINARY(16) NOT NULL REFERENCES user(id),
    name VARCHAR(256) NOT NULL,
    comment VARCHAR(256),
    public BOOLEAN NOT NULL,
    created DATETIME NOT NULL,
    tracks TEXT
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX index_playlist_user_id_fk ON playlist(user_id);

CREATE TABLE meta (
    `key` VARCHAR(32) PRIMARY KEY,
    value VARCHAR(256) NOT NULL
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS radio_station (
    id BINARY(16) PRIMARY KEY,
    stream_url VARCHAR(256) NOT NULL,
    name VARCHAR(256) NOT NULL,
    homepage_url VARCHAR(256),
    created DATETIME NOT NULL
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS podcast_channel (
    id BINARY(16) PRIMARY KEY,
    url VARCHAR(256) UNIQUE NOT NULL,
    title VARCHAR(256),
    description VARCHAR(256),
    cover_art VARCHAR(256),
    original_image_url VARCHAR(256),
    status TINYINT NOT NULL,
    error_message VARCHAR(256),
    created TIMESTAMP NOT NULL,
    last_fetched TIMESTAMP,
    INDEX index_channel_status (status)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS podcast_episode (
    id BINARY(16) PRIMARY KEY,
    stream_url VARCHAR(256) NOT NULL,
    file_path VARCHAR(256),
    channel_id BINARY(16) NOT NULL,
    title VARCHAR(256),
    description VARCHAR(256),
    duration VARCHAR(8),
    status TINYINT NOT NULL,
    publish_date DATETIME,
    error_message VARCHAR(256),
    created DATETIME NOT NULL,
    size INTEGER,
    suffix VARCHAR(8),
    bitrate INTEGER,
    content_type VARCHAR(64),
    cover_art VARCHAR(256),
    genre VARCHAR(16),
    year SMALLINT,
    FOREIGN KEY(channel_id) REFERENCES podcast_channel(id),
    INDEX index_episode_channel_id_fk (channel_id),
    INDEX index_episode_status (status),
    UNIQUE(channel_id, title, stream_url)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
