-- 每周三发送给柯的语句
	SELECT
		`ts`.`teacher_id` AS `teacher_id`,
		`tun`.`english_name` AS `english_name`,
		from_unixtime(min(`tc`.`effective_start_time`)) AS `首次薪资生效时间`
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
	ORDER BY
		`tc`.`effective_start_time` DESC
		
		
		
		
-- 临时拉的数据
SELECT  tun.id
      , tun.english_name
      , tun.email
      , c.name_english as country
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_start_time))), '无有效合同') AS `当前签约合同开始日`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_end_time))), '无有效合同') AS `当前签约合同结束日`
FROM newuuabc.teacher_user_new AS tun
	LEFT JOIN newuuabc.teacher_signed AS ts
		ON tun.id = ts.teacher_id 
			AND ts.enable = 1 
			AND ts.status = 1
			AND ts.effective_end_time >= UNIX_TIMESTAMP(CURDATE())
  LEFT JOIN newuuabc.country c 
    ON tun.country=c.country_id
WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
GROUP BY tun.id

---------------------------------------------------------------------
---------------------------------------------------------------------
SELECT  tun.id
      , tun.english_name
      , tun.email
      , tun.skype
      , tc.salary/100 `1v1时薪(美元)`
      , tc.salary_class/100 as `小班课时薪(美元)`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_start_time))), '无有效合同') AS `当前签约合同开始日`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_start_time))) +interval 6 month, '无有效合同') AS `当前签约合同开始日+6月`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_end_time))), '无有效合同') AS `当前签约合同结束日`
FROM newuuabc.teacher_user_new AS tun
	inner JOIN newuuabc.teacher_signed AS ts
		ON tun.id = ts.teacher_id 
			AND ts.enable = 1 
			AND ts.status = 1
			AND ts.effective_end_time >= UNIX_TIMESTAMP(CURDATE())
  inner join (
          select   signed_id
                   ,salary
                   ,salary_class
          FROM newuuabc.teacher_contract 
          where FROM_UNIXTIME(effective_end_time)>=current_date
            )  AS tc
		ON ts.id = tc.signed_id
WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
GROUP BY tun.id
