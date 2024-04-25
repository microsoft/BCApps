// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;


table 149030 "BCCT Header"
{
    DataClassification = SystemMetadata;
    Extensible = false;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Description"; Text[50])
        {
            Caption = 'Description';
        }
        field(4; Status; Enum "BCCT Header Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(5; "Started at"; DateTime)
        {
            Caption = 'Started at';
            Editable = false;
        }
        field(6; " Default Delay (ms)"; Integer)
        {
            Caption = 'Default Delay (ms) between tests';
            InitValue = 100;
            MinValue = 1;
            MaxValue = 10000;
        }
        field(7; "Dataset"; Code[50])
        {
            Caption = 'Dataset';
            TableRelation = "BCCT Dataset"."Dataset Name";
        }
        field(8; "Ended at"; DateTime)
        {
            Caption = 'Ended at';
            Editable = false;
        }
        field(9; "Duration"; Duration)
        {
            Caption = 'Duration';
            Editable = false;
        }
        field(10; "No. of tests running"; Integer)
        {
            Caption = 'No. of tests running';
            trigger OnValidate()
            var
                BCCTLine: Record "BCCT Line";
                BCCTHeaderCU: Codeunit "BCCT Header";
            begin
                if "No. of tests running" < 0 then
                    "No. of tests running" := 0;

                if "No. of tests running" <> 0 then
                    exit;

                case Status of
                    Status::Running:
                        begin
                            BCCTLine.SetRange("BCCT Code", "Code");
                            BCCTLine.SetRange(Status, BCCTLine.Status::" ");
                            if not BCCTLine.IsEmpty then
                                exit;
                            BCCTHeaderCU.SetRunStatus(Rec, Rec.Status::Completed);
                            BCCTLine.SetRange("BCCT Code", "Code");
                            BCCTLine.SetRange(Status);
                            BCCTLine.ModifyAll(Status, BCCTLine.Status::Completed);
                        end;
                    Status::Cancelled:
                        begin
                            BCCTLine.SetRange("BCCT Code", "Code");
                            BCCTLine.ModifyAll(Status, BCCTLine.Status::Cancelled);
                        end;
                end;
            end;
        }
        field(11; Tag; Text[20])
        {
            Caption = 'Tag';
            DataClassification = CustomerContent;
        }
#pragma warning disable AA0232
        field(12; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("BCCT Log Entry"."Duration (ms)" where("BCCT Code" = field("Code"), Version = field("Version"), Operation = const('Scenario')));
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(16; "Base Version"; Integer)
        {
            Caption = 'Base Version';
            DataClassification = CustomerContent;
            MinValue = 0;
            trigger OnValidate()
            begin
                if "Base Version" > Version then
                    Error(BaseVersionMustBeLessThanVersionErr)
            end;
        }
        field(19; RunID; Guid)
        {
            Caption = 'Unique RunID';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(20; ModelVersion; Option)
        {
            Caption = 'Model Version';
            OptionMembers = Latest,Preview;
            DataClassification = SystemMetadata;
        }
        field(21; "No. of tests in the last run"; Integer)
        {
            Caption = 'No. of tests in the last run';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("Code"), "Version" = field("Version")));
        }
        field(22; "No. of passed tests last run"; Integer)
        {
            Caption = 'No. of passed tests in the last run';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("Code"), "Version" = field("Version"))); // TODO: Can I filter on option of the status?
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    var
        BaseVersionMustBeLessThanVersionErr: Label 'Base Version must be less than or equal to Version';
}
