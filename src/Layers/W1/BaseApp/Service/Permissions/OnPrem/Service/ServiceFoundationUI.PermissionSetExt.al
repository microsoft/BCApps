// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Maintenance;

permissionsetextension 6466 "Service Foundation UI" extends "Foundation UI"
{
    Permissions =
                tabledata "Serv. Price Group Setup" = Rim,
                tabledata "Service Mgt. Setup" = Rim,
                tabledata "Service Status Priority Setup" = Rim,
                tabledata "Troubleshooting Setup" = Rim;
}
