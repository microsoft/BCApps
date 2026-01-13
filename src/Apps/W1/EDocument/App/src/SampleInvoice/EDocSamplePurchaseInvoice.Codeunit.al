// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Reflection;
using System.Utilities;

/// <summary>
/// The purpose of the codeunit is to generate sample purchase invoices in PDF format.
/// </summary>
codeunit 6209 "E-Doc Sample Purchase Invoice"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempEDocPurchHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchLine: Record "E-Document Purchase Line" temporary;
        ReportLayoutList: Record "Report Layout List";
        MixLayoutsForPDFGeneration: Boolean;

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
    procedure AddInvoice(VendorNo: Code[20]; ExternalDocNo: Text[35]; Scenario: Text[2048])
    begin
        AddInvoice(VendorNo, ExternalDocNo, Scenario, 0);
    end;

    /// <summary>
    /// Adds a sample purchase invoice.
    /// </summary>
    procedure AddInvoice(VendorNo: Code[20]; ExternalDocNo: Text[35]; Scenario: Text[2048]; TotalTaxAmount: Decimal)
    var
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        TempEDocPurchHeader.Reset();
        TempEDocPurchHeader.DeleteAll();
        TempEDocPurchLine.Reset();
        TempEDocPurchLine.DeleteAll();
        InitSamplePurchInvHeader(TempEDocPurchHeader, VendorNo, GetSampleInvoicePostingDate(), ExternalDocNo, TotalTaxAmount);
        TempEDocPurchHeader.Insert();
        SamplePurchInvFile."File Name" := GetSamplePurchInvFileName();
        SamplePurchInvFile.Scenario := Scenario;
        SamplePurchInvFile."Vendor Name" := TempEDocPurchHeader."Vendor Company Name";
        SamplePurchInvFile.Insert();
    end;

    /// <summary>
    /// Sets the flag to mix layouts for PDF generation.
    /// </summary>
    procedure SetMixLayoutsForPDFGeneration()
    begin
        MixLayoutsForPDFGeneration := true;
    end;

    /// <summary>
    /// Initializes a sample purchase invoice header.
    /// </summary>
    /// <param name="EDocPurchaseHeader"></param>
    /// <param name="VendorNo"></param>
    /// <param name="DocumentDate"></param>
    /// <param name="ExternalDocNo"></param>
    /// <param name="TotalTaxAmount"></param>
    internal procedure InitSamplePurchInvHeader(var EDocPurchaseHeader: Record "E-Document Purchase Header"; VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35]; TotalTaxAmount: Decimal)
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        clear(EDocPurchaseHeader);
        CompanyInformation.Get();
        EDocPurchaseHeader."Customer Company Name" := CompanyInformation.Name;
        EDocPurchaseHeader."Customer Company Id" := CompanyInformation."Bank Account No.";
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        EDocPurchaseHeader."Customer Address" :=
            CopyStr(
                CompanyInformation.Address + ' ' + CompanyInformation."Address 2" + ', ' + CompanyInformation.City + ', ' + CompanyInformation.County + ', ' + CompanyInformation."Post Code" + ' ' + CountryRegion.Name,
                1, MaxStrLen(EDocPurchaseHeader."Customer Address"));
        EDocPurchaseHeader."Shipping Address" := EDocPurchaseHeader."Customer Address";
        EDocPurchaseHeader."Shipping Address Recipient" := EDocPurchaseHeader."Customer Company Name";
        EDocPurchaseHeader."Sales Invoice No." := ExternalDocNo;
        EDocPurchaseHeader."Document Date" := DocumentDate;
        EDocPurchaseHeader."Due Date" := DocumentDate;
        Vendor.Get(VendorNo);
        EDocPurchaseHeader."Vendor Company Name" := Vendor.Name + ' ' + Vendor.Contact;
        EDocPurchaseHeader."Vendor Address" := Vendor.Address + ', ' + Vendor.City + ', ' + Vendor.County + ', ' + Vendor."Post Code" + ' ' + Vendor."Country/Region Code";
        EDocPurchaseHeader."Vendor Address Recipient" := EDocPurchaseHeader."Vendor Company Name";
        GeneralLedgerSetup.Get();
        EDocPurchaseHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        EDocPurchaseHeader."[BC] Vendor No." := Vendor."No.";
        EDocPurchaseHeader."Total VAT" := TotalTaxAmount;
    end;

    /// <summary>
    /// Adds a sample purchase invoice line.
    /// </summary>
    procedure AddLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddLine(LineType, No, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line to the current temporary header.
    /// </summary>
    procedure AddLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddLine(TempEDocPurchLine, TempEDocPurchHeader, LineType, No, Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a sample purchase invoice line to the specified header.
    /// </summary>
    internal procedure AddLine(EDocPurchaseHeader: Record "E-Document Purchase Header"; LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        EDocPurchaseLine: Record "E-Document Purchase Line";
    begin
        AddLine(EDocPurchaseLine, EDocPurchaseHeader, LineType, No, Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    local procedure AddLine(var EDocPurchaseLine: Record "E-Document Purchase Line"; EDocPurchaseHeader: Record "E-Document Purchase Header"; LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
        LineNo: Integer;
    begin
        EDocPurchaseHeader.TestField("[BC] Vendor No.");

        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocPurchaseHeader."E-Document Entry No.");
        if EDocPurchaseLine.FindLast() then
            LineNo := EDocPurchaseLine."Line No.";
        LineNo += 10000;

        EDocPurchaseLine."E-Document Entry No." := EDocPurchaseHeader."E-Document Entry No.";
        EDocPurchaseLine."Line No." := LineNo;
        EDocPurchaseLine."[BC] Purchase Line Type" := LineType;
        EDocPurchaseLine."[BC] Purchase Type No." := No;
        EDocPurchaseLine."Product Code" := No;
        EDocPurchaseLine.Description := GetLineDescription(LineType, No, Description);
        EDocPurchaseLine.Quantity := Quantity;
        if UnitOfMeasureCode <> '' then
            UnitOfMeasure.Get(UnitOfMeasureCode)
        else
            UnitOfMeasure.Init();
        EDocPurchaseLine."Unit of Measure" := UnitOfMeasure.Description;
        EDocPurchaseLine."Unit Price" := DirectUnitCost;
        EDocPurchaseLine."Sub Total" := Round(EDocPurchaseLine.Quantity * EDocPurchaseLine."Unit Price");
        EDocPurchaseLine."Currency Code" := EDocPurchaseHeader."Currency Code";
        EDocPurchaseLine."[BC] Deferral Code" := DeferralCode;
        EDocPurchaseLine.Insert();
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
        TempEDocPurchHeader.TestField("[BC] Vendor No.");
        SetLayout(SamplePurchInvPDF);
        TempBlob := SamplePurchInvPDF.GeneratePDF(TempEDocPurchHeader, TempEDocPurchLine);
        if TempBlob.Length() = 0 then
            error(GeneratedPdfIsEmptyErr);

        SamplePurchInvFile.Get(GetSamplePurchInvFileName());
        TempBlob.CreateInStream(InStream);
        SamplePurchInvFile."File Content".CreateOutStream(OutStream);
        Copystream(OutStream, InStream);
        SamplePurchInvFile.Modify();
    end;

    local procedure GetSamplePurchInvFileName(): Text[100]
    var
        SamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        exit(CopyStr(TempEDocPurchHeader."Sales Invoice No." + '.pdf', 1, MaxStrLen(SamplePurchInvFile."File Name")))
    end;

    local procedure GetLineDescription(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]): Text[100]
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
    begin
        if Description <> '' then
            exit(Description);
        case LineType of
            Enum::"Purchase Line Type"::Item:
                begin
                    Item.Get(No);
                    exit(Item.Description);
                end;
            Enum::"Purchase Line Type"::"G/L Account":
                begin
                    GLAccount.Get(No);
                    exit(GLAccount.Name);
                end;
        end;
        exit('');
    end;

    local procedure SetLayout(var SamplePurchInvPDF: Codeunit "E-Doc Sample Purch.Inv. PDF")
    begin
        if not MixLayoutsForPDFGeneration then
            exit;
        if ReportLayoutList."Report ID" = 0 then begin
            ReportLayoutList.SetRange("Report ID", Report::"E-Doc Sample Purchase Invoice");
            ReportLayoutList.FindSet();
        end;
        SamplePurchInvPDF.SetSamplePurchInvoiceLayout(ReportLayoutList.Name);
        if ReportLayoutList.Next() = 0 then
            ReportLayoutList.FindSet();
    end;
}