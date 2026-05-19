-- Run this in your MySQL database
CREATE TABLE IF NOT EXISTS `Favorites` (
  `id`        INT NOT NULL AUTO_INCREMENT,
  `clientId`  INT NOT NULL,
  `workerId`  INT NOT NULL,
  `createdAt` DATETIME NOT NULL,
  `updatedAt` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_client_worker` (`clientId`, `workerId`),
  CONSTRAINT `fk_fav_client` FOREIGN KEY (`clientId`) REFERENCES `ClientProfiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fav_worker` FOREIGN KEY (`workerId`) REFERENCES `WorkerProfiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
