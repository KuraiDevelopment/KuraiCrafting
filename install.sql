-- ============================================================================
-- KURAI.DEV ADVANCED CRAFTING SYSTEM v3.0
-- Database Schema with Prop Storage
-- ============================================================================

-- Player Progression
CREATE TABLE IF NOT EXISTS `crafting_progression` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `level` INT(11) NOT NULL DEFAULT 0,
  `xp` INT(11) NOT NULL DEFAULT 0,
  `total_crafted` INT(11) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Crafting Statistics
CREATE TABLE IF NOT EXISTS `crafting_stats` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `recipe_id` VARCHAR(100) NOT NULL,
  `amount` INT(11) NOT NULL DEFAULT 1,
  `success` TINYINT(1) NOT NULL DEFAULT 1,
  `quality` VARCHAR(20) DEFAULT 'normal',
  `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `recipe_id` (`recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Blueprints
CREATE TABLE IF NOT EXISTS `crafting_blueprints` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `recipe_id` VARCHAR(100) NOT NULL,
  `unlocked_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_blueprint` (`citizenid`, `recipe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Specializations
CREATE TABLE IF NOT EXISTS `crafting_specializations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `specialization` VARCHAR(50) NOT NULL,
  `spec_level` INT(11) NOT NULL DEFAULT 1,
  `spec_xp` INT(11) NOT NULL DEFAULT 0,
  `selected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dynamic Crafting Stations with Prop Data
CREATE TABLE IF NOT EXISTS `crafting_stations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `station_type` VARCHAR(50) NOT NULL,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0.0,
  `show_blip` TINYINT(1) NOT NULL DEFAULT 0,
  `label` VARCHAR(100) NOT NULL,
  `prop` VARCHAR(100) DEFAULT NULL,
  `prop_offset_x` FLOAT DEFAULT 0.0,
  `prop_offset_y` FLOAT DEFAULT 0.0,
  `prop_offset_z` FLOAT DEFAULT -1.0,
  `created_by` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `station_type` (`station_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Achievements (Future)
CREATE TABLE IF NOT EXISTS `crafting_achievements` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `achievement_id` VARCHAR(100) NOT NULL,
  `progress` INT(11) DEFAULT 0,
  `completed` TINYINT(1) DEFAULT 0,
  `unlocked_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_achievement` (`citizenid`, `achievement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Leaderboard View
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

-- Popular Recipes View
CREATE OR REPLACE VIEW `popular_recipes` AS
SELECT 
    recipe_id,
    COUNT(*) as times_crafted,
    SUM(amount) as total_amount,
    ROUND(SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM crafting_stats
GROUP BY recipe_id
ORDER BY times_crafted DESC;
