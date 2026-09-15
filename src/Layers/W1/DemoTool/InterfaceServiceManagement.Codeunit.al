codeunit 117000 "Interface Service Management"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        NextLineNo: Integer;
        XServiceManagement: Label 'Service Management';
        XSC00001: Label 'SC00001';
        XSC00002: Label 'SC00002';
        XSC00003: Label 'SC00003';
        XSC00005: Label 'SC00005';
        XSC00006: Label 'SC00006';
        XSC00007: Label 'SC00007';
        XSO000003: Label 'SO000003';
        XSO000004: Label 'SO000004';
        XSO000005: Label 'SO000005';
        XSO000006: Label 'SO000006';
        XSO000007: Label 'SO000007';
        XSO000008: Label 'SO000008';
        XINPROCESS: Label 'IN PROCESS';
        XMarty: Label 'Marty';
        XTerry: Label 'Terry';
        XSCIasterisk: Label 'XSCI*';
        XBLUE: Label 'BLUE';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XServiceManagement);

        Steps := 0;
        MaxSteps := 53; // Number of calls to RunCodeunit

        RunCodeunit(CODEUNIT::"Add Source Code Setup");
        RunCodeunit(CODEUNIT::"Add No. Series");
        RunCodeunit(CODEUNIT::"Add No. Series Line");
        RunCodeunit(CODEUNIT::"Add G/L Account");
        RunCodeunit(CODEUNIT::"Add Job Responsibility");
        RunCodeunit(CODEUNIT::"Add Resource");
        RunCodeunit(CODEUNIT::"Add Res. Capacity Entry");
        RunCodeunit(CODEUNIT::"Add Employee");
        RunCodeunit(CODEUNIT::"Add Salesperson/Purchaser");
        RunCodeunit(CODEUNIT::"Create Service Zone");
        RunCodeunit(CODEUNIT::"Create Service Cost");
        RunCodeunit(CODEUNIT::"Create Service Base Calendar");
        RunCodeunit(CODEUNIT::"Create Service Mgt. Setup");
        RunCodeunit(CODEUNIT::"Create Job Queue Setup");
        RunCodeunit(CODEUNIT::"Create Job Queue Entries");
        RunCodeunit(CODEUNIT::"Create Service Hour");
        RunCodeunit(CODEUNIT::"Create Work-Hour Template");
        RunCodeunit(CODEUNIT::"Create Skill Code");
        RunCodeunit(CODEUNIT::"Create Fault Reason Code");
        RunCodeunit(CODEUNIT::"Create Service Order Type");
        RunCodeunit(CODEUNIT::"Create Service Item Group");
        RunCodeunit(CODEUNIT::"Create Service Shelf");
        RunCodeunit(CODEUNIT::"Create Service Status Priority");
        RunCodeunit(CODEUNIT::"Create Repair Status");
        RunCodeunit(CODEUNIT::"Create Resolution Code");
        RunCodeunit(CODEUNIT::"Create Fault Area");
        RunCodeunit(CODEUNIT::"Create Symptom Code");
        RunCodeunit(CODEUNIT::"Create Fault Code");
        RunCodeunit(CODEUNIT::"Create Service Contract Accoun");
        RunCodeunit(CODEUNIT::"Create Service Contract Templa");
        RunCodeunit(CODEUNIT::"Create Contract Group");
        RunCodeunit(CODEUNIT::"Create Resource Service Zone");
        RunCodeunit(CODEUNIT::"Create Item (serv)");
        RunCodeunit(CODEUNIT::"Add BOM Component");
        RunCodeunit(CODEUNIT::"Create Loaner");
        RunCodeunit(CODEUNIT::"Create Resource Skill");
        RunCodeunit(CODEUNIT::"Create Service Item");
        RunCodeunit(CODEUNIT::"Create Service Item Component");
        RunCodeunit(CODEUNIT::"Create Service Price Adjustmen");
        RunCodeunit(CODEUNIT::"Create Serv. Price Adjustment");
        RunCodeunit(CODEUNIT::"Create Service Price Group");
        RunCodeunit(CODEUNIT::"Create Serv. Price Group Setup");
        RunCodeunit(CODEUNIT::"Create Troubleshooting Header");
        RunCodeunit(CODEUNIT::"Create Troubleshooting Line");
        RunCodeunit(CODEUNIT::"Create Troubleshooting Setup");
        if not DemoDataSetup."Skip sequence of actions" then begin
            RunCodeunit(CODEUNIT::"Create Service Header");
            RunCodeunit(CODEUNIT::"Create Service Item Line");
            RunCodeunit(CODEUNIT::"Create Service Line");
            RunCodeunit(CODEUNIT::"Create Service Order Allocatio");
        end;
        RunCodeunit(CODEUNIT::"Create Service Contract Header");
        RunCodeunit(CODEUNIT::"Create Service Contract Line");
        RunCodeunit(CODEUNIT::"Upd. Service Zone in Customer");
        Window.Close();
    end;

    procedure "Before Posting"()
    begin
    end;

    procedure Post(PostingDate: Date)
    begin
    end;

    procedure "After Posting"()
    var
        SalesHeader: Record "Sales Header";
        ServContrHeader: Record "Service Contract Header";
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServInvLine: Record "Service Line";
        CreateContrInv: Report "Create Contract Invoices";
        SignServContractDoc: Codeunit SignServContractDoc;
        CreateServiceHeader: Codeunit "Create Service Header";
        CreateServiceItemLine: Codeunit "Create Service Item Line";
        CreateServiceInvoiceLine: Codeunit "Create Service Line";
        TempDate: Date;
    begin
        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00001);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00002);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00003);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00005);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00006);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Get(ServContrHeader."Contract Type"::Contract, XSC00007);
        Clear(SignServContractDoc);
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServContrHeader);

        ServContrHeader.Reset();
        ServContrHeader.SetRange("Contract Type", ServContrHeader."Contract Type"::Contract);
        // FP
        ServContrHeader.SetFilter("Next Invoice Date", '<%1', MakeAdjustments.AdjustDate(19030126D));
        while ServContrHeader.FindFirst() do begin
            Clear(CreateContrInv);
            CreateContrInv.SetHideDialog(true);
            CreateContrInv.SetOptions(ServContrHeader."Next Invoice Date", CalcDate('<+1M-1D>', ServContrHeader."Next Invoice Date"), 0);
            ServContrHeader.SetRange("Contract Type", ServContrHeader."Contract Type");
            ServContrHeader.SetRange("Contract No.", ServContrHeader."Contract No.");
            CreateContrInv.SetTableView(ServContrHeader);
            CreateContrInv.UseRequestPage := false;
            CreateContrInv.Run();

            ServContrHeader.SetRange("Contract Type");
            ServContrHeader.SetRange("Contract No.");
        end;

        TempDate := WorkDate();
        WorkDate(MakeAdjustments.AdjustDate(19021212D));
        CreateSalesInvoice(2, '40000', 19021212D);
        WorkDate(MakeAdjustments.AdjustDate(19021204D));
        CreateSalesInvoice(2, '50000', 19021204D);
        WorkDate(MakeAdjustments.AdjustDate(19030116D));
        CreateSalesInvoice(2, '30000', 19030116D);
        WorkDate(TempDate);

        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000003, ServHeader.Priority::Low, '40000', '', '40000', '', '', 19030106D, 102021T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000004, ServHeader.Priority::Low, '50000', '', '50000', '', '', 19030109D, 102421T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000005, ServHeader.Priority::Low, '40000', '', '40000', '', '', 19030109D, 152021T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000006, ServHeader.Priority::Low, '30000', '', '30000', '', '', 19030120D, 142921T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000007, ServHeader.Priority::Low, '40000', '', '40000', '', '', 19030118D, 172021T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceHeader.InsertData(ServHeader."Document Type"::Order, XSO000008, ServHeader.Priority::Low, '50000', '', '50000', '', '', 19030119D, 103521T,
          0D, 0D, 0T, 0D, 0T);
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000003, 10000, '30', XINPROCESS, '7', '7', '776', '1', 12, 19030109D, 132000T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000003, 20000, '31', XINPROCESS, '7', '7', '776', '1', 12, 19030109D, 132000T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000003, 30000, '32', XINPROCESS, '7', '7', '776', '1', 12, 19030109D, 132000T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000004, 10000, '36', XINPROCESS, '7', '8', '781', '2', 12, 19030110D, 132400T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000005, 10000, '33', XINPROCESS, '7', '1', '71A', 'Z', 12, 19030110D, 142000T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000006, 10000, '41', XINPROCESS, '', '', '', '', 8, 19030123D, 092900T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000007, 10000, '35', XINPROCESS, '', '', '', '', 8, 19030119D, 092400T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceItemLine.InsertData(
          ServItemLine."Document Type"::Order, XSO000008, 10000, '36', XINPROCESS, '7', '1', '71A', 'Z', 12, 19030120D, 133500T, 0D, 0T, 0D, 0T, '', '');
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000003, 10000, 10000, '30', '', ServInvLine.Type::Resource, XMarty, '', false, 1, 1, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000003, 20000, 20000, '31', '', ServInvLine.Type::Resource, XMarty, '', false, 1, 1, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000003, 30000, 30000, '32', '', ServInvLine.Type::Resource, XMarty, '', false, 1, 1, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000004, 10000, 10000, '36', '', ServInvLine.Type::Resource, XMarty, '', false, 2, 2, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000005, 10000, 10000, '33', '', ServInvLine.Type::Resource, XTerry, '', false, 2.5, 2.5, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000005, 20000, 10000, '33', '', ServInvLine.Type::Item, '80026', '', false, 1, 1, 20.4, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000006, 10000, 10000, '41', '', ServInvLine.Type::Resource, XTerry, '', false, 1.5, 1.5, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000006, 20000, 10000, '41', '', ServInvLine.Type::Item, '80206', '', false, 1, 1, 1.4, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000007, 10000, 10000, '35', '', ServInvLine.Type::Resource, XMarty, '', false, 2, 2, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000007, 20000, 10000, '35', '', ServInvLine.Type::Item, '80210', '', false, 1, 1, 32.7, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000008, 10000, 10000, '36', '', ServInvLine.Type::Resource, XTerry, '', false, 2.5, 2.5, 54, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");
        CreateServiceInvoiceLine.InsertData(
          ServInvLine."Document Type"::Order, XSO000008, 20000, 10000, '36', '', ServInvLine.Type::Item, '80026', '', false, 1, 1, 20.4, true, 0,
          ServInvLine."Price Adjmt. Status"::" ");

        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetFilter("No.", XSCIasterisk);
        if SalesHeader.Find('-') then
            repeat
                InvoiceSales(SalesHeader);
            until SalesHeader.Next() = 0;

        ChangeLogDates();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;

    procedure CreateSalesInvoice("Document Type": Integer; "Sell-to Customer No.": Code[20]; "Posting Date": Date)
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        Clear(SalesHeader);
        SalesHeader.SetHideValidationDialog(true);

        SalesHeader.Validate("Document Type", "Document Type");
        SalesHeader.Validate("No.", '');
        SalesHeader."Posting Date" := MakeAdjustments.AdjustDate("Posting Date");
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", "Sell-to Customer No.");
        SalesHeader.Validate("Posting Date");
        SalesHeader.Validate("Order Date", MakeAdjustments.AdjustDate("Posting Date"));
        SalesHeader.Validate("Shipment Date", MakeAdjustments.AdjustDate("Posting Date"));
        SalesHeader.Validate("Document Date", MakeAdjustments.AdjustDate("Posting Date"));
        SalesHeader.Validate("Location Code", XBLUE);

        SalesHeader."Currency Factor" :=
          CurrencyExchRate.ExchangeRate(WorkDate(), SalesHeader."Currency Code");

        SalesHeader.Modify(true);

        case SalesHeader."Sell-to Customer No." of
            '40000':
                begin
                    NextLineNo := 10000;
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8908-W', 3);
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8916-W', 2);
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8924-W', 1);
                end;
            '50000':
                begin
                    NextLineNo := 10000;
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8916-W', 1);
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8924-W', 1);
                end;
            '30000':
                begin
                    NextLineNo := 10000;
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8908-W', 3);
                    CreateSalesLine(SalesHeader."Document Type", SalesHeader."No.", "Sales Line Type"::Item, '8924-W', 1);
                end;
        end;

        InvoiceSales(SalesHeader);
    end;

    procedure CreateSalesLine("Document type": Enum "Sales Document Type"; "Document no.": Code[20]; Type: Enum "Sales Line Type"; "No.": Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", "Document type");
        SalesLine.Validate("Document No.", "Document no.");
        SalesLine.Validate("Line No.", NextLineNo);
        SalesLine.Insert(true);
        NextLineNo += 10000;

        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", "No.");
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    procedure InvoiceSales(SalesHeader: Record "Sales Header")
    var
        "Sales Line": Record "Sales Line";
        "Sales-Post": Codeunit "Sales-Post";
        "Sales-Calc. Discount": Codeunit "Sales-Calc. Discount";
    begin
        "Sales Line".Reset();
        "Sales Line".SetRange("Document Type", SalesHeader."Document Type");
        "Sales Line".SetRange("Document No.", SalesHeader."No.");
        "Sales Line".SetFilter("Qty. to Invoice", '<>0');
        if "Sales Line".Find('<>=') then begin
            "Sales Line".SetRange("Qty. to Invoice");
            "Sales-Calc. Discount".Run("Sales Line");
            Clear("Sales-Calc. Discount");
            SalesHeader.Find();
            SalesHeader.Ship := true;
            SalesHeader.Invoice := true;
            "Sales-Post".Run(SalesHeader);
        end;
    end;

    procedure ChangeLogDates()
    var
        ServItem: Record "Service Item";
        ServItemLog: Record "Service Item Log";
        ServHeader: Record "Service Header";
        ServOrderLog: Record "Service Document Log";
        ServContrHeader: Record "Service Contract Header";
        ContrChangeLog: Record "Contract Change Log";
    begin
        ServItem.Reset();
        if ServItem.Find('-') then
            repeat
                ServItemLog.Reset();
                ServItemLog.SetRange("Service Item No.", ServItem."No.");
                if ServItemLog.Find('-') then
                    repeat
                        if ServItemLog.After = '' then
                            ServItemLog."Change Date" := ServItem."Installation Date";
                        if ServItemLog.After = 'Installed' then
                            ServItemLog."Change Date" := ServItem."Warranty Starting Date (Parts)";
                        ServItemLog.Modify();
                    until ServItemLog.Next() = 0;
            until ServItem.Next() = 0;

        ServHeader.Reset();
        if ServHeader.Find('-') then
            repeat
                ServOrderLog.Reset();
                ServOrderLog.SetRange("Document Type", ServHeader."Document Type");
                ServOrderLog.SetRange("Document No.", ServHeader."No.");
                ServOrderLog.ModifyAll("Change Date", ServHeader."Order Date");
            until ServHeader.Next() = 0;

        ServContrHeader.Reset();
        if ServContrHeader.Find('-') then
            repeat
                ContrChangeLog.Reset();
                ContrChangeLog.SetRange("Contract Type", ServContrHeader."Contract Type");
                ContrChangeLog.SetRange("Contract No.", ServContrHeader."Contract No.");
                ContrChangeLog.ModifyAll("Date of Change", ServContrHeader."Starting Date");
            until ServContrHeader.Next() = 0;
    end;
}

