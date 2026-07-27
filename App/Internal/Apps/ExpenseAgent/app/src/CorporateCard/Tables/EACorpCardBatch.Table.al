// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

table 7212 EACorpCardBatch
{
    Caption = 'Corp Card Import Batch';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardBatches;
    DrillDownPageId = EACorpCardBatches;
    ReplicateData = false;

    fields
    {
        field(1; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            AutoIncrement = true;
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            TableRelation = EACorpCardProvider.Code;
        }
        field(3; "Started DT"; DateTime)
        {
            Caption = 'Started Date-Time';
        }
        field(4; "Ended DT"; DateTime)
        {
            Caption = 'Ended Date-Time';
        }
        field(5; "Source Ref"; Text[100])
        {
            Caption = 'Source Reference';
        }
        field(6; Status; Enum EACorpCardBatchStatus)
        {
            Caption = 'Status';
        }
        field(7; Imported; Integer)
        {
            Caption = 'Imported';
        }
        field(8; Rejected; Integer)
        {
            Caption = 'Rejected';
        }
        field(9; Duplicates; Integer)
        {
            Caption = 'Duplicates';
        }
        field(10; Exceptions; Integer)
        {
            Caption = 'Exceptions';
        }
        field(11; "Data Exch Entry No."; Integer)
        {
            Caption = 'Data Exchange Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
    }

    keys
    {
        key(PK; "Batch No.")
        {
            Clustered = true;
        }
        key(Provider; "Provider Code", "Started DT")
        {
        }
    }
}