-- Alves Racing - track_times enriquecida para scoreboard/ranking
-- Execute uma vez no banco do servidor.
-- Mantém as colunas antigas para compatibilidade com scripts já existentes.

ALTER TABLE `track_times`
  MODIFY COLUMN `timestamp` DATETIME NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `track_times`
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

-- Corrige registros recentes que entraram com timestamp zerado por insert numérico em coluna DATETIME.
UPDATE `track_times`
SET `timestamp` = COALESCE(`createdAt`, NOW())
WHERE `timestamp` IS NULL OR `timestamp` = '0000-00-00 00:00:00';

-- Backfill útil para scoreboard sem depender sempre de JOIN.
UPDATE `track_times` tt
LEFT JOIN `race_tracks` rt ON rt.`raceid` = tt.`trackId`
SET tt.`trackName` = COALESCE(tt.`trackName`, rt.`name`)
WHERE tt.`trackName` IS NULL;

CREATE INDEX IF NOT EXISTS `idx_track_times_recent` ON `track_times` (`timestamp`);
CREATE INDEX IF NOT EXISTS `idx_track_times_track_recent` ON `track_times` (`trackId`, `timestamp`);
CREATE INDEX IF NOT EXISTS `idx_track_times_racer_recent` ON `track_times` (`racerid`, `timestamp`);
CREATE INDEX IF NOT EXISTS `idx_track_times_session` ON `track_times` (`raceSessionId`);
CREATE INDEX IF NOT EXISTS `idx_track_times_type_recent` ON `track_times` (`raceType`, `timestamp`);
