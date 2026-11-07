// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 5617 FASourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("FA Registers")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Registers';
                Image = FARegisters;
                RunObject = Page "FA Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View the fixed asset registers. Every register shows the first and last entry numbers of its entries. An FA register is created when you post a transaction that results in one or more FA entries.';
            }
        }
    }
}
