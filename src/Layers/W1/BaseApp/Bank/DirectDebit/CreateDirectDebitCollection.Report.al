// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Creates direct debit collections from open customer ledger entries based on specified criteria.
/// Filters customers and invoices, validates mandates, and automatically generates collection entries
/// for eligible transactions within the specified date range.
/// </summary>
report 1200 "Create Direct Debit Collection"
{
    Caption = 'Create Direct Debit Collection';
    ProcessingOnly = true;
    TransactionType = Update;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "Currency Code", "Country/Region Code";
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Currency Code" = field("Currency Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting(Open, "Due Date") where(Open = const(true), "Document Type" = const(Invoice));

                trigger OnAfterGetRecord()
                begin
                    if OnlyCustomersWithMandate then
                        if not Customer.HasValidDDMandate("Due Date") then
                            CurrReport.Skip();
                    if OnlyInvoicesWithMandate then begin
                        SEPADirectDebitMandate.Get("Direct Debit Mandate ID");
                        if not SEPADirectDebitMandate.IsMandateActive("Due Date") then
                            CurrReport.Skip();
                    end;

                    if not EntryFullyCollected("Entry No.") then begin
                        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", "Cust. Ledger Entry");
                        NoOfEntries += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetAutoCalcFields("Remaining Amount");
                    SetRange("Due Date", FromDate, ToDate);
                    if OnlyInvoicesWithMandate then
                        SetFilter("Direct Debit Mandate ID", '<>%1', '');
                    SetFilter("Currency Code", BankAccount."Currency Code");
                end;
            }

            trigger OnPreDataItem()
            begin
                DirectDebitCollection.CreateRecord(BankAccount.GetDirectDebitMessageNo(), BankAccount."No.", PartnerType);
                SetRange("Partner Type", PartnerType);
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
                field(FromDueDate; FromDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'From Due Date';
                    ToolTip = 'Specifies the earliest payment due date on sales invoices that you want to create a direct-debit collection for.';
                }
                field(ToDueDate; ToDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'To Due Date';
                    ToolTip = 'Specifies the latest payment due date on sales invoices that you want to create a direct-debit collection for.';

                    trigger OnValidate()
                    begin
                        if (ToDate <> 0D) and (FromDate > ToDate) then
                            Error(WrongDateErr);
                    end;
                }
                field(PartnerType; PartnerType)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Partner Type';
                    NotBlank = true;
                    ToolTip = 'Specifies if the direct-debit collection is made for customers of type Company or Person.';
                }
                field(OnlyCustomerValidMandate; OnlyCustomersWithMandate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Only Customers With Valid Mandate';
                    ToolTip = 'Specifies if a direct-debit collection is created for customers who have a valid direct-debit mandate. A direct-debit collection is created even if the Direct Debit Mandate ID field is not filled on the sales invoice.';
                }
                field(OnlyInvoiceValidMandate; OnlyInvoicesWithMandate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Only Invoices With Valid Mandate';
                    ToolTip = 'Specifies if a direct-debit collection is only created for sales invoices if a valid direct-debit mandate is selected in the Direct Debit Mandate ID field on the sales invoice.';
                }
                field(BankAccNo; BankAccount."No.")
                {
                    ApplicationArea = Suite;
                    Caption = 'Bank Account No.';
                    TableRelation = "Bank Account";
                    ToolTip = 'Specifies which of your company''s bank accounts the collected payment will be transferred to from the customer''s bank account.';

                    trigger OnValidate()
                    begin
                        if BankAccount."No." = '' then
                            exit;
                        BankAccount.Get(BankAccount."No.");
                        if BankAccount."Direct Debit Msg. Nos." = '' then
                            Error(DirectDebitMsgNosErr, BankAccount."No.")
                    end;
                }
                field(BankAccName; BankAccount.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bank Account Name';
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the name of the bank account that you select in the Bank Account No. field. This field is filled automatically.';
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

    trigger OnPostReport()
    begin
        if NoOfEntries = 0 then
            Error(NoEntriesCreatedErr);
        Message(EntriesCreatedMsg, NoOfEntries);
    end;

    trigger OnPreReport()
    begin
        BankAccount.Get(BankAccount."No.");
        GLSetup.Get();
    end;

    var
        BankAccount: Record "Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        GLSetup: Record "General Ledger Setup";
        NoOfEntries: Integer;

        WrongDateErr: Label 'To Date must be equal to or greater than From Date.';
        NoEntriesCreatedErr: Label 'No entries have been created.', Comment = '%1=Field;%2=Table;%3=Field;Table';
        EntriesCreatedMsg: Label '%1 entries have been created.', Comment = '%1 = an integer number, e.g. 7.';
        DirectDebitMsgNosErr: Label 'The bank account %1 is not set up for direct debit collections. It needs a number series for direct debit files. You specify the number series on the card for the bank account.', Comment = '%1=Code, the No. of Bank Account';

    protected var
        FromDate: Date;
        ToDate: Date;
        OnlyCustomersWithMandate: Boolean;
        OnlyInvoicesWithMandate: Boolean;
        PartnerType: Enum "Partner Type";

    local procedure EntryFullyCollected(EntryNo: Integer): Boolean
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Applies-to Entry No.", EntryNo);
        if DirectDebitCollectionEntry.IsEmpty() then
            exit(false);

        DirectDebitCollectionEntry.SetFilter(
          Status, '%1|%2', DirectDebitCollectionEntry.Status::New, DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollectionEntry.CalcSums("Transfer Amount");
        exit(DirectDebitCollectionEntry."Transfer Amount" >= "Cust. Ledger Entry"."Remaining Amount");
    end;
}

