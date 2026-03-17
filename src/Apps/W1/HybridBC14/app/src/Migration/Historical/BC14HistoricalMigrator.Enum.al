// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

enum 50156 "BC14 Historical Migrator" implements "IHistoricalMigrator"
{
    Extensible = true;

    value(0; "Posted Sales Invoice")
    {
        Caption = 'Posted Sales Invoice';
        Implementation = "IHistoricalMigrator" = "BC14 Posted Sales Inv Migr.";
    }
}
