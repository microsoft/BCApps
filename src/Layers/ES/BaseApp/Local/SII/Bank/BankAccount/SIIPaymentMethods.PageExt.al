// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;

pageextension 7000127 "SII Payment Methods" extends "Payment Methods"
{
    layout
    {
        addafter("Pmt. Export Line Definition")
        {
            field("SII Payment Method Code"; Rec."SII Payment Method Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the sii:Medio node in the SII XML file.';
            }
        }
    }
}
