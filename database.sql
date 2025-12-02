-- Database setup for Kurai Crafting System
-- Run this SQL script on your FiveM database

CREATE TABLE IF NOT EXISTS `bldr_crafting_players` (
  `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
  `xp` INT NOT NULL DEFAULT 0,
  `level` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Optional: Create index for faster lookups
CREATE INDEX IF NOT EXISTS `idx_level` ON `bldr_crafting_players` (`level`);

-- Optional: Table for storing custom crafting stations (if using admin station placement)
CREATE TABLE IF NOT EXISTS `bldr_crafting_stations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `coords` TEXT NOT NULL,
  `heading` FLOAT DEFAULT 0.0,
  `data` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
