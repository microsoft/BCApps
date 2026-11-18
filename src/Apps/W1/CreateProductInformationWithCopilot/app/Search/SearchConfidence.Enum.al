#if not CLEANSCHEMA33
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

enum 7331 "Search Confidence"
{
    Extensible = false;
#if not CLEAN30
    ObsoleteState = Pending;
    ObsoleteReason = 'Copilot item substitution suggestions are discontinued. Use modern search on the Items list instead.';
    ObsoleteTag = '30.0';
#endif

    value(0; "None")
    {
    }
    value(1; "Low")
    {
    }
    value(2; "Medium")
    {
    }
    value(3; "High")
    {
    }
}
#endif