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
using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Setup;

codeunit 10627 "E-Invoice Exp. Serv. Cr. Memo"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        // check section
        ServiceCrMemoLine.SetRange("Document No.", Rec."No.");
        ServiceCrMemoLine.SetFilter(Type, '>%1', 0);
        ServiceCrMemoLine.SetFilter("No.", '<>%1', ' ');
        if not ServiceCrMemoLine.FindSet() then
            exit;

        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Serv. Cr. Memo", Rec);

        // transfer data section
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);
        repeat
            if not IsRoundingLine(ServiceCrMemoLine) then
                FillLineTableData(TempEInvoiceExportLine, ServiceCrMemoLine);
        until ServiceCrMemoLine.Next() = 0;

        // export section
        ExportToXML(TempEInvoiceExportHeader, TempEInvoiceExportLine);
        ModifyServiceCrMemoHeader(Rec."No.");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure ExportToXML(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary)
    var
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // initialize
        EInvoiceExportCommon.SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);
        // common
        EInvoiceExportCommon.CreateDocAndRootNode();
        EInvoiceExportCommon.AddHeaderCommonContent();
        EInvoiceExportCommon.AddHeaderNote();
        EInvoiceExportCommon.AddHeaderDocumentCurrencyCode();
        EInvoiceExportCommon.AddHeaderTaxCurrencyCode();
        EInvoiceExportCommon.AddHeaderBillingReference();
        EInvoiceExportCommon.AddHeaderAccountingSupplierParty();
        EInvoiceExportCommon.AddHeaderAccountingCustomerParty();
        EInvoiceExportCommon.AddDelivery();
        EInvoiceExportCommon.AddHeaderTaxExchangeRate();
        EInvoiceExportCommon.AddHeaderAllowanceCharge();
        EInvoiceExportCommon.AddHeaderTaxTotal();
        EInvoiceExportCommon.AddHeaderLegalMonetaryTotal();
        // Common for invoice and credit memo header
        TempEInvoiceExportLine.FindSet();

        repeat
            EInvoiceExportCommon.CreateLineNode(TempEInvoiceExportLine);
            EInvoiceExportCommon.AddLineInvCrMemoCommonContent();
            EInvoiceExportCommon.AddDelivery();
            EInvoiceExportCommon.AddLineTaxTotal();
            EInvoiceExportCommon.AddLineItem();
            EInvoiceExportCommon.AddLinePrice();
        until TempEInvoiceExportLine.Next() = 0;
        // Save file
        ServiceMgtSetup.Get();
        EInvoiceExportCommon.SaveToXML(TempEInvoiceTransferFile, ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path", TempEInvoiceExportHeader."No.");
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceCommentLine: Record "Service Comment Line";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        TempEInvoiceExportHeader.Init();
        // header fields related to the source table
        TempEInvoiceExportHeader.TransferFields(ServiceCrMemoHeader);
        // calculated fields
        if TempEInvoiceExportHeader."Currency Code" = '' then begin
            GLSetup.Get();
            TempEInvoiceExportHeader."Currency Code" := GLSetup."LCY Code";
        end;

        if ServiceCrMemoHeader."Applies-to Doc. Type" = ServiceCrMemoHeader."Applies-to Doc. Type"::Invoice then
            TempEInvoiceExportHeader."Document No." := ServiceCrMemoHeader."Applies-to Doc. No."
        else
            TempEInvoiceExportHeader."Document No." := ServiceCrMemoHeader."External Document No.";
        // header fields not related to the source table
        TempEInvoiceExportHeader."Schema Name" := 'CreditNote';
        TempEInvoiceExportHeader."Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2 UBL-CreditNote-2.0.xsd';
        TempEInvoiceExportHeader.xmlns :=
          'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
        TempEInvoiceExportHeader."Customization ID" := GetCustomizationID(ServiceCrMemoHeader);
        TempEInvoiceExportHeader."Profile ID" := 'urn:www.cenbii.eu:profile:bii05:ver2.0';
        TempEInvoiceExportHeader."Uses Common Aggregate Comp." := true;
        TempEInvoiceExportHeader."Uses Common Basic Comp." := true;
        TempEInvoiceExportHeader."Uses Common Extension Comp." := false;
        TempEInvoiceExportHeader."Quantity Name" := 'CreditedQuantity';
        // header fields related to tax amounts
        FillHeaderTaxAmounts(TempEInvoiceExportHeader);
        // custom
        TempEInvoiceExportHeader."Shipment Date" := ServiceCrMemoHeader."Delivery Date";
        TempEInvoiceExportHeader."Bill-to Country/Region Code" := EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(TempEInvoiceExportHeader."Bill-to Country/Region Code");
        if ServiceCommentLine.Get(
             ServiceCommentLine."Table Name"::"Service Invoice Header", 0, ServiceCrMemoHeader."No.", ServiceCommentLine.Type::General,
             0, 10000)
        then
            TempEInvoiceExportHeader.Note := ServiceCommentLine.Comment;
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", TempEInvoiceExportHeader."No.");
        if ServiceCrMemoLine.FindSet() then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(ServiceCrMemoLine) then
                    TempEInvoiceExportHeader."Total Rounding Amount" += ServiceCrMemoLine."Amount Including VAT"
                else begin
                    TempEInvoiceExportHeader."Total Invoice Discount Amount" +=
                      ServiceCrMemoLine."Inv. Discount Amount" + ServiceCrMemoLine."Line Discount Amount";
                    TempEInvoiceExportHeader."Legal Taxable Amount" += ServiceCrMemoLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += ServiceCrMemoLine."Amount Including VAT";
                    TempEInvoiceExportHeader."Tax Amount" += ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount;
                end;
            until ServiceCrMemoLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; ServiceCrMemoLine: Record "Service Cr.Memo Line")
    var
        SalesCommentLine: Record "Sales Comment Line";
        Id: Integer;
    begin
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;

        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.TransferFields(ServiceCrMemoLine, true);
        if SalesCommentLine.Get(
             SalesCommentLine."Document Type"::"Posted Credit Memo", ServiceCrMemoLine."Document No.", ServiceCrMemoLine."Line No.", 10000)
        then
            TempEInvoiceExportLine.Comment := SalesCommentLine.Comment;
        TempEInvoiceExportLine.Insert();
    end;

    local procedure GetCustomizationID(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Text[250]
    var
        ResponsibilityCenter: Record "Responsibility Center";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryCode: Code[10];
        CustomizationID: Text[250];
    begin
        CustomizationID :=
          'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:' +
          'urn:www.peppol.eu:bis:peppol5a:ver2.0';

        if Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then begin
            if ResponsibilityCenter.Get(ServiceCrMemoHeader."Responsibility Center") then
                CountryCode := ResponsibilityCenter."Country/Region Code"
            else begin
                CompanyInformation.Get();
                CountryCode := CompanyInformation."Country/Region Code";
            end;

            if Customer."Country/Region Code" = CountryCode then
                CustomizationID += ':extended:urn:www.difi.no:ehf:kreditnota:ver2.0';
        end;

        exit(CustomizationID);
    end;

    local procedure IsRoundingLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::"G/L Account" then begin
            Customer.Get(ServiceCrMemoLine."Bill-to Customer No.");
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if ServiceCrMemoLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ModifyServiceCrMemoHeader(DocumentNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.Get(DocumentNo);
        ServiceCrMemoHeader."E-Invoice Created" := true;
        ServiceCrMemoHeader.Modify();
    end;
}

