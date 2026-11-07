codeunit 101763 "Create Std. Item Journal Line"
{

    trigger OnRun()
    begin
        LineNo := 0;
        InsertData(XITEM, XNEW1896S, '1896-S', 2, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70000', 3, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70001', 3, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70002', 3, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70003', 3, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70010', 3, 1, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70040', 3, 2, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70200', 3, 3, XProductionofNewAthensDesk, XPROD);
        InsertData(XITEM, XNEW1896S, '70201', 3, 1, XProductionofNewAthensDesk, XPROD);
    end;

    var
        StdItemJnlLine: Record "Standard Item Journal Line";
        XITEM: Label 'ITEM';
        XNEW1896S: Label 'NEW1896-S';
        XProductionofNewAthensDesk: Label 'Production of New Athens Desk';
        XPROD: Label 'PROD';
        LineNo: Integer;

    procedure InsertData(JournalTemplateName: Code[10]; StdItemJnlCode: Code[10]; "No.": Code[20]; EntryType: Integer; Quantity: Decimal; Description: Text[50]; Department: Code[20])
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        StdItemJnlLine.Init();
        StdItemJnlLine."Line No." := 0;
        StdItemJnlLine.Validate("Journal Template Name", JournalTemplateName);
        ItemJnlTemplate.Get(JournalTemplateName);
        StdItemJnlLine.Validate("Source Code", ItemJnlTemplate."Source Code");
        StdItemJnlLine.Validate("Standard Journal Code", StdItemJnlCode);
        StdItemJnlLine.Validate("Item No.", "No.");
        StdItemJnlLine.Validate("Entry Type", EntryType);
        if Quantity <> 0 then
            StdItemJnlLine.Validate(Quantity, Quantity);
        if Department <> '' then
            StdItemJnlLine.Validate("Shortcut Dimension 1 Code", Department);
        StdItemJnlLine.Validate(Description, Description);
        LineNo := LineNo + 10000;
        StdItemJnlLine."Line No." := LineNo;
        StdItemJnlLine.Insert(true);
    end;
}

