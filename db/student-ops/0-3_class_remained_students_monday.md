# 剩余 0-3 课时小班课学员名单数据拉取


**需求来源**

提出人: 霍崇崇 <chongchong.huo@uuabc.com>

部门:

**拉取周期**

每周一

**用途**


**详细**

```
为了确定小班课剩余课时0-3课时学员后续的学习政策和相关沟通，需要您帮忙拉取该部分学员的名单，具体信息如下，
课程类型：1对4小班课
时间段：6月11日 - 8月15日
小班课课时剩余：0-3节
拉取维度：【上车批次】【学员姓名】【学员电话】【对应督导】【对应顾问】【顾问对应主管团队】【类型-付费/未付费】【剩余小班课课时】
   【已消耗小班课课时】【小班课课程合同有效期】【渠道-至慧学堂/市场】
```

**SQL**

```sql
DROP TABLE tmp_contract;

CREATE TEMPORARY TABLE tmp_contract (
	SELECT c.id , c.student_id, c.start_time
		, ct.name, ct.contract_type, ct.deadline
		, DATE_ADD(FROM_UNIXTIME(c.start_time), INTERVAL ct.deadline MONTH) AS deadline_time
	FROM newuuabc.contract AS c
		INNER JOIN newuuabc.contract_template AS ct
			on c.template_id = ct.id
	WHERE c.status IN (3, 4)
		AND ct.is_del = 1
		AND c.id IN (SELECT contract_id FROM newuuabc.contract_details WHERE subject_id IN (7, 8) AND (total + free_total) > 0)
)


SELECT su.id AS `学员ID`
	, su.name AS `学员姓名`
	, su.phone AS `学员电话`
	, su.assign_teacher AS `督导ID`
	, a1.truename AS `督导姓名` 
	, su.assign_consultant AS `顾问ID`
	, a2.truename AS `顾问姓名`
	, d.depart_name AS `顾问团队`
	, CASE WHEN su.`type` = 2 THEN '付费' ELSE '未付费' END AS `类型`
	, sh.school_hour AS `剩余小班课课时`
	, sh.used AS `已消耗小班课课时`
	, GROUP_CONCAT(t.train_id SEPARATOR ' / ') AS `车次ID`
	, GROUP_CONCAT(course_name SEPARATOR ' / ') AS `课程分类`
	, GROUP_CONCAT(DATE_FORMAT(FROM_UNIXTIME(t.start_date), "%Y-%m-%d") SEPARATOR ' / ') AS `发车时间`
	, GROUP_CONCAT(DISTINCT c.deadline_time SEPARATOR ' / ') AS `小班课课程合同有效期`
	, bi.GET_CHANNEL_BY_LEVEL(cl.id, 2) AS `渠道`
-- 	, cl.channel_name AS `渠道`
FROM newuuabc.student_user AS su
	INNER JOIN newuuabc.school_hour AS sh
		ON su.id = sh.student_id AND sh.subject_id = 7
	LEFT JOIN newuuabc.admin AS a1
		ON su.assign_teacher = a1.masterid
	LEFT JOIN newuuabc.admin AS a2
		ON su.assign_consultant = a2.masterid
	LEFT JOIN newuuabc.department AS d
		ON a2.dept = d.id
	LEFT JOIN newuuabc.channel_list AS cl
		ON su.channel = cl.id
	LEFT JOIN tmp_contract AS c
		ON su.id = c.student_id
	LEFT JOIN classbooking.passenger AS p
		ON su.id = p.student_id
	LEFT JOIN classschedule.train AS t
		ON p.train_id = t.train_id
	LEFT JOIN newuuabc.course_type AS ct
		ON t.lesson_category = ct.id
WHERE sh.school_hour < 4
 	AND p.on_time BETWEEN UNIX_TIMESTAMP('2018-06-11') AND UNIX_TIMESTAMP('2018-08-20')
 	AND p.off_time IS NULL
GROUP BY su.id, c.id
ORDER BY su.id
```

**备注**

