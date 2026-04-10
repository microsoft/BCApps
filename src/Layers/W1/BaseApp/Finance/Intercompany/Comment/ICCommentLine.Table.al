// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Comment;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

/// <summary>
/// Stores comment lines for intercompany transactions enabling detailed communication between partner companies.
/// Supports annotations on inbox, outbox, and handled transactions for audit trail and collaboration purposes.
/// </summary>
table 424 "IC Comment Line"
{
    Caption = 'IC Comment Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifies the type of intercompany transaction table this comment belongs to.
        /// </summary>
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'IC Inbox Transaction,IC Outbox Transaction,Handled IC Inbox Transaction,Handled IC Outbox Transaction';
            OptionMembers = "IC Inbox Transaction","IC Outbox Transaction","Handled IC Inbox Transaction","Handled IC Outbox Transaction";
        }
        /// <summary>
        /// Transaction number linking this comment to a specific intercompany transaction.
        /// </summary>
        field(2; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Code identifying the intercompany partner associated with this transaction comment.
        /// </summary>
        field(3; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Sequential line number for organizing multiple comments within a transaction.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Date when the comment was created or last modified.
        /// </summary>
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        /// <summary>
        /// Text content of the comment providing additional information or notes about the transaction.
        /// </summary>
        field(6; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        /// <summary>
        /// Indicates whether the comment relates to a rejected or newly created transaction.
        /// </summary>
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
        }
        /// <summary>
        /// Code of the intercompany partner who created this comment for tracking authorship.
        /// </summary>
        field(8; "Created By IC Partner Code"; Code[20])
        {
            Caption = 'Created By IC Partner Code';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Initializes a new comment line with default values including current date and IC partner code.
    /// Sets up proper filtering context for the comment based on transaction and partner information.
    /// </summary>
    procedure SetUpNewLine()
    var
        ICCommentLine: Record "IC Comment Line";
        ICSetup: Record "IC Setup";
    begin
        ICCommentLine.SetRange("Table Name", "Table Name");
        ICCommentLine.SetRange("Transaction No.", "Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", "IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", "Transaction Source");
        ICCommentLine.SetRange(Date, WorkDate());
        if not ICCommentLine.FindFirst() then
            Date := WorkDate();

        if ICSetup.Get() then
            Rec."Created By IC Partner Code" := ICSetup."IC Partner Code";

        OnAfterSetUpNewLine(Rec, ICCommentLine);
    end;

    /// <summary>
    /// Integration event raised after setting up a new comment line for custom initialization logic.
    /// </summary>
    /// <param name="ICCommentLineRec">New comment line record being initialized</param>
    /// <param name="ICCommentLineFilter">Filtered comment line record used for context</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ICCommentLineRec: Record "IC Comment Line"; var ICCommentLineFilter: Record "IC Comment Line")
    begin
    end;
}

