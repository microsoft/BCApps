#pragma warning disable AA0247
report 14918 "Items Receipt Act TORG-1"
{
    Caption = 'Items Receipt Act TORG-1';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = filter(Order | Invoice | "Credit Memo"));
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    Item: Record Item;
                    Qty: Decimal;
                    Price: Decimal;
                    FactQuantity: Decimal;
                    FullAmount: Decimal;
                    ReceiveAmount: Decimal;
                    AmountInclVat: Decimal;
                    PlannedQtyPerUnitOfMeasure: Decimal;
                    FactQtyPerUnitOfMeasure: Decimal;
                    TempVar: Decimal;
                begin
                    if Type = Type::Item then begin
                        TestField("Location Code");

                        Qty := Quantity;
                        Price := "Direct Unit Cost";
                        FactQuantity := "Qty. to Receive";
                        PlannedQtyPerUnitOfMeasure := "Qty. per Unit of Measure";
                        FactQtyPerUnitOfMeasure := "Qty. per Unit of Measure";

                        if PurchLineWithLCYAmt.Get("Document Type", "Document No.", "Line No.") then
                            FillAmounts(PurchLineWithLCYAmt, Price, FullAmount, AmountInclVat);

                        if (ShowActualQty and not Surplus) and PurchLineWithLCYAmtToReceive.Get("Document Type", "Document No.", "Line No.") then
                            FillAmounts(PurchLineWithLCYAmtToReceive, Price, ReceiveAmount, AmountInclVat);

                        if PlannedQtyPerUnitOfMeasure <> 0 then
                            Price := Price / PlannedQtyPerUnitOfMeasure;

                        if "Document Type" = "Document Type"::"Credit Memo" then
                            if "Appl.-to Item Entry" <> 0 then begin
                                ItemLedgerEntry.Get("Appl.-to Item Entry");
                                ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");

                                PlannedQtyPerUnitOfMeasure := ItemLedgerEntry."Qty. per Unit of Measure";
                                if ItemLedgerEntry."Qty. per Unit of Measure" <> 0 then
                                    Qty := ItemLedgerEntry.Quantity / PlannedQtyPerUnitOfMeasure
                                else
                                    Qty := ItemLedgerEntry.Quantity;

                                FactQuantity := Qty - Quantity;

                                if PurchLineWithLCYAmtToReceive.Get("Document Type", "Document No.", "Line No.") then
                                    FillAmounts(PurchLineWithLCYAmtToReceive, Price, FullAmount, AmountInclVat);

                                if PurchLineWithLCYAmt.Get("Document Type", "Document No.", "Line No.") then
                                    FillAmounts(PurchLineWithLCYAmt, Price, ReceiveAmount, TempVar);

                                ReceiveAmount := FullAmount - ReceiveAmount;
                                AmountInclVat := AmountInclVat - TempVar;

                                Price := FullAmount / ItemLedgerEntry.Quantity;
                            end else begin
                                Qty := 0;
                                Price := 0;
                                FullAmount := 0;
                                AmountInclVat := 0;
                                ReceiveAmount := 0;
                                PlannedQtyPerUnitOfMeasure := 0;
                                FactQuantity := 0;
                            end;

                        if Item.Get("No.") then;

                        FillLineBuffer(
                          LineCounter,
                          "No.",
                          Description,
                          Item."Base Unit of Measure",
                          PlannedQtyPerUnitOfMeasure,
                          FactQtyPerUnitOfMeasure,
                          Qty,
                          Price,
                          FullAmount,
                          ReceiveAmount,
                          "Net Weight",
                          "Gross Weight",
                          FactQuantity,
                          AmountInclVat,
                          "VAT %",
                          Surplus,
                          false);

                        LineCounter := LineCounter + 1;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeaderBuffer(
                  DATABASE::"Purchase Header",
                  "Document Type".AsInteger(),
                  "No.",
                  "Document Date",
                  "Posting Date",
                  "Buy-from Vendor No.",
                  "Pay-to Vendor No.",
                  "Location Code",
                  "Vendor VAT Invoice No.",
                  "Vendor VAT Invoice Date",
                  "Agreement No.",
                  "External Agreement No.");

                CalcAmounts("Purchase Header");
                if ShowActualQty then
                    CalcReceivePurchLines("Purchase Header");
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("Invt. Document Header"; "Invt. Document Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Receipt));
            dataitem("Invt. Document Line"; "Invt. Document Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Price: Decimal;
                begin
                    TestField("Location Code");

                    Price := "Unit Cost";
                    if "Qty. per Unit of Measure" <> 0 then
                        Price := Price / "Qty. per Unit of Measure";

                    if Item.Get("Item No.") then;

                    FillLineBuffer(
                      LineCounter,
                      "Item No.",
                      Description,
                      Item."Base Unit of Measure",
                      "Qty. per Unit of Measure",
                      "Qty. per Unit of Measure",
                      Quantity,
                      Price,
                      Quantity * "Unit Cost",
                      Quantity * "Unit Cost",
                      "Net Weight",
                      "Gross Weight",
                      Quantity,
                      Quantity * "Unit Cost",
                      0,
                      false,
                      true);

                    LineCounter := LineCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeaderBuffer(
                  DATABASE::"Invt. Document Header",
                  "Document Type".AsInteger(),
                  "No.",
                  "Document Date",
                  "Posting Date",
                  '',
                  '',
                  "Location Code",
                  '',
                  0D,
                  '',
                  '');
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem("Invt. Receipt Header"; "Invt. Receipt Header")
        {
            DataItemTableView = sorting("No.");
            dataitem("Invt. Receipt Line"; "Invt. Receipt Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Price: Decimal;
                begin
                    TestField("Location Code");

                    Price := "Unit Cost";

                    if "Qty. per Unit of Measure" <> 0 then
                        Price := Price / "Qty. per Unit of Measure";

                    if Item.Get("Item No.") then;

                    FillLineBuffer(
                      LineCounter,
                      "Item No.",
                      Description,
                      Item."Base Unit of Measure",
                      "Qty. per Unit of Measure",
                      "Qty. per Unit of Measure",
                      Quantity,
                      Price,
                      Quantity * "Unit Cost",
                      Quantity * "Unit Cost",
                      "Net Weight",
                      "Gross Weight",
                      Quantity,
                      Quantity * "Unit Cost",
                      0,
                      false,
                      true);

                    LineCounter := LineCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeaderBuffer(
                  DATABASE::"Invt. Document Header",
                  "Purchase Document Type"::Quote.AsInteger(),
                  "No.",
                  "Document Date",
                  "Posting Date",
                  '',
                  '',
                  "Location Code",
                  '',
                  0D,
                  '',
                  '');
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();
            end;
        }
        dataitem(HeaderLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                Location: Record Location;
                Vendor: Record Vendor;
                Employee: Record Employee;
                DocumentSignature: Record "Document Signature";
                LocalisationManagement: Codeunit "Localisation Management";
                FormatAddr: Codeunit "Format Address";
                CustAddr: array[8] of Text[100];
                EmployeePosition: Text[50];
                EmployeeName: Text[100];
            begin
                ExcelReportBuilderMgr.SetSheet('Sheet1');
                ExcelReportBuilderMgr.AddSection('PAGE1');
                ExcelReportBuilderMgr.AddDataToSection('DocumentNumber', HeaderBuffer."No.");

                if CompanyInformation."Director No." <> '' then
                    if Employee.Get(CompanyInformation."Director No.") then begin
                        ExcelReportBuilderMgr.AddDataToSection('DirectorPosition', Employee.GetJobTitleName());
                        ExcelReportBuilderMgr.AddDataToSection('DirectorName', CompanyInformation."Director Name");
                    end;

                FormatAddr.FormatAddr(
                  CustAddr, CompanyInformation.Name, CompanyInformation."Name 2", CompanyInformation."Phone No.",
                  CompanyInformation.Address, CompanyInformation."Address 2",
                  CompanyInformation.City, CompanyInformation."Post Code",
                  CompanyInformation.County, CompanyInformation."Country/Region Code");

                ExcelReportBuilderMgr.AddDataToSection('CompanyName',
                  CustAddr[1] + ' ' + CustAddr[2] + ' ' + CustAddr[3] + ' ' + CustAddr[4] + ' ' +
                  CustAddr[5] + ' ' + CustAddr[6] + ' ' + CustAddr[7] + ' ' + CustAddr[8]);

                ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(HeaderBuffer."Document Date"));

                if Location.Get(HeaderBuffer."Location Code") then
                    ExcelReportBuilderMgr.AddDataToSection('DepartmentName', Location.Name);

                ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInformation."OKPO Code");

                if HeaderBuffer."Buy-from Vendor No." <> '' then
                    if Vendor.Get(HeaderBuffer."Buy-from Vendor No.") then begin
                        FormatAddr.FormatAddr(CustAddr, Vendor.Name, Vendor."Name 2", Vendor."Phone No.",
                          Vendor.Address, Vendor."Address 2", Vendor.City, Vendor."Post Code",
                          Vendor.County, Vendor."Country/Region Code");

                        ExcelReportBuilderMgr.AddDataToSection('InvoiceAccountName',
                          CustAddr[1] + ' ' + CustAddr[2] + ' ' + CustAddr[3] + ' ' + CustAddr[4] + ' ' +
                          CustAddr[5] + ' ' + CustAddr[6] + ' ' + CustAddr[7] + ' ' + CustAddr[8]);
                    end;

                if HeaderBuffer."Pay-to Vendor No." <> '' then
                    if Vendor.Get(HeaderBuffer."Pay-to Vendor No.") then begin
                        FormatAddr.FormatAddr(CustAddr, Vendor.Name, Vendor."Name 2", Vendor."Phone No.",
                          Vendor.Address, Vendor."Address 2", Vendor.City, Vendor."Post Code",
                          Vendor.County, Vendor."Country/Region Code");

                        ExcelReportBuilderMgr.AddDataToSection('VendAccountName',
                          CustAddr[1] + ' ' + CustAddr[2] + ' ' + CustAddr[3] + ' ' + CustAddr[4] + ' ' +
                          CustAddr[5] + ' ' + CustAddr[6] + ' ' + CustAddr[7] + ' ' + CustAddr[8]);
                    end;
                ExcelReportBuilderMgr.AddDataToSection('ReportNo', ReportNo);
                if ReportDate <> 0D then begin
                    ExcelReportBuilderMgr.AddDataToSection('DocmentDateDay', Format(ReportDate, 0, '<Day,2>'));
                    ExcelReportBuilderMgr.AddDataToSection('DocumentDateMonth', Format(ReportDate, 0, '<Month,2>'));
                    ExcelReportBuilderMgr.AddDataToSection('DocumentDateYear', Format(ReportDate, 0, '<Year>'));
                end;
                ExcelReportBuilderMgr.AddDataToSection('ReportOperationType', ReportOperationType);

                ExcelReportBuilderMgr.AddDataToSection('FactureNumber', HeaderBuffer."Vendor VAT Invoice No.");
                ExcelReportBuilderMgr.AddDataToSection('FactureDate', LocalisationManagement.Date2Text(HeaderBuffer."Vendor VAT Invoice Date"));

                if VendAgrmt.Get(HeaderBuffer."Buy-from Vendor No.", HeaderBuffer."Agreement No.") then begin
                    ExcelReportBuilderMgr.AddDataToSection('ContractNumber', Format(HeaderBuffer."External Agreement No."));
                    ExcelReportBuilderMgr.AddDataToSection('ContractDate',
                      LocalisationManagement.Date2Text(VendAgrmt."Agreement Date"));
                end;

                ExcelReportBuilderMgr.SetSheet('Sheet3');
                ExcelReportBuilderMgr.AddSection('PAGE3');

                if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
                     DocumentSignature."Employee Type"::Chairman, EmployeePosition, EmployeeName)
                then begin
                    ExcelReportBuilderMgr.AddDataToSection('CommissionHeadTitle', EmployeePosition);
                    ExcelReportBuilderMgr.AddDataToSection('CommissionHeadName', EmployeeName);
                end;

                if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
                     DocumentSignature."Employee Type"::Member1, EmployeePosition, EmployeeName)
                then begin
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember1Title', EmployeePosition);
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember1Name', EmployeeName);
                end;

                if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
                     DocumentSignature."Employee Type"::Member2, EmployeePosition, EmployeeName)
                then begin
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember2Title', EmployeePosition);
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember2Name', EmployeeName);
                end;

                if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
                     DocumentSignature."Employee Type"::Member3, EmployeePosition, EmployeeName)
                then begin
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember3Title', EmployeePosition);
                    ExcelReportBuilderMgr.AddDataToSection('CommissionMember3Name', EmployeeName);
                end;

                ExcelReportBuilderMgr.AddDataToSection('AccountantName', CompanyInformation."Accountant Name");

                if DocumentSignature.Get(
                     HeaderBuffer."No. of Documents", HeaderBuffer."Document Type",
                     HeaderBuffer."No.", DocumentSignature."Employee Type"::StoredBy)
                then
                    ExcelReportBuilderMgr.AddDataToSection('Stockkeeper', DocumentSignature."Employee Name")
                else
                    if Location.Get(HeaderBuffer."Location Code") and Employee.Get(Location."Responsible Employee No.") then
                        ExcelReportBuilderMgr.AddDataToSection('Stockkeeper', Employee.FullName());
            end;
        }
        dataitem(LineLoop; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            var
                QuantityDifference: Decimal;
                VatAmount: Decimal;
                QuantityDifferenceBase: Decimal;
                DiffAmount: Decimal;
                NetDiff: Decimal;
                GrossDiff: Decimal;
            begin
                if Number = 1 then
                    LineBuffer.FindSet()
                else
                    LineBuffer.Next();

                if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
                    ExcelReportBuilderMgr.AddPagebreak();
                    ExcelReportBuilderMgr.AddSection('PAGEHEADER');
                    ExcelReportBuilderMgr.AddSection('BODY');
                end;

                VatAmount := LineBuffer."Amount Including VAT" - LineBuffer.Amount;

                if ShowActualQty then begin
                    if LineBuffer.Surplus or LineBuffer."Special Order" then begin
                        FillFactInvoice(LineBuffer."Outstanding Quantity", LineBuffer.Quantity,
                          LineBuffer.Quantity * LineBuffer."Gross Weight",
                          LineBuffer.Quantity * LineBuffer."Net Weight", LineBuffer.Amount);

                        LineBuffer."Qty. to Receive" := LineBuffer.Quantity;
                        QuantityDifferenceBase := Round(LineBuffer.Quantity * LineBuffer."Outstanding Quantity", 1, '>');
                        DiffAmount := LineBuffer.Amount;
                        NetDiff := LineBuffer."Net Weight" * LineBuffer.Quantity;
                        GrossDiff := LineBuffer."Gross Weight" * LineBuffer.Quantity;

                        LineBuffer."Outstanding Quantity" := 0;
                        QuantityDifference := Round(LineBuffer.Quantity, 1, '>')
                    end else begin
                        FillPlannedInvoice(LineBuffer."Outstanding Quantity", LineBuffer.Quantity,
                          LineBuffer.Quantity * LineBuffer."Gross Weight",
                          LineBuffer.Quantity * LineBuffer."Net Weight", LineBuffer.Amount);
                        FillFactInvoice(LineBuffer."Unit Volume", LineBuffer."Qty. to Receive",
                          LineBuffer."Qty. to Receive" * LineBuffer."Gross Weight",
                          LineBuffer."Qty. to Receive" * LineBuffer."Net Weight", LineBuffer."Outstanding Amount");

                        NetDiff := LineBuffer."Qty. to Receive" * LineBuffer."Net Weight" - LineBuffer."Net Weight" * LineBuffer.Quantity;
                        GrossDiff := LineBuffer."Qty. to Receive" * LineBuffer."Gross Weight" - LineBuffer."Gross Weight" * LineBuffer.Quantity;

                        VatAmount := LineBuffer."Amount Including VAT" - LineBuffer."Outstanding Amount";
                        QuantityDifference := Round(LineBuffer."Qty. to Receive", 1, '>') - Round(LineBuffer.Quantity, 1, '>');
                        QuantityDifferenceBase := Round(LineBuffer."Qty. to Receive" * LineBuffer."Unit Volume", 1, '>') -
                          Round(LineBuffer.Quantity * LineBuffer."Outstanding Quantity", 1, '>');
                        DiffAmount := LineBuffer."Outstanding Amount" - LineBuffer.Amount;
                    end;

                    if QuantityDifferenceBase <> 0 then
                        FillPlannedFactDifference(
                          LineBuffer."Unit Volume" - LineBuffer."Outstanding Quantity",
                          QuantityDifference,
                          QuantityDifferenceBase,
                          GrossDiff,
                          NetDiff,
                          DiffAmount);
                end else
                    FillPlannedInvoice(LineBuffer."Outstanding Quantity", LineBuffer.Quantity, LineBuffer.Quantity * LineBuffer."Gross Weight",
                      LineBuffer.Quantity * LineBuffer."Net Weight", LineBuffer.Amount);

                FillGeneralInformationFields(Number, LineBuffer."No.", LineBuffer.Description,
                  LineBuffer."Unit of Measure Code", LineBuffer."Unit of Measure",
                  LineBuffer."Direct Unit Cost", LineBuffer."Amount Including VAT", LineBuffer."VAT %", VatAmount);
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderMgr.AddSection('REPORTFOOTER');
                FillSumFields();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, LineBuffer.Count);

                ExcelReportBuilderMgr.SetSheet('Sheet2');
                ExcelReportBuilderMgr.AddSection('PAGEHEADER');
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowActualQty; ShowActualQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Actual Quantity';
                        ToolTip = 'Specifies if the TORG-1 report must include actual quantities for received items.';
                    }
                    field(ReportNo; ReportNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order No';
                        ToolTip = 'Specifies the number of the related order.';
                    }
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order Date';
                        ToolTip = 'Specifies the creation date of the related order.';
                    }
                    field(ReportOperationType; ReportOperationType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
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

    trigger OnInitReport()
    begin
        InitReportTemplate();

        GLSetup.Get();
        CompanyInformation.Get();
    end;

    trigger OnPostReport()
    begin
        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        HeaderBuffer: Record "Purchase Header" temporary;
        LineBuffer: Record "Purchase Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        PurchLineWithLCYAmt: Record "Purchase Line" temporary;
        PurchLineWithLCYAmtToReceive: Record "Purchase Line" temporary;
        VendAgrmt: Record "Vendor Agreement";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LineCounter: Integer;
        ReportNo: Text;
        ReportDate: Date;
        ReportOperationType: Text;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountInclVATLCY: Decimal;
        TotalAmountInclVATLCYCalc: Decimal;
        TotalUnitsFact: Decimal;
        TotalUnitOfMeasureFact: Decimal;
        TotalUnitsPlan: Decimal;
        TotalUnitOfMeasurePlan: Decimal;
        TotalUnitsDiff: Decimal;
        TotalUnitOfMeasureDiff: Decimal;
        TotalDocGrossWeight: Decimal;
        TotalDocNetWeight: Decimal;
        TotalDocLineAmount: Decimal;
        TotalFactGrossWeight: Decimal;
        TotalFactNetWeight: Decimal;
        TotalFactLineAmount: Decimal;
        TotalDeviationGrossWeight: Decimal;
        TotalDeviationNetWeight: Decimal;
        TotalDeviationLineAmount: Decimal;
        TotalVATAmountLCY: Decimal;
        ShowActualQty: Boolean;
        FileName: Text;

    [Scope('OnPrem')]
    procedure FillHeaderBuffer(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocumentDate: Date; PostingDate: Date; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20]; LocationCode: Code[10]; VendorVatInvoiceNo: Code[20]; VendorVatInvoiceDate: Date; AgreementNo: Code[20]; ExtAgreementNo: Text[30])
    begin
        HeaderBuffer."Document Type" := "Purchase Document Type".FromInteger(DocumentType);
        HeaderBuffer."No." := DocumentNo;
        HeaderBuffer."Buy-from Vendor No." := BuyFromVendorNo;
        HeaderBuffer."Pay-to Vendor No." := PayToVendorNo;
        HeaderBuffer."No. of Documents" := TableID;
        HeaderBuffer."Document Date" := DocumentDate;
        HeaderBuffer."Posting Date" := PostingDate;
        HeaderBuffer."Location Code" := LocationCode;
        HeaderBuffer."Vendor VAT Invoice No." := VendorVatInvoiceNo;
        HeaderBuffer."Vendor VAT Invoice Date" := VendorVatInvoiceDate;
        HeaderBuffer."Agreement No." := AgreementNo;
        HeaderBuffer."External Agreement No." := ExtAgreementNo;
        HeaderBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure FillLineBuffer(LineNo: Integer; ItemNo: Code[20]; ItemName: Text[250]; UnitOfMeasureCode: Code[10]; PlannedQtyPerUnitOfMeasure: Decimal; FactQtyPerUnitOfMeasure: Decimal; Qty: Decimal; Price: Decimal; Amount: Decimal; ReceiveAmount: Decimal; NetWeight: Decimal; GrossWeight: Decimal; QtyToReceive: Decimal; AmountIncludingVAT: Decimal; VATPercent: Decimal; Surplus: Boolean; DocumentType: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LineBuffer."Line No." := LineNo;
        LineBuffer."No." := ItemNo;
        LineBuffer.Description := ItemName;
        LineBuffer."Unit of Measure Code" := UnitOfMeasureCode;
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            LineBuffer."Unit of Measure" := UnitOfMeasure.Description;
        LineBuffer."Outstanding Quantity" := PlannedQtyPerUnitOfMeasure;
        LineBuffer."Unit Volume" := FactQtyPerUnitOfMeasure;
        LineBuffer.Quantity := Qty;
        LineBuffer."Direct Unit Cost" := Price;
        LineBuffer.Amount := Amount;
        LineBuffer."Outstanding Amount" := ReceiveAmount;
        LineBuffer."Gross Weight" := GrossWeight;
        LineBuffer."Net Weight" := NetWeight;
        LineBuffer."Qty. to Receive" := QtyToReceive;
        LineBuffer."Amount Including VAT" := AmountIncludingVAT;
        LineBuffer."VAT %" := VATPercent;
        LineBuffer.Surplus := Surplus;
        LineBuffer."Special Order" := DocumentType;
        LineBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure FillGeneralInformationFields(LineNo: Integer; ItemNo: Code[20]; ItemName: Text[250]; UnitOfMeasureCode: Code[10]; UnitOfMeasureName: Text[50]; Price: Decimal; AmountIncludingVAT: Decimal; VATPercent: Decimal; VATCost: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        ExcelReportBuilderMgr.AddDataToSection('ItemName', Format(LineNo) + ' ' + ItemName);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', ItemNo);

        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            ExcelReportBuilderMgr.AddDataToSection('OKEI', UnitOfMeasure."OKEI Code");

        if UnitOfMeasureName <> '' then
            ExcelReportBuilderMgr.AddDataToSection('Unit', UnitOfMeasureName);
        if Price <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('Price', Format(Round(Price), 0, 1));

        if AmountIncludingVAT <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('LineAmountWithTax', StdRepMgt.FormatReportValue(Round(AmountIncludingVAT), 2));
        if VATPercent <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('VATValue', Format(VATPercent, 0, 1));
        if VATCost <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('VATAmount', StdRepMgt.FormatReportValue(Round(VATCost), 2));
        TotalVATAmountLCY += VATCost;
        TotalAmountInclVATLCYCalc += Round(AmountIncludingVAT);
    end;

    [Scope('OnPrem')]
    procedure FillPlannedInvoice(QtyperUnitofMeasure: Decimal; Quantity: Decimal; GrossWeight: Decimal; NetWeight: Decimal; UnitsPrice: Decimal)
    begin
        ExcelReportBuilderMgr.AddDataToSection('DocQtyPerUOM', Format(QtyperUnitofMeasure, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('DocQty', Format(Round(Quantity, 1, '>')) + '/' +
          Format(Round(Quantity * QtyperUnitofMeasure, 1, '>')));
        if GrossWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('DocGrossWeight', Format(GrossWeight, 0, 1));
        if NetWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('DocNetWeight', Format(NetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('DocLineAmount', StdRepMgt.FormatReportValue(Round(UnitsPrice), 2));

        TotalUnitOfMeasurePlan += Round(Quantity, 1, '>');
        TotalUnitsPlan += Round(Quantity * QtyperUnitofMeasure, 1);
        TotalDocGrossWeight += GrossWeight;
        TotalDocNetWeight += NetWeight;
        TotalDocLineAmount += Round(UnitsPrice);
    end;

    [Scope('OnPrem')]
    procedure FillFactInvoice(QtyperUnitofMeasure: Decimal; Quantity: Decimal; GrossWeight: Decimal; NetWeight: Decimal; UnitsPrice: Decimal)
    begin
        ExcelReportBuilderMgr.AddDataToSection('FactQtyPerUOM', Format(QtyperUnitofMeasure, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('FactQty', Format(Round(Quantity, 1, '>')) + '/' +
          Format(Round(Quantity * QtyperUnitofMeasure, 1, '>')));
        if GrossWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('FactGrossWeight', Format(GrossWeight, 0, 1));
        if NetWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('FactNetWeight', Format(NetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('FactLineAmount', StdRepMgt.FormatReportValue(Round(UnitsPrice), 2));

        TotalUnitOfMeasureFact += Round(Quantity, 1, '>');
        TotalUnitsFact += Round(Quantity * QtyperUnitofMeasure, 1);
        TotalFactGrossWeight += GrossWeight;
        TotalFactNetWeight += NetWeight;
        TotalFactLineAmount += UnitsPrice;
    end;

    [Scope('OnPrem')]
    procedure FillPlannedFactDifference(QtyperUnitofMeasure: Decimal; Quantity: Decimal; QuantityBase: Decimal; GrossWeight: Decimal; NetWeight: Decimal; UnitsPrice: Decimal)
    begin
        ExcelReportBuilderMgr.AddDataToSection('DeviationQtyPerUOM', Format(QtyperUnitofMeasure));
        ExcelReportBuilderMgr.AddDataToSection('DeviationQty', Format(Quantity) + '/' + Format(QuantityBase));
        if GrossWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('DeviationGrossWeight', Format(GrossWeight, 0, 1));
        if NetWeight <> 0 then
            ExcelReportBuilderMgr.AddDataToSection('DeviationNetWeight', Format(NetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('DeviationAmount', StdRepMgt.FormatReportValue(UnitsPrice, 2));

        TotalUnitOfMeasureDiff += Quantity;
        TotalUnitsDiff += QuantityBase;
        TotalDeviationGrossWeight += GrossWeight;
        TotalDeviationNetWeight += NetWeight;
        TotalDeviationLineAmount += UnitsPrice;
    end;

    [Scope('OnPrem')]
    procedure FillSumFields()
    begin
        ExcelReportBuilderMgr.AddDataToSection('totalNetQty', Format(TotalUnitOfMeasurePlan) + '/' + Format(TotalUnitsPlan));
        ExcelReportBuilderMgr.AddDataToSection('totalNetGrossweight', Format(TotalDocGrossWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalNetWeight', Format(TotalDocNetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalNetAmount', StdRepMgt.FormatReportValue(TotalDocLineAmount, 2));
        ExcelReportBuilderMgr.AddDataToSection('totalQty', Format(TotalUnitOfMeasureFact) + '/' + Format(TotalUnitsFact));
        ExcelReportBuilderMgr.AddDataToSection('totalGrossweight', Format(TotalFactGrossWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalLineNetweight', Format(TotalFactNetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalAmount', StdRepMgt.FormatReportValue(Round(TotalFactLineAmount), 2));
        ExcelReportBuilderMgr.AddDataToSection('totalAmountWithTax', StdRepMgt.FormatReportValue(TotalAmountInclVATLCYCalc, 2));
        ExcelReportBuilderMgr.AddDataToSection('totalVATAmount', StdRepMgt.FormatReportValue(Round(TotalVATAmountLCY), 2));
        ExcelReportBuilderMgr.AddDataToSection('totalDeviationQty', Format(TotalUnitOfMeasureDiff) + '/' + Format(TotalUnitsDiff));
        ExcelReportBuilderMgr.AddDataToSection('totalDeviationGrossweight', Format(TotalDeviationGrossWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalDeviationNetweight', Format(TotalDeviationNetWeight, 0, 1));
        ExcelReportBuilderMgr.AddDataToSection('totalDeviationAmount', StdRepMgt.FormatReportValue(TotalDeviationLineAmount, 2));
    end;

    [Scope('OnPrem')]
    procedure CalcAmounts(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        PurchasePosting: Codeunit "Purch.-Post";
    begin
        PurchasePosting.SumPurchLines2Ex(PurchHeader, PurchLineWithLCYAmt, PurchLine, 0,
          TotalAmount, TotalAmountInclVAT, TotalAmountLCY, TotalAmountInclVATLCY);
    end;

    [Scope('OnPrem')]
    procedure GetDocSignParameters(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; EmployeeType: Integer; var EmployeeJobTitle: Text[50]; var EmployeeName: Text[100]): Boolean
    var
        DocumentSignature: Record "Document Signature";
    begin
        if DocumentSignature.Get(TableID, DocumentType, DocumentNo, EmployeeType) then begin
            EmployeeJobTitle := DocumentSignature."Employee Job Title";
            EmployeeName := DocumentSignature."Employee Name";
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CalcReceivePurchLines(PurchHeader: Record "Purchase Header")
    var
        TempPurchLine: Record "Purchase Line" temporary;
        PurchLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchasePosting: Codeunit "Purch.-Post";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchLine.Find('-') then
            repeat
                TempPurchLine := PurchLine;

                if PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo" then
                    if PurchLine."Appl.-to Item Entry" <> 0 then begin
                        ItemLedgerEntry.Get(PurchLine."Appl.-to Item Entry");
                        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");
                        if ItemLedgerEntry."Qty. per Unit of Measure" <> 0 then
                            TempPurchLine.Quantity := ItemLedgerEntry.Quantity / ItemLedgerEntry."Qty. per Unit of Measure"
                        else
                            TempPurchLine.Quantity := ItemLedgerEntry.Quantity;
                    end else
                        TempPurchLine.Quantity := 0
                else
                    TempPurchLine.Quantity := TempPurchLine."Qty. to Receive";
                TempPurchLine.Insert();

            until PurchLine.Next() = 0;
        PurchasePosting.SumPurchLines2Ex(PurchHeader, PurchLineWithLCYAmtToReceive, TempPurchLine, 0,
          TotalAmount, TotalAmountInclVAT, TotalAmountLCY, TotalAmountInclVATLCY);
    end;

    [Scope('OnPrem')]
    procedure FillAmounts(PurchLine: Record "Purchase Line"; var Price: Decimal; var Amount: Decimal; var AmountInclVat: Decimal)
    begin
        if PurchLine.Quantity <> 0 then
            Price := PurchLine.Amount / PurchLine.Quantity;

        Amount := PurchLine.Amount;
        AmountInclVat := PurchLine."Amount Including VAT";
    end;

    local procedure InitReportTemplate()
    begin
        PurchSetup.Get();
        PurchSetup.TestField("TORG-1 Template Code");
        ExcelReportBuilderMgr.InitTemplate(PurchSetup."TORG-1 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewShowActualQty: Boolean; NewReportNo: Text; NewReportDate: Date; NewReportOperationType: Text)
    begin
        ShowActualQty := NewShowActualQty;
        ReportNo := NewReportNo;
        ReportDate := NewReportDate;
        ReportOperationType := NewReportOperationType;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

