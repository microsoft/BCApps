// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Ledger;

query 7150 "Item Analysis View Source"
{
    Caption = 'Item Analysis View Source';

    elements
    {
        dataitem(ItemAnalysisView; "Item Analysis View")
        {
            filter(AnalysisArea; "Analysis Area")
            {
            }
            filter(AnalysisViewCode; "Code")
            {
            }
            dataitem(ValueEntry; "Value Entry")
            {
                SqlJoinType = CrossJoin;
                filter(EntryNo; "Entry No.")
                {
                }
                column(ItemNo; "Item No.")
                {
                }
                column(SourceType; "Source Type")
                {
                }
                column(SourceNo; "Source No.")
                {
                }
                column(EntryType; "Entry Type")
                {
                }
                column(ItemLedgerEntryType; "Item Ledger Entry Type")
                {
                }
                column(ItemLedgerEntryNo; "Item Ledger Entry No.")
                {
                }
                column(ItemChargeNo; "Item Charge No.")
                {
                }
                column(LocationCode; "Location Code")
                {
                }
                column(PostingDate; "Posting Date")
                {
                }
                column(DimensionSetID; "Dimension Set ID")
                {
                }
                column(ILEQuantity; "Item Ledger Entry Quantity")
                {
                    Method = Sum;
                }
                column(InvoicedQuantity; "Invoiced Quantity")
                {
                    Method = Sum;
                }
                column(SalesAmountActual; "Sales Amount (Actual)")
                {
                    Method = Sum;
                }
                column(SalesAmountExpected; "Sales Amount (Expected)")
                {
                    Method = Sum;
                }
                column(CostAmountActual; "Cost Amount (Actual)")
                {
                    Method = Sum;
                }
                column(CostAmountNonInvtbl; "Cost Amount (Non-Invtbl.)")
                {
                    Method = Sum;
                }
                column(CostAmountExpected; "Cost Amount (Expected)")
                {
                    Method = Sum;
                }
                dataitem(DimSet1; "Dimension Set Entry")
                {
                    DataItemLink = "Dimension Set ID" = ValueEntry."Dimension Set ID", "Dimension Code" = ItemAnalysisView."Dimension 1 Code";
                    column(DimVal1; "Dimension Value Code")
                    {
                    }
                    dataitem(DimSet2; "Dimension Set Entry")
                    {
                        DataItemLink = "Dimension Set ID" = ValueEntry."Dimension Set ID", "Dimension Code" = ItemAnalysisView."Dimension 2 Code";
                        column(DimVal2; "Dimension Value Code")
                        {
                        }
                        dataitem(DimSet3; "Dimension Set Entry")
                        {
                            DataItemLink = "Dimension Set ID" = ValueEntry."Dimension Set ID", "Dimension Code" = ItemAnalysisView."Dimension 3 Code";
                            column(DimVal3; "Dimension Value Code")
                            {
                            }
                        }
                    }
                }
            }
        }
    }
}

