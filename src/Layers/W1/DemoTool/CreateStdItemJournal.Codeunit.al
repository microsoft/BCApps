codeunit 101762 "Create Std. Item Journal"
{

    trigger OnRun()
    begin
        InsertData(XITEM, XNEW1896S, XProductionofNewAthensDesk);
    end;

    var
        StdItemJournal: Record "Standard Item Journal";
        XNEW1896S: Label 'NEW1896-S';
        XProductionofNewAthensDesk: Label 'Production of New Athens Desk';
        XITEM: Label 'ITEM';

    procedure InsertData(JnlTemplateName: Code[10]; "Code": Code[10]; Description: Text[50])
    begin
        StdItemJournal.Init();
        StdItemJournal.Validate("Journal Template Name", JnlTemplateName);
        StdItemJournal.Validate(Code, Code);
        StdItemJournal.Validate(Description, Description);
        StdItemJournal.Insert();
    end;
}

