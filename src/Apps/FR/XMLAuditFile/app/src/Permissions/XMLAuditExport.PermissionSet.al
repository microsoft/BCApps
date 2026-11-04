// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Ledger;

permissionset 10808 "XML Audit - Export"
{
    Caption = 'XML Audit - Export', MaxLength = 30;
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "XML - Objects",
                             "Audit Export - Edit";

    Permissions = tabledata Contact = r,
                  tabledata "G/L Entry" = r,
                  table "G/L Entry" = X;
}
