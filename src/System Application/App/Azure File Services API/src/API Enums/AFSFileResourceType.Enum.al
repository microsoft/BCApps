// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

/// <summary>
/// Indicator of what type the resource is.
/// </summary>
enum 8954 "AFS File Resource Type"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    ///  Indicates entry is of file type.
    /// </summary>
    value(0; File)
    {
        Caption = 'File', Locked = true;
    }
    /// <summary>
    ///  Indicates entry is of directory type.
    /// </summary>
    value(1; Directory)
    {
        Caption = 'Directory', Locked = true;
    }
}