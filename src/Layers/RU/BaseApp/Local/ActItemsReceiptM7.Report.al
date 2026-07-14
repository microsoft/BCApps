#pragma warning disable AA0247
report 14917 "Act Items Receipt M-7"
{
    Caption = 'Act Items Receipt M-7';
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
                    Qty: Decimal;
                    Price: Decimal;
                    Amount: Decimal;
                    FactQty: Decimal;
                    FactPrice: Decimal;
                    FactAmount: Decimal;
                    ShortageQty: Decimal;
                    ShortageAmount: Decimal;
                    SurplusQty: Decimal;
                    SurplusAmount: Decimal;
                begin
                    if Type = Type::Item then begin
                        TestField("Location Code");

                        FillLocationBuffer("No.", "Location Code",
                          GetDimValueCode("Purchase Line"."Dimension Set ID"));

                        case "Document Type" of
                            "Document Type"::Order,
                            "Document Type"::Invoice:
                                begin
                                    if Surplus then begin
                                        Qty := 0;
                                        Price := 0;
                                        Amount := 0;
                                    end else begin
                                        Qty := Quantity;
                                        Price := "Direct Unit Cost";
                                        Amount := Qty * Price;
                                        if PurchLineWithLCYAmt.Get("Document Type", "Document No.", "Line No.") then
                                            FillAmounts(PurchLineWithLCYAmt, Price, Amount);
                                    end;

                                    if ShowActualQty then begin
                                        FactQty := "Qty. to Receive";
                                        FactPrice := "Direct Unit Cost";
                                        FactAmount := FactQty * FactPrice;
                                        if PurchLineWithLCYAmtToReceive.Get("Document Type", "Document No.", "Line No.") then
                                            FillAmounts(PurchLineWithLCYAmtToReceive, FactPrice, FactAmount);
                                        if Surplus then begin
                                            SurplusQty := FactQty;
                                            SurplusAmount := FactAmount;
                                        end else begin
                                            ShortageQty := Abs(Quantity - FactQty);
                                            ShortageAmount := Abs(Amount - FactAmount);
                                        end;
                                    end;
                                end;
                            "Document Type"::"Credit Memo":
                                begin
                                    if "Appl.-to Item Entry" <> 0 then begin
                                        ItemLedgerEntry.Get("Appl.-to Item Entry");
                                        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Purchase Amount (Actual)");
                                        if "Qty. per Unit of Measure" <> 0 then
                                            Qty := ItemLedgerEntry.Quantity / "Qty. per Unit of Measure"
                                        else
                                            Qty := ItemLedgerEntry.Quantity;

                                        if (("Qty. per Unit of Measure" > 1) and (ItemLedgerEntry."Qty. per Unit of Measure" <> 1) and
                                            ("Qty. per Unit of Measure" <> ItemLedgerEntry."Qty. per Unit of Measure"))
                                        then begin
                                            Qty := ItemLedgerEntry.Quantity;
                                            FactQty := Qty - Quantity * "Qty. per Unit of Measure";
                                            Price := "Direct Unit Cost" / "Qty. per Unit of Measure";
                                            FactPrice := Price;
                                            ShortageQty := Quantity * "Qty. per Unit of Measure";
                                        end else begin
                                            Price := "Direct Unit Cost";
                                            FactQty := Qty - Quantity;
                                            FactPrice := "Direct Unit Cost";
                                            ShortageQty := Quantity;
                                        end;

                                        Amount := Qty * Price;
                                        FactAmount := FactQty * FactPrice;

                                        if PurchLineWithLCYAmtToReceive.Get("Document Type", "Document No.", "Line No.") then begin
                                            FillAmounts(PurchLineWithLCYAmtToReceive, Price, Amount);
                                            if Qty <> 0 then
                                                Price := Amount / Qty;
                                        end;

                                        if PurchLineWithLCYAmt.Get("Document Type", "Document No.", "Line No.") then begin
                                            FillAmounts(PurchLineWithLCYAmt, FactPrice, FactAmount);
                                            FactAmount := Amount - FactAmount;
                                        end;

                                        ShortageAmount := Amount - FactAmount;

                                        if FactQty <> 0 then
                                            FactPrice := FactAmount / FactQty;
                                    end;
                                    SurplusQty := 0;
                                    SurplusAmount := 0;
                                end;
                        end;

                        FillLineBuffer(
                          8 + LineCounter,
                          "No.",
                          Description,
                          "Unit of Measure Code",
                          Qty,
                          Price,
                          Amount,
                          FactQty,
                          FactPrice,
                          FactAmount,
                          0,
                          ShortageQty,
                          ShortageAmount,
                          SurplusQty,
                          SurplusAmount);

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
                  "Vendor Shipment No.");
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
                begin
                    FillLocationBuffer("Item No.", "Location Code",
                      GetDimValueCode("Invt. Document Line"."Dimension Set ID"));

                    TestField("Location Code");

                    FillLineBuffer(
                      8 + LineCounter,
                      "Item No.",
                      Description,
                      "Unit of Measure Code",
                      0,
                      0,
                      0,
                      Quantity,
                      "Unit Amount",
                      Quantity * "Unit Amount",
                      0,
                      0,
                      0,
                      Quantity,
                      Quantity * "Unit Amount");

                    LineCounter := LineCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeaderBuffer(
                  DATABASE::"Invt. Document Header",
                  0,
                  "No.",
                  "Document Date",
                  "Posting Date",
                  '',
                  '',
                  "Location Code",
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
                begin
                    FillLocationBuffer("Item No.", "Location Code",
                      GetDimValueCode("Invt. Receipt Line"."Dimension Set ID"));

                    TestField("Location Code");

                    FillLineBuffer(
                      8 + LineCounter,
                      "Item No.",
                      Description,
                      "Unit of Measure Code",
                      0,
                      0,
                      0,
                      Quantity,
                      "Unit Amount",
                      Quantity * "Unit Amount",
                      "Item Rcpt. Entry No.",
                      0,
                      0,
                      Quantity,
                      Quantity * "Unit Amount");

                    LineCounter := LineCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeaderBuffer(
                  DATABASE::"Invt. Receipt Header",
                  0,
                  "No.",
                  "Document Date",
                  "Posting Date",
                  '',
                  '',
                  "Location Code",
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
            begin
                FillSheet1();

                ExcelReportBuilderMgr.SetSheet('Sheet2');
                ExcelReportBuilderMgr.AddSection('PAGE2');

                FillSheet4();
            end;
        }
        dataitem(LineLoop; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    LineBuffer.FindSet()
                else
                    LineBuffer.Next();

                FillDocumentLine(
                  LineBuffer."No.",
                  LineBuffer.Description,
                  LineBuffer."Unit of Measure Code",
                  LineBuffer."Unit of Measure",
                  LineBuffer.Quantity,
                  LineBuffer."Direct Unit Cost",
                  LineBuffer."Line Amount",
                  LineBuffer."Quantity Received",
                  LineBuffer."Unit Price (LCY)",
                  LineBuffer."Outstanding Amount",
                  LineBuffer."Appl.-to Item Entry",
                  LineBuffer."Return Shpd. Not Invd.",
                  LineBuffer."VAT Base Amount",
                  LineBuffer."Return Qty. to Ship",
                  LineBuffer."Prepayment Amount");
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderMgr.AddSection('PAGEFOOTER');
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, LineBuffer.Count);

                ExcelReportBuilderMgr.SetSheet('Sheet3');
                ExcelReportBuilderMgr.AddSection('REPORTHEADER');

                if LocationBuffer.FindSet() then
                    repeat
                        FillLocationLine(
                          LocationBuffer."Dimension 1 Code",
                          OperationTypeCode,
                          OrgDepartment,
                          ActivityKind,
                          HeaderBuffer."Pay-to Vendor No.",
                          LocationBuffer."Dimension 1 Value Code",
                          LocationBuffer."Dimension 2 Code",
                          HeaderBuffer."Orig. Invoice No.");
                    until LocationBuffer.Next() = 0;

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
                    field(ShowActualQuantity; ShowActualQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Actual Quantity';
                        ToolTip = 'Specifies if the actual quantity received is displayed on the item receipt.';
                    }
                    field(OperationTypeCode; OperationTypeCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type Code';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
                    }
                    field(OrgDepartment; OrgDepartment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Organization Department';
                        ToolTip = 'Specifies the name of the receiving department.';
                    }
                    field(ActivityKind; ActivityKind)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Activity Kind';
                    }
                    field(CorrAccDimension; CorrAccDimension)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Corr. Acc. Dimension Code';
                        TableRelation = Dimension;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            DimensionTable: Record Dimension;
                            DimensionListForm: Page "Dimension List";
                        begin
                            DimensionListForm.LookupMode := true;
                            if DimensionListForm.RunModal() = ACTION::LookupOK then begin
                                DimensionListForm.GetRecord(DimensionTable);
                                CorrAccDimension := DimensionTable.Code;
                            end;
                        end;
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
        CompanyInformation.Get();
        GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            ExcelReportBuilderMgr.ExportData()
        else
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName);
    end;

    trigger OnPreReport()
    begin
        InitReportTemplate();
    end;

    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        UnitOfMeasure: Record "Unit of Measure";
        Employee: Record Employee;
        LocationBuffer: Record "Dimension Value Combination" temporary;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        DocumentSignature: Record "Document Signature";
        HeaderBuffer: Record "Purchase Header" temporary;
        LineBuffer: Record "Purchase Line" temporary;
        VendAgrmt: Record "Vendor Agreement";
        HeaderLocation: Record Location;
        PurchLineWithLCYAmt: Record "Purchase Line" temporary;
        PurchLineWithLCYAmtToReceive: Record "Purchase Line" temporary;
        LocMgt: Codeunit "Localisation Management";
        LocalReportManagement: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        OperationTypeCode: Code[10];
        OrgDepartment: Code[10];
        ActivityKind: Code[10];
        CorrAccDimension: Code[20];
        ShowActualQty: Boolean;
        FileName: Text;
        LineCounter: Integer;

    local procedure FillLocationBuffer(ItemNo: Code[20]; LocationCode: Code[10]; DimValueCode: Code[20])
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.Get(LocationCode, Item."Inventory Posting Group");
        if not LocationBuffer.Get(LocationCode, InventoryPostingSetup."Inventory Account", DimValueCode, '') then begin
            LocationBuffer."Dimension 1 Code" := LocationCode;
            LocationBuffer."Dimension 1 Value Code" := InventoryPostingSetup."Inventory Account";
            LocationBuffer."Dimension 2 Code" := DimValueCode;
            LocationBuffer.Insert();
        end;
    end;

    local procedure FillHeaderBuffer(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocumentDate: Date; PostingDate: Date; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20]; LocationCode: Code[10]; VendorShipmentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if TableID = DATABASE::"Purchase Header" then begin
            PurchaseHeader.Get(DocumentType, DocumentNo);
            HeaderBuffer.TransferFields(PurchaseHeader);
            HeaderBuffer."Pmt. Discount Date" := 0D;
            if HeaderBuffer."Agreement No." <> '' then begin
                VendAgrmt.Get(HeaderBuffer."Buy-from Vendor No.", HeaderBuffer."Agreement No.");
                HeaderBuffer."Pmt. Discount Date" := VendAgrmt."Agreement Date";
            end;
        end else begin
            HeaderBuffer."Document Type" := "Purchase Document Type".FromInteger(DocumentType);
            HeaderBuffer."No." := DocumentNo;
            HeaderBuffer."Buy-from Vendor No." := BuyFromVendorNo;
            HeaderBuffer."Pay-to Vendor No." := PayToVendorNo;
        end;
        HeaderBuffer."Orig. Invoice No." := VendorShipmentNo;
        HeaderBuffer."No. of Documents" := TableID;
        HeaderBuffer."Document Date" := DocumentDate;
        HeaderBuffer."Posting Date" := PostingDate;
        HeaderBuffer."Location Code" := LocationCode;
        HeaderBuffer.Insert();
    end;

    local procedure FillLineBuffer(LineNo: Integer; ItemNo: Code[20]; ItemName: Text[250]; UnitOfMeasureCode: Code[10]; Qty: Decimal; Price: Decimal; Amount: Decimal; FactQty: Decimal; FactPrice: Decimal; FactAmount: Decimal; ItemEntryNo: Integer; DeficitQty: Decimal; DeficitAmount: Decimal; SurplusQty: Decimal; SurplusAmount: Decimal)
    begin
        LineBuffer."Line No." := LineNo;
        LineBuffer."No." := ItemNo;
        LineBuffer.Description := ItemName;
        LineBuffer."Unit of Measure Code" := UnitOfMeasureCode;
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            LineBuffer."Unit of Measure" := UnitOfMeasure.Description;
        LineBuffer.Quantity := Qty;
        LineBuffer."Direct Unit Cost" := Price;
        LineBuffer."Line Amount" := Amount;
        LineBuffer."Quantity Received" := FactQty;
        LineBuffer."Unit Price (LCY)" := FactPrice;
        LineBuffer."Outstanding Amount" := FactAmount;
        LineBuffer."Appl.-to Item Entry" := ItemEntryNo;
        LineBuffer."Return Shpd. Not Invd." := DeficitQty;
        LineBuffer."VAT Base Amount" := DeficitAmount;
        LineBuffer."Return Qty. to Ship" := SurplusQty;
        LineBuffer."Prepayment Amount" := SurplusAmount;
        LineBuffer.Insert();
    end;

    local procedure FillDocumentLine(ItemNo: Code[20]; ItemName: Text[250]; UnitOfMeasureCode: Code[10]; UnitOfMeasureName: Text[50]; Qty: Decimal; Price: Decimal; Amount: Decimal; FactQty: Decimal; FactPrice: Decimal; FactAmount: Decimal; ItemEntryNo: Integer; DeficitQty: Decimal; DeficitAmount: Decimal; SurplusQty: Decimal; SurplusAmount: Decimal)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('ItemName', ItemName);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', ItemNo);

        ExcelReportBuilderMgr.AddDataToSection('Unit', UnitOfMeasureCode);
        ExcelReportBuilderMgr.AddDataToSection('UnitName', UnitOfMeasureName);

        ExcelReportBuilderMgr.AddDataToSection('DocQty', BlankZeroValue(Qty));
        ExcelReportBuilderMgr.AddDataToSection('DocPrice', BlankZeroValue(Round(Price)));
        ExcelReportBuilderMgr.AddDataToSection('DocAmount', BlankZeroValue(Round(Amount)));
        ExcelReportBuilderMgr.AddDataToSection('FactQty', BlankZeroValue(FactQty));
        ExcelReportBuilderMgr.AddDataToSection('FactPrice', BlankZeroValue(Round(FactPrice)));
        ExcelReportBuilderMgr.AddDataToSection('FactAmount', BlankZeroValue(Round(FactAmount)));
        ExcelReportBuilderMgr.AddDataToSection('ItemEntryNo', BlankZeroValue(ItemEntryNo));
        ExcelReportBuilderMgr.AddDataToSection('LossQty', BlankZeroValue(DeficitQty));
        ExcelReportBuilderMgr.AddDataToSection('LossAmount', BlankZeroValue(DeficitAmount));
        ExcelReportBuilderMgr.AddDataToSection('ExcessQty', BlankZeroValue(SurplusQty));
        ExcelReportBuilderMgr.AddDataToSection('ExcessAmount', BlankZeroValue(Round(SurplusAmount)));
    end;

    local procedure FillLocationLine(LocationCode: Code[20]; OperationTypeCode: Code[10]; OrgDepartment: Code[10]; ActivityKind: Code[10]; VendorNo: Code[20]; GLAccountNo: Code[20]; CorrAccDimValue: Code[20]; DocumentNo: Code[20])
    var
        Location: Record Location;
    begin
        ExcelReportBuilderMgr.AddSection('LocationBody');
        Location.Get(LocationCode);

        ExcelReportBuilderMgr.AddDataToSection('OperationType', OperationTypeCode);
        ExcelReportBuilderMgr.AddDataToSection('DepartmentName', OrgDepartment);
        ExcelReportBuilderMgr.AddDataToSection('ActivityCategory', ActivityKind);
        ExcelReportBuilderMgr.AddDataToSection('StockName', Location.Name + Location."Name 2");
        ExcelReportBuilderMgr.AddDataToSection('VendAccount', VendorNo);
        ExcelReportBuilderMgr.AddDataToSection('LedgerAccount', GLAccountNo);
        ExcelReportBuilderMgr.AddDataToSection('AnalysisCode', CorrAccDimValue);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNo', DocumentNo);
    end;

    local procedure GetDocSignParameters(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; EmployeeType: Integer; var EmployeePosition: Text[50]; var EmployeeName: Text[50]; var EmployeeDocument: Text[250]): Boolean
    begin
        case TableID of
            DATABASE::"Purchase Header",
            DATABASE::"Invt. Document Header":
                exit(
                  LocalReportManagement.GetDocSignEmplInfo(
                    false,
                    TableID,
                    DocumentType,
                    DocumentNo,
                    EmployeeType,
                    EmployeePosition,
                    EmployeeName,
                    EmployeeDocument));
            DATABASE::"Invt. Receipt Header":
                exit(
                  LocalReportManagement.GetDocSignEmplInfo(
                    true,
                    TableID,
                    DocumentType,
                    DocumentNo,
                    EmployeeType,
                    EmployeePosition,
                    EmployeeName,
                    EmployeeDocument));
        end;

        exit(false);
    end;

    local procedure GetDimValueCode(DimSetID: Integer): Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if CorrAccDimension <> '' then
            if DimSetEntry.Get(DimSetID, CorrAccDimension) then
                exit(DimSetEntry."Dimension Value Code");

        exit('');
    end;

    local procedure CalcAmounts(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        PurchasePosting: Codeunit "Purch.-Post";
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountInclVATLCY: Decimal;
    begin
        PurchasePosting.SumPurchLines2Ex(PurchHeader, PurchLineWithLCYAmt, PurchLine, 0,
          TotalAmount, TotalAmountInclVAT, TotalAmountLCY, TotalAmountInclVATLCY);
    end;

    local procedure CalcReceivePurchLines(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempPurchLine: Record "Purchase Line" temporary;
        PurchasePosting: Codeunit "Purch.-Post";
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountInclVATLCY: Decimal;
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchLine.FindSet() then
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

    local procedure FillAmounts(PurchLine: Record "Purchase Line"; var Price: Decimal; var Amount: Decimal)
    begin
        if PurchLine.Quantity <> 0 then
            Price := PurchLine.Amount / PurchLine.Quantity;

        Amount := PurchLine.Amount;
    end;

    local procedure InitReportTemplate()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("M-7 Template Code");
        ExcelReportBuilderMgr.InitTemplate(PurchSetup."M-7 Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillSheet1()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet1');
        ExcelReportBuilderMgr.AddSection('PAGE1');

        ExcelReportBuilderMgr.AddDataToSection('DocumentNumber', HeaderBuffer."No.");

        if CompanyInformation."Director No." <> '' then
            if Employee.Get(CompanyInformation."Director No.") then begin
                ExcelReportBuilderMgr.AddDataToSection('DirectorPosition', Employee.GetJobTitleName());
                ExcelReportBuilderMgr.AddDataToSection('DirectorName', CompanyInformation."Director Name");
            end;

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', LocalReportManagement.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInformation."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(HeaderBuffer."Document Date"));

        if HeaderBuffer."Buy-from Vendor No." <> '' then begin
            Vendor.Get(HeaderBuffer."Buy-from Vendor No.");
            ExcelReportBuilderMgr.AddDataToSection('InvoiceAccountName',
              LocalReportManagement.GetVendorName(HeaderBuffer."Buy-from Vendor No.") + ', ' +
              HeaderBuffer."Buy-from Address" + HeaderBuffer."Buy-from Address 2" + ', ' +
              HeaderBuffer."Buy-from City" + ', ' +
              HeaderBuffer."Buy-from Post Code" + ', ' +
              HeaderBuffer."Buy-from County" + ', ' +
              Vendor."Phone No.");
        end;

        if HeaderBuffer."Pay-to Vendor No." <> '' then begin
            Vendor.Get(HeaderBuffer."Pay-to Vendor No.");
            ExcelReportBuilderMgr.AddDataToSection('VendAccountName',
              LocalReportManagement.GetVendorName(HeaderBuffer."Pay-to Vendor No.") + ', ' +
              HeaderBuffer."Pay-to Address" + HeaderBuffer."Pay-to Address 2" + ', ' +
              HeaderBuffer."Pay-to City" + ', ' +
              HeaderBuffer."Pay-to Post Code" + ', ' +
              HeaderBuffer."Pay-to County" + ', ' +
              Vendor."Phone No.");
        end;

        ExcelReportBuilderMgr.AddDataToSection('AcceptorAccount',
          LocalReportManagement.GetCompanyName() + ',' +
          CompanyInformation.Address + CompanyInformation."Address 2" + ',' +
          CompanyInformation."Phone No.");

        if HeaderBuffer."External Agreement No." <> '' then
            ExcelReportBuilderMgr.AddDataToSection('ContractNumber', HeaderBuffer."External Agreement No.")
        else
            ExcelReportBuilderMgr.AddDataToSection('ContractNumber', HeaderBuffer."Agreement No.");

        if HeaderBuffer."Pmt. Discount Date" <> 0D then
            ExcelReportBuilderMgr.AddDataToSection('ContractDate', LocMgt.Date2Text(HeaderBuffer."Pmt. Discount Date"));
    end;

    local procedure FillSheet4()
    var
        EmployeePosition: Text[50];
        EmployeeName: Text[50];
        EmployeeDocument: Text[250];
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet4');
        ExcelReportBuilderMgr.AddSection('PAGE4');

        ExcelReportBuilderMgr.AddDataToSection('AcceptanceDate', Format(HeaderBuffer."Posting Date"));

        ExcelReportBuilderMgr.AddDataToSection('ActNo', Format(HeaderBuffer."No."));
        ExcelReportBuilderMgr.AddDataToSection('ActDay', Format(HeaderBuffer."Document Date", 0, '<Day,2>'));

        ExcelReportBuilderMgr.AddDataToSection('ActMonth', Format(LocMgt.Month2Text(HeaderBuffer."Document Date")));
        ExcelReportBuilderMgr.AddDataToSection('ActYear', Format(HeaderBuffer."Document Date", 0, '<Year>'));

        if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
             DocumentSignature."Employee Type"::Member1, EmployeePosition, EmployeeName, EmployeeDocument)
        then begin
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember1Title', EmployeePosition);
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember1Name', EmployeeName);
            ExcelReportBuilderMgr.AddDataToSection('CommissionDocument1', EmployeeDocument);
        end;

        if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
             DocumentSignature."Employee Type"::Member2, EmployeePosition, EmployeeName, EmployeeDocument)
        then begin
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember2Title', EmployeePosition);
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember2Name', EmployeeName);
            ExcelReportBuilderMgr.AddDataToSection('CommissionDocument2', EmployeeDocument);
        end;

        if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
             DocumentSignature."Employee Type"::Member3, EmployeePosition, EmployeeName, EmployeeDocument)
        then begin
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember3Title', EmployeePosition);
            ExcelReportBuilderMgr.AddDataToSection('CommissionMember3Name', EmployeeName);
            ExcelReportBuilderMgr.AddDataToSection('CommissionDocument3', EmployeeDocument);
        end;

        if GetDocSignParameters(HeaderBuffer."No. of Documents", HeaderBuffer."Document Type".AsInteger(), HeaderBuffer."No.",
             DocumentSignature."Employee Type"::StoredBy, EmployeePosition, EmployeeName, EmployeeDocument)
        then
            ExcelReportBuilderMgr.AddDataToSection('Stockkeeper', EmployeeName)
        else
            if HeaderLocation.Get(HeaderBuffer."Location Code") then
                ExcelReportBuilderMgr.AddDataToSection('Stockkeeper', HeaderLocation.Contact);
    end;

    local procedure BlankZeroValue(Value: Decimal): Text
    begin
        if Value = 0 then
            exit('');

        exit(Format(Value));
    end;
}

