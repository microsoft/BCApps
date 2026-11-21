// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

table 6944 "Exp. Report Change Log Entry"
{
    Access = Internal;
    Caption = 'Expense Report Change Log Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "Exp. Report Change Log Entries";
    LookupPageId = "Exp. Report Change Log Entries";
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the table containing the expense report that currently owns the change entry.';
        }
        field(3; "Source Record System ID"; Guid)
        {
            Caption = 'Source Record System ID';
            DataClassification = SystemMetadata;
            TableRelation =
            if ("Source Table ID" = const(Database::"Expense Report Header")) "Expense Report Header".SystemId
            else
            if ("Source Table ID" = const(Database::"Posted Expense Report Header")) "Posted Expense Report Header".SystemId;
            ToolTip = 'Specifies the immutable SystemId of the expense report that currently owns the change entry.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Expense Report No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the expense report that was changed.';
        }
        field(5; "Document Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the expense report line that was changed. The value is 0 for changes to the expense report header.';
        }
        field(6; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the expense that the changed expense report line was created from.';
        }
        field(7; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(8; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Field Caption"; Text[80])
        {
            Caption = 'Field';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the field that was changed.';
        }
        field(10; "Old Value"; Text[2048])
        {
            Caption = 'Old Value';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the value of the field before the change.';
        }
        field(11; "New Value"; Text[2048])
        {
            Caption = 'New Value';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the value of the field after the change.';
        }
        field(12; "User ID"; Code[50])
        {
            Caption = 'Changed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the user who made the change.';
        }
        field(13; "Changed At"; DateTime)
        {
            Caption = 'Date and Time';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the date and time when the change was made.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Source; "Source Table ID", "Source Record System ID", "Document Line No.", "Entry No.")
        {
        }
    }

    trigger OnModify()
    begin
        Error(CannotModifyErr);
    end;

    trigger OnRename()
    begin
        Error(CannotModifyErr);
    end;

    var
        CannotModifyErr: Label 'Expense report change log entries cannot be modified.';
}