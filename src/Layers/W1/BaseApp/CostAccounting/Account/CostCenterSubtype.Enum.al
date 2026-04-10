// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

enum 1114 "Cost Center Subtype"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Service Cost Center") { Caption = 'Service Cost Center'; }
    value(2; "Aux. Cost Center") { Caption = 'Aux. Cost Center'; }
    value(3; "Main Cost Center") { Caption = 'Main Cost Center'; }
}
