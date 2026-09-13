// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

table 7212 "EA Corp Card Batch"
{
    Caption = 'Corp Card Import Batch';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Batches";
    DrillDownPageId = "EA Corp Card Batches";
    ReplicateData = false;

    fields
    {
        field(1; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the batch number for the imported corporate card transactions.';
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            TableRelation = "EA Corp Card Provider".Code;
            ToolTip = 'Specifies the provider code for the imported corporate card transactions.';
        }
        field(3; "Started DT"; DateTime)
        {
            Caption = 'Started Date-Time';
            ToolTip = 'Specifies the date and time when the import of corporate card transactions started.';
        }
        field(4; "Ended DT"; DateTime)
        {
            Caption = 'Ended Date-Time';
            ToolTip = 'Specifies the date and time when the import of corporate card transactions ended.';
        }
        field(5; "Source Ref"; Text[100])
        {
            Caption = 'Source Reference';
            ToolTip = 'Specifies the source reference for the imported corporate card transactions.';
        }
        field(6; Status; Enum "EA Corp Card Batch Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the imported corporate card transactions.';
        }
        field(7; Imported; Integer)
        {
            Caption = 'Imported';
            ToolTip = 'Specifies the number of imported corporate card transactions.';
        }
        field(8; Rejected; Integer)
        {
            Caption = 'Rejected';
            ToolTip = 'Specifies the number of rejected corporate card transactions.';
        }
        field(9; Duplicates; Integer)
        {
            Caption = 'Duplicates';
            ToolTip = 'Specifies the number of duplicate corporate card transactions.';
        }
        field(10; Exceptions; Integer)
        {
            Caption = 'Exceptions';
            ToolTip = 'Specifies the number of corporate card transactions that have exceptions.';
        }
        field(11; "Data Exch Entry No."; Integer)
        {
            Caption = 'Data Exchange Entry No.';
            TableRelation = "Data Exch."."Entry No.";
            ToolTip = 'Specifies the data exchange entry number for the imported corporate card transactions.';
        }
        field(12; "Imported Transactions"; Integer)
        {
            Caption = 'Imported Transactions';
            FieldClass = FlowField;
            CalcFormula = count("EA Corp Card Trans" where("Batch No." = field("Batch No."), "Provider Code" = field("Provider Code")));
            Editable = false;
            ToolTip = 'Specifies the number of imported corporate card transactions.';
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