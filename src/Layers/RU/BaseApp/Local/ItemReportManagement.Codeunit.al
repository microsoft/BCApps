#pragma warning disable AA0247
codeunit 12462 "Item Report Management"
{

    trigger OnRun()
    begin
    end;

    var
        NoItemDeviationsErr: Label 'There are no item deviations for the document.';
        TelTxt: Label 'tel.: ';
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        Torg2RHeaderId: Integer;

    [Scope('OnPrem')]
    procedure PrintTORG2(DocPrintBuffer: Record "Document Print Buffer"; OperationType: Text[30]; OrderNo: Code[20]; OrderDate: Date; FileName: Text)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseHeaderTemp: Record "Purchase Header" temporary;
        PurchaseLineTemp: Record "Purchase Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtReceiptHeader: Record "Invt. Receipt Header";
    begin
        PurchSetup.Get();

        case DocPrintBuffer."Table ID" of
            DATABASE::"Purchase Header":
                begin
                    PurchaseHeader.Get(DocPrintBuffer."Document Type", DocPrintBuffer."Document No.");
                    PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
                    PurchaseHeaderTemp.Init();
                    PurchaseHeaderTemp.TransferFields(PurchaseHeader);
                    PurchaseHeaderTemp.Insert();
                end;
            DATABASE::"Invt. Document Header":
                begin
                    InvtDocumentHeader.Get(DocPrintBuffer."Document Type", DocPrintBuffer."Document No.");
                    InvtDocumentHeader.TestField(Status, InvtDocumentHeader.Status::Released);
                    PurchaseHeaderTemp.Init();
                    PurchaseHeaderTemp."Location Code" := InvtDocumentHeader."Location Code";
                    PurchaseHeaderTemp."No." := InvtDocumentHeader."No.";
                    PurchaseHeaderTemp."Document Date" := InvtDocumentHeader."Document Date";
                    PurchaseHeaderTemp.Insert();
                end;
            DATABASE::"Invt. Receipt Header":
                begin
                    InvtReceiptHeader.Get(DocPrintBuffer."Document No.");
                    PurchaseHeaderTemp.Init();
                    PurchaseHeaderTemp."Location Code" := InvtReceiptHeader."Location Code";
                    PurchaseHeaderTemp."No." := InvtReceiptHeader."No.";
                    PurchaseHeaderTemp."Document Date" := InvtReceiptHeader."Document Date";
                    PurchaseHeaderTemp.Insert();
                end;
        end;

        CopyDocLinesToTempDocLines(DocPrintBuffer, PurchaseLineTemp);
        if CalculateNumberOfLines(PurchaseLineTemp, DocPrintBuffer."Table ID") = 0 then
            Error(NoItemDeviationsErr);

        PurchSetup.TestField("TORG-2 Template Code");
        ExcelReportBuilderMgr.InitTemplate(PurchSetup."TORG-2 Template Code");

        FillGeneralInfo(OperationType, OrderNo, OrderDate);
        FillHeader(DocPrintBuffer, PurchaseHeaderTemp);

        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    local procedure FillGeneralInfo(OperationType: Text[30]; OrderNo: Code[20]; OrderDate: Date)
    var
        CompanyInfo: Record "Company Information";
        StdRepMgt: Codeunit "Local Report Management";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderMgr.SetSheet('Sheet1');
        ExcelReportBuilderMgr.AddSection('PAGE1');
        ExcelReportBuilderMgr.AddDataToSection(
          'CompanyName',
          StdRepMgt.GetCompanyName() + ' ' +
          StdRepMgt.GetCompanyAddress() + ' ' +
          StdRepMgt.GetCompanyPhoneFax());
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('OKDP', CompanyInfo."OKVED Code");
        ExcelReportBuilderMgr.AddDataToSection('OrderNo', OrderNo);
        if OrderDate <> 0D then begin
            ExcelReportBuilderMgr.AddDataToSection('DocumentDateDay', Format(OrderDate, 0, '<Day,2>'));
            ExcelReportBuilderMgr.AddDataToSection('DocumentDateMonth', Format(OrderDate, 0, '<Month,2>'));
            ExcelReportBuilderMgr.AddDataToSection('DocumentDateYear', Format(OrderDate, 0, '<Year>'));
        end;
        ExcelReportBuilderMgr.AddDataToSection('OperationType', OperationType);
        ExcelReportBuilderMgr.AddDataToSection('DirectorPosition', StdRepMgt.GetEmpPosition(CompanyInfo."Director No."));
        ExcelReportBuilderMgr.AddDataToSection('DirectorName', CompanyInfo."Director Name");
    end;

    local procedure FillHeader(DocPrintBuffer: Record "Document Print Buffer"; var PurchaseHeaderBuffer: Record "Purchase Header" temporary)
    var
        PurchaseLineTemp: Record "Purchase Line" temporary;
        Location: Record Location;
        Vendor: Record Vendor;
        TransportMethod: Record "Transport Method";
        VendorAgreement: Record "Vendor Agreement";
        LocalMgt: Codeunit "Localisation Management";
        LocalReportMgt: Codeunit "Local Report Management";
        Address: Text;
        Name: Text[250];
    begin
        if Location.Get(PurchaseHeaderBuffer."Location Code") then
            ExcelReportBuilderMgr.AddDataToSection('DepartmentName', Location.Name);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNumber', PurchaseHeaderBuffer."No.");
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(PurchaseHeaderBuffer."Document Date"));

        if DocPrintBuffer."Table ID" = DATABASE::"Purchase Header" then begin
            ExcelReportBuilderMgr.AddDataToSection('VendorReceiptDoc', PurchaseHeaderBuffer."Vendor Receipts No." + ' ' + Format(PurchaseHeaderBuffer."Vendor Receipts Date"));

            if PurchaseHeaderBuffer."Agreement No." <> '' then begin
                ExcelReportBuilderMgr.AddDataToSection('ContractNumber', PurchaseHeaderBuffer."Agreement No.");
                VendorAgreement.Get(PurchaseHeaderBuffer."Buy-from Vendor No.", PurchaseHeaderBuffer."Agreement No.");
                ExcelReportBuilderMgr.AddDataToSection('ContractDateDay', Format(VendorAgreement."Agreement Date", 0, '<Day>'));
                ExcelReportBuilderMgr.AddDataToSection('ContractDateMonth', LocalMgt.Month2Text(VendorAgreement."Agreement Date"));
                ExcelReportBuilderMgr.AddDataToSection('ContractDateYear', Format(VendorAgreement."Agreement Date", 0, '<Year>'));
            end;

            if PurchaseHeaderBuffer."Vendor VAT Invoice No." <> '' then begin
                ExcelReportBuilderMgr.AddDataToSection('VendorVATInvoiceNo', PurchaseHeaderBuffer."Vendor VAT Invoice No.");
                ExcelReportBuilderMgr.AddDataToSection('VendorVATInvoiceDateDay', Format(PurchaseHeaderBuffer."Vendor VAT Invoice Date", 0, '<Day>'));
                ExcelReportBuilderMgr.AddDataToSection('VendorVATInvoiceDateMonth', LocalMgt.Month2Text(PurchaseHeaderBuffer."Vendor VAT Invoice Date"));
                ExcelReportBuilderMgr.AddDataToSection('VendorVATInvoiceDateYear', Format(PurchaseHeaderBuffer."Vendor VAT Invoice Date", 0, '<Year>'));
            end;

            if TransportMethod.Get(PurchaseHeaderBuffer."Transport Method") then
                ExcelReportBuilderMgr.AddDataToSection('TransportMethod', TransportMethod.Description);

            ExcelReportBuilderMgr.AddDataToSection('CompanyAddress',
              PurchaseHeaderBuffer."Ship-to Post Code" + ' ' + PurchaseHeaderBuffer."Ship-to City" + ', ' +
              PurchaseHeaderBuffer."Ship-to Address" + ' ' + PurchaseHeaderBuffer."Ship-to Address 2");

            Vendor.Get(PurchaseHeaderBuffer."Buy-from Vendor No.");
            Address :=
              LocalReportMgt.GetFullAddr(
                PurchaseHeaderBuffer."Buy-from Post Code", PurchaseHeaderBuffer."Buy-from City", PurchaseHeaderBuffer."Buy-from Address", PurchaseHeaderBuffer."Buy-from Address 2", '', PurchaseHeaderBuffer."Buy-from County");
            Name := LocalReportMgt.GetVendorName(PurchaseHeaderBuffer."Buy-from Vendor No.");
            if Vendor."Phone No." <> '' then
                ExcelReportBuilderMgr.AddDataToSection('InvoiceAccountName',
                  Name + ', ' + Address + ', ' + PurchaseHeaderBuffer."Buy-from Address 2" + ', ' + TelTxt + Vendor."Phone No.")
            else
                ExcelReportBuilderMgr.AddDataToSection('InvoiceAccountName', Name + ', ' + Address + ', ' + PurchaseHeaderBuffer."Buy-from Address 2");

            Address := '';
            Vendor.Get(PurchaseHeaderBuffer."Pay-to Vendor No.");
            Address :=
              LocalReportMgt.GetFullAddr(PurchaseHeaderBuffer."Pay-to Post Code", PurchaseHeaderBuffer."Pay-to City", PurchaseHeaderBuffer."Pay-to Address", PurchaseHeaderBuffer."Pay-to Address 2", '', PurchaseHeaderBuffer."Pay-to County");
            Name := LocalReportMgt.GetVendorName(PurchaseHeaderBuffer."Pay-to Vendor No.");
            if Vendor."Phone No." <> '' then
                ExcelReportBuilderMgr.AddDataToSection('VendAccountName',
                  Name + ', ' + Address + ', ' + PurchaseHeaderBuffer."Pay-to Address 2" + ', ' + TelTxt + Vendor."Phone No.")
            else
                ExcelReportBuilderMgr.AddDataToSection('VendAccountName', Name + ', ' + Address + ', ' + PurchaseHeaderBuffer."Pay-to Address 2");
        end;

        CopyDocLinesToTempDocLines(DocPrintBuffer, PurchaseLineTemp);
        FillLines(DocPrintBuffer, PurchaseHeaderBuffer, PurchaseLineTemp);
    end;

    local procedure FillLines(DocumentPrintBuffer: Record "Document Print Buffer"; var TempPurchHeader: Record "Purchase Header" temporary; var TempPurchLine: Record "Purchase Line" temporary)
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLineBuffer: Record "Purchase Line" temporary;
        TotalAccomQty: Decimal;
        TotalAccomQtyToReceive: Decimal;
        TotalGrossWeight: Decimal;
        TotalNetWeight: Decimal;
        DecimalArray: array[17] of Decimal;
        TextArray: array[5] of Text[250];
        CurrencyFactor: Decimal;
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet2');
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');
        Torg2RHeaderId := ExcelReportBuilderMgr.GetCurrentSectionId();

        CopyDocLinesToTempDocLines(DocumentPrintBuffer, PurchaseLineBuffer);
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');
        if TempPurchLine.FindSet() then
            repeat
                ClearArrays(DecimalArray, TextArray);
                if (TempPurchLine.Quantity <> TempPurchLine."Qty. to Receive") or TempPurchLine.Surplus or
                   (DocumentPrintBuffer."Table ID" <> DATABASE::"Purchase Header")
                then begin
                    if TempPurchHeader."Currency Code" <> '' then
                        CurrencyFactor := TempPurchHeader."Currency Factor"
                    else
                        CurrencyFactor := 1;

                    TextArray[1] := TempPurchLine.Description + ' ' + TempPurchLine."Description 2";
                    Item.Get(TempPurchLine."No.");
                    UnitOfMeasure.Get(Item."Base Unit of Measure");
                    TextArray[2] := UnitOfMeasure.Description;
                    TextArray[3] := UnitOfMeasure."OKEI Code";
                    if DocumentPrintBuffer."Table ID" = DATABASE::"Purchase Header" then
                        TextArray[4] := TempPurchLine."No.";
                    TextArray[5] := TempPurchLine."No.";

                    DecimalArray[1] := TempPurchLine.Quantity;

                    ItemUnitOfMeasure.SetRange("Item No.", TempPurchLine."No.");
                    ItemUnitOfMeasure.SetRange(Code, TempPurchLine."Unit of Measure");
                    DecimalArray[8] := TempPurchLine.Amount / CurrencyFactor / TempPurchLine."Quantity (Base)";
                    if DocumentPrintBuffer."Table ID" = DATABASE::"Purchase Header" then
                        DecimalArray[5] := DecimalArray[8]
                    else
                        DecimalArray[8] := TempPurchLine."Direct Unit Cost" / CurrencyFactor / (TempPurchLine."Quantity (Base)" / TempPurchLine.Quantity);

                    if DocumentPrintBuffer."Table ID" = DATABASE::"Purchase Header" then begin
                        if (TempPurchHeader."Document Type" = TempPurchHeader."Document Type"::"Credit Memo") and not TempPurchLine.Surplus then begin
                            if TempPurchLine."Appl.-to Item Entry" <> 0 then begin
                                ItemLedgerEntry.Get(TempPurchLine."Appl.-to Item Entry");
                                if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Purchase Receipt" then begin
                                    PurchRcptLine.Get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.");
                                    DecimalArray[2] := PurchRcptLine."Gross Weight" * PurchRcptLine.Quantity;
                                    DecimalArray[3] := DecimalArray[2];
                                    TotalNetWeight := TotalNetWeight + PurchRcptLine."Net Weight" * PurchRcptLine.Quantity;
                                end;
                                DecimalArray[1] := ItemLedgerEntry.Quantity / ItemLedgerEntry."Qty. per Unit of Measure";
                                DecimalArray[4] := ItemLedgerEntry.Quantity;
                                DecimalArray[6] := DecimalArray[4] * DecimalArray[5];
                                DecimalArray[7] := DecimalArray[4] - TempPurchLine."Return Qty. to Ship (Base)";
                                TotalAccomQtyToReceive := TotalAccomQtyToReceive + DecimalArray[1] - TempPurchLine.Quantity;
                            end
                        end else
                            if TempPurchLine.Surplus then begin
                                PurchaseLineBuffer.SetRange("No.", TempPurchLine."No.");
                                PurchaseLineBuffer.SetRange(Surplus, false);
                                DecimalArray[1] := 0;
                                if PurchaseLineBuffer.FindSet() then
                                    repeat
                                        if PurchaseLineBuffer.Quantity = PurchaseLineBuffer."Qty. to Receive" then begin
                                            DecimalArray[1] := DecimalArray[1] + PurchaseLineBuffer.Quantity;
                                            DecimalArray[2] := DecimalArray[2] + PurchaseLineBuffer."Gross Weight" * PurchaseLineBuffer.Quantity;
                                            DecimalArray[4] := DecimalArray[4] + PurchaseLineBuffer."Quantity (Base)";
                                            DecimalArray[6] := DecimalArray[6] + PurchaseLineBuffer.Amount / CurrencyFactor;
                                            DecimalArray[7] := DecimalArray[7] + PurchaseLineBuffer."Qty. to Receive (Base)";
                                            TotalAccomQtyToReceive := TotalAccomQtyToReceive + PurchaseLineBuffer.Quantity;
                                            TotalNetWeight := TotalNetWeight + PurchaseLineBuffer."Net Weight" * PurchaseLineBuffer.Quantity;
                                        end;
                                    until PurchaseLineBuffer.Next() = 0;
                                DecimalArray[3] := DecimalArray[2] + TempPurchLine."Gross Weight" * TempPurchLine.Quantity;
                                DecimalArray[7] := DecimalArray[7] + TempPurchLine."Qty. to Receive (Base)";
                            end else begin
                                DecimalArray[2] := TempPurchLine."Gross Weight" * TempPurchLine.Quantity;
                                DecimalArray[3] := DecimalArray[2];
                                DecimalArray[4] := TempPurchLine."Quantity (Base)";
                                DecimalArray[6] := TempPurchLine.Amount / CurrencyFactor;
                                DecimalArray[7] := TempPurchLine."Qty. to Receive (Base)";
                                TotalNetWeight := TotalNetWeight + TempPurchLine."Net Weight" * TempPurchLine.Quantity;
                            end
                    end else
                        DecimalArray[7] := TempPurchLine."Quantity (Base)";

                    DecimalArray[9] := DecimalArray[7] * Round(DecimalArray[8], 0.01);

                    if DocumentPrintBuffer."Table ID" = DATABASE::"Purchase Header" then begin
                        if DecimalArray[4] > DecimalArray[7] then
                            DecimalArray[14] := DecimalArray[4] - DecimalArray[7]
                        else
                            DecimalArray[16] := DecimalArray[7] - DecimalArray[4];
                        DecimalArray[15] := DecimalArray[14] * DecimalArray[5];
                        DecimalArray[17] := DecimalArray[16] * DecimalArray[5];
                    end;

                    TotalAccomQty := TotalAccomQty + DecimalArray[1];
                    if DocumentPrintBuffer."Table ID" = DATABASE::"Purchase Header" then
                        TotalAccomQtyToReceive := TotalAccomQtyToReceive + TempPurchLine."Qty. to Receive"
                    else
                        TotalAccomQtyToReceive := TotalAccomQtyToReceive + TempPurchLine.Quantity;

                    TotalGrossWeight := TotalGrossWeight + DecimalArray[2];

                    FillLineToExcel(DecimalArray, TextArray);
                end;
            until TempPurchLine.Next() = 0;
        FillTotalsToExcel(TotalAccomQty, TotalAccomQtyToReceive, TotalGrossWeight, TotalNetWeight);
    end;

    local procedure FillLineToExcel(DecimalLineValue: array[17] of Decimal; TextLineValue: array[5] of Text[250])
    begin
        ExcelReportBuilderMgr.AddSection('BODY');
        ExcelReportBuilderMgr.AddDataToSection('ItemName', TextLineValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('Unit', TextLineValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('OKEI', TextLineValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', TextLineValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('ItemId2', TextLineValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('DocQty', FormatValue(Format(DecimalLineValue[4])));
        ExcelReportBuilderMgr.AddDataToSection('DocPrice', FormatValue(Format(Round(DecimalLineValue[5], 0.01), 0, 1)));
        ExcelReportBuilderMgr.AddDataToSection('DocAmount', FormatValue(Format(Round(DecimalLineValue[6], 0.01), 0, 1)));
        ExcelReportBuilderMgr.AddDataToSection('FactQty', FormatValue(Format(DecimalLineValue[7])));
        ExcelReportBuilderMgr.AddDataToSection('FactPrice', FormatValue(Format(Round(DecimalLineValue[8], 0.01), 0, 1)));
        ExcelReportBuilderMgr.AddDataToSection('FactAmount', FormatValue(Format(DecimalLineValue[9], 0, 1)));
        ExcelReportBuilderMgr.AddDataToSection('LossQty', FormatValue(Format(DecimalLineValue[14])));
        ExcelReportBuilderMgr.AddDataToSection('LossAmount', FormatValue(Format(Round(DecimalLineValue[15], 0.01), 0, 1)));
        ExcelReportBuilderMgr.AddDataToSection('ProfitQty', FormatValue(Format(DecimalLineValue[16])));
        ExcelReportBuilderMgr.AddDataToSection('ProfitAmount', FormatValue(Format(Round(DecimalLineValue[17], 0.01), 0, 1)));
    end;

    local procedure CalculateNumberOfLines(var LineBuffer2: Record "Purchase Line" temporary; TableID: Integer) Number: Integer
    begin
        if LineBuffer2.FindFirst() then
            repeat
                if TableID = DATABASE::"Purchase Header" then begin
                    if (LineBuffer2.Quantity <> LineBuffer2."Qty. to Receive") or LineBuffer2.Surplus then
                        Number := Number + 1;
                end else
                    Number := Number + 1;
            until LineBuffer2.Next() = 0;
    end;

    local procedure CopyDocLinesToTempDocLines(DocPrintBuffer: Record "Document Print Buffer"; var PurchaseLineBuffer: Record "Purchase Line" temporary)
    var
        PurchaseLine2: Record "Purchase Line";
        InvtDocumentLine2: Record "Invt. Document Line";
        InvtReceiptLine2: Record "Invt. Receipt Line";
    begin
        case DocPrintBuffer."Table ID" of
            DATABASE::"Purchase Header":
                begin
                    PurchaseLine2.SetRange("Document Type", DocPrintBuffer."Document Type");
                    PurchaseLine2.SetRange("Document No.", DocPrintBuffer."Document No.");
                    PurchaseLine2.SetRange(Type, PurchaseLine2.Type::Item);
                    if PurchaseLine2.FindSet() then
                        repeat
                            PurchaseLineBuffer.Init();
                            PurchaseLineBuffer.TransferFields(PurchaseLine2);
                            PurchaseLineBuffer.Insert();
                        until PurchaseLine2.Next() = 0;
                end;
            DATABASE::"Invt. Document Header":
                begin
                    InvtDocumentLine2.SetRange("Document Type", DocPrintBuffer."Document Type");
                    InvtDocumentLine2.SetRange("Document No.", DocPrintBuffer."Document No.");
                    if InvtDocumentLine2.FindSet() then
                        repeat
                            PurchaseLineBuffer.Init();
                            PurchaseLineBuffer."Line No." := InvtDocumentLine2."Line No.";
                            PurchaseLineBuffer."No." := InvtDocumentLine2."Item No.";
                            PurchaseLineBuffer.Description := InvtDocumentLine2.Description;
                            PurchaseLineBuffer.Quantity := InvtDocumentLine2.Quantity;
                            PurchaseLineBuffer."Direct Unit Cost" := InvtDocumentLine2."Unit Cost";
                            PurchaseLineBuffer."Quantity (Base)" := InvtDocumentLine2."Quantity (Base)";
                            PurchaseLineBuffer.Insert();
                        until InvtDocumentLine2.Next() = 0;
                end;
            DATABASE::"Invt. Receipt Header":
                begin
                    InvtReceiptLine2.SetRange("Document No.", DocPrintBuffer."Document No.");
                    if InvtReceiptLine2.FindSet() then
                        repeat
                            PurchaseLineBuffer.Init();
                            PurchaseLineBuffer."Line No." := InvtReceiptLine2."Line No.";
                            PurchaseLineBuffer."No." := InvtReceiptLine2."Item No.";
                            PurchaseLineBuffer.Description := InvtReceiptLine2.Description;
                            PurchaseLineBuffer.Quantity := InvtReceiptLine2.Quantity;
                            PurchaseLineBuffer."Direct Unit Cost" := InvtReceiptLine2."Unit Cost";
                            PurchaseLineBuffer."Quantity (Base)" := InvtReceiptLine2."Quantity (Base)";
                            PurchaseLineBuffer.Insert();
                        until InvtReceiptLine2.Next() = 0;
                end;
        end;
    end;

    local procedure ClearArrays(DecimaArray2: array[17] of Decimal; TextArray2: array[5] of Text[250])
    var
        i: Integer;
    begin
        while i < 16 do begin
            Clear(DecimaArray2[i + 1]);
            i := i + 1;
        end;
        i := 1;
        while i < 5 do begin
            Clear(TextArray2[i]);
            i := i + 1;
        end;
    end;

    local procedure FormatValue(Value: Text[50]): Text[50]
    begin
        if Value = '0' then
            exit('');
        exit(Value);
    end;

    local procedure FillTotalsToExcel(AccomQty: Decimal; AccomQtyToReceive: Decimal; GrossWeight: Decimal; NetWeight: Decimal)
    begin
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'AccomQty', FormatValue(Format(AccomQty)));
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'GrossWeight', FormatValue(Format(GrossWeight)));
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'TareWeight', FormatValue(Format(GrossWeight - NetWeight)));
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'NetWeight', FormatValue(Format(NetWeight)));
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'QtyActual', Format(AccomQtyToReceive));
        ExcelReportBuilderMgr.AddDataToPreviousSection(
          Torg2RHeaderId, 'QtyDiff', Format(Abs(AccomQty - AccomQtyToReceive)));
    end;
}

