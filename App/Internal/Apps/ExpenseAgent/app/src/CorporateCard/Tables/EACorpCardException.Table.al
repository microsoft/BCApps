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
        }
        field(2; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            TableRelation = EACorpCardBatch."Batch No.";
        }
        field(3; "Trans Entry No."; Integer)
        {
            Caption = 'Transaction Entry No.';
            TableRelation = EACorpCardTrans."Entry No.";
        }
        field(4; "Exception Type"; Enum EACorpCardExcpType)
        {
            Caption = 'Exception Type';
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(6; Resolved; Boolean)
        {
            Caption = 'Resolved';
        }
        field(7; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
        }
        field(8; "Resolved DT"; DateTime)
        {
            Caption = 'Resolved Date-Time';
        }
        field(9; "Created DT"; DateTime)
        {
            Caption = 'Created Date-Time';
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