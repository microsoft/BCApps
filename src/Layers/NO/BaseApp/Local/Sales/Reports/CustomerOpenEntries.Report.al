// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 10616 "Customer - Open Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerOpenEntries.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Open Entries';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CustDateFilter; StrSubstNo('Period: %1', CustDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustomerTableName; Customer.TableName + ': ' + CustFilter)
            {
            }
            column(OutputNo; OutputNo)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(PrintOnlyOnePerPageInt; PrintOnlyOnePerPageInt)
            {
            }
            column(No_Cust; "No.")
            {
            }
            column(Name_Cust; Name)
            {
            }
            column(PhoneNo_Cust; "Phone No.")
            {
            }
            column(RemainingAmtLCY_CustLedgEntry; "Cust. Ledger Entry"."Remaining Amt. (LCY)")
            {
            }
            column(AmtLCY_CustLedgEntry; "Cust. Ledger Entry"."Amount (LCY)")
            {
            }
            column(CustOpenEntriesCaption; CustOpenEntriesCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocTypeCaption; DocTypeCaptionLbl)
            {
            }
            column(DocNoCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(DescCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(EntryNoCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(RemainingAmtCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(RemainingAmtLCYCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(AmtLCYCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption("Amount (LCY)"))
            {
            }
            column(AmtCaption_CustLedgEntry; "Cust. Ledger Entry".FieldCaption(Amount))
            {
            }
            column(PhoneNoCaption_Cust; FieldCaption("Phone No."))
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(DateFilter_Cust; "Date Filter")
            {
            }
            column(GlobalDim2Filter_Cust; "Global Dimension 2 Filter")
            {
            }
            column(GlobalDim1Filter_Cust; "Global Dimension 1 Filter")
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                DataItemTableView = sorting("Customer No.", "Posting Date");
                column(AmountLCY_CustLedgEntry; "Amount (LCY)")
                {
                }
                column(RemainingAmountLCY_CustLedgEntry; "Remaining Amt. (LCY)")
                {
                }
                column(Name_Customer; Customer.Name)
                {
                }
                column(PostingDate_CustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocType_CustLedgEntry; "Document Type")
                {
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                }
                column(Desc_CustLedgEntry; Description)
                {
                }
                column(CustEntryDueDate; Format(CustEntryDueDate))
                {
                }
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                }
                column(CurrCode_CustLedgEntry; "Currency Code")
                {
                }
                column(RemainingAmt_CustLedgEntry; "Remaining Amount")
                {
                }
                column(Amt_CustLedgEntry; Amount)
                {
                }
                column(PostingDate_CustLedgerEntry; "Posting Date")
                {
                }
                column(GlobalDim2Code_CustLedgerEntry; "Global Dimension 2 Code")
                {
                }
                column(GlobalDim1Code_CustLedgerEntry; "Global Dimension 1 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Document Type" = "Document Type"::Payment then
                        CustEntryDueDate := 0D
                    else
                        CustEntryDueDate := "Due Date";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Open, true);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // if the checkbox in options is check on then add OutputNo and change the value of PrintOnlyOnePerPageInt to 2
                if PrintOnlyOnePerPage then begin
                    OutputNo := OutputNo + 1;
                    PrintOnlyOnePerPageInt := 2;
                end;
            end;

            trigger OnPreDataItem()
            begin
                OutputNo := 1;
                PrintOnlyOnePerPageInt := 1;
                // to see whether the checkbox in options is check on
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if you want to print a new page for each customer ledger entry.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CustFilter := Customer.GetFilters();
        CustDateFilter := Customer.GetFilter("Date Filter");
    end;

    var
        PrintOnlyOnePerPage: Boolean;
        CustFilter: Text[250];
        CustDateFilter: Text[30];
        CustEntryDueDate: Date;
        OutputNo: Integer;
        PrintOnlyOnePerPageInt: Integer;
        CustOpenEntriesCaptionLbl: Label 'Customer - Open Entries';
        PageCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocTypeCaptionLbl: Label 'D T';
        DueDateCaptionLbl: Label 'Due Date';
        CurrCodeCaptionLbl: Label 'Curre Code';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
}

