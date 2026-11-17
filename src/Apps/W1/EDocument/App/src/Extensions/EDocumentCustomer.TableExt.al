// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.Extensions;

using Microsoft.Sales.Customer;

tableextension 6174 "E-Document Customer" extends Customer
{
    fields
    {
        field(6101; "Use Reg. No. in E-Document"; Boolean)
        {
            Caption = 'Use Registration No. in Electronic Document';
            DataClassification = CustomerContent;
        }
    }
}
