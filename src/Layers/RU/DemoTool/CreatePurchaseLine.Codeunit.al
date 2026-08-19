codeunit 101039 "Create Purchase Line"
{

    trigger OnRun()
    begin
        // calls of InsertData are moved to codeunit 101038
    end;

    var
        PurchaseLine: Record "Purchase Line";
        "Line No.": Integer;
        "Previous Document No.": Code[20];

    procedure InsertData("Document Type": Enum "Purchase Document Type"; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; "Location Code": Code[10]; Quantity: Decimal; "FA Posting Type": Integer; "Direct Unit Cost": Decimal; "Insurance No.": Code[20]; "Maintenance Code": Code[10]; Dim7Value: Code[20]; Dim8Value: Code[20])
    var
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", "Document Type");
        PurchaseLine.Validate("Document No.", "Document No.");

        case "Previous Document No." of
            "Document No.":
                begin
                    "Line No." := "Line No." + 10000;
                    PurchaseLine.Validate("Line No.", "Line No.");
                end;
            else begin
                "Line No." := 10000;
                "Previous Document No." := "Document No.";
                PurchaseLine.Validate("Line No.", "Line No.");
            end;
        end;

        PurchaseLine.Validate(Type, Type);
        PurchaseLine.Validate("No.", "No.");
        PurchaseLine.Validate("Location Code", "Location Code");
        PurchaseLine.Validate(Quantity, Quantity);

        if Description <> '' then
            PurchaseLine.Description := Description;

        PurchaseLine.Validate("Direct Unit Cost", "Direct Unit Cost");

        if "FA Posting Type" > 0 then begin
            PurchaseLine.Validate("FA Posting Type", "FA Posting Type");
            PurchaseLine.Validate("Direct Unit Cost", "Direct Unit Cost");
            PurchaseLine.Validate("Insurance No.", "Insurance No.");
            PurchaseLine.Validate("Maintenance Code", "Maintenance Code");
        end;
        InterfaceBasisData.AddDocDimValue(PurchaseLine."Dimension Set ID", 7, Dim7Value);
        InterfaceBasisData.AddDocDimValue(PurchaseLine."Dimension Set ID", 8, Dim8Value);
        PurchaseLine.Insert();
    end;

    procedure AddEmplPurchase("Document Type": Enum "Purchase Document Type"; "Document No.": Code[20]; "Vendor No.": Code[20])
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "Document No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Empl. Purchase");
        PurchaseLine.Validate("Empl. Purchase Vendor No.", "Vendor No.");
        PurchaseLine.Modify();
    end;

    procedure InsertData2("Document Type": Enum "Purchase Document Type"; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; "Location Code": Code[10]; Quantity: Decimal; "FA Posting Type": Integer; "Direct Unit Cost": Decimal; "Insurance No.": Code[20]; "Maintenance Code": Code[10]; "Depreciation Book": Code[10]; Dim7Value: Code[20]; Dim8Value: Code[20])
    var
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", "Document Type");
        PurchaseLine.Validate("Document No.", "Document No.");

        case "Previous Document No." of
            "Document No.":
                begin
                    "Line No." := "Line No." + 10000;
                    PurchaseLine.Validate("Line No.", "Line No.");
                end;
            else begin
                "Line No." := 10000;
                "Previous Document No." := "Document No.";
                PurchaseLine.Validate("Line No.", "Line No.");
            end;
        end;

        PurchaseLine.Validate(Type, Type);
        PurchaseLine.Validate("No.", "No.");
        PurchaseLine.Validate("Location Code", "Location Code");
        PurchaseLine.Validate(Quantity, Quantity);

        if Description <> '' then
            PurchaseLine.Description := Description;

        PurchaseLine.Validate("Direct Unit Cost", "Direct Unit Cost");
        PurchaseLine.Validate("Depreciation Book Code", "Depreciation Book");

        if "FA Posting Type" > 0 then begin
            PurchaseLine.Validate("FA Posting Type", "FA Posting Type");
            PurchaseLine.Validate("Insurance No.", "Insurance No.");
            PurchaseLine.Validate("Maintenance Code", "Maintenance Code");
        end;
        InterfaceBasisData.AddDocDimValue(PurchaseLine."Dimension Set ID", 7, Dim7Value);
        InterfaceBasisData.AddDocDimValue(PurchaseLine."Dimension Set ID", 8, Dim8Value);
        PurchaseLine.Insert();
    end;

    procedure InsertDataAndUpdateUnitCost(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Type: Integer; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        InsertData(DocumentType, DocumentNo, Type, No, '', LocationCode, Quantity, 0, 0, '', '', '', '');
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    procedure InsertDataAndUpdateUnitOfMeasure(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Type: Integer; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        InsertData(DocumentType, DocumentNo, Type, No, '', LocationCode, Quantity, 0, 0, '', '', '', '');
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;
}

