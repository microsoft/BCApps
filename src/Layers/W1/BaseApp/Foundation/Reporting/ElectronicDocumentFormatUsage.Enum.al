// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

#pragma warning disable AL0659
enum 61 "Electronic Document Format Usage"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(1; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(2; "Sales Validation") { Caption = 'Sales Validation'; }
    value(6; "Job Quote") { Caption = 'Project Quote'; }
    value(7; "Job Task Quote") { Caption = 'Project Task Quote'; }
}
