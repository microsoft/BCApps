codeunit 101281 "Create Item Ledger,Phys. Invt."
{
    // This codeunit should maybe be a part of the Item Journal Line Codeunit, 101083,
    // but this is made to make physical inventories, and therefore, it is made
    // seperately.


    trigger OnRun()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        DemoDataSetup.Get();
        GLEntry.Reset();
        GLEntry.FindLast();

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", XPHYSINV);
        ItemJournalLine.Validate("Journal Batch Name", XDEFAULT);
        "Line No." := "Line No." + 10000;
        ItemJournalLine.Validate("Line No.", "Line No.");

        Clear(CalcQty);
        CalcQty.SetItemJnlLine(ItemJournalLine);
        CalcQty.InitializeRequest(GLEntry."Posting Date", XPHYS1, false, false);
        CalcQty.UseRequestPage(false);
        CalcQty.RunModal();

        ModifyData('70000', '', '', XBLUE, 2);
        ModifyData('70100', '', '', XBLUE, -21);
        ModifyData('70101', '', '', XBLUE, 15);
        ModifyData('70102', '', '', XBLUE, 6);
        ModifyData('70103', '', '', XBLUE, -8);
        ModifyData('70104', '', '', XBLUE, 2);
        ModifyData('70200', '', '', XBLUE, -12);
        ModifyData('70201', '', '', XBLUE, 5);
        ModifyData('1928-S', '', '', XRED, -1);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLEntry: Record "G/L Entry";
        "Line No.": Integer;
        CalcQty: Report "Calculate Inventory";
        XPHYS1: Label 'PHYS1';
        XBLUE: Label 'BLUE';
        XRED: Label 'RED';
        XDEFAULT: Label 'DEFAULT';
        XPHYSINV: Label 'PHYS. INV.';

    procedure ModifyData("Item No.": Code[20]; "Shortcut Dimension 1": Code[20]; "Shortcut Dimension 2": Code[20]; Location: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", XPHYSINV);
        ItemJournalLine.SetRange("Journal Batch Name", XDEFAULT);
        ItemJournalLine.SetRange("Item No.", "Item No.");
        ItemJournalLine.SetRange("Shortcut Dimension 1 Code", "Shortcut Dimension 1");
        ItemJournalLine.SetRange("Shortcut Dimension 2 Code", "Shortcut Dimension 2");
        ItemJournalLine.SetRange("Location Code", Location);
        if ItemJournalLine.FindFirst() then begin
            ItemJournalLine.Validate("Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Phys. Inventory)" + Quantity);
            ItemJournalLine.Modify();
        end else
            Message(
              'Create Item Ledger,Phys. Invt., Item No. %1, No changes in quantity, caused by no Item Journal Lines.',
              "Item No.");
    end;
}

