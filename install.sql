-- ============================================================================
-- KURAI.DEV ADVANCED CRAFTING SYSTEM v3.0
-- Database Schema with Blueprints, Specializations, Tool Tracking
-- ============================================================================

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
  `quality` VARCHAR(20) DEFAULT 'normal',
  `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid_index` (`citizenid`),
  KEY `recipe_index` (`recipe_id`),
  KEY `timestamp_index` (`timestamp`),
  KEY `idx_crafting_stats_citizen_recipe` (`citizenid`, `recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== BLUEPRINTS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_blueprints` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `recipe_id` VARCHAR(100) NOT NULL,
  `unlocked_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `unlock_method` VARCHAR(50) DEFAULT 'item',
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_blueprint` (`citizenid`, `recipe_id`),
  KEY `citizenid_index` (`citizenid`),
  KEY `recipe_index` (`recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== SPECIALIZATIONS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_specializations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `specialization` VARCHAR(50) NOT NULL,
  `spec_level` INT(11) NOT NULL DEFAULT 1,
  `spec_xp` INT(11) NOT NULL DEFAULT 0,
  `selected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  KEY `specialization_index` (`specialization`)
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

-- ====================== ACHIEVEMENTS TABLE ======================
CREATE TABLE IF NOT EXISTS `crafting_achievements` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `achievement_id` VARCHAR(100) NOT NULL,
  `progress` INT(11) DEFAULT 0,
  `completed` TINYINT(1) DEFAULT 0,
  `unlocked_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_achievement` (`citizenid`, `achievement_id`),
  KEY `citizenid_index` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== CRAFTING QUEUE TABLE (Optional) ======================
CREATE TABLE IF NOT EXISTS `crafting_queue` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `recipe_id` VARCHAR(100) NOT NULL,
  `amount` INT(11) NOT NULL DEFAULT 1,
  `station_type` VARCHAR(50) NOT NULL,
  `status` ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
  `queued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid_index` (`citizenid`),
  KEY `status_index` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================== INDEXES FOR PERFORMANCE ======================
CREATE INDEX IF NOT EXISTS idx_progression_level ON crafting_progression(level DESC);
CREATE INDEX IF NOT EXISTS idx_blueprints_citizen ON crafting_blueprints(citizenid);
CREATE INDEX IF NOT EXISTS idx_stats_timestamp ON crafting_stats(timestamp DESC);

-- ====================== VIEWS FOR ANALYTICS ======================

-- Top crafters leaderboard
CREATE OR REPLACE VIEW `crafting_leaderboard` AS
SELECT 
    cp.citizenid,
    cp.level,
    cp.xp,
    cp.total_crafted,
    cs.specialization,
    RANK() OVER (ORDER BY cp.level DESC, cp.xp DESC) as ranking
FROM crafting_progression cp
LEFT JOIN crafting_specializations cs ON cp.citizenid = cs.citizenid
ORDER BY cp.level DESC, cp.xp DESC
LIMIT 100;

-- Most popular recipes
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

-- Blueprint distribution
CREATE OR REPLACE VIEW `blueprint_stats` AS
SELECT 
    recipe_id,
    COUNT(*) as players_with_blueprint,
    MIN(unlocked_at) as first_unlock,
    MAX(unlocked_at) as latest_unlock
FROM crafting_blueprints
GROUP BY recipe_id
ORDER BY players_with_blueprint DESC;

-- Specialization distribution
CREATE OR REPLACE VIEW `specialization_distribution` AS
SELECT 
    specialization,
    COUNT(*) as player_count,
    AVG(spec_level) as avg_level
FROM crafting_specializations
GROUP BY specialization
ORDER BY player_count DESC;

-- Recent activity
CREATE OR REPLACE VIEW `recent_crafting_activity` AS
SELECT 
    cs.citizenid,
    cs.recipe_id,
    cs.amount,
    cs.success,
    cs.quality,
    cs.timestamp,
    cp.level as crafter_level,
    csp.specialization
FROM crafting_stats cs
LEFT JOIN crafting_progression cp ON cs.citizenid = cp.citizenid
LEFT JOIN crafting_specializations csp ON cs.citizenid = csp.citizenid
ORDER BY cs.timestamp DESC
LIMIT 100;

-- Player crafting summary
CREATE OR REPLACE VIEW `player_crafting_summary` AS
SELECT 
    cp.citizenid,
    cp.level,
    cp.xp,
    cp.total_crafted,
    csp.specialization,
    csp.spec_level,
    COUNT(DISTINCT cb.recipe_id) as blueprints_owned,
    (SELECT COUNT(*) FROM crafting_stats WHERE citizenid = cp.citizenid AND success = 1) as successful_crafts,
    (SELECT COUNT(*) FROM crafting_stats WHERE citizenid = cp.citizenid AND success = 0) as failed_crafts
FROM crafting_progression cp
LEFT JOIN crafting_specializations csp ON cp.citizenid = csp.citizenid
LEFT JOIN crafting_blueprints cb ON cp.citizenid = cb.citizenid
GROUP BY cp.citizenid;

-- ====================== STORED PROCEDURES (Optional) ======================

DELIMITER //

-- Reset player crafting data
CREATE PROCEDURE IF NOT EXISTS `ResetPlayerCrafting`(IN p_citizenid VARCHAR(50))
BEGIN
    DELETE FROM crafting_progression WHERE citizenid = p_citizenid;
    DELETE FROM crafting_stats WHERE citizenid = p_citizenid;
    DELETE FROM crafting_blueprints WHERE citizenid = p_citizenid;
    DELETE FROM crafting_specializations WHERE citizenid = p_citizenid;
    DELETE FROM crafting_achievements WHERE citizenid = p_citizenid;
    
    INSERT INTO crafting_progression (citizenid, level, xp, total_crafted) 
    VALUES (p_citizenid, 0, 0, 0);
END //

-- Get player crafting rank
CREATE PROCEDURE IF NOT EXISTS `GetPlayerRank`(IN p_citizenid VARCHAR(50))
BEGIN
    SELECT ranking FROM (
        SELECT 
            citizenid,
            RANK() OVER (ORDER BY level DESC, xp DESC) as ranking
        FROM crafting_progression
    ) ranked
    WHERE citizenid = p_citizenid;
END //

DELIMITER ;

-- ====================== MIGRATION HELPERS ======================
-- Run these if upgrading from v2.0

-- Add quality column to existing stats table
-- ALTER TABLE crafting_stats ADD COLUMN IF NOT EXISTS quality VARCHAR(20) DEFAULT 'normal';

-- Add unlock_method to blueprints
-- ALTER TABLE crafting_blueprints ADD COLUMN IF NOT EXISTS unlock_method VARCHAR(50) DEFAULT 'item';

-- Add spec_level and spec_xp to specializations
-- ALTER TABLE crafting_specializations ADD COLUMN IF NOT EXISTS spec_level INT(11) DEFAULT 1;
-- ALTER TABLE crafting_specializations ADD COLUMN IF NOT EXISTS spec_xp INT(11) DEFAULT 0;
