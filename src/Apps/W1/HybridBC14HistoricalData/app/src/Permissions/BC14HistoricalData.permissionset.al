// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

permissionset 46882 "BC14 Historical Data"
{
    Assignable = true;
    Caption = 'BC14 Historical Data';

    Permissions =
        tabledata "BC14 Arch. Sales Inv. Header" = RIMD,
        tabledata "BC14 Arch. Sales Inv. Line" = RIMD,
        tabledata "BC14 Old G/L Entry" = RIMD,
        tabledata "BC14 Old Cust. Ledg. Entry" = RIMD;
}
