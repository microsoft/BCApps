// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 10619 "E-Invoice Export Sales Invoice"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // If there are no invoice lines, there's nothing to export
        SalesInvoiceLine.SetRange("Document No.", Rec."No.");
        SalesInvoiceLine.SetFilter(Type, '>%1', 0);
        SalesInvoiceLine.SetFilter("No.", '<>%1', ' ');
        if not SalesInvoiceLine.FindSet() then
            exit;

        // Pre-processing data verifications
        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Sales Invoice", Rec);

        // Move data from the sales invoice tables to the common tables
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);
        repeat
            if not IsRoundingLine(SalesInvoiceLine) then
                FillLineTableData(TempEInvoiceExportLine, SalesInvoiceLine);
        until SalesInvoiceLine.Next() = 0;
        EInvoiceExportCommon.SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);

        // Create invoice root node and XML content
        EInvoiceExportCommon.CreateDocAndRootNode();
        EInvoiceExportCommon.AddHeaderCommonContent();
        EInvoiceExportCommon.AddHeaderInvoiceTypeCode();
        EInvoiceExportCommon.AddHeaderNote();
        EInvoiceExportCommon.AddHeaderDocumentCurrencyCode();
        EInvoiceExportCommon.AddHeaderTaxCurrencyCode();
        EInvoiceExportCommon.AddHeaderOrderReference();
        EInvoiceExportCommon.AddHeaderContractDocumentReference();
        EInvoiceExportCommon.AddHeaderAccountingSupplierParty();
        EInvoiceExportCommon.AddHeaderAccountingCustomerParty();
        EInvoiceExportCommon.AddDelivery();
        EInvoiceExportCommon.AddHeaderPaymentMeans();
        EInvoiceExportCommon.AddHeaderAllowanceCharge();
        EInvoiceExportCommon.AddHeaderTaxExchangeRate();
        EInvoiceExportCommon.AddHeaderTaxTotal();
        EInvoiceExportCommon.AddHeaderLegalMonetaryTotal();

        // Add XML content for the invoice lines
        TempEInvoiceExportLine.FindSet();

        repeat
            EInvoiceExportCommon.CreateLineNode(TempEInvoiceExportLine);
            EInvoiceExportCommon.AddLineNote();
            EInvoiceExportCommon.AddLineInvCrMemoCommonContent();
            EInvoiceExportCommon.AddLineAccountingCost();
            EInvoiceExportCommon.AddLineOrderLineReference();
            EInvoiceExportCommon.AddDelivery();
            EInvoiceExportCommon.AddLineAllowanceCharge();
            EInvoiceExportCommon.AddLineTaxTotal();
            EInvoiceExportCommon.AddLineItem();
            EInvoiceExportCommon.AddLinePrice();
        until TempEInvoiceExportLine.Next() = 0;

        // Save file
        SalesSetup.Get();
        EInvoiceExportCommon.SaveToXML(TempEInvoiceTransferFile, SalesSetup."E-Invoice Sales Invoice Path", Rec."No.");
        SetEInvoiceStatusCreated(Rec."No.");
    end;

    var
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCommentLine: Record "Sales Comment Line";
        DocumentTools: Codeunit DocumentTools;
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        // Convert the currency code to the standard code list used by E-Invoices
        SalesInvoiceHeader."Currency Code" := EInvoiceDocumentEncode.GetEInvoiceCurrencyCode(SalesInvoiceHeader."Currency Code");

        // Fill-in the fields which have the same field ID and type
        TempEInvoiceExportHeader.Init();
        TempEInvoiceExportHeader.TransferFields(SalesInvoiceHeader, true);
        if TempEInvoiceExportHeader."Currency Code" = '' then begin
            GeneralLedgerSetup.Get();
            TempEInvoiceExportHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        end;

        // Fill-in the XML schema information
        TempEInvoiceExportHeader."Schema Name" := 'Invoice';
        TempEInvoiceExportHeader."Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 UBL-Invoice-2.0.xsd';
        TempEInvoiceExportHeader.xmlns := 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
        TempEInvoiceExportHeader."Customization ID" := GetCustomizationID(SalesInvoiceHeader);
        TempEInvoiceExportHeader."Profile ID" := 'urn:www.cenbii.eu:profile:bii04:ver2.0';
        TempEInvoiceExportHeader."Uses Common Aggregate Comp." := true;
        TempEInvoiceExportHeader."Uses Common Basic Comp." := true;
        TempEInvoiceExportHeader."Uses Common Extension Comp." := true;

        // Fill-in header fields related to tax amounts
        FillHeaderTaxAmounts(TempEInvoiceExportHeader);

        TempEInvoiceExportHeader."Quantity Name" := 'InvoicedQuantity';

        // Update (if empty) and validate the Bill-to Country/Region Code
        TempEInvoiceExportHeader."Bill-to Country/Region Code" :=
          EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(TempEInvoiceExportHeader."Bill-to Country/Region Code");
        TempEInvoiceExportHeader.GLN := SalesInvoiceHeader.GLN;

        // Get Giro KID
        TempEInvoiceExportHeader."Payment ID" := DocumentTools.GetEInvoiceExportPaymentID(TempEInvoiceExportHeader);

        // If there is any header-related comment, copy it over
        if SalesCommentLine.Get(SalesCommentLine."Document Type"::"Posted Invoice", SalesInvoiceHeader."No.", 0, 10000) then
            TempEInvoiceExportHeader.Note := SalesCommentLine.Comment;
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", TempEInvoiceExportHeader."No.");
        if SalesInvoiceLine.FindSet() then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(SalesInvoiceLine) then
                    TempEInvoiceExportHeader."Total Rounding Amount" += SalesInvoiceLine."Amount Including VAT"
                else begin
                    TempEInvoiceExportHeader."Total Invoice Discount Amount" +=
                      SalesInvoiceLine."Inv. Discount Amount" + SalesInvoiceLine."Line Discount Amount";
                    TempEInvoiceExportHeader."Legal Taxable Amount" += SalesInvoiceLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += SalesInvoiceLine."Amount Including VAT";
                    TempEInvoiceExportHeader."Tax Amount" += SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
                end;
            until SalesInvoiceLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesCommentLine: Record "Sales Comment Line";
        Id: Integer;
    begin
        Id := 0;
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;

        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine.TransferFields(SalesInvoiceLine, true);
        if SalesCommentLine.Get(
             SalesCommentLine."Document Type"::"Posted Invoice", SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", 10000)
        then
            TempEInvoiceExportLine.Comment := SalesCommentLine.Comment;
        TempEInvoiceExportLine.Insert();
    end;

    local procedure GetCustomizationID(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        ResponsibilityCenter: Record "Responsibility Center";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryCode: Code[10];
        CustomizationID: Text[250];
    begin
        CustomizationID :=
          'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:' +
          'urn:www.peppol.eu:bis:peppol4a:ver2.0';

        if Customer.Get(SalesInvoiceHeader."Bill-to Customer No.") then begin
            if ResponsibilityCenter.Get(SalesInvoiceHeader."Responsibility Center") then
                CountryCode := ResponsibilityCenter."Country/Region Code"
            else begin
                CompanyInformation.Get();
                CountryCode := CompanyInformation."Country/Region Code";
            end;

            if Customer."Country/Region Code" = CountryCode then
                CustomizationID += ':extended:urn:www.difi.no:ehf:faktura:ver2.0';
        end;

        exit(CustomizationID);
    end;

    local procedure IsRoundingLine(SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::"G/L Account" then begin
            Customer.Get(SalesInvoiceLine."Bill-to Customer No.");
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if SalesInvoiceLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure SetEInvoiceStatusCreated(DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."E-Invoice Created" := true;
        SalesInvoiceHeader.Modify();
    end;
}

