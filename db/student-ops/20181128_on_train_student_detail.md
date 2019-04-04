# 车次上最新学员数据明细


**需求来源**

提出人: 王艺霏<yifei.wang@uuabc.com>;

部门:

**拉取周期**

临时

**用途**
由于1.5系统部分车次即将结课，将对学生进行合并车次处理，需BI支持车次上最新学员数据明细。

**详细**

```
      所需名单维度：【车次ID】【车次名称】【学生ID】【学生姓名】【联系方式】【是否付费】【剩余课时】【所属顾问】【所属班主任】

注 ：【车次ID】：  目前所需拉取学生名单的车次ID为28 29 30 43 44 45 46 57 58 59 60 61 62；
       【是否付费】：付费指该生合同为销售合同，且支付金额大于0；
       【剩余课时】：指1v4小班课剩余课时，不包含直播课课时/1v1课时；
```

**SQL**

```sql
select
    t1.train_id as '车次ID'
    ,coalesce(t2.name, '') as '车次名称'
    ,t1.student_id as '学生ID'
    ,coalesce(t3.name, '') as '学生姓名'
    ,coalesce(t3.phone, '') as '联系方式'
    ,case when t7.student_id is not null then 1 else 0 end as '是否付费'
    ,coalesce(t6.remain, 0) as '剩余课时'
    ,coalesce(t4.truename, '') as '所属顾问'
    ,coalesce(t5.truename, '') as '所属班主任'
from
    (select
        train_id
        ,student_id
        ,from_unixtime(on_time) as on_time
        ,from_unixtime(off_time) as off_time
        ,status
        ,on_train_period
        ,off_train_period
    from classbooking.passenger
    where train_id in (28, 29, 30, 43, 44, 45, 46, 57, 58, 59, 60, 61, 62)
    and status = 1
    )   t1
left join
    classschedule.train t2
on  t1.train_id = t2.train_id
left join
    newuuabc.student_user t3
on  t1.student_id = t3.id
left join
    newuuabc.admin t4
on  t3.assign_consultant = t4.masterid
left join
    newuuabc.admin t5
on  t3.assign_teacher = t5.masterid
left join
    (select
        student_id
        ,sum(school_hour) as remain
    from newuuabc.school_hour
    where subject_id in (7, 8)
    group by student_id
    )   t6
on  t3.id = t6.student_id
left join
    (select distinct
        student_id
    from newuuabc.contract
    where contract_type = 1
    and status = 4
    and is_del = 1
    and contract_amount > 0
    )   t7
on  t3.id = t7.student_id
;
```

**备注**

