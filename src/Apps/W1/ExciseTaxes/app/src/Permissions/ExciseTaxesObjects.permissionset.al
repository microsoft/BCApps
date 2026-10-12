// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

permissionset 7450 "ExciseTaxes - Objects"
{
    Caption = 'Excise Taxes - Objects';
    Access = Internal;
    Assignable = false;

    Permissions =
        table "Excise Tax Type" = X,
#if not CLEAN30
        table "Excise Tax Item/FA Rate" = X,
#endif
        table "Excise Tax Rate" = X,
        table "Item Excise Tax" = X,
        table "Excise Tax Entry Permission" = X,
        page "Excise Tax Types" = X,
        page "Excise Tax Type Card" = X,
#if not CLEAN30
        page "Excise Tax Item/FA Rates" = X,
#endif
        page "Excise Tax Rates" = X,
        page "Item Excise Taxes" = X,
        page "Item Excise Tax API" = X,
        page "Excise Tax Entry Permissions" = X,
        report "Create Excise Tax Jnl. Entries" = X,
        codeunit "Excise Tax Upgrade" = X;
}