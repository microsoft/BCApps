// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using System.Utilities;
using Microsoft.Purchases.Document;
using System.IO;

/// <summary>
/// Facade codeunit for managing sample purchase invoice PDF generation.
/// Provides methods to add header, add lines, and generate PDF using temporary tables.
/// </summary>
codeunit 6208 "E-Doc Sample Purch.Inv. PDF"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempSamplePurchInvHeader: Record "E-Doc Sample Purch.Inv. Hdr." temporary;
        TempSamplePurchInvLine: Record "E-Doc Sample Purch. Inv. Line" temporary;

    /// <summary>
    /// Adds a new header record to the temporary buffer.
    /// </summary>
    /// <param name="NewSamplePurchInvHeader">A new sample invoice header to add.</param>
    procedure AddHeader(NewSamplePurchInvHeader: Record "E-Doc Sample Purch.Inv. Hdr.")
    begin
        TempSamplePurchInvHeader := NewSamplePurchInvHeader;
        TempSamplePurchInvHeader.Insert();
    end;

    /// <summary>
    /// Adds a new line record to the temporary buffer.
    /// </summary>
    /// <param name="NewSamplePurchInvLine">A new sample invoice line to add.</param>
    procedure AddLine(NewSamplePurchInvLine: Record "E-Doc Sample Purch. Inv. Line")
    begin
        TempSamplePurchInvLine := NewSamplePurchInvLine;
        TempSamplePurchInvLine.Insert();
    end;

    /// <summary>
    /// Transfers fields from a Purchase Header record to the temporary header buffer.
    /// </summary>
    /// <param name="PurchHeader"></param>
    procedure TransferFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        TempSamplePurchInvHeader.TransferFields(PurchHeader, true);
        TempSamplePurchInvHeader.Insert();
    end;

    /// <summary>
    /// Transfers fields from a Purchase Line record to the temporary line buffer.
    /// </summary>
    /// <param name="PurchLine"></param>
    procedure TransferFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        TempSamplePurchInvLine.TransferFields(PurchLine, true);
        TempSamplePurchInvLine.Insert();
    end;

    /// <summary>
    /// Generates a PDF from the current header and lines buffer.
    /// </summary>
    /// <returns>TempBlob containing the generated PDF.</returns>
    procedure GeneratePDF() TempBlob: Codeunit "Temp Blob"
    var
        SamplePurchaseInvoice: Report "E-Doc Sample Purchase Invoice";
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
}
