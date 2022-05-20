-- 1. Добавить внешние ключи. --
ALTER TABLE `dealer`
    ADD CONSTRAINT dealer_company_id_company_fk FOREIGN KEY (id_company)
        REFERENCES company (id_company)
        ON UPDATE CASCADE
        ON DELETE CASCADE;

ALTER TABLE `order`
    ADD CONSTRAINT order_production_id_production_fk FOREIGN KEY (id_production)
        REFERENCES production (id_production)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT order_dealer_id_dealer_fk FOREIGN KEY (id_dealer)
        REFERENCES dealer (id_dealer)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT order_pharmacy_id_pharmacy_fk FOREIGN KEY (id_pharmacy)
        REFERENCES pharmacy (id_pharmacy)
        ON UPDATE CASCADE
        ON DELETE CASCADE;

ALTER TABLE `production`
    ADD CONSTRAINT production_company_id_company_fk FOREIGN KEY (id_company)
        REFERENCES company (id_company)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT production_medicine_id_medicine_fk FOREIGN KEY (id_medicine)
        REFERENCES medicine (id_medicine)
        ON UPDATE CASCADE
        ON DELETE CASCADE;


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
  
  
-- 7. Добавить необходимые индексы. --
CREATE INDEX company_name_idx ON company (name);

CREATE INDEX medicine_name_idx ON medicine (name);

CREATE INDEX medicine_cure_duration_idx ON medicine (cure_duration);

CREATE INDEX production_price_idx ON production (price);

CREATE INDEX order_date_idx ON `order` (date);
