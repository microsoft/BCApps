// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSForCustomer;

permissionset 18661 APP
{
    Access = Public;
    Assignable = true;
    Caption = 'app';

    Permissions = tabledata "Customer Allowed Sections" = RIMD,
                  tabledata "TDS Customer Concessional Code" = RIMD;
}
