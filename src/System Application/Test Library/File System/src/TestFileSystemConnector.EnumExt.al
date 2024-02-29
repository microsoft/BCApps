// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.FileSystem;

using System.FileSystem;

enumextension 80201 "Test File System Connector" extends "File System Connector"
{
    value(80200; "Test File System Connector")
    {
        Implementation = "File System Connector" = "Test File System Connector";
    }
}