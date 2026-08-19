// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Enum for registering post-migration validations.
/// </summary>
enum 46885 "BC14 Migration Validation" implements "BC14 Migration Validation"
{
    Extensible = true;

    value(0; "Balance Warning")
    {
        Caption = 'Balance Warning';
        Implementation = "BC14 Migration Validation" = "BC14 Balance Warning";
    }
}
