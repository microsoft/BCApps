// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.EServices.EDocument;

permissionsetextension 1001 "SII LOCAL" extends "LOCAL"
{
    Permissions =
                  tabledata "SII Doc. Upload State" = RIMD,
                  tabledata "SII History" = RIMD,
                  tabledata "SII Purch. Doc. Scheme Code" = RIMD,
                  tabledata "SII Sales Document Scheme Code" = RIMD,
                  tabledata "SII Missing Entries State" = RIMD,
                  tabledata "SII Session" = RIMD,
                  tabledata "SII Setup" = RIMD,
                  tabledata "SII Sending State" = RIMD;
}