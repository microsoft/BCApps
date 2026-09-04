// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

#pragma warning disable AL0659 // Accepted: renaming the enum is a breaking change
enum 10756 "SII Doc. Upload State Document Type"
#pragma warning restore AL0659
{
    Extensible = true;

    value(1; Payment)
    {
        Caption = 'Payment';
    }
    value(2; Invoice)
    {
        Caption = 'Invoice';
    }
    value(3; "Credit Memo")
    {
        Caption = 'Credit Memo';
    }
    value(6; Refund)
    {
        Caption = 'Refund';
    }	
}
