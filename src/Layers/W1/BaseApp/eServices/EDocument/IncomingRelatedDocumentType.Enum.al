// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 141 "Incoming Related Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Journal") { Caption = 'Journal'; }
    value(1; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(2; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(3; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(4; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(5; " ") { Caption = ' '; }
    value(6; "Service Invoice") { Caption = 'Service Invoice'; }
    value(7; "Service Credit Memo") { Caption = 'Service Credit Memo'; }
}
