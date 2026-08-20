// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

pageextension 10974 "E-Reporting E-Documents" extends "E-Documents"
{
    actions
    {
        addlast(Processing)
        {
            action(RefuseFREInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refuse E-Invoice';
                Image = Reject;
                ToolTip = 'Refuse the incoming French electronic purchase invoice and send the response to the supplier.';
                Visible = (Rec.Direction = Rec.Direction::Incoming) and (Rec."Document Type" = Rec."Document Type"::"Purchase Invoice");

                trigger OnAction()
                var
                    FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
                    FREInvoiceRefusalDialog: Page "FR E-Invoice Refusal Dialog";
                    ReasonCode: Code[20];
                    ReasonDescription: Text[500];
                begin
                    if FREInvoiceRefusalDialog.RunModal() <> Action::OK then
                        exit;
                    FREInvoiceRefusalDialog.GetReason(ReasonCode, ReasonDescription);
                    FREInvoiceMessageMgt.RefuseInvoice(Rec, ReasonCode, ReasonDescription);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
