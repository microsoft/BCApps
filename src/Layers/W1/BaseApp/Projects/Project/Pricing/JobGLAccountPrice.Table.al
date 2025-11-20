// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Projects.Project.Job;

table 1014 "Job G/L Account Price"
{
    Caption = 'Project G/L Account Price';
    DrillDownPageID = "Job G/L Account Prices";
    LookupPageID = "Job G/L Account Prices";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            NotBlank = true;
            TableRelation = Job;

            trigger OnValidate()
            begin
                GetJob();
                "Currency Code" := Job."Currency Code";
            end;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            begin
                if "Job Task No." <> '' then begin
                    JT.Get("Job No.", "Job Task No.");
                    JT.TestField("Job Task Type", JT."Job Task Type"::Posting);
                end;
            end;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                "Unit Cost Factor" := 0;
            end;
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then begin
                    "Unit Cost Factor" := 0;
                    "Line Discount %" := 0;
                    "Unit Price" := 0;
                end;
            end;
        }
        field(7; "Unit Cost Factor"; Decimal)
        {
            Caption = 'Unit Cost Factor';

            trigger OnValidate()
            begin
                "Unit Price" := 0;
            end;
        }
        field(8; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(9; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
        }
        field(10; Description; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "G/L Account No.", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        Job.Get("Job No.");
        CheckGLAccountNotEmpty();
    end;

    var
        Job: Record Job;
        JT: Record "Job Task";

    local procedure GetJob()
    begin
        TestField("Job No.");
        Job.Get("Job No.");
    end;

    local procedure CheckGLAccountNotEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccountNotEmpty(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("G/L Account No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccountNotEmpty(var JobGLAccountPrice: Record "Job G/L Account Price"; var IsHandled: Boolean)
    begin
    end;
}
