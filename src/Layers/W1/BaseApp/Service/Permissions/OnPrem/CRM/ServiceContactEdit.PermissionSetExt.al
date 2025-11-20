// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Archive;

permissionsetextension 6471 "Service Contact - Edit" extends "Contact - Edit"
{
    Permissions =
                  tabledata "Service Contract Header" = rm,
                  tabledata "Service Header" = rm,
                  tabledata "Service Header Archive" = r;
}
