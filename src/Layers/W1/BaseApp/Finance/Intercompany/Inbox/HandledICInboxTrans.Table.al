// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Archives processed intercompany inbox transactions for historical tracking and audit purposes.
/// Stores completed transaction information including processing status and actions taken.
/// </summary>
table 420 "Handled IC Inbox Trans."
{
    Caption = 'Handled IC Inbox Trans.';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the handled intercompany transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner that sent this handled transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type for the handled transaction indicating the originating document type.
        /// </summary>
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
        /// <summary>
        /// IC source type for cross-reference with partner's transaction classification.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type for the handled transaction processing.
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number for the handled intercompany transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Posting date when the handled transaction was processed.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Transaction source indicating whether the handled transaction was returned by partner or created by partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Document date for the handled intercompany transaction.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Status of the handled transaction processing.
        /// </summary>
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Accepted,Posted,,Returned to IC Partner,Cancelled';
            OptionMembers = Accepted,Posted,,"Returned to IC Partner",Cancelled;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC partner G/L account number for the handled transaction.
        /// </summary>
        field(12; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Source line number for the handled transaction reference.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// IC account type for the handled transaction classification.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// IC account number for the handled transaction processing.
        /// </summary>
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

    /// <summary>
    /// Opens the detailed view for this handled transaction based on its source type (Journal, Sales Document, or Purchase Document).
    /// </summary>
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

    /// <summary>
    /// Integration event raised after showing handled IC transaction details.
    /// </summary>
    /// <param name="HandledICInboxTrans">Handled IC inbox transaction record</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    /// <summary>
    /// Integration event raised during deletion for source type-specific processing.
    /// </summary>
    /// <param name="HandledICInboxTrans">Handled IC inbox transaction record being deleted</param>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;
}

