use ipl_project;

-- Bowlers who have bowled most deliveries
WITH bowler_deliveries AS (
    SELECT 
        a.Bowler,
        COUNT(*) AS Deliveries
    FROM Ball_by_Ball a
    GROUP BY a.Bowler
)
SELECT 
    p.Player_Name,
    c.Country_Name,
    bs.Bowling_skill,
    bd.Deliveries
FROM bowler_deliveries bd
JOIN Player p
    ON bd.Bowler = p.Player_Id
JOIN Country c
    ON p.Country_Name = c.Country_Id
JOIN Bowling_Style bs
    ON p.Bowling_skill = bs.Bowling_Id
ORDER BY bd.Deliveries DESC;

#Highest Wicket takers in IPL
-- Runout, Retired hurt and Obstructing field are not counted as bowlers wicket
WITH bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Bowling_skill
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
),

wicket_details AS (
    SELECT 
        a.Match_Id,
        a.Innings_No,
        a.Over_Id,
        a.Ball_Id,
        b.Bowler,
        a.Kind_Out
    FROM Wicket_Taken a
    JOIN Ball_by_Ball b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id
    WHERE a.Kind_Out IN (1, 2, 4, 6, 7, 8)
)

SELECT 
    bi.Player_Name,
    COUNT(wd.Kind_Out) AS Wickets,

    SUM(CASE WHEN wd.Kind_Out = 1 THEN 1 ELSE 0 END) AS caught,
    SUM(CASE WHEN wd.Kind_Out = 2 THEN 1 ELSE 0 END) AS bowled,
    SUM(CASE WHEN wd.Kind_Out = 4 THEN 1 ELSE 0 END) AS lbw,
    SUM(CASE WHEN wd.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumped

FROM wicket_details wd

JOIN bowler_info bi
    ON wd.Bowler = bi.Player_Id
GROUP BY 
    bi.Player_Id,
    bi.Player_Name
ORDER BY Wickets DESC;

-- Highest wicket Talen By the bowler in an ipl matches
WITH bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Bowling_skill
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
),

wickets AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        COUNT(w.Kind_Out) AS Wickets
    FROM Ball_by_Ball bb
    JOIN Wicket_Taken w
        ON bb.Match_Id = w.Match_Id
        AND bb.Innings_No = w.Innings_No
        AND bb.Over_Id = w.Over_Id
        AND bb.Ball_Id = w.Ball_Id
    WHERE w.Kind_Out IN (1, 2, 4, 6, 7, 8)
    GROUP BY bb.Bowler, bb.Match_Id
),

runs AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        SUM(
            COALESCE(bs.Runs_Scored, 0) + 
            COALESCE(er.Extra_Runs, 0)
        ) AS runs
    FROM Ball_by_Ball bb

    LEFT JOIN Batsman_Scored bs
        ON bb.Match_Id = bs.Match_Id
        AND bb.Innings_No = bs.Innings_No
        AND bb.Over_Id = bs.Over_Id
        AND bb.Ball_Id = bs.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bb.Match_Id = er.Match_Id
        AND bb.Innings_No = er.Innings_No
        AND bb.Over_Id = er.Over_Id
        AND bb.Ball_Id = er.Ball_Id

    GROUP BY bb.Bowler, bb.Match_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bi.Bowling_skill,

    CONCAT(w.Wickets, '-', r.runs) AS Best

FROM wickets w

JOIN runs r
    ON w.Bowler = r.Bowler
    AND w.Match_Id = r.Match_Id

JOIN bowler_info bi
    ON w.Bowler = bi.Player_Id

ORDER BY w.Wickets DESC;

--  No of 5-wicket hauls by bowlers in an IPL 
WITH bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Bowling_skill
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
),

match_wickets AS (
    SELECT 
        bb.Bowler,
        wt.Match_Id,
        COUNT(wt.Kind_Out) AS Wickets
    FROM Wicket_Taken wt

    JOIN Ball_by_Ball bb
        ON wt.Match_Id = bb.Match_Id
        AND wt.Innings_No = bb.Innings_No
        AND wt.Over_Id = bb.Over_Id
        AND wt.Ball_Id = bb.Ball_Id

    WHERE wt.Kind_Out IN (1, 2, 4, 6, 7, 8)

    GROUP BY 
        bb.Bowler,
        wt.Match_Id
),

five_wicket_matches AS (
    SELECT 
        mw.Bowler,
        mw.Match_Id
    FROM match_wickets mw
    WHERE mw.Wickets >= 5
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bi.Bowling_skill,
    COUNT(*) AS hauls

FROM five_wicket_matches fwm

JOIN bowler_info bi
    ON fwm.Bowler = bi.Player_Id

GROUP BY 
    bi.Player_Id,
    bi.Player_Name,
    bi.Country_Name,
    bi.Bowling_skill

ORDER BY hauls DESC;

-- Most Runs Conceded by a Bowler in an IPL Match
WITH bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Bowling_skill
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
),

bowler_runs AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        SUM(
            COALESCE(bs.Runs_Scored, 0) + 
            COALESCE(er.Extra_Runs, 0)
        ) AS runs
    FROM Ball_by_Ball bb

    LEFT JOIN Batsman_Scored bs
        ON bb.Match_Id = bs.Match_Id
        AND bb.Innings_No = bs.Innings_No
        AND bb.Over_Id = bs.Over_Id
        AND bb.Ball_Id = bs.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bb.Match_Id = er.Match_Id
        AND bb.Innings_No = er.Innings_No
        AND bb.Over_Id = er.Over_Id
        AND bb.Ball_Id = er.Ball_Id

    GROUP BY 
        bb.Bowler,
        bb.Match_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bi.Bowling_skill,
    br.runs

FROM bowler_runs br

JOIN bowler_info bi
    ON br.Bowler = bi.Player_Id

ORDER BY br.runs DESC;

 -- # Highest Runs Concede in an IPL over by a bowler
 WITH batsman_over AS (
    SELECT 
        Match_Id,
        Innings_No,
        Over_Id,
        SUM(Runs_Scored) AS runs,
        SUM(CASE WHEN Runs_Scored = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN Runs_Scored = 6 THEN 1 ELSE 0 END) AS Sixes
    FROM Batsman_Scored
    GROUP BY Match_Id, Innings_No, Over_Id
),

extra_over AS (
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
),

bowler_over AS (
    SELECT 
        bb.Match_Id,
        bb.Innings_No,
        bb.Over_Id,
        p.Player_Name,
        bs.Bowling_skill,
        c.Country_Name
    FROM Ball_by_Ball bb
    JOIN Player p
        ON bb.Bowler = p.Player_Id
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    GROUP BY 
        bb.Match_Id,
        bb.Innings_No,
        bb.Over_Id,
        p.Player_Name,
        bs.Bowling_skill,
        c.Country_Name
)

SELECT 
    bo.Player_Name AS Bowler,

    (bats.runs + COALESCE(exe.Extra, 0)) AS Runs,

    bats.Fours,
    bats.Sixes,

    COALESCE(exe.Extra, 0) AS Extra,
    COALESCE(exe.wides, 0) AS wides,
    COALESCE(exe.noballs, 0) AS noballs,
    COALESCE(exe.legbyes, 0) AS legbyes

FROM batsman_over bats

JOIN bowler_over bo
    ON bats.Match_Id = bo.Match_Id
    AND bats.Innings_No = bo.Innings_No
    AND bats.Over_Id = bo.Over_Id

LEFT JOIN extra_over exe
    ON bats.Match_Id = exe.Match_Id
    AND bats.Innings_No = exe.Innings_No
    AND bats.Over_Id = exe.Over_Id

ORDER BY Runs DESC;

-- # best economy bowler's in IPL
WITH bowler_stats AS (
    SELECT 
        bb.Bowler,

        SUM(
            COALESCE(er.Extra_Runs, 0) + bs.Runs_Scored
        ) AS runs,

        SUM(COALESCE(er.Extra_Runs, 0)) AS extras,

        COUNT(*) / 6 AS overs,

        ROUND(
            SUM(
                COALESCE(er.Extra_Runs, 0) + bs.Runs_Scored
            ) / NULLIF(COUNT(*) / 6, 0),
        2) AS economy

    FROM Batsman_Scored bs

    JOIN Ball_by_Ball bb
        ON bs.Match_Id = bb.Match_Id
        AND bs.Innings_No = bb.Innings_No
        AND bs.Over_Id = bb.Over_Id
        AND bs.Ball_Id = bb.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bs.Match_Id = er.Match_Id
        AND bs.Innings_No = er.Innings_No
        AND bs.Over_Id = er.Over_Id
        AND bs.Ball_Id = er.Ball_Id

    GROUP BY bb.Bowler

    HAVING COUNT(*) / 6 >= 50
),

bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        bs.Bowling_skill,
        c.Country_Name
    FROM Player p
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bs.overs,
    bs.runs,
    bs.extras,
    bs.economy

FROM bowler_stats bs

JOIN bowler_info bi
    ON bs.Bowler = bi.Player_Id

ORDER BY bs.economy ASC;

-- worst economy
WITH bowler_stats AS (
    SELECT 
        bb.Bowler,

        SUM(
            COALESCE(er.Extra_Runs, 0) + bs.Runs_Scored
        ) AS runs,

        SUM(COALESCE(er.Extra_Runs, 0)) AS extras,

        COUNT(*) / 6 AS overs,

        ROUND(
            SUM(
                COALESCE(er.Extra_Runs, 0) + bs.Runs_Scored
            ) / NULLIF(COUNT(*) / 6, 0),
        2) AS economy

    FROM Batsman_Scored bs

    JOIN Ball_by_Ball bb
        ON bs.Match_Id = bb.Match_Id
        AND bs.Innings_No = bb.Innings_No
        AND bs.Over_Id = bb.Over_Id
        AND bs.Ball_Id = bb.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bs.Match_Id = er.Match_Id
        AND bs.Innings_No = er.Innings_No
        AND bs.Over_Id = er.Over_Id
        AND bs.Ball_Id = er.Ball_Id

    GROUP BY bb.Bowler

    HAVING COUNT(*) / 6 >= 50
),

bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        bs.Bowling_skill,
        c.Country_Name
    FROM Player p
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bs.overs,
    bs.runs,
    bs.extras,
    bs.economy

FROM bowler_stats bs

JOIN bowler_info bi
    ON bs.Bowler = bi.Player_Id

ORDER BY bs.economy DESC;

-- #Best Death overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an over -- mistake in wickets
WITH death_over_runs AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id,

        SUM(
            COALESCE(bs.Runs_Scored, 0) + 
            COALESCE(er.Extra_Runs, 0)
        ) AS runs

    FROM Ball_by_Ball bb

    LEFT JOIN Batsman_Scored bs
        ON bb.Match_Id = bs.Match_Id
        AND bb.Innings_No = bs.Innings_No
        AND bb.Over_Id = bs.Over_Id
        AND bb.Ball_Id = bs.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bb.Match_Id = er.Match_Id
        AND bb.Innings_No = er.Innings_No
        AND bb.Over_Id = er.Over_Id
        AND bb.Ball_Id = er.Ball_Id

    WHERE bb.Over_Id IN (16,17,18,19,20)

    GROUP BY 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id
),

bowler_stats AS (
    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / NULLIF(COUNT(*), 0), 2) AS Economy
    FROM death_over_runs
    GROUP BY Bowler
),

death_over_wickets AS (
    SELECT 
        bb.Bowler,
        COUNT(*) AS Wickets
    FROM Ball_by_Ball bb

    JOIN Wicket_Taken wt
        ON bb.Match_Id = wt.Match_Id
        AND bb.Innings_No = wt.Innings_No
        AND bb.Over_Id = wt.Over_Id
        AND bb.Ball_Id = wt.Ball_Id

    WHERE bb.Over_Id IN (16,17,18,19,20)
      AND wt.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY bb.Bowler
),

bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bs.Overs,
    bs.Runs,
    COALESCE(w.Wickets, 0) AS Wickets,
    bs.Economy,

    ROUND(
        COALESCE(w.Wickets, 0) / NULLIF(bs.Overs, 0),
    2) AS Wicket_rate

FROM bowler_stats bs

LEFT JOIN death_over_wickets w
    ON bs.Bowler = w.Bowler

JOIN bowler_info bi
    ON bs.Bowler = bi.Player_Id

WHERE bs.Overs >= 50

ORDER BY 
    bs.Economy ASC,
    Wicket_rate DESC;

 -- Poor Death overs Bowler's in Indian Premier League   
 -- reverse the Logics
 
 -- #Best powerplay overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an over
WITH powerplay_runs AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id,

        SUM(
            COALESCE(bs.Runs_Scored, 0) + 
            COALESCE(er.Extra_Runs, 0)
        ) AS runs

    FROM Ball_by_Ball bb

    LEFT JOIN Batsman_Scored bs
        ON bb.Match_Id = bs.Match_Id
        AND bb.Innings_No = bs.Innings_No
        AND bb.Over_Id = bs.Over_Id
        AND bb.Ball_Id = bs.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bb.Match_Id = er.Match_Id
        AND bb.Innings_No = er.Innings_No
        AND bb.Over_Id = er.Over_Id
        AND bb.Ball_Id = er.Ball_Id

    WHERE bb.Over_Id BETWEEN 1 AND 6

    GROUP BY 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id
),

bowler_stats AS (
    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / NULLIF(COUNT(*), 0), 2) AS Economy
    FROM powerplay_runs
    GROUP BY Bowler
),

powerplay_wickets AS (
    SELECT 
        bb.Bowler,
        COUNT(*) AS Wickets

    FROM Ball_by_Ball bb

    JOIN Wicket_Taken wt
        ON bb.Match_Id = wt.Match_Id
        AND bb.Innings_No = wt.Innings_No
        AND bb.Over_Id = wt.Over_Id
        AND bb.Ball_Id = wt.Ball_Id

    WHERE bb.Over_Id BETWEEN 1 AND 6
      AND wt.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY bb.Bowler
),

bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bs.Overs,
    bs.Runs,
    COALESCE(w.Wickets, 0) AS Wickets,
    bs.Economy,

    ROUND(
        COALESCE(w.Wickets, 0) / NULLIF(bs.Overs, 0),
    2) AS Wicket_rate

FROM bowler_stats bs

LEFT JOIN powerplay_wickets w
    ON bs.Bowler = w.Bowler

JOIN bowler_info bi
    ON bs.Bowler = bi.Player_Id

WHERE bs.Overs >= 50

ORDER BY 
    bs.Economy ASC,
    Wicket_rate DESC;

-- #Poor Powerplay overs Bowler's in Indian Premier League 
-- reverse the logfics

- #Best Middle overs Bowler's in Indian Premier League
-- #Wickets_rate= average no of wickets ball in an over
-- wickets priblems
WITH middle_over_runs AS (
    SELECT 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id,

        SUM(
            COALESCE(bs.Runs_Scored, 0) + 
            COALESCE(er.Extra_Runs, 0)
        ) AS runs

    FROM Ball_by_Ball bb

    LEFT JOIN Batsman_Scored bs
        ON bb.Match_Id = bs.Match_Id
        AND bb.Innings_No = bs.Innings_No
        AND bb.Over_Id = bs.Over_Id
        AND bb.Ball_Id = bs.Ball_Id

    LEFT JOIN Extra_Runs er
        ON bb.Match_Id = er.Match_Id
        AND bb.Innings_No = er.Innings_No
        AND bb.Over_Id = er.Over_Id
        AND bb.Ball_Id = er.Ball_Id

    WHERE bb.Over_Id BETWEEN 7 AND 15

    GROUP BY 
        bb.Bowler,
        bb.Match_Id,
        bb.Over_Id
),

bowler_stats AS (
    SELECT 
        Bowler,
        COUNT(*) AS Overs,
        SUM(runs) AS Runs,
        ROUND(SUM(runs) / NULLIF(COUNT(*), 0), 2) AS Economy
    FROM middle_over_runs
    GROUP BY Bowler
),

middle_over_wickets AS (
    SELECT 
        bb.Bowler,
        COUNT(*) AS Wickets

    FROM Ball_by_Ball bb

    JOIN Wicket_Taken wt
        ON bb.Match_Id = wt.Match_Id
        AND bb.Innings_No = wt.Innings_No
        AND bb.Over_Id = wt.Over_Id
        AND bb.Ball_Id = wt.Ball_Id

    WHERE bb.Over_Id BETWEEN 7 AND 15
      AND wt.Kind_Out IN (1,2,4,6,7,8)

    GROUP BY bb.Bowler
),

bowler_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    bi.Player_Name,
    bi.Country_Name,
    bs.Overs,
    bs.Runs,
    COALESCE(w.Wickets, 0) AS Wickets,
    bs.Economy,

    ROUND(
        COALESCE(w.Wickets, 0) / NULLIF(bs.Overs, 0),
    2) AS Wicket_rate

FROM bowler_stats bs

LEFT JOIN middle_over_wickets w
    ON bs.Bowler = w.Bowler

JOIN bowler_info bi
    ON bs.Bowler = bi.Player_Id

WHERE bs.Overs >= 50

ORDER BY 
    bs.Economy ASC,
    Wicket_rate DESC;
    
-- best bowler in ipl
WITH runs_economy AS (

    -- 🔹 Runs + Economy
    SELECT 
        a.Bowler,

        SUM(
            COALESCE(b.Runs_Scored,0) + COALESCE(c.Extra_Runs,0)
        ) AS Runs,

        COUNT(*) / 6 AS Overs,

        ROUND(
            SUM(
                COALESCE(b.Runs_Scored,0) + COALESCE(c.Extra_Runs,0)
            ) / NULLIF(COUNT(*)/6,0)
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

    GROUP BY a.Bowler
    HAVING COUNT(*) / 6 >= 50
),

wickets AS (

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
),

match_stats AS (

    -- 🔹 Matches
    SELECT 
        Bowler,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Bowler
),

best_performance AS (

    -- 🔹 Best performance per bowler
    SELECT 
        t.Bowler,
        MAX(CONCAT(t.Wickets,'-',t.runs)) AS Best

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
),

player_info AS (

    -- 🔹 Player info
    SELECT 
        p.Player_Id,
        p.Player_Name,
        bs.Bowling_skill,
        c.Country_Name
    FROM Player p
    JOIN Bowling_Style bs
        ON p.Bowling_skill = bs.Bowling_Id
    JOIN Country c
        ON p.Country_Name = c.Country_Id
)

SELECT 
    p.Player_Name,
    p.Country_Name,
    m.Matches,
    r.Runs,
    w.Wickets,
    r.Economy,
    bp.Best

FROM runs_economy r

JOIN wickets w
    ON r.Bowler = w.Bowler

JOIN best_performance bp
    ON r.Bowler = bp.Bowler

JOIN match_stats m
    ON r.Bowler = m.Bowler

JOIN player_info p
    ON r.Bowler = p.Player_Id

ORDER BY 
    r.Economy ASC,
    w.Wickets DESC;
    
-- #Worst Bowlers in IPL reverse the logics

-- batsman who have faced most deliveries
WITH deliveries AS (

    -- 🔹 Count deliveries faced by each batsman
    SELECT 
        a.Striker,
        COUNT(*) AS Deliveries
    FROM Ball_by_Ball a
    GROUP BY a.Striker
),

player_info AS (

    -- 🔹 Player + country + batting style dimension
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    p.Player_Name,
    p.Country_Name,
    p.Batting_hand,
    d.Deliveries

FROM deliveries d

JOIN player_info p
    ON d.Striker = p.Player_Id

ORDER BY d.Deliveries DESC;

-- # Highest run scored by a batsman in an IPL 
WITH player_info AS (

    -- 🔹 Player dimension (name, country, batting style)
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
),

runs AS (

    -- 🔹 Runs scored per player
    SELECT 
        b.Striker,
        SUM(a.Runs_Scored) AS Runs
    FROM Batsman_Scored a
    JOIN Ball_by_Ball b
        ON a.Match_Id = b.Match_Id 
        AND a.Innings_No = b.Innings_No
        AND a.Over_Id = b.Over_Id 
        AND a.Ball_Id = b.Ball_Id
    GROUP BY b.Striker
)

SELECT 
    p.Player_Name,
    p.Country_Name,
    p.Batting_hand,
    r.Runs

FROM runs r

JOIN player_info p
    ON r.Striker = p.Player_Id

ORDER BY r.Runs DESC;

-- # Player who got dismissed at duck(0 score) highest no of times
WITH match_runs AS (

    -- 🔹 Runs per player per match
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
    HAVING SUM(b.Runs_Scored) = 0
),

player_info AS (

    -- 🔹 Player dimension
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    p.Player_Name,
    p.Country_Name,
    p.Batting_hand,
    COUNT(*) AS ducks

FROM match_runs m

JOIN player_info p
    ON m.Striker = p.Player_Id

GROUP BY 
    p.Player_Id,
    p.Player_Name,
    p.Country_Name,
    p.Batting_hand

ORDER BY ducks DESC;

-- # Highest run score by a batsman in an IPL match
WITH match_stats AS (
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
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    pi.Player_Name,
    pi.Country_Name,
    ms.runs AS highest_score,
    ms.balls,
    ms.dots,
    ms.fours,
    ms.sixes

FROM match_stats ms

JOIN player_info pi
    ON ms.Striker = pi.Player_Id

ORDER BY ms.runs DESC;

-- # No of fifties and centruies by a batsman in an IPL
WITH match_runs AS (
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
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    pi.Player_Name,
    pi.Country_Name,

    SUM(CASE WHEN mr.runs >= 50 AND mr.runs < 100 THEN 1 ELSE 0 END) AS fifties,
    SUM(CASE WHEN mr.runs >= 100 THEN 1 ELSE 0 END) AS centuries,
    MAX(mr.runs) AS highest_score

FROM match_runs mr

JOIN player_info pi
    ON mr.Striker = pi.Player_Id

GROUP BY 
    pi.Player_Id,
    pi.Player_Name,
    pi.Country_Name

ORDER BY (fifties + centuries) DESC;

-- # Power Hitters of IPL
WITH boundary_stats AS (
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
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    pi.Player_Name,
    pi.Country_Name,
    bs.boundaries,
    bs.fours,
    bs.sixes

FROM boundary_stats bs

JOIN player_info pi
    ON bs.Striker = pi.Player_Id

ORDER BY bs.sixes DESC;

-- # Batsman's with Highest strike rate and batting_average in IPL
WITH runs_sr AS (
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
),

dismissals AS (
    SELECT 
        Player_Out,
        COUNT(*) AS dismissals
    FROM Wicket_Taken
    GROUP BY Player_Out
),

matches AS (
    SELECT 
        Striker,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Striker
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    pi.Player_Name AS Player,
    pi.Country_Name,
    m.Matches,
    rs.Runs,

    ROUND(rs.Runs / NULLIF(d.dismissals, 0), 2) AS Batting_Avg,
    rs.Strike_Rate

FROM runs_sr rs

JOIN dismissals d
    ON rs.Striker = d.Player_Out

JOIN matches m
    ON rs.Striker = m.Striker

JOIN player_info pi
    ON rs.Striker = pi.Player_Id

WHERE m.Matches >= 50

ORDER BY 
    Batting_Avg DESC,
    rs.Strike_Rate DESC;
    

-- #Batsman's with lowest strike rate and batting_average in IPL
-- revsrse the logics

-- # Best Batsman's in IPL
WITH runs_sr AS (
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
),

dismissals AS (
    SELECT 
        Player_Out,
        COUNT(*) AS dismissals
    FROM Wicket_Taken
    GROUP BY Player_Out
),

matches AS (
    SELECT 
        Striker,
        COUNT(DISTINCT Match_Id) AS Matches
    FROM Ball_by_Ball
    GROUP BY Striker
),

match_runs AS (
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
),

milestones AS (
    SELECT 
        Striker,
        SUM(CASE WHEN runs >= 50 AND runs < 100 THEN 1 ELSE 0 END) AS fifties,
        SUM(CASE WHEN runs >= 100 THEN 1 ELSE 0 END) AS centuries,
        MAX(runs) AS Best_Score
    FROM match_runs
    GROUP BY Striker
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name,
        bs.Batting_hand
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
    JOIN Batting_Style bs
        ON p.Batting_hand = bs.Batting_Id
)

SELECT 
    pi.Player_Name AS Player,
    m.Matches,
    rs.Runs,
    rs.Strike_Rate,

    ROUND(rs.Runs / NULLIF(d.dismissals, 0), 2) AS Batting_Avg,

    ms.fifties,
    ms.centuries,
    ms.Best_Score

FROM runs_sr rs

JOIN dismissals d
    ON rs.Striker = d.Player_Out

JOIN matches m
    ON rs.Striker = m.Striker

JOIN milestones ms
    ON rs.Striker = ms.Striker

JOIN player_info pi
    ON rs.Striker = pi.Player_Id

WHERE m.Matches >= 50

ORDER BY 
    Batting_Avg DESC,
    rs.Strike_Rate DESC;
    
-- Fielding Statistics
-- Best Fielders in IPL
WITH fielder_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
),

fielding_stats AS (
    SELECT 
        fi.Player_Id,
        fi.Player_Name,
        fi.Country_Name,

        COUNT(a.Kind_Out) AS dismissals,
        SUM(CASE WHEN a.Kind_Out = 1 THEN 1 ELSE 0 END) AS catch,
        SUM(CASE WHEN a.Kind_Out = 3 THEN 1 ELSE 0 END) AS run_out,
        SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumping

    FROM Wicket_Taken a

    JOIN fielder_info fi
        ON a.Fielders = fi.Player_Id

    WHERE a.Kind_Out IN (1, 3, 6)

    GROUP BY 
        fi.Player_Id,
        fi.Player_Name,
        fi.Country_Name

    HAVING SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) = 0
)

SELECT 
    Player_Name,
    Country_Name,
    dismissals,
    catch,
    run_out
FROM fielding_stats

ORDER BY dismissals DESC;

-- #Best Wicket-Keepers in IPL
WITH fielder_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
),

wicketkeeper_stats AS (
    SELECT 
        fi.Player_Id,
        fi.Player_Name,
        fi.Country_Name,

        COUNT(a.Kind_Out) AS dismissals,
        SUM(CASE WHEN a.Kind_Out = 1 THEN 1 ELSE 0 END) AS catch,
        SUM(CASE WHEN a.Kind_Out = 3 THEN 1 ELSE 0 END) AS run_out,
        SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) AS stumping

    FROM Wicket_Taken a

    JOIN fielder_info fi
        ON a.Fielders = fi.Player_Id

    WHERE a.Kind_Out IN (1, 3, 6)

    GROUP BY 
        fi.Player_Id,
        fi.Player_Name,
        fi.Country_Name

    HAVING SUM(CASE WHEN a.Kind_Out = 6 THEN 1 ELSE 0 END) != 0
)

SELECT 
    Player_Name,
    Country_Name,
    dismissals,
    catch,
    run_out,
    stumping
FROM wicketkeeper_stats

ORDER BY dismissals DESC;

-- -- Captain Statistics
-- # Most successful captains of IPL
WITH captain_matches AS (
    SELECT 
        Match_Id,
        Team_Id,
        Player_Id
    FROM Player_Match
    WHERE Role_Id IN (1,4)
),

match_result AS (
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
),

player_info AS (
    SELECT 
        p.Player_Id,
        p.Player_Name,
        c.Country_Name
    FROM Player p
    JOIN Country c
        ON p.Country_Name = c.Country_Id
),

captain_stats AS (
    SELECT 
        pi.Player_Id,
        pi.Player_Name,
        pi.Country_Name,

        COUNT(*) AS Matches,

        SUM(CASE WHEN cm.Team_Id = mr.Winner THEN 1 ELSE 0 END) AS Wins,

        ROUND(
            SUM(CASE WHEN cm.Team_Id = mr.Winner THEN 1 ELSE 0 END) 
            / COUNT(*), 2
        ) AS Win_perc,

        SUM(CASE WHEN cm.Team_Id = mr.Winner THEN mr.chasing ELSE 0 END) AS chasing_wins,
        SUM(CASE WHEN cm.Team_Id != mr.Winner THEN mr.defending ELSE 0 END) AS defending_losses,

        SUM(CASE WHEN cm.Team_Id = mr.Winner THEN mr.defending ELSE 0 END) AS defending_wins,
        SUM(CASE WHEN cm.Team_Id != mr.Winner THEN mr.chasing ELSE 0 END) AS chasing_losses

    FROM captain_matches cm

    LEFT JOIN match_result mr
        ON cm.Match_Id = mr.Match_Id

    JOIN player_info pi
        ON cm.Player_Id = pi.Player_Id

    GROUP BY 
        pi.Player_Id,
        pi.Player_Name,
        pi.Country_Name
)

SELECT 
    Player_Name AS Captain,
    Country_Name,
    Matches,
    Wins,
    Win_perc,

    ROUND(
        chasing_wins / NULLIF(chasing_wins + defending_losses, 0),
    2) AS Chasing_perc,

    ROUND(
        defending_wins / NULLIF(defending_wins + chasing_losses, 0),
    2) AS Defending_perc

FROM captain_stats

WHERE Matches >= 30

ORDER BY 
    Win_perc DESC,
    Chasing_perc DESC,
    Defending_perc DESC;

-- Team Statistics
-- Best Team in IPL -- error 
WITH franchise_mapping AS (
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
),

team_stats AS (
    SELECT 
        t.Team_Id,
        t.Team_Name AS franchise,

        COUNT(x.Match_Id) AS matches,

        SUM(CASE WHEN x.Win_Type = 1 THEN 1 ELSE 0 END) AS wins,

        ROUND(
            SUM(CASE WHEN x.Win_Type = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(x.Match_Id), 0),
        2) AS win_percentage

    FROM franchise_mapping x

    JOIN Team t
        ON x.Team_Id = t.Team_Id

    GROUP BY t.Team_Id, t.Team_Name
)

SELECT 
    franchise,
    matches,
    wins,
    win_percentage

FROM team_stats

ORDER BY win_percentage DESC;

-- -- # best team in chasing the score
WITH franchise_mapping AS (
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
),

team_stats AS (
    SELECT 
        franchise,
        COUNT(Match_Id) AS matches,

        SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END) AS wins,

        ROUND(
            SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(Match_Id), 0),
        2) AS win_percentage

    FROM franchise_mapping
    GROUP BY franchise
)

SELECT 
    franchise,
    matches,
    wins,
    win_percentage
FROM team_stats
ORDER BY win_percentage DESC;

-- Best Team in IPL
WITH

-- 🔹 Matches where Team_1 played
team1_matches AS (
    SELECT Team_1 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Team_1
),

-- 🔹 Matches where Team_2 played
team2_matches AS (
    SELECT Team_2 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Team_2
),

-- 🔹 Wins
team_wins AS (
    SELECT Match_Winner AS Team_Id, COUNT(*) AS Wins
    FROM `Match`
    WHERE Match_Winner IS NOT NULL
    GROUP BY Match_Winner
),

-- 🔹 Defending performance
defending_cte AS (
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
),

-- 🔹 Chasing performance
chasing_cte AS (
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
)

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

LEFT JOIN team1_matches a
    ON f.Team_Id = a.Team_Id

LEFT JOIN team2_matches b
    ON f.Team_Id = b.Team_Id

LEFT JOIN team_wins c
    ON f.Team_Id = c.Team_Id

LEFT JOIN defending_cte d
    ON f.Team_Id = d.franchise

LEFT JOIN chasing_cte e
    ON f.Team_Id = e.franchise

ORDER BY 
    Win_perc DESC,
    Chasing_perc DESC,
    Defending_perc DESC;
    
-- IPL SEASONS BEST PLAYER
WITH season_base AS (
    SELECT 
        Season_Id,
        Season_Year,
        Man_of_the_Series,
        Orange_Cap,
        Purple_Cap
    FROM Season
),

man_of_season AS (
    SELECT 
        Player_Id,
        Player_Name
    FROM Player
),

top_scorer AS (
    SELECT 
        Player_Id,
        Player_Name
    FROM Player
),

top_wicket_taker AS (
    SELECT 
        Player_Id,
        Player_Name
    FROM Player
)

SELECT 
    s.Season_Year,
    b.Player_Name AS Man_of_Season,
    c.Player_Name AS Top_Scorer,
    d.Player_Name AS Top_Wicket_Tacker

FROM season_base s

JOIN man_of_season b
    ON s.Man_of_the_Series = b.Player_Id

JOIN top_scorer c
    ON s.Orange_Cap = c.Player_Id

JOIN top_wicket_taker d
    ON s.Purple_Cap = d.Player_Id;
    
-- # IPL Season's Winners,Runners Up, Win Type
WITH final_match AS (
    SELECT 
        Season_Id,
        MAX(Match_Id) AS Final_Match_Id
    FROM `Match`
    GROUP BY Season_Id
),

match_detail AS (
    SELECT 
        m.Match_Id,
        m.Season_Id,
        m.Team_1,
        m.Team_2,
        m.Match_Winner
    FROM `Match` m
),

team_info AS (
    SELECT 
        Team_Id,
        Team_Name
    FROM Team
)

SELECT 
    s.Season_Year,
    w.Team_Name AS Winner,
    r.Team_Name AS Runner_Up

FROM Season s

JOIN final_match f
    ON s.Season_Id = f.Season_Id

JOIN match_detail m
    ON m.Match_Id = f.Final_Match_Id

JOIN team_info w
    ON m.Match_Winner = w.Team_Id

JOIN team_info r
    ON CASE 
        WHEN m.Team_1 = m.Match_Winner THEN m.Team_2
        ELSE m.Team_1
    END = r.Team_Id;
    
-- Runs scored in powerplay,middle and death overs in different seasons of
-- IPL
WITH match_info AS (
    SELECT 
        Match_Id,
        Season_Id
    FROM `Match`
),

season_info AS (
    SELECT 
        Season_Id,
        Season_Year
    FROM Season
),

season_matches AS (
    SELECT 
        Season_Id,
        COUNT(Match_Id) AS Matches
    FROM `Match`
    GROUP BY Season_Id
),

ball_runs AS (
    SELECT 
        a.Match_Id,
        a.Innings_No,
        a.Over_Id,
        a.Runs_Scored,
        COALESCE(c.Extra_Runs, 0) AS Extra_Runs
    FROM Batsman_Scored a
    LEFT JOIN Extra_Runs c
        ON a.Match_Id = c.Match_Id
        AND a.Innings_No = c.Innings_No
        AND a.Over_Id = c.Over_Id
        AND a.Ball_Id = c.Ball_Id
),

joined_data AS (
    SELECT 
        b.Season_Id,
        b.Match_Id,
        br.Over_Id,
        (br.Runs_Scored + br.Extra_Runs) AS total_runs
    FROM match_info b
    JOIN ball_runs br
        ON b.Match_Id = br.Match_Id
)

SELECT 
    s.Season_Year,
    m.Matches,

    SUM(CASE 
            WHEN j.Over_Id <= 6 
            THEN j.total_runs ELSE 0 
        END) AS powerplay,

    SUM(CASE 
            WHEN j.Over_Id > 6 AND j.Over_Id <= 15 
            THEN j.total_runs ELSE 0 
        END) AS middleovers,

    SUM(CASE 
            WHEN j.Over_Id > 15 
            THEN j.total_runs ELSE 0 
        END) AS deathovers

FROM joined_data j

JOIN season_info s
    ON j.Season_Id = s.Season_Id

JOIN season_matches m
    ON j.Season_Id = m.Season_Id

GROUP BY 
    s.Season_Year,
    m.Matches;

-- -- #highest score of a Season 
-- problem is not get the highest we have to rank and generate a code
WITH extra_runs_cte AS (
    SELECT 
        Match_Id,
        Innings_No,
        SUM(Extra_Runs) AS extra
    FROM Extra_Runs
    GROUP BY Match_Id, Innings_No
),

match_base AS (
    SELECT 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,
        b.Team_1,
        b.Team_2,
        b.Toss_Winner,
        b.Toss_Decide,
        a.Runs_Scored,
        COALESCE(e.extra, 0) AS extra_runs
    FROM Batsman_Scored a
    JOIN `Match` b
        ON a.Match_Id = b.Match_Id
    LEFT JOIN extra_runs_cte e
        ON a.Match_Id = e.Match_Id
        AND a.Innings_No = e.Innings_No
),

score_cte AS (
    SELECT 
        Match_Id,
        Innings_No,
        Season_Id,
        Venue_Id,

        SUM(Runs_Scored) + MAX(extra_runs) AS Score,

        CASE 
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_2
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_1
            WHEN Toss_Winner = Team_2 AND Toss_Decide = 1 THEN Team_1
            ELSE Team_2
        END AS batting_team_id,

        CASE 
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_1
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_2
            WHEN Toss_Winner = Team_2 AND Toss_Decide = 1 THEN Team_2
            ELSE Team_1
        END AS fielding_team_id

    FROM match_base
    GROUP BY 
        Match_Id,
        Innings_No,
        Season_Id,
        Venue_Id,
        Team_1,
        Team_2,
        Toss_Winner,
        Toss_Decide
),

season_info AS (
    SELECT Season_Id, Season_Year FROM Season
),

team_info AS (
    SELECT Team_Id, Team_Name FROM Team
),

venue_info AS (
    SELECT v.Venue_Id, c.City_Name
    FROM Venue v
    JOIN City c ON v.City_Id = c.City_Id
)

SELECT 
    s.Season_Year,

    CASE 
        WHEN sc.Innings_No = 1 THEN bt.Team_Name
        ELSE ft.Team_Name
    END AS batting_team,

    CASE 
        WHEN sc.Innings_No = 1 THEN ft.Team_Name
        ELSE bt.Team_Name
    END AS fielding_team,

    sc.Score,
    v.City_Name

FROM score_cte sc

JOIN season_info s
    ON sc.Season_Id = s.Season_Id

JOIN team_info bt
    ON sc.batting_team_id = bt.Team_Id

JOIN team_info ft
    ON sc.fielding_team_id = ft.Team_Id

JOIN venue_info v
    ON sc.Venue_Id = v.Venue_Id;
    
-- - #Lowest score of a Season 
-- same problem we have to add the rank and extract 
WITH extra_runs_cte AS (
    SELECT 
        Match_Id,
        Innings_No,
        SUM(Extra_Runs) AS extra
    FROM Extra_Runs
    GROUP BY Match_Id, Innings_No
),

match_base AS (
    SELECT 
        a.Match_Id,
        a.Innings_No,
        b.Season_Id,
        b.Venue_Id,
        b.Team_1,
        b.Team_2,
        b.Toss_Winner,
        b.Toss_Decide,
        b.Win_Type,
        a.Runs_Scored,
        COALESCE(e.extra, 0) AS extra_runs
    FROM Batsman_Scored a
    JOIN `Match` b
        ON a.Match_Id = b.Match_Id
    LEFT JOIN extra_runs_cte e
        ON a.Match_Id = e.Match_Id
        AND a.Innings_No = e.Innings_No
),

score_cte AS (
    SELECT 
        Match_Id,
        Innings_No,
        Season_Id,
        Venue_Id,

        (SUM(Runs_Scored) + MAX(extra_runs)) AS Score,

        CASE 
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_2
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_1
            WHEN Toss_Winner = Team_2 AND Toss_Decide = 1 THEN Team_1
            ELSE Team_2
        END AS batting_team_id,

        CASE 
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 1 THEN Team_1
            WHEN Toss_Winner = Team_1 AND Toss_Decide = 2 THEN Team_2
            WHEN Toss_Winner = Team_2 AND Toss_Decide = 1 THEN Team_2
            ELSE Team_1
        END AS fielding_team_id

    FROM match_base
    WHERE Win_Type NOT IN (3,4)
    GROUP BY 
        Match_Id,
        Innings_No,
        Season_Id,
        Venue_Id,
        Team_1,
        Team_2,
        Toss_Winner,
        Toss_Decide
),

season_cte AS (
    SELECT Season_Id, Season_Year FROM Season
),

team_cte AS (
    SELECT Team_Id, Team_Name FROM Team
),

venue_cte AS (
    SELECT v.Venue_Id, c.City_Name
    FROM Venue v
    JOIN City c
        ON v.City_Id = c.City_Id
)

SELECT 
    s.Season_Year,

    CASE 
        WHEN sc.Innings_No = 1 THEN bt.Team_Name
        ELSE ft.Team_Name
    END AS batting_team,

    CASE 
        WHEN sc.Innings_No = 1 THEN ft.Team_Name
        ELSE bt.Team_Name
    END AS fielding_team,

    sc.Score,
    v.City_Name

FROM score_cte sc

JOIN season_cte s
    ON sc.Season_Id = s.Season_Id

JOIN team_cte bt
    ON sc.batting_team_id = bt.Team_Id

JOIN team_cte ft
    ON sc.fielding_team_id = ft.Team_Id

JOIN venue_cte v
    ON sc.Venue_Id = v.Venue_Id;
    
-- -- # Season Wise Team Performance
WITH

-- 🔹 Matches where Team_1 played
team1_matches AS (
    SELECT Season_Id, Team_1 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Season_Id, Team_1
),

-- 🔹 Matches where Team_2 played
team2_matches AS (
    SELECT Season_Id, Team_2 AS Team_Id, COUNT(*) AS matches
    FROM `Match`
    GROUP BY Season_Id, Team_2
),

-- 🔹 Wins per season
season_wins AS (
    SELECT Season_Id, Match_Winner AS Team_Id, COUNT(*) AS Wins
    FROM `Match`
    WHERE Match_Winner IS NOT NULL
    GROUP BY Season_Id, Match_Winner
),

-- 🔹 Defending performance base
defending_base AS (
    SELECT 
        Season_Id,
        franchise,
        Win_Type
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
),

defending_cte AS (
    SELECT 
        Season_Id,
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
        2) AS Defending_perc
    FROM defending_base
    GROUP BY Season_Id, franchise
),

-- 🔹 Chasing performance base
chasing_base AS (
    SELECT 
        Season_Id,
        franchise,
        Win_Type
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
),

chasing_cte AS (
    SELECT 
        Season_Id,
        franchise,
        ROUND(
            SUM(CASE WHEN Win_Type = 2 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0),
        2) AS Chasing_perc
    FROM chasing_base
    GROUP BY Season_Id, franchise
)

-- 🔹 FINAL RESULT
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
CROSS JOIN Season g

LEFT JOIN team1_matches a
    ON f.Team_Id = a.Team_Id
    AND g.Season_Id = a.Season_Id

LEFT JOIN team2_matches b
    ON f.Team_Id = b.Team_Id
    AND g.Season_Id = b.Season_Id

LEFT JOIN season_wins c
    ON f.Team_Id = c.Team_Id
    AND g.Season_Id = c.Season_Id

LEFT JOIN defending_cte d
    ON f.Team_Id = d.franchise
    AND g.Season_Id = d.Season_Id

LEFT JOIN chasing_cte e
    ON f.Team_Id = e.franchise
    AND g.Season_Id = e.Season_Id

ORDER BY 
    g.Season_Id,
    Matches DESC,
    Wins DESC,
    Chasing_perc DESC;