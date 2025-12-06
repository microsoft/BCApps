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
/// The purpose of the codeunit is to compose sample purchase invoice data for PDF generation.
/// </summary>
codeunit 6209 "E-Doc Sample Invoice Generator"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempSamplePurchInvHdr: Record "E-Doc Sample Purch.Inv. Hdr." temporary;
        TempSamplePurchInvLine: Record "E-Doc Sample Purch. Inv. Line" temporary;

    /// <summary>
    /// 
    /// </summary>
    procedure GetSampleInvoicePostingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindFirst();
        exit(AccountingPeriod."Starting Date");
    end;

    /// <summary>
    /// Adds a sample purchase invoice header.
    /// </summary>
    /// <param name="VendorNo">The vendor number.</param>
    /// <param name="DocumentDate">The document date.</param>
    /// <param name="DueDate">The due date.</param>
    /// <param name="ExternalDocNo">The external document number.</param>
    procedure AddSamplePurchaseHeader(VendorNo: Code[20]; ExternalDocNo: Text[35])
    var
        Vendor: Record Vendor;
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
        Clear(TempSamplePurchInvLine);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    /// <param name="LineType">The line type.</param>
    /// <param name="No">The item/G/L account number.</param>
    /// <param name="Description">The description.</param>
    /// <param name="Quantity">The quantity.</param>
    /// <param name="DirectUnitCost">The direct unit cost.</param>
    /// <param name="DeferralCode">The deferral code.</param>
    /// <param name="UnitOfMeasureCode">The unit of measure code.</param>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    /// <param name="LineType">The line type.</param>
    /// <param name="No">The item/G/L account number.</param>
    /// <param name="Description">The description.</param>
    /// <param name="Quantity">The quantity.</param>
    /// <param name="DirectUnitCost">The direct unit cost.</param>
    /// <param name="UnitOfMeasureCode">The unit of measure code.</param>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    /// <param name="LineType">The line type.</param>
    /// <param name="No">The item/G/L account number.</param>
    /// <param name="TaxGroupCode">The tax group code.</param>
    /// <param name="Description">The description.</param>
    /// <param name="Quantity">The quantity.</param>
    /// <param name="DirectUnitCost">The direct unit cost.</param>
    /// <param name="UnitOfMeasureCode">The unit of measure code.</param>
    procedure AddSamplePurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddSamplePurchaseLine(LineType, No, TaxGroupCode, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    /// <param name="LineType">The line type.</param>
    /// <param name="No">The item/G/L account number.</param>
    /// <param name="TaxGroupCode">The tax group code.</param>
    /// <param name="Description">The description.</param>
    /// <param name="Quantity">The quantity.</param>
    /// <param name="DirectUnitCost">The direct unit cost.</param>
    /// <param name="DeferralCode">The deferral code.</param>
    /// <param name="UnitOfMeasureCode">The unit of measure code.</param>
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
        TempSamplePurchInvLine."Tax Group Code" := TaxGroupCode; // TODO: Looks like i do not need this
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
    /// Generates sample invoices in PDF format and stores them in the "E-Doc Sample Purch. Inv File" table.
    /// </summary>
    procedure Generate()
    var
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
        SamplePurchInvRunner: Codeunit "E-Doc Sample Purch.Inv. Runner";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        GeneratedPdfIsEmptyErr: Label 'Generated PDF is empty';
    begin
        if not TempSamplePurchInvHdr.FindSet() then
            exit;

        repeat
            Clear(SamplePurchInvRunner);
            SamplePurchInvRunner.AddHeader(TempSamplePurchInvHdr);
            TempSamplePurchInvLine.SetRange("Document No.", TempSamplePurchInvHdr."No.");
            if TempSamplePurchInvLine.FindSet() then
                repeat
                    SamplePurchInvRunner.AddLine(TempSamplePurchInvLine);
                until TempSamplePurchInvLine.Next() = 0;

            TempBlob := SamplePurchInvRunner.GeneratePDF();
            if TempBlob.Length() = 0 then
                error(GeneratedPdfIsEmptyErr);

            SamplePurchInvFile.Init();
            SamplePurchInvFile."File Name" := CopyStr(TempSamplePurchInvHdr."Vendor Invoice No.", 1, MaxStrLen(SamplePurchInvFile."File Name"));
            TempBlob.CreateInStream(InStream);
            SamplePurchInvFile."File Content".CreateOutStream(OutStream);
            Copystream(OutStream, InStream);
            SamplePurchInvFile.Insert();
        until TempSamplePurchInvHdr.Next() = 0;
    end;
}