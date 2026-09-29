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
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ViewFREInvoiceLifecycle)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'French E-Invoice Lifecycle';
                Image = History;
                ToolTip = 'View the French lifecycle statuses and payment occurrences associated with this E-Document.';
                RunObject = page "FR E-Invoice Messages";
                RunPageLink = "E-Document Entry No." = field("Entry No");
            }
            action(RefuseFREInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refuse E-Invoice';
                Image = Reject;
                ToolTip = 'Refuse the incoming French electronic purchase invoice and send the response to the supplier.';
                Visible = (Rec.Direction = Rec.Direction::Incoming) and (Rec."Document Type" = Rec."Document Type"::"Purchase Invoice") and IsSupportedFrenchService;

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
            action(AcceptFREInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Accept E-Invoice';
                Image = Approve;
                ToolTip = 'Accept the incoming French electronic purchase invoice and send the response to the supplier.';
                Visible = (Rec.Direction = Rec.Direction::Incoming) and (Rec."Document Type" = Rec."Document Type"::"Purchase Invoice") and IsSupportedFrenchService;

                trigger OnAction()
                var
                    FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
                begin
                    FREInvoiceMessageMgt.AcceptInvoice(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        EDocumentService: Record "E-Document Service";
    begin
        IsSupportedFrenchService := false;
        if EDocumentService.Get(Rec.Service) then
            IsSupportedFrenchService := EDocumentService."Document Format" in [EDocumentService."Document Format"::"Peppol BIS 3.0 FR", EDocumentService."Document Format"::"Factur-X FR"];
    end;

    var
        IsSupportedFrenchService: Boolean;
}
