// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Document;

tableextension 5005280 DRVendor extends Vendor
{
    fields
    {
        field(5005270; "Delivery Reminder Terms"; Code[10])
        {
            Caption = 'Delivery Reminder Terms';
            TableRelation = "Delivery Reminder Term";
            DataClassification = CustomerContent;
        }
    }
}
