// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

enumextension 46850 "BC14 Migration Provider Ext" extends "Custom Migration Provider"
{
    value(46850; "BC14 Re-Implementation")
    {
        Caption = 'Business Central 14 Re-Implementation';
        Implementation = "Custom Migration Provider" = "BC14 Migration Provider", "Custom Migration Table Mapping" = "BC14 Migration Provider";
    }
}
