// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

enum 597 "Exch. Rate Adjmt. Dimensions"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Source Entry Dimensions") { Caption = 'Source Entry Dimensions'; }
    value(1; "No Dimensions") { Caption = 'No Dimensions'; }
    value(2; "G/L Account Dimensions") { Caption = 'G/L Account Dimensions'; }
}
