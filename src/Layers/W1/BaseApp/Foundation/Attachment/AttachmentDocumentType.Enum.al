// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

enum 1173 "Attachment Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote")
    {
        Caption = 'Quote';
    }
    value(1; "Order")
    {
        Caption = 'Order';
    }
    value(2; "Invoice")
    {
        Caption = 'Invoice';
    }
    value(3; "Credit Memo")
    {
        Caption = 'Credit Memo';
    }
    value(4; "Blanket Order")
    {
        Caption = 'Blanket Order';
    }
    value(5; "Return Order")
    {
        Caption = 'Return Order';
    }
    value(6; "VAT Return Submission")
    {
        Caption = 'VAT Return Submission';
    }
    value(7; "VAT Return Response")
    {
        Caption = 'VAT Return Response';
    }
    value(20; "Service Contract Quote")
    {
        Caption = 'Service Contract Quote';
    }
    value(21; "Service Contract")
    {
        Caption = 'Service Contract';
    }
}
