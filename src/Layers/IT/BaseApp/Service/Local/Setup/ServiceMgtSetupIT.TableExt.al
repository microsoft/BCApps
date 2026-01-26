// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Setup;

tableextension 12460 "Service Mgt. Setup IT" extends "Service Mgt. Setup"
{
    fields
    {
        field(12100; "Validate Document On Posting"; Boolean)
        {
            Caption = 'Validate Document On Posting';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                SalesReceivablesSetup: Record "Sales & Receivables Setup";
                ElectronicDocumentFormat: Record "Electronic Document Format";
            begin
                if "Validate Document On Posting" then begin
                    SalesReceivablesSetup.Get();
                    SalesReceivablesSetup.TestField("Fattura PA Electronic Format");
                    ElectronicDocumentFormat.Get(
                        SalesReceivablesSetup."Fattura PA Electronic Format", ElectronicDocumentFormat.Usage::"Service Validation");
                end;
            end;
        }
        field(12182; "Notify On Occur. Date Change"; Boolean)
        {
            Caption = 'Notify On Occur. Date Change';
            DataClassification = SystemMetadata;
        }
    }
}
