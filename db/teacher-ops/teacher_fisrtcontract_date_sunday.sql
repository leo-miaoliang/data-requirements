drop table if exists bi.nextweek_teacherlist; 
create table bi.nextweek_teacherlist as
SELECT  tun.id
      , tun.english_name
      , tun.email
      , FROM_UNIXTIME(min(ts.effective_start_time)) as first_contract_date
FROM newuuabc.teacher_user_new AS tun
	inner JOIN newuuabc.teacher_signed AS ts
		ON tun.id = ts.teacher_id 
			AND ts.enable = 1 
			AND ts.status = 1
			AND ts.effective_start_time >= UNIX_TIMESTAMP(CURDATE())
WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
GROUP BY tun.id
HAVING  min(ts.effective_start_time)>=UNIX_TIMESTAMP(CURDATE()+interval 1 day) and min(ts.effective_start_time)<UNIX_TIMESTAMP(CURDATE()+interval 9 day)
order by ts.effective_start_time; 
