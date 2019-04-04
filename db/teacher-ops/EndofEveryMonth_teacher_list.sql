    SELECT
		`ts`.`teacher_id` AS `teacher_id`,
		`tun`.`english_name` AS `english_name`,
		 from_unixtime(min(`tc`.`effective_start_time`)) AS `首次薪资生效时间`,
		 from_unixtime(max(`tc`.`effective_end_time`)) AS `当前合同结束日`,
		 tun.comment AS `备注`
	FROM `newuuabc`.`teacher_signed` `ts`
	   JOIN `newuuabc`.`teacher_contract` `tc` 
            ON (`ts`.`id` = `tc`.`signed_id`)
	   JOIN `newuuabc`.`teacher_user_new` `tun` 
            ON (`ts`.`teacher_id` = `tun`.`id`)
	WHERE
		  (`tun`.`status` = 3)
			AND (`tun`.`type` = 1)
			AND (`tun`.`disable` = 1)
			AND (`ts`.`enable` = 1)
			AND (`ts`.`status` = 1)
	GROUP BY
		`ts`.`teacher_id`
    HAVING from_unixtime(min(`tc`.`effective_start_time`)) <='2018-11-30'
	ORDER BY
		`ts`.`teacher_id` asc