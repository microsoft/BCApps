// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Foundation.AuditCodes;

/// <summary>
/// Extends Source Codes page with G/L register navigation functionality.
/// Adds action to view G/L registers filtered by the selected source code.
/// </summary>
/// <remarks>
/// Extends Source Codes page. Adds navigation group with G/L Registers action.
/// Enables drill-down from source codes to related G/L posting registers.
/// Provides filtered view of G/L registers based on source code selection.
/// </remarks>
pageextension 45 GLSourceCodesExt extends "Source Codes"
{
    actions
    {
        addfirst(Navigation)
        {
            group("&Source")
            {
                Caption = '&Source';
                Image = CodesList;
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    RunPageLink = "Source Code" = field(Code);
                    RunPageView = sorting("Source Code");
                    ToolTip = 'View posted G/L entries.';
                }
            }
        }
    }
}
