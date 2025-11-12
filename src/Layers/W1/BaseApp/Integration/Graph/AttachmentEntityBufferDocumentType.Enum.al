// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

#pragma warning disable AL0659
enum 135 "Attachment Entity Buffer Document Type"
#pragma warning restore AL0659
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; "Journal") { Caption = 'Journal'; }
    value(2; "Sales Order") { Caption = 'Sales Order'; }
    value(3; "Sales Quote") { Caption = 'Sales Quote'; }
    value(4; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(5; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(6; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(7; "Purchase Order") { Caption = 'Purchase Order'; }
    value(9; "Employee") { Caption = 'Employee'; }
    value(10; "Job") { Caption = 'Project'; }
    value(11; "Item") { Caption = 'Item'; }
    value(12; "Customer") { Caption = 'Customer'; }
    value(13; "Vendor") { Caption = 'Vendor'; }
    value(14; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(15; "Customer Statement") { Caption = 'Customer Statement'; }
}