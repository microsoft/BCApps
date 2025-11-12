// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

tableextension 99000757 "Mfg. Item Templ." extends "Item Templ."
{
    fields
    {
        field(8011; "Production Blocked"; Enum "Item Production Blocked")
        {
            Caption = 'Production Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which transactions with the item cannot be processed on production documents, except requisition worksheet, planning worksheet and journals.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Production Blocked"));
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Routing No."));
            end;
        }
        field(99000751; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = CustomerContent;
            TableRelation = "Production BOM Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Production BOM No."));
            end;
        }
        field(99000779; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Non-Inventory Cost';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Single-Lvl Mat. Non-Invt. Cost"));
            end;
        }
        field(99000780; "Allow Whse. Overpick"; Boolean)
        {
            AutoFormatType = 2;
            Caption = 'Allow Whse. Overpick';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that the record is allowed to be created in the Warehouse Pick list against the Released Production Order more than the quantity defined in the component Line. For example, system will allow to create Pick for 10 units even if the component in the BOM is defined for 3 units.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Allow Whse. Overpick"));
            end;
        }
    }
}