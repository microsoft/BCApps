// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Specifies the authentication types for SFTP accounts.
/// </summary>
enum 4621 "Ext. SFTP Auth Type"
{
    Extensible = false;
    Access = Public;
    ObsoleteReason = 'The SFTP connector is deprecated because platform hardening will prevent support for SFTP connections.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    /// <summary>
    /// Authenticate using password.
    /// </summary>
    value(0; Password)
    {
        Caption = 'Password';
    }

    /// <summary>
    /// Authenticate using private key.
    /// </summary>
    value(1; Certificate)
    {
        Caption = 'Certificate';
    }
}
