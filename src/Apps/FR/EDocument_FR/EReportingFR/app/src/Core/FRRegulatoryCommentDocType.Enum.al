// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10973 "FR Reg. Comment Doc. Type"
{
    Extensible = false;

    value(0; Order)
    {
        Caption = 'Order';
    }
    value(1; Invoice)
    {
        Caption = 'Invoice';
    }
    value(2; "Credit Memo")
    {
        Caption = 'Credit Memo';
    }
    value(3; "Posted Invoice")
    {
        Caption = 'Posted Invoice';
    }
    value(4; "Posted Credit Memo")
    {
        Caption = 'Posted Credit Memo';
    }
}