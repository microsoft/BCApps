#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.History;
using System.IO;

/// <summary>
/// Exports sales credit memos to PEPPOL 2.0 electronic document format.
/// </summary>
codeunit 1603 "Export Sales Cr.M. - PEPPOL2.0"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'PEPPOL 2.0 is no longer supported.';
    ObsoleteTag = '26.0';
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesCrMemoHeader, OutStr);

        Rec.Modify();
    end;

    /// <summary>
    /// Generates an XML file in PEPPOL 2.0 format for the sales credit memo.
    /// </summary>
    /// <param name="VariantRec">Specifies the sales credit memo record to export.</param>
    /// <param name="OutStr">Returns the generated XML content as an output stream.</param>
    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesCreditMemoPEPPOL20: XMLport "Sales Credit Memo - PEPPOL 2.0";
    begin
        SalesCreditMemoPEPPOL20.Initialize(VariantRec);
        SalesCreditMemoPEPPOL20.SetDestination(OutStr);
        SalesCreditMemoPEPPOL20.Export();
    end;
}
#endif
