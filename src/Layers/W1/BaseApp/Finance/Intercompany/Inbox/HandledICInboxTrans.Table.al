// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;

table 420 "Handled IC Inbox Trans."
{
    Caption = 'Handled IC Inbox Trans.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
#if not CLEANSCHEMA29
        field(3; "Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
            ObsoleteReason = 'Replaced by IC Source Type for Enum typing';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Accepted,Posted,,Returned to IC Partner,Cancelled';
            OptionMembers = Accepted,Posted,,"Returned to IC Partner",Cancelled;
        }
#if not CLEANSCHEMA25
        field(12; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        field(15; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Document Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        HndlInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        HndlICInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        HndlICInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    HndlInboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    HndlInboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    HndlInboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    HndlInboxJnlLine.DeleteAll(true);
                end;
            "IC Source Type"::"Sales Document":
                if HndlICInboxSalesHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then
                    HndlICInboxSalesHdr.Delete(true);
            "IC Source Type"::"Purchase Document":
                if HndlICInboxPurchHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then
                    HndlICInboxPurchHdr.Delete(true);
            else
                OnDeleteOnSourceTypeCase(Rec);
        end;
        DeleteComments("Transaction No.", "IC Partner Code");
    end;

    procedure ShowDetails()
    var
        HandledICInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        HandledICInboxJnlLines: Page "Handled IC Inbox Jnl. Lines";
        HandledICInboxSalesDoc: Page "Handled IC Inbox Sales Doc.";
        HandledICInboxPurchDoc: Page "Handled IC Inbox Purch. Doc.";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    HandledICInboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    HandledICInboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICInboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICInboxJnlLines);
                    HandledICInboxJnlLines.SetTableView(HandledICInboxJnlLine);
                    HandledICInboxJnlLines.RunModal();
                end;
            "IC Source Type"::"Sales Document":
                begin
                    HandledICInboxSalesHeader.SetRange("IC Transaction No.", "Transaction No.");
                    HandledICInboxSalesHeader.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICInboxSalesHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICInboxSalesDoc);
                    HandledICInboxSalesDoc.SetTableView(HandledICInboxSalesHeader);
                    HandledICInboxSalesDoc.RunModal();
                end;
            "IC Source Type"::"Purchase Document":
                begin
                    HandledICInboxPurchHeader.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICInboxPurchHeader.SetRange("IC Transaction No.", "Transaction No.");
                    HandledICInboxPurchHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICInboxPurchDoc);
                    HandledICInboxPurchDoc.SetTableView(HandledICInboxPurchHeader);
                    HandledICInboxPurchDoc.RunModal();
                end;
        end;

        OnAfterShowDetails(Rec);
    end;

    local procedure DeleteComments(TransactionNo: Integer; ICPartnerCode: Code[20])
    var
        ICCommentLine: Record "IC Comment Line";
    begin
        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"Handled IC Inbox Transaction");
        ICCommentLine.SetRange("Transaction No.", TransactionNo);
        ICCommentLine.SetRange("IC Partner Code", ICPartnerCode);
        ICCommentLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;
}

