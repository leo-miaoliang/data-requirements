# 班主任所属学生名单及车次情况


**需求来源**

提出人: 王艺霏 <yifei.wang@uuabc.com>

部门:

**拉取周期**



**用途**


**详细**

```
【学生ID】【学生姓名】【手机号码】【所属顾问】【所属督导】【是否付费】【剩余课时】【是否上车】

注明： 1. 只需求1-4班主任名下所属学生名单。1-4班主任为：褚贻敏  李许多 林敏 陈佳静  和涛  施雪娇  吕妍科  葛志远  张雯娜  程显梅  张娇娇
          2. 剩余课时为学生账户中的剩余课时，学生查询中的剩余课时不准确（下图）
```

**SQL**

```sql
select
    t1.truename as '所属督导'
    ,t5.truename as '所属顾问'
    ,t2.id as '学生id'
    ,t2.name as '学生姓名'
    ,t2.phone as '手机号码'
    ,case when t2.type = 2 then '是' else '否' end as '是否付费'
    ,coalesce(t3.school_hour, 0) as '剩余课时'
    ,case when t4.student_id is not null then '是' else '否' end as '是否上车'
from
    (select
        masterid
        ,truename
    from newuuabc.admin
    where truename like '%储贻敏%'  --
    or truename like '%李许多%'  --
    or truename like '%林敏%'  --
    or truename like '%陈佳静%'  --
    or truename like '%和涛%'  --
    or truename like '%施雪娇%'  --
    or truename like '%吕研科%'  --
    or truename like '%葛志远%'  --
    or truename like '%张雯娜%'  --
    or truename like '%程显梅%'  --
    or truename like '%张娇娇%'  --
    )   t1
left join
    newuuabc.student_user   t2
on  t1.masterid = t2.assign_teacher
left join
    (select
        student_id
        ,sum(school_hour) as school_hour
    from newuuabc.school_hour
    group by student_id
    )   t3
on  t2.id = t3.student_id
left join
    (select
        c2.student_id
        ,c2.train_id
    from classschedule.train c1
    inner join
        (select
            train_id
            ,student_id
            ,sum(case when status = 1 then 1 else 0 end) as cnt1
            ,sum(case when status = 2 then 1 else 0 end) as cnt2
        from classbooking.passenger
        group by train_id, student_id
        )   c2
    on  c1.train_id = c2.train_id
    and c2.cnt2 = 0
    where coalesce(c1.finish_date, 0) = 0
    )   t4
on  t2.id = t4.student_id
left join
    newuuabc.admin  t5
on  t2.assign_consultant = t5.masterid
;
```

**备注**

