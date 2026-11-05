// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Ledger;

query 10672 "SAF-T G/L Entry Total"
{
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(GLEntry; "G/L Entry")
        {
            filter(PostingDate; "Posting Date")
            {
            }
            filter(SourceCode; "Source Code")
            {
            }
            filter(AmountFilter; Amount)
            {
            }
            column(TotalAmount; Amount)
            {
                Method = Sum;
            }
        }
    }
}
