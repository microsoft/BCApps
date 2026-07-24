// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

pageextension 10977 "E-Reporting E-Doc. Service" extends "E-Document Service"
{
    layout
    {
        addlast(ExportProcessing)
        {
            group(FrenchLifecycle)
            {
                Caption = 'French Invoice Lifecycle';
                Visible = IsFrenchInvoiceFormat;

                field("FR Sender Platform ID"; Rec."FR Sender Platform ID")
                {
                    ApplicationArea = All;
                }
                field("FR Sender Platform Scheme"; Rec."FR Sender Platform Scheme")
                {
                    ApplicationArea = All;
                }
                field("FR Sender Platform Name"; Rec."FR Sender Platform Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsFrenchInvoiceFormat := Rec."Document Format" in [Rec."Document Format"::"Peppol BIS 3.0 FR", Rec."Document Format"::"Factur-X FR"];
    end;

    var
        IsFrenchInvoiceFormat: Boolean;
}