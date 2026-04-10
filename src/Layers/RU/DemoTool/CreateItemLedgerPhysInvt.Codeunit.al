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
        CalcQty.InitializeRequest(CA.AdjustDate(19021231D), XPHYS1, false, false);
        CalcQty.UseRequestPage(false);
        CalcQty.RunModal();

        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", XPHYSINV);
        ItemJournalLine.SetRange("Journal Batch Name", XDEFAULT);
        ItemJournalLine.SetFilter("Location Code", '<> %1', XBLUE);
        ItemJournalLine.DeleteAll();
        ItemJournalLine.SetRange("Location Code", XBLUE);
        ItemJournalLine.SetRange("Item No.", '70000', '70299');
        ItemJournalLine.DeleteAll();
        ItemJournalLine.SetRange("Item No.", '1900-S', '766BC-C');
        ItemJournalLine.DeleteAll();

        ModifyData(XMAT + '-002', '', '', XBLUE, -2, XEXP + '_94');
        ModifyData(XITE + '-021', '', '', XBLUE, -5, XEXP + '_94');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLEntry: Record "G/L Entry";
        "Line No.": Integer;
        CalcQty: Report "Calculate Inventory";
        XPHYS1: Label 'PHYS1';
        XBLUE: Label 'BLUE';
        XDEFAULT: Label 'DEFAULT';
        XPHYSINV: Label 'PHYS. INV.';
        XMAT: Label 'MAT';
        XITE: Label 'ITE';
        CA: Codeunit "Make Adjustments";
        XEXP: Label 'EXP';

    procedure ModifyData("Item No.": Code[20]; "Shortcut Dimension 1": Code[20]; "Shortcut Dimension 2": Code[20]; Location: Code[10]; Quantity: Decimal; "Gen. Bus. Posting Group": Code[20])
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
            ItemJournalLine.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
            ItemJournalLine.Validate("Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Phys. Inventory)" + Quantity);
            ItemJournalLine.Modify();
        end else
            Message(
              'Create Item Ledger,Phys. Invt., Item No. %1, No changes in quantity, caused by no Item Journal Lines.',
              "Item No.");
    end;
}

