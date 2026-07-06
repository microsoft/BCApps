// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;

tableextension 60 ShowCurrencyGenLedgSetup extends "General Ledger Setup"
{
    fields
    {
        /// <summary>
        /// Specifies when the currency symbol is shown in the UI.
        /// This field allows users to configure the visibility of currency symbols based on their preferences.
        /// The options include 'Never', 'Always', 'FCY Only', 'ACY Only', and 'FCY and ACY'.
        /// This flexibility helps in adapting the display of currency symbols to
        /// </summary>
        field(165; "Show Currency"; Enum "Show Currency")
        {
            Caption = 'Show Currency';
            ToolTip = 'Specifies when the currency symbol or code is shown in the UI.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Currency: Record Currency;
            begin
                Currency.CheckDuplicateCurrencySymbol(Rec."Local Currency Symbol");
            end;
        }
        field(166; "Currency Symbol Position"; Enum "Currency Symbol Position")
        {
            Caption = 'Currency Symbol Position';
            ToolTip = 'Specifies the position of the currency symbol in relation to the amount.';
            DataClassification = SystemMetadata;
        }
    }
}