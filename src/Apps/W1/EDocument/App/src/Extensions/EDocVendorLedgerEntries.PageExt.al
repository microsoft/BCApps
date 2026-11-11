// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

pageextension 6112 "E-Doc. Vendor Ledger Entries" extends "Vendor Ledger Entries"
{
    layout
    {
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
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", Rec."Posting Date", Rec."Vendor No.", Enum::"E-Document Direction"::Incoming, this.MapToEDocumentType());
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.EDocStatusFactBox.Page.SetDocumentIdentity(Rec."Document No.", Rec."Posting Date", Rec."Vendor No.", Enum::"E-Document Direction"::Incoming, this.MapToEDocumentType());
        CurrPage.EDocMessages.Page.SetSourceDocumentIdentity(Rec."Document No.", Rec."Posting Date", Rec."Vendor No.", Enum::"E-Document Direction"::Incoming, this.MapToEDocumentType());
    end;

    local procedure MapToEDocumentType(): Enum "E-Document Type"
    begin
        case Rec."Document Type" of
            Rec."Document Type"::Invoice:
                exit(Enum::"E-Document Type"::"Purchase Invoice");
            Rec."Document Type"::"Credit Memo":
                exit(Enum::"E-Document Type"::"Purchase Credit Memo");
            else
                exit(Enum::"E-Document Type"::None);
        end;
    end;
}
