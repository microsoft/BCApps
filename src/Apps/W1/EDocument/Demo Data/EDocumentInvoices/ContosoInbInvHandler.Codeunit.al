// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;
using System.Utilities;

/// <summary>
/// Implementation of IStructuredFormatReader for Contoso Inbound E-Document invoices.
/// </summary>
codeunit 5392 "Contoso Inb.Inv. Handler" implements IStructureReceivedEDocument, IStructuredDataType, IStructuredFormatReader, IProcessStructuredData
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Specified how to structure the received E-Document Data Storage into a structured data type.
    /// For example for a PDF this could be calling ADI and populating the structured data type with the ADI result.
    /// </summary>
    /// <param name="EDocumentDataStorage"></param>
    /// <returns></returns>
    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    begin
        exit(this);
    end;

    /// <summary>
    /// Returns the file format of the structured data type, such as JSON or XML.
    /// </summary>
    /// <returns></returns>
    procedure GetFileFormat(): Enum "E-Doc. File Format";
    begin
        exit("E-Doc. File Format"::PDF);
    end;

    /// <summary>
    /// Returns the content of the structured data type, such as a JSON string or XML document.
    /// </summary>
    /// <returns></returns>
    procedure GetContent(): Text;
    begin
        exit('Dummy content for PDF structured data type');
    end;

    /// <summary>
    /// Returns the how the structured data should be "parsed" / read into a draft.
    /// </summary>
    /// <returns></returns>
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        exit(Enum::"E-Doc. Read into Draft"::"Demo Invoice");
    end;

    /// <summary>
    /// Read the data into the E-Document data structures.
    /// </summary>
    /// <param name="EDocument">The E-Document record.</param>
    /// <param name="TempBlob">The temporary blob that contains the data to read</param>
    /// <returns>The data process to run on the structured data.</returns>
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    begin
        // The E-Document Purchase Header and Line records have been already inserted by the "Contoso Inbound E-Document" codeunit
        exit(Enum::"E-Doc. Process Draft"::"Demo Invoice");
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

    /// <summary>
    /// From an E-Document that has had its data structures populated, process the data to assign Business Central values
    /// </summary>
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type";
    begin
        // The E-Document Purchase Header and Line records have been already inserted by the "Contoso Inbound E-Document" codeunit
        exit("E-Document Type"::"Purchase Invoice");
    end;

    /// <summary>
    /// Get the vendor for the E-Document
    /// </summary>
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor;
    begin
        exit(GetDefaultIProcessStructuredDataImplementation().GetVendor(EDocument, Customizations));
    end;

    /// <summary>
    /// Open the draft page for the E-Document
    /// </summary>
    procedure OpenDraftPage(var EDocument: Record "E-Document");
    begin
        GetDefaultIProcessStructuredDataImplementation().OpenDraftPage(EDocument);
    end;

    /// <summary>
    /// Clean up any custom or scenario specific records using during processing 
    /// </summary>
    /// <param name="EDocument"></param>
    procedure CleanUpDraft(EDocument: Record "E-Document");
    begin
        GetDefaultIProcessStructuredDataImplementation().CleanUpDraft(EDocument);
    end;

    local procedure GetDefaultIProcessStructuredDataImplementation(): Interface IProcessStructuredData
    begin
        exit(Enum::"E-Doc. Process Draft"::"Purchase Document");
    end;

}
