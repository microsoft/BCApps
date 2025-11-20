// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Projects.Project.Setup;

table 1006 "Job WIP Method"
{
    Caption = 'Project WIP Method';
    DrillDownPageID = "Job WIP Methods";
    LookupPageID = "Job WIP Methods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                ValidateModification();
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                ValidateModification();
            end;
        }
        field(3; "WIP Cost"; Boolean)
        {
            Caption = 'WIP Cost';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateModification();
                if "Recognized Costs" <> "Recognized Costs"::"Usage (Total Cost)" then
                    Error(Text003, FieldCaption("Recognized Costs"), "Recognized Costs");
            end;
        }
        field(4; "WIP Sales"; Boolean)
        {
            Caption = 'WIP Sales';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateModification();
                if "Recognized Sales" <> "Recognized Sales"::"Contract (Invoiced Price)" then
                    Error(Text003, FieldCaption("Recognized Sales"), "Recognized Sales");
            end;
        }
        field(5; "Recognized Costs"; Enum "Job WIP Recognized Costs Type")
        {
            Caption = 'Recognized Costs';

            trigger OnValidate()
            begin
                ValidateModification();
                if "Recognized Costs" <> "Recognized Costs"::"Usage (Total Cost)" then
                    "WIP Cost" := true;
            end;
        }
        field(6; "Recognized Sales"; Enum "Job WIP Recognized Sales Type")
        {
            Caption = 'Recognized Sales';

            trigger OnValidate()
            begin
                ValidateModification();
                if "Recognized Sales" <> "Recognized Sales"::"Contract (Invoiced Price)" then
                    "WIP Sales" := true;
            end;
        }
        field(7; Valid; Boolean)
        {
            Caption = 'Valid';
            InitValue = true;

            trigger OnValidate()
            var
                JobsSetup: Record "Jobs Setup";
            begin
                JobsSetup.SetRange("Default WIP Method", Code);
                if not JobsSetup.IsEmpty() then
                    Error(Text007, JobsSetup.FieldCaption("Default WIP Method"));
            end;
        }
        field(8; "System Defined"; Boolean)
        {
            Caption = 'System Defined';
            Editable = false;
            InitValue = false;
        }
        field(9; "System-Defined Index"; Integer)
        {
            Caption = 'System-Defined Index';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Valid)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobsSetup: Record "Jobs Setup";
    begin
        if "System Defined" then
            Error(Text001, FieldCaption("System Defined"));

        JobWIPEntry.SetRange("WIP Method Used", Code);
        JobWIPGLEntry.SetRange("WIP Method Used", Code);
        if not (JobWIPEntry.IsEmpty() and JobWIPGLEntry.IsEmpty) then
            Error(Text004, JobWIPEntry.TableCaption(), JobWIPGLEntry.TableCaption());

        JobsSetup.SetRange("Default WIP Method", Code);
        if not JobsSetup.IsEmpty() then
            Error(Text006);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete methods that are %1.';
        Text002: Label 'You cannot modify methods that are %1.';
        Text003: Label 'You cannot modify this field when %1 is %2.';
        Text004: Label 'You cannot delete methods that have entries in %1 or %2.';
        Text005: Label 'You cannot modify methods that have entries in %1 or %2.';
#pragma warning restore AA0470
        Text006: Label 'You cannot delete the default method.';
#pragma warning disable AA0470
        Text007: Label 'This method must be valid because it is defined as the %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateModification()
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        if "System Defined" then
            Error(Text002, FieldCaption("System Defined"));
        JobWIPEntry.SetRange("WIP Method Used", Code);
        JobWIPGLEntry.SetRange("WIP Method Used", Code);
        if not (JobWIPEntry.IsEmpty() and JobWIPGLEntry.IsEmpty) then
            Error(Text005, JobWIPEntry.TableCaption(), JobWIPGLEntry.TableCaption());
    end;
}

