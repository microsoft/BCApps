// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

query 9059 "Service Header Doc. Type Count"
{
    elements
    {
        dataitem(Service_Header; "Service Header")
        {
            filter(Customer_No; "Customer No.")
            {
            }

            filter(Bill_to_Customer_No; "Bill-to Customer No.")
            {
            }

            column(Document_Type; "Document Type")
            {
            }

            column(DocTypeCount)
            {
                Method = Count;
            }
        }
    }
}
