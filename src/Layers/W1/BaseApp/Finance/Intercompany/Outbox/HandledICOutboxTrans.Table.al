// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;

table 416 "Handled IC Outbox Trans."
{
    Caption = 'Handled IC Outbox Trans.';
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
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Sent to IC Partner,Rejection Sent to IC Partner,Cancelled';
            OptionMembers = "Sent to IC Partner","Rejection Sent to IC Partner",Cancelled;
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
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ICOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        ICOutboxSalesHdr: Record "Handled IC Outbox Sales Header";
        ICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    ICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    ICOutboxJnlLine.DeleteAll(true);
                end;
            "IC Source Type"::"Sales Document":
                if ICOutboxSalesHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then
                    ICOutboxSalesHdr.Delete(true);
            "IC Source Type"::"Purchase Document":
                if ICOutboxPurchHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then
                    ICOutboxPurchHdr.Delete(true);
            else
                OnDeleteOnSourceTypeCase(Rec);
        end;

        DeleteComments("Transaction No.", "IC Partner Code");
    end;

    procedure ShowDetails()
    var
        HandledICOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        HandledICOutboxJnlLines: Page "Handled IC Outbox Jnl. Lines";
        HandledICOutboxSalesDoc: Page "Handled IC Outbox Sales Doc.";
        HandledICOutboxPurchDoc: Page "Handled IC Outbox Purch. Doc.";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    HandledICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    HandledICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICOutboxJnlLines);
                    HandledICOutboxJnlLines.SetTableView(HandledICOutboxJnlLine);
                    HandledICOutboxJnlLines.RunModal();
                end;
            "IC Source Type"::"Sales Document":
                begin
                    HandledICOutboxSalesHeader.SetRange("IC Transaction No.", "Transaction No.");
                    HandledICOutboxSalesHeader.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICOutboxSalesHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICOutboxSalesDoc);
                    HandledICOutboxSalesDoc.SetTableView(HandledICOutboxSalesHeader);
                    HandledICOutboxSalesDoc.RunModal();
                end;
            "IC Source Type"::"Purchase Document":
                begin
                    HandledICOutboxPurchHdr.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICOutboxPurchHdr.SetRange("IC Transaction No.", "Transaction No.");
                    HandledICOutboxPurchHdr.SetRange("Transaction Source", "Transaction Source");
                    Clear(HandledICOutboxPurchDoc);
                    HandledICOutboxPurchDoc.SetTableView(HandledICOutboxPurchHdr);
                    HandledICOutboxPurchDoc.RunModal();
                end;
        end;

        OnAfterShowDetails(Rec);
    end;

    local procedure DeleteComments(TransactionNo: Integer; ICPartnerCode: Code[20])
    var
        ICCommentLine: Record "IC Comment Line";
    begin
        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"Handled IC Outbox Transaction");
        ICCommentLine.SetRange("Transaction No.", TransactionNo);
        ICCommentLine.SetRange("IC Partner Code", ICPartnerCode);
        ICCommentLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;
}

