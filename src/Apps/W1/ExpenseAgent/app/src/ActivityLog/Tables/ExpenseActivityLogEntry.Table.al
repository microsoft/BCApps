// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

table 7100 "Expense Activity Log Entry"
{
    Access = Internal;
    Caption = 'Expense Activity Log Entry';
    DataClassification = CustomerContent;
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
            ToolTip = 'Specifies the table containing the source document that currently owns the activity entry.';
        }
        field(3; "Source Record System ID"; Guid)
        {
            Caption = 'Source Record System ID';
            DataClassification = SystemMetadata;
            TableRelation = if ("Source Table ID" = const(Database::"Expense Report Header")) "Expense Report Header".SystemId
                            else
                            if ("Source Table ID" = const(Database::"Posted Expense Report Header")) "Posted Expense Report Header".SystemId;
            ToolTip = 'Specifies the immutable SystemId of the source document that currently owns the activity entry.';
        }
        field(4; "Subject Table ID"; Integer)
        {
            Caption = 'Subject Table ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the table containing the logical subject described by the activity entry.';
        }
        field(5; "Subject System ID"; Guid)
        {
            Caption = 'Subject System ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the stable SystemId of the logical subject described by the activity entry.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(7; "Document Description"; Text[100])
        {
            Caption = 'Document Description';
            DataClassification = CustomerContent;
        }
        field(8; "Event Type"; Enum "Expense Activity Event Type")
        {
            Caption = 'Activity';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the activity that occurred for the expense report.';
        }
        field(9; "Occurred At"; DateTime)
        {
            Caption = 'Date and Time';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the date and time when the activity occurred.';
        }
        field(10; "Initiated By"; Enum "Expense Activity Initiator")
        {
            Caption = 'Initiated By';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the activity originated from a person or the autonomous Expense Agent.';
        }
        field(11; "Actor Role"; Enum "Expense Activity Actor Role")
        {
            Caption = 'Actor Role';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the business capacity in which the actor performed the activity.';
        }
        field(12; "Actor Table ID"; Integer)
        {
            Caption = 'Actor Table ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the table containing the record that represents the actor.';
        }
        field(13; "Actor Record System ID"; Guid)
        {
            Caption = 'Actor Record System ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = if ("Actor Table ID" = const(Database::"Expense User")) "Expense User".SystemId
                            else
                            if ("Actor Table ID" = const(Database::User)) User.SystemId;
            ToolTip = 'Specifies the immutable SystemId of the record that represents the actor.';
        }
        field(14; "Actor Display Name"; Text[100])
        {
            Caption = 'Performed By';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the name of the user or agent that performed the activity.';
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            DataClassification = AccountData;
        }
        field(16; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount (LCY)';
            DataClassification = AccountData;
        }
        field(17; "Reimbursable Amount"; Decimal)
        {
            AutoFormatExpression = "Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount';
            DataClassification = AccountData;
        }
        field(18; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount (LCY)';
            DataClassification = AccountData;
        }
        field(19; "Refundable Amount"; Decimal)
        {
            AutoFormatExpression = "Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Refundable Amount';
            DataClassification = AccountData;
        }
        field(20; "Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Refundable Amount (LCY)';
            DataClassification = AccountData;
        }
        field(21; "Reimbursement Currency Code"; Code[10])
        {
            Caption = 'Reimbursement Currency Code';
            DataClassification = AccountData;
        }
        field(22; "Reimbursement Currency Factor"; Decimal)
        {
            Caption = 'Reimbursement Currency Factor';
            DataClassification = AccountData;
            DecimalPlaces = 0 : 15;
        }
        field(50; Comment; Text[2048])
        {
            Caption = 'Details';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies additional details recorded for the activity.';
        }
        field(51; Categories; Text[2048])
        {
            Caption = 'Categories';
            DataClassification = CustomerContent;
        }
        field(52; "Attached Receipt Count"; Integer)
        {
            Caption = 'Attached Receipt Count';
            DataClassification = SystemMetadata;
        }
        field(53; "Expense Count"; Integer)
        {
            Caption = 'Expense Count';
            DataClassification = SystemMetadata;
        }
        field(100; "History Actor Table ID Filter"; Integer)
        {
            Caption = 'History Actor Table ID Filter';
            FieldClass = FlowFilter;
        }
        field(101; "History Actor System ID Filter"; Guid)
        {
            Caption = 'History Actor System ID Filter';
            FieldClass = FlowFilter;
        }
        field(102; "History Actor Role Filter"; Enum "Expense Activity Actor Role")
        {
            Caption = 'History Actor Role Filter';
            FieldClass = FlowFilter;
        }
        field(103; "History Subject Match"; Boolean)
        {
            Caption = 'History Subject Match';
            FieldClass = FlowField;
            CalcFormula = exist("Expense Activity Log Entry" where(
                "Subject Table ID" = field("Subject Table ID"),
                "Subject System ID" = field("Subject System ID"),
                "Actor Table ID" = field("History Actor Table ID Filter"),
                "Actor Record System ID" = field("History Actor System ID Filter"),
                "Actor Role" = field("History Actor Role Filter")));
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Source; "Source Table ID", "Source Record System ID", "Occurred At", "Entry No.")
        {
        }
        key(Subject; "Subject Table ID", "Subject System ID", "Occurred At", "Entry No.")
        {
        }
        key(Actor; "Actor Table ID", "Actor Record System ID", "Actor Role", "Subject Table ID", "Subject System ID", "Occurred At", "Entry No.")
        {
        }
        key(Occurred; "Occurred At", "Entry No.")
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
        CannotModifyErr: Label 'Activity log entries cannot be modified.';
}
