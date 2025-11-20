// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

enum 6670 "Returns Related Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Order") { Caption = 'Sales Order'; }
    value(1; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(2; "Sales Return Order") { Caption = 'Sales Return Order'; }
    value(3; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(4; "Purchase Order") { Caption = 'Purchase Order'; }
    value(5; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(6; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    value(7; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
}
