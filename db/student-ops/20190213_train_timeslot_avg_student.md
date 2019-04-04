# 1.5系统开课情况


**需求来源**

提出人: 徐林君<linjun.xu@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**
2.0系统春季班选课，排班需要参考学生历年在校开学时段（非寒暑假）内自由选课的时间分布，

参考数据来源：1.5系统开课情况。

时间范围：2018年9月3日（星期一）——2018年11月25日（星期日）


**SQL**

```sql
select
    t2.time1
    ,t2.train_name
    ,sum(case when t2.weekday1 = 2 then t2.avg_student_cnt else 0 end) as student_day1
    ,sum(case when t2.weekday1 = 3 then t2.avg_student_cnt else 0 end) as student_day2
    ,sum(case when t2.weekday1 = 4 then t2.avg_student_cnt else 0 end) as student_day3
    ,sum(case when t2.weekday1 = 5 then t2.avg_student_cnt else 0 end) as student_day4
    ,sum(case when t2.weekday1 = 6 then t2.avg_student_cnt else 0 end) as student_day5
    ,sum(case when t2.weekday1 = 7 then t2.avg_student_cnt else 0 end) as student_day6
    ,sum(case when t2.weekday1 = 1 then t2.avg_student_cnt else 0 end) as student_day7
from
    (select
        t1.time1
        ,t1.weekday1
        ,t1.train_name
        ,count(distinct t1.date1) as date_cnt
        ,count(1) as student_cnt
        ,round(count(1) / count(distinct t1.date1), 2) as avg_student_cnt
    from
        (select
            date(from_unixtime(t1.start_time)) as date1
            ,dayofweek(date(from_unixtime(t1.start_time))) as weekday1
            ,date_format(from_unixtime(t1.start_time), '%H:%i') as time1
            ,t1.student_id
            ,t1.room_id
            ,t1.train_id
            ,t2.name as train_name
        from classbooking.student_class t1
        inner join
            classschedule.train t2
        on  t1.train_id = t2.train_id
        and t2.name in ('语言基础课KA', '语言基础课KB', '语言基础课JA', '语言基础课JB', '语言基础课PC')
        where date(from_unixtime(t1.start_time)) between '2018-09-03' and '2018-11-25'
        and t1.room_id is not null
        and date_format(from_unixtime(t1.start_time), '%H:%i') between '10:15' and '20:45'
        and t1.status = 3
        )   t1
    group by t1.time1, t1.weekday1, t1.train_name
    )   t2
group by t2.time1, t2.train_name
;
```

**备注**

