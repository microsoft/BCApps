// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Reflection;

table 149032 "BCCT Line"
{
    DataClassification = SystemMetadata;
    Extensible = false;
    Access = Internal;
    ReplicateData = false;

    fields
    {
        field(1; "BCCT Code"; Code[100])
        {
            Caption = 'BCCT Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "BCCT Header";
            DataClassification = CustomerContent;
        }
        field(2; "Line No."; Integer)
        {
            Editable = false;
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                CodeunitMetadata: Record "CodeUnit Metadata";
                BCCTLookupRoles: Page "BCCT Lookup Codeunits";
            begin
                BCCTLookupRoles.LookupMode := true;
                if BCCTLookupRoles.RunModal() = ACTION::LookupOK then begin
                    BCCTLookupRoles.GetRecord(CodeunitMetadata);
                    Validate("Codeunit ID", CodeunitMetadata.ID);
                end;
            end;

            trigger OnValidate()
            var
                CodeunitMetadata: Record "CodeUnit Metadata";
            begin
                CodeunitMetadata.Get("Codeunit ID");
                CalcFields("Codeunit Name");


                if ("Codeunit ID" = Codeunit::"BCCT Role Wrapper") or not (CodeunitMetadata.TableNo in [0, Database::"BCCT Line"]) then
                    if not (CodeunitMetadata.SubType = CodeunitMetadata.SubType::Test) then
                        Error(NotSupportedCodeunitErr, "Codeunit Name");
            end;
        }
#pragma warning disable AS0086
        field(4; "Codeunit Name"; Text[249])
#pragma warning restore AS0086
        {
            Caption = 'Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit), "Object ID" = field("Codeunit ID")));
        }

        field(6; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(7; Dataset; Text[100])
        {
            Caption = 'Override the suite dataset';
            DataClassification = CustomerContent;
            TableRelation = "BCCT Dataset"."Dataset Name";
        }
        field(9; "Status"; Enum "BCCT Line Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(10; "Min. User Delay (ms)"; Integer)
        {
            Caption = 'Min. User Delay (ms)';
            MinValue = 100;
            MaxValue = 10000;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Max. User Delay (ms)" < "Min. User Delay (ms)" then
                    "Max. User Delay (ms)" := "Min. User Delay (ms)";
            end;
        }
        field(11; "Max. User Delay (ms)"; Integer)
        {
            Caption = 'Max. User Delay (ms)';
            MinValue = 1000;
            MaxValue = 30000;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Max. User Delay (ms)" < "Min. User Delay (ms)" then
                    "Max. User Delay (ms)" := "Min. User Delay (ms)";
            end;
        }
        field(12; "Delay (ms btwn. iter.)"; Integer)
        {
            Caption = 'Delay between iterations (ms)';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(14; "Version Filter"; Integer)
        {
            Caption = 'Version Filter';
            FieldClass = FlowFilter;
        }
        field(15; "No. of Tests"; Integer)
        {
            Caption = 'No. of Tests';
            // ToolTip ='Specifies the number of tests executed for this BCCT line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> '')));
        }
#pragma warning disable AA0232
        // TODO: Remove warning, add SIFT key
        field(16; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("BCCT Log Entry"."Duration (ms)" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(19; Sequence; Option)
        {
            Caption = 'Sequence';
            OptionMembers = Initialization,Scenario,Finish;
            DataClassification = CustomerContent;
        }
        field(21; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(25; "Base Version Filter"; Integer)
        {
            Caption = 'Base Version Filter';
            FieldClass = FlowFilter;
        }
        field(26; "No. of Tests - Base"; Integer)
        {
            Caption = 'No. of Tests - Base';
            // ToolTip ='Specifies the number of tests executed for this BCCT line for the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(27; "Total Duration - Base (ms)"; Integer)
        {
            Caption = 'Total Duration - Base (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("BCCT Log Entry"."Duration (ms)" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(22; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Tests Passed';
            // ToolTip ='Specifies the number of tests passed in the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(23; "No. of Operations"; Integer) //TODO: Change the name to No. of Scenarios? 
        {
            Caption = 'No. of Operations';
            // ToolTip ='Specifies the number of operations executed including "Execute Procedure" operation for the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Version Filter")));
        }
        field(30; "No. of Tests Passed - Base"; Integer)
        {
            Caption = 'No. of Tests Passed - Base';
            // ToolTip ='Specifies the number of tests passed in the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Execute Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(31; "No. of Operations - Base"; Integer) //TODO: Change the name to No. of Scenarios? 
        {
            Caption = 'No. of Operations - Base';
            // ToolTip ='Specifies the number of operations executed including "Execute Procedure" operation for the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BCCT Log Entry" where("BCCT Code" = field("BCCT Code"), "BCCT Line No." = field("Line No."), Version = field("Base Version Filter")));
        }
    }

    keys
    {
        key(Key1; "BCCT Code", "Line No.")
        {
            Clustered = true;
        }

        key(Key3; "BCCT Code", "Codeunit ID")
        {
            IncludedFields = Dataset;
        }
    }

    var
        NotSupportedCodeunitErr: Label 'Codeunit %1 can not be used for testing.', Comment = '%1 = codeunit name';

}