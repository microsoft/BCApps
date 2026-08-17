// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

enumextension 46851 "BC14 Warning Type Ext" extends "Cloud Migration Warning Type"
{
    value(46850; "BC14 Balance Mismatch")
    {
        Caption = 'Balance Mismatch';
        Implementation = "Cloud Migration Warning" = "BC14 Balance Warning";
    }
}
