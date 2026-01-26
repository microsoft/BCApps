codeunit 161307 "Create Contr. Codes Lines"
{

    trigger OnRun()
    begin
        InsertData(XxCONPROV, (20000101D), XxA2000P, 10, 33.33, ContributionCodeLine."Contribution Type"::INPS);
        InsertData(XxCPAV, (20000101D), XxA2000V, 2, 0, ContributionCodeLine."Contribution Type"::INPS);
        InsertData(XxNOPROV, (20000101D), XxA2000P, 10, 33.3333, ContributionCodeLine."Contribution Type"::INPS);
        InsertData(XxNOPROV, (20010101D), XxA2000P, 12, 33.3333, ContributionCodeLine."Contribution Type"::INPS);
    end;

    var
        XxCONPROV: Label 'CONPROV';
        XxA2000P: Label 'A2000P';
        XxCPAV: Label 'CPAV';
        XxA2000V: Label 'A2000V';
        XxNOPROV: Label 'NOPROV';
        ContributionCodeLine: Record "Contribution Code Line";

    procedure InsertData("Code": Code[20]; "Starting Date": Date; "Social Security Bracket Code": Code[10]; "Social Security %": Decimal; "Free-Lance Amount %": Decimal; "Contribution Type": Option)
    begin
        ContributionCodeLine.Init();
        ContributionCodeLine.Validate(Code, Code);
        ContributionCodeLine.Validate("Starting Date", "Starting Date");
        ContributionCodeLine."Social Security Bracket Code" := "Social Security Bracket Code";
        ContributionCodeLine.Validate("Social Security %", "Social Security %");
        ContributionCodeLine.Validate("Free-Lance Amount %", "Free-Lance Amount %");
        ContributionCodeLine.Validate("Contribution Type", "Contribution Type");
        ContributionCodeLine.Insert();
    end;
}

