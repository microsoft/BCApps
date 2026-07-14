// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

pageextension 13414 "Currencies FI" extends Currencies
{
    actions
    {
        addlast(processing)
        {
            action("Import Exchange Rates")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Exchange Rates';
                Image = Import;
                RunObject = Codeunit "Currency Exch. Rate Import";
                ToolTip = 'Update currency exchange rates.';
            }
        }
    }
}
