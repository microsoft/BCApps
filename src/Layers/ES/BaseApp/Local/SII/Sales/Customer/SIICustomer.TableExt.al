// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Customer;

#pragma warning disable AS0088
tableextension 10728 "SII Customer" extends Customer
{
    fields
    {
        field(10702; "Not in AEAT"; Boolean)
        {
            Caption = 'Not in AEAT';
            DataClassification = CustomerContent;
        }
    }
}
