// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

tableextension 99001531 "Subc. Prod BOM Line Ext." extends "Production BOM Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001522; "Subcontracting Type"; Enum "Subcontracting Type")
        {
            Caption = 'Subcontracting Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production BOM Line.';
            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Subcontracting Type" = "Subcontracting Type"::Transfer then
                    if (Type = Type::Item) and ("No." <> '') then begin
                        Item.Get("No.");
                        Item.TestField(Type, Item.Type::Inventory);
                    end;
            end;
        }
    }
}