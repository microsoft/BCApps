// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Comment;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

table 424 "IC Comment Line"
{
    Caption = 'IC Comment Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'IC Inbox Transaction,IC Outbox Transaction,Handled IC Inbox Transaction,Handled IC Outbox Transaction';
            OptionMembers = "IC Inbox Transaction","IC Outbox Transaction","Handled IC Inbox Transaction","Handled IC Outbox Transaction";
        }
        field(2; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(3; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
        }
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ICCommentLineRec: Record "IC Comment Line"; var ICCommentLineFilter: Record "IC Comment Line")
    begin
    end;
}

