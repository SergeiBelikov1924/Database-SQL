/* Урок 6. SQL – Транзакции. Временные таблицы, управляющие конструкции, циклы
Для решения задач используйте базу данных lesson4 (скрипт создания, прикреплен к 4 семинару).
- Создайте таблицу users_old, аналогичную таблице users.
- Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users в таблицу users_old.
(использование транзакции с выбором commit или rollback – обязательно).
- Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток.
С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день",
с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
(по желанию)* Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users,
communities и messages в таблицу logs помещается время и дата создания записи, название таблицы,
идентификатор первичного ключа.
 */

USE lesson_4;
-- Создайте таблицу users_old, аналогичную таблице users.

DROP TABLE IF EXISTS lesson_4.users_old;
CREATE TABLE lesson_4.users_old
(
	id INT PRIMARY KEY AUTO_INCREMENT,
    firstname VARCHAR(50) COMMENT 'Имя',
    lastname VARCHAR(50) COMMENT 'Фамилия',
    email VARCHAR(120) UNIQUE
);

-- Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users
-- в таблицу users_old.
-- (использование транзакции с выбором commit или rollback – обязательно).

DROP PROCEDURE IF EXISTS sp_user_move;
DELIMITER //
CREATE PROCEDURE sp_user_move
(
	IN user_id BIGINT,
	OUT tran_result varchar(100)
)
DETERMINISTIC
BEGIN
	
	DECLARE `_rollback` BIT DEFAULT b'0';
	DECLARE code varchar(100);
	DECLARE error_string varchar(100); 

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET `_rollback` = b'1';
 		GET stacked DIAGNOSTICS CONDITION 1
			code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
	END;

	START TRANSACTION;
	 INSERT INTO lesson_4.users_old (firstname, lastname, email)
	 SELECT firstname, lastname, email
	 FROM lesson_4.users
	 WHERE id = user_id;
	 DELETE FROM lesson_4.users
	 WHERE id = user_id;
	
	IF `_rollback` THEN
		SET tran_result = CONCAT('Ошибка: ', code, ' Текст ошибки: ', error_string);
		ROLLBACK;
	ELSE
		SET tran_result = 'Успешно';
		COMMIT;
	END IF;
END//
DELIMITER ;

SELECT * FROM users;
SELECT * IN users_old;
CALL sp_user_move(1, @tran_result); 
SELECT @tran_result;

-- Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток.
-- С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро",
-- с 12:00 до 18:00 функция должна возвращать фразу "Добрый день",
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

DROP FUNCTION IF EXISTS hello;
DELIMITER //
CREATE FUNCTION hello()
RETURNS VARCHAR(12) READS SQL DATA 
BEGIN
	DECLARE res_text VARCHAR(12);
	SELECT
		CASE
			WHEN CURTIME() BETWEEN '06:00:00' AND '11:59:59' THEN 'Доброе утро'
			WHEN CURTIME() BETWEEN '12:00:00' AND '17:59:59' THEN 'Добрый день'
			WHEN CURTIME() BETWEEN '18:00:00' AND '23:59:59' THEN 'Добрый вечер'
			WHEN CURTIME() BETWEEN '00:00:00' AND '05:59:59' THEN 'Доброй ночи'
	END INTO res_text;
	RETURN res_text;
END//
DELIMITER ;

SELECT hello();


