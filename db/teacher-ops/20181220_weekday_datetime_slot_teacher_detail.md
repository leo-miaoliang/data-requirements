# 周一至周五白天有可用车位外教老师列表


**需求来源**

提出人: "柯雁影"<yanying.ke@uuabc.com>

部门:

**拉取周期**
临时


**用途**


**详细**

```
```

**SQL**

```sql

SELECT
    t2.teacher_user_id
    ,t2.english_name
    ,case when t2.weekday = 1 then '周一'
            when t2.weekday = 2 then '周二'
            when t2.weekday = 3 then '周三'
            when t2.weekday = 4 then '周四'
            when t2.weekday = 5 then '周五'
    end as weekday
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
    from
        (SELECT
            st.teacher_user_id
            ,st.id
            ,tt.english_name
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
        and cs.start_time between 615 and 1035
        inner join
            newuuabc.teacher_signed ts
        on  st.teacher_user_id = ts.teacher_id
        and st.signed_id = ts.id
        and ts.enable = 1
        and ts.status = 1
        and current_date between date(from_unixtime(ts.effective_start_time)) and date(from_unixtime(ts.effective_end_time))
        where st.weekday between 1 and 5  -- 周一至周五
        and current_date between date(from_unixtime(st.effective_start_time)) and date(from_unixtime(st.effective_end_time))
        )   t1
    group by t1.teacher_user_id, t1.english_name, t1.weekday
    )   t2
;
```

**备注**

