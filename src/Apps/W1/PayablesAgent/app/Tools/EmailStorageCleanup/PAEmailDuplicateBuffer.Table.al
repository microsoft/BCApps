// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// In-memory representation of one Email Inbox duplicate group (rows sharing the same account and external message id).
/// </summary>
table 3321 "PA Email Duplicate Buffer"
{
    Caption = 'Email Inbox Duplicate Group';
    DataClassification = SystemMetadata;
    Access = Internal;
    Extensible = false;
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "External Message Id"; Text[2048])
        {
            Caption = 'External message id';
        }
        field(11; "Account Id"; Guid)
        {
            Caption = 'Account id';
        }
        field(12; "Keep Email Inbox Id"; BigInteger)
        {
            Caption = 'Kept Email Inbox id';
        }
        field(20; "Duplicate Count"; Integer)
        {
            Caption = 'Copies';
            ToolTip = 'Specifies how many Email Inbox rows exist for this email. All but the oldest one are redundant.';
        }
        field(21; "Redundant Count"; Integer)
        {
            Caption = 'Redundant copies';
            ToolTip = 'Specifies how many Email Inbox rows would be deleted for this email. The oldest row is always kept.';
        }
        field(22; "Skipped Count"; Integer)
        {
            Caption = 'Copies to skip';
            ToolTip = 'Specifies how many redundant copies would be left untouched (skipped) because their email message is shared with another inbox row, and removing them would take that row''s message with it.';
        }
        field(30; "Sender Address"; Text[250])
        {
            Caption = 'Sender';
        }
        field(31; Description; Text[2048])
        {
            Caption = 'Subject';
        }
        field(40; "Oldest Received DateTime"; DateTime)
        {
            Caption = 'Oldest received';
        }
        field(41; "Newest Received DateTime"; DateTime)
        {
            Caption = 'Newest received';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByRedundancy; "Redundant Count")
        {
        }
    }
}
