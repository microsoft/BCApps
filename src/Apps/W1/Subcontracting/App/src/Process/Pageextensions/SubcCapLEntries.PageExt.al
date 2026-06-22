// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Utilities;

pageextension 99001502 "Subc. CapLEntries" extends "Capacity Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Subc. Purch. Order No."; Rec."Subc. Purch. Order No.")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subc. Purch. Order Line No."; Rec."Subc. Purch. Order Line No.")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
            field("Subc. Subcontractor No."; Rec."Subc. Subcontractor No.")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the number of the related subcontractor.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("Ent&ry")
        {
            group(Production)
            {
                Caption = 'Production';

                action(ShowDocument)
                {
                    ApplicationArea = Subcontracting;
                    Caption = 'Show Document';
                    Image = Document;
                    ToolTip = 'View the document related to this capacity ledger entry. Shows the posted purchase receipt or invoice if available, otherwise shows the purchase order.';
                    trigger OnAction()
                    begin
                        ShowRelatedDocument(Rec);
                    end;
                }
            }
        }
    }
    local procedure ShowRelatedDocument(CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PageManagement: Codeunit "Page Management";
    begin
        if CapacityLedgerEntry."Document No." <> '' then begin
            if PurchRcptHeader.Get(CapacityLedgerEntry."Document No.") then begin
                PageManagement.PageRun(PurchRcptHeader);
                exit;
            end;

            if PurchInvHeader.Get(CapacityLedgerEntry."Document No.") then begin
                PageManagement.PageRun(PurchInvHeader);
                exit;
            end;
        end;

        if CapacityLedgerEntry."Subc. Purch. Order No." <> '' then
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, CapacityLedgerEntry."Subc. Purch. Order No.") then begin
                PageManagement.PageRun(PurchaseHeader);
                exit;
            end;
        // No document found
        Message(NoDocumentFoundMsg);
    end;

    var
        NoDocumentFoundMsg: Label 'No related document could be found for this entry.';
}