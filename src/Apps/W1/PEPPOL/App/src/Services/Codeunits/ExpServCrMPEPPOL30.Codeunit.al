// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Service.History;
using System.IO;

/// <summary>
/// Codeunit for exporting service credit memos in PEPPOL 3.0 format.
/// Handles the export process including validation and XML generation.
/// </summary>
codeunit 37211 "Exp. Serv.CrM. PEPPOL30"
{
    TableNo = "Record Export Buffer";

    /// <summary>
    /// Main trigger that processes the export of a service credit memo to PEPPOL 3.0 format.
    /// Validates the document and generates the XML output.
    /// </summary>
    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PEPPOLServiceValidation: Codeunit "PEPPOL30 Service Validation";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceCrMemoHeader);

        PEPPOLServiceValidation.CheckServiceCreditMemo(ServiceCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceCrMemoHeader, OutStr);

        Rec.Modify();
    end;

    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL30";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}

