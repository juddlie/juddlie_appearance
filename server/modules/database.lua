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
end)
