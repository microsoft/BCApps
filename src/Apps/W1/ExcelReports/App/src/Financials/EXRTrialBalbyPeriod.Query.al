// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

using Microsoft.Finance.GeneralLedger.Ledger;

query 4408 "EXR Trial Bal by Period"
{
    Access = Internal;
    DataAccessIntent = ReadOnly;
    QueryType = Normal;

    elements
    {
        dataitem(GLEntry; "G/L Entry")
        {
            filter(GLAccountNo; "G/L Account No.")
            {
            }
            filter(PostingDate; "Posting Date")
            {
            }
            filter(BusinessUnitCode; "Business Unit Code")
            {
            }
            filter(VATReportingDate; "VAT Reporting Date")
            {
            }
            filter(DimensionSetID; "Dimension Set ID")
            {
            }
            column(DimensionValue1Code; "Global Dimension 1 Code")
            {
            }
            column(DimensionValue2Code; "Global Dimension 2 Code")
            {
            }
            column(Amount; Amount)
            {
                Method = Sum;
            }
            column(DebitAmount; "Debit Amount")
            {
                Method = Sum;
            }
            column(CreditAmount; "Credit Amount")
            {
                Method = Sum;
            }
        }
    }
}
