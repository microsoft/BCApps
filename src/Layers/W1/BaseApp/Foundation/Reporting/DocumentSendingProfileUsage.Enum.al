// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

enum 62 "Document Sending Profile Usage"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(1; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(3; "Service Invoice") { Caption = 'Service Invoice'; }
    value(4; "Service Credit Memo") { Caption = 'Service Credit Memo'; }
    value(5; "Job Quote") { Caption = 'Project Quote'; }
}
