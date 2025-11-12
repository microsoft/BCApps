// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;

query 410 "Analysis View Source"
{
    Caption = 'Analysis View Source';

    elements
    {
        dataitem(Analysis_View; "Analysis View")
        {
            filter(AnalysisViewCode; "Code")
            {
            }
            dataitem(G_L_Entry; "G/L Entry")
            {
                SqlJoinType = CrossJoin;
                filter(EntryNo; "Entry No.")
                {
                }
                column(GLAccNo; "G/L Account No.")
                {
                }
                column(BusinessUnitCode; "Business Unit Code")
                {
                }
                column(PostingDate; "Posting Date")
                {
                }
                column(DimensionSetID; "Dimension Set ID")
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
                column(AmountACY; "Additional-Currency Amount")
                {
                    Method = Sum;
                }
                column(DebitAmountACY; "Add.-Currency Debit Amount")
                {
                    Method = Sum;
                }
                column(CreditAmountACY; "Add.-Currency Credit Amount")
                {
                    Method = Sum;
                }
                dataitem(DimSet1; "Dimension Set Entry")
                {
                    DataItemLink = "Dimension Set ID" = G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 1 Code";
                    column(DimVal1; "Dimension Value Code")
                    {
                    }
                    dataitem(DimSet2; "Dimension Set Entry")
                    {
                        DataItemLink = "Dimension Set ID" = G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 2 Code";
                        column(DimVal2; "Dimension Value Code")
                        {
                        }
                        dataitem(DimSet3; "Dimension Set Entry")
                        {
                            DataItemLink = "Dimension Set ID" = G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 3 Code";
                            column(DimVal3; "Dimension Value Code")
                            {
                            }
                            dataitem(DimSet4; "Dimension Set Entry")
                            {
                                DataItemLink = "Dimension Set ID" = G_L_Entry."Dimension Set ID", "Dimension Code" = Analysis_View."Dimension 4 Code";
                                column(DimVal4; "Dimension Value Code")
                                {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

