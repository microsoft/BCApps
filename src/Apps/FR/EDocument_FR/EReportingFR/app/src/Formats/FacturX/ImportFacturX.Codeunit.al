// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using System.IO;
using System.Telemetry;
using System.Utilities;

codeunit 10982 "Import Factur-X"
{
    Access = Internal;

    var
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureNameTok: Label 'E-document Factur-X Format', Locked = true;
        StartEventNameTok: Label 'E-document Factur-X import started. Parsing basic information.', Locked = true;
        ContinueEventNameTok: Label 'Parsing complete information for E-document Factur-X import.', Locked = true;
        EndEventNameTok: Label 'E-document Factur-X import completed. %1 #%2 created.', Comment = '%1 = Document Type, %2 = Document No.', Locked = true;

    procedure ParseBasicInfo(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FREDocHelpers: Codeunit "EDoc. Helpers";
        CIIXmlBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        InStr: InStream;
        DocNo: Text;
        TypeCode: Text;
        IssueDate: Text;
        DueDateText: Text;
        AmountText: Text;
        CurrencyCode: Text;
        SellerVATId: Text[20];
        SellerGLN: Code[13];
        VendorNo: Code[20];
        PdfInStr: InStream;
    begin
        FeatureTelemetry.LogUsage('0000FXA', FeatureNameTok, StartEventNameTok);
        TempBlob.CreateInStream(PdfInStr);
        ExtractCIIXmlFromPdf(TempBlob, CIIXmlBlob);

        CIIXmlBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);

        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('rsm', RsmNamespaceTok);
        NamespaceMgr.AddNamespace('ram', RamNamespaceTok);
        NamespaceMgr.AddNamespace('udt', UdtNamespaceTok);

        EDocument.Direction := EDocument.Direction::Incoming;

        // Detect and validate document type from TypeCode.
        TypeCode := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//rsm:ExchangedDocument/ram:TypeCode');
        SetDocumentTypeFromTypeCode(TypeCode, EDocument);

        DocNo := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//rsm:ExchangedDocument/ram:ID');
        EDocument."Incoming E-Document No." := CopyStr(DocNo, 1, MaxStrLen(EDocument."Incoming E-Document No."));

        IssueDate := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString');
        if IssueDate <> '' then
            EDocument."Document Date" := EvaluateDate(IssueDate);

        DueDateText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString');
        if DueDateText <> '' then
            EDocument."Due Date" := EvaluateDate(DueDateText);

        // Currency code
        CurrencyCode := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode');
        GeneralLedgerSetup.Get();
        if CurrencyCode <> GeneralLedgerSetup."LCY Code" then
            EDocument."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(EDocument."Currency Code"));

        AmountText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount');
        if AmountText <> '' then
            Evaluate(EDocument."Amount Excl. VAT", AmountText, 9);

        AmountText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount');
        if AmountText <> '' then
            Evaluate(EDocument."Amount Incl. VAT", AmountText, 9);

        // Parse seller info
        EDocument."Bill-to/Pay-to Name" := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name'),
            1, MaxStrLen(EDocument."Bill-to/Pay-to Name"));

        // Parse buyer/receiving company info
        EDocument."Receiving Company Name" := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name'),
            1, MaxStrLen(EDocument."Receiving Company Name"));
        EDocument."Receiving Company Address" := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:LineOne'),
            1, MaxStrLen(EDocument."Receiving Company Address"));
        EDocument."Receiving Company VAT Reg. No." := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            1, MaxStrLen(EDocument."Receiving Company VAT Reg. No."));

        // Try to match vendor by GLN, VAT Registration No., or name+address
        SellerVATId := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            1, MaxStrLen(SellerVATId));
        SellerGLN := CopyStr(
            FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:GlobalID'),
            1, MaxStrLen(SellerGLN));

        VendorNo := EDocumentImportHelper.FindVendor('', SellerGLN, SellerVATId);
        if VendorNo = '' then
            VendorNo := EDocumentImportHelper.FindVendorByNameAndAddress(
                EDocument."Bill-to/Pay-to Name",
                FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineOne'));

        if VendorNo <> '' then
            EDocument."Bill-to/Pay-to No." := VendorNo;

        CreateDocumentAttachment(EDocument, PdfInStr);
    end;

    procedure ParseCompleteInfo(var EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header" temporary; var PurchaseLine: Record "Purchase Line" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        CIIXmlBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        LineNodes: XmlNodeList;
        LineNode: XmlNode;
        InStr: InStream;
        DocNo: Text;
        IssueDateText: Text;
        DueDateText: Text;
        InvoiceDiscountAmount: Decimal;
        LineCounter: Integer;
    begin
        FeatureTelemetry.LogUsage('0000FXB', FeatureNameTok, ContinueEventNameTok);
        ExtractCIIXmlFromPdf(TempBlob, CIIXmlBlob);

        CIIXmlBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);

        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('rsm', RsmNamespaceTok);
        NamespaceMgr.AddNamespace('ram', RamNamespaceTok);
        NamespaceMgr.AddNamespace('udt', UdtNamespaceTok);

        // Purchase header
        PurchaseHeader."Buy-from Vendor No." := EDocument."Bill-to/Pay-to No.";
        PurchaseHeader."Currency Code" := EDocument."Currency Code";
        PurchaseHeader."No." := CopyStr(EDocument."Incoming E-Document No.", 1, MaxStrLen(PurchaseHeader."No."));
        PurchaseHeader."Vendor Invoice No." := CopyStr(EDocument."Incoming E-Document No.", 1, MaxStrLen(PurchaseHeader."Vendor Invoice No."));

        DocNo := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//rsm:ExchangedDocument/ram:ID');
        if DocNo <> '' then begin
            PurchaseHeader."No." := CopyStr(DocNo, 1, MaxStrLen(PurchaseHeader."No."));
            PurchaseHeader."Vendor Invoice No." := CopyStr(DocNo, 1, MaxStrLen(PurchaseHeader."Vendor Invoice No."));
        end;

        IssueDateText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString');
        if IssueDateText <> '' then begin
            PurchaseHeader."Document Date" := EvaluateDate(IssueDateText);
            PurchaseHeader."Posting Date" := PurchaseHeader."Document Date";
        end;

        case EDocument."Document Type" of
            EDocument."Document Type"::"Purchase Credit Memo":
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
            else
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        end;

        // Due date
        DueDateText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString');
        if DueDateText <> '' then begin
            PurchaseHeader."Due Date" := EvaluateDate(DueDateText);
            EDocument."Due Date" := PurchaseHeader."Due Date";
        end;

        // Parse line items
        LineCounter := 0;
        if XmlDoc.SelectNodes('//ram:IncludedSupplyChainTradeLineItem', NamespaceMgr, LineNodes) then
            foreach LineNode in LineNodes do begin
                LineCounter += 1;
                ParseLineItem(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", LineNode, NamespaceMgr, LineCounter);
            end;

        InvoiceDiscountAmount := GetInvoiceDiscountAmount(XmlDoc, NamespaceMgr);
        if InvoiceDiscountAmount <> 0 then
            ApplyInvoiceDiscountToPurchaseLines(PurchaseLine, InvoiceDiscountAmount);

        CreateHeaderChargeLines(EDocument, PurchaseHeader, PurchaseLine, XmlDoc, NamespaceMgr, LineCounter);

        FeatureTelemetry.LogUsage('0000FXC', FeatureNameTok, StrSubstNo(EndEventNameTok, EDocument."Document Type", EDocument."Incoming E-Document No."));
        OnAfterParseCompleteInfo(EDocument, PurchaseHeader, PurchaseLine);
    end;

    local procedure ExtractCIIXmlFromPdf(var PdfBlob: Codeunit "Temp Blob"; var CIIXmlBlob: Codeunit "Temp Blob")
    var
        PDFDocument: Codeunit "PDF Document";
        PdfInStr: InStream;
    begin
        PdfBlob.CreateInStream(PdfInStr);
        if not PDFDocument.GetDocumentAttachmentStream(PdfInStr, CIIXmlBlob) then
            // Fallback: if no embedded attachment found, assume input is raw CII XML
            CIIXmlBlob := PdfBlob;
    end;

    local procedure ParseLineItem(var PurchaseLine: Record "Purchase Line" temporary; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineNode: XmlNode; NamespaceMgr: XmlNamespaceManager; LineCounter: Integer)
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        LineXmlDoc: XmlDocument;
        LineXmlText: Text;
        ItemReferenceNoText: Text;
        DescriptionText: Text;
        QuantityText: Text;
        UnitOfMeasureCodeText: Text;
        UnitPriceText: Text;
        GrossUnitPriceText: Text;
        LineAmountText: Text;
        LineDiscountPercentText: Text;
        LineDiscountAmountText: Text;
        VATRateText: Text;
        UnitPrice: Decimal;
        GrossUnitPrice: Decimal;
        LineDiscountAmount: Decimal;
        LineDiscountPercent: Decimal;
    begin
        // Create a temporary XmlDocument from the line node for GetNodeValue compatibility
        LineNode.WriteTo(LineXmlText);
        XmlDocument.ReadFrom(LineXmlText, LineXmlDoc);
        NamespaceMgr.NameTable(LineXmlDoc.NameTable());
        NamespaceMgr.AddNamespace('ram', RamNamespaceTok);
        NamespaceMgr.AddNamespace('udt', UdtNamespaceTok);

        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := DocumentNo;
        PurchaseLine."Line No." := LineCounter * 10000;
        PurchaseLine."Allow Invoice Disc." := true;

        ItemReferenceNoText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:SpecifiedTradeProduct/ram:GlobalID');
        PurchaseLine."Item Reference No." := CopyStr(ItemReferenceNoText, 1, MaxStrLen(PurchaseLine."Item Reference No."));

        // BT-153 Item name
        DescriptionText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:SpecifiedTradeProduct/ram:Name');
        PurchaseLine.Description := CopyStr(DescriptionText, 1, MaxStrLen(PurchaseLine.Description));

        // BT-129 Invoiced quantity
        QuantityText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:SpecifiedLineTradeDelivery/ram:BilledQuantity');
        if QuantityText <> '' then
            Evaluate(PurchaseLine.Quantity, QuantityText, 9);

        UnitOfMeasureCodeText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode');
        if UnitOfMeasureCodeText <> '' then
            PurchaseLine."Unit of Measure Code" := CopyStr(UnitOfMeasureCodeText, 1, MaxStrLen(PurchaseLine."Unit of Measure Code"));

        // BT-146 Item net price
        UnitPriceText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:NetPriceProductTradePrice/ram:ChargeAmount');
        if UnitPriceText <> '' then begin
            Evaluate(UnitPrice, UnitPriceText, 9);
            PurchaseLine."Direct Unit Cost" := UnitPrice;
        end;

        // BT-148 Item gross price
        GrossUnitPriceText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:GrossPriceProductTradePrice/ram:ChargeAmount');
        if GrossUnitPriceText <> '' then
            Evaluate(GrossUnitPrice, GrossUnitPriceText, 9);

        // BT-131 Line total amount
        LineAmountText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount');
        if LineAmountText <> '' then begin
            Evaluate(PurchaseLine.Amount, LineAmountText, 9);
            PurchaseLine."VAT Base Amount" := PurchaseLine.Amount;
        end;

        // BT-138 Line allowance percentage
        LineDiscountPercentText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr,
            '//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=''false'']/ram:CalculationPercent');
        if LineDiscountPercentText <> '' then begin
            Evaluate(LineDiscountPercent, LineDiscountPercentText, 9);
            PurchaseLine."Line Discount %" := LineDiscountPercent;
        end else begin
            // Some CII files provide line allowance as amount, not percentage.
            LineDiscountAmountText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr,
                '//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=''false'']/ram:ActualAmount');
            if LineDiscountAmountText <> '' then
                Evaluate(LineDiscountAmount, LineDiscountAmountText, 9);

            LineDiscountPercent := DeriveLineDiscountPercent(GrossUnitPrice, UnitPrice, PurchaseLine.Quantity, LineDiscountAmount, PurchaseLine.Amount);
            if LineDiscountPercent <> 0 then
                PurchaseLine."Line Discount %" := LineDiscountPercent;
        end;

        // VAT rate
        VATRateText := FREDocHelpers.GetNodeValue(LineXmlDoc, NamespaceMgr, '//ram:ApplicableTradeTax/ram:RateApplicablePercent');
        if VATRateText <> '' then
            Evaluate(PurchaseLine."VAT %", VATRateText, 9);

        PurchaseLine.Insert();
    end;

    local procedure DeriveLineDiscountPercent(GrossUnitPrice: Decimal; NetUnitPrice: Decimal; Quantity: Decimal; LineAllowanceAmount: Decimal; LineTotalAmount: Decimal): Decimal
    var
        GrossLineAmount: Decimal;
        DiscountAmount: Decimal;
        DiscountPercent: Decimal;
    begin
        if (GrossUnitPrice > 0) and (NetUnitPrice > 0) and (NetUnitPrice < GrossUnitPrice) then
            exit(Round((GrossUnitPrice - NetUnitPrice) / GrossUnitPrice * 100, 0.00001));

        if (GrossUnitPrice > 0) and (Quantity <> 0) then begin
            GrossLineAmount := GrossUnitPrice * Quantity;

            if LineAllowanceAmount > 0 then
                DiscountAmount := LineAllowanceAmount
            else
                if (LineTotalAmount > 0) and (LineTotalAmount < GrossLineAmount) then
                    DiscountAmount := GrossLineAmount - LineTotalAmount;

            if DiscountAmount > 0 then begin
                DiscountPercent := DiscountAmount / GrossLineAmount * 100;
                exit(Round(DiscountPercent, 0.00001));
            end;
        end;

        exit(0);
    end;

    local procedure GetInvoiceDiscountAmount(XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager): Decimal
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        AmountText: Text;
        InvoiceDiscountAmount: Decimal;
    begin
        AmountText := FREDocHelpers.GetNodeValue(XmlDoc, NamespaceMgr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount');
        if (AmountText <> '') and Evaluate(InvoiceDiscountAmount, AmountText, 9) then
            exit(InvoiceDiscountAmount);

        exit(GetHeaderAllowanceChargeAmountSum(XmlDoc, NamespaceMgr));
    end;

    local procedure GetHeaderAllowanceChargeAmountSum(XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager): Decimal
    var
        AllowanceNodes: XmlNodeList;
        AllowanceNode: XmlNode;
        AmountText: Text;
        Amount: Decimal;
        TotalAmount: Decimal;
    begin
        if XmlDoc.SelectNodes('//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=''false'']/ram:ActualAmount', NamespaceMgr, AllowanceNodes) then
            foreach AllowanceNode in AllowanceNodes do begin
                AmountText := AllowanceNode.AsXmlElement().InnerText();
                if (AmountText <> '') and Evaluate(Amount, AmountText, 9) then
                    TotalAmount += Amount;
            end;

        exit(TotalAmount);
    end;

    local procedure ApplyInvoiceDiscountToPurchaseLines(var TempPurchaseLine: Record "Purchase Line" temporary; InvoiceDiscountAmount: Decimal)
    var
        TempPurchaseLineCopy: Record "Purchase Line" temporary;
        TotalBaseAmount: Decimal;
        CurrentDiscount: Decimal;
        LineCount: Integer;
        LineIndex: Integer;
        DistributedAmount: Decimal;
    begin
        TempPurchaseLineCopy.Copy(TempPurchaseLine, true);
        TempPurchaseLineCopy.SetFilter(Amount, '<>0');
        TempPurchaseLineCopy.CalcSums(Amount);
        TotalBaseAmount := TempPurchaseLineCopy.Amount;
        LineCount := TempPurchaseLineCopy.Count();

        if (TotalBaseAmount = 0) or (LineCount = 0) then
            exit;

        TempPurchaseLineCopy.Reset();
        TempPurchaseLineCopy.Copy(TempPurchaseLine, true);
        DistributedAmount := 0;
        if TempPurchaseLineCopy.FindSet() then
            repeat
                TempPurchaseLineCopy."Allow Invoice Disc." := true;
                if TempPurchaseLineCopy.Amount = 0 then
                    CurrentDiscount := 0
                else begin
                    LineIndex += 1;
                    if LineIndex = LineCount then
                        CurrentDiscount := Round(InvoiceDiscountAmount - DistributedAmount, 0.01)
                    else
                        CurrentDiscount := Round(InvoiceDiscountAmount * TempPurchaseLineCopy.Amount / TotalBaseAmount, 0.01);
                end;

                TempPurchaseLineCopy."Inv. Discount Amount" := CurrentDiscount;
                DistributedAmount += CurrentDiscount;
                TempPurchaseLineCopy.Modify();
            until TempPurchaseLineCopy.Next() = 0;
    end;

    local procedure CreateDocumentAttachment(var EDocument: Record "E-Document"; PdfInStream: InStream)
    var
        DocumentAttachment: Record "Document Attachment";
        EDocumentService: Record "E-Document Service";
        EDocumentHelper: Codeunit "E-Document Helper";
        EDocumentAttachmentProcessor: Codeunit "E-Doc. Attachment Processor";
        FileNameTok: Label '%1_%2', Comment = '%1 = Document Type, %2 = Document No.', Locked = true;
    begin
        if PdfInStream.Length = 0 then
            exit;

        EDocumentHelper.GetEdocumentService(EDocument, EDocumentService);
        if not EDocumentService."Embed PDF in export" then
            exit;

        DocumentAttachment."No." := CopyStr(EDocument."Incoming E-Document No.", 1, MaxStrLen(DocumentAttachment."No."));
        DocumentAttachment.Validate("File Extension", 'pdf');
        DocumentAttachment."File Name" := StrSubstNo(FileNameTok, EDocument."Document Type", EDocument."Incoming E-Document No.");
        EDocumentAttachmentProcessor.Insert(EDocument, PdfInStream, DocumentAttachment.FindUniqueFileName(DocumentAttachment."File Name", DocumentAttachment."File Extension"));
    end;

    local procedure CreateHeaderChargeLines(var EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header" temporary; var PurchaseLine: Record "Purchase Line" temporary; XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; var LineCounter: Integer)
    var
        RecRef: RecordRef;
        ChargeNodes: XmlNodeList;
        ChargeNode: XmlNode;
        IndicatorNode: XmlNode;
        AmountNode: XmlNode;
        ReasonNode: XmlNode;
        AmountText: Text;
        IsCharge: Boolean;
    begin
        // Process header-level charges (surcharges where ChargeIndicator = true)
        if not XmlDoc.SelectNodes('//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge', NamespaceMgr, ChargeNodes) then
            exit;

        foreach ChargeNode in ChargeNodes do begin
            IsCharge := false;
            if ChargeNode.SelectSingleNode('ram:ChargeIndicator/udt:Indicator', NamespaceMgr, IndicatorNode) then
                IsCharge := (IndicatorNode.AsXmlElement().InnerText() = 'true') or (IndicatorNode.AsXmlElement().InnerText() = '1');

            if IsCharge then begin
                LineCounter += 1;
                PurchaseLine.Init();
                PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                PurchaseLine."Document No." := PurchaseHeader."No.";
                PurchaseLine."Line No." := LineCounter * 10000;
                PurchaseLine.Quantity := 1;
                PurchaseLine.Type := PurchaseLine.Type::"G/L Account";

                if ChargeNode.SelectSingleNode('ram:ActualAmount', NamespaceMgr, AmountNode) then begin
                    AmountText := AmountNode.AsXmlElement().InnerText();
                    if AmountText <> '' then begin
                        Evaluate(PurchaseLine."Direct Unit Cost", AmountText, 9);
                        Evaluate(PurchaseLine.Amount, AmountText, 9);
                    end;
                end;

                if ChargeNode.SelectSingleNode('ram:Reason', NamespaceMgr, ReasonNode) then
                    PurchaseLine.Description := CopyStr(ReasonNode.AsXmlElement().InnerText(), 1, MaxStrLen(PurchaseLine.Description));

                RecRef.GetTable(PurchaseLine);
                EDocumentImportHelper.FindGLAccountForLine(EDocument, RecRef);
                PurchaseLine."No." := RecRef.Field(PurchaseLine.FieldNo("No.")).Value;
                PurchaseLine.Insert();
            end;
        end;
    end;

    local procedure SetDocumentTypeFromTypeCode(TypeCode: Text; var EDocument: Record "E-Document")
    begin
        TypeCode := UpperCase(TypeCode);
        if IsCreditMemoTypeCode(TypeCode) then begin
            EDocument."Document Type" := EDocument."Document Type"::"Purchase Credit Memo";
            exit;
        end;

        if IsInvoiceTypeCode(TypeCode) then begin
            EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice";
            exit;
        end;

        Error(UnsupportedDocumentTypeErr, TypeCode);
    end;

    local procedure IsInvoiceTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '380', '384', '751', '877':
                exit(true);
        end;

        exit(false);
    end;

    local procedure IsCreditMemoTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '381', '261':
                exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateDate(DateText: Text): Date
    var
        DateValue: Date;
    begin
        // Format 20241115 (CCYYMMDD)
        Evaluate(DateValue, CopyStr(DateText, 7, 2) + '.' + CopyStr(DateText, 5, 2) + '.' + CopyStr(DateText, 1, 4));
        exit(DateValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterParseCompleteInfo(EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header" temporary; var PurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        UnsupportedDocumentTypeErr: Label 'Unsupported document type: %1', Comment = '%1 = Document type';
}
