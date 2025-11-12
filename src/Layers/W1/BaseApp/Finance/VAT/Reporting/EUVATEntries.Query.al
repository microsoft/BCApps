// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;

query 141 "EU VAT Entries"
{
    Caption = 'EU VAT Entries';

    elements
    {
        dataitem(VAT_Entry; "VAT Entry")
        {
            DataItemTableFilter = Type = const(Sale);
            column(Base; Base)
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(VATReportingDate; "VAT Reporting Date")
            {
            }
            column(DocumentDate; "Document Date")
            {
            }
            column(Type; Type)
            {
            }
            column(EU_3_Party_Trade; "EU 3-Party Trade")
            {
            }
            column(VAT_Registration_No; "VAT Registration No.")
            {
            }
            column(EU_Service; "EU Service")
            {
            }
            column(Entry_No; "Entry No.")
            {
            }
            dataitem(Country_Region; "Country/Region")
            {
                DataItemLink = Code = VAT_Entry."Country/Region Code";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = "EU Country/Region Code" = filter(<> '');
                column(Name; Name)
                {
                }
                column(EU_Country_Region_Code; "EU Country/Region Code")
                {
                }
                column(CountryCode; "Code")
                {
                }
            }
        }
    }
}

