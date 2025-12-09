// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Service.History;
using System.IO;
using Microsoft.Foundation.Company;

codeunit 37211 "Exp. Serv.CrM. PEPPOL30"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CompanyInformation: Record "Company Information";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceCrMemoHeader);
        CompanyInformation.Get();

        PEPPOL30Validation := CompanyInformation."PEPPOL 3.0 Service Format";
        PEPPOL30Validation.ValidateCreditMemo(ServiceCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceCrMemoHeader, OutStr, CompanyInformation."PEPPOL 3.0 Service Format");

        Rec.Modify();
    end;

    /// <summary>
    /// Generates the XML file for a PEPPOL 3.0 sales invoice.
    /// </summary>
    /// <param name="VariantRec">The record containing the sales invoice data.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream; PEPPOL30Format: Enum "PEPPOL 3.0 Format")
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL30";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec, PEPPOL30Format);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}

