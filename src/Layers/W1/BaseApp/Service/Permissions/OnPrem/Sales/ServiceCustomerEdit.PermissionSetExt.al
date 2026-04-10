// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;

permissionsetextension 6473 "Service Customer - Edit" extends "Customer - Edit"
{
    Permissions =
                  tabledata "Contract Gain/Loss Entry" = rm,
                  tabledata "Filed Service Contract Header" = rm,
                  tabledata "Filed Contract Line" = rm,
                  tabledata "Service Contract Header" = Rm,
                  tabledata "Service Contract Line" = Rm,
                  tabledata "Service Header" = r,
                  tabledata "Service Header Archive" = r,
                  tabledata "Service Invoice Line" = Rm,
                  tabledata "Service Item" = Rm,
                  tabledata "Service Item Line" = Rm,
                  tabledata "Service Item Line Archive" = Rm,
                  tabledata "Service Ledger Entry" = rm,
                  tabledata "Service Line" = r,
                  tabledata "Service Line Archive" = r,
                  tabledata "Service Zone" = R,
                  tabledata "Warranty Ledger Entry" = rm;
}