// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.History;
using System.IO;

codeunit 37205 "Exp. Sales CrM. PEPPOL30"
{
    TableNo = "Record Export Buffer";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PeppolSetup: Record "PEPPOL 3.0 Setup";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesCrMemoHeader);

        PeppolSetup.GetSetup();
        PEPPOL30Validation := PeppolSetup."PEPPOL 3.0 Sales Format";
        PEPPOL30Validation.ValidatePostedDocument(SalesCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesCrMemoHeader, OutStr, PeppolSetup."PEPPOL 3.0 Sales Format");

        Rec.Modify(false);
    end;

    /// <summary>
    /// Generates the XML file for a PEPPOL 3.0 sales credit memo.
    /// </summary>
    /// <param name="VariantRec">The record containing the sales credit memo data.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream; Format: Enum "PEPPOL 3.0 Format")
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL30";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec, Format);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}
