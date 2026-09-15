// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6111 "E-Doc. Cust. Ledger Entries" extends "Customer Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field(EDocumentStatus; EDocumentStatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Status';
                ToolTip = 'Specifies the status of the latest electronic document linked to this record. Hidden by default; add it via Personalize to make it visible.';
                Visible = false;
                Editable = false;
            }
        }
        addlast(FactBoxes)
        {
            part(EDocStatusFactBox; "E-Doc. Status FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document';
                ShowFilter = false;
            }
            part(EDocMessages; "E-Document Messages FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Messages';
                ShowFilter = false;
            }
        }
    }
    actions
    {
        addafter("&Navigate")
        {
            action("OpenEDocument")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open E-Document';
                Image = Open;
                Scope = Repeater;
                ToolTip = 'Opens the electronic document linked to this ledger entry, if any.';

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                begin
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", Rec."Posting Date", Rec."Customer No.", Enum::"E-Document Direction"::Outgoing, this.MapToEDocumentType());
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(OpenEDocument_Promoted; OpenEDocument)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        EDocument: Record "E-Document";
    begin
        HasAnyEDocument := GuiAllowed() and EDocument.HasEDocument();
    end;

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := '';
        if HasAnyEDocument then
            EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec."Document No.", Rec."Posting Date", Rec."Customer No.", Enum::"E-Document Direction"::Outgoing, this.MapToEDocumentType());
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.EDocStatusFactBox.Page.SetDocumentIdentity(Rec."Document No.", Rec."Posting Date", Rec."Customer No.", Enum::"E-Document Direction"::Outgoing, this.MapToEDocumentType());
        CurrPage.EDocMessages.Page.SetSourceDocumentIdentity(Rec."Document No.", Rec."Posting Date", Rec."Customer No.", Enum::"E-Document Direction"::Outgoing, this.MapToEDocumentType());
    end;

    var
        HasAnyEDocument: Boolean;
        EDocumentStatusText: Text;

    local procedure MapToEDocumentType(): Enum "E-Document Type"
    begin
        case Rec."Document Type" of
            Rec."Document Type"::Invoice:
                exit(Enum::"E-Document Type"::"Sales Invoice");
            Rec."Document Type"::"Credit Memo":
                exit(Enum::"E-Document Type"::"Sales Credit Memo");
            Rec."Document Type"::"Finance Charge Memo":
                exit(Enum::"E-Document Type"::"Issued Finance Charge Memo");
            Rec."Document Type"::Reminder:
                exit(Enum::"E-Document Type"::"Issued Reminder");
            else
                exit(Enum::"E-Document Type"::None);
        end;
    end;
}
