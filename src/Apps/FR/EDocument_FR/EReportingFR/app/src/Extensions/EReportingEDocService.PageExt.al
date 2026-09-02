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
                Visible = (Rec."Document Format" = Rec."Document Format"::"Peppol BIS 3.0 FR") or (Rec."Document Format" = Rec."Document Format"::"Factur-X FR");

                field("FR Sender Platform ID"; Rec."FR Sender Platform ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FR Sender Platform Scheme"; Rec."FR Sender Platform Scheme")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FR Sender Platform Name"; Rec."FR Sender Platform Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}