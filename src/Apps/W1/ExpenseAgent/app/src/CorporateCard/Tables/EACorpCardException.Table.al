// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7213 EACorpCardException
{
    Access = Internal;
    Caption = 'Corp Card Exception';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardExceptions;
    DrillDownPageId = EACorpCardExceptions;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the entry number for the corporate card exception.';
        }
        field(2; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            TableRelation = EACorpCardBatch."Batch No.";
            ToolTip = 'Specifies the batch number for the corporate card exception.';
        }
        field(3; "Trans Entry No."; Integer)
        {
            Caption = 'Transaction Entry No.';
            TableRelation = EACorpCardTrans."Entry No.";
            ToolTip = 'Specifies the transaction entry number for the corporate card exception.';
        }
        field(4; "Exception Type"; Enum EACorpCardExcpType)
        {
            Caption = 'Exception Type';
            ToolTip = 'Specifies the exception type for the corporate card exception.';
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
            ToolTip = 'Specifies the message for the corporate card exception.';
        }
        field(6; Resolved; Boolean)
        {
            Caption = 'Resolved';
            ToolTip = 'Specifies whether the corporate card exception has been resolved.';
        }
        field(7; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
            ToolTip = 'Specifies the user who resolved the corporate card exception.';
        }
        field(8; "Resolved DT"; DateTime)
        {
            Caption = 'Resolved Date-Time';
            ToolTip = 'Specifies the date and time when the corporate card exception was resolved.';
        }
        field(9; "Created DT"; DateTime)
        {
            Caption = 'Created Date-Time';
            ToolTip = 'Specifies the date and time when the corporate card exception was created.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(OpenByDate; Resolved, "Created DT")
        {
        }
    }
}