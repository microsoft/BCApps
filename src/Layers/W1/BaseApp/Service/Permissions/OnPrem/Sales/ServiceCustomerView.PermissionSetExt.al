// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Document;

permissionsetextension 6474 "Service Customer - View" extends "Customer - View"
{
    Permissions = tabledata "Service Line" = r;
}
