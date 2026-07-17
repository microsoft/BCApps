// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

pageextension 10974 "E-Reporting E-Documents" extends "E-Documents"
{
    layout
    {
        addlast(DocumentList)
        {
            field("Clearance Date"; Rec."Clearance Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Reporting Acceptance Date';
                ToolTip = 'Specifies the date and time when the e-reporting transaction was accepted by the tax authority.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ViewFREInvoiceLifecycles)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Invoice Lifecycles';
                Image = History;
                ToolTip = 'View French electronic invoice lifecycle occurrences for this e-document.';

                trigger OnAction()
                var
                    FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
                begin
                    FREInvoiceLifecycle.SetRange("E-Document Entry No.", Rec."Entry No");
                    Page.Run(Page::"FR E-Invoice Lifecycles", FREInvoiceLifecycle);
                end;
            }
        }
    }
}
