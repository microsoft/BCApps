// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Specifies how to interpret the configured base folder for SharePoint REST accounts.
/// </summary>
enum 4580 "Ext. SharePoint Path Format"
{
    Extensible = false;

    value(0; URL)
    {
        Caption = 'URL';
    }
    value(1; "Decoded Path")
    {
        Caption = 'Decoded Path';
    }
}
