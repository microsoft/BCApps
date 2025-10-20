// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.History;
using System.Utilities;
using System.IO;

/// <summary>
/// The purpose of the codeunit is to compose entities for generating the e-document invoices
/// </summary>
codeunit 5429 "E-Doc. Inv. Contoso Composer"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;

    /// <summary>
    /// 
    /// </summary>
    procedure AddEDocPurchaseHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35])
    begin
        if TempPurchHeader."No." = '' then
            TempPurchHeader."No." := '1'
        else
            TempPurchHeader."No." := IncStr(TempPurchHeader."No.");
        TempPurchHeader."Buy-from Vendor No." := VendorNo;
        TempPurchHeader."Vendor Invoice No." := ExternalDocNo;
        TempPurchHeader."Posting Date" := DocumentDate;
        TempPurchHeader.Insert();
        Clear(TempPurchLine);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="DeferralCode"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="TaxGroupCode"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, TaxGroupCode, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="TaxGroupCode"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="DeferralCode"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        TempPurchHeader.TestField("No.");
        TempPurchLine."Document No." := TempPurchHeader."No.";
        TempPurchLine."Line No." += 10000;
        TempPurchLine.Type := LineType;
        TempPurchLine."No." := No;
        TempPurchLine."Tax Group Code" := TaxGroupCode;
        TempPurchLine.Description := Description;
        TempPurchLine.Quantity := Quantity;
        TempPurchLine."Direct Unit Cost" := DirectUnitCost;
        TempPurchLine."Deferral Code" := DeferralCode;
        TempPurchLine."Unit of Measure Code" := UnitOfMeasureCode;
        TempPurchLine.Insert();
    end;

    /// <summary>
    /// 
    /// </summary>
    procedure ProcessComposedEntries()
    var
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        TempPurchHeader.Reset();
        TempPurchHeader.FindSet();
        repeat
            PurchHeader := CreatePurchInvFromTempBuffer();
            PurchInvHeader := PostPurchaseInvoice(PurchHeader);
            TempBlob := SavePurchInvReportToPDF(PurchInvHeader);
        until TempPurchHeader.Next() = 0;
    end;

    local procedure CreatePurchInvFromTempBuffer() PurchHeader: Record "Purchase Header"
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", TempPurchHeader."Buy-from Vendor No.");
        PurchHeader.Validate("Posting Date", TempPurchHeader."Posting Date");
        PurchHeader.Validate("Vendor Invoice No.", TempPurchHeader."Vendor Invoice No.");
        PurchHeader.Modify(true);
        TempPurchLine.SetRange("Document No.", TempPurchHeader."No.");
        TempPurchLine.FindSet();
        repeat
            clear(PurchLine);
            PurchLine."Document Type" := PurchLine."Document Type"::Invoice;
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := TempPurchLine."Line No.";
            PurchLine.Insert(true);
            PurchLine.Validate(Type, TempPurchLine.Type);
            PurchLine.Validate("No.", TempPurchLine."No.");
            PurchLine.Validate("Tax Group Code", TempPurchLine."Tax Group Code");
            PurchLine.Validate(Description, TempPurchLine.Description);
            PurchLine.Validate(Quantity, TempPurchLine.Quantity);
            PurchLine.Validate("Direct Unit Cost", TempPurchLine."Direct Unit Cost");
            PurchLine.Validate("Deferral Code", TempPurchLine."Deferral Code");
            PurchLine.Validate("Unit of Measure Code", TempPurchLine."Unit of Measure Code");
            PurchLine.Modify(true);
        until TempPurchLine.Next() = 0;
    end;

    local procedure PostPurchaseInvoice(PurchHeader: Record "Purchase Header") PurchInvHeader: Record "Purch. Inv. Header"
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchHeader.Invoice := true;
        PurchHeader.Receive := true;
        PurchHeader.Modify(true);
        PurchPost.Run(PurchHeader);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchHeader."No.");
        PurchInvHeader.FindFirst();
    end;

    local procedure SavePurchInvReportToPDF(PurchInvHeader: Record "Purch. Inv. Header") TempBlob: Codeunit "Temp Blob"
    var
        PurchaseInvoiceReport: Report "Purchase - Invoice";
        FileManagement: Codeunit "File Management";
        FilePath: Text[250];
    begin
        PurchInvHeader.SetRecFilter();
        PurchaseInvoiceReport.SetTableView(PurchInvHeader);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, 250);
        PurchaseInvoiceReport.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
    end;

}