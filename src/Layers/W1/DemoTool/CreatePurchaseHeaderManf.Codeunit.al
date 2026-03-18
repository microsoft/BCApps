codeunit 119065 "Create Purchase Header Manf"
{

    trigger OnRun()
    begin
        InsertData(1, '32456123', '1000', 19020819D, '5755', '');
    end;

    var
        "Purchase Header": Record "Purchase Header";
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Document Type": Integer; "Buy-from Vendor No.": Code[20]; ProdOrderNumber: Code[20]; "Posting Date": Date; "Vendor Invoice No.": Code[20]; "Payment Method": Code[10])
    begin
        "Purchase Header".Init();
        "Purchase Header".Validate("Document Type", "Document Type");
        "Purchase Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Purchase Header".Validate("No.", ProdOrderNumber);
        "Purchase Header".Insert(true);
        "Purchase Header".Validate("Buy-from Vendor No.", "Buy-from Vendor No.");
        "Purchase Header".Validate("Posting Date");
        "Purchase Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Expected Receipt Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Document Date", CA.AdjustDate("Posting Date"));
        case "Document Type" of
            1, 2:
                "Purchase Header".Validate("Vendor Invoice No.", "Vendor Invoice No.");
            3:
                "Purchase Header".Validate("Vendor Cr. Memo No.", "Vendor Invoice No.");
        end;

        if "Payment Method" <> '' then
            "Purchase Header".Validate("Payment Method Code", "Payment Method");
        "Purchase Header".Modify();
    end;
}

