-- 2. Выдать информацию по всем заказам лекарства “Кордерон” компании "Аргус" с указанием названий аптек, дат, объема заказов
SELECT 
  `pharmacy`.`name` AS `name`, 
  `order`.`date` AS `date`,
  `order`.`quantity` AS `quantity`
FROM `order`
  LEFT JOIN `production` ON `production`.`id_production` = `order`.`id_production`
  LEFT JOIN `medicine` ON `medicine`.`id_medicine` = `production`.`id_medicine`
  LEFT JOIN `dealer` ON `dealer`.`id_dealer` = `order`.`id_dealer`
  LEFT JOIN `company` ON `company`.`id_company` = `dealer`.`id_company`
  LEFT JOIN `pharmacy` ON `pharmacy`.`id_pharmacy` = `order`.`id_pharmacy`
WHERE `company`.`name` = "Аргус" AND `medicine`.`name` = "Кордеон";


-- 3. Дать список лекарств компании "Фарма", на которые не были сделаны заказы до 25 января
SELECT
  `medicine`.`name` AS `medicine`,
  `order`.`date` AS `date`,
  `pharmacy`.`name` AS `pharmacy`
FROM `order`
  LEFT JOIN `production` ON `production`.`id_production` = `order`.`id_production`
  LEFT JOIN `medicine` ON `medicine`.`id_medicine` = `production`.`id_medicine` -- ? начинать с лекарств
  LEFT JOIN `pharmacy` ON `pharmacy`.`id_pharmacy` = `order`.`id_pharmacy`
  LEFT JOIN `company` ON `company`.`id_company` = `production`.`id_company`
WHERE `company`.`name` = "Фарма"
GROUP BY `medicine` 
  HAVING MIN(`date`) > "2019-01-25"; -- or is null


-- 4. Дать минимальный и максимальный баллы лекарств каждой фирмы, которая оформила не менее 120 заказов
SELECT 
  `company`.`name` AS `name`,
  MIN(`production`.`rating`) AS `min_rating`,
  MAX(`production`.`rating`) AS `max_rating`,
  SUM(`order`.`quantity`) AS `quantity`
FROM `order`
  LEFT JOIN `production` ON `production`.`id_production` = `order`.`id_production`
  LEFT JOIN `company` ON `company`.`id_company` = `production`.`id_company`
GROUP BY `company`.`name`
  HAVING `quantity` > 120;


-- 5. Дать списки сделавших заказы аптек по всем дилерам компании "AstraZeneca". Если у дилера нет заказов, в названии аптеки проставить NULL
SELECT 
  `pharmacy`.`name` AS `pharmacy`,
  `company`.`name` AS `company`,
  `order`.`date` AS `date`
FROM `order`
  RIGHT JOIN `dealer` ON `dealer`.`id_dealer` = `order`.`id_dealer`
  LEFT JOIN `company` ON `company`.`id_company` = `dealer`.`id_company`
  LEFT JOIN `pharmacy` ON `pharmacy`.`id_pharmacy` = `order`.`id_pharmacy`
WHERE `company`.`name` = "AstraZeneca";


-- 6. Уменьшить на 20% стоимость всех лекарств, если она превышает 3000, а длительность лечения не более 7 дней
UPDATE `production`
  LEFT JOIN `medicine` ON `medicine`.`id_medicine` = `production`.`id_medicine`
SET `production`.`price` = `production`.`price` * 0.8
WHERE `production`.`price` > 3000 
  AND `medicine`.`cure_duration` <= 7;

SELECT * FROM `production`
  LEFT JOIN `medicine` ON `medicine`.`id_medicine` = `production`.`id_medicine`
  WHERE `medicine`.`cure_duration` <= 7;