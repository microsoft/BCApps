codeunit 101037 "Create Sales Line"
{

    trigger OnRun()
    begin
        // calls of InsertData are moved to codeunit 101036

    end;

    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        "Line No.": Integer;
        "Previous Document No.": Code[20];
        LastOrdinaryLineNo: Integer;
        XSALES: Label 'SALES';
        XOPERATION: Label 'OPERATION';

    procedure InsertData("Document Type": Enum "Sales Document Type"; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; "Location Code": Code[10]; Quantity: Decimal; Dim2Value: Code[20]; Dim7Value: Code[20]; Dim8Value: Code[20])
    var
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", "Document Type");
        SalesLine.Validate("Document No.", "Document No.");

        case "Previous Document No." of
            "Document No.":
                begin
                    "Line No." := "Line No." + 10000;
                    SalesLine.Validate("Line No.", "Line No.");
                end;
            else begin
                "Line No." := 10000;
                "Previous Document No." := "Document No.";
                SalesLine.Validate("Line No.", "Line No.");
            end;
        end;

        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", "No.");
        SalesLine.Validate("Location Code", "Location Code");
        SalesLine.Validate(Quantity, Quantity);

        if Type = 4 then // Fixed asset
            SalesLine."Depreciation Book Code" := XOPERATION;

        SalesLine.Insert();
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then begin
            TransferExtendedText.InsertSalesExtText(SalesLine);
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "Document No.");
            SalesLine.FindLast();
            "Line No." := SalesLine."Line No.";
        end;
        LastOrdinaryLineNo := "Line No.";

        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 1, XSALES);
        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 2, Dim2Value);
        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 7, Dim7Value);
        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 8, Dim8Value);
    end;

    procedure InsertResource("Document Type": Enum "Sales Document Type"; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; "Work Type Code": Code[10]; Quantity: Decimal; Dim2Value: Code[20]; Dim7Value: Code[20]; Dim8Value: Code[20])
    var
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", "Document Type");
        SalesLine.Validate("Document No.", "Document No.");

        case "Previous Document No." of
            "Document No.":
                begin
                    "Line No." := "Line No." + 10000;
                    SalesLine.Validate("Line No.", "Line No.");
                end;
            else begin
                "Line No." := 10000;
                "Previous Document No." := "Document No.";
                SalesLine.Validate("Line No.", "Line No.");
            end;
        end;

        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", "No.");
        SalesLine.Validate(Description, Description);
        SalesLine.Validate("Work Type Code", "Work Type Code");
        SalesLine.Validate(Quantity, Quantity);

        SalesLine.Insert();
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then begin
            TransferExtendedText.InsertSalesExtText(SalesLine);
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "Document No.");
            SalesLine.FindLast();
            "Line No." := SalesLine."Line No.";
        end;
        LastOrdinaryLineNo := "Line No.";

        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 2, Dim2Value);
        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 7, Dim7Value);
        InterfaceBasisData.AddDocDimValue(SalesLine."Dimension Set ID", 8, Dim8Value);
        SalesLine.Modify(true);
    end;

    procedure UpdateData(Description: Text[50]; "Unit Price": Decimal; "Unit Cost": Decimal)
    begin
        if Description <> '' then
            SalesLine.Description := Description;
        if "Unit Price" <> 0 then
            SalesLine.Validate("Unit Price", "Unit Price");
        if "Unit Cost" <> 0 then
            SalesLine.Validate("Unit Cost (LCY)", "Unit Cost");
        SalesLine.Modify();
    end;

    procedure InsertDataAndUpdateUnitPrice(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Integer; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        InsertData(DocumentType, DocumentNo, Type, No, LocationCode, Quantity, '', '', '');
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);
    end;
}

