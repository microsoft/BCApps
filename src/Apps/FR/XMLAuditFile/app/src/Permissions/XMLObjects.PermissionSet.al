// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

permissionset 10807 "XML - Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = codeunit "Data Check XML" = X,
                  codeunit "Data Handling XML" = X,
                  codeunit "Generate File XML" = X,
                  codeunit "Install XML" = X,
                  codeunit "Page Visibility XML" = X,
                  xmlport "Export G/L Entries FR" = X;
}
