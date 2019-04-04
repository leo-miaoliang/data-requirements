
create table bi.tmp_teacher as 
SELECT
	id,
	english_name,
	CASE
WHEN aa.is_old = 1 THEN
	'列表一'
WHEN aa.is_old = 2 THEN
	'列表二'
END flag
FROM
	newuuabc.teacher_user_new aa
WHERE
	id IN (
		1429,
		1375,
		1348,
		1298,
		1142,
		1418,
		1380,
		1415,
		1432,
		1461,
		1370,
		1294,
		1128,
		1253,
		1284,
		1259,
		1177,
		620,
		1340,
		832,
		900,
		909,
		926,
		949,
		1165,
		1213,
		1222,
		1224,
		1290,
		1323,
		1328,
		1168,
		907,
		1237,
		1300,
		1377,
		1320,
		1318,
		1189,
		961,
		762,
		700,
		747,
		966,
		967,
		1009,
		1094,
		1117,
		1124,
		1456,
		1108,
		936,
		836,
		456,
		1211,
		920,
		679,
		929,
		912,
		1076,
		902,
		1507,
		1486,
		1472,
		1468,
		1286,
		1285,
		840,
		737,
		470,
		910,
		984,
		865,
		156,
		780,
		765,
		719,
		1007,
		1426,
		1493,
		750,
		1323,
		755,
		1444,
		1010,
		1410,
		956,
		593,
		1280,
		796,
		834,
		483,
		1248,
		1287,
		1353,
		1336,
		1469,
		1065,
		1555,
		1393,
		1214,
		829,
		1275,
		1076,
		1099,
		1306,
		1055,
		598,
		1064,
		1025,
		1401,
		1174,
		1025,
		1211,
		1358,
		1076,
		908,
		1467,
		1138,
		1327
	)


select a.*
    ,ifnull(b.time1 ,0)
    ,ifnull(b.time2 ,0)
    ,ifnull(b.time3 ,0)
    ,ifnull(b.time4 ,0)
    ,ifnull(b.time5 ,0)
    ,ifnull(b.time6 ,0)
    ,ifnull(b.time7 ,0)
    ,ifnull(b.time8 ,0)
    ,ifnull(b.time9 ,0)
    ,ifnull(b.time10,0)
    ,ifnull(b.time11,0)
    ,ifnull(b.time12,0)
    ,ifnull(b.time13,0)
    ,ifnull(b.time14,0)
    ,ifnull(b.time15,0)
    ,ifnull(b.time16,0)
    ,ifnull(b.time17,0)
    ,ifnull(b.time18,0)
    ,ifnull(b.time19,0)
from bi.tmp_teacher a
left join 
(SELECT
    t2.teacher_user_id
    ,t2.english_name
    ,t2.time1
    ,t2.time2
    ,t2.time3
    ,t2.time4
    ,t2.time5
    ,t2.time6
    ,t2.time7
    ,t2.time8
    ,t2.time9
    ,t2.time10
    ,t2.time11
    ,t2.time12
    ,t2.time13
    ,t2.time14
    ,t2.time15
    ,t2.time16
    ,t2.time17
    ,t2.time18
    ,t2.time19
from
    (SELECT
        t1.teacher_user_id
        ,t1.english_name
        ,t1.weekday
        ,sum(case when t1.start_time = 615 then 1 else 0 end) as time1
        ,sum(case when t1.start_time = 650 then 1 else 0 end) as time2
        ,sum(case when t1.start_time = 685 then 1 else 0 end) as time3
        ,sum(case when t1.start_time = 720 then 1 else 0 end) as time4
        ,sum(case when t1.start_time = 755 then 1 else 0 end) as time5
        ,sum(case when t1.start_time = 790 then 1 else 0 end) as time6
        ,sum(case when t1.start_time = 825 then 1 else 0 end) as time7
        ,sum(case when t1.start_time = 860 then 1 else 0 end) as time8
        ,sum(case when t1.start_time = 895 then 1 else 0 end) as time9
        ,sum(case when t1.start_time = 930 then 1 else 0 end) as time10
        ,sum(case when t1.start_time = 965 then 1 else 0 end) as time11
        ,sum(case when t1.start_time = 1000 then 1 else 0 end) as time12
        ,sum(case when t1.start_time = 1035 then 1 else 0 end) as time13
        ,sum(case when t1.start_time = 1070 then 1 else 0 end) as time14
        ,sum(case when t1.start_time = 1105 then 1 else 0 end) as time15
	      ,sum(case when t1.start_time = 1140 then 1 else 0 end) as time16
        ,sum(case when t1.start_time = 1175 then 1 else 0 end) as time17
	      ,sum(case when t1.start_time = 1210 then 1 else 0 end) as time18
        ,sum(case when t1.start_time = 1245 then 1 else 0 end) as time19
    from
        (SELECT
            st.teacher_user_id
            ,st.id
            ,tun.english_name
            ,st.weekday
            ,cs.start_time
        from newuuabc.signed_time AS st
        inner join
            newuuabc.teacher_user_new AS tun
        on  st.teacher_user_id = tun.id
        and tun.`type` = 1  -- 1外教
        AND tun.status = 3  -- 3全职签约老师
        AND tun.disable = 1  -- 1有效
        INNER JOIN newuuabc.carport_slot AS cs
        on cs.start_time >= st.start_time
        and cs.end_time <= st.end_time
        and cs.start_time between 615 and 1245
        inner join
            newuuabc.teacher_signed ts
        on  st.teacher_user_id = ts.teacher_id
        and st.signed_id = ts.id
        and ts.enable = 1
        and ts.status = 1
        and current_date between date(from_unixtime(ts.effective_start_time)) and date(from_unixtime(ts.effective_end_time))
        -- change to week
        where st.weekday =1
        and current_date between date(from_unixtime(st.effective_start_time)) and date(from_unixtime(st.effective_end_time))

        )   t1
    group by t1.teacher_user_id, t1.english_name
    )   t2
) b on a.id=b.teacher_user_id
order by a.id




