// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Ledger;

pageextension 28002 WHTGLRegisters extends "G/L Registers"
{
    layout
    {
        addafter("To VAT Entry No.")
        {
            field("From WHT Entry No."; Rec."From WHT Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the first WHT entry number in the register.';
            }
            field("To WHT Entry No."; Rec."To WHT Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the last entry number in the register.';
            }
        }
    }

    actions
    {
        addafter(ChangeDimensions)
        {
            action("WHT Entries")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Entries';
                RunObject = Codeunit "G/L Reg.-WHT Entries";
                ToolTip = 'View the withholding tax entries for the register.';
            }
        }
    }
}
