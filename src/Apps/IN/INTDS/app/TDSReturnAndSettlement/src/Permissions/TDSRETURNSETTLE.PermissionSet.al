// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSReturnAndSettlement;

permissionset 18746 "TDS RETURN SETTLE"
{
    Access = Public;
    Assignable = true;
    Caption = 'TDS Return and Settlement';

    Permissions = tabledata "TDS Journal Batch" = RIMD,
                  tabledata "TDS Journal Line" = RIMD,
                  tabledata "TDS Journal Template" = RIMD,
                  tabledata "TDS Challan Register" = RIMD;
}
