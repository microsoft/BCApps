#pragma warning disable AA0247
report 14951 "Bill of Lading"
{
    Caption = 'Bill of Lading';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
        }
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
        }
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control1210004)
                {
                    ShowCaption = false;
                    field(ItemDescription; ItemDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Description';
                    }
                    field(VehicleDescription; VehicleDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vehicle Description';
                    }
                    field(VehicleRegistrationNo; VehicleDescriptionRegNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vehicle Registration No.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ExcelTemplate: Record "Excel Template";
        FileName: Text[1024];
        ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment;
    begin
        if not DefineReportSource(ReportSource, SalesHeader) then
            exit;

        if ReportSource = ReportSource::UnpostedSales then
            SalesHeader.TestField(Status, SalesHeader.Status::Released);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Bill of Lading Template Code");

        FileName := ExcelTemplate.OpenTemplate(SalesReceivablesSetup."Bill of Lading Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);

        FillSheets(SalesHeader, ReportSource);

        if TestMode then begin
            if FileNameSilent <> '' then
                ExcelMgt.SaveWrkBook(FileNameSilent);
            ExcelMgt.CloseBook();
        end else
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(SalesReceivablesSetup."Bill of Lading Template Code"));
    end;

    var
        ExcelMgt: Codeunit "Excel Management";
        ItemDescription: Text[1024];
        VehicleDescription: Text[1024];
        VehicleDescriptionRegNo: Text[1024];
        TestMode: Boolean;
        FileNameSilent: Text;

    [Scope('OnPrem')]
    procedure FillSheets(SalesHeader: Record "Sales Header"; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment)
    var
        LocRepMgt: Codeunit "Local Report Management";
        Quantity: Decimal;
        Weight: Decimal;
        Volume: Decimal;
    begin
        ExcelMgt.OpenSheet('стр.1');
        ExcelMgt.FillCell('BU9', Format(SalesHeader."Order Date"));
        ExcelMgt.FillCell('CQ9', SalesHeader."No.");
        ExcelMgt.FillCell('B15', GetVendorInfo(SalesHeader));
        ExcelMgt.FillCell('B20', GetCustomerInfo(SalesHeader));
        ExcelMgt.FillCell('B25', ItemDescription);
        GetLinesInfo(SalesHeader, Quantity, Weight, Volume, ReportSource);
        ExcelMgt.FillCell('BF25', Format(Quantity));
        ExcelMgt.FillCell('B27', LocRepMgt.FormatReportValue(Weight, 2) + ',  ,' + LocRepMgt.FormatReportValue(Volume, 2));
        ExcelMgt.FillCell('BF29', LocRepMgt.FormatReportValue(GetAmountLCY(SalesHeader, ReportSource), 2));

        ExcelMgt.FillCell('B44', GetShippingAgentName(SalesHeader));
        ExcelMgt.FillCell('B47', VehicleDescription);
        ExcelMgt.FillCell('BF47', VehicleDescriptionRegNo);
        ExcelMgt.FillCell('B60', GetLocationInfo(SalesHeader));
        ExcelMgt.WriteAllToCurrentSheet();

        ExcelMgt.OpenSheet('стр.2');
        ExcelMgt.FillCell('B21', GetPayerInfo(SalesHeader));
        ExcelMgt.FillCell('B9', LocRepMgt.FormatReportValue(Weight, 2));
        ExcelMgt.WriteAllToCurrentSheet();
    end;

    [Scope('OnPrem')]
    procedure GetVendorInfo(SalesHeader: Record "Sales Header"): Text[250]
    var
        LocRepMgt: Codeunit "Local Report Management";
    begin
        if SalesHeader."Consignor No." = '' then
            exit(LocRepMgt.GetCompanyName() + '. ' + LocRepMgt.GetLegalAddress() + LocRepMgt.GetCompanyPhoneFax());

        exit(LocRepMgt.GetConsignerInfo(SalesHeader."Consignor No.", SalesHeader."Responsibility Center"));
    end;

    [Scope('OnPrem')]
    procedure GetCustomerInfo(SalesHeader: Record "Sales Header"): Text
    var
        LocRepMgt: Codeunit "Local Report Management";
    begin
        exit(
          LocRepMgt.GetShipToAddrName(
            SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code", SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2") + ' ' +
          LocRepMgt.GetFullAddr(
            SalesHeader."Sell-to Post Code", SalesHeader."Sell-to City",
            SalesHeader."Sell-to Address", SalesHeader."Sell-to Address 2", '', SalesHeader."Sell-to County") + ' ' +
          LocRepMgt.GetCustPhoneFax(SalesHeader."Sell-to Customer No."));
    end;

    [Scope('OnPrem')]
    procedure GetPayerInfo(SalesHeader: Record "Sales Header"): Text
    var
        LocRepMgt: Codeunit "Local Report Management";
    begin
        exit(
          LocRepMgt.GetShipToAddrName(
            SalesHeader."Bill-to Customer No.", SalesHeader."Ship-to Code", SalesHeader."Bill-to Name", SalesHeader."Bill-to Name 2") + ' ' +
          LocRepMgt.GetFullAddr(
            SalesHeader."Bill-to Post Code", SalesHeader."Bill-to City",
            SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2", '', SalesHeader."Bill-to County") + ' ' +
          LocRepMgt.GetCustBankAttrib(SalesHeader."Bill-to Customer No.", SalesHeader."Agreement No."));
    end;

    [Scope('OnPrem')]
    procedure GetShippingAgentName(SalesHeader: Record "Sales Header"): Text[250]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShippingAgent.Get(SalesHeader."Shipping Agent Code") then
            exit(ShippingAgent.Name);
    end;

    [Scope('OnPrem')]
    procedure GetResponsiblePersonInfo(SalesHeader: Record "Sales Header"; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment): Text[250]
    var
        Employee: Record Employee;
        DocumentSignature: Record "Document Signature";
        PostedDocumentSignature: Record "Posted Document Signature";
        LocRepMgt: Codeunit "Local Report Management";
    begin
        case ReportSource of
            ReportSource::UnpostedSales:
                begin
                    if not DocumentSignature.Get(
                         DATABASE::"Sales Header",
                         SalesHeader."Document Type",
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(DocumentSignature."Employee No.") then
                        exit('');
                end;
            ReportSource::SalesInvoice:
                begin
                    if not PostedDocumentSignature.Get(
                         DATABASE::"Sales Invoice Header",
                         0,
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(PostedDocumentSignature."Employee No.") then
                        exit('');
                end;
            ReportSource::SalesShipment:
                begin
                    if not PostedDocumentSignature.Get(
                         DATABASE::"Sales Shipment Header",
                         0,
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(PostedDocumentSignature."Employee No.") then
                        exit('');
                end;
        end;

        exit(
          LocRepMgt.GetEmpName(Employee."No.") + ' ' +
          Employee."Phone No." + ' ' +
          Employee."Mobile Phone No.");
    end;

    [Scope('OnPrem')]
    procedure GetLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment)
    begin
        case ReportSource of
            ReportSource::UnpostedSales:
                GetSalesLinesInfo(SalesHeader, Quantity, Weight, Volume);
            ReportSource::SalesInvoice:
                GetInvoiceLinesInfo(SalesHeader, Quantity, Weight, Volume);
            ReportSource::SalesShipment:
                GetShipmentLinesInfo(SalesHeader, Quantity, Weight, Volume);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSalesLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        if SalesLine.FindSet() then
            repeat
                Quantity += SalesLine."Qty. to Ship";
                Weight += SalesLine."Qty. to Ship" * SalesLine."Net Weight";
                Volume += SalesLine."Qty. to Ship" * SalesLine."Unit Volume";
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesHeader."No.");

        if SalesInvoiceLine.FindSet() then
            repeat
                Quantity += SalesInvoiceLine.Quantity;
                Weight += SalesInvoiceLine.Quantity * SalesInvoiceLine."Net Weight";
                Volume += SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Volume";
            until SalesInvoiceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetShipmentLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesHeader."No.");

        if SalesShipmentLine.FindSet() then
            repeat
                Quantity += SalesShipmentLine.Quantity;
                Weight += SalesShipmentLine.Quantity * SalesShipmentLine."Net Weight";
                Volume += SalesShipmentLine.Quantity * SalesShipmentLine."Unit Volume";
            until SalesShipmentLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetLocationInfo(SalesHeader: Record "Sales Header"): Text[250]
    var
        Location: Record Location;
        CountryRegion: Record "Country/Region";
    begin
        Location.Get(SalesHeader."Location Code");
        CountryRegion.Get(Location."Country/Region Code");
        exit(
          CountryRegion."Local Name" + '  ' + Location."Post Code" + '  ' +
          Location.City + '  ' + Location.Address + '  ' + Location."Address 2");
    end;

    [Scope('OnPrem')]
    procedure GetAmountLCY(SalesHeader: Record "Sales Header"; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment): Decimal
    begin
        case ReportSource of
            ReportSource::UnpostedSales:
                begin
                    SalesHeader.CalcFields("Amount Including VAT (LCY)");
                    exit(SalesHeader."Amount Including VAT (LCY)");
                end;
            ReportSource::SalesInvoice:
                exit(GetInvoiceLinesAmountLCY(SalesHeader));
            ReportSource::SalesShipment:
                exit(GetShipmentLinesAmountLCY(SalesHeader));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceLinesAmountLCY(SalesHeader: Record "Sales Header") AmountLCY: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesHeader."No.");

        if SalesInvoiceLine.FindSet() then
            repeat
                AmountLCY += SalesInvoiceLine."Amount Including VAT (LCY)";
            until SalesInvoiceLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetShipmentLinesAmountLCY(SalesHeader: Record "Sales Header") AmountLCY: Decimal
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesHeader."No.");

        if SalesShipmentLine.FindSet() then
            repeat
                AmountLCY += SalesShipmentLine."Amount Including VAT (LCY)";
            until SalesShipmentLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure DefineReportSource(var ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment; var SalesHeader: Record "Sales Header"): Boolean
    begin
        if "Sales Header".GetFilters <> '' then begin
            ReportSource := ReportSource::UnpostedSales;
            SalesHeader := "Sales Header";
            exit(true);
        end;

        if "Sales Invoice Header".GetFilters <> '' then begin
            ReportSource := ReportSource::SalesInvoice;
            SalesHeader.TransferFields("Sales Invoice Header");
            exit(true);
        end;

        if "Sales Shipment Header".GetFilters <> '' then begin
            ReportSource := ReportSource::SalesShipment;
            SalesHeader.TransferFields("Sales Shipment Header");
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileNameSilent := NewFileName;
    end;
}

