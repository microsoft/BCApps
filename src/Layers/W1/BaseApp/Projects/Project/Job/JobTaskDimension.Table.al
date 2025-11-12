// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

table 1002 "Job Task Dimension"
{
    Caption = 'Project Task Dimension';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Job Task"."Job No.";
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            TableRelation = Dimension.Code;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
                "Dimension Value Code" := '';
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"), Blocked = const(false));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
        field(5; "Multiple Selection Action"; Option)
        {
            Caption = 'Multiple Selection Action';
            OptionCaption = ' ,Change,Delete';
            OptionMembers = " ",Change,Delete;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        UpdateGlobalDim('');
    end;

    trigger OnInsert()
    begin
        if "Dimension Value Code" = '' then
            Error(Text001, TableCaption);

        UpdateGlobalDim("Dimension Value Code");
    end;

    trigger OnModify()
    begin
        UpdateGlobalDim("Dimension Value Code");
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnRename(Rec, IsHandled);
        if IsHandled then
            exit;

        Error(Text000, TableCaption);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'At least one dimension value code must have a value. Enter a value or delete the %1. ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure UpdateGlobalDim(DimensionValue: Code[20])
    var
        JobTask: Record "Job Task";
        GLSEtup: Record "General Ledger Setup";
    begin
        GLSEtup.Get();
        if "Dimension Code" = GLSEtup."Global Dimension 1 Code" then begin
            JobTask.Get("Job No.", "Job Task No.");
            JobTask."Global Dimension 1 Code" := DimensionValue;
            JobTask.Modify(true);
        end else
            if "Dimension Code" = GLSEtup."Global Dimension 2 Code" then begin
                JobTask.Get("Job No.", "Job Task No.");
                JobTask."Global Dimension 2 Code" := DimensionValue;
                JobTask.Modify(true);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var JobTaskDimension: Record "Job Task Dimension"; var IsHandled: Boolean)
    begin
    end;
}

