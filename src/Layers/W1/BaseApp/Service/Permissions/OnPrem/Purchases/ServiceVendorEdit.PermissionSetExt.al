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

permissionsetextension 6470 "Service Vendor - Edit" extends "Vendor - Edit"
{
    Permissions =
                  tabledata "Contract Gain/Loss Entry" = rm,
                  tabledata "Filed Service Contract Header" = rm,
                  tabledata "Filed Contract Line" = rm,
                  tabledata "Service Contract Header" = Rm,
                  tabledata "Service Contract Line" = Rm,
                  tabledata "Service Header" = Rm,
                  tabledata "Service Header Archive" = Rm,
                  tabledata "Service Invoice Line" = Rm,
                  tabledata "Service Item" = Rm,
                  tabledata "Service Item Line" = Rm,
                  tabledata "Service Item Line Archive" = Rm,
                  tabledata "Service Ledger Entry" = rm,
                  tabledata "Warranty Ledger Entry" = rm;
}