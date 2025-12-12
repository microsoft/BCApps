// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

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
    begin
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
}
