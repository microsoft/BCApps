// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Setup;

codeunit 10621 "E-Invoice Exp. Iss. Fin. Chrg."
{
    Permissions = TableData "Issued Fin. Charge Memo Header" = rm;
    TableNo = "Issued Fin. Charge Memo Header";

    trigger OnRun()
    var
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line";
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // Pre-Check
        IssuedFinChrgMemoLine.SetRange("Finance Charge Memo No.", Rec."No.");
        if not IssuedFinChrgMemoLine.FindSet() then
            exit;

        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Iss. Fin.Chrg.", Rec);

        // Fill in the Common Tables
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);

        repeat
            if not IsRoundingLine(IssuedFinChrgMemoLine, Rec."Customer No.") then
                FillLineTableData(TempEInvoiceExportLine, IssuedFinChrgMemoLine);
        until IssuedFinChrgMemoLine.Next() = 0;

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
        EInvoiceExportCommon.SaveToXML(TempEInvoiceTransferFile, SalesSetup."E-Invoice Fin. Charge Path", Rec."No.");

        ModifyIssFinChrg(Rec."No.");
    end;

    var
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        IssuedFinChrgMemoHeader."Currency Code" :=
          EInvoiceDocumentEncode.GetEInvoiceCurrencyCode(IssuedFinChrgMemoHeader."Currency Code");

        TempEInvoiceExportHeader.Init();
        TempEInvoiceExportHeader.ID := 0;
        TempEInvoiceExportHeader."No." := IssuedFinChrgMemoHeader."No.";
        TempEInvoiceExportHeader."Bill-to Customer No." := IssuedFinChrgMemoHeader."Customer No.";
        TempEInvoiceExportHeader."Bill-to Name" := IssuedFinChrgMemoHeader.Name;
        TempEInvoiceExportHeader."Bill-to Address" := IssuedFinChrgMemoHeader.Address;
        TempEInvoiceExportHeader."Bill-to Address 2" := IssuedFinChrgMemoHeader."Address 2";
        TempEInvoiceExportHeader."Bill-to City" := IssuedFinChrgMemoHeader.City;
        TempEInvoiceExportHeader."Your Reference" := IssuedFinChrgMemoHeader."Your Reference";
        TempEInvoiceExportHeader."Posting Date" := IssuedFinChrgMemoHeader."Posting Date";
        TempEInvoiceExportHeader."Currency Code" := IssuedFinChrgMemoHeader."Currency Code";
        TempEInvoiceExportHeader."VAT Registration No." := IssuedFinChrgMemoHeader."VAT Registration No.";
        TempEInvoiceExportHeader."Bill-to Post Code" := IssuedFinChrgMemoHeader."Post Code";
        TempEInvoiceExportHeader."Bill-to County" := IssuedFinChrgMemoHeader.County;
        TempEInvoiceExportHeader."Bill-to Country/Region Code" := IssuedFinChrgMemoHeader."Country/Region Code";
        TempEInvoiceExportHeader."Sell-to Country/Region Code" := IssuedFinChrgMemoHeader."Country/Region Code";
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
        TempEInvoiceExportHeader.GLN := IssuedFinChrgMemoHeader.GLN;

        // Fill-in header fields related to tax amounts
        FillHeaderTaxAmounts(TempEInvoiceExportHeader);
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", TempEInvoiceExportHeader."No.");
        if IssuedFinChargeMemoLine.FindSet() then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(IssuedFinChargeMemoLine, TempEInvoiceExportHeader."Bill-to Customer No.") then
                    TempEInvoiceExportHeader."Total Rounding Amount" += IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount"
                else begin
                    TempEInvoiceExportHeader."Legal Taxable Amount" += IssuedFinChargeMemoLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount";
                    TempEInvoiceExportHeader."Tax Amount" += IssuedFinChargeMemoLine."VAT Amount";
                end;
            until IssuedFinChargeMemoLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line")
    var
        Id: Integer;
    begin
        Id := 0;
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;
        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine."Document No." := IssuedFinChrgMemoLine."Document No.";
        TempEInvoiceExportLine."Line No." := IssuedFinChrgMemoLine."Line No.";
        TempEInvoiceExportLine.Type := IssuedFinChrgMemoLine.Type;
        TempEInvoiceExportLine."No." := IssuedFinChrgMemoLine."No.";
        TempEInvoiceExportLine."Document Type" := IssuedFinChrgMemoLine."Document Type";
        TempEInvoiceExportLine.Description := IssuedFinChrgMemoLine.Description;
        TempEInvoiceExportLine."Remaining Amount" := IssuedFinChrgMemoLine."Remaining Amount";
        TempEInvoiceExportLine."VAT %" := IssuedFinChrgMemoLine."VAT %";
        TempEInvoiceExportLine.Amount := IssuedFinChrgMemoLine.Amount;
        TempEInvoiceExportLine."Amount Including VAT" := IssuedFinChrgMemoLine.Amount + IssuedFinChrgMemoLine."VAT Amount";
        TempEInvoiceExportLine."VAT Calculation Type" := IssuedFinChrgMemoLine."VAT Calculation Type";
        TempEInvoiceExportLine."VAT Identifier" := IssuedFinChrgMemoLine."VAT Identifier";
        TempEInvoiceExportLine."VAT Prod. Posting Group" := IssuedFinChrgMemoLine."VAT Prod. Posting Group";
        TempEInvoiceExportLine.Insert(true);
    end;

    local procedure IsRoundingLine(IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"; CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if IssuedFinChargeMemoLine.Type = IssuedFinChargeMemoLine.Type::"G/L Account" then begin
            Customer.Get(CustomerNo);
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if IssuedFinChargeMemoLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure ModifyIssFinChrg(DocumentNo: Code[20])
    var
        IssuedFinChargeMemoHeader2: Record "Issued Fin. Charge Memo Header";
    begin
        IssuedFinChargeMemoHeader2.Get(DocumentNo);
        IssuedFinChargeMemoHeader2."E-Invoice Created" := true;
        IssuedFinChargeMemoHeader2.Modify();
    end;
}

