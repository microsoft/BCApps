// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Worksheet;

tableextension 99000787 "Mfg. Item Ledger Entry" extends "Item Ledger Entry"
{
    procedure SetSourceFilterForProdOutputPutAway(ProdOrderLine: Record "Prod. Order Line")
    begin
        SetRange("Order Type", "Order Type"::Production);
        SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        SetRange("Order Line No.", ProdOrderLine."Line No.");
        SetRange("Entry Type", "Entry Type"::Output);
    end;

    procedure SetSourceFilterForProdOutputPutAway(WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        SetRange("Order Type", "Order Type"::Production);
        SetRange("Order No.", WhseWorksheetLine."Source No.");
        SetRange("Order Line No.", WhseWorksheetLine."Source Line No.");
        SetRange("Entry Type", "Entry Type"::Output);
    end;
}