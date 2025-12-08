// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;
using System.Utilities;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Item;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;

/// <summary>
/// The purpose of the codeunit is to generate sample purchase invoices in PDF format.
/// </summary>
codeunit 6209 "E-Doc Sample Purchase Invoice"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempSamplePurchInvHdr: Record "E-Doc Sample Purch.Inv. Hdr." temporary;
        TempSamplePurchInvLine: Record "E-Doc Sample Purch. Inv. Line" temporary;

    /// <summary>
    /// Gets the posting date for the sample invoice.
    /// </summary>
    procedure GetSampleInvoicePostingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.FindFirst() then
            exit(AccountingPeriod."Starting Date");
        exit(WorkDate());
    end;

    /// <summary>
    /// Adds a sample purchase invoice.
    /// </summary>
    procedure AddSamplePurchaseInvoice(VendorNo: Code[20]; ExternalDocNo: Text[35]; Scenario: Text[2048])
    var
        Vendor: Record Vendor;
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        if TempSamplePurchInvHdr."No." = '' then
            TempSamplePurchInvHdr."No." := '1'
        else
            TempSamplePurchInvHdr."No." := IncStr(TempSamplePurchInvHdr."No.");
        Vendor.Get(VendorNo);
        TempSamplePurchInvHdr."Buy-from Vendor No." := Vendor."No.";
        TempSamplePurchInvHdr."Pay-to Vendor No." := Vendor."No.";
        TempSamplePurchInvHdr."Pay-to Name" := Vendor.Name;
        TempSamplePurchInvHdr."Pay-to Address" := Vendor.Address;
        TempSamplePurchInvHdr."Pay-to Country/Region Code" := Vendor."Country/Region Code";
        TempSamplePurchInvHdr."Pay-to City" := Vendor.City;
        TempSamplePurchInvHdr."Pay-to Post Code" := Vendor."Post Code";
        TempSamplePurchInvHdr."Vendor Invoice No." := ExternalDocNo;
        TempSamplePurchInvHdr."Posting Date" := GetSampleInvoicePostingDate();
        TempSamplePurchInvHdr."Due Date" := GetSampleInvoicePostingDate();
        TempSamplePurchInvHdr.Insert();
        SamplePurchInvFile."File Name" := GetSamplePurchInvFileName();
        SamplePurchInvFile.Scenario := Scenario;
        SamplePurchInvFile.Insert();
        Clear(TempSamplePurchInvLine);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, TaxGroupCode, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        UnitOfMeasure: Record "Unit of Measure";
        Amount: Decimal;
    begin
        TempSamplePurchInvHdr.TestField("No.");
        TempSamplePurchInvLine.Init();
        TempSamplePurchInvLine."Document No." := TempSamplePurchInvHdr."No.";
        TempSamplePurchInvLine."Line No." += 10000;
        TempSamplePurchInvLine.Type := LineType;
        TempSamplePurchInvLine."No." := No;
        TempSamplePurchInvLine."Tax Group Code" := TaxGroupCode;
        TempSamplePurchInvLine.Description := Description;
        if TempSamplePurchInvLine.Description = '' then
            case LineType of
                Enum::"Purchase Line Type"::Item:
                    begin
                        Item.Get(No);
                        TempSamplePurchInvLine.Description := Item.Description;
                    end;
                Enum::"Purchase Line Type"::"G/L Account":
                    begin
                        GLAccount.Get(No);
                        TempSamplePurchInvLine.Description := GLAccount.Name;
                    end;
            end;
        TempSamplePurchInvLine.Quantity := Quantity;
        TempSamplePurchInvLine."Direct Unit Cost" := DirectUnitCost;
        TempSamplePurchInvLine."Deferral Code" := DeferralCode;
        TempSamplePurchInvLine."Unit of Measure Code" := UnitOfMeasureCode;
        if TempSamplePurchInvLine."Unit of Measure Code" = '' then
            TempSamplePurchInvLine."Unit of Measure" := ''
        else begin
            UnitOfMeasure.Get(TempSamplePurchInvLine."Unit of Measure Code");
            TempSamplePurchInvLine."Unit of Measure" := UnitOfMeasure.Description;
        end;
        Amount := Quantity * DirectUnitCost;
        TempSamplePurchInvLine.Amount := Amount;
        TempSamplePurchInvLine."Amount Including VAT" := Amount;
        TempSamplePurchInvLine.Insert();
    end;

    /// <summary>
    /// Generates sample invoices in PDF format based on added headers and lines and stores them in the "E-Doc Sample Purch. Inv File" table.
    /// </summary>
    procedure Generate()
    var
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
        SamplePurchInvPDF: Codeunit "E-Doc Sample Purch.Inv. PDF";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        GeneratedPdfIsEmptyErr: Label 'Generated PDF is empty';
    begin
        if not TempSamplePurchInvHdr.FindSet() then
            exit;

        repeat
            Clear(SamplePurchInvPDF);
            SamplePurchInvPDF.AddHeader(TempSamplePurchInvHdr);
            TempSamplePurchInvLine.SetRange("Document No.", TempSamplePurchInvHdr."No.");
            if TempSamplePurchInvLine.FindSet() then
                repeat
                    SamplePurchInvPDF.AddLine(TempSamplePurchInvLine);
                until TempSamplePurchInvLine.Next() = 0;

            TempBlob := SamplePurchInvPDF.GeneratePDF();
            if TempBlob.Length() = 0 then
                error(GeneratedPdfIsEmptyErr);

            SamplePurchInvFile.Get(GetSamplePurchInvFileName());
            TempBlob.CreateInStream(InStream);
            SamplePurchInvFile."File Content".CreateOutStream(OutStream);
            Copystream(OutStream, InStream);
            SamplePurchInvFile.Modify();
        until TempSamplePurchInvHdr.Next() = 0;
    end;

    local procedure GetSamplePurchInvFileName(): Text[100]
    var
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        exit(CopyStr(TempSamplePurchInvHdr."Vendor Invoice No.", 1, MaxStrLen(SamplePurchInvFile."File Name")))
    end;
}