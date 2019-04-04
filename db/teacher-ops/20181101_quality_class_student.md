# 最新各语言课车次上的学生名单


**需求来源**

提出人: 王艺霏<yifei.wang@uuabc.com>

部门:

**拉取周期**

2018-11-01

**用途**


**详细**

```
由于四季切齐，1v4班主任团队需求最新各语言课车次上的学生名单，需BI支持。所需维度如下：
【车次ID】【车次名称】【学生ID】【学生姓名】【联系方式】【是否付费】【剩余课时数】【所属顾问】【所属班主任】
注：
【车次ID】【车次名称】：所有语言课车次且状态为确认发车状态
                                      （所有语言课车次ID为67 68 69 70 71 66 57 58 59 60 61 62 43 44 45 46 33 34 35 36  28 29 30 ）
【是否付费】：学生购买小班课合同，且付费金额大于0
【剩余课时数】：1v4课时剩余数(不包括直播等其他课时）
```

**SQL**

```sql
select
    t1.train_id as '车次id'
    ,t1.name as '车次名称'
    ,t2.student_id as '学生id'
    ,t3.name as '学生姓名'
    ,t3.phone as '联系方式'
    -- ,case when t3.type = 1 then '未付费' when t3.type = 2 then '已付费' else '' end as '是否付费1'
    ,case when t7.student_id is not null then '已付费' else '未付费' end as '是否付费'
    ,t4.cnt as '剩余课时数'
    ,t3.assign_consultant as '所属顾问id'
    ,t5.truename as '所属顾问姓名'
    ,t3.assign_teacher as '所属班主任id'
    ,t6.truename as '所属班主任姓名'
from
    (select
        train_id
        ,name
        ,status
        ,start_date
        ,finish_date
    from classschedule.train
    where train_id in (67,68,69,70,71,66,57,58,59,60,61,62,43,44,45,46,33,34,35,36,28,29,30)
    )   t1
left join  -- 取当前在车上的学员
    (select
        train_id
        ,student_id
        ,status
        ,on_time
        ,off_time
    from classbooking.passenger
    where status = 1
    -- and off_time is null
    )   t2
on  t1.train_id = t2.train_id
inner join
    newuuabc.student_user   t3
on  t2.student_id = t3.id
and t3.flag = 1
and t3.disable = 0
left join
    (select
        student_id
        ,sum(school_hour) as cnt
    from newuuabc.school_hour
    where subject_id in (7, 8)
    group by student_id
    )   t4
on  t2.student_id = t4.student_id
left join
    newuuabc.admin  t5
on  t3.assign_consultant = t5.masterid
left join
    newuuabc.admin  t6
on  t3.assign_teacher = t6.masterid
left join
    (select distinct
        t1.student_id
    from newuuabc.contract t1
    inner join
        newuuabc.contract_details t2
    on  t1.id = t2.contract_id
    and t2.subject_id = 7  -- 1对4外教主课
    and t2.total > 0
    inner join
        newuuabc.contract_payment t3
    on  t1.id = t3.contract_id
    and t3.is_success = 2
    and t3.total_fee > 0
    where t1.status in (3, 4)
    and t1.is_del = 1
    )   t7
on  t3.id = t7.student_id
;
```

**备注**

