// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

enum 98 "G/L Setup VAT Calculation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Bill-to/Pay-to No.") { Caption = 'Bill-to/Pay-to No.'; }
    value(1; "Sell-to/Buy-from No.") { Caption = 'Sell-to/Buy-from No.'; }
}
