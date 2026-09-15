// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11380 "Export Electronic Payment File"
{
    Caption = 'Export Electronic Payment File';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Check Exported" = const(false), "Check Printed" = const(false), "Bank Payment Type" = filter("Electronic Payment" | "Electronic Payment-IAT"), "Document Type" = filter(Payment | Refund));
            RequestFilterFields = "Journal Template Name", "Journal Batch Name";
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Applies-to ID" = field("Applies-to ID");
                DataItemLinkReference = "Gen. Journal Line";
                DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date", "Currency Code") order(descending) where(Open = const(true));

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Remaining Amt. (LCY)");
                    if ("Pmt. Discount Date" >= SettleDate) and
                       ("Remaining Pmt. Disc. Possible" <> 0) and
                       ((-ExportAmount - TotalAmountPaid) - "Remaining Pmt. Disc. Possible" >= -"Amount to Apply")
                    then
                        AmountPaid := -("Amount to Apply" - "Remaining Pmt. Disc. Possible")
                    else
                        if (-ExportAmount - TotalAmountPaid) > -"Amount to Apply" then
                            AmountPaid := -"Amount to Apply"
                        else
                            AmountPaid := -ExportAmount - TotalAmountPaid;

                    TotalAmountPaid := TotalAmountPaid + AmountPaid;
                end;

                trigger OnPreDataItem()
                begin
                    if "Gen. Journal Line"."Applies-to ID" = '' then
                        CurrReport.Break();

                    if BankAccountIs = BankAccountIs::Acnt then begin
                        if "Gen. Journal Line"."Bal. Account Type" <> "Gen. Journal Line"."Bal. Account Type"::Customer then
                            CurrReport.Break();
                        SetRange("Customer No.", "Gen. Journal Line"."Bal. Account No.");
                    end else begin
                        if "Gen. Journal Line"."Account Type" <> "Gen. Journal Line"."Account Type"::Customer then
                            CurrReport.Break();
                        SetRange("Customer No.", "Gen. Journal Line"."Account No.");
                    end;
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Applies-to ID" = field("Applies-to ID");
                DataItemLinkReference = "Gen. Journal Line";
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") order(descending) where(Open = const(true));

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Remaining Amt. (LCY)");
                    if ("Pmt. Discount Date" >= SettleDate) and
                       ("Remaining Pmt. Disc. Possible" <> 0) and
                       ((-ExportAmount - TotalAmountPaid) - "Remaining Pmt. Disc. Possible" >= -"Amount to Apply")
                    then
                        AmountPaid := -("Amount to Apply" - "Remaining Pmt. Disc. Possible")
                    else
                        if (-ExportAmount - TotalAmountPaid) > -"Amount to Apply" then
                            AmountPaid := -"Amount to Apply"
                        else
                            AmountPaid := -ExportAmount - TotalAmountPaid;

                    TotalAmountPaid := TotalAmountPaid + AmountPaid;
                end;

                trigger OnPreDataItem()
                begin
                    if "Gen. Journal Line"."Applies-to ID" = '' then
                        CurrReport.Break();

                    if BankAccountIs = BankAccountIs::Acnt then begin
                        if "Gen. Journal Line"."Bal. Account Type" <> "Gen. Journal Line"."Bal. Account Type"::Vendor then
                            CurrReport.Break();
                        SetRange("Vendor No.", "Gen. Journal Line"."Bal. Account No.");
                    end else begin
                        if "Gen. Journal Line"."Account Type" <> "Gen. Journal Line"."Account Type"::Vendor then
                            CurrReport.Break();
                        SetRange("Vendor No.", "Gen. Journal Line"."Account No.");
                    end;
                end;
            }
            dataitem(Unapplied; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    AmountPaid := -ExportAmount - TotalAmountPaid;
                end;

                trigger OnPreDataItem()
                begin
                    if TotalAmountPaid >= -ExportAmount then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            var
                TraceNumber: Code[30];
            begin
                if "Account Type" = "Account Type"::"Bank Account" then begin
                    BankAccountIs := BankAccountIs::Acnt;
                    if "Account No." <> BankAccount."No." then
                        CurrReport.Skip();
                end else
                    if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then begin
                        BankAccountIs := BankAccountIs::BalAcnt;
                        if "Bal. Account No." <> BankAccount."No." then
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();

                CheckAndStartExport("Gen. Journal Line");

                if IATFileCreated and ("Bank Payment Type" = "Bank Payment Type"::"Electronic Payment-IAT") then begin
                    if IATBatchOpen then
                        if (LastProcessedGenJournalLine."Account Type" <> "Account Type") or
                           (LastProcessedGenJournalLine."Account No." <> "Account No.") or
                           (LastProcessedGenJournalLine."Foreign Exchange Indicator" <> "Foreign Exchange Indicator") or
                           (LastProcessedGenJournalLine."Foreign Exchange Ref.Indicator" <> "Foreign Exchange Ref.Indicator") or
                           (LastProcessedGenJournalLine."Foreign Exchange Reference" <> "Foreign Exchange Reference") or
                           (LastProcessedGenJournalLine."Source Code" <> "Source Code")
                        then begin
                            ExportPaymentsIAT.EndExportBatch('220');
                            IATBatchOpen := false;
                        end;
                    if not IATBatchOpen then begin
                        ExportPaymentsIAT.StartExportBatch("Gen. Journal Line", '220', SettleDate);
                        IATBatchOpen := true;
                    end;
                end;

                SetPayeeType("Gen. Journal Line");

                AmountPaid := 0;
                TotalAmountPaid := 0;
                if PayeeType = PayeeType::Vendor then
                    ProcessVendor("Gen. Journal Line")
                else
                    ProcessCustomer("Gen. Journal Line");

                TotalAmountPaid := AmountPaid;

                TraceNumber := GetTraceNumber("Gen. Journal Line");

                if TraceNumber <> '' then begin
                    "Posting Date" := SettleDate;
                    "Check Printed" := true;
                    "Check Exported" := true;
                    "Export File Name" := BankAccount."Last E-Pay Export File Name";
                    "Exported to Payment File" := true;
                    BankAccount."Last Remittance Advice No." := IncStr(BankAccount."Last Remittance Advice No.");
                    "Document No." := BankAccount."Last Remittance Advice No.";
                    Modify();
                    InsertIntoCheckLedger(TraceNumber, -ExportAmount, RecordId);
                end;
                LastProcessedGenJournalLine := "Gen. Journal Line";
            end;

            trigger OnPostDataItem()
            begin
                if ACHFileCreated then begin
                    BankAccount.Modify();
                    case BankAccount."Export Format" of
                        BankAccount."Export Format"::US:
                            begin
                                ExportPaymentsACH.EndExportBatch('220');
                                if not ExportPaymentsACH.EndExportFile() then
                                    Error(UserCancelledErr);
                            end;
                        BankAccount."Export Format"::CA:
                            ExportPaymentsRB.EndExportFile();
                        BankAccount."Export Format"::MX:
                            begin
                                ExportPaymentsCecoban.EndExportBatch();
                                ExportPaymentsCecoban.EndExportFile();
                            end;
                    end;
                end;
                if IATFileCreated then begin
                    BankAccount.Modify();
                    if IATBatchOpen then begin
                        ExportPaymentsIAT.EndExportBatch('220');
                        IATBatchOpen := false;
                    end;

                    if not ExportPaymentsIAT.EndExportFile() then
                        Error(UserCancelledErr);
                end;
            end;

            trigger OnPreDataItem()
            begin
                ACHFileCreated := false;
                IATFileCreated := false;
                IATBatchOpen := false;
                Clear(LastProcessedGenJournalLine);
                if PostingDateOption = PostingDateOption::"Skip Lines Which Do Not Match" then
                    SetRange("Posting Date", SettleDate);
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
                    field(BankAccountNo; BankAccount."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the payment is transmitted to.';
                    }
                    field(SettleDate; SettleDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settle Date';
                        ToolTip = 'Specifies the settle date that will be transmitted to the bank. This date will become the posting date for the exported payment journal entries. Transmission should occur two or three banking days before the settle date. Ask your bank for the exact number of days.';
                    }
                    field(PostingDateOption; PostingDateOption)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If Posting Date does not match Settle Date:';
                        OptionCaption = 'Change Posting Date To Match,Skip Lines Which Do Not Match';
                        ToolTip = 'Specifies what will occur if the posting date does not match the settle date. The options are to change the posting date to match the entered settle date, or to skip any payment journal lines where the entered posting date does not match the settle date.';
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
        CompanyInformation.Get();
        GenJournalTemplate.Get("Gen. Journal Line".GetFilter("Journal Template Name"));

        BankAccount.LockTable();
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Currency Code", '');
        // local currency only
        BankAccount.TestField("Export Format");
        BankAccount.TestField("Last Remittance Advice No.");

        GenJournalTemplate.Get("Gen. Journal Line".GetFilter("Journal Template Name"));
        if not GenJournalTemplate."Force Doc. Balance" then
            if not Confirm(CannotVoidQst, true) then
                Error(UserCancelledErr);
    end;

    var
        CompanyInformation: Record "Company Information";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustBankAccount: Record "Customer Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vendor: Record Vendor;
        VendBankAccount: Record "Vendor Bank Account";
        VendLedgEntry: Record "Vendor Ledger Entry";
        LastProcessedGenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        ExportPaymentsCecoban: Codeunit "Export Payments (Cecoban)";
        CheckManagement: Codeunit CheckManagement;
        FormatAddress: Codeunit "Format Address";
        ACHFileCreated: Boolean;
        IATFileCreated: Boolean;
        IATBatchOpen: Boolean;
        ExportAmount: Decimal;
        BankAccountIs: Option Acnt,BalAcnt;
        SettleDate: Date;
        PostingDateOption: Option "Change Posting Date To Match","Skip Lines Which Do Not Match";
        PayeeAddress: array[8] of Text[100];
        PayeeType: Option Vendor,Customer;
        AmountPaid: Decimal;
        TotalAmountPaid: Decimal;
        InvalidExportFormatErr: Label '%1 is not a valid %2 in %3 %4.', Comment = '%1=Bank account export format,%2=Bank account export format field caption,%3=Bank account table caption,%4=Bank account number';
        AccountTypeErr: Label 'For Electronic Payments, the %1 must be %2 or %3.', Comment = '%1=Balance account type,%2=Customer table caption,%3=Vendor table caption';
        CannotVoidQst: Label 'Warning:  Transactions cannot be financially voided when Force Doc. Balance is set to No in the Journal Template.  Do you want to continue anyway?';
        UserCancelledErr: Label 'Process cancelled at user request.';

    local procedure InsertIntoCheckLedger(Trace: Code[30]; Amt: Decimal; RecordIdToPrint: RecordID)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.Init();
        CheckLedgerEntry."Bank Account No." := BankAccount."No.";
        CheckLedgerEntry."Posting Date" := SettleDate;
        CheckLedgerEntry."Document Type" := "Gen. Journal Line"."Document Type";
        CheckLedgerEntry."Document No." := "Gen. Journal Line"."Document No.";
        CheckLedgerEntry.Description := "Gen. Journal Line".Description;
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Electronic Payment";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Exported;
        CheckLedgerEntry."Check Date" := SettleDate;
        CheckLedgerEntry."Check No." := "Gen. Journal Line"."Document No.";
        if BankAccountIs = BankAccountIs::Acnt then begin
            CheckLedgerEntry."Bal. Account Type" := "Gen. Journal Line"."Bal. Account Type";
            CheckLedgerEntry."Bal. Account No." := "Gen. Journal Line"."Bal. Account No.";
        end else begin
            CheckLedgerEntry."Bal. Account Type" := "Gen. Journal Line"."Account Type";
            CheckLedgerEntry."Bal. Account No." := "Gen. Journal Line"."Account No.";
        end;
        CheckLedgerEntry."Trace No." := Trace;
        CheckLedgerEntry."Transmission File Name" := "Gen. Journal Line"."Export File Name";
        CheckLedgerEntry.Amount := Amt;
        CheckManagement.InsertCheck(CheckLedgerEntry, RecordIdToPrint);
    end;

    local procedure StartExportBasedOnFormat(var BankAccount: Record "Bank Account"; var GenJnlLine: Record "Gen. Journal Line"; SettleDate: Date) FileCreated: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartExportBasedOnFormat(ExportPaymentsACH, BankAccount, GenJnlLine, SettleDate, FileCreated, IsHandled);
        if IsHandled then
            exit(FileCreated);

        FileCreated := false;
        case BankAccount."Export Format" of
            BankAccount."Export Format"::US:
                begin
                    ExportPaymentsACH.StartExportFile(BankAccount."No.", '');
                    ExportPaymentsACH.StartExportBatch('220', 'CTX', GenJnlLine."Source Code", SettleDate);
                    FileCreated := true;
                end;
            BankAccount."Export Format"::CA:
                begin
                    ExportPaymentsRB.StartExportFile(BankAccount."No.", "Gen. Journal Line");
                    FileCreated := true;
                end;
            BankAccount."Export Format"::MX:
                begin
                    ExportPaymentsCecoban.StartExportFile(BankAccount."No.", '');
                    ExportPaymentsCecoban.StartExportBatch(30, GenJnlLine."Source Code", SettleDate);
                    FileCreated := true;
                end;
            else
                Error(InvalidExportFormatErr,
                  BankAccount."Export Format",
                  BankAccount.FieldCaption("Export Format"),
                  BankAccount.TableCaption(),
                  BankAccount."No.");
        end;
        BankAccount.Find();  // re-read, since StartExportFile changed it.
        exit(FileCreated);
    end;

    local procedure ProcessVendor(var GenJnlLine: Record "Gen. Journal Line")
    var
        EFTRecipientBankAccountMgt: codeunit "EFT Recipient Bank Account Mgt";
    begin
        FormatAddress.Vendor(PayeeAddress, Vendor);

        EFTRecipientBankAccountMgt.GetRecipientVendorBankAccount(VendBankAccount, GenJnlLine, Vendor."No.");

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.FindFirst();
            VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            if (VendLedgEntry."Pmt. Discount Date" >= SettleDate) and
               (VendLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
               (-(ExportAmount + VendLedgEntry."Remaining Pmt. Disc. Possible") >= -VendLedgEntry."Amount to Apply")
            then
                AmountPaid := -(VendLedgEntry."Amount to Apply" - VendLedgEntry."Remaining Pmt. Disc. Possible")
            else
                if -ExportAmount > -VendLedgEntry."Amount to Apply" then
                    AmountPaid := -VendLedgEntry."Amount to Apply"
                else
                    AmountPaid := -ExportAmount;
        end;
    end;

    local procedure ProcessCustomer(var GenJnlLine: Record "Gen. Journal Line")
    var
        EFTRecipientBankAccountMgt: codeunit "EFT Recipient Bank Account Mgt";
    begin
        FormatAddress.Customer(PayeeAddress, Customer);

        EFTRecipientBankAccountMgt.GetRecipientCustomerBankAccount(CustBankAccount, GenJnlLine, Customer."No.");

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            CustLedgEntry.SetRange("Customer No.", Customer."No.");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.FindFirst();
            CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
            if (CustLedgEntry."Pmt. Discount Date" >= SettleDate) and
               (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
               (-(ExportAmount - CustLedgEntry."Remaining Pmt. Disc. Possible") >= -CustLedgEntry."Amount to Apply")
            then
                AmountPaid := -(CustLedgEntry."Amount to Apply" - CustLedgEntry."Remaining Pmt. Disc. Possible")
            else
                if -ExportAmount > -CustLedgEntry."Amount to Apply" then
                    AmountPaid := -CustLedgEntry."Amount to Apply"
                else
                    AmountPaid := -ExportAmount;
        end;
    end;

    procedure SetOptions(BankAccountNo: Code[20]; ExportSettleDate: Date; SelectedPostingDateOption: Option "Change Posting Date To Match","Skip Lines Which Do Not Match")
    begin
        // Set up parameters to allow for this report to run programmatically without a request page
        BankAccount.Get(BankAccountNo);
        SettleDate := ExportSettleDate;
        PostingDateOption := SelectedPostingDateOption;
    end;

    local procedure CheckAndStartExport(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if not ACHFileCreated and
           (GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Electronic Payment")
        then begin
            ACHFileCreated := StartExportBasedOnFormat(BankAccount, "Gen. Journal Line", SettleDate);
            BankAccount.Find();
        end;
        if not IATFileCreated and
           (GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT")
        then
            if BankAccount."Export Format" = BankAccount."Export Format"::US then begin
                ExportPaymentsIAT.StartExportFile(BankAccount."No.", '');
                BankAccount.Find();
                IATFileCreated := true;
            end else
                Error(InvalidExportFormatErr,
                  BankAccount."Export Format",
                  BankAccount.FieldCaption("Export Format"),
                  BankAccount.TableCaption(),
                  BankAccount."No.");
    end;

    local procedure SetPayeeType(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if BankAccountIs = BankAccountIs::Acnt then begin
            ExportAmount := GenJournalLine."Amount (LCY)";
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor then begin
                PayeeType := PayeeType::Vendor;
                Vendor.Get(GenJournalLine."Bal. Account No.");
            end else
                if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Customer then begin
                    PayeeType := PayeeType::Customer;
                    Customer.Get(GenJournalLine."Bal. Account No.");
                end else
                    Error(AccountTypeErr,
                      GenJournalLine.FieldCaption("Bal. Account Type"), Customer.TableCaption(), Vendor.TableCaption());
        end else begin
            ExportAmount := -GenJournalLine."Amount (LCY)";
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then begin
                PayeeType := PayeeType::Vendor;
                Vendor.Get(GenJournalLine."Account No.");
            end else
                if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then begin
                    PayeeType := PayeeType::Customer;
                    Customer.Get(GenJournalLine."Account No.");
                end else
                    Error(AccountTypeErr,
                      GenJournalLine.FieldCaption("Account Type"), Customer.TableCaption(), Vendor.TableCaption());
        end;
    end;

    local procedure GetTraceNumber(var GenJournalLine: Record "Gen. Journal Line"): Code[30]
    begin
        case BankAccount."Export Format" of
            BankAccount."Export Format"::US:
                begin
                    if GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Electronic Payment" then
                        exit(ExportPaymentsACH.ExportElectronicPayment(GenJournalLine, ExportAmount));

                    exit(ExportPaymentsIAT.ExportElectronicPayment(GenJournalLine, ExportAmount));
                end;
            BankAccount."Export Format"::CA:
                exit(ExportPaymentsRB.ExportElectronicPayment(GenJournalLine, ExportAmount, SettleDate));
            BankAccount."Export Format"::MX:
                exit(ExportPaymentsCecoban.ExportElectronicPayment(GenJournalLine, ExportAmount, SettleDate));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartExportBasedOnFormat(var ExportPaymentsACH: Codeunit "Export Payments (ACH)"; var BankAccount: Record "Bank Account"; var GenJournalLine: Record "Gen. Journal Line"; SettleDate: Date; var FileCreated: Boolean; var IsHandled: Boolean)
    begin
    end;
}

