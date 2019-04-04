SELECT su.id
	, su.name
	, su.english_name
	, su.phone
	-- , SUBSTRING(device, LOCATE('消息服务:', device) + CHAR_LENGTH('消息服务:'), 2)
	, CASE SUBSTRING(device, LOCATE('消息服务:', device) + CHAR_LENGTH('消息服务:'), 2)
		WHEN '支持' THEN '是'
		ELSE '否' END as `支持消息服务`
	, CASE SUBSTRING(device, LOCATE('声网教室:', device) + CHAR_LENGTH('声网教室:'), 2)
		WHEN '支持' THEN '是'
		ELSE '否' END as `支持声网教室`
	, IF(LOCATE('系统 # ', device) > 0
		, SUBSTRING(device
			, LOCATE('系统 # ', device) + CHAR_LENGTH('系统 # ')
			, LOCATE(',', device, (LOCATE('系统 # ', device) + CHAR_LENGTH('系统 # '))) - LOCATE('系统 # ', device) - CHAR_LENGTH('系统 # ')
		 )
		, '' ) as `系统`
	, IF(LOCATE('系统 # ', device) > 0
		, SUBSTRING(device
			, LOCATE(', ', device, (LOCATE('系统 # ', device) + CHAR_LENGTH('系统 # '))) + CHAR_LENGTH(', ')
			, LOCATE('#', device, (LOCATE('系统 # ', device) + CHAR_LENGTH('系统 # '))) - LOCATE(', ', device, (LOCATE('系统 # ', device) + CHAR_LENGTH('系统 # '))) - CHAR_LENGTH(', ')
		 )
		, '' ) as `浏览器`
	, CASE IF(LOCATE('视频 # ', device)
		, SUBSTRING(device
			, LOCATE('连接', device, (LOCATE('视频 # ', device))) + CHAR_LENGTH('连接')
			, 2)
		, ''
		) WHEN '成功' THEN '成功'
		  WHEN '不成功' THEN '不成功'
		ELSE '不成功' END as `连接`
	, CASE SUBSTRING(device
		, LOCATE('用户选择：', device, (LOCATE('声音 # ', device))) + CHAR_LENGTH('用户选择：')
		, 3)
		WHEN '听得到' THEN '是'
		WHEN '听不到' THEN '否'
		ELSE ''
		END as `是否听到声音`
	, CASE SUBSTRING(device
		, LOCATE('启用', device, (LOCATE('摄像头 # ', device))) + CHAR_LENGTH('启用')
		, 2)
		WHEN '正常' THEN '是'
		WHEN '失败' THEN '否'
		ELSE ''
		END as `摄像头启用`
	, CASE SUBSTRING(device
		, LOCATE('用户选择：', device, (LOCATE('摄像头 # ', device))) + CHAR_LENGTH('用户选择：')
		, 3)
		WHEN '可以看' THEN '是'
		WHEN '看不到' THEN '否'
		ELSE ''
		END as `摄像头可视`
	, CASE SUBSTRING(device
		, LOCATE('用户选择：', device, (LOCATE('麦克风 # ', device))) + CHAR_LENGTH('用户选择：')
		, 3)
		WHEN '可以听' THEN '是'
		WHEN '听不到' THEN '否'
		WHEN LOCATE('可以听到麦克风', device) > 0 THEN '是' 
		ELSE ''
		END AS `麦克风听到`
	, convert_tz(FROM_UNIXTIME(create_at), '+00:00', '+08:00') as `记录时间`
	, IF(COUNT(DISTINCT nl.created_at) > 0, '是', '否') as `是否进入测网课`
from newuuabc.net_test as nt
	INNER JOIN newuuabc.student_user as su
		on nt.user_id = su.id
	LEFT JOIN classroom.network_log as nl
		ON nt.user_id = nl.user_id
			and UNIX_TIMESTAMP(nl.created_at) BETWEEN nt.create_at and nt.create_at + 1000  
where convert_tz(FROM_UNIXTIME(nt.create_at), '+00:00', '+08:00') >= '2019-01-08'
	AND convert_tz(FROM_UNIXTIME(nt.create_at), '+00:00', '+08:00') < '2019-01-09'
	and su.flag = 1
GROUP by nt.id
order by nt.create_at desc


