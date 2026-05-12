create database ipl_project;

use ipl_project;
select * from ball_by_ball;

-- Bowlers who have bowled most deliveries
SELECT 
    b.Player_Name,
    c.Country_Name,
    d.Bowling_skill,
    COUNT(*) AS Deliveries
FROM Ball_by_Ball a
JOIN Player b
    ON a.Bowler = b.Player_Id
JOIN Country c
    ON b.Country_Name = c.Country_Id
JOIN Bowling_Style d
    ON b.Bowling_skill = d.Bowling_Id
GROUP BY 
    b.Player_Name,
    c.Country_Name,
    d.Bowling_skill
ORDER BY Deliveries DESC;

#Highest Wicket takers in IPL
-- Runout, Retired hurt and Obstructing field are not counted as bowlers wicket
SELECT 
    c.Player_Name,
    COUNT(a.Kind_Out) AS Wickets,

    SUM(CASE WHEN a.Kind_Out = 1 THEN 1 ELSE 0 END) AS caught,
    SUM(CASE WHEN a.Kind_Out = 2 THEN 1 ELSE 0 END) AS bowled,
    SUM(CASE WHEN a.Kind_Out = 4 THEN 1 ELSE 0 END) AS lbw,
    SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumped

FROM Wicket_Taken a

JOIN Ball_by_Ball b
    ON a.Match_Id = b.Match_Id 
    AND a.Innings_No = b.Innings_No
    AND a.Over_Id = b.Over_Id 
    AND a.Ball_Id = b.Ball_Id

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Bowling_skill
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Bowling_Style c
        ON a.Bowling_skill = c.Bowling_Id
) c
ON b.Bowler = c.Player_Id

WHERE a.Kind_Out IN (1, 2, 4, 6, 7, 8)

GROUP BY 
    c.Player_Id,
    c.Player_Name

ORDER BY Wickets DESC; 

-- Highest wicket Talen By the bowler in an ipl matches
SELECT 
    c.Player_Name,
    c.Country_Name,
    c.Bowling_skill,
    CONCAT(a.Wickets, '-', b.runs) AS Best

FROM (
    SELECT 
        a.Bowler,
        a.Match_Id,
        COUNT(b.Kind_Out) AS Wickets
    FROM Ball_by_Ball a
    JOIN Wicket_Taken b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id
    WHERE b.Kind_Out IN (1, 2, 4, 6, 7, 8)
    GROUP BY a.Bowler, a.Match_Id
) a

JOIN (
    SELECT 
        a.Bowler,
        a.Match_Id,
        SUM(
            COALESCE(b.Runs_Scored, 0) + 
            COALESCE(c.Extra_Runs, 0)
        ) AS runs
    FROM Ball_by_Ball a
    LEFT JOIN Batsman_Scored b 
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id
    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id 
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id 
        AND a.Ball_Id = c.Ball_Id
    GROUP BY a.Bowler, a.Match_Id
) b
    ON a.Bowler = b.Bowler
    AND a.Match_Id = b.Match_Id

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Bowling_skill
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Bowling_Style c
        ON a.Bowling_skill = c.Bowling_Id
) c
    ON a.Bowler = c.Player_Id

ORDER BY a.Wickets DESC;

--  No of 5-wicket hauls by bowlers in an IPL 
SELECT 
    t.Player_Name,
    t.Country_Name,
    t.Bowling_skill,
    COUNT(*) AS hauls

FROM (
    SELECT 
        c.Player_Id,
        c.Player_Name,
        c.Country_Name,
        c.Bowling_skill,
        COUNT(a.Kind_Out) AS Wickets

    FROM Wicket_Taken a

    JOIN Ball_by_Ball b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    JOIN (
        SELECT 
            a.Player_Id,
            a.Player_Name,
            b.Country_Name,
            c.Bowling_skill
        FROM Player a
        JOIN Country b
            ON a.Country_Name = b.Country_Id
        JOIN Bowling_Style c
            ON a.Bowling_skill = c.Bowling_Id
    ) c
        ON b.Bowler = c.Player_Id

    WHERE a.Kind_Out IN (1, 2, 4, 6, 7, 8)

    GROUP BY 
        c.Player_Id,
        c.Player_Name,
        c.Country_Name,
        c.Bowling_skill,
        a.Match_Id

    HAVING Wickets >= 5
) t

GROUP BY 
    t.Player_Id,
    t.Player_Name,
    t.Country_Name,
    t.Bowling_skill

ORDER BY hauls DESC;

-- Most Runs Conceded by a Bowler in an IPL Match
SELECT 
    b.Player_Name,
    b.Country_Name,
    b.Bowling_skill,
    a.runs

FROM (
    SELECT 
        a.Bowler,
        a.Match_Id,
        SUM(
            COALESCE(b.Runs_Scored, 0) + 
            COALESCE(c.Extra_Runs, 0)
        ) AS runs

    FROM Ball_by_Ball a

    LEFT JOIN Batsman_Scored b 
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id 
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id 
        AND a.Ball_Id = c.Ball_Id

    GROUP BY 
        a.Bowler,
        a.Match_Id
) a

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Bowling_skill
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Bowling_Style c
        ON a.Bowling_skill = c.Bowling_Id
) b
    ON a.Bowler = b.Player_Id

ORDER BY a.runs DESC;

-- # Highest Runs Concede in an IPL over by a bowler
SELECT 
    c.Player_Name AS Bowler,
    MAX(a.runs + b.Extra) AS Runs,
    a.Fours,
    a.Sixes,
    b.Extra,
    b.wides,
    b.noballs,
    b.legbyes

FROM (
    SELECT 
        Match_Id,
        Innings_No,
        Over_Id,
        SUM(Runs_Scored) AS runs,
        SUM(CASE WHEN Runs_Scored = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN Runs_Scored = 6 THEN 1 ELSE 0 END) AS Sixes
    FROM Batsman_Scored
    GROUP BY Match_Id, Innings_No, Over_Id
) a

JOIN (
    SELECT 
        Match_Id,
        Innings_No,
        Over_Id,
        SUM(Extra_Runs) AS Extra,
        SUM(CASE WHEN Extra_Type_Id = 1 THEN 1 ELSE 0 END) AS legbyes,
        SUM(CASE WHEN Extra_Type_Id = 2 THEN 1 ELSE 0 END) AS wides,
        SUM(CASE WHEN Extra_Type_Id = 4 THEN 1 ELSE 0 END) AS noballs
    FROM Extra_Runs
    GROUP BY Match_Id, Innings_No, Over_Id
) b
    ON a.Match_Id = b.Match_Id 
    AND a.Innings_No = b.Innings_No
    AND a.Over_Id = b.Over_Id

JOIN (
    SELECT 
        a.Match_Id,
        a.Innings_No,
        a.Over_Id,
        b.Player_Name,
        c.Bowling_skill,
        d.Country_Name
    FROM Ball_by_Ball a
    JOIN Player b
        ON a.Bowler = b.Player_Id
    JOIN Bowling_Style c
        ON b.Bowling_skill = c.Bowling_Id
    JOIN Country d
        ON b.Country_Name = d.Country_Id
    GROUP BY 
        a.Match_Id,
        a.Innings_No,
        a.Over_Id,
        b.Player_Name,
        c.Bowling_skill,
        d.Country_Name
) c
    ON a.Match_Id = c.Match_Id 
    AND a.Innings_No = c.Innings_No
    AND a.Over_Id = c.Over_Id

GROUP BY 
    c.Player_Name,
    a.Fours,
    a.Sixes,
    b.Extra,
    b.wides,
    b.noballs,
    b.legbyes

ORDER BY Runs DESC;

--  best economy bowler's in IPL
SELECT 
    b.Player_Name,
    b.Country_Name,
    a.overs,
    a.runs,
    a.extras,
    a.economy

FROM (
    SELECT 
        b.Bowler,

        SUM(COALESCE(c.Extra_Runs, 0) + a.Runs_Scored) AS runs,
        SUM(COALESCE(c.Extra_Runs, 0)) AS extras,

        COUNT(*) / 6 AS overs,

        ROUND(
            SUM(COALESCE(c.Extra_Runs, 0) + a.Runs_Scored) 
            / NULLIF(COUNT(*) / 6, 0),
        2) AS economy

    FROM Batsman_Scored a

    JOIN Ball_by_Ball b
        ON a.Match_Id = b.Match_Id
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id
        AND a.Ball_Id = b.Ball_Id

    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id
        AND a.Ball_Id = c.Ball_Id

    GROUP BY b.Bowler

    HAVING COUNT(*) / 6 >= 50   -- instead of alias 'overs'

) a

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Bowling_skill,
        c.Country_Name
    FROM Player a
    JOIN Bowling_Style b
        ON a.Bowling_skill = b.Bowling_Id
    JOIN Country c
        ON a.Country_Name = c.Country_Id
) b
    ON a.Bowler = b.Player_Id

ORDER BY a.economy ASC;


-- Worst Economy Bowlers
SELECT 
    b.Player_Name,
    b.Country_Name,
    a.overs,
    a.runs,
    a.extras,
    a.economy

FROM (
    SELECT 
        b.Bowler,

        SUM(COALESCE(c.Extra_Runs, 0) + a.Runs_Scored) AS runs,
        SUM(COALESCE(c.Extra_Runs, 0)) AS extras,

        COUNT(*) / 6 AS overs,

        ROUND(
            SUM(COALESCE(c.Extra_Runs, 0) + a.Runs_Scored) 
            / NULLIF(COUNT(*) / 6, 0),
        2) AS economy

    FROM Batsman_Scored a

    JOIN Ball_by_Ball b
        ON a.Match_Id = b.Match_Id
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id
        AND a.Ball_Id = b.Ball_Id

    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id
        AND a.Ball_Id = c.Ball_Id

    GROUP BY b.Bowler

    HAVING COUNT(*) / 6 >= 50   -- instead of alias 'overs'

) a

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Bowling_skill,
        c.Country_Name
    FROM Player a
    JOIN Bowling_Style b
        ON a.Bowling_skill = b.Bowling_Id
    JOIN Country c
        ON a.Country_Name = c.Country_Id
) b
    ON a.Bowler = b.Player_Id

ORDER BY a.economy DESC;

-- #Best Death overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an ove
SELECT 
    p.Player_Name,
    c.Country_Name,

    a.Overs,
    a.Runs,
    w.Wickets,
    a.Economy,

    ROUND(w.Wickets / NULLIF(a.Overs, 0), 2) AS Wicket_rate

FROM (
    -- 🔹 Overs + Runs + Economy
    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / COUNT(*), 2) AS Economy

    FROM (
        SELECT 
            a.Bowler,
            a.Match_Id,
            a.Over_Id,

            SUM(
                COALESCE(b.Runs_Scored, 0) + 
                COALESCE(c.Extra_Runs, 0)
            ) AS runs

        FROM Ball_by_Ball a

        LEFT JOIN Batsman_Scored b 
            ON a.Match_Id = b.Match_Id 
            AND a.Innings_No = b.Innings_No
            AND a.Over_Id = b.Over_Id 
            AND a.Ball_Id = b.Ball_Id

        LEFT JOIN Extra_Runs c
            ON a.Match_Id = c.Match_Id 
            AND a.Innings_No = c.Innings_No
            AND a.Over_Id = c.Over_Id 
            AND a.Ball_Id = c.Ball_Id

        WHERE a.Over_Id IN (16,17,18,19,20)

        GROUP BY 
            a.Bowler,
            a.Match_Id,
            a.Over_Id
    ) t

    GROUP BY Bowler
) a

JOIN (
    -- 🔹 Correct Wicket Calculation
    SELECT 
        a.Bowler,
        COUNT(*) AS Wickets
    FROM Ball_by_Ball a

    JOIN Wicket_Taken b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    WHERE 
        a.Over_Id IN (16,17,18,19,20)
        AND b.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY a.Bowler
) w
    ON a.Bowler = w.Bowler

JOIN Player p ON a.Bowler = p.Player_Id
JOIN Country c ON p.Country_Name = c.Country_Id

WHERE a.Overs >= 50

ORDER BY 
    a.Economy ASC,
    Wicket_rate DESC;
    
 -- Poor Death overs Bowler's in Indian Premier League   
 -- reverse the Logics


-- #Best powerplay overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an over
SELECT 
    p.Player_Name,
    c.Country_Name,

    a.Overs,
    a.Runs,
    w.Wickets,
    a.Economy,

    ROUND(w.Wickets / NULLIF(a.Overs, 0), 2) AS Wicket_rate

FROM (
    -- 🔹 Overs + Runs + Economy (Powerplay 1–6 overs)
    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / COUNT(*), 2) AS Economy

    FROM (
        SELECT 
            a.Bowler,
            a.Match_Id,
            a.Over_Id,

            SUM(
                COALESCE(b.Runs_Scored, 0) + 
                COALESCE(c.Extra_Runs, 0)
            ) AS runs

        FROM Ball_by_Ball a

        LEFT JOIN Batsman_Scored b 
            ON a.Match_Id = b.Match_Id 
            AND a.Innings_No = b.Innings_No
            AND a.Over_Id = b.Over_Id 
            AND a.Ball_Id = b.Ball_Id

        LEFT JOIN Extra_Runs c
            ON a.Match_Id = c.Match_Id 
            AND a.Innings_No = c.Innings_No
            AND a.Over_Id = c.Over_Id 
            AND a.Ball_Id = c.Ball_Id

        WHERE a.Over_Id IN (1,2,3,4,5,6)

        GROUP BY 
            a.Bowler,
            a.Match_Id,
            a.Over_Id
    ) t

    GROUP BY Bowler
) a

JOIN (
    -- 🔹 Correct wicket calculation
    SELECT 
        a.Bowler,
        COUNT(*) AS Wickets

    FROM Ball_by_Ball a

    JOIN Wicket_Taken b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    WHERE 
        a.Over_Id IN (1,2,3,4,5,6)
        AND b.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY a.Bowler
) w
    ON a.Bowler = w.Bowler

JOIN Player p ON a.Bowler = p.Player_Id
JOIN Country c ON p.Country_Name = c.Country_Id

WHERE a.Overs >= 50

ORDER BY 
    a.Economy ASC,
    Wicket_rate DESC;

-- #Poor Powerplay overs Bowler's in Indian Premier League 
-- reverse the logfics

-- #Best Middle overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an over
-- wickets priblems
SELECT 
    p.Player_Name,
    c.Country_Name,

    a.Overs,
    a.Runs,
    w.Wickets,
    a.Economy,

    ROUND(w.Wickets / NULLIF(a.Overs, 0), 2) AS Wicket_rate

FROM (

    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / COUNT(*), 2) AS Economy

    FROM (

        SELECT 
            a.Bowler,
            a.Match_Id,
            a.Over_Id,

            SUM(
                COALESCE(b.Runs_Scored, 0) + 
                COALESCE(c.Extra_Runs, 0)
            ) AS runs

        FROM Ball_by_Ball a

        LEFT JOIN Batsman_Scored b 
            ON a.Match_Id = b.Match_Id 
            AND a.Innings_No = b.Innings_No
            AND a.Over_Id = b.Over_Id 
            AND a.Ball_Id = b.Ball_Id

        LEFT JOIN Extra_Runs c
            ON a.Match_Id = c.Match_Id 
            AND a.Innings_No = c.Innings_No
            AND a.Over_Id = c.Over_Id 
            AND a.Ball_Id = c.Ball_Id

        WHERE a.Over_Id IN (7,8,9,10,11,12,13,14,15)

        GROUP BY 
            a.Bowler,
            a.Match_Id,
            a.Over_Id

    ) t

    GROUP BY Bowler

) a

JOIN (

    SELECT 
        a.Bowler,
        COUNT(*) AS Wickets

    FROM Ball_by_Ball a

    JOIN Wicket_Taken b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    WHERE 
        a.Over_Id IN (7,8,9,10,11,12,13,14,15)
        AND b.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY a.Bowler

) w
    ON a.Bowler = w.Bowler

JOIN Player p 
    ON a.Bowler = p.Player_Id

JOIN Country c 
    ON p.Country_Name = c.Country_Id

WHERE a.Overs >= 50

ORDER BY 
    a.Economy ASC,
    Wicket_rate DESC;
    
-- Best Bowler in IPL
-- error in runs
SELECT 
    e.Player_Name,
    e.Country_Name,
    d.Matches,
    a.Runs,
    b.Wickets,
    a.Economy,
    c.Best

FROM (

    -- 🔹 Runs + Economy
    SELECT 
        Bowler,
        SUM(COALESCE(b.Runs_Scored,0) + COALESCE(c.Extra_Runs,0)) AS Runs,
        COUNT(*) / 6 AS Overs,
        ROUND(
            SUM(COALESCE(b.Runs_Scored,0) + COALESCE(c.Extra_Runs,0)) 
            / NULLIF(COUNT(*)/6,0)
        ,2) AS Economy

    FROM Ball_by_Ball a

    LEFT JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id
        AND a.Ball_Id = b.Ball_Id

    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id
        AND a.Ball_Id = c.Ball_Id

    GROUP BY Bowler
    HAVING COUNT(*)/6 >= 50

) a

JOIN (

    -- 🔹 Wickets
    SELECT 
        a.Bowler,
        COUNT(*) AS Wickets

    FROM Ball_by_Ball a

    JOIN Wicket_Taken b
        ON a.Match_Id = b.Match_Id
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id
        AND a.Ball_Id = b.Ball_Id

    WHERE b.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY a.Bowler

) b
    ON a.Bowler = b.Bowler

JOIN (

    -- 🔹 Best performance per bowler
    SELECT 
        t.Bowler,
        MAX(CONCAT(t.Wickets, '-', t.runs)) AS Best

    FROM (

        SELECT 
            a.Bowler,
            a.Match_Id,
            COUNT(b.Kind_Out) AS Wickets,
            SUM(
                COALESCE(c.Runs_Scored,0) + COALESCE(d.Extra_Runs,0)
            ) AS runs

        FROM Ball_by_Ball a

        JOIN Wicket_Taken b
            ON a.Match_Id = b.Match_Id
            AND a.Innings_No = b.Innings_No
            AND a.Over_Id = b.Over_Id
            AND a.Ball_Id = b.Ball_Id

        LEFT JOIN Batsman_Scored c
            ON a.Match_Id = c.Match_Id
            AND a.Innings_No = c.Innings_No
            AND a.Over_Id = c.Over_Id
            AND a.Ball_Id = c.Ball_Id

        LEFT JOIN Extra_Runs d
            ON a.Match_Id = d.Match_Id
            AND a.Innings_No = d.Innings_No
            AND a.Over_Id = d.Over_Id
            AND a.Ball_Id = d.Ball_Id

        GROUP BY a.Bowler, a.Match_Id

    ) t

    GROUP BY t.Bowler

) c
    ON a.Bowler = c.Bowler

JOIN (

    -- 🔹 Matches
    SELECT 
        Bowler,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Bowler

) d
    ON a.Bowler = d.Bowler

JOIN (

    -- 🔹 Player info
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Bowling_skill,
        c.Country_Name
    FROM Player a
    JOIN Bowling_Style b
        ON a.Bowling_skill = b.Bowling_Id
    JOIN Country c
        ON a.Country_Name = c.Country_Id

) e
    ON a.Bowler = e.Player_Id

ORDER BY 
    a.Economy ASC,
    b.Wickets DESC;
    
-- #Worst Bowlers in IPL reverse the logics


-- #Batsmens who have faced most deliveries
SELECT 
    b.Player_Name,
    c.Country_Name,
    d.Batting_hand,
    COUNT(*) AS Deliveries

FROM Ball_by_Ball a

JOIN Player b
    ON a.Striker = b.Player_Id

JOIN Country c
    ON b.Country_Name = c.Country_Id

JOIN Batting_Style d
    ON b.Batting_hand = d.Batting_Id

GROUP BY 
    a.Striker,
    b.Player_Name,
    c.Country_Name,
    d.Batting_hand

ORDER BY Deliveries DESC;

-- # Highest run scored by a batsman in an IPL 
SELECT 
    c.Player_Name,
    c.Country_Name,
    c.Batting_hand,
    SUM(a.Runs_Scored) AS Runs

FROM Batsman_Scored a

JOIN Ball_by_Ball b
    ON a.Match_Id = b.Match_Id 
    AND a.Innings_No = b.Innings_No
    AND a.Over_Id = b.Over_Id 
    AND a.Ball_Id = b.Ball_Id

JOIN (
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Batting_hand
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Batting_Style c
        ON a.Batting_hand = c.Batting_Id
) c
    ON b.Striker = c.Player_Id

GROUP BY 
    c.Player_Id,
    c.Player_Name,
    c.Country_Name,
    c.Batting_hand

ORDER BY Runs DESC;

-- Player who got dismissed at duck(0 score) highest no of times
SELECT 
    p.Player_Name,
    c.Country_Name,
    bs.Batting_hand,
    COUNT(*) AS ducks

FROM (

    SELECT 
        a.Striker,
        a.Match_Id,
        SUM(b.Runs_Scored) AS runs

    FROM Ball_by_Ball a

    JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    GROUP BY 
        a.Striker,
        a.Match_Id

    HAVING SUM(b.Runs_Scored) = 0

) a

JOIN Player p
    ON a.Striker = p.Player_Id

JOIN Country c
    ON p.Country_Name = c.Country_Id

JOIN Batting_Style bs
    ON p.Batting_hand = bs.Batting_Id

GROUP BY 
    p.Player_Id,
    p.Player_Name,
    c.Country_Name,
    bs.Batting_hand

ORDER BY ducks DESC;

-- # Highest run score by a batsman in an IPL match
SELECT 
    p.Player_Name,
    c.Country_Name,
    a.runs AS highest_score,
    a.balls,
    a.dots,
    a.fours,
    a.sixes

FROM (

    SELECT 
        a.Striker,
        a.Match_Id,

        SUM(b.Runs_Scored) AS runs,
        COUNT(*) AS balls,

        SUM(CASE WHEN b.Runs_Scored = 0 THEN 1 ELSE 0 END) AS dots,
        SUM(CASE WHEN b.Runs_Scored = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN b.Runs_Scored = 6 THEN 1 ELSE 0 END) AS sixes

    FROM Ball_by_Ball a

    JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    GROUP BY 
        a.Striker,
        a.Match_Id

) a

JOIN Player p
    ON a.Striker = p.Player_Id

JOIN Country c
    ON p.Country_Name = c.Country_Id

JOIN Batting_Style bs
    ON p.Batting_hand = bs.Batting_Id

ORDER BY a.runs DESC;

-- # No of fifties and centruies by a batsman in an IPL
SELECT 
    p.Player_Name,
    c.Country_Name,

    SUM(CASE WHEN a.runs >= 50 AND a.runs < 100 THEN 1 ELSE 0 END) AS fifties,
    SUM(CASE WHEN a.runs >= 100 THEN 1 ELSE 0 END) AS centuries,
    MAX(a.runs) AS highest_score

FROM (

    SELECT 
        a.Striker,
        a.Match_Id,
        SUM(b.Runs_Scored) AS runs

    FROM Ball_by_Ball a

    JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    GROUP BY 
        a.Striker,
        a.Match_Id

) a

JOIN Player p
    ON a.Striker = p.Player_Id

JOIN Country c
    ON p.Country_Name = c.Country_Id

JOIN Batting_Style bs
    ON p.Batting_hand = bs.Batting_Id

GROUP BY 
    p.Player_Id,
    p.Player_Name,
    c.Country_Name

ORDER BY (fifties + centuries) DESC;

-- # Power Hitters of IPL
SELECT 
    p.Player_Name,
    c.Country_Name,
    a.boundaries,
    a.fours,
    a.sixes

FROM (

    SELECT 
        a.Striker,

        SUM(CASE 
                WHEN b.Runs_Scored = 4 OR b.Runs_Scored = 6 
                THEN 1 ELSE 0 
            END) AS boundaries,

        SUM(CASE WHEN b.Runs_Scored = 4 THEN 1 ELSE 0 END) AS fours,

        SUM(CASE WHEN b.Runs_Scored = 6 THEN 1 ELSE 0 END) AS sixes

    FROM Ball_by_Ball a

    JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    GROUP BY a.Striker

) a

JOIN Player p
    ON a.Striker = p.Player_Id

JOIN Country c
    ON p.Country_Name = c.Country_Id

JOIN Batting_Style bs
    ON p.Batting_hand = bs.Batting_Id

ORDER BY a.sixes DESC;

-- # Batsman's with Highest strike rate and batting_average in IPL
SELECT 
    d.Player_Name AS Player,
    d.Country_Name,
    c.Matches,
    a.Runs,

    ROUND(a.Runs / NULLIF(b.dismissals, 0), 2) AS Batting_Avg,

    a.Strike_Rate

FROM (

    -- 🔹 Runs + Strike Rate
    SELECT 
        a.Striker,
        SUM(COALESCE(b.Runs_Scored, 0)) AS Runs,

        100 * (
            SUM(COALESCE(b.Runs_Scored, 0)) / NULLIF(COUNT(*), 0)
        ) AS Strike_Rate

    FROM Ball_by_Ball a

    LEFT JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id

    GROUP BY a.Striker

) a

JOIN (

    -- 🔹 Dismissals
    SELECT 
        Player_Out,
        COUNT(*) AS dismissals
    FROM Wicket_Taken
    GROUP BY Player_Out

) b
    ON a.Striker = b.Player_Out

JOIN (

    -- 🔹 Matches
    SELECT 
        Striker,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Striker

) c
    ON a.Striker = c.Striker

JOIN (

    -- 🔹 Player details
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Batting_hand
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Batting_Style c
        ON a.Batting_hand = c.Batting_Id

) d
    ON a.Striker = d.Player_Id

WHERE c.Matches >= 50

ORDER BY 
    Batting_Avg DESC,
    a.Strike_Rate DESC;
    
-- #Batsman's with lowest strike rate and batting_average in IPL
-- reverse the Logics


-- # Best Batsman's in IPL
SELECT 
    f.Player_Name AS Player,
    e.Matches,
    a.Runs,
    a.Strike_Rate,

    ROUND(a.Runs / NULLIF(b.dismissals, 0), 2) AS Batting_Avg,

    c.fifties,
    c.centuries,
    c.Best_Score

FROM (

    -- 🔹 Runs + Strike Rate
    SELECT 
        a.Striker,
        SUM(COALESCE(b.Runs_Scored,0)) AS Runs,

        100 * (
            SUM(COALESCE(b.Runs_Scored,0)) / NULLIF(COUNT(*),0)
        ) AS Strike_Rate

    FROM Ball_by_Ball a

    LEFT JOIN Batsman_Scored b
        ON a.Match_Id = b.Match_Id
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id
        AND a.Ball_Id = b.Ball_Id

    GROUP BY a.Striker

) a

JOIN (

    -- 🔹 Dismissals
    SELECT 
        Player_Out,
        COUNT(*) AS dismissals
    FROM Wicket_Taken
    GROUP BY Player_Out

) b
    ON a.Striker = b.Player_Out

JOIN (

    -- 🔹 Milestones (50s, 100s, Best Score)
    SELECT 
        Striker,

        SUM(CASE WHEN runs >= 50 AND runs < 100 THEN 1 ELSE 0 END) AS fifties,
        SUM(CASE WHEN runs >= 100 THEN 1 ELSE 0 END) AS centuries,
        MAX(runs) AS Best_Score

    FROM (

        SELECT 
            a.Striker,
            a.Match_Id,
            SUM(b.Runs_Scored) AS runs

        FROM Ball_by_Ball a

        JOIN Batsman_Scored b
            ON a.Match_Id = b.Match_Id
            AND a.Innings_No = b.Innings_No
            AND a.Over_Id = b.Over_Id
            AND a.Ball_Id = b.Ball_Id

        GROUP BY a.Striker, a.Match_Id

    ) x

    GROUP BY Striker

) c
    ON a.Striker = c.Striker

JOIN (

    -- 🔹 Matches
    SELECT 
        Striker,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Striker

) e
    ON a.Striker = e.Striker

JOIN (

    -- 🔹 Player Info
    SELECT 
        a.Player_Id,
        a.Player_Name,
        b.Country_Name,
        c.Batting_hand
    FROM Player a
    JOIN Country b
        ON a.Country_Name = b.Country_Id
    JOIN Batting_Style c
        ON a.Batting_hand = c.Batting_Id

) f
    ON a.Striker = f.Player_Id

WHERE e.Matches >= 50

ORDER BY 
    Batting_Avg DESC,
    a.Strike_Rate DESC;
    
-- Fielding Statistics
-- Best Fielders in IPL
SELECT 
    Player_Name,
    Country_Name,
    dismissals,
    catch,
    run_out
FROM (
    SELECT 
        b.Player_Name,
        b.Country_Name,
        COUNT(a.Kind_Out) AS dismissals,
        SUM(CASE WHEN a.Kind_Out = 1 THEN 1 ELSE 0 END) AS catch,
        SUM(CASE WHEN a.Kind_Out = 3 THEN 1 ELSE 0 END) AS run_out,
        SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumping
    FROM Wicket_Taken a
    JOIN (
        SELECT 
            p.Player_Id,
            p.Player_Name,
            c.Country_Name
        FROM Player p
        JOIN Country c
            ON p.Country_Name = c.Country_Id
    ) b
        ON a.Fielders = b.Player_Id
    WHERE a.Kind_Out IN (1, 3, 6)
    GROUP BY b.Player_Id, b.Player_Name, b.Country_Name
    HAVING SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) = 0
) t
ORDER BY dismissals DESC;

-- #Best Wicket-Keepers in IPL
SELECT 
    b.Player_Name,
    b.Country_Name,
    COUNT(a.Kind_Out) AS dismissals,
    SUM(CASE WHEN a.Kind_Out = 1 THEN 1 ELSE 0 END) AS catch,
    SUM(CASE WHEN a.Kind_Out = 3 THEN 1 ELSE 0 END) AS run_out,
    SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumping
FROM Wicket_Taken a
JOIN (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
) b
    ON a.Fielders = b.Player_Id
WHERE a.Kind_Out IN (1, 3, 6)
GROUP BY b.Player_Id, b.Player_Name, b.Country_Name
HAVING SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) != 0
ORDER BY dismissals DESC;

-- Captain Statistics
-- # Most successful captains of IPL
SELECT 
    c.Player_Name AS Captain,
    c.Country_Name,
    COUNT(*) AS Matches,

    SUM(CASE WHEN a.Team_Id = b.Winner THEN 1 ELSE 0 END) AS Wins,

    ROUND(
        SUM(CASE WHEN a.Team_Id = b.Winner THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS Win_perc,

    ROUND(
        SUM(CASE WHEN a.Team_Id = b.Winner THEN b.chasing ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN a.Team_Id = b.Winner THEN b.chasing ELSE 0 END)
            + SUM(CASE WHEN a.Team_Id != b.Winner THEN b.defending ELSE 0 END),
        0),
    2) AS Chasing_perc,

    ROUND(
        SUM(CASE WHEN a.Team_Id = b.Winner THEN b.defending ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN a.Team_Id = b.Winner THEN b.defending ELSE 0 END)
            + SUM(CASE WHEN a.Team_Id != b.Winner THEN b.chasing ELSE 0 END),
        0),
    2) AS Defending_perc

FROM (
    SELECT 
        Match_Id,
        Team_Id,
        Player_Id
    FROM Player_Match
    WHERE Role_Id IN (1,4)
) a

LEFT JOIN (
    SELECT 
        Match_Id,
        CASE 
            WHEN Win_Type = 1 THEN 
                CASE 
                    WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_1
                    WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_2
                    WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_2
                    ELSE Team_1
                END
            ELSE 
                CASE 
                    WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_2
                    WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_1
                    WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_1
                    ELSE Team_2
                END
        END AS Winner,

        CASE WHEN Win_Type = 1 THEN 1 ELSE 0 END AS defending,
        CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END AS chasing

    FROM `Match`
    WHERE Win_Type IN (1,2)
) b
    ON a.Match_Id = b.Match_Id

JOIN (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
) c
    ON a.Player_Id = c.Player_Id

GROUP BY 
    c.Player_Id, c.Player_Name, c.Country_Name

HAVING Matches >= 30

ORDER BY 
    Win_perc DESC, 
    Chasing_perc DESC, 
    Defending_perc DESC;
    
-- Team Statistics
-- Best Team in IPL
SELECT 
    t.Team_Name AS franchise,
    COUNT(x.Match_Id) AS matches,
    SUM(CASE WHEN x.Win_Type = 1 THEN 1 ELSE 0 END) AS wins,

    ROUND(
        SUM(CASE WHEN x.Win_Type = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(x.Match_Id), 0),
    2) AS win_percentage

FROM (
    SELECT 
        a.Match_Id,
        a.Win_Type,

        -- Correct franchise mapping based on toss + decision
        CASE 
            WHEN a.Toss_Winner = a.Team_1 AND a.Toss_Decide = 2 THEN a.Team_1
            WHEN a.Toss_Winner = a.Team_1 AND a.Toss_Decide = 1 THEN a.Team_2
            WHEN a.Toss_Winner = a.Team_2 AND a.Toss_Decide = 2 THEN a.Team_2
            ELSE a.Team_1
        END AS Team_Id

    FROM `Match` a
) x

JOIN Team t
    ON x.Team_Id = t.Team_Id

GROUP BY t.Team_Id, t.Team_Name
ORDER BY win_percentage DESC;

-- # best team in chasing the score
SELECT 
    franchise,
    COUNT(Match_Id) AS matches,
    SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END) AS wins,

    ROUND(
        SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(Match_Id), 0),
    2) AS win_percentage

FROM (
    SELECT 
        a.Match_Id,
        a.Win_Type,

        CASE 
            WHEN a.Toss_Winner = a.Team_1 AND a.Toss_Decide = 2 THEN c.Team_Name
            WHEN a.Toss_Winner = a.Team_1 AND a.Toss_Decide = 1 THEN b.Team_Name
            WHEN a.Toss_Winner = a.Team_2 AND a.Toss_Decide = 2 THEN b.Team_Name
            ELSE c.Team_Name
        END AS franchise

    FROM `Match` a
    JOIN Team b ON a.Team_1 = b.Team_Id
    JOIN Team c ON a.Team_2 = c.Team_Id
) x

GROUP BY franchise
ORDER BY win_percentage DESC;

-- # Best Teams in IPL
SELECT 
    f.Team_Name AS Team,

    COALESCE(a.matches, 0) + COALESCE(b.matches, 0) AS Matches,
    COALESCE(c.Wins, 0) AS Wins,

    ROUND(
        COALESCE(c.Wins, 0) 
        / NULLIF(COALESCE(a.matches, 0) + COALESCE(b.matches, 0), 0),
    2) AS Win_perc,

    COALESCE(d.Defending_perc, 0) AS Defending_perc,
    COALESCE(e.Chasing_perc, 0) AS Chasing_perc

FROM Team f

/* Matches where Team_1 */
LEFT JOIN (
    SELECT Team_1 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Team_1
) a
ON f.Team_Id = a.Team_Id

/* Matches where Team_2 */
LEFT JOIN (
    SELECT Team_2 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Team_2
) b
ON f.Team_Id = b.Team_Id

/* Wins */
LEFT JOIN (
    SELECT Match_Winner AS Team_Id, COUNT(*) AS Wins
    FROM `Match`
    WHERE Match_Winner IS NOT NULL
    GROUP BY Match_Winner
) c
ON f.Team_Id = c.Team_Id

/* Defending performance */
LEFT JOIN (
    SELECT 
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(Match_Id), 0),
        2) AS Defending_perc
    FROM (
        SELECT 
            Match_Id,
            CASE 
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_1
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_2
                WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_2
                ELSE Team_1
            END AS franchise,
            Win_Type,
            Outcome_type
        FROM `Match`
        WHERE Outcome_type = 1
    ) x
    GROUP BY franchise
) d
ON f.Team_Id = d.franchise

/* Chasing performance */
LEFT JOIN (
    SELECT 
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(Match_Id), 0),
        2) AS Chasing_perc
    FROM (
        SELECT 
            Match_Id,
            CASE 
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_2
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_1
                WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_1
                ELSE Team_2
            END AS franchise,
            Win_Type,
            Outcome_type
        FROM `Match`
        WHERE Outcome_type = 1
    ) y
    GROUP BY franchise
) e
ON f.Team_Id = e.franchise

ORDER BY 
    Win_perc DESC,
    Chasing_perc DESC,
    Defending_perc DESC;

-- # IPL Season's Best PLayers
select Season_Year,
        b.Player_Name as Man_of_Season,
        c.Player_Name as Top_Scorer,
        d.Player_Name as Top_Wicket_Tacker
        from Season a
        join Player b
        on a.Man_of_the_Series=b.Player_Id
        join Player c
        on a.Orange_Cap=c.Player_Id
        join Player d
        on a.Purple_Cap=d.Player_Id;
        
-- # IPL Season's Winners,Runners Up, Win Type
SELECT 
    s.Season_Year,
    w.Team_Name AS Winner,
    r.Team_Name AS Runner_Up

FROM Season s

JOIN (
    -- Get final match of each season (highest Match_Id per Season)
    SELECT 
        Season_Id,
        MAX(Match_Id) AS Final_Match_Id
    FROM `Match`
    GROUP BY Season_Id
) f
    ON s.Season_Id = f.Season_Id

JOIN `Match` m
    ON m.Match_Id = f.Final_Match_Id

JOIN Team w
    ON m.Match_Winner = w.Team_Id

JOIN Team r
    ON CASE 
            WHEN m.Team_1 = m.Match_Winner THEN m.Team_2
            ELSE m.Team_1
        END = r.Team_Id;

-- Runs scored in powerplay,middle and death overs in different seasons of
-- IPL
SELECT 
    d.Season_Year,
    e.Matches,

    SUM(CASE 
            WHEN a.Over_Id <= 6 
            THEN a.Runs_Scored + COALESCE(c.Extra_Runs, 0) 
            ELSE 0 
        END) AS powerplay,

    SUM(CASE 
            WHEN a.Over_Id > 6 AND a.Over_Id <= 15 
            THEN a.Runs_Scored + COALESCE(c.Extra_Runs, 0) 
            ELSE 0 
        END) AS middleovers,

    SUM(CASE 
            WHEN a.Over_Id > 15 
            THEN a.Runs_Scored + COALESCE(c.Extra_Runs, 0) 
            ELSE 0 
        END) AS deathovers

FROM Batsman_Scored a

JOIN `Match` b
    ON a.Match_Id = b.Match_Id

LEFT JOIN Extra_Runs c
    ON a.Match_Id = c.Match_Id
    AND a.Innings_No = c.Innings_No
    AND a.Over_Id = c.Over_Id
    AND a.Ball_Id = c.Ball_Id

JOIN Season d
    ON b.Season_Id = d.Season_Id

JOIN (
    SELECT 
        Season_Id,
        COUNT(Match_Id) AS Matches
    FROM `Match`
    GROUP BY Season_Id
) e
    ON b.Season_Id = e.Season_Id
GROUP BY d.Season_Year, e.Matches;

-- #highest score of a Season 
-- problem is not get the highest we have to rank and generate a code
SELECT 
    s.Season_Year,

    CASE 
        WHEN x.Innings_No = 1 THEN bt.Team_Name
        ELSE ft.Team_Name
    END AS batting_team,

    CASE 
        WHEN x.Innings_No = 1 THEN ft.Team_Name
        ELSE bt.Team_Name
    END AS fielding_team,

    x.Score,
    c.City_Name

FROM (

    SELECT 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,

        (SUM(a.Runs_Scored) + COALESCE(MAX(e.extra), 0)) AS Score,

        CASE 
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 1 THEN b.Team_2
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 2 THEN b.Team_1
            WHEN b.Toss_Winner = b.Team_2 AND b.Toss_Decide = 1 THEN b.Team_1
            ELSE b.Team_2
        END AS batting_team_id,

        CASE 
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 1 THEN b.Team_1
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 2 THEN b.Team_2
            WHEN b.Toss_Winner = b.Team_2 AND b.Toss_Decide = 1 THEN b.Team_2
            ELSE b.Team_1
        END AS fielding_team_id

    FROM Batsman_Scored a

    JOIN `Match` b
        ON a.Match_Id = b.Match_Id

    LEFT JOIN (
        SELECT 
            Match_Id,
            Innings_No,
            SUM(Extra_Runs) AS extra
        FROM Extra_Runs
        GROUP BY Match_Id, Innings_No
    ) e
        ON a.Match_Id = e.Match_Id
        AND a.Innings_No = e.Innings_No

    GROUP BY 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,
        batting_team_id,
        fielding_team_id

) x

JOIN Season s
    ON x.Season_Id = s.Season_Id

JOIN Team bt
    ON x.batting_team_id = bt.Team_Id

JOIN Team ft
    ON x.fielding_team_id = ft.Team_Id

JOIN Venue v
    ON x.Venue_Id = v.Venue_Id

JOIN City c
    ON v.City_Id = c.City_Id;
    
-- #Lowest score of a Season 
-- same problem we have to add the rank and extract 
SELECT 
    s.Season_Year,

    CASE 
        WHEN x.Innings_No = 1 THEN bt.Team_Name
        ELSE ft.Team_Name
    END AS batting_team,

    CASE 
        WHEN x.Innings_No = 1 THEN ft.Team_Name
        ELSE bt.Team_Name
    END AS fielding_team,

    x.Score,
    c.City_Name

FROM (

    SELECT 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,

        (SUM(a.Runs_Scored) + COALESCE(MAX(e.extra), 0)) AS Score,

        CASE 
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 1 THEN b.Team_2
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 2 THEN b.Team_1
            WHEN b.Toss_Winner = b.Team_2 AND b.Toss_Decide = 1 THEN b.Team_1
            ELSE b.Team_2
        END AS batting_team_id,

        CASE 
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 1 THEN b.Team_1
            WHEN b.Toss_Winner = b.Team_1 AND b.Toss_Decide = 2 THEN b.Team_2
            WHEN b.Toss_Winner = b.Team_2 AND b.Toss_Decide = 1 THEN b.Team_2
            ELSE b.Team_1
        END AS fielding_team_id

    FROM Batsman_Scored a

    JOIN `Match` b
        ON a.Match_Id = b.Match_Id

    LEFT JOIN (
        SELECT 
            Match_Id,
            Innings_No,
            SUM(Extra_Runs) AS extra
        FROM Extra_Runs
        GROUP BY Match_Id, Innings_No
    ) e
        ON a.Match_Id = e.Match_Id
        AND a.Innings_No = e.Innings_No

    WHERE b.Win_Type NOT IN (3,4)

    GROUP BY 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,
        batting_team_id,
        fielding_team_id

) x

JOIN Season s
    ON x.Season_Id = s.Season_Id

JOIN Team bt
    ON x.batting_team_id = bt.Team_Id

JOIN Team ft
    ON x.fielding_team_id = ft.Team_Id

JOIN Venue v
    ON x.Venue_Id = v.Venue_Id

JOIN City c
    ON v.City_Id = c.City_Id;

-- # Season Wise Team Performance
SELECT 
    g.Season_Year,
    f.Team_Name,

    COALESCE(a.matches, 0) + COALESCE(b.matches, 0) AS Matches,
    COALESCE(c.Wins, 0) AS Wins,

    ROUND(
        COALESCE(c.Wins, 0) 
        / NULLIF(COALESCE(a.matches, 0) + COALESCE(b.matches, 0), 0),
    2) AS Win_perc,

    COALESCE(d.Defending_perc, 0) AS Defending_perc,
    COALESCE(e.Chasing_perc, 0) AS Chasing_perc

FROM Team f

JOIN Season g

/* Matches as Team_1 */
LEFT JOIN (
    SELECT Season_Id, Team_1 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Season_Id, Team_1
) a
ON f.Team_Id = a.Team_Id AND g.Season_Id = a.Season_Id

/* Matches as Team_2 */
LEFT JOIN (
    SELECT Season_Id, Team_2 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Season_Id, Team_2
) b
ON f.Team_Id = b.Team_Id AND g.Season_Id = b.Season_Id

/* Wins */
LEFT JOIN (
    SELECT Season_Id, Match_Winner AS Team_Id, COUNT(*) AS Wins
    FROM `Match`
    WHERE Match_Winner IS NOT NULL
    GROUP BY Season_Id, Match_Winner
) c
ON f.Team_Id = c.Team_Id AND g.Season_Id = c.Season_Id

/* Defending performance */
LEFT JOIN (
    SELECT 
        Season_Id,
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
        2) AS Defending_perc
    FROM (
        SELECT 
            Match_Id,
            Season_Id,
            CASE 
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_1
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_2
                WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_2
                ELSE Team_1
            END AS franchise,
            Win_Type
        FROM `Match`
        WHERE Outcome_type = 1
    ) x
    GROUP BY Season_Id, franchise
) d
ON f.Team_Id = d.franchise AND g.Season_Id = d.Season_Id

/* Chasing performance */
LEFT JOIN (
    SELECT 
        Season_Id,
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
        2) AS Chasing_perc
    FROM (
        SELECT 
            Match_Id,
            Season_Id,
            CASE 
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_2
                WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_1
                WHEN Toss_Winner = Team_2 AND Toss_Decide = 2 THEN Team_1
                ELSE Team_2
            END AS franchise,
            Win_Type
        FROM `Match`
        WHERE Outcome_type = 1
    ) y
    GROUP BY Season_Id, franchise
) e
ON f.Team_Id = e.franchise AND g.Season_Id = e.Season_Id

ORDER BY 
    g.Season_Id,
    Matches DESC,
    Wins DESC,
    Chasing_perc DESC;