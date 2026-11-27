// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TCS.TCSBase;

permissionset 18807 "TCS BASE"
{
    Access = Public;
    Assignable = true;
    Caption = 'TCS Base';

    Permissions = tabledata "Allowed NOC" = RIMD,
                  tabledata "Customer Concessional Code" = RIMD,
                  tabledata "T.C.A.N. No." = RIMD,
                  tabledata "TCS Entry" = RIMD,
                  tabledata "TCS Setup" = RIMD,
                  tabledata "TCS Posting Setup" = RIMD,
                  tabledata "TCS Nature Of Collection" = RIMD,
                  tabledata "Sales Line Buffer TCS On Pmt." = RIMD;
}
