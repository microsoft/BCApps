codeunit 101083 "Create Item Journal Line"
{

    trigger OnRun()
    begin
        InsertData('1968-S', 236, XBLUE);
        InsertData('1968-S', 28, XRED);
        InsertData('1968-S', 14, XGREEN);
        InsertData('1972-S', 37, XBLUE);
        InsertData('1972-S', 5, XRED);
        InsertData('1972-S', 90, XYELLOW);
        InsertData('1908-S', 234, XBLUE);
        InsertData('1908-S', 5, XRED);
        InsertData('1908-S', 47, XGREEN);
        InsertData('1980-S', 65, XBLUE);
        InsertData('1980-S', 24, XRED);
        InsertData('1980-S', 14, XGREEN);
        InsertData('2000-S', 134, XBLUE);
        InsertData('2000-S', 12, XRED);
        InsertData('2000-S', 17, XGREEN);
        InsertData('1900-S', 52, XBLUE);
        InsertData('1900-S', 46, XRED);
        InsertData('1900-S', 47, XGREEN);
        InsertData('1936-S', 36, XBLUE);
        InsertData('1936-S', 50, XRED);
        InsertData('1936-S', 50, XGREEN);
        InsertData('1964-S', 59, XBLUE);
        InsertData('1964-S', 29, XRED);
        InsertData('1964-S', 71, XGREEN);
        InsertData('1988-S', 43, XYELLOW);
        InsertData('1988-S', 41, XBLUE);
        InsertData('1988-S', 83, XGREEN);
        InsertData('1960-S', 136, XBLUE);
        InsertData('1960-S', 32, XRED);
        InsertData('1960-S', 17, XBLUE);
        InsertData('1896-S', 160, XYELLOW);
        InsertData('1896-S', 52, XRED);
        InsertData('1896-S', 49, XGREEN);
        InsertData('1906-S', 70, XBLUE);
        InsertData('1906-S', 63, XRED);
        InsertData('1906-S', 108, XGREEN);
        InsertData('1928-S', 97, XYELLOW);

        InsertData('1928-S', 56 + 1, XRED);
        InsertData('1928-S', 149, XBLUE);
        InsertData('1920-S', 38, XBLUE);
        InsertData('1920-S', 8, XRED);
        InsertData('1920-S', 67, XGREEN);
        InsertData('1996-S', 116, XYELLOW);
        InsertData('1996-S', 29, XRED);
        InsertData('1996-S', 44, XBLUE);
        InsertData('1972-W', 4, XBLUE);
        InsertData('1972-W', 5, XRED);
        InsertData('1972-W', 2, XGREEN);
        InsertData('1988-W', 13, XYELLOW);
        InsertData('1988-W', 5, XRED);
        InsertData('1988-W', 9, XGREEN);
        InsertData('1984-W', 3, XBLUE);
        InsertData('1984-W', 4, XRED);
        InsertData('1984-W', 3, XGREEN);
        InsertData('1968-W', 10, XYELLOW);
        InsertData('1968-W', 6, XRED);
        InsertData('1968-W', 4, XGREEN);
        InsertData('1992-W', 6, XBLUE);
        InsertData('1992-W', 5, XGREEN);
        InsertData('766BC-C', 1, XRED);
        InsertData('766BC-C', 2, XBLUE);
        InsertData('766BC-B', 1, XYELLOW);
        InsertData('766BC-B', 1, XRED);
        InsertData('766BC-B', 3, XBLUE);
        InsertData('766BC-A', 2, XGREEN);
        InsertData('1924-W', 1, XBLUE);
        InsertData('1924-W', 2, XRED);
        InsertData('1924-W', 3, XGREEN);
        InsertData('1952-W', 2, XRED);
        InsertData('1952-W', 2, XBLUE);
        InsertData('1928-W', 4, XBLUE);
        InsertData('1928-W', 4, XGREEN);
        InsertData('1976-W', 3, XYELLOW);
        InsertData('1976-W', 3, XRED);
        InsertData('1976-W', 3, XBLUE);
        InsertData('1964-W', 6, XBLUE);
        InsertData('1964-W', 5, XGREEN);
        InsertData('70000', 2187 + 15 - 2, XBLUE);
        InsertData('70001', 2310 + 15, XBLUE);
        InsertData('70002', 2496 + 15, XBLUE);
        InsertData('70003', 2110 + 15, XBLUE);
        InsertData('70010', 2255 + 15, XBLUE);
        InsertData('70011', 2150 + 15, XBLUE);
        InsertData('70040', 2206 + 15, XBLUE);
        InsertData('70041', 2009 + 15, XBLUE);
        InsertData('70060', 63 + 20, XBLUE);
        InsertData('70100', 3621 + 20 + 21, XBLUE);
        InsertData('70101', 3698 + 20 - 15, XBLUE);
        InsertData('70102', 3211 + 20 - 6, XBLUE);
        InsertData('70103', 3006 + 20 + 8, XBLUE);
        InsertData('70104', 2981 + 7 - 2, XBLUE);
        InsertData('70200', 1599 + 32 + 12, XBLUE);
        InsertData('70201', 1239 + 21 - 5, XBLUE);

        InsertDataExtended('1896-S', 1, XGREEN, BlankItemJnlLine."Entry Type"::"Negative Adjmt.", XUNBOX, 19030102D, CreateUnitOfMeasure.GetBoxUnitOfMeasureCode());
        InsertDataExtended('1896-S', 4, XGREEN, BlankItemJnlLine."Entry Type"::"Positive Adjmt.", XUNBOX, 19030102D, CreateUnitOfMeasure.GetPcsUnitOfMeasureCode());
    end;

    var
        BlankItemJnlLine: Record "Item Journal Line";
        "Item Journal Batch": Record "Item Journal Batch";
        CA: Codeunit "Make Adjustments";
        CreateUnitOfMeasure: Codeunit "Create Unit of Measure";
        "Line No.": Integer;
        XBLUE: Label 'BLUE';
        XRED: Label 'RED';
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XITEM: Label 'ITEM';
        XDEFAULT: Label 'DEFAULT';
        XSTART: Label 'START';
        XUNBOX: Label 'UNBOX';

    procedure InsertData("Item No.": Code[20]; Quantity: Decimal; "Location Code": Code[10])
    var
        "Item Journal Line": Record "Item Journal Line";
    begin
        InitItemJnlLine("Item Journal Line", XITEM, XDEFAULT);
        "Item Journal Line".Validate("Item No.", "Item No.");
        "Item Journal Line".Validate("Posting Date", CA.AdjustDate(19021231D));
        "Item Journal Line".Validate("Entry Type", "Item Journal Line"."Entry Type"::"Positive Adjmt.");
        "Item Journal Line".Validate("Document No.", XSTART);
        "Item Journal Line".Validate(Quantity, Quantity);
        "Item Journal Line".Validate("Location Code", "Location Code");
        "Item Journal Line".Insert(true);
    end;

    local procedure InsertDataExtended("Item No.": Code[20]; Quantity: Decimal; "Location Code": Code[10]; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; PostingDate: Date; UnitOfMeasureCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        InitItemJnlLine(ItemJournalLine, XITEM, XDEFAULT);
        ItemJournalLine.Validate("Item No.", "Item No.");
        ItemJournalLine.Validate("Posting Date", CA.AdjustDate(PostingDate));
        ItemJournalLine.Validate("Entry Type", EntryType);
        ItemJournalLine.Validate("Document No.", DocumentNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ItemJournalLine.Validate("Location Code", "Location Code");
        ItemJournalLine.Insert(true);
    end;

    procedure InitItemJnlLine(var "Item Journal Line": Record "Item Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        "Item Journal Line".Init();
        "Item Journal Line".Validate("Journal Template Name", "Journal Template Name");
        "Item Journal Line".Validate("Journal Batch Name", "Journal Batch Name");
        if ("Journal Template Name" <> "Item Journal Batch"."Journal Template Name") or
           ("Journal Batch Name" <> "Item Journal Batch".Name)
        then begin
            "Item Journal Batch".Get("Journal Template Name", "Journal Batch Name");
            if ("Item Journal Batch"."No. Series" <> '') or
               ("Item Journal Batch"."Posting No. Series" <> '')
            then begin
                "Item Journal Batch"."No. Series" := '';
                "Item Journal Batch"."Posting No. Series" := '';
                "Item Journal Batch".Modify();
            end;
        end;
        "Line No." := "Line No." + 10000;
        "Item Journal Line".Validate("Line No.", "Line No.");
        "Item Journal Line".SetUpNewLine(BlankItemJnlLine);
    end;
}

