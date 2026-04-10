// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Foundation.Address;

/// <summary>
/// Query for aggregating VAT entry base amounts by country, VAT registration number, and EU service classification.
/// Provides summarized VAT base amounts for EU reporting and cross-border transaction analysis.
/// </summary>
/// <remarks>
/// Filtered to sales VAT entries with grouping by country/region and VAT registration. 
/// Supports EU country identification and 3-party trade analysis for compliance reporting.
/// </remarks>
query 19 "VAT Entries Base Amt. Sum"
{
    Caption = 'VAT Entries Base Amt. Sum';
    OrderBy = ascending(Country_Region_Code), ascending(VAT_Registration_No);

    elements
    {
        dataitem(VAT_Entry; "VAT Entry")
        {
            DataItemTableFilter = Type = const(Sale);
            filter(Posting_Date; "Posting Date")
            {
            }
            filter(VAT_Date; "VAT Reporting Date")
            {
            }
            filter(Document_Date; "Document Date")
            {
            }
            column(VAT_Registration_No; "VAT Registration No.")
            {
            }
            column(EU_3_Party_Trade; "EU 3-Party Trade")
            {
            }
            column(EU_Service; "EU Service")
            {
            }
            column(Country_Region_Code; "Country/Region Code")
            {
            }
            column(Sum_Base; Base)
            {
                Method = Sum;
            }
            column(Sum_Additional_Currency_Base; "Additional-Currency Base")
            {
                Method = Sum;
            }
            column(Bill_to_Pay_to_No; "Bill-to/Pay-to No.")
            {
            }
            dataitem(Country_Region; "Country/Region")
            {
                DataItemLink = Code = VAT_Entry."Country/Region Code";
                column(EU_Country_Region_Code; "EU Country/Region Code")
                {
                    ColumnFilter = EU_Country_Region_Code = filter(<> '');
                }
            }
        }
    }
}

