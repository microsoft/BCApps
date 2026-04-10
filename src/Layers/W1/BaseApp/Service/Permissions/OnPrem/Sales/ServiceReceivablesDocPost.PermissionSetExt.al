// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using Microsoft.Service.Document;
using Microsoft.Service.Setup;

permissionsetextension 2529 "Service Receivables Doc.- Post" extends "Recievables Documents - Post"
{
    Permissions =
                  tabledata "Service Document Register" = Rd,
                  tabledata "Service Mgt. Setup" = R;
}