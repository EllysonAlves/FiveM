-- ============================================================
-- ALVES RACING - INSTALACAO PLUG-AND-PLAY (Qbox + oxmysql)
-- Execute uma vez no banco do servidor antes de iniciar o resource.
-- Seguro para rodar mais de uma vez: usa CREATE IF NOT EXISTS / UPSERT.
-- ============================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `race_tracks` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `checkpoints` LONGTEXT NOT NULL,
  `records` LONGTEXT NULL,
  `creatorid` VARCHAR(80) NULL,
  `creatorname` VARCHAR(120) NULL,
  `distance` FLOAT NOT NULL DEFAULT 0,
  `raceid` VARCHAR(80) NOT NULL,
  `curated` TINYINT(1) NOT NULL DEFAULT 1,
  `access` LONGTEXT NULL,
  `racerid` VARCHAR(80) NOT NULL DEFAULT '',
  `metadata` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_race_tracks_raceid` (`raceid`),
  KEY `idx_race_tracks_name` (`name`),
  KEY `idx_race_tracks_curated` (`curated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `racer_names` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `racerid` VARCHAR(80) NOT NULL,
  `citizenid` VARCHAR(80) NOT NULL,
  `racername` VARCHAR(120) NOT NULL,
  `auth` LONGTEXT NULL,
  `crew` VARCHAR(80) NULL,
  `createdby` VARCHAR(80) NULL,
  `lasttouched` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `races` INT NOT NULL DEFAULT 0,
  `wins` INT NOT NULL DEFAULT 0,
  `tracks` INT NOT NULL DEFAULT 0,
  `ranking` INT NOT NULL DEFAULT 1000,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `crypto` INT NOT NULL DEFAULT 10066,
  `elo_points` INT NOT NULL DEFAULT 0 COMMENT 'Pontos ELO dentro do tier atual',
  `elo_tier` VARCHAR(50) NOT NULL DEFAULT 'Street' COMMENT 'Street, Semi Slick, Slick, Profissional',
  `revoked` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_racer_names_racerid` (`racerid`),
  KEY `idx_racer_names_citizen_active` (`citizenid`, `active`),
  KEY `idx_racer_names_name` (`racername`),
  KEY `idx_racer_names_ranking` (`ranking`),
  KEY `idx_racer_names_elo` (`elo_tier`, `elo_points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `track_times` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `raceSessionId` VARCHAR(64) NULL,
  `trackId` VARCHAR(80) NOT NULL,
  `trackName` VARCHAR(120) NULL,
  `racerName` VARCHAR(120) NOT NULL,
  `racerid` VARCHAR(80) NOT NULL,
  `citizenid` VARCHAR(80) NULL,
  `carClass` VARCHAR(20) NOT NULL DEFAULT 'S',
  `vehicleModel` VARCHAR(80) NOT NULL,
  `vehicleDisplayName` VARCHAR(80) NULL,
  `raceType` VARCHAR(30) NOT NULL DEFAULT 'casual',
  `time` INT NOT NULL,
  `position` INT NULL,
  `totalRacers` INT NULL,
  `laps` INT NOT NULL DEFAULT 0,
  `checkpoints` INT NOT NULL DEFAULT 0,
  `bestLap` INT NULL,
  `averageSpeedKmh` DECIMAL(8,2) NULL,
  `finished` TINYINT(1) NOT NULL DEFAULT 1,
  `finishReason` VARCHAR(32) NOT NULL DEFAULT 'completed',
  `eloBefore` INT NULL,
  `eloAfter` INT NULL,
  `eloDelta` INT NULL,
  `timestamp` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `createdAt` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_track_times_recent` (`timestamp`),
  KEY `idx_track_times_track_recent` (`trackId`, `timestamp`),
  KEY `idx_track_times_racer_recent` (`racerid`, `timestamp`),
  KEY `idx_track_times_citizen_recent` (`citizenid`, `timestamp`),
  KEY `idx_track_times_session` (`raceSessionId`),
  KEY `idx_track_times_type_recent` (`raceType`, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `alves_vehicle_presets` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(80) NOT NULL,
  `vehicleModel` VARCHAR(80) NOT NULL,
  `preset` LONGTEXT NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_alves_vehicle_preset` (`citizenid`, `vehicleModel`),
  KEY `idx_alves_vehicle_preset_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Compatibilidade caso o servidor ja tenha tabelas antigas do cw-racingapp.
ALTER TABLE `race_tracks`
  ADD COLUMN IF NOT EXISTS `racerid` VARCHAR(80) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS `metadata` LONGTEXT NULL;

ALTER TABLE `racer_names`
  ADD COLUMN IF NOT EXISTS `racerid` VARCHAR(80) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS `elo_points` INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS `elo_tier` VARCHAR(50) NOT NULL DEFAULT 'Street';

ALTER TABLE `track_times`
  MODIFY COLUMN `timestamp` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS `raceSessionId` VARCHAR(64) NULL AFTER `id`,
  ADD COLUMN IF NOT EXISTS `trackName` VARCHAR(120) NULL AFTER `trackId`,
  ADD COLUMN IF NOT EXISTS `citizenid` VARCHAR(80) NULL AFTER `racerid`,
  ADD COLUMN IF NOT EXISTS `vehicleDisplayName` VARCHAR(80) NULL AFTER `vehicleModel`,
  ADD COLUMN IF NOT EXISTS `position` INT NULL AFTER `time`,
  ADD COLUMN IF NOT EXISTS `totalRacers` INT NULL AFTER `position`,
  ADD COLUMN IF NOT EXISTS `laps` INT NOT NULL DEFAULT 0 AFTER `totalRacers`,
  ADD COLUMN IF NOT EXISTS `checkpoints` INT NOT NULL DEFAULT 0 AFTER `laps`,
  ADD COLUMN IF NOT EXISTS `bestLap` INT NULL AFTER `checkpoints`,
  ADD COLUMN IF NOT EXISTS `averageSpeedKmh` DECIMAL(8,2) NULL AFTER `bestLap`,
  ADD COLUMN IF NOT EXISTS `finished` TINYINT(1) NOT NULL DEFAULT 1 AFTER `averageSpeedKmh`,
  ADD COLUMN IF NOT EXISTS `finishReason` VARCHAR(32) NOT NULL DEFAULT 'completed' AFTER `finished`,
  ADD COLUMN IF NOT EXISTS `eloBefore` INT NULL AFTER `finishReason`,
  ADD COLUMN IF NOT EXISTS `eloAfter` INT NULL AFTER `eloBefore`,
  ADD COLUMN IF NOT EXISTS `eloDelta` INT NULL AFTER `eloAfter`,
  ADD COLUMN IF NOT EXISTS `createdAt` DATETIME NULL DEFAULT CURRENT_TIMESTAMP AFTER `timestamp`;

-- Uma pista demo simples perto do aeroporto para o servidor ja subir com lobby funcional.
-- Depois e so cadastrar/substituir pelas pistas reais do servidor.
INSERT INTO `race_tracks` (`name`, `checkpoints`, `creatorid`, `creatorname`, `distance`, `raceid`, `curated`, `access`, `racerid`, `metadata`)
VALUES (
  'Alves Demo - LSIA Sprint',
  '[{"coords":{"x":-1034.04,"y":-2733.89,"z":20.16},"offset":{"left":{"x":-1039.04,"y":-2733.89,"z":20.16},"right":{"x":-1029.04,"y":-2733.89,"z":20.16}}},{"coords":{"x":-1190.42,"y":-2495.64,"z":13.94},"offset":{"left":{"x":-1195.42,"y":-2495.64,"z":13.94},"right":{"x":-1185.42,"y":-2495.64,"z":13.94}}},{"coords":{"x":-1000.44,"y":-2220.77,"z":8.98},"offset":{"left":{"x":-1005.44,"y":-2220.77,"z":8.98},"right":{"x":-995.44,"y":-2220.77,"z":8.98}}},{"coords":{"x":-815.32,"y":-2477.25,"z":13.82},"offset":{"left":{"x":-820.32,"y":-2477.25,"z":13.82},"right":{"x":-810.32,"y":-2477.25,"z":13.82}}}]',
  'alves',
  'Alves Racing',
  2800,
  'ALVES-DEMO-LSIA-001',
  1,
  '{}',
  'SYSTEM',
  '{}'
)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `checkpoints` = VALUES(`checkpoints`),
  `distance` = VALUES(`distance`),
  `curated` = VALUES(`curated`);

UPDATE `track_times`
SET `timestamp` = COALESCE(`createdAt`, NOW())
WHERE `timestamp` IS NULL OR `timestamp` = '0000-00-00 00:00:00';

UPDATE `track_times` tt
LEFT JOIN `race_tracks` rt ON rt.`raceid` = tt.`trackId`
SET tt.`trackName` = COALESCE(tt.`trackName`, rt.`name`)
WHERE tt.`trackName` IS NULL;
