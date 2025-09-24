// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;
using Microsoft.Sales.History;
using System.IO;

/// <summary>
/// Codeunit for exporting sales credit memos in PEPPOL 3.0 format.
/// Handles the export process including validation and XML generation.
/// </summary>
codeunit 37205 "Exp. Sales CrM. PEPPOL30"
{
    TableNo = "Record Export Buffer";

    /// <summary>
    /// Main trigger that processes the export of a sales credit memo to PEPPOL 3.0 format.
    /// Validates the document and generates the XML output.
    /// </summary>
    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CompanyInformation: Record "Company Information";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesCrMemoHeader);
        CompanyInformation.Get();

        PEPPOL30Validation := CompanyInformation."E-Document Format";
        PEPPOL30Validation.CheckSalesCreditMemo(SalesCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesCrMemoHeader, OutStr);

        Rec.Modify(false);
    end;

    /// <summary>
    /// Generates the XML file for a PEPPOL 3.0 sales credit memo.
    /// </summary>
    /// <param name="VariantRec">The record containing the sales credit memo data.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL30";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}

