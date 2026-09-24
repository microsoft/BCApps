// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7213 "EA Corp Card Exception"
{
    Access = Internal;
    Caption = 'Corp Card Exception';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Exceptions";
    DrillDownPageId = "EA Corp Card Exceptions";
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the entry number for the corporate card exception.';
        }
        field(2; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Batch"."Batch No.";
            ToolTip = 'Specifies the batch number for the corporate card exception.';
        }
        field(3; "Trans Entry No."; Integer)
        {
            Caption = 'Transaction Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Trans"."Entry No.";
            ToolTip = 'Specifies the transaction entry number for the corporate card exception.';
        }
        field(4; "Exception Type"; Enum "EA Corp Card Exception Type")
        {
            Caption = 'Exception Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the exception type for the corporate card exception.';
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the message for the corporate card exception.';
        }
        field(6; Resolved; Boolean)
        {
            Caption = 'Resolved';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the corporate card exception has been resolved.';
        }
        field(7; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Specifies the user who resolved the corporate card exception.';
        }
        field(8; "Resolved DT"; DateTime)
        {
            Caption = 'Resolved Date-Time';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the date and time when the corporate card exception was resolved.';
        }
        field(9; "Created DT"; DateTime)
        {
            Caption = 'Created Date-Time';
            DataClassification = SystemMetadata;
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

    trigger OnModify()
    begin
        if Resolved = xRec.Resolved then begin
            "Resolved By" := xRec."Resolved By";
            "Resolved DT" := xRec."Resolved DT";
            exit;
        end;

        if Resolved then begin
            "Resolved By" := CopyStr(UserId(), 1, MaxStrLen("Resolved By"));
            "Resolved DT" := CurrentDateTime();
        end else begin
            Clear("Resolved By");
            Clear("Resolved DT");
        end;
    end;
}