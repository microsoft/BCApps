// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;
using System.Utilities;
using System.IO;

/// <summary>
/// Facade codeunit for managing sample purchase invoice PDF generation.
/// Provides methods to add header, add lines, and generate PDF using temporary tables.
/// </summary>
codeunit 6208 "Sample Purch. Invoice Runner"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempSamplePurchInvHeader: Record "Sample Purch. Inv. Header" temporary;
        TempSamplePurchInvLine: Record "Sample Purch. Inv. Line" temporary;
        CurrentDocNo: Code[20];
        LineCounter: Integer;

    /// <summary>
    /// Adds a new header record to the temporary buffer.
    /// </summary>
    /// <param name="VendorNo">Buy-from Vendor No.</param>
    /// <param name="DocumentDate">Posting Date of the document.</param>
    /// <param name="ExternalDocNo">Vendor Invoice No.</param>
    procedure AddHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35])
    begin
        if TempSamplePurchInvHeader."No." = '' then
            CurrentDocNo := '1'
        else
            CurrentDocNo := IncStr(TempSamplePurchInvHeader."No.");

        TempSamplePurchInvHeader.Init();
        TempSamplePurchInvHeader."No." := CurrentDocNo;
        TempSamplePurchInvHeader."Buy-from Vendor No." := VendorNo;
        TempSamplePurchInvHeader."Vendor Invoice No." := ExternalDocNo;
        TempSamplePurchInvHeader."Posting Date" := DocumentDate;
        TempSamplePurchInvHeader.Insert();
        LineCounter := 0;
    end;

    /// <summary>
    /// Adds a new line record to the temporary buffer.
    /// </summary>
    /// <param name="LineType">Type of the purchase line.</param>
    /// <param name="No">No. of the item/G/L account etc.</param>
    /// <param name="LineDescription">Description of the line.</param>
    /// <param name="LineQuantity">Quantity.</param>
    /// <param name="UnitCost">Direct Unit Cost.</param>
    /// <param name="DeferralCode">Deferral Code.</param>
    /// <param name="UnitOfMeasureCode">Unit of Measure Code.</param>
    procedure AddLine(LineType: Enum "Purchase Line Type"; No: Code[20]; LineDescription: Text[100]; LineQuantity: Decimal; UnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddLine(LineType, No, '', LineDescription, LineQuantity, UnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a new line record to the temporary buffer with Tax Group Code.
    /// </summary>
    /// <param name="LineType">Type of the purchase line.</param>
    /// <param name="No">No. of the item/G/L account etc.</param>
    /// <param name="TaxGroupCode">Tax Group Code.</param>
    /// <param name="LineDescription">Description of the line.</param>
    /// <param name="LineQuantity">Quantity.</param>
    /// <param name="UnitCost">Direct Unit Cost.</param>
    /// <param name="DeferralCode">Deferral Code.</param>
    /// <param name="UnitOfMeasureCode">Unit of Measure Code.</param>
    procedure AddLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; LineDescription: Text[100]; LineQuantity: Decimal; UnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        TempSamplePurchInvHeader.TestField("No.");
        LineCounter += 10000;

        TempSamplePurchInvLine.Init();
        TempSamplePurchInvLine."Document No." := CurrentDocNo;
        TempSamplePurchInvLine."Line No." := LineCounter;
        TempSamplePurchInvLine.Type := LineType;
        TempSamplePurchInvLine."No." := No;
        TempSamplePurchInvLine."Tax Group Code" := TaxGroupCode;
        TempSamplePurchInvLine.Description := LineDescription;
        TempSamplePurchInvLine.Quantity := LineQuantity;
        TempSamplePurchInvLine."Direct Unit Cost" := UnitCost;
        TempSamplePurchInvLine."Deferral Code" := DeferralCode;
        TempSamplePurchInvLine."Unit of Measure Code" := UnitOfMeasureCode;
        TempSamplePurchInvLine.Insert();
    end;

    /// <summary>
    /// Generates a PDF from the current header and lines buffer.
    /// </summary>
    /// <returns>TempBlob containing the generated PDF.</returns>
    procedure GeneratePDF() TempBlob: Codeunit "Temp Blob"
    var
        SamplePurchaseInvoice: Report "Sample Purchase Invoice";
        FileManagement: Codeunit "File Management";
        FilePath: Text[250];
    begin
        TempSamplePurchInvHeader.Reset();
        TempSamplePurchInvLine.Reset();

        SamplePurchaseInvoice.SetData(TempSamplePurchInvHeader, TempSamplePurchInvLine);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, MaxStrLen(FilePath));
        SamplePurchaseInvoice.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
    end;

    /// <summary>
    /// Clears all temporary data from the buffers.
    /// </summary>
    procedure Clear()
    begin
        TempSamplePurchInvHeader.Reset();
        TempSamplePurchInvHeader.DeleteAll();
        TempSamplePurchInvLine.Reset();
        TempSamplePurchInvLine.DeleteAll();
        CurrentDocNo := '';
        LineCounter := 0;
    end;

    /// <summary>
    /// Gets the current temporary header buffer.
    /// </summary>
    /// <param name="TempHeader">Variable to receive the header records.</param>
    procedure GetHeaders(var TempHeader: Record "Sample Purch. Inv. Header" temporary)
    begin
        TempHeader.Copy(TempSamplePurchInvHeader, true);
    end;

    /// <summary>
    /// Gets the current temporary line buffer.
    /// </summary>
    /// <param name="TempLines">Variable to receive the line records.</param>
    procedure GetLines(var TempLines: Record "Sample Purch. Inv. Line" temporary)
    begin
        TempLines.Copy(TempSamplePurchInvLine, true);
    end;
}
