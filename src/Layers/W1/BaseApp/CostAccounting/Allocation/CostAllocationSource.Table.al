// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using System.Security.AccessControl;

table 1106 "Cost Allocation Source"
{
    Caption = 'Cost Allocation Source';
    DataClassification = CustomerContent;
    LookupPageID = "Cost Allocation Sources";

    fields
    {
        field(1; ID; Code[10])
        {
            Caption = 'ID';
        }
        field(2; Level; Integer)
        {
            Caption = 'Level';
            InitValue = 1;
            MaxValue = 99;
            MinValue = 1;
        }
        field(3; "Valid From"; Date)
        {
            Caption = 'Valid From';
        }
        field(4; "Valid To"; Date)
        {
            Caption = 'Valid To';
        }
        field(5; "Cost Type Range"; Code[30])
        {
            Caption = 'Cost Type Range';
            TableRelation = "Cost Type";
            ValidateTableRelation = false;
        }
        field(6; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCostCenterCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if ("Cost Center Code" <> '') and ("Cost Object Code" <> '') then
                    Error(Text003);
            end;
        }
        field(7; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCostObjectCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if ("Cost Center Code" <> '') and ("Cost Object Code" <> '') then
                    Error(Text003);
            end;
        }
        field(8; Variant; Code[10])
        {
            Caption = 'Variant';
        }
        field(10; "Credit to Cost Type"; Code[20])
        {
            Caption = 'Credit to Cost Type';
            TableRelation = "Cost Type";
        }
        field(20; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(22; "Total Share"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Cost Allocation Target".Share where(ID = field(ID)));
            Caption = 'Total Share';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(60; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(61; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(100; "Allocation Source Type"; Option)
        {
            Caption = 'Allocation Source Type';
            OptionCaption = 'Both,Actual,Budget';
            OptionMembers = Both,Actual,Budget;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; Level, "Valid From", "Valid To", "Cost Type Range")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; ID, Level, Variant)
        {
        }
    }

    trigger OnDelete()
    begin
        CostAllocationTarget.SetRange(ID, ID);
        CostAllocationTarget.DeleteAll();
    end;

    trigger OnInsert()
    begin
        // Get ID if empty.
        if ID = '' then begin
            CostAccSetup.LockTable();
            CostAccSetup.Get();
            if CostAccSetup."Last Allocation ID" = '' then
                Error(Text000);
            CostAccSetup."Last Allocation ID" := IncStr(CostAccSetup."Last Allocation ID");
            CostAccSetup.Modify();
            ID := CostAccSetup."Last Allocation ID";
        end;

        Modified();
    end;

    trigger OnModify()
    begin
        Modified();
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostAllocationTarget: Record "Cost Allocation Target";

#pragma warning disable AA0074
        Text000: Label 'To assign the allocation ID, the Last Allocation ID field must be defined in the Cost Accounting setup.';
        Text003: Label 'You cannot define both cost center and cost object.';
#pragma warning restore AA0074

    local procedure Modified()
    begin
        "Last Date Modified" := Today;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCostCenterCode(var CostAllocationSource: Record "Cost Allocation Source"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCostObjectCode(var CostAllocationSource: Record "Cost Allocation Source"; var IsHandled: Boolean)
    begin
    end;
}
