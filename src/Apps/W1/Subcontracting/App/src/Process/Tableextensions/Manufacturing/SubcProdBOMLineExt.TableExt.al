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
        field(99001522; "Component Supply Method"; Enum "Component Supply Method")
        {
            Caption = 'Component Supply Method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how components are supplied to the subcontractor for the production BOM line. Vendor-supplied - components are provided by the subcontractor. Consignment at Vendor - components are owned by your company but stored at the subcontractor location. Transfer to Vendor - components are sent to the subcontractor through a transfer order.';
            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Component Supply Method" = "Component Supply Method"::"Transfer to Vendor" then
                    if (Type = Type::Item) and ("No." <> '') then begin
                        Item.Get("No.");
                        Item.TestField(Type, Item.Type::Inventory);
                    end;
            end;
        }
    }
}