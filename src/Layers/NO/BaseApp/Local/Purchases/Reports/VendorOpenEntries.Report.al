// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 10617 "Vendor - Open Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorOpenEntries.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Open Entries';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Date Filter";
            column(PeriodVendorDateFilter; StrSubstNo('Period: %1', VendorDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendorVendorFilter; Vendor.TableName + ': ' + VendorFilter)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
            }
            column(VATRegistrationNo_Vendor; "VAT Registration No.")
            {
            }
            column(VendorLedgerEntryRemainingAmtLCY; "Vendor Ledger Entry"."Remaining Amt. (LCY)")
            {
            }
            column(VendorLedgerEntryAmountLCY; "Vendor Ledger Entry"."Amount (LCY)")
            {
            }
            column(VendorFilter; VendorFilter)
            {
            }
            column(OutputNo; outputno)
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(VendorOpenEntriesCaption; VendorOpenEntriesCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(VendorLedgerEntryDocumentNoCaption; DocNoCaption)
            {
            }
            column(VendorLedgerEntryDescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(VendorLedgerEntryEntryNoCaption; "Vendor Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
            {
            }
            column(VendorLedgerEntryRemainingAmountCaption; "Vendor Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(VendorLedgerEntryRemainingAmtLCYCaption; "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(VendorLedgerEntryAmountLCYCaption; "Vendor Ledger Entry".FieldCaption("Amount (LCY)"))
            {
            }
            column(VendorLedgerEntryAmountCaption; "Vendor Ledger Entry".FieldCaption(Amount))
            {
            }
            column(PhoneNoCaption_Vendor; FieldCaption("Phone No."))
            {
            }
            column(VATRegistrationNoCaption_Vendor; FieldCaption("VAT Registration No."))
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(GlobalDimension2Filter_Vendor; "Global Dimension 2 Filter")
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                DataItemTableView = sorting("Vendor No.", "Posting Date");
                column(AmountLCY_VendorLedgerEntry; "Amount (LCY)")
                {
                }
                column(RemainingAmtLCY_VendorLedgerEntry; "Remaining Amt. (LCY)")
                {
                }
                column(VendorName; Vendor.Name)
                {
                }
                column(FormattedPostingDate_VendorLedgerEntry; Format("Posting Date"))
                {
                }
                column(DocumentType_VendorLedgerEntry; "Document Type")
                {
                }
                column(DocumentNo_VendorLedgerEntry; "Document No.")
                {
                }
                column(Description_VendorLedgerEntry; Description)
                {
                }
                column(VendorEntryDueDate; Format(VendorEntryDueDate))
                {
                }
                column(EntryNo_VendorLedgerEntry; "Entry No.")
                {
                }
                column(CurrencyCode_VendorLedgerEntry; "Currency Code")
                {
                }
                column(RemainingAmount_VendorLedgerEntry; "Remaining Amount")
                {
                }
                column(Amount_VendorLedgerEntry; Amount)
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(PostingDate_VendorLedgerEntry; "Posting Date")
                {
                }
                column(GlobalDimension1Code_VendorLedgerEntry; "Global Dimension 1 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Document Type" = "Document Type"::Payment then
                        VendorEntryDueDate := 0D
                    else
                        VendorEntryDueDate := "Due Date";

                    if UseExternalDocNo then
                        "Document No." := CopyStr("External Document No.", 1, MaxStrLen("Document No."));
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Open, true);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPage then
                    outputno := outputno + 1;
            end;

            trigger OnPreDataItem()
            begin
                outputno := 1;
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
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if you want to print a new page for each vendor ledger entry.';
                    }
                    field(UseExternalDocNo; UseExternalDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Document No.';
                        ToolTip = 'Specifies if you want to print the vendor''s document numbers, such as the invoice number, for all transactions. Clear this check box to print only internal document numbers.';
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
        VendorFilter := Vendor.GetFilters();
        VendorDateFilter := Vendor.GetFilter("Date Filter");

        if UseExternalDocNo then
            DocNoCaption := "Vendor Ledger Entry".FieldCaption("External Document No.")
        else
            DocNoCaption := "Vendor Ledger Entry".FieldCaption("Document No.");
    end;

    var
        PrintOnlyOnePerPage: Boolean;
        VendorFilter: Text[250];
        VendorDateFilter: Text[30];
        VendorEntryDueDate: Date;
        outputno: Integer;
        VendorOpenEntriesCaptionLbl: Label 'Vendor - Open Entries';
        PageCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentTypeCaptionLbl: Label 'D Ty';
        DueDateCaptionLbl: Label 'Due Date';
        CurrencyCodeCaptionLbl: Label 'Curre Code';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        ContinuedCaptionLbl: Label 'Continued';
        UseExternalDocNo: Boolean;
        DocNoCaption: Text;
}

