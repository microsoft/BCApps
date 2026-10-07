// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

enum 233 "Vendor Apply Calculation Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Direct") { }
    value(1; "Gen. Jnl. Line") { }
    value(2; "Purchase Header") { }
}
