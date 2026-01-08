// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Foundation.Reporting;
using System.IO;
using System.Utilities;

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
        TempEDocPurchHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchLine: Record "E-Document Purchase Line" temporary;

    /// <summary>
    /// Adds a new header record to the temporary buffer.
    /// </summary>
    procedure AddHeader(NewEDocPurchHeader: Record "E-Document Purchase Header")
    begin
        TempEDocPurchHeader := NewEDocPurchHeader;
        TempEDocPurchHeader.Insert();
    end;

    /// <summary>
    /// Adds a new line record to the temporary buffer.
    /// </summary>
    procedure AddLine(NewEDocPurchLine: Record "E-Document Purchase Line")
    begin
        TempEDocPurchLine := NewEDocPurchLine;
        TempEDocPurchLine.Insert();
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
        TempEDocPurchHeader.Reset();
        TempEDocPurchLine.Reset();

        SamplePurchaseInvoice.SetData(TempEDocPurchHeader, TempEDocPurchLine);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, MaxStrLen(FilePath));
        SamplePurchaseInvoice.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
    end;

    /// <summary>
    /// Generates a PDF from the passed header and lines buffer
    /// </summary>
    /// <param name="TempPassedEDocPurchHeader"></param>
    /// <param name="TempPassedEDocPurchLine"></param>
    /// <returns></returns>
    procedure GeneratePDF(var TempEDocPurchHeaderToSet: Record "E-Document Purchase Header" temporary; var TempEDocPurchLineToSet: Record "E-Document Purchase Line" temporary) TempBlob: Codeunit "Temp Blob"
    var
        SamplePurchaseInvoice: Report "E-Doc Sample Purchase Invoice";
        FileManagement: Codeunit "File Management";
        FilePath: Text[250];
    begin
        SamplePurchaseInvoice.SetData(TempEDocPurchHeaderToSet, TempEDocPurchLineToSet);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, MaxStrLen(FilePath));
        SamplePurchaseInvoice.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
    end;

    /// <summary>
    /// Sets the certain Word layout for E-Doc Sample Purchase Invoice report
    /// </summary>
    /// <param name="LayoutNo"></param>
    procedure SetSamplePurchInvoiceLayout(LayoutName: Text[250])
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedLayout(LayoutName);
    end;
}
