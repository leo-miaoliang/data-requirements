select t.*,ifnull((case when s.is_cert=1 then '有' when s.is_cert=2 then '无' end),'NA') as is_cert
from 
(
(SELECT  tun.id
      , tun.english_name
      , tun.email
      , tun.skype
      , tc.salary/100 `1v1时薪(美元)`
      , tc.salary_class/100 as `小班课时薪(美元)`
      , tc.salary_live/100   as `直播课时薪`
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
                   ,salary_live
          FROM newuuabc.teacher_contract 
          where FROM_UNIXTIME(effective_end_time)>=current_date
            )  AS tc
		ON ts.id = tc.signed_id
WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
GROUP BY tun.id
)
union ALL
(
SELECT  tun.id
      , tun.english_name
      , tun.email
      , tun.skype
      , ll.salary/100 `1v1时薪(美元)`
      , ll.salary_class/100 as `小班课时薪(美元)`
      , ll.salary_live/100   as `直播课时薪`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_start_time))), '无有效合同') AS `当前签约合同开始日`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_start_time))) +interval 6 month, '无有效合同') AS `当前签约合同开始日+6月`
      , COALESCE(date(FROM_UNIXTIME(MIN(ts.effective_end_time))), '无有效合同') AS `当前签约合同结束日`
FROM newuuabc.teacher_user_new AS tun
	inner JOIN newuuabc.teacher_signed AS ts
		ON tun.id = ts.teacher_id 
			AND ts.enable = 1 
			AND ts.status = 1
			AND ts.effective_end_time >= UNIX_TIMESTAMP(CURDATE())
  left join (
          select   signed_id
                   ,salary
                   ,salary_class
                   ,salary_live
          FROM newuuabc.teacher_contract 
          where FROM_UNIXTIME(effective_end_time)>=current_date
            )  AS tc on ts.id = tc.signed_id
  left join (
        select  signed_id,max(effective_start_time) as effective_start_time
        from  newuuabc.teacher_contract 
        group by signed_id
           ) tcc
		ON ts.id = tcc.signed_id
   inner join newuuabc.teacher_contract ll on tcc.effective_start_time=ll.effective_start_time and ll.signed_id=tcc.signed_id
WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1 and tc.signed_id is null
GROUP BY tun.id
) 
)t
left join
 newuuabc.teacher_info_collect s
  on t.id=s.teacher_id