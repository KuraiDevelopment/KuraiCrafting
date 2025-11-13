-- Advanced Crafting System Database Schema
-- Compatible with oxmysql for QBCore/QBox

-- ====================== PLAYER PROGRESSION TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_progression` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `level` INT(11) NOT NULL DEFAULT 0,
  `xp` INT(11) NOT NULL DEFAULT 0,
  `total_crafted` INT(11) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  KEY `level_index` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== CRAFTING STATISTICS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_stats` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `recipe_id` VARCHAR(100) NOT NULL,
  `amount` INT(11) NOT NULL DEFAULT 1,
  `success` TINYINT(1) NOT NULL DEFAULT 1,
  `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid_index` (`citizenid`),
  KEY `recipe_index` (`recipe_id`),
  KEY `timestamp_index` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== DYNAMIC CRAFTING STATIONS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_stations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `station_type` VARCHAR(50) NOT NULL,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0.0,
  `show_blip` TINYINT(1) NOT NULL DEFAULT 0,
  `label` VARCHAR(100) NOT NULL,
  `created_by` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `station_type_index` (`station_type`),
  KEY `created_by_index` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== OPTIONAL: ACHIEVEMENTS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_achievements` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `achievement_id` VARCHAR(100) NOT NULL,
  `unlocked_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_achievement` (`citizenid`, `achievement_id`),
  KEY `citizenid_index` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== INDEXES FOR PERFORMANCE ======================
-- Additional indexes for common queries
CREATE INDEX idx_crafting_stats_citizen_recipe ON crafting_stats(citizenid, recipe_id);
CREATE INDEX idx_progression_level ON crafting_progression(level DESC);

-- ====================== VIEWS FOR ANALYTICS (OPTIONAL) ======================
-- Top crafters view
CREATE OR REPLACE VIEW `top_crafters` AS
SELECT 
    citizenid,
    level,
    xp,
    total_crafted,
    RANK() OVER (ORDER BY level DESC, xp DESC) as ranking
FROM crafting_progression
ORDER BY level DESC, xp DESC
LIMIT 100;

-- Most crafted items view
CREATE OR REPLACE VIEW `popular_recipes` AS
SELECT 
    recipe_id,
    COUNT(*) as times_crafted,
    SUM(amount) as total_amount,
    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_crafts,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed_crafts,
    ROUND(SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM crafting_stats
GROUP BY recipe_id
ORDER BY times_crafted DESC;

-- Recent activity view
CREATE OR REPLACE VIEW `recent_crafting_activity` AS
SELECT 
    cs.citizenid,
    cs.recipe_id,
    cs.amount,
    cs.success,
    cs.timestamp,
    cp.level as crafter_level
FROM crafting_stats cs
LEFT JOIN crafting_progression cp ON cs.citizenid = cp.citizenid
ORDER BY cs.timestamp DESC
LIMIT 100;
