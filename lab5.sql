use lab5_schema;

-- 1. Добавить внешние ключи --
ALTER TABLE `room`
ADD CONSTRAINT `FK_room_hotel_id_hotel` FOREIGN KEY (`id_hotel`)
REFERENCES `hotel`(`id_hotel`)
	ON DELETE CASCADE
	ON UPDATE CASCADE;

ALTER TABLE `room`
ADD CONSTRAINT `FK_room_room_category_id_room_category` FOREIGN KEY (`id_room_category`)
REFERENCES `room_category`(`id_room_category`) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE;
    
ALTER TABLE `booking`
ADD CONSTRAINT `FK_booking_client_id_client` FOREIGN KEY (`id_client`) 
REFERENCES `client`(`id_client`) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE;

ALTER TABLE `room_in_booking`
ADD CONSTRAINT `FK_room_in_booking_booking_id_booking` FOREIGN KEY (`id_booking`) 
REFERENCES `booking`(`id_booking`) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE;
    
ALTER TABLE `room_in_booking`
ADD CONSTRAINT `FK_room_in_booking_room_id_room` FOREIGN KEY (`id_room`)
REFERENCES `room`(`id_room`) 
	ON DELETE CASCADE 
	ON UPDATE CASCADE;


-- Временная таблица для последующих обращений к ней --
CREATE TEMPORARY TABLE `client_booking_info`
SELECT `client`.`id_client`, `client`.`name` AS `client`, `phone`, `hotel`.`id_hotel`, `hotel`.`name` AS `hotel`, `room`.`id_room`,
	`room`.`number` AS `room_number`, `room_category`.`id_room_category`, `room_category`.`name` AS `room_category`, 
    `id_room_in_booking`, `booking_date`, `checkin_date`, `checkout_date` FROM `client`
JOIN `booking` ON `client`.`id_client` = `booking`.`id_client`
JOIN `room_in_booking` ON `room_in_booking`.`id_room_in_booking` = `booking`.`id_booking`
JOIN `room` ON `room`.`id_room` = `room_in_booking`.`id_room`
JOIN `room_category` ON `room`.`id_room_category` = `room_category`.`id_room_category`
JOIN `hotel` ON `hotel`.`id_hotel` = `room`.`id_hotel`;

SELECT * FROM `client_booking_info`;


-- 2. Выдать информацию о клиентах гостиницы “Космос”, проживающих в номерах категории “Люкс” на 1 апреля 2019г. --
SELECT `client`, `phone` FROM `client_booking_info`
WHERE (`id_hotel` = 1) AND (`id_room_category` = 5) AND (`checkin_date` <= "2019-04-01") AND (`checkout_date` > "2019-04-01");


-- 3. Дать список свободных номеров всех гостиниц на 22 апреля --
SELECT `hotel`.`name`, `number` AS `free_room` FROM `room`
JOIN `hotel` ON `room`.`id_hotel` = `hotel`.`id_hotel`
WHERE `id_room` IN (
	SELECT `id_room` FROM `room_in_booking`
  WHERE "2019-04-22" NOT BETWEEN `room_in_booking`.`checkin_date` AND `room_in_booking`.`checkout_date`
) OR `id_room` NOT IN (SELECT `id_room` FROM `room_in_booking`);


-- 4. Дать количество проживающих в гостинице “Космос” на 23 марта по каждой категории номеров --
SELECT `hotel`, `room_category`, COUNT(`room_category`) AS `number_of_clients` FROM `client_booking_info`
WHERE (`id_hotel` = 1) AND (`checkin_date` <= "2019-03-23") AND (`checkout_date` > "2019-03-23")
GROUP BY `room_category`;


-- 5. Дать список последних проживавших клиентов по всем комнатам гостиницы “Космос”, выехавшим в апреле с указанием даты выезда. --
SELECT `client` AS `last_client`, `room_number`, MAX(`checkout_date`) AS `checkout_date` FROM `client_booking_info`
WHERE (`id_hotel` = 1) AND (MONTH(`checkout_date`) = 4)
GROUP BY `room_number`;


-- 6. Продлить на 2 дня дату проживания в гостинице “Космос” всем клиентам комнат категории “Бизнес”, которые заселились 10 мая. --
UPDATE `room_in_booking`
SET `room_in_booking`.`checkout_date` = ADDDATE(`checkout_date`, INTERVAL 2 DAY)
WHERE `id_room_in_booking` = (
	SELECT `id_room_in_booking` FROM `client_booking_info`
	WHERE (`id_hotel` = 1) AND (`id_room_category` = 3) AND (`checkin_date` = "2019-03-10")
);


-- 7. Найти все "пересекающиеся" варианты проживания. 
-- Правильное состояние: не может быть забронирован один номер на одну дату несколько раз, 
-- т.к. нельзя заселиться нескольким клиентам в один номер. Записи в таблице room_in_booking с id_room_in_booking = 5 и 2154 
-- являются примером неправильного состояния, которые необходимо найти. 
-- Результирующий кортеж выборки должен содержать информацию о двух конфликтующих номерах.

SELECT `left`.`id_room_in_booking`, `left`.`id_booking`, `left`.`id_room`, `left`.`checkin_date`, `left`.`checkout_date`,
	`right`.`id_room_in_booking`, `right`.`id_booking`, `right`.`id_room`, `right`.`checkin_date`, `right`.`checkout_date`
FROM `room_in_booking` AS `left`, `room_in_booking` AS `right`
WHERE (`left`.`id_room` = `right`.`id_room` AND `left`.`id_booking` != `right`.`id_booking`) AND
	((`left`.`checkin_date` <= `right`.`checkin_date` AND `left`.`checkout_date` > `right`.`checkin_date`) OR
    (`right`.`checkin_date` <= `left`.`checkin_date` AND `right`.`checkout_date` > `left`.`checkin_date`));
    

-- 8. Создать бронирование в транзакции. 
START TRANSACTION;

SET @client_id = 13;
SET @checkin_date = "2022-04-15", @checkout_date = "2022-05-15";
SET @hotel_id = 9;
SET @room_number = 66;

INSERT INTO `booking` (`id_client`, `booking_date`)
VALUES (@client_id, "2022-03-15");

SET @id_booking = (
	SELECT `id_booking` FROM `booking`
	ORDER BY `booking_date` DESC LIMIT 1
);

SET @id_room = (
	SELECT r.`id_room` FROM room r
	INNER JOIN `hotel` h ON r.`id_hotel` = h.`id_hotel` AND h.`id_hotel` = @hotel_id
	WHERE r.`number` = @room_number LIMIT 1
);

INSERT INTO room_in_booking (id_booking, id_room, checkin_date, checkout_date)
VALUES (@id_booking, @id_room, @checkin_date, @checkout_date);

COMMIT;


-- 9. Добавить необходимые индексы для всех таблиц. --
CREATE INDEX `ix_hotel_name` 
ON `hotel`(`name`);

CREATE INDEX `ix_room_id_room_category_id_hotel` 
ON `room`(`id_room_category`, `id_hotel`);

CREATE INDEX `ix_room_in_booking_checkin_date_checkout_date` 
ON `room_in_booking`(`checkin_date`, `checkout_date`);

-- Удаление временной таблицы
DROP TABLE IF EXISTS `client_booking_info`;