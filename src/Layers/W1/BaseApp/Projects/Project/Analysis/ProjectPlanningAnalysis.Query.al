// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;

query 487 "Project Planning Analysis"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Project Planning Analysis';
    AboutTitle = 'About Project Planning Analysis';
    AboutText = 'The Project Planning Analysis is a query that joins data from project planning lines with project master data.';

    elements
    {
        dataitem(JobPlanLine; "Job Planning Line")
        {
            column(JobNo; "Job No.")
            {
                Caption = 'Job No.';
            }
            column(JobTaskNo; "Job Task No.")
            {
                Caption = 'Job Task No.';
            }
            column(LineNo; "Line No.")
            {
                Caption = 'Line No.';
            }
            column(LineType; "Line Type")
            {
                Caption = 'Line Type';
            }
            column(PlanningDate; "Planning Date")
            {
                Caption = 'Planning Date';
            }
            column(JobPlanLineDocumentNo; "Document No.")
            {
                Caption = 'Job Planning Line Document No.';
            }
            column(Type; Type)
            {
                Caption = 'Type';
            }
            column(TypeNo; "No.")
            {
                Caption = 'Type No.';
            }
            column(WorkTypeCode; "Work Type Code")
            {
                Caption = 'Work Type Code';
            }
            column(Quantity; Quantity)
            {
                Caption = 'Quantity';
            }
            column(UnitOfMeasureCode; "Unit of Measure Code")
            {
                Caption = 'Unit of Measure Code';
            }
            column(UnitCost; "Unit Cost")
            {
                Caption = 'Unit Cost';
            }
            column(TotalCost; "Total Cost")
            {
                Caption = 'Total Cost';
            }
            column(UnitPrice; "Unit Price")
            {
                Caption = 'Unit Price';
            }
            column(TotalPrice; "Total Price")
            {
                Caption = 'Total Price';
            }
            column(LineDiscountAmount; "Line Discount Amount")
            {
                Caption = 'Line Discount Amount';
            }
            column(LineAmount; "Line Amount")
            {
                Caption = 'Line Amount';
            }
            column(TotalCostLCY; "Total Cost (LCY)")
            {
                Caption = 'Total Cost (LCY)';
            }
            column(UnitPriceLCY; "Unit Price (LCY)")
            {
                Caption = 'Unit Price (LCY)';
            }
            column(TotalPriceLCY; "Total Price (LCY)")
            {
                Caption = 'Total Price (LCY)';
            }
            column(LineDiscountAmountLCY; "Line Discount Amount (LCY)")
            {
                Caption = 'Line Discount Amount (LCY)';
            }
            column(LineAmountLCY; "Line Amount (LCY)")
            {
                Caption = 'Line Amount (LCY)';
            }
            dataitem(Job; Job)
            {
                DataItemLink = "No." = JobPlanLine."Job No.";
                SqlJoinType = InnerJoin;
                column(JobDesc; Description)
                {
                    Caption = 'Job Description';
                }
                column(BillToCustNo; "Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
                column(BillToName; "Bill-to Name")
                {
                    Caption = 'Bill-to Name';
                }
                column(BillToCountry; "Bill-to County")
                {
                    Caption = 'Bill-to Country';
                }
                column(BillToCountryRegionCode; "Bill-to Country/Region Code")
                {
                    Caption = 'Bill-to Country/Region Code';
                }
                column(StartingDate; "Starting Date")
                {
                    Caption = 'Starting Date';
                }
                column(EndingDate; "Ending Date")
                {
                    Caption = 'Ending Date';
                }
                column(Status; Status)
                {
                    Caption = 'Status';
                }
                column(PersonResponsible; "Person Responsible")
                {
                    Caption = 'Person Responsible';
                }
                column(GlobalDim1Code; "Global Dimension 1 Code")
                {
                    Caption = 'Global Dimension 1 Code';
                }
                column(GlobalDim2Code; "Global Dimension 2 Code")
                {
                    Caption = 'Global Dimension 2 Code';
                }
                column(JobPostingGroup; "Job Posting Group")
                {
                    Caption = 'Job Posting Group';
                }
                column(CustDiscGroup; "Customer Disc. Group")
                {
                    Caption = 'Customer Discount Group';
                }
                column(CustPriceGroup; "Customer Price Group")
                {
                    Caption = 'Customer Price Group';
                }
                column(LocationCode; "Location Code")
                {
                    Caption = 'Location Code';
                }
                column(BinCode; "Bin Code")
                {
                    Caption = 'Bin Code';
                }
                column(JobWIPMethod; "WIP Method")
                {
                    Caption = 'Job WIP Method';
                }
                column(BillToContactNo; "Bill-to Contact No.")
                {
                    Caption = 'Bill-to Contact No.';
                }
                column(BillToContact; "Bill-to Contact")
                {
                    Caption = 'Bill-to Contact';
                }
                column(ExDocNo; "External Document No.")
                {
                    Caption = 'External Document No.';
                }
                dataitem(JobTask; "Job Task")
                {
                    DataItemLink = "Job No." = JobPlanLine."Job No.", "Job Task No." = JobPlanLine."Job Task No.";
                    SqlJoinType = LeftOuterJoin;
                    column(JobTaskDesc; Description)
                    {
                        Caption = 'Job Task Description';
                    }
                    column(JobTaskType; "Job Task Type")
                    {
                        Caption = 'Job Task Type';
                    }
                    column(WIPTotal; "WIP-Total")
                    {
                        Caption = 'WIP-Total';
                    }
                    column(JobTaskPostingGroup; "Job Posting Group")
                    {
                        Caption = 'Job Posting Group';
                    }
                    column(JobTaskWIPMethod; "WIP Method")
                    {
                        Caption = 'Job Task WIP Method';
                    }
                    dataitem(JobPlanLineInv; "Job Planning Line Invoice")
                    {
                        DataItemLink = "Job No." = JobPlanLine."Job No.", "Job Task No." = JobPlanLine."Job Task No.", "Job Planning Line No." = JobPlanLine."Line No.";
                        SqlJoinType = FullOuterJoin;
                        column(DocumentType; "Document Type")
                        {
                            Caption = 'Invoice Document Type';
                        }
                        column(JobPlanLineInvDocNo; "Document No.")
                        {
                            Caption = 'Invoice Document No.';
                        }
                        column(QuantityTransferred; "Quantity Transferred")
                        {
                            Caption = 'Qty. Transferred';
                        }
                        column(InvoicedDate; "Invoiced Date")
                        {
                            Caption = 'Invoiced Date';
                        }
                        column(InvAmountLCY; "Invoiced Amount (LCY)")
                        {
                            Caption = 'Invoiced Amount (LCY)';
                        }
                        column(InvCostAmtLCY; "Invoiced Cost Amount (LCY)")
                        {
                            Caption = 'Invoiced Cost Amount (LCY)';
                        }
                        dataitem(Item; Item)
                        {
                            DataItemLink = "No." = JobPlanLine."No.";
                            SqlJoinType = LeftOuterJoin;
                            column(ItemDescription; Description)
                            {
                                Caption = 'Item Description';
                            }
                            column(ItemCategoryCode; "Item Category Code")
                            {
                                Caption = 'Item Category Code';
                            }
                            dataitem(Resource; Resource)
                            {
                                DataItemLink = "No." = JobPlanLine."No.";
                                SqlJoinType = LeftOuterJoin;
                                column(ResourceName; Name)
                                {
                                    Caption = 'Resource Name';
                                }
                                column(ResourceGroupNo; "Resource Group No.")
                                {
                                    Caption = 'Resource Group No.';
                                }
                                dataitem(GLAccount; "G/L Account")
                                {
                                    DataItemLink = "No." = JobPlanLine."No.";
                                    SqlJoinType = LeftOuterJoin;
                                    column(GLAccName; Name)
                                    {
                                        Caption = 'G/L Account Name';
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}