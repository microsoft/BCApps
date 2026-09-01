codeunit 118847 "Create Dist. Item Journal"
{

    trigger OnRun()
    begin
        InsertData('LS-75', 12, XWHITE, '');
        InsertData('LS-120', 6, XWHITE, '');
        InsertData('LS-150', 7, XWHITE, '');
        InsertData('LS-10PC', 38, XWHITE, '');
        InsertData('LS-MAN-10', 100, XWHITE, '');
        InsertData('LS-2', 200, XWHITE, '');
        InsertData('LS-S15', 60, XWHITE, '');
        InsertData('LS-150', 1, XWHITE, '');
        InsertData('LS-MAN-10', 40, XWHITE, '');
        InsertData('LS-100', 32, XWHITE, '');
        InsertData('LSU-15', 28, XWHITE, '');
        InsertData('LSU-8', 15, XWHITE, '');
        InsertData('LSU-4', 100, XWHITE, '');
        InsertData('FF-100', 42, XWHITE, '');
        InsertData('C-100', 33, XWHITE, '');
        InsertData('HS-100', 56, XWHITE, '');
        InsertData('SPK-100', 78, XWHITE, '');
        InsertData('LS-75', 11, XBLUE, '');
        InsertData('LS-120', 13, XGREEN, '');
    end;

    var
        BlankItemJnlLine: Record "Item Journal Line";
        "Item Journal Batch": Record "Item Journal Batch";
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XWHITE: Label 'WHITE';
        XBLUE: Label 'BLUE';
        XGREEN: Label 'GREEN';
        XITEM: Label 'ITEM';
        XDEFAULT: Label 'DEFAULT';
        XSTART: Label 'START';

    procedure InsertData("Item No.": Code[20]; Quantity: Decimal; "Location Code": Code[10]; "Bin Code": Code[20])
    var
        "Item Journal Line": Record "Item Journal Line";
    begin
        InitItemJnlLine("Item Journal Line", XITEM, XDEFAULT);
        "Item Journal Line".Validate("Item No.", "Item No.");
        "Item Journal Line".Validate("Posting Date", CA.AdjustDate(19030126D));
        "Item Journal Line".Validate("Entry Type", "Item Journal Line"."Entry Type"::"Positive Adjmt.");
        "Item Journal Line".Validate("Document No.", XSTART);
        "Item Journal Line".Validate(Quantity, Quantity);
        "Item Journal Line".Validate("Location Code", "Location Code");
        if "Bin Code" <> '' then
            "Item Journal Line".Validate("Bin Code", "Bin Code");
        "Item Journal Line".Insert(true);
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

