// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Enum extension to register the SFTP connector.
/// </summary>
enumextension 4621 "Ext. SFTP Connector" extends "Ext. File Storage Connector"
{
    /// <summary>
    /// The SFTP connector.
    /// </summary>
    value(4621; "SFTP")
    {
        Caption = 'SFTP';
        Implementation = "External File Storage Connector" = "Ext. SFTP Connector Impl";
    }
}