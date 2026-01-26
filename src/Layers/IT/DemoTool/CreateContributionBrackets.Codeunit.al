codeunit 161308 "Create Contribution Brackets"
{

    trigger OnRun()
    begin
        InsertData(XxA2000P, XBracketsYear2000, ContributionBracket."Contribution Type"::INPS);
        InsertData(XxA2000V, XBracketsYear2000Lawy, ContributionBracket."Contribution Type"::INPS);
    end;

    var
        XxA2000P: Label 'A2000P';
        XBracketsYear2000: Label 'Brackets Year 2000';
        XxA2000V: Label 'A2000V';
        XBracketsYear2000Lawy: Label 'Brackets Year 2000 Lawy.';
        ContributionBracket: Record "Contribution Bracket";

    procedure InsertData("Code": Code[10]; Description: Text[30]; ContributionType: Option)
    begin
        ContributionBracket.Init();
        ContributionBracket.Validate(Code, Code);
        ContributionBracket.Validate(Description, Description);
        ContributionBracket.Validate("Contribution Type", ContributionType);
        ContributionBracket.Insert();
    end;
}

