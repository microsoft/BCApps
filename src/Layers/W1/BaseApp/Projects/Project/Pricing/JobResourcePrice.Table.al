// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 1012 "Job Resource Price"
{
    Caption = 'Project Resource Price';
    DrillDownPageID = "Job Resource Prices";
    LookupPageID = "Job Resource Prices";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
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
            ToolTip = 'Specifies the number of the project task if the resource price should only apply to a specific project task.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            begin
                LockTable();
                if "Job Task No." <> '' then begin
                    JT.Get("Job No.", "Job Task No.");
                    JT.TestField("Job Task Type", JT."Job Task Type"::Posting);
                end;
            end;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the price that you are setting up for the project should apply to a resource, to a resource group, or to all resources and resource groups.';
            OptionCaption = 'Resource,Group(Resource),All';
            OptionMembers = Resource,"Group(Resource)",All;

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    Code := '';
                    Description := '';
                end;
            end;
        }
        field(4; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the resource or resource group that this price applies to. The No. must correspond to your selection in the Type field.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const("Group(Resource)")) "Resource Group";

            trigger OnValidate()
            var
                Res: Record Resource;
                ResGrp: Record "Resource Group";
            begin
                if (Code <> '') and (Type = Type::All) then
                    Error(Text000, FieldCaption(Code), FieldCaption(Type), Type);
                case Type of
                    Type::Resource:
                        begin
                            Res.Get(Code);
                            Description := Res.Name;
                        end;
                    Type::"Group(Resource)":
                        begin
                            ResGrp.Get(Code);
                            "Work Type Code" := '';
                            Description := ResGrp.Name;
                        end;
                    Type::All:
                        begin
                            "Work Type Code" := '';
                            Description := '';
                        end;
                end;
            end;
        }
        field(5; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";
        }
        field(6; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';

            trigger OnValidate()
            begin
                "Unit Cost Factor" := 0;
            end;
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code for the currency of the sales price if the price that you have set up in this line is in a foreign currency. Choose the field to see the available currency codes.';
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
        field(8; "Unit Cost Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Cost Factor';
            ToolTip = 'Specifies the unit cost factor. If you have agreed with you customer that he should pay for certain resource usage by cost value plus a certain percent value to cover your overhead expenses, you can set up a unit cost factor in this field.';

            trigger OnValidate()
            begin
                "Unit Price" := 0;
            end;
        }
        field(9; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies a line discount percent that applies to this resource, or resource group. This is useful, for example if you want invoice lines for the project to show a discount percent.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the resource, or resource group, you have entered in the Code field.';
            Editable = false;
        }
        field(11; "Apply Job Price"; Boolean)
        {
            Caption = 'Apply Project Price';
            ToolTip = 'Specifies whether the price for this resource, or resource group, should apply to the project, even if the price is zero.';
            InitValue = true;
        }
        field(12; "Apply Job Discount"; Boolean)
        {
            Caption = 'Apply Project Discount';
            ToolTip = 'Specifies whether to apply a discount to the project. Select this field if the discount percent for this resource or resource group should apply to the project, even if the discount percent is zero.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", Type, "Code", "Work Type Code", "Currency Code")
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
        if (Type = Type::Resource) and (Code = '') then
            FieldError(Code);
    end;

    trigger OnModify()
    begin
        if (Type = Type::Resource) and (Code = '') then
            FieldError(Code);
    end;

    var
        Job: Record Job;
        JT: Record "Job Task";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be specified when %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetJob()
    begin
        TestField("Job No.");
        Job.Get("Job No.");
    end;
}
