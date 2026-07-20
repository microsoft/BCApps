// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.Purchases.Vendor;

tableextension 28009 "PINT A-NZ Sample Ext" extends Vendor
{
    fields
    {
        field(28008; "PINT ANZ Sample Note"; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }
}
