// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.Receivables;

pageextension 6113 "E-Doc. Payment Registration" extends "Payment Registration"
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
        addafter(Navigate)
        {
            action("OpenEDocument")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open E-Document';
                Image = Open;
                Scope = Repeater;
                ToolTip = 'Opens the electronic document linked to the customer ledger entry that this payment applies to, if any.';

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                begin
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", ApplicablePostingDate, Rec."Source No.", Enum::"E-Document Direction"::Outgoing, ApplicableDocumentType);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        this.UpdateApplicableLedgerEntryData();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.EDocStatusFactBox.Page.SetDocumentIdentity(Rec."Document No.", ApplicablePostingDate, Rec."Source No.", Enum::"E-Document Direction"::Outgoing, ApplicableDocumentType);
        CurrPage.EDocMessages.Page.SetSourceDocumentIdentity(Rec."Document No.", ApplicablePostingDate, Rec."Source No.", Enum::"E-Document Direction"::Outgoing, ApplicableDocumentType);
    end;

    local procedure UpdateApplicableLedgerEntryData()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Clear(ApplicablePostingDate);
        ApplicableDocumentType := Enum::"E-Document Type"::None;

        if not CustLedgerEntry.Get(Rec."Ledger Entry No.") then
            exit;

        ApplicablePostingDate := CustLedgerEntry."Posting Date";
        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                ApplicableDocumentType := Enum::"E-Document Type"::"Sales Invoice";
            CustLedgerEntry."Document Type"::"Credit Memo":
                ApplicableDocumentType := Enum::"E-Document Type"::"Sales Credit Memo";
            CustLedgerEntry."Document Type"::"Finance Charge Memo":
                ApplicableDocumentType := Enum::"E-Document Type"::"Issued Finance Charge Memo";
            CustLedgerEntry."Document Type"::Reminder:
                ApplicableDocumentType := Enum::"E-Document Type"::"Issued Reminder";
        end;
    end;

    var
        ApplicablePostingDate: Date;
        ApplicableDocumentType: Enum "E-Document Type";
}
