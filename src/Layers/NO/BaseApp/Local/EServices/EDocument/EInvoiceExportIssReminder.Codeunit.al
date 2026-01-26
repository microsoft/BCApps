// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;

codeunit 10622 "E-Invoice Export Iss. Reminder"
{
    Permissions = TableData "Issued Reminder Header" = rm;
    TableNo = "Issued Reminder Header";

    trigger OnRun()
    var
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        IssuedReminderLine: Record "Issued Reminder Line";
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // Pre-Check
        IssuedReminderLine.SetRange("Reminder No.", Rec."No.");
        if not IssuedReminderLine.FindSet() then
            exit;

        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Iss. Reminder", Rec);

        // Fill in the Common Tables
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);

        repeat
            if not IsRoundingLine(IssuedReminderLine, Rec."Customer No.") then
                FillLineTableData(TempEInvoiceExportLine, IssuedReminderLine);
        until IssuedReminderLine.Next() = 0;

        EInvoiceExportCommon.SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);

        // Create XML Content
        EInvoiceExportCommon.CreateDocAndRootNode();
        EInvoiceExportCommon.AddHeaderCommonContent();
        EInvoiceExportCommon.AddHeaderAccountingSupplierParty();
        EInvoiceExportCommon.AddHeaderAccountingCustomerParty();
        EInvoiceExportCommon.AddHeaderTaxTotal();
        EInvoiceExportCommon.AddHeaderLegalMonetaryTotal();

        TempEInvoiceExportLine.FindSet();
        repeat
            if (TempEInvoiceExportLine.Type <> TempEInvoiceExportLine.Type::" ") or (TempEInvoiceExportLine."No." <> '') or
               (TempEInvoiceExportLine.Description <> '')
            then begin
                EInvoiceExportCommon.CreateLineNode(TempEInvoiceExportLine);
                EInvoiceExportCommon.AddLineReminderContent();
            end;
        until TempEInvoiceExportLine.Next() = 0;

        // Save file
        SalesSetup.Get();
        EInvoiceExportCommon.SaveToXML(TempEInvoiceTransferFile, SalesSetup."E-Invoice Reminder Path", Rec."No.");

        ModifyIssuedReminderHeader(Rec."No.");
    end;

    var
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; IssuedReminderHeader: Record "Issued Reminder Header")
    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        IssuedReminderHeader."Currency Code" := EInvoiceDocumentEncode.GetEInvoiceCurrencyCode(IssuedReminderHeader."Currency Code");

        TempEInvoiceExportHeader.Init();
        TempEInvoiceExportHeader.ID := 0;
        TempEInvoiceExportHeader."No." := IssuedReminderHeader."No.";
        TempEInvoiceExportHeader."Bill-to Customer No." := IssuedReminderHeader."Customer No.";
        TempEInvoiceExportHeader."Bill-to Name" := IssuedReminderHeader.Name;
        TempEInvoiceExportHeader."Bill-to Address" := IssuedReminderHeader.Address;
        TempEInvoiceExportHeader."Bill-to Address 2" := IssuedReminderHeader."Address 2";
        TempEInvoiceExportHeader."Bill-to City" := IssuedReminderHeader.City;
        TempEInvoiceExportHeader."Your Reference" := IssuedReminderHeader."Your Reference";
        TempEInvoiceExportHeader."Posting Date" := IssuedReminderHeader."Posting Date";
        TempEInvoiceExportHeader."Currency Code" := IssuedReminderHeader."Currency Code";
        TempEInvoiceExportHeader."VAT Registration No." := IssuedReminderHeader."VAT Registration No.";
        TempEInvoiceExportHeader."Bill-to Post Code" := IssuedReminderHeader."Post Code";
        TempEInvoiceExportHeader."Bill-to County" := IssuedReminderHeader.County;
        TempEInvoiceExportHeader."Bill-to Country/Region Code" := IssuedReminderHeader."Country/Region Code";
        TempEInvoiceExportHeader."Sell-to Country/Region Code" := IssuedReminderHeader."Country/Region Code";
        TempEInvoiceExportHeader."Schema Name" := 'Reminder';
        TempEInvoiceExportHeader."Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:Reminder-2 UBL-Reminder-2.0.xsd';
        TempEInvoiceExportHeader.xmlns := 'urn:oasis:names:specification:ubl:schema:xsd:Reminder-2';
        TempEInvoiceExportHeader."Customization ID" := 'urn:www.cenbii.eu:transaction:biicoretrdm017:ver1.0' +
          ':#urn:www.cenbii.eu:profile:biixy:ver1.0#urn:www.difi.no:ehf:purring:ver1';
        TempEInvoiceExportHeader."Profile ID" := 'urn:www.cenbii.eu:profile:biixy:ver1.0';
        TempEInvoiceExportHeader."Uses Common Aggregate Comp." := true;
        TempEInvoiceExportHeader."Uses Common Basic Comp." := true;
        TempEInvoiceExportHeader."Uses Common Extension Comp." := true;
        TempEInvoiceExportHeader."Sales Line Found" := true;
        TempEInvoiceExportHeader.GLN := IssuedReminderHeader.GLN;

        // Fill-in header fields related to tax amounts
        FillHeaderTaxAmounts(TempEInvoiceExportHeader);
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", TempEInvoiceExportHeader."No.");
        if IssuedReminderLine.FindSet() then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(IssuedReminderLine, TempEInvoiceExportHeader."Bill-to Customer No.") then
                    TempEInvoiceExportHeader."Total Rounding Amount" += IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount"
                else begin
                    TempEInvoiceExportHeader."Legal Taxable Amount" += IssuedReminderLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount";
                    TempEInvoiceExportHeader."Tax Amount" += IssuedReminderLine."VAT Amount";
                end;
            until IssuedReminderLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; IssuedReminderLine: Record "Issued Reminder Line")
    var
        Id: Integer;
    begin
        Id := 0;
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;
        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine."Document No." := IssuedReminderLine."Document No.";
        TempEInvoiceExportLine."Line No." := IssuedReminderLine."Line No.";
        TempEInvoiceExportLine.Type := IssuedReminderLine.Type.AsInteger();
        TempEInvoiceExportLine."No." := IssuedReminderLine."No.";
        TempEInvoiceExportLine."Document Type" := IssuedReminderLine."Document Type";
        TempEInvoiceExportLine.Description := IssuedReminderLine.Description;
        TempEInvoiceExportLine."Remaining Amount" := IssuedReminderLine."Remaining Amount";
        TempEInvoiceExportLine."VAT %" := IssuedReminderLine."VAT %";
        TempEInvoiceExportLine.Amount := IssuedReminderLine.Amount;
        TempEInvoiceExportLine."Amount Including VAT" := IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount";
        TempEInvoiceExportLine."VAT Calculation Type" := IssuedReminderLine."VAT Calculation Type";
        TempEInvoiceExportLine."VAT Identifier" := IssuedReminderLine."VAT Identifier";
        TempEInvoiceExportLine."VAT Prod. Posting Group" := IssuedReminderLine."VAT Prod. Posting Group";
        TempEInvoiceExportLine.Insert(true);
    end;

    local procedure IsRoundingLine(IssuedReminderLine: Record "Issued Reminder Line"; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if IssuedReminderLine.Type = IssuedReminderLine.Type::"G/L Account" then begin
            Customer.Get(CustomerNo);
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if IssuedReminderLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ModifyIssuedReminderHeader(DocumentNo: Code[20])
    var
        IssuedReminderHeader2: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader2.Get(DocumentNo);
        IssuedReminderHeader2."E-Invoice Created" := true;
        IssuedReminderHeader2.Modify();
    end;
}

