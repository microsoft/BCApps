// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TCS.TCSReturnAndSettlement;

permissionset 18869 "TCS RETURN SETTLE"
{
    Access = Public;
    Assignable = true;
    Caption = 'TCS Return and Settlement';

    Permissions = tabledata "TCS Journal Template" = RIMD,
                  tabledata "TCS Challan Register" = RIMD,
                  tabledata "TCS Journal Line" = RIMD,
                  tabledata "TCS Journal Batch" = RIMD;
}
