// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Location;

page 149912 "Subc. WIP Entry Create Dialog"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create WIP Ledger Entry';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Parameters';
                field("Location Code"; LocationCode)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Location Code';
                    TableRelation = Location;
                    ToolTip = 'Specifies the location at which the WIP ledger entry is created.';
                }
                field("Quantity (Base)"; QuantityBase)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Manufacturing;
                    Caption = 'Quantity (Base)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity (base) for the new WIP ledger entry.';
                }
            }
        }
    }

    var
        LocationCode: Code[10];
        QuantityBase: Decimal;

    procedure GetLocationCode(): Code[10]
    begin
        exit(LocationCode);
    end;

    procedure GetQuantityBase(): Decimal
    begin
        exit(QuantityBase);
    end;
}