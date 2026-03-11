// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

/// <summary>
/// Indicator of what type the resource is.
/// </summary>
enum 9452 "Ext. File Storage File Type"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Indicates if entry is a directory.
    /// </summary>
    value(0; Directory)
    {
        Caption = 'Directory';
    }

    /// <summary>
    /// Indicates if entry is a file type.
    /// </summary>
    value(1; File)
    {
        Caption = 'File';
    }
}