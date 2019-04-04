# 所有付费学员剩余课时数据


**需求来源**

提出人: 王艺霏<yifei.wang@uuabc.com>;

部门:

**拉取周期**

临时

**用途**


**详细**

```
所需数据维度：【学生ID】【学生姓名】【总课时数】【已使用课时数】【剩余课时数】【所属顾问】【所属班主任】
注释：【剩余课时】为学生1v4小班课剩余课时，不包含1v1课时和直播课课时。
```

**SQL**

```sql
select
    t1.id
    ,t1.name
    ,coalesce(t2.total, 0) as total
    ,coalesce(t2.used, 0) as used
    ,coalesce(t2.total, 0) - coalesce(t2.used, 0) as remain
    ,coalesce(t3.truename, '') as consultant_name
    ,coalesce(t4.truename, '') as teacher_name
from newuuabc.student_user t1
left join
    (select
        student_id
        ,sum(total) as total
        ,sum(used) as used
    from newuuabc.school_hour
    where subject_id in (7, 8)
    group by student_id
    )   t2
on  t1.id = t2.student_id
left join
    newuuabc.admin t3
on  t1.assign_consultant = t3.masterid
left join
    newuuabc.admin t4
on  t1.assign_teacher = t4.masterid
where t1.flag = 1
and t1.disable = 0
and t1.`type` = 2
;
```

**备注**

