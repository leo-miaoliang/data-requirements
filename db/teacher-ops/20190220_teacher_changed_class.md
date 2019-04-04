# 老师变更课时


**需求来源**

提出人: 柯雁影<yanying.ke@uuabc.com>

部门:

**拉取周期**
每日（9点）


**用途**


**详细**

```
```

**SQL**

```sql

drop procedure if exists bi.p_teacher_changed_class_detail;

delimiter //
create procedure bi.p_teacher_changed_class_detail(in in_stat_date date)
begin
    set @stat_date := in_stat_date;
    select
        a1.class_id
        ,a1.class_type1
        ,a1.start_time1
        ,a1.teacher_id_previous
        ,a2.english_name
        ,a1.teacher_id_current
        ,a3.english_name
    from
        (-- 1v1
        select
            t1.id as class_id
            ,t1.class_type1
            ,t1.start_time1
            ,t1.teacher_id as teacher_id_previous
            ,t2.teacher_id as teacher_id_current
        from
            (select
                id
                ,class_id
                ,class_appoint_course_id
                ,'1v1' class_type1
                ,teacher_user_id as teacher_id
                ,convert_tz(from_unixtime(start_time), '+00:00', '+08:00') as start_time1
            from bi.appoint_course_his
            where partition_key = date_format(date_sub(@stat_date, interval 1 day), '%Y%m%d')
            and class_appoint_course_id = 0
            and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between date_format(date_add(@stat_date, interval 0 day), '%Y-%m-%d') and date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d')
            and convert_tz(from_unixtime(start_time), '+00:00', '+08:00') <= date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d 12:00:00')
            )   t1
        left join
            (select
                id
                ,class_id
                ,class_appoint_course_id
                ,'1v1' as class_type1
                ,teacher_user_id as teacher_id
                ,convert_tz(from_unixtime(start_time), '+00:00', '+08:00') as start_time1
            from bi.appoint_course_his
            where partition_key = date_format(@stat_date, '%Y%m%d')
            )   t2
        on  t1.id = t2.id
        where t1.teacher_id <> t2.teacher_id
        and t1.teacher_id <> 0
        and t2.teacher_id <> 0
        -- 1v4old
        union all
        select
            t1.id as class_id
            ,t1.class_type1
            ,t1.start_time1
            ,t1.teacher_id
            ,t2.teacher_id
        from
            (select
                id
                ,'1v4old' class_type1
                ,teacher_user_id as teacher_id
                ,convert_tz(from_unixtime(start_time), '+00:00', '+08:00') as start_time1
            from bi.class_appoint_course_his
            where partition_key = date_format(date_sub(@stat_date, interval 1 day), '%Y%m%d')
            and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between date_format(date_add(@stat_date, interval 0 day), '%Y-%m-%d') and date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d')
            and convert_tz(from_unixtime(start_time), '+00:00', '+08:00') <= date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d 12:00:00')
            )   t1
        left join
            (select
                id
                ,class_id
                ,'1v4old' as class_type1
                ,teacher_user_id as teacher_id
                ,convert_tz(from_unixtime(start_time), '+00:00', '+08:00') as start_time1
            from bi.class_appoint_course_his
            where partition_key = date_format(@stat_date, '%Y%m%d')
            )   t2
        on  t1.id = t2.id
        where t1.teacher_id <> t2.teacher_id
        and t1.teacher_id <> 0
        and t2.teacher_id <> 0
        -- 1v4new
        union all
        select
            t1.room_id as class_id
            ,t1.class_type
            ,t1.start_time1
            ,t1.teacher_id
            ,t2.teacher_id
        from
            (select
                room_id
                ,teacher_id
                ,from_unixtime(start_time) as start_time1
                ,'1v4new' as class_type
            from bi.classroom_his
            where partition_key = date_format(date_sub(@stat_date, interval 1 day), '%Y%m%d')
            and date(from_unixtime(start_time)) between date_format(date_add(@stat_date, interval 0 day), '%Y-%m-%d') and date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d')
            and from_unixtime(start_time) <= date_format(date_add(@stat_date, interval 1 day), '%Y-%m-%d 12:00:00')
            )   t1
        left join
            (select
                room_id
                ,teacher_id
                ,from_unixtime(start_time) as start_time1
                ,'1v4new' as class_type
            from bi.classroom_his
            where partition_key = date_format(@stat_date, '%Y%m%d')
            )   t2
        on  t1.room_id = t2.room_id
        where t1.teacher_id <> t2.teacher_id
        and t1.teacher_id <> 0
        and t2.teacher_id <> 0
        )   a1
    left join
        newuuabc.teacher_user_new a2
    on  a1.teacher_id_previous = a2.id
    left join
        newuuabc.teacher_user_new a3
    on  a1.teacher_id_current = a3.id
    ;
end
//

delimiter ;



```

**备注**

