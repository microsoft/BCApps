// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

enum 590 "G/L Source Currency Posting"
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Multiple Currencies") { Caption = 'Multiple Currencies'; }
    value(2; "Same Currency") { Caption = 'Same Currency'; }
    value(3; "LCY Only") { Caption = 'LCY Only'; }
}
