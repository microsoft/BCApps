// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 7313 WhseSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("Warehouse Registers")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Registers';
                Image = WarehouseRegisters;
                RunObject = Page "Warehouse Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View all warehouse entries per registration date.';
            }
        }
    }
}
