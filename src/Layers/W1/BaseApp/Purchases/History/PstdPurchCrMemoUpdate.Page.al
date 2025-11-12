// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

page 1357 "Pstd. Purch. Cr.Memo - Update"
{
    Caption = 'Posted Purchase Credit Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Purch. Cr. Memo Hdr.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who shipped the items.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the purchase header was posted.';
                }
            }
            group("Cr. Memo Details")
            {
                Caption = 'Cr. Memo Details';
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xPurchCrMemoHdr := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then
            if RecordChanged() then
                Codeunit.Run(Codeunit::"Purch. Cr. Memo. Hdr. - Edit", Rec);
    end;

    var
        xPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged := Rec."Posting Description" <> xPurchCrMemoHdr."Posting Description";
        OnAfterRecordChanged(Rec, xRec, IsChanged, xPurchCrMemoHdr);
    end;

    procedure SetRec(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        Rec := PurchCrMemoHdr;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; xPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsChanged: Boolean; xPurchCrMemoHdrGlobal: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}
