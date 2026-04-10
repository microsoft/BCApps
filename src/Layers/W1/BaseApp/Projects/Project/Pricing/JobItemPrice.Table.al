// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;

table 1013 "Job Item Price"
{
    Caption = 'Project Item Price';
    DrillDownPageID = "Job Item Prices";
    LookupPageID = "Job Item Prices";
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
            ToolTip = 'Specifies the number of the project task if the item price should only apply to a specific project task.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            begin
                if "Job Task No." <> '' then begin
                    JT.Get("Job No.", "Job Task No.");
                    JT.TestField("Job Task Type", JT."Job Task Type"::Posting);
                end;
            end;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item that this price applies to. Choose the field to see the available items.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                Item.Get("Item No.");
                Validate("Unit of Measure Code", Item."Sales Unit of Measure");
            end;
        }
        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5; "Unit Price"; Decimal)
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
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the default currency code that is defined for a project. Project item prices will only be used if the currency code for the project item is the same as the currency code set for the project.';
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
            AutoFormatType = 0;
            Caption = 'Unit Cost Factor';
            ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';

            trigger OnValidate()
            begin
                "Unit Price" := 0;
            end;
        }
        field(8; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies a project-specific line discount percent that applies to this line. This is useful, for example, if you want invoice lines for the project to show a discount percent.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(9; Description; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item you have entered in the Item No. field.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant code if the price that you are setting up should apply to a specific variant of the item.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(11; "Apply Job Price"; Boolean)
        {
            Caption = 'Apply Project Price';
            ToolTip = 'Specifies whether the project-specific price or unit cost factor for this item should apply to the project. The default project price that is defined is included when project-related entries are created, but you can modify this value.';
            InitValue = true;
        }
        field(12; "Apply Job Discount"; Boolean)
        {
            Caption = 'Apply Project Discount';
            ToolTip = 'Specifies the check box for this field if the project-specific discount percent for this item should apply to the project. The default line discount for the line that is defined is included when project entries are created, but you can modify this value.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Item No.", "Variant Code", "Unit of Measure Code", "Currency Code")
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
        CheckItemNoNotEmpty();
    end;

    var
        Item: Record Item;
        Job: Record Job;
        JT: Record "Job Task";

    local procedure GetJob()
    begin
        TestField("Job No.");
        Job.Get("Job No.");
    end;

    local procedure CheckItemNoNotEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemNoNotEmpty(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemNoNotEmpty(var JobItemPrice: Record "Job Item Price"; var IsHandled: Boolean)
    begin
    end;
}
