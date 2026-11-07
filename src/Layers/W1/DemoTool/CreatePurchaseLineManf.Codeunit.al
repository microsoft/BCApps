codeunit 119066 "Create Purchase Line Manf"
{

    trigger OnRun()
    begin
        InsertData(1, '1000', 2, '1600', '', 3, 0, 0, '', '');
    end;

    var
        "Purchase Line": Record "Purchase Line";
        "Line No.": Integer;
        "Previous Document No.": Code[20];

    procedure InsertData("Document Type": Integer; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; "Location Code": Code[10]; Quantity: Decimal; "FA Posting Type": Integer; "Direct Unit Cost": Decimal; "Insurance No.": Code[20]; "Maintenance Code": Code[20])
    begin
        "Purchase Line".Init();
        "Purchase Line".Validate("Document Type", "Document Type");
        "Purchase Line".Validate("Document No.", "Document No.");

        case "Previous Document No." of
            "Document No.":
                begin
                    "Line No." := "Line No." + 10000;
                    "Purchase Line".Validate("Line No.", "Line No.");
                end;
            else begin
                    "Line No." := 10000;
                    "Previous Document No." := "Document No.";
                    "Purchase Line".Validate("Line No.", "Line No.");
                end;
        end;

        "Purchase Line".Validate(Type, Type);
        "Purchase Line".Validate("No.", "No.");
        "Purchase Line".Validate("Location Code", "Location Code");
        "Purchase Line".Validate(Quantity, Quantity);

        if "FA Posting Type" > 0 then begin
            "Purchase Line".Validate("FA Posting Type", "FA Posting Type");
            "Purchase Line".Validate("Direct Unit Cost", "Direct Unit Cost");
            "Purchase Line".Validate("Insurance No.", "Insurance No.");
            "Purchase Line".Validate("Maintenance Code", "Maintenance Code");
        end;
        "Purchase Line".Insert();
    end;
}

