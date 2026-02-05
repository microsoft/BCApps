// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;

permissionset 20405 "QltyMngmnt - Edit"
{
    Caption = 'Quality Management - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Read";

    Permissions =
        tabledata "Qlty. Inspect. Creation Rule" = IMD,
        tabledata "Qlty. I. Result Condit. Conf." = IMD,
        tabledata "Qlty. Inspection Result" = IMD,
        tabledata "Qlty. Lookup Code" = IMD,
        tabledata "Qlty. Management Setup" = IMD,
        tabledata "Qlty. Related Transfers Buffer" = IMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = IMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = IMD,
        tabledata "Qlty. Inspect. Source Config." = IMD,
        tabledata "Qlty. Inspection Template Line" = IMD,
        tabledata "Qlty. Inspection Template Hdr." = IMD,
        tabledata "Qlty. Inspection Line" = IMD,
        tabledata "Qlty. Inspection Header" = IMD,
        tabledata "Qlty. Test" = IMD;
}
