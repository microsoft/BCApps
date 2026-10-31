// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;

pageextension 3309 "PA Purchase Invoice List" extends "Purchase Invoices"
{
    actions
    {
        addlast(processing)
        {
            action(PANewInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New from PDF';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible;

                trigger OnAction()
                var
                    TaskUpload: Codeunit "PA Task Upload";
                begin
                    TaskUpload.UploadInvoiceWithAgent();
                end;
            }
        }
        addlast(Prompting)
        {
            action(PANewInvoicePrompting)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New from PDF';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible;

                trigger OnAction()
                var
                    TaskUpload: Codeunit "PA Task Upload";
                begin
                    TaskUpload.UploadInvoiceWithAgent();
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(PANewInvoice_Promoted; PANewInvoice)
            {
            }
        }
        modify(Category_New)
        {
            ShowAs = SplitButton;
        }
    }
    trigger OnOpenPage()
    begin
        IsAgentActionVisible := PAAgentAccess.CanShowAgentActions();
    end;

    var
        PAAgentAccess: Codeunit "PA Agent Access";
        IsAgentActionVisible: Boolean;
}