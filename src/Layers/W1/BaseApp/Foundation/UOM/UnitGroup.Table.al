// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.UOM;

using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

table 5400 "Unit Group"
{
    DataClassification = SystemMetadata;
    Caption = 'Unit Group';
    Extensible = false;

    fields
    {
        field(1; "Source Type"; Enum "Unit Group Source Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Type';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Source Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Id';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item.SystemId
            else
            "Resource".SystemId;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source No.';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item."No."
            else
            "Resource"."No.";
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            FieldClass = FlowField;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Unit Group")));
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Id")
        {
            Clustered = true;
        }
    }

    var
        ItemUnitGroupPrefixLbl: Label 'ITEM', Locked = true;
        ResourceUnitGroupPrefixLbl: Label 'RESOURCE', Locked = true;

    procedure GetCode(): Code[50]
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        case "Source Type" of
            "Source Type"::Item:
                if Item.GetBySystemId("Source Id") then
                    exit(ItemUnitGroupPrefixLbl + ' ' + Item."No." + ' ' + 'UOM GR');
            "Source Type"::Resource:
                if Resource.GetBySystemId("Source Id") then
                    exit(ResourceUnitGroupPrefixLbl + ' ' + Resource."No." + ' ' + 'UOM GR');
        end;
    end;

    procedure GetSourceName(): Text[100]
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        case "Source Type" of
            "Source Type"::Item:
                if Item.GetBySystemId("Source Id") then
                    exit(Item.Description);
            "Source Type"::Resource:
                if Resource.GetBySystemId("Source Id") then
                    exit(Resource.Name);
        end;
    end;
}