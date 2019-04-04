# 1v1 付费学员销售合同


**需求来源**

提出人: 胡新星 <xinxing.hu@uuabc.com>

部门:

**拉取周期**

临时

**用途**


**详细**

```
运营部门需要分析1-1付费学员上课有效期数据，需要以下数据维度：
拉取对象：所有1对1销售合同付费学员（付费后还未开课+开课中）
数据维度：
【学生ID】
【学生姓名】
【班主任】
【顾问】
【学生购买合同】：1-1销售合同，一般为尝鲜包、畅学包、精英包、学霸包
【合同起始时间】
【合同终止时间】
【正式课合同购买课时】
【正式课合同赠送课时】
【正式课剩余课时】
```

**SQL**

```sql
DROP TABLE tmp_contract;

CREATE TEMPORARY TABLE tmp_contract (
	SELECT c.id , c.student_id, c.start_time
		, ct.name, ct.contract_type, ct.deadline
		, DATE_ADD(FROM_UNIXTIME(c.start_time), INTERVAL ct.deadline MONTH) AS deadline_time
		, cd.total
		, cd.free_total
		, cd.remain
	FROM newuuabc.contract AS c
		INNER JOIN newuuabc.contract_template AS ct
			ON c.template_id = ct.id
		INNER JOIN (
			SELECT contract_id, SUM(total) AS total, SUM(free_total) AS free_total
				, SUM(remain + `free`) AS remain
			FROM newuuabc.contract_details 
			WHERE subject_id IN (1, 2) AND (total + free_total) > 0
			GROUP BY contract_id 
		) AS cd
			ON c.id = cd.contract_id
	WHERE c.status IN (3, 4)
		AND ct.is_del = 1
		AND ct.contract_type = 1
);

SELECT tc.student_id AS `学生ID`
	, su.name AS `学生姓名`
	, tc.name AS `学生购买合同`
	, a2.truename AS `班主任`
	, a1.truename AS `顾问`
	, FROM_UNIXTIME(tc.start_time) AS `合同起始时间`
	, tc.deadline_time AS `合同终止时间`
	, tc.total AS `正式课合同购买课时`
	, tc.free_total AS `正式课合同赠送课时`
	, tc.remain AS `正式课合同剩余课时`
	, sh.school_hour AS `1v1总剩余课时`
FROM tmp_contract AS tc
	INNER JOIN newuuabc.student_user AS su
		ON tc.student_id = su.id
	LEFT JOIN newuuabc.school_hour AS sh
		ON tc.student_id = sh.student_id
			AND sh.subject_id IN (1, 2)
	LEFT JOIN newuuabc.admin AS a1
		ON su.assign_consultant = a1.masterid
	LEFT JOIN newuuabc.admin AS a2
		ON su.assign_teacher = a2.masterid
WHERE su.flag = 1
ORDER BY tc.student_id, tc.start_time;
```

**备注**

