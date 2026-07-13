// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Actions executed after all migrators finish data movement (currently: posting the
/// staged BC14 journal batches). Separate enum from migrators because actions consume
/// already-migrated data rather than producing it — and so partner extensions register
/// new post-migration steps here, not in any migrator enum.
/// </summary>
enum 46884 "BC14 Post Migration Action" implements "BC14 Post Migration Action"
{
    Extensible = true;

    value(0; "Journal Post")
    {
        Caption = 'Journal Post';
        Implementation = "BC14 Post Migration Action" = "BC14 Journal Post Action";
    }
}
