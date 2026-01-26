// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

report 10610 "Customer - Collection List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerCollectionList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Collection List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Customer No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(No_IssuedReminderHeader; "No.")
            {
            }
            column(CustomerNo_IssuedReminderHeader; "Customer No.")
            {
            }
            column(CustomerPhoneNo; Customer."Phone No.")
            {
            }
            column(PostingDate_IssuedReminderHeader; Format("Posting Date"))
            {
            }
            column(IssuedReminderHeaderName; Name)
            {
            }
            column(ReminderTotal; ReminderTotal)
            {
            }
            column(CustomerCollectionListCaption; CustomerCollectionListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(IssuedReminderLineAmountCaption; "Issued Reminder Line".FieldCaption(Amount))
            {
            }
            column(IssuedReminderLineRemainingAmountCaption; "Issued Reminder Line".FieldCaption("Remaining Amount"))
            {
            }
            column(IssuedReminderLineDescriptionCaption; "Issued Reminder Line".FieldCaption(Description))
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(IssuedReminderLineDocumentNoCaption; "Issued Reminder Line".FieldCaption("Document No."))
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(IssuedReminderLineNoCaption; "Issued Reminder Line".FieldCaption("No."))
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(IssuedReminderLineOriginalAmountCaption; "Issued Reminder Line".FieldCaption("Original Amount"))
            {
            }
            column(OpenTextCaption; OpenTextCaptionLbl)
            {
            }
            column(NoOfRemindersCaption; NoOfRemindersCaptionLbl)
            {
            }
            column(NoCaption_IssuedReminderHeader; FieldCaption("No."))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(CustomerNoCaption_IssuedReminderHeader; FieldCaption("Customer No."))
            {
            }
            column(PhoneNoCaption; PhoneNoCaptionLbl)
            {
            }
            column(NameCaption_IssuedReminderHeader; FieldCaption(Name))
            {
            }
            column(ReminderTotalCaption; ReminderTotalCaptionLbl)
            {
            }
            dataitem(TestReminderLine; "Issued Reminder Line")
            {
                DataItemLink = "Reminder No." = field("No.");
                DataItemTableView = sorting("Reminder No.", "Line No.");
                RequestFilterFields = "No. of Reminders", Type;

                trigger OnAfterGetRecord()
                begin
                    if ("No. of Reminders" >= ReminderTerms."Max. No. of Reminders") and ("No. of Reminders" > 0) then begin
                        CollectionLines := true;
                        CurrReport.Break(); // A line is found. Stop the test
                    end;
                    CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowCollection then
                        CurrReport.Break();
                    CollectionLines := false;
                end;
            }
            dataitem("Issued Reminder Line"; "Issued Reminder Line")
            {
                DataItemLink = "Reminder No." = field("No.");
                DataItemTableView = sorting("Reminder No.", "Line No.");
                column(Type_IssuedReminderLine; Type)
                {
                }
                column(DueDate_IssuedReminderLine; Format("Due Date"))
                {
                }
                column(DocumentType_IssuedReminderLine; "Document Type")
                {
                }
                column(DocumentNo_IssuedReminderLine; "Document No.")
                {
                }
                column(Description_IssuedReminderLine; Description)
                {
                }
                column(RemainingAmount_IssuedReminderLine; "Remaining Amount")
                {
                }
                column(No_IssuedReminderLine; "No.")
                {
                }
                column(Amount_IssuedReminderLine; Amount)
                {
                }
                column(OriginalAmount_IssuedReminderLine; "Original Amount")
                {
                }
                column(OpenText; OpenText)
                {
                }
                column(NoOfReminders_IssuedReminderLine; "No. of Reminders")
                {
                }
                column(RemainingAmountAmount; "Remaining Amount" + Amount)
                {
                }
                column(TotalToCollectCaption; TotalToCollectCaptionLbl)
                {
                }
                column(LineNo_IssuedReminderLine; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Remaining Amount" = 0) and (Amount = 0) then
                        CurrReport.Skip();
                    if CustLedgerEntry.Get("Entry No.") then begin
                        if ShowCollection and ("Issued Reminder Line"."No. of Reminders" < ReminderTerms."Max. No. of Reminders") then
                            CurrReport.Skip();
                        if ShowOpen and (not CustLedgerEntry.Open) then
                            CurrReport.Skip();

                        if CustLedgerEntry.Open then
                            OpenText := 'Yes'
                        else
                            OpenText := 'No';
                    end else begin
                        if ShowCollection or ShowOpen then
                            CurrReport.Skip();
                        OpenText := '';
                    end;
                    ReminderTotal := ReminderTotal + "Remaining Amount" + Amount;
                    ReminderTotal := "Remaining Amount" + Amount;
                end;

                trigger OnPreDataItem()
                begin
                    if ShowCollection and (not CollectionLines) then
                        CurrReport.Break();
                    CopyFilters(TestReminderLine);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ReminderTerms.Get("Reminder Terms Code");
                Customer.Get("Customer No.");
            end;

            trigger OnPreDataItem()
            begin
                ReminderTotal := 0;
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
                    field(ShowCollection; ShowCollection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only Lines to collect';
                        ToolTip = 'Specifies if you want to show only reminder lines that have reached the highest reminder level.';
                    }
                    field(ShowOpen; ShowOpen)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only open Entries';
                        ToolTip = 'Specifies if you want to show only open entries.';
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

    var
        ReminderTerms: Record "Reminder Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        ReminderTotal: Decimal;
        CollectionLines: Boolean;
        OpenText: Text[30];
        ShowCollection: Boolean;
        ShowOpen: Boolean;
        CustomerCollectionListCaptionLbl: Label 'Customer - Collection List';
        PageCaptionLbl: Label 'Page';
        DueDateCaptionLbl: Label 'Due Date';
        DocumentTypeCaptionLbl: Label 'D Ty';
        TypeCaptionLbl: Label 'Ty';
        OpenTextCaptionLbl: Label 'Open';
        NoOfRemindersCaptionLbl: Label 'No. of Remind';
        PostingDateCaptionLbl: Label 'Posting Date';
        PhoneNoCaptionLbl: Label 'Phone No.';
        ReminderTotalCaptionLbl: Label 'Total';
        TotalToCollectCaptionLbl: Label 'Total to collect';
}

