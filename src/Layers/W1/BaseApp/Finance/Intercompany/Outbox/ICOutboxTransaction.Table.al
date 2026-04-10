// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using System.Utilities;

/// <summary>
/// Stores intercompany transactions pending transmission to partner companies.
/// Manages outbound transaction staging, status tracking, and partner communication for intercompany operations.
/// </summary>
/// <remarks>
/// Primary staging table for outbound intercompany transactions. Integrates with partner setup, transaction processing, and status management.
/// Key relationships: IC Partner, IC Outbox Sales Header, IC Outbox Purchase Header, IC Outbox Jnl. Line.
/// Extensible via table extensions for custom transaction types and additional status tracking fields.
/// </remarks>
table 414 "IC Outbox Transaction"
{
    Caption = 'IC Outbox Transaction';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany outbox transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner for this outbound transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner".Code;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type option indicating the origin of the intercompany transaction.
        /// </summary>
        field(3; "Source Type"; Option)
        {
            Caption = 'Source Type';
            Editable = false;
            OptionCaption = 'Journal Line,Sales Document,Purchase Document';
            OptionMembers = "Journal Line","Sales Document","Purchase Document";
            ObsoleteReason = 'Replaced by IC Source Type for Enum typing';
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
        }
#endif
        /// <summary>
        /// Source type enum indicating the origin of the intercompany transaction.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type classification for the intercompany transaction.
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number of the source transaction being processed for intercompany transmission.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;

            trigger OnLookup()
            begin
                OnBeforeLookupDocumentNo(Rec);
            end;
        }
        /// <summary>
        /// Posting date of the source transaction for intercompany processing.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source classification indicating whether transaction was created by current company or rejected by partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document date from the source transaction for intercompany transmission.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Action to be performed on the outbox transaction line during processing.
        /// </summary>
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Send to IC Partner,Return to Inbox,Cancel';
            OptionMembers = "No Action","Send to IC Partner","Return to Inbox",Cancel;

            trigger OnValidate()
            begin
                case "Line Action" of
                    "Line Action"::"Return to Inbox":
                        TestField("Transaction Source", "Transaction Source"::"Rejected by Current Company");
                    "Line Action"::"Send to IC Partner":
                        OutboxCheckSend();
                end;
            end;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC Partner G/L account number for the intercompany transaction.
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
        /// Source line number from the originating document for transaction traceability.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Account type for intercompany journal transactions.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Account number for intercompany journal transactions based on IC Account Type.
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
        key(Key2; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICOutboxPurchHdr: Record "IC Outbox Purchase Header";
        ICOutboxSalesHdr: Record "IC Outbox Sales Header";
        ICCommentLine: Record "IC Comment Line";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    ICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxJnlLine.FindFirst() then
                        ICOutboxJnlLine.DeleteAll(true);
                end;
            "IC Source Type"::"Sales Document":
                begin
                    ICOutboxSalesHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxSalesHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxSalesHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxSalesHdr.FindFirst() then
                        ICOutboxSalesHdr.Delete(true);
                end;
            "IC Source Type"::"Purchase Document":
                begin
                    ICOutboxPurchHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxPurchHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxPurchHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxPurchHdr.FindFirst() then
                        ICOutboxPurchHdr.Delete(true);
                end;
            else
                OnDeleteOnSourceTypeCase(Rec);
        end;

        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"IC Outbox Transaction");
        ICCommentLine.SetRange("Transaction No.", "Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", "IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", "Transaction Source");
        if ICCommentLine.Find('-') then
            repeat
                ICCommentLine.Delete(true);
            until ICCommentLine.Next() = 0;
    end;

    /// <summary>
    /// Opens the detailed view for the outbox transaction based on its source type.
    /// Displays appropriate page for journal lines, sales documents, or purchase documents.
    /// </summary>
    procedure ShowDetails()
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICOutboxPurchHeader: Record "IC Outbox Purchase Header";
        ICOutboxJnlLines: Page "IC Outbox Jnl. Lines";
        ICOutboxSalesDoc: Page "IC Outbox Sales Doc.";
        ICOutboxPurchDoc: Page "IC Outbox Purchase Doc.";
    begin
        case "IC Source Type" of
            "IC Source Type"::Journal:
                begin
                    ICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxJnlLines);
                    ICOutboxJnlLines.SetTableView(ICOutboxJnlLine);
                    ICOutboxJnlLines.RunModal();
                end;
            "IC Source Type"::"Sales Document":
                begin
                    ICOutboxSalesHeader.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxSalesHeader.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxSalesHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxSalesDoc);
                    ICOutboxSalesDoc.SetTableView(ICOutboxSalesHeader);
                    ICOutboxSalesDoc.RunModal();
                end;
            "IC Source Type"::"Purchase Document":
                begin
                    ICOutboxPurchHeader.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxPurchHeader.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxPurchHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxPurchDoc);
                    ICOutboxPurchDoc.SetTableView(ICOutboxPurchHeader);
                    ICOutboxPurchDoc.RunModal();
                end;
        end;

        OnAfterShowDetails(Rec);
    end;

    local procedure OutboxCheckSend()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction2: Record "IC Outbox Transaction";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Transaction No. %2 is a copy of Transaction No. %1, which has already been set to Send to IC Partner.\Do you also want to send Transaction No. %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TransactionAlreadyExistsInOutboxHandledQst: Label '%1 %2 has already been sent to intercompany partner %3. Resending it will create a duplicate %1 for them. Do you want to send it again?', Comment = '%1 - Document Type, %2 - Document No, %3 - IC parthner code';
        SalesInvoicePreviouslySentAsOrderMsg: Label 'A sales order for this invoice has already been sent to intercompany partner %1. Resending it can lead to duplicate information. Do you want to send it?', Comment = '%1 - Intercompany Partner Code';
    begin
        IsHandled := false;
        OnBeforeOutboxCheckSend(Rec, IsHandled);
        if IsHandled then
            exit;

        HandledICOutboxTrans.SetRange("IC Source Type", "IC Source Type");
        HandledICOutboxTrans.SetRange("Document Type", "Document Type");
        HandledICOutboxTrans.SetRange("Document No.", "Document No.");
        OnOutboxCheckSendOnBeforeHandledICOutboxTransFindFirst(Rec, HandledICOutboxTrans);
        if HandledICOutboxTrans.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(
                    TransactionAlreadyExistsInOutboxHandledQst, HandledICOutboxTrans."Document Type",
                    HandledICOutboxTrans."Document No.", HandledICOutboxTrans."IC Partner Code"),
                true)
            then
                Error('');

        ICOutboxTransaction2.SetRange("IC Source Type", "IC Source Type");
        ICOutboxTransaction2.SetRange("Document Type", "Document Type");
        ICOutboxTransaction2.SetRange("Document No.", "Document No.");
        ICOutboxTransaction2.SetFilter("Transaction No.", '<>%1', "Transaction No.");
        ICOutboxTransaction2.SetRange("IC Account Type", "IC Account Type");
        ICOutboxTransaction2.SetRange("IC Account No.", "IC Account No.");
        ICOutboxTransaction2.SetRange("Source Line No.", "Source Line No.");
        ICOutboxTransaction2.SetRange("Line Action", "Line Action"::"Send to IC Partner");
        if ICOutboxTransaction2.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, ICOutboxTransaction2."Transaction No.", "Transaction No."), true)
            then
                Error('');

        if SalesInvoicePreviouslySentAsOrder() then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(SalesInvoicePreviouslySentAsOrderMsg, Rec."IC Partner Code"), true)
            then
                Error('');
    end;

    local procedure SalesInvoicePreviouslySentAsOrder(): Boolean
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Invoice then
            exit(false);
        if Rec."IC Source Type" <> Rec."IC Source Type"::"Sales Document" then
            exit(false);
        if Rec."Transaction Source" <> Rec."Transaction Source"::"Created by Current Company" then
            exit(false);
        if not ICOutboxSalesHeader.Get(Rec."Transaction No.", Rec."IC Partner Code", Rec."Transaction Source") then
            exit(false);
        HandledICOutboxTrans.SetRange("IC Partner Code", Rec."IC Partner Code");
        HandledICOutboxTrans.SetRange("Transaction Source", Rec."Transaction Source");
        HandledICOutboxTrans.SetRange("Document No.", ICOutboxSalesHeader."Order No.");
        HandledICOutboxTrans.SetRange("IC Source Type", Rec."IC Source Type");
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Order);
        exit(not HandledICOutboxTrans.IsEmpty());
    end;

    /// <summary>
    /// Integration event raised after showing transaction details to enable custom processing.
    /// </summary>
    /// <param name="IOutboxTransction">IC Outbox Transaction record after details display</param>
    /// <remarks>
    /// Raised from ShowDetails procedure after displaying transaction details page.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDetails(var IOutboxTransction: Record "IC Outbox Transaction")
    begin
    end;

    /// <summary>
    /// Integration event raised before document number lookup to enable custom lookup logic.
    /// </summary>
    /// <param name="ICOutboxTransaction">IC Outbox Transaction record for lookup context</param>
    /// <remarks>
    /// Raised from Document No. field OnLookup trigger.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocumentNo(ICOutboxTransaction: Record "IC Outbox Transaction");
    begin
    end;

    /// <summary>
    /// Integration event raised before outbox send validation to enable custom send checks.
    /// </summary>
    /// <param name="ICOutboxTransaction">IC Outbox Transaction record being validated</param>
    /// <param name="IsHandled">Set to true to skip standard send validation</param>
    /// <remarks>
    /// Raised from OutboxCheckSend procedure before standard validation logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutboxCheckSend(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;
    /// <summary>
    /// Integration event raised before finding handled outbox transactions for send validation.    
    /// </summary>
    /// <param name="ICOutboxTrans">IC Outbox Transaction record being validated</param>
    /// <param name="HandledICOutboxTrans">Handled IC Outbox Transactions record for filtering</param>
    /// <remarks>   
    /// Raised from OutboxCheckSend procedure before searching for handled outbox transactions.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOutboxCheckSendOnBeforeHandledICOutboxTransFindFirst(var ICOutboxTrans: Record "IC Outbox Transaction"; var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    /// <summary>
    /// Integration event raised during transaction deletion based on source type.
    /// Enables custom cleanup logic for specific source type scenarios.
    /// </summary>
    /// <param name="ICOutboxTransaction">IC Outbox Transaction record being deleted</param>
    /// <remarks>
    /// Raised from OnDelete trigger during source type-specific deletion processing.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;
}

