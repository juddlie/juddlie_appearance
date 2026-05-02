---@param table_ string
---@param column string
---@param ddl string
local function addColumnIfMissing(table_, column, ddl)
  local exists <const> = MySQL.scalar.await(
    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?",
    { table_, column }
  ) or 0
  
  if exists == 0 then
    MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN %s"):format(table_, ddl))
  end
end

MySQL.ready(function()
  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance` (
      `identifier` VARCHAR(60) NOT NULL,
      `skin`       LONGTEXT    NOT NULL,
      PRIMARY KEY (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_presets` (
      `id`         INT          NOT NULL AUTO_INCREMENT,
      `identifier` VARCHAR(60)  NOT NULL,
      `preset_id`  VARCHAR(60)  NOT NULL,
      `name`       VARCHAR(100) NOT NULL,
      `tags`       TEXT         DEFAULT NULL,
      `data`       LONGTEXT     NOT NULL,
      `share_code` VARCHAR(20)  DEFAULT NULL,
      `created_at` BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_outfits` (
      `id`         INT          NOT NULL AUTO_INCREMENT,
      `identifier` VARCHAR(60)  NOT NULL,
      `outfit_id`  VARCHAR(60)  NOT NULL,
      `name`       VARCHAR(100) NOT NULL,
      `category`   VARCHAR(30)  DEFAULT 'custom',
      `data`       LONGTEXT     NOT NULL,
      `share_code` VARCHAR(20)  DEFAULT NULL,
      `favorite`   TINYINT(1)   DEFAULT 0,
      `created_at` BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_job_outfits` (
      `id`         INT          NOT NULL AUTO_INCREMENT,
      `identifier` VARCHAR(60)  NOT NULL,
      `job`        VARCHAR(60)  NOT NULL,
      `data`       LONGTEXT     NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `identifier_job` (`identifier`, `job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_faction_uniforms` (
      `id`         INT          NOT NULL AUTO_INCREMENT,
      `faction`    VARCHAR(60)  NOT NULL,
      `kind`       VARCHAR(10)  NOT NULL DEFAULT 'job',
      `uniform_id` VARCHAR(60)  NOT NULL,
      `name`       VARCHAR(100) NOT NULL,
      `min_grade`  INT          NOT NULL DEFAULT 0,
      `data`       LONGTEXT     NOT NULL,
      `created_by` VARCHAR(60)  DEFAULT NULL,
      `created_at` BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `faction_kind_uniform` (`faction`, `kind`, `uniform_id`),
      KEY `faction` (`faction`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_share_codes` (
      `code`         VARCHAR(20) NOT NULL,
      `identifier`   VARCHAR(60) NOT NULL,
      `kind`         VARCHAR(20) NOT NULL DEFAULT 'outfit',
      `payload`      LONGTEXT    NOT NULL,
      `max_uses`     INT         NOT NULL DEFAULT 0,
      `uses`         INT         NOT NULL DEFAULT 0,
      `expires_at`   BIGINT      DEFAULT NULL,
      `created_at`   BIGINT      NOT NULL,
      PRIMARY KEY (`code`),
      KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_marketplace` (
      `id`           VARCHAR(60)  NOT NULL,
      `seller`       VARCHAR(60)  NOT NULL,
      `seller_name`  VARCHAR(100) DEFAULT NULL,
      `name`         VARCHAR(100) NOT NULL,
      `description`  TEXT         DEFAULT NULL,
      `category`     VARCHAR(30)  DEFAULT 'custom',
      `tags`         TEXT         DEFAULT NULL,
      `price`        INT          NOT NULL DEFAULT 0,
      `data`         LONGTEXT     NOT NULL,
      `purchases`    INT          NOT NULL DEFAULT 0,
      `created_at`   BIGINT       NOT NULL,
      `expires_at`   BIGINT       DEFAULT NULL,
      `status`       VARCHAR(20)  NOT NULL DEFAULT 'active',
      PRIMARY KEY (`id`),
      KEY `seller` (`seller`),
      KEY `status_created` (`status`, `created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_owned_items` (
      `id`           INT          NOT NULL AUTO_INCREMENT,
      `identifier`   VARCHAR(60)  NOT NULL,
      `item_kind`    VARCHAR(20)  NOT NULL,
      `item_key`     VARCHAR(60)  NOT NULL,
      `acquired_at`  BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `identifier_item` (`identifier`, `item_kind`, `item_key`),
      KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_drops` (
      `id`           VARCHAR(60)  NOT NULL,
      `name`         VARCHAR(100) NOT NULL,
      `description`  TEXT         DEFAULT NULL,
      `tier`         VARCHAR(20)  NOT NULL DEFAULT 'seasonal',
      `data`         LONGTEXT     NOT NULL,
      `restrictions` LONGTEXT     DEFAULT NULL,
      `starts_at`    BIGINT       DEFAULT NULL,
      `ends_at`      BIGINT       DEFAULT NULL,
      `claimable`    TINYINT(1)   NOT NULL DEFAULT 0,
      `created_by`   VARCHAR(60)  DEFAULT NULL,
      `created_at`   BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      KEY `tier` (`tier`),
      KEY `window` (`starts_at`, `ends_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `juddlie_appearance_wardrobe` (
      `id`           INT          NOT NULL AUTO_INCREMENT,
      `identifier`   VARCHAR(60)  NOT NULL,
      `slot`         INT          NOT NULL,
      `name`         VARCHAR(100) NOT NULL,
      `data`         LONGTEXT     NOT NULL,
      `updated_at`   BIGINT       NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `identifier_slot` (`identifier`, `slot`),
      KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])

  addColumnIfMissing("juddlie_appearance_outfits", "tags", "`tags` TEXT DEFAULT NULL")
end)
