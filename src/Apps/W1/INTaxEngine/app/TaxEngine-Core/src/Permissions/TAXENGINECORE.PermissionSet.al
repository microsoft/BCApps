// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.Core;

permissionset 20131 "TAX ENGINE CORE"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Core';

    Permissions = tabledata "Script Symbol" = RIMD,
                  tabledata "Script Symbol Member Value" = RIMD,
                  tabledata "Script Symbol Value" = RIMD,
                  tabledata "Lookup Field Filter" = RIMD,
                  tabledata "Lookup Field Sorting" = RIMD,
                  tabledata "Lookup Table Filter" = RIMD,
                  tabledata "Lookup Table Sorting" = RIMD,
                  tabledata "Script Symbol Lookup" = RIMD;
}
