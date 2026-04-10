// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Stores processed intercompany outbox transactions after successful transmission to partners.
/// Maintains historical archive of completed intercompany transactions for audit and tracking purposes.
/// </summary>
/// <remarks>
/// Historical archive table for completed intercompany outbox transactions.
/// Supports transaction tracking, status monitoring, and comprehensive audit trails for intercompany operations.
/// Integration points: IC Partner, transaction source documents, G/L accounts, journal processing.
/// </remarks>
table 416 "Handled IC Outbox Trans."
{
    Caption = 'Handled IC Outbox Trans.';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique transaction number for intercompany transaction identification.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code identifying the receiving company.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type of the intercompany transaction for legacy transaction categorization.
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
        /// Source type of the intercompany transaction for classification and routing.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type for the intercompany transaction processing.
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number for transaction identification and reference.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Date when the intercompany transaction was posted for accounting and audit purposes.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source of the transaction indicating whether created by current company or rejected by partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document date from the source transaction for chronological tracking and reporting.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Current status of the handled intercompany transaction indicating transmission and processing state.
        /// </summary>
        field(11; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Sent to IC Partner,Rejection Sent to IC Partner,Cancelled';
            OptionMembers = "Sent to IC Partner","Rejection Sent to IC Partner",Cancelled;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC partner G/L account number for legacy transaction mapping and compatibility.
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
        /// Source line number from the originating document for detailed transaction traceability.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Type of intercompany account used for transaction classification and posting.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Intercompany account number for transaction posting and partner reconciliation.
        /// </summary>
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

    /// <summary>
    /// Opens the appropriate detail page for viewing handled intercompany transaction line details.
    /// Displays journal lines, sales documents, or purchase documents based on transaction source type.
    /// </summary>
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

    /// <summary>
    /// Integration event raised after showing transaction details for custom processing or navigation.
    /// Enables additional detail display or post-processing when viewing handled IC outbox transactions.
    /// </summary>
    /// <param name="HandledICOutboxTrans">Handled IC outbox transaction record displayed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    /// <summary>
    /// Integration event raised during deletion for custom source type processing.
    /// Enables custom cleanup logic for non-standard transaction source types.
    /// </summary>
    /// <param name="HandledICOutboxTrans">Handled IC outbox transaction being deleted</param>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;
}

