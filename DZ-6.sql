/* 
1. Написать функцию, которая удаляет всю информацию об указанном пользователе из БД vk. 
Пользователь задается по id. Удалить нужно все сообщения, лайки, медиа записи, профиль и запись из таблицы users. 
Функция должна возвращать номер пользователя.
 */


USE vk;

DROP FUNCTION IF EXISTS del_user;
 
ALTER TABLE `vk`.`profiles` DROP FOREIGN KEY `profiles_ibfk_2`;
ALTER TABLE `vk`.`profiles` ADD CONSTRAINT `profiles_ibfk_2` FOREIGN KEY (`photo_id`) REFERENCES `media`(`id`) ON UPDATE CASCADE ON DELETE CASCADE;

 
DELIMITER // 

CREATE FUNCTION del_user(del_user_id BIGINT UNSIGNED)
RETURNS BIGINT DETERMINISTIC
  BEGIN
	
	DELETE FROM messages msg WHERE msg.from_user_id  = del_user_id OR msg.to_user_id = del_user_id;
	DELETE FROM users_communities uc WHERE uc.user_id  = del_user_id;
	DELETE FROM friend_requests fr WHERE fr.initiator_user_id = del_user_id OR fr.target_user_id = del_user_id;

	DELETE FROM likes l WHERE l.user_id  = del_user_id;
	DELETE FROM likes WHERE media_id IN (SELECT id FROM media WHERE user_id = del_user_id);

	DELETE FROM profiles p WHERE p.user_id = del_user_id;
	DELETE FROM media m WHERE m.user_id  = del_user_id;

	DELETE FROM users u WHERE u.id = del_user_id;
	  
	RETURN del_user_id; 
  END//

DELIMITER ; 
  

SELECT concat('удален пользователь ', del_user(1));


-- 2. Предыдущую задачу решить с помощью процедуры и обернуть используемые команды в транзакцию внутри процедуры.
USE vk;

 
ALTER TABLE `vk`.`profiles` DROP FOREIGN KEY `profiles_ibfk_2`;
ALTER TABLE `vk`.`profiles` ADD CONSTRAINT `profiles_ibfk_2` FOREIGN KEY (`photo_id`) REFERENCES `media`(`id`) ON UPDATE CASCADE ON DELETE CASCADE;


DROP PROCEDURE IF EXISTS `remove_user`;

DELIMITER $$

CREATE PROCEDURE `remove_user` (IN r_user_id BIGINT UNSIGNED, OUT tran_result varchar(200))
BEGIN
   DECLARE `_rollback` BOOL DEFAULT 0;
   DECLARE code varchar(100);
   DECLARE error_string varchar(100);

   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
   begin
    	SET `_rollback` = 1;
	GET stacked DIAGNOSTICS CONDITION 1
          code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
    	set tran_result := concat('Error occured. Code: ', code, '. Text: ', error_string);
    end;
   
   START TRANSACTION;
    DELETE FROM messages msg WHERE msg.from_user_id  = r_user_id OR msg.to_user_id = r_user_id;
	DELETE FROM users_communities uc WHERE uc.user_id  = r_user_id;
	DELETE FROM friend_requests fr WHERE fr.initiator_user_id = r_user_id OR fr.target_user_id = r_user_id;

	DELETE FROM likes l WHERE l.user_id  = r_user_id;
	DELETE FROM likes WHERE media_id IN (SELECT id FROM media WHERE user_id = r_user_id);
	DELETE FROM profiles p WHERE p.user_id = r_user_id;
	DELETE FROM media m WHERE m.user_id  = r_user_id;

	DELETE FROM users u WHERE u.id = r_user_id;
  
  IF `_rollback` THEN
	       ROLLBACK;
	    ELSE
		set tran_result := concat('удален пользователь ', r_user_id); -- 'ok';
	       COMMIT;
	    END IF;

END$$

DELIMITER ;

call remove_user(5, @tran_result);
select @tran_result;