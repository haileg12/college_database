CREATE DATABASE IF NOT EXISTS college_statistics;

-- Colleges table (central entity)
CREATE TABLE IF NOT EXISTS colleges (
    college_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    UNIQUE KEY (name, state)
);

-- Tuition information
CREATE TABLE IF NOT EXISTS tuition_info (
    college_id INT PRIMARY KEY,
    institution_type VARCHAR(100) NOT NULL,
    degree_length VARCHAR(50) NOT NULL,
    in_state_tuition INT NOT NULL,
    in_state_total INT NOT NULL,
    out_of_state_tuition INT NOT NULL,
    out_of_state_total INT NOT NULL,
    FOREIGN KEY (college_id) REFERENCES colleges(college_id)
);

-- Diversity statistics
CREATE TABLE IF NOT EXISTS diversity_stats (
    college_id INT PRIMARY KEY,
    total_enrollment INT NOT NULL,
    women INT NOT NULL,
    americanIndian_alaskaNative INT NOT NULL,
    asian INT NOT NULL,
    black INT NOT NULL,
    hispanic INT NOT NULL,
    hawaiianNative_pacificIslander INT NOT NULL,
    white INT NOT NULL,
    twoPlus INT NOT NULL,
    unknown_race INT NOT NULL,
    nonResident_foreign INT NOT NULL,
    total_minority INT NOT NULL,
    FOREIGN KEY (college_id) REFERENCES colleges(college_id)
);

-- Salary potential
CREATE TABLE IF NOT EXISTS salary_potential (
    college_id INT PRIMARY KEY,
    early_career_pay INT NOT NULL,
    mid_career_pay INT NOT NULL,
    stem_percent INT NOT NULL,
    FOREIGN KEY (college_id) REFERENCES colleges(college_id)
);




-- 1. Colleges and their Tuition Information
-- Insight: Basic overview of tuition costs by college across states.
-- Query Type: Joins across multiple tables
SELECT c.name, c.state, t.in_state_tuition, t.out_of_state_tuition
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id;

-- 2. Colleges and their Diversity Statistics
-- Insight: Identifies colleges with high or low minority enrollment rates.
-- Query Type: Joins across multiple tables
SELECT c.name, d.total_enrollment, d.total_minority
FROM colleges c
JOIN diversity_stats d ON c.college_id = d.college_id;

-- 3. Colleges and Salary Potential
-- Insight: Highlights colleges offering strong career earnings potential.
-- Query Type: Joins across multiple tables
SELECT c.name, s.early_career_pay, s.mid_career_pay
FROM colleges c
JOIN salary_potential s ON c.college_id = s.college_id;

-- 4. Highest Mid-Career Salaries
-- Insight: Find top 10 colleges producing high-earning alumni later in their careers.
-- Query Type: Joins across multiple tables, Aggregations (ordering)
SELECT c.name, s.mid_career_pay
FROM colleges c
JOIN salary_potential s ON c.college_id = s.college_id
ORDER BY s.mid_career_pay DESC
LIMIT 10;

-- 5. Create a View: College Summary
-- Note: The college_summary view simplifies repeated salary and tuition analysis.
-- Query Type: View creation for simplified analysis
CREATE OR REPLACE VIEW college_summary AS
SELECT 
    c.name,
    c.state,
    t.institution_type,
    t.degree_length,
    t.in_state_tuition,
    t.out_of_state_tuition,
    s.early_career_pay,
    s.mid_career_pay,
    s.stem_percent
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id
JOIN salary_potential s ON c.college_id = s.college_id;

-- 6. Colleges with Lowest In-State Tuition (Using View)
-- Insight: Lists the most affordable colleges for in-state students.
-- Query Type: View usage, Aggregations (ordering)
SELECT name, state, in_state_tuition
FROM college_summary
ORDER BY in_state_tuition ASC
LIMIT 10;

-- 7. Colleges with Highest Early Career Pay (Using View)
-- Insight: Highlights colleges providing the best starting salaries.
-- Query Type: View usage, Aggregations (ordering)
SELECT name, early_career_pay
FROM college_summary
ORDER BY early_career_pay DESC
LIMIT 10;

-- 8. Colleges with Highest STEM Graduate Percentage (Using View)
-- Insight: Find colleges specializing in STEM fields.
-- Query Type: View usage, Aggregations (ordering)
SELECT name, stem_percent
FROM college_summary
ORDER BY stem_percent DESC
LIMIT 10;

-- 9. 2-Year Colleges with High Mid-Career Earnings (Using View)
-- Insight: Identifies strong career payoff for shorter degree programs.
-- Query Type: View usage, Aggregations (filtering and ordering)
SELECT name, mid_career_pay
FROM college_summary
WHERE degree_length = '2 Years'
ORDER BY mid_career_pay DESC
LIMIT 10;

-- 10. Average Tuition by State
-- Insight: Understands tuition differences across states.
-- Query Type: Joins across multiple tables, Aggregations (grouping, ordering)
SELECT c.state,
       AVG(t.in_state_tuition) AS avg_in_state,
       AVG(t.out_of_state_tuition) AS avg_out_state
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id
GROUP BY c.state
ORDER BY avg_out_state DESC;

-- 11. Average Early Career Pay by Institution Type
-- Insight: Compare public vs private institution career outcomes.
-- Query Type: Joins across multiple tables, Aggregations (grouping, ordering)
SELECT t.institution_type, AVG(s.early_career_pay) AS avg_early_pay
FROM tuition_info t
JOIN salary_potential s ON t.college_id = s.college_id
GROUP BY t.institution_type
ORDER BY avg_early_pay DESC;

-- 12. States with Highest Average Minority Enrollment
-- Insight: Identify states supporting diverse college environments.
-- Query Type: Joins across multiple tables, Aggregations (grouping, ordering)
SELECT c.state, AVG(d.total_minority) AS avg_minority_percent
FROM colleges c
JOIN diversity_stats d ON c.college_id = d.college_id
GROUP BY c.state
ORDER BY avg_minority_percent DESC
LIMIT 5;

-- 13. Colleges with Above-Average Early Career Pay
-- Insight: Focus on schools that beat the national early career average.
-- Query Type: Joins across multiple tables, Subquery
SELECT c.name, s.early_career_pay
FROM colleges c
JOIN salary_potential s ON c.college_id = s.college_id
WHERE s.early_career_pay > (SELECT AVG(early_career_pay) FROM salary_potential);

-- 14. Colleges with Above-Average Minority Enrollment
-- Insight: Highlights colleges excelling in minority student representation.
-- Query Type: Joins across multiple tables, Subquery
SELECT c.name, d.total_minority
FROM colleges c
JOIN diversity_stats d ON c.college_id = d.college_id
WHERE d.total_minority > (SELECT AVG(total_minority) FROM diversity_stats);

-- 15. Colleges with Largest Pay Growth (Mid vs Early Career)
-- Insight: Where your long-term income grows the most after graduating.
-- Query Type: Joins across multiple tables, Aggregations (ordering)
SELECT c.name, (s.mid_career_pay - s.early_career_pay) AS pay_growth
FROM colleges c
JOIN salary_potential s ON c.college_id = s.college_id
ORDER BY pay_growth DESC
LIMIT 10;

-- 16. Public Colleges with Highest Diversity
-- Insight: Best public colleges for diversity.
-- Query Type: Joins across multiple tables, Aggregations (filtering, ordering)
SELECT c.name, d.total_minority
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id
JOIN diversity_stats d ON c.college_id = d.college_id
WHERE t.institution_type LIKE '%Public%'
ORDER BY d.total_minority DESC
LIMIT 10;

-- 17. Private Colleges with Lowest Total Cost
-- Insight: Affordable private institutions.
-- Query Type: Joins across multiple tables, Aggregations (filtering, ordering)
SELECT c.name, t.in_state_total
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id
WHERE t.institution_type LIKE '%Private%'
ORDER BY t.in_state_total ASC
LIMIT 10;

-- 18. Colleges Where Women Enrollment is Below 50%
-- Insight: Gender imbalance insight.
-- Query Type: Joins across multiple tables, Aggregations (filtering)
SELECT c.name, d.women
FROM colleges c
JOIN diversity_stats d ON c.college_id = d.college_id
WHERE d.women < 50;

-- 19. Large Colleges (20,000+ Enrollment) and Average Mid-Career Pay
-- Insight: See if bigger colleges correlate with higher mid-career earnings.
-- Query Type: Joins across multiple tables, Aggregations (filtering, aggregation)
SELECT AVG(s.mid_career_pay) AS avg_mid_pay_large_colleges
FROM colleges c
JOIN salary_potential s ON c.college_id = s.college_id
JOIN diversity_stats d ON c.college_id = d.college_id
WHERE d.total_enrollment > 20000;

-- 20. Colleges with Tuition Lower Than State Average
-- Insight: Colleges that are cheaper than their state’s average cost for their institution type.
-- Query Type: Joins across multiple tables, Subquery, Aggregations (ordering)
SELECT c.name, c.state, t.in_state_tuition
FROM colleges c
JOIN tuition_info t ON c.college_id = t.college_id
WHERE t.in_state_tuition < (
  SELECT AVG(t2.in_state_tuition)
  FROM tuition_info t2
  WHERE t2.institution_type = t.institution_type
)
ORDER BY c.state;
