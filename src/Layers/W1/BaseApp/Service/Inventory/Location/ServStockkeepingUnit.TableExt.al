// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Service.Document;

tableextension 6454 "Serv. Stockkeeping Unit" extends "Stockkeeping Unit"
{
    fields
    {
        field(5901; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = sum("Service Line"."Outstanding Qty. (Base)" where("Document Type" = const(Order),
                                                                              Type = const(Item),
                                                                              "No." = field("Item No."),
                                                                              "Location Code" = field("Location Code"),
                                                                              "Variant Code" = field("Variant Code"),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Needed by Date" = field("Date Filter")));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
