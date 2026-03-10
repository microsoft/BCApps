// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;

enumextension 50150 "BC14 Migration Provider Ext" extends "Custom Migration Provider"
{
    value(50150; "BC14 Re-Implementation")
    {
        Caption = 'BC14 Re-Implementation';
        Implementation = "Custom Migration Provider" = "BC14 Migration Provider", "Custom Migration Table Mapping" = "BC14 Migration Provider";
    }
}
