USE `appbuilder-admin`;

DROP PROCEDURE IF EXISTS `CLOSE_FP_PROCESS`;

DELIMITER $$
CREATE PROCEDURE `CLOSE_FP_PROCESS` (
    IN FISCAL_PERIOD_UUID varchar(255)
) 
BEGIN
    DECLARE FP_Closed varchar(255) DEFAULT "";
    DECLARE FP_OPEN varchar(255) DEFAULT "1592549785939";
    -- DECLARE FP_Closing varchar(255) DEFAULT "1592549786026";
    -- DECLARE FP_Next_To_Use varchar(255) DEFAULT "1592549785894";
    DECLARE FY_PERIOD varchar(255);
    DECLARE OLD_END_DATE date;
    DECLARE SEARCHDATE date;
    DECLARE NEW_FP varchar(255);
    /* */
    SELECT `FY Per`, `End` 
    INTO FY_PERIOD, OLD_END_DATE
    FROM `AB_AccountingApp_FiscalMonth`
    WHERE `uuid` = FISCAL_PERIOD_UUID
    LIMIT 1;

    UPDATE `AB_AccountingApp_FiscalMonth`
    SET `Open` = 0
    WHERE `uuid` = FISCAL_PERIOD_UUID
    LIMIT 1;

    -- find the next fiscal month(.startDate == my.endDate + 1)
    -- SELECT DATEADD(day, 1, OLD_END_DATE) AS DateAdd INTO SEARCHDATE;
    SELECT `FY Per` INTO NEW_FP
    FROM `AB_AccountingApp_FiscalMonth`
    WHERE `Start` = OLD_END_DATE + interval 1 day
    LIMIT 1;
    -- set open
    UPDATE `AB_AccountingApp_FiscalMonth`
    SET `Open` = 1,
        `Status` = FP_OPEN
    -- WHERE `Start` = DATEADD(day, 1, OLD_END_DATE);
    WHERE `FY Per` LIKE NEW_FP
    LIMIT 1;

    -- INSERT new GLSegment (inc. 3991) 
    INSERT INTO `AB_AccountingApp_GLSegment` (
            `uuid`,
            `Balndx`,
            `FY Period`,
            `COA Num`,
            `RC Code`,
            `Starting Balance`,
            `Credit`,
            `Debit`,
            `Running Balance`
        ) 
        SELECT *
            FROM
        (
            SELECT DISTINCT
                UUID() `uuid`,
                CONCAT (NEW_FP, '-', GL.`COA Num`, '-', GL.`RC Code`) `Balndx`, 
                NEW_FP `FY Period`, -- Next Fiscal Month
                GL.`COA Num`, -- Same as Original Balance Record
                GL.`RC Code`,
                IFNULL(GL.`Running Balance`, 0) `Starting Balance`,
                0 `Credit`,
                0 `Debit`,
                IFNULL(GL.`Running Balance`, 0) `Running Balance`
            FROM
                `AB_AccountingApp_GLSegment` GL
            WHERE
                GL.`FY Period` LIKE FY_PERIOD
        ) r;

END$$
DELIMITER ;