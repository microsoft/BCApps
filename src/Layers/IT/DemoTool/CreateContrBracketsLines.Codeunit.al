codeunit 161309 "Create Contr. Brackets Lines"
{

    trigger OnRun()
    begin
        InsertData(XxA2000P, 51000, 95, ContributionBracketLine."Contribution Type"::INPS);
        InsertData(XxA2000P, 65000, 100, ContributionBracketLine."Contribution Type"::INPS);
        InsertData(XxA2000V, 65000, 100, ContributionBracketLine."Contribution Type"::INPS);
    end;

    var
        XxA2000P: Label 'A2000P';
        XxA2000V: Label 'A2000V';
        ContributionBracketLine: Record "Contribution Bracket Line";

    procedure InsertData("Code": Code[10]; Amount: Decimal; TaxableBasePercent: Decimal; ContributionType: Option)
    begin
        ContributionBracketLine.Init();
        ContributionBracketLine.Validate(Code, Code);
        ContributionBracketLine.Validate(Amount, Amount);
        ContributionBracketLine.Validate("Taxable Base %", TaxableBasePercent);
        ContributionBracketLine.Validate("Contribution Type", ContributionType);
        ContributionBracketLine.Insert();
    end;
}

