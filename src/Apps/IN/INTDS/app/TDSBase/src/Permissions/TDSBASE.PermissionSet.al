// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSBase;

permissionset 18685 "TDS BASE"
{
    Access = Public;
    Assignable = true;
    Caption = 'TDS Base';

    Permissions = tabledata "Acknowledgement Setup" = RIMD,
                  tabledata "Act Applicable" = RIMD,
                  tabledata "Allowed Sections" = RIMD,
                  tabledata "TDS Concessional Code" = RIMD,
                  tabledata "TDS Entry" = RIMD,
                  tabledata "TDS Nature Of Remittance" = RIMD,
                  tabledata "TDS Posting Setup" = RIMD,
                  tabledata "TDS Section" = RIMD,
                  tabledata "TDS Setup" = RIMD;
}
