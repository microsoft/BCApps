// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using Microsoft.Utilities;

codeunit 10626 "E-Invoice Export Serv. Invoice"
{
    Permissions = TableData "Service Invoice Header" = rm;
    TableNo = "Service Invoice Header";

    trigger OnRun()
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // Is there a location for storing the file? If not, don't bother processing it.
        ServiceMgtSetup.Get();
        ServiceMgtSetup."E-Invoice Service Invoice Path" := DelChr(ServiceMgtSetup."E-Invoice Service Invoice Path", '>', '\');
        ServiceMgtSetup.TestField("E-Invoice Service Invoice Path");

        // Set filters on the service invoice line
        ServiceInvoiceLine.SetRange("Document No.", Rec."No.");
        ServiceInvoiceLine.SetFilter(Type, '>%1', 0);
        ServiceInvoiceLine.SetFilter("No.", '<>%1', ' ');

        // If there are no lines, there's nothing to export
        if not ServiceInvoiceLine.FindSet() then
            exit;

        // Pre-processing verifications
        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Serv. Invoice", Rec);

        // Move data from the sales invoice tables to the common tables
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);
        repeat
            if not IsRoundingLine(ServiceInvoiceLine) then
                FillLineTableData(TempEInvoiceExportLine, ServiceInvoiceLine);
        until ServiceInvoiceLine.Next() = 0;

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
            EInvoiceExportCommon.AddLineInvCrMemoCommonContent();
            EInvoiceExportCommon.AddLineAccountingCost();
            EInvoiceExportCommon.AddLineOrderLineReference();
            EInvoiceExportCommon.AddDelivery();
            EInvoiceExportCommon.AddLineTaxTotal();
            EInvoiceExportCommon.AddLineItem();
            EInvoiceExportCommon.AddLinePrice();
        until TempEInvoiceExportLine.Next() = 0;

        // Save file
        EInvoiceExportCommon.SaveToXML(TempEInvoiceTransferFile, ServiceMgtSetup."E-Invoice Service Invoice Path", Rec."No.");

        SetEInvoiceStatusCreated(Rec."No.");
    end;

    var
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceCommentLine: Record "Service Comment Line";
        DocumentTools: Codeunit DocumentTools;
    begin
        TempEInvoiceExportHeader.Init();

        // Fill-in the fields which have the same field ID and type
        TempEInvoiceExportHeader.TransferFields(ServiceInvoiceHeader, true);
        if TempEInvoiceExportHeader."Currency Code" = '' then begin
            GeneralLedgerSetup.Get();
            TempEInvoiceExportHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        end;

        // Fill-in the XML schema information
        TempEInvoiceExportHeader."Schema Name" := 'Invoice';
        TempEInvoiceExportHeader."Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 UBL-Invoice-2.0.xsd';
        TempEInvoiceExportHeader.xmlns := 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
        TempEInvoiceExportHeader."Customization ID" := GetCustomizationID(ServiceInvoiceHeader);
        TempEInvoiceExportHeader."Profile ID" := 'urn:www.cenbii.eu:profile:bii05:ver2.0';
        TempEInvoiceExportHeader."Uses Common Aggregate Comp." := true;
        TempEInvoiceExportHeader."Uses Common Basic Comp." := true;
        TempEInvoiceExportHeader."Uses Common Extension Comp." := true;

        // Fill-in header fields related to tax amounts
        FillHeaderTaxAmounts(TempEInvoiceExportHeader);

        TempEInvoiceExportHeader."Quantity Name" := 'InvoicedQuantity';
        TempEInvoiceExportHeader."Payment ID" := DocumentTools.GetEInvoiceExportPaymentID(TempEInvoiceExportHeader);
        TempEInvoiceExportHeader."Document No." := ServiceInvoiceHeader."External Document No.";
        TempEInvoiceExportHeader."Shipment Date" := ServiceInvoiceHeader."Delivery Date";

        // Avoid to add Invoice->AccountingSupplierParty->Person and Invoice->AccountingCustomerParty->Person (only on the service invoice).
        TempEInvoiceExportHeader."Sell-to Contact No." := '';

        // If there is any header-related comment, copy it over
        if ServiceCommentLine.Get(
             ServiceCommentLine."Table Name"::"Service Invoice Header", 0, ServiceInvoiceHeader."No.", ServiceCommentLine.Type::General, 0,
             10000)
        then
            TempEInvoiceExportHeader.Note := ServiceCommentLine.Comment;
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", TempEInvoiceExportHeader."No.");
        if ServiceInvoiceLine.FindSet() then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(ServiceInvoiceLine) then
                    TempEInvoiceExportHeader."Total Rounding Amount" += ServiceInvoiceLine."Amount Including VAT"
                else begin
                    TempEInvoiceExportHeader."Total Invoice Discount Amount" +=
                      ServiceInvoiceLine."Inv. Discount Amount" + ServiceInvoiceLine."Line Discount Amount";
                    TempEInvoiceExportHeader."Legal Taxable Amount" += ServiceInvoiceLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += ServiceInvoiceLine."Amount Including VAT";
                    TempEInvoiceExportHeader."Tax Amount" += ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount;
                end;
            until ServiceInvoiceLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; ServiceInvoiceLine: Record "Service Invoice Line")
    var
        Id: Integer;
    begin
        Id := 0;
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;

        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine.TransferFields(ServiceInvoiceLine, true);
        TempEInvoiceExportLine."Account Code" := ServiceInvoiceLine."Account Code";
        TempEInvoiceExportLine.Insert();
    end;

    local procedure GetCustomizationID(ServiceInvoiceHeader: Record "Service Invoice Header"): Text[250]
    var
        ResponsibilityCenter: Record "Responsibility Center";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryCode: Code[10];
        CustomizationID: Text[250];
    begin
        CustomizationID :=
          'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended' +
          'urn:www.peppol.eu:bis:peppol5a:ver2.0';

        if Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.") then begin
            if ResponsibilityCenter.Get(ServiceInvoiceHeader."Responsibility Center") then
                CountryCode := ResponsibilityCenter."Country/Region Code"
            else begin
                CompanyInformation.Get();
                CountryCode := CompanyInformation."Country/Region Code";
            end;

            if Customer."Country/Region Code" = CountryCode then
                CustomizationID :=
                  'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:' +
                  'urn:www.peppol.eu:bis:peppol5a:ver2.0:extended:' +
                  'urn:www.difi.no:ehf:faktura:ver2.0';
        end;

        exit(CustomizationID);
    end;

    local procedure IsRoundingLine(ServiceInvoiceLine: Record "Service Invoice Line"): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::"G/L Account" then begin
            Customer.Get(ServiceInvoiceLine."Bill-to Customer No.");
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if ServiceInvoiceLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure SetEInvoiceStatusCreated(DocumentNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.Get(DocumentNo);
        ServiceInvoiceHeader."E-Invoice Created" := true;
        ServiceInvoiceHeader.Modify();
    end;
}

