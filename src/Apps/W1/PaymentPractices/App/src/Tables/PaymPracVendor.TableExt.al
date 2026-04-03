// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Vendor;

tableextension 680 "Paym. Prac. Vendor" extends Vendor
{
    fields
    {
        field(680; "Small Business Supplier"; Boolean)
        {
            Caption = 'Small Business Supplier';
            ToolTip = 'Specifies whether this vendor is classified as a small business supplier for payment practice reporting purposes.';
            DataClassification = CustomerContent;
        }
    }
}
