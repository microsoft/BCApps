// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// File scenarios.
/// Used to decouple file accounts from sending files.
/// </summary>
enum 9451 "File Scenario"
{
    Extensible = true;

    /// <summary>
    /// The default file scenario.
    /// Used in the cases where no other scenario is defined.
    /// </summary>
    value(0; Default)
    {
        Caption = 'Default';
    }
}