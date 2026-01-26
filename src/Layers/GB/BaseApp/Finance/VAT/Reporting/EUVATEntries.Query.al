// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;

/// <summary>
/// Data query for extracting VAT entry information for European Union sales reporting.
/// Filters VAT entries by sale type and provides access to base amounts, VAT amounts, and country information.
/// </summary>
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
#if not CLEAN27
                dataitem(ECSL_VAT_Report_Line_Relation; "ECSL VAT Report Line Relation")
                {
                    DataItemLink = "VAT Entry No." = VAT_Entry."Entry No.";
                    SqlJoinType = LeftOuterJoin;
                    column(VAT_Entry_No; "VAT Entry No.")
                    {
                    }
                    column(ECSL_Line_No; "ECSL Line No.")
                    {
                    }
                    column(ECSL_Report_No; "ECSL Report No.")
                    {
                    }
                    dataitem(ECSL_VAT_Report_Line; "ECSL VAT Report Line")
                    {
                        DataItemLink = "Line No." = ECSL_VAT_Report_Line_Relation."ECSL Line No.", "Report No." = ECSL_VAT_Report_Line_Relation."ECSL Report No.";
                        SqlJoinType = LeftOuterJoin;
                        column(Line_Status; "Line Status")
                        {
                        }
                        column(XML_Part_Id; "XML Part Id")
                        {
                        }
                        column(Line_No; "Line No.")
                        {
                        }
                        column(Report_No; "Report No.")
                        {
                        }
                    }
                }
#endif
            }
        }
    }
}

