codeunit 119052 "Create Item Journal Line manf."
{

    trigger OnRun()
    begin
        InsertData('1100', 200, '');
        InsertData('1110', 400, '');
        InsertData('1120', 10000, '');
        InsertData('1150', 200, '');
        InsertData('1151', 200, '');
        InsertData('1155', 200, '');
        InsertData('1160', 200, '');
        InsertData('1170', 200, '');
        InsertData('1200', 200, '');
        InsertData('1250', 200, '');
        InsertData('1251', 10000, '');
        InsertData('1255', 200, '');
        InsertData('1300', 200, '');
        InsertData('1310', 100, '');
        InsertData('1320', 100, '');
        InsertData('1330', 100, '');
        InsertData('1400', 200, '');
        InsertData('1450', 200, '');
        InsertData('1500', 200, '');
        InsertData('1600', 200, '');
        InsertData('1700', 200, '');
        InsertData('1710', 200, '');
        InsertData('1720', 200, '');
        InsertData('1800', 200, '');
        InsertData('1850', 200, '');
        InsertData('1900', 200, '');
    end;

    var
        "Item Journal Batch": Record "Item Journal Batch";
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XITEM: Label 'ITEM';
        XDEFAULT: Label 'DEFAULT';
        XSTARTMANF: Label 'START-MANF';

    procedure InsertData("Item No.": Code[20]; Quantity: Decimal; "Location Code": Code[10])
    var
        "Item Journal Line": Record "Item Journal Line";
    begin
        InitItemJnlLine("Item Journal Line", XITEM, XDEFAULT);
        "Item Journal Line".Validate("Item No.", "Item No.");
        "Item Journal Line".Validate("Posting Date", CA.AdjustDate(19020601D));
        "Item Journal Line".Validate("Entry Type", "Item Journal Line"."Entry Type"::"Positive Adjmt.");
        "Item Journal Line".Validate("Document No.", XSTARTMANF);
        "Item Journal Line".Validate(Quantity, Quantity);
        "Item Journal Line".Validate("Location Code", "Location Code");
        "Item Journal Line".Insert(true);
    end;

    procedure InitItemJnlLine(var "Item Journal Line": Record "Item Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    var
        LastItemJournalLine: Record "Item Journal Line";
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

        LastItemJournalLine.Reset();
        LastItemJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        LastItemJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if LastItemJournalLine.FindLast() then
            "Line No." := LastItemJournalLine."Line No." + 10000
        else
            "Line No." := 10000;
        "Item Journal Line".Validate("Line No.", "Line No.");
    end;
}

