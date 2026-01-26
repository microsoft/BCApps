codeunit 101037 "Create Sales Line"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(1, '101001', 2, '1968-S', XRED, 5, '', 0);
        InsertData(1, '101001', 2, '1996-S', XRED, 7, '', 0);
        InsertData(1, '101002', 2, '1928-S', XGREEN, 14, '', 0);
        InsertData(1, '101002', 2, '1988-W', XGREEN, 1, '', 0);
        InsertData(1, '101002', 2, '1972-S', XGREEN, 1, '', 0);
        InsertData(1, '101003', 2, '1968-S', XRED, 4, '', 0);
        InsertData(1, '101003', 2, '1960-S', XRED, 7, '', 0);
        InsertData(1, '101003', 2, '1976-W', XRED, 5, '', 0);
        InsertData(1, '101003', 2, '70011', XRED, 1, '', 0);
        InsertData(1, '101004', 2, '1896-S', XGREEN, 1, '', 0);
        InsertData(1, '101005', 2, '1920-S', XRED, 4, '', 0);
        InsertData(1, '101006', 2, '1896-S', XRED, 1, '', 0);
        InsertData(1, '101006', 2, '1906-S', XRED, 1, '', 0);
        InsertData(1, '101007', 2, '766BC-C', XGREEN, 1, '', 0);
        InsertData(1, '101008', 2, '1992-W', XRED, 1, '', 0);
        InsertData(1, '101009', 2, '1976-W', XGREEN, 5, '', 0);
        InsertData(1, '101009', 2, '1964-W', XGREEN, 2, '', 0);
        InsertData(1, '101010', 2, '1972-S', XRED, 6, '', 0);
        InsertData(1, '101010', 2, '1968-S', XRED, 4, '', 0);
        InsertData(1, '101010', 2, '1980-S', XRED, 3, '', 0);
        InsertData(1, '101011', 2, '1920-S', XGREEN, 5, '', 0);
        InsertData(1, '101011', 2, '1900-S', XGREEN, 12, '', 0);
        InsertData(1, '101011', 2, '1996-S', XGREEN, 1, '', 0);
        InsertData(1, '101012', 2, '1928-S', XGREEN, 5, '', 0);
        InsertData(1, '101013', 2, '1952-W', XGREEN, 1, '', 0);
        InsertData(1, '101013', 2, '1928-W', XGREEN, 2, '', 0);
        InsertData(1, '101013', 2, '1964-W', XGREEN, 2, '', 0);
        InsertData(1, '101014', 2, '766BC-A', XGREEN, 2, '', 0);
        InsertData(1, '101014', 2, '766BC-C', XGREEN, 1, '', 0);
        InsertData(1, '101015', 2, '1972-S', XRED, 6, '', 0);
        InsertData(1, '101015', 2, '1968-S', XRED, 5, '', 0);
        InsertData(1, '101015', 2, '1896-S', XRED, 12, '', 0);
        InsertData(1, '101015', 2, '1906-S', XRED, 12, '', 0);
        InsertData(1, '101016', 2, '1920-S', XRED, 1, '', 0);
        InsertData(1, '101017', 2, '1928-W', XGREEN, 2, '', 0);
        InsertData(1, '101017', 2, '1964-W', XGREEN, 1, '', 0);
        InsertData(1, '101017', 2, '1976-W', XGREEN, 1, '', 0);
        InsertData(1, '101018', 2, '1980-S', XGREEN, 6, '', 0);
        InsertData(1, '101019', 2, '1952-W', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1928-W', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1976-W', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1964-W', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '70060', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1896-S', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1908-S', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '1928-S', XRED, 2, '', 0);
        InsertData(1, '101019', 2, '70102', XRED, 2, '', 0);
        InsertData(1, '101020', 2, '1992-W', XRED, 4, '', 0);
        InsertData(1, '101021', 2, '1968-W', XRED, 2, '', 0);
        InsertData(1, '101021', 2, '1964-W', XRED, 1, '', 0);
        InsertData(1, '101021', 2, '1960-S', XRED, 1, '', 0);
        InsertData(1, '101022', 2, '1976-W', XYELLOW, 3, '', 0);
        InsertData(1, '101022', 2, '1964-W', XGREEN, 4, '', 0);
        InsertData(1, '101023', 2, '1920-S', XGREEN, 4, '', 0);
        InsertData(1, '101023', 2, '1936-S', XGREEN, 23, '', 0);
        CreateINSalesOrderLines();

        // Add new orders here
        InsertResource(2, '103001', 3, XTerry, XAssemblingFurnitureJanuary, '', 25);
        InsertResource(2, '103001', 3, XTerry, XAssemblingFurnitureJanuary, XMILES, 120);
        InsertResource(2, '103002', 3, XTerry, XAssemblingFurnitureJanuary, '', 25);
        InsertResource(2, '103002', 3, XTerry, XAssemblingFurnitureJanuary, XMILES, 96);
        InsertResource(2, '103003', 3, XTerry, XAssemblingFurnitureJanuary, '', 25);
        InsertResource(2, '103003', 3, XTerry, XAssemblingFurnitureJanuary, XMILES, 76);

        InsertData(2, '103005', 2, '1976-W', XRED, 4, '', 0);
        InsertData(2, '103006', 2, '1976-W', XRED, 20, '', 0);
        InsertData(2, '103007', 2, '1976-W', XRED, 15, '', 0);
        InsertData(2, '103008', 2, '1976-W', XRED, 15, '', 0);
        InsertData(2, '103009', 2, '1976-W', XRED, 31, '', 0);
        InsertData(2, '103010', 2, '1976-W', XRED, 17, '', 0);
        InsertDataAndUpdateUnitPrice(2, '103011', 2, '70000', '', 3, 4349 / 3);
        InsertDataAndUpdateUnitPrice(2, '103012', 2, '70000', '', 4, 5798.78 / 4);
        InsertDataAndUpdateUnitPrice(2, '103013', 2, '70000', '', 5, 7248.48 / 5);
        InsertDataAndUpdateUnitPrice(2, '103014', 2, '70000', '', 1, 1232.24);
        CreateSalesInvLines();

        // Add new invoices here

        InsertData(3, '104001', 2, '1968-S', XRED, 2, '', 0);
        InsertData(3, '104002', 2, '1896-S', XGREEN, 1, '', 0);
        InsertData(3, '104003', 2, '766BC-C', XGREEN, 1, '', 0);
        InsertData(3, '104004', 2, '766BC-C', XGREEN, 1, '', 0);
        InsertData(3, '104005', 2, '1896-S', XRED, 1, '', 0);
        CreateSalesCrMemoLines();
        // Add new credit memos here

    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        "Line No.": Integer;
        "Previous Document No.": Code[20];
        LastOrdinaryLineNo: Integer;
        XRED: Label 'RED';
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XTerry: Label 'Terry';
        XMILES: Label 'MILES';
        XAssemblingFurnitureJanuary: Label 'Assembling Furniture, January';
        XBLUE: Label 'BLUE';

    procedure InsertData("Document Type": Integer; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; "Location Code": Code[10]; Quantity: Decimal; NOC: Code[20]; UnitPrice: Decimal)
    var
        CalculateTax: Codeunit "Calculate Tax";
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
        SalesHeader.Get("Document Type", "Document No.");
        if SalesHeader."Location Code" <> '' then
            SalesLine.Validate("Location Code", SalesHeader."Location Code");
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Validate("TCS Nature of Collection", NOC);
        if UnitPrice <> 0 then
            SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Insert();
        CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then begin
            TransferExtendedText.InsertSalesExtText(SalesLine);
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "Document No.");
            SalesLine.FindLast();
            "Line No." := SalesLine."Line No.";
        end;
        LastOrdinaryLineNo := "Line No.";
    end;

    procedure InsertResource("Document Type": Integer; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; "Work Type Code": Code[10]; Quantity: Decimal)
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
    end;

    local procedure InsertDataAndUpdateUnitPrice(DocumentType: Integer; DocumentNo: Code[20]; Type: Integer; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        InsertData(DocumentType, DocumentNo, Type, No, LocationCode, Quantity, '', 0);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);
    end;

    procedure InsertDataTCS("Document Type": Integer; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Quantity: Decimal; UnitPrice: Decimal; NOC: Code[20])
    var
        CalculateTax: Codeunit "Calculate Tax";
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
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Validate("TCS Nature of Collection", NOC);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Insert();
        CalculateTax.CallTaxEngineOnSalesLine(SalesLine, SalesLine);

        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then begin
            TransferExtendedText.InsertSalesExtText(SalesLine);
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "Document No.");
            SalesLine.FindLast();
            "Line No." := SalesLine."Line No.";
        end;
        LastOrdinaryLineNo := "Line No.";
    end;

    procedure GetDocumentNo(SalesDocType: Enum "Sales Document Type"; ExternalDocNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesDocType);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        SalesHeader.FindFirst();
        exit(SalesHeader."No.");
    end;

    local procedure InsertRefInvNo(DocType: Integer; DocNo: Code[20]; SourceNo: Code[20])
    var
        RefInvNo: Record "Reference Invoice No.";
    begin
        RefInvNo.Init();
        if DocType = 3 then
            RefInvNo."Document Type" := RefInvNo."Document Type"::"Credit Memo";
        if DocType = 5 then
            RefInvNo."Document Type" := RefInvNo."Document Type"::"Return Order";
        RefInvNo."Document No." := DocNo;
        RefInvNo."Source Type" := RefInvNo."Source Type"::Customer;
        RefInvNo."Source No." := SourceNo;
        RefInvNo."Reference Invoice Nos." := 'DUMMY-' + DocNo;
        RefInvNo.Verified := true;
        RefInvNo.Insert();
    end;

    procedure CreateINSalesOrderLines()
    begin
        InsertData(1, 'SO-0001', 2, '1936-S', '', 10, '', 100);
        InsertData(1, 'SO-0001', 2, '1968-S', '', 10, '', 100);
        InsertData(1, 'SO-0002', 2, '1936-S', '', 10, '', 100);
        InsertData(1, 'SO-0002', 2, '1968-S', '', 10, '', 100);
        InsertData(1, 'SO-0003', 2, '1960-S', '', 1, 'A', 10000);
        InsertData(1, 'SO-0004', 1, '6711', '', 10, 'A', 100);
    end;

    procedure CreateSalesInvLines()
    begin
        InsertData(2, 'SI-0001', 1, '6955', '', 1, '', 1000);
        InsertData(2, 'SI-0002', 1, '6711', '', 1, 'A', 6000);
    end;

    procedure CreateSalesCrMemoLines()
    begin
        InsertData(3, 'SCM-1001', 2, '1936-S', XBLUE, 7, '', 100);
        InsertData(3, 'SCM-1001', 2, '1936-S', XBLUE, 8, '', 100);
        InsertData(3, 'SCM-1002', 1, '6955', XBLUE, 1, '', 100);


        InsertRefInvNo(3, 'SCM-1001', '10000');
        InsertRefInvNo(3, 'SCM-1002', '10000');
    end;
}
