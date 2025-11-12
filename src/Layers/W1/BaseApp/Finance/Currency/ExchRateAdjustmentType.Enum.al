// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

enum 595 "Exch. Rate Adjustment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "No Adjustment") { Caption = 'No Adjustment'; }
    value(1; "Adjust Amount") { Caption = 'Adjust Amount'; }
    value(2; "Adjust Additional-Currency Amount") { Caption = 'Adjust Additional-Currency Amount'; }
}
