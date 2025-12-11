// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Document;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;

/// <summary>
/// Implementation of IStructuredFormatReader for Contoso Inbound E-Document invoices.
/// </summary>
codeunit 5392 "Contoso Inb.Inv. Format Reader" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Read the data into the E-Document data structures.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="TempBlob">The temporary blob that contains the data to read</param>
    /// <returns>The data process to run on the structured data.</returns>
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        PurchHeader: Record "Purchase Header";
        InStream: InStream;
        PurchHeaderView: Text;
        ProvdedDataIsEmptyErr: Label 'The provided data is empty.';
    begin
        TempBlob.CreateInStream(InStream);
        if InStream.Length() = 0 then
            Error(ProvdedDataIsEmptyErr);
        InStream.Read(PurchHeaderView);
        PurchHeader.SetView(PurchHeaderView);
        PurchHeader.Find();
        InsertEDocPurchInvoiceFromPurchInvoice(PurchHeader, EDocument."Entry No");
        exit(Enum::"E-Doc. Process Draft"::"Purchase Document");
    end;

    /// <summary>
    /// Presents a view of the data 
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="TempBlob">The temporary blob that contains the data to read</param>
    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        EDocReadablePurchaseDoc: Page "E-Doc. Readable Purchase Doc.";
    begin
        EDocPurchaseHeader.Get(EDocument."Entry No");
        TempEDocPurchaseHeader := EDocPurchaseHeader;
        TempEDocPurchaseHeader.Insert();
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindSet();
        repeat
            TempEDocPurchaseLine := EDocPurchaseLine;
            TempEDocPurchaseLine.Insert();
        until EDocPurchaseLine.Next() = 0;
        EDocReadablePurchaseDoc.SetBuffer(TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.Run();
    end;

    local procedure InsertEDocPurchInvoiceFromPurchInvoice(PurchHeader: Record "Purchase Header"; EDocEntryNo: Integer)
    var
        PurchLine: Record "Purchase Line";
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        AllocAccSystemIds: List of [Guid];
    begin
        EDocPurchaseHeader := InsertEDocPurchHeaderFromPurchHeader(PurchHeader, EDocEntryNo);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindSet();
        repeat
            InsertEDocPurchLineFromPurchLine(AllocAccSystemIds, PurchLine, EDocEntryNo, EDocPurchaseHeader."Currency Code");
        until PurchLine.Next() = 0;
    end;

    local procedure InsertEDocPurchHeaderFromPurchHeader(PurchHeader: Record "Purchase Header"; EDocEntryNo: Integer) EDocPurchaseHeader: Record "E-Document Purchase Header";
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        EDocPurchaseHeader."E-Document Entry No." := EDocEntryNo;
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
        EDocPurchaseHeader."Sales Invoice No." := PurchHeader."Vendor Invoice No.";
        EDocPurchaseHeader."Document Date" := PurchHeader."Posting Date";
        EDocPurchaseHeader."Due Date" := PurchHeader."Due Date";
        Vendor.Get(PurchHeader."Buy-from Vendor No.");
        EDocPurchaseHeader."Vendor Company Name" := Vendor.Name + ' ' + Vendor.Contact;
        EDocPurchaseHeader."Vendor Address" := PurchHeader."Pay-to Address" + ', ' + Vendor.City + ', ' + Vendor.County + ', ' + Vendor."Post Code" + ' ' + Vendor."Country/Region Code";
        EDocPurchaseHeader."Vendor Address Recipient" := EDocPurchaseHeader."Vendor Company Name";
        GeneralLedgerSetup.Get();
        EDocPurchaseHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        PurchHeader.CalcFields("Amount Including VAT");
        EDocPurchaseHeader.Total := PurchHeader."Amount Including VAT";
        EDocPurchaseHeader."[BC] Vendor No." := PurchHeader."Buy-from Vendor No.";
        EDocPurchaseHeader.Insert();
    end;

    local procedure InsertEDocPurchLineFromPurchLine(var AllocAccSystemIds: List of [Guid]; PurchLine: Record "Purchase Line"; EDocEntryNo: Integer; CurrencyCode: Code[10])
    var
        EDocPurchaseLine: Record "E-Document Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UpdatePuchLineTypeAndNumberOnEDocPurchaseLine(EDocPurchaseLine, PurchLine);
        if EDocPurchaseLine."[BC] Purchase Line Type" = EDocPurchaseLine."[BC] Purchase Line Type"::"Allocation Account" then begin
            if AllocAccSystemIds.Contains(PurchLine."Alloc. Purch. Line SystemId") then
                exit;
            PurchLine.SetRange("Alloc. Purch. Line SystemId", PurchLine."Alloc. Purch. Line SystemId");
            PurchLine.CalcSums("Direct Unit Cost", "Amount Including VAT");
            PurchLine.SetRange("Alloc. Purch. Line SystemId");
            AllocAccSystemIds.Add(PurchLine."Alloc. Purch. Line SystemId");
        end;
        EDocPurchaseLine."E-Document Entry No." := EDocEntryNo;
        EDocPurchaseLine."Line No." := PurchLine."Line No.";
        EDocPurchaseLine.Description := PurchLine.Description;
        EDocPurchaseLine.Quantity := PurchLine.Quantity;
        if PurchLine."Unit of Measure Code" <> '' then
            UnitOfMeasure.Get(PurchLine."Unit of Measure Code")
        else
            UnitOfMeasure.Init();
        EDocPurchaseLine."Unit of Measure" := UnitOfMeasure.Description;
        EDocPurchaseLine."Unit Price" := PurchLine."Direct Unit Cost";
        EDocPurchaseLine."Sub Total" := PurchLine."Amount Including VAT";
        EDocPurchaseLine."Currency Code" := CurrencyCode;
        EDocPurchaseLine."[BC] Deferral Code" := PurchLine."Deferral Code";
        EDocPurchaseLine."[BC] Variant Code" := PurchLine."Variant Code";
        EDocPurchaseLine.Insert();
    end;

    local procedure UpdatePuchLineTypeAndNumberOnEDocPurchaseLine(var EDocPurchaseLine: Record "E-Document Purchase Line"; PurchLine: Record "Purchase Line")
    begin
        if PurchLine."Allocation Account No." = '' then begin
            EDocPurchaseLine."[BC] Purchase Line Type" := PurchLine.Type;
            EDocPurchaseLine."[BC] Purchase Type No." := PurchLine."No.";
            exit;
        end;
        EDocPurchaseLine."[BC] Purchase Line Type" := EDocPurchaseLine."[BC] Purchase Line Type"::"Allocation Account";
        EDocPurchaseLine."[BC] Purchase Type No." := PurchLine."Allocation Account No.";
    end;

}
