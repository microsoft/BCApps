// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace ExternalEDocument.WriterConsumer;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

/// <summary>
/// Compile-time external consumer: no internalsVisibleTo grant from E-Document Core.
/// </summary>
codeunit 50100 "External Purchase Draft Reader" implements IStructuredFormatReader
{
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        TempPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempPurchaseLines: Record "E-Document Purchase Line" temporary;
        PurchaseDraftWriter: Codeunit "E-Doc. Purchase Draft Writer";
    begin
        // A real implementation parses TempBlob before populating these staging buffers.
        TempPurchaseHeader."Vendor Company Name" := 'External Reader Supplier';
        TempPurchaseLines.Init();
        TempPurchaseLines."Line No." := 10000;
        TempPurchaseLines.Description := 'External reader sample';
        TempPurchaseLines.Insert();

        PurchaseDraftWriter.PersistDraft(EDocument, TempPurchaseHeader, TempPurchaseLines);
        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        // Rendering the original document is implementation-specific.
    end;
}
