// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

codeunit 11000000 "Process Proposal Lines"
{
    TableNo = "Proposal Line";

    trigger OnRun()
    begin
        ClearAll();
        ProposalLine := Rec;
        ProposalLine.CopyFilters(Rec);
        ProposalLine.SetCurrentKey("Our Bank No.", Process);
        ProposalLine.SetRange(Process, true)
    end;

    var
        Text1000000: Label 'There is nothing to check.';
        Text1000001: Label '%1 %4 have been checked\';
        Text1000002: Label 'This contains:\\';
        Text1000003: Label '  %2 error(s) \';
        Text1000004: Label '  %3 warning(s)';
        Text1000005: Label 'Process proposal lines?';
        Text1000006: Label 'Output cancelled.';
        Text1000007: Label 'There is nothing to process.';
        Text1000008: Label 'The proposal lines were processed.';
        Text1000009: Label 'There are %3 lines processed and %2 lines not processed of %1 lines.';
        Text1000010: Label '%1 is not filled out correctly.';
        Text1000011: Label 'No %1 entered in %2.';
        Text1000012: Label '%1 is not stated correctly %2.';
        Text1000013: Label '%1 in number series must be switched on in number serie %2.';
        Text1000014: Label '%1 %2 must not be in the past.';
        Text1000015: Label '%1 must not be zero.';
        Text1000016: Label '%1 must be negative when %2=%3.';
        Text1000017: Label '%1 must be positive when %2=%3.';
        Text1000018: Label '%1 is not filled out.';
        Text1000019: Label '%1 is already in use, modify %1.';
        Text1000020: Label '%1 is already used more than once in the proposal.';
        Text1000021: Label 'Credit limit for bank %1 will be exceeded.';
        Text1000023: Label '%1 of %2 has not been entered correctly.';
        Text1000024: Label '%1 is not found in table %2.';
        Text1000025: Label '%1 %2 has open credit memo''s.';
        Text1000026: Label '%1 %2 has not been entered correctly.';
        Text1000027: Label '%1 is not entered.';
        Text1000028: Label '%1 is filled in, but %2 is 0.';
        Text1000029: Label '%1 must not be zero in detail line for %2 %3.';
        Text1000030: Label 'No Check ID entered in %1 %2.';
        ProposalLine: Record "Proposal Line";
        PaymentHistory: Record "Payment History";
        GenJnlLine: Record "Gen. Journal Line" temporary;
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
        LocalFuncMgt: Codeunit "Local Functionality Mgt.";
        NumberPosted: Integer;
        ErrorNumber: Integer;
        ErrorText: Text[125];
        WarningsText: Text[125];
        WarningNumber: Integer;
        AccountNo: Text[30];
        Text1000035: Label '%1 must not be zero in %2.';

    [Scope('OnPrem')]
    procedure CheckProposalLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProposalLines(ProposalLine, IsHandled);
        if IsHandled then
            exit;

        ErrorNumber := 0;
        NumberPosted := 0;
        WarningNumber := 0;

        if ProposalLine.Find('-') then
            repeat
                NumberPosted := NumberPosted + 1;
                if not CheckAProposalLine(ProposalLine) then
                    ErrorNumber := ErrorNumber + 1;
                if Warningstext <> '' then
                    WarningNumber := WarningNumber + 1;
                if (Errortext <> ProposalLine."Error Message") or
                   (Warningstext <> ProposalLine.Warning)
                then begin
                    ProposalLine."Error Message" := Errortext;
                    ProposalLine.Warning := Warningstext;
                    ProposalLine.Modify();
                end;
            until ProposalLine.Next() = 0;

        if NumberPosted = 0 then
            Message(Text1000000)
        else
            Message(Text1000001 + Text1000002 + Text1000003 + Text1000004, NumberPosted, ErrorNumber, WarningNumber, ProposalLine.TableCaption());
    end;

    [Scope('OnPrem')]
    procedure ProcessProposalLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessProposalLines(ProposalLine, IsHandled);
        if IsHandled then
            exit;

        ShowProcessLinesConfirm();

        ErrorNumber := 0;
        NumberPosted := 0;
        GenJnlLine.DeleteAll();

        if ProposalLine.Find('-') then begin
            repeat
                NumberPosted := NumberPosted + 1;
                if CheckAProposalLine(ProposalLine) then begin
                    if not PaymentHistoryPresent(ProposalLine, PaymentHistory) then
                        CreatePaymentHistory(ProposalLine, PaymentHistory);
                    CreatePaymentHistoryLine(ProposalLine, PaymentHistory);
                    DeleteProposallines(ProposalLine);
                end else begin
                    if (Errortext <> ProposalLine."Error Message") or
                       (Warningstext <> ProposalLine.Warning)
                    then begin
                        ProposalLine."Error Message" := Errortext;
                        ProposalLine.Warning := Warningstext;
                        ProposalLine.Modify();
                    end;
                    ErrorNumber := ErrorNumber + 1;
                end
            until ProposalLine.Next() = 0;
            FinancialInterfaceTelebank.PostFDBR(GenJnlLine);
            GenJnlLine.DeleteAll();
        end;

        if NumberPosted = 0 then
            Message(Text1000007)
        else
            case ErrorNumber of
                0:
                    Message(Text1000008);
                1:
                    Message(Text1000009, NumberPosted, ErrorNumber, NumberPosted -
                      ErrorNumber);
                else
                    Message(Text1000009, NumberPosted, ErrorNumber, NumberPosted -
                      ErrorNumber);
            end;
    end;

    local procedure ShowProcessLinesConfirm()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowProcessLinesConfirm(ProposalLine, IsHandled);
        if IsHandled then
            exit;

        if not Confirm(Text1000005, false) then
            Error(Text1000006);
    end;

    procedure CheckAProposalLine(CheckRecord: Record "Proposal Line") res: Boolean
    var
        TranMode: Record "Transaction Mode";
        ExportProtocol: Record "Export Protocol";
        NoSeries: Record "No. Series";
        OurBnk: Record "Bank Account";
        DetailLine: Record "Detail Line";
        PaymentHistoryLine: Record "Payment History Line";
        ProposalLine: Record "Proposal Line";
    begin
        Errortext := '';
        Warningstext := '';

        // //////////////////////////////////////////////////////////////////////
        // General information

        if not TranMode.Get(CheckRecord."Account Type", CheckRecord."Transaction Mode") then begin
            Errortext := StrSubstNo(Text1000010, CheckRecord.FieldCaption("Transaction Mode"));
            exit(false);
        end;

        if not ExportProtocol.Get(TranMode."Export Protocol") then begin
            Errortext := StrSubstNo(Text1000011, TranMode.FieldCaption("Export Protocol"), TranMode.TableCaption());
            exit(false);
        end;

        if not NoSeries.Get(TranMode."Run No. Series") then begin
            Errortext := StrSubstNo(Text1000012,
                TranMode.FieldCaption("Run No. Series"), TranMode.TableCaption());
            exit(false);
        end;

        if not NoSeries."Default Nos." then begin
            Errortext := StrSubstNo(Text1000013,
                NoSeries.FieldCaption("Default Nos."), NoSeries.Code);
            exit(false);
        end;

        if CheckRecord."Transaction Date" < Today then begin
            Errortext := StrSubstNo(Text1000014,
                CheckRecord.FieldCaption("Transaction Date"),
                CheckRecord."Transaction Date");
            exit(false);
        end;
        if CheckRecord.Amount = 0 then begin
            Errortext := StrSubstNo(Text1000015, CheckRecord.FieldCaption(Amount));
            exit(false);
        end;

        case CheckRecord.Order of
            CheckRecord.Order::Credit:
                if CheckRecord.Amount > 0 then begin
                    Errortext :=
                      StrSubstNo(Text1000016, CheckRecord.FieldCaption(Amount),
                        CheckRecord.FieldCaption("Transaction Mode"), CheckRecord."Transaction Mode");
                    exit(false);
                end;
            CheckRecord.Order::Debit:
                if CheckRecord.Amount < 0 then begin
                    Errortext :=
                      StrSubstNo(Text1000017, CheckRecord.FieldCaption(Amount),
                        CheckRecord.FieldCaption("Transaction Mode"), CheckRecord."Transaction Mode");
                    exit(false);
                end;
        end;

        // //////////////////////////////////////////////////////////////////////
        // identification

        if CheckRecord.Identification = '' then begin
            Errortext := StrSubstNo(Text1000018,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;

        PaymentHistoryLine.SetCurrentKey("Our Bank", Identification, Status);
        PaymentHistoryLine.SetRange("Our Bank", CheckRecord."Our Bank No.");
        PaymentHistoryLine.SetRange(Identification, CheckRecord.Identification);
        PaymentHistoryLine.SetFilter(Status, '<>%1&<>%2&<>%3',
          PaymentHistoryLine.Status::Posted,
          PaymentHistoryLine.Status::Cancelled,
          PaymentHistoryLine.Status::Rejected);
        if PaymentHistoryLine.FindFirst() then begin
            Errortext := StrSubstNo(Text1000019,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;
        ProposalLine.SetCurrentKey("Our Bank No.", Identification);
        ProposalLine.SetRange("Our Bank No.", CheckRecord."Our Bank No.");
        ProposalLine.SetRange(Identification, CheckRecord.Identification);
        ProposalLine.SetFilter("Line No.", '<>%1', CheckRecord."Line No.");
        if ProposalLine.FindFirst() then begin
            Errortext := StrSubstNo(Text1000020,
                CheckRecord.FieldCaption(Identification));
            exit(false);
        end;

        // //////////////////////////////////////////////////////////////////////
        // Own account

        if not CheckOurBank(CheckRecord, OurBnk) then
            exit(false);

        // //////////////////////////////////////////////////////////////////////
        // Customer, Vendor and Employee

        if not CheckLedgerEntries(CheckRecord) then
            exit(false);

        if not LocalFuncMgt.CheckBankAccNo(CheckRecord."Bank Account No.", CheckRecord."Bank Country/Region Code", AccountNo) then begin
            Errortext := StrSubstNo(Text1000026, CheckRecord.FieldCaption("Bank Account No."), CheckRecord."Bank Account No.");
            exit(false);
        end;

        if not (CheckRecord."Account Type" = CheckRecord."Account Type"::Employee) then begin
            if CheckRecord."Account Holder Name" = '' then begin
                Errortext := StrSubstNo(Text1000027,
                    CheckRecord.FieldCaption("Account Holder Name"));
                exit(false);
            end;

            if CheckRecord."Account Holder City" = '' then begin
                Errortext := StrSubstNo(Text1000027,
                    CheckRecord.FieldCaption("Account Holder City"));
                exit(false);
            end;
        end;

        if (CheckRecord."Foreign Currency" <> '') and
           (CheckRecord."Foreign Amount" = 0)
        then
            if OurBnk."Currency Code" <> CheckRecord."Foreign Currency" then begin
                Errortext :=
                  StrSubstNo(
                    Text1000028, CheckRecord.FieldCaption("Foreign Currency"), CheckRecord.FieldCaption("Foreign Amount")
                    );
                exit(false);
            end;

        // /////////////////////////////////////////////////////////////////////
        // Per detail line

        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines");
        DetailLine.SetRange("Our Bank", CheckRecord."Our Bank No.");
        DetailLine.SetRange(Status, DetailLine.Status::Proposal);
        DetailLine.SetRange("Connect Batches", '');
        DetailLine.SetRange("Connect Lines", CheckRecord."Line No.");
        if DetailLine.Find('-') then
            repeat
                if DetailLine.Amount = 0 then begin
                    Errortext :=
                      StrSubstNo(
                        Text1000029,
                        DetailLine.FieldCaption(Amount),
                        DetailLine.FieldCaption("Serial No. (Entry)"),
                        DetailLine."Serial No. (Entry)");
                    exit(false);
                end;
                if DetailLine."Serial No. (Entry)" = 0 then begin
                    Errortext :=
                      StrSubstNo(
                        Text1000035,
                        DetailLine.FieldCaption("Serial No. (Entry)"),
                        DetailLine.TableCaption());
                    exit(false);
                end;
            until DetailLine.Next() = 0;

        // //////////////////////////////////////////////////////////////////////
        // Protocol specific

        if ExportProtocol."Check ID" <> 0 then begin
            CheckRecord."Error Message" := '';
            CheckRecord.Warning := '';
            CODEUNIT.Run(ExportProtocol."Check ID", CheckRecord);
            if CheckRecord.Warning <> '' then
                Warningstext := CheckRecord.Warning;
            if CheckRecord."Error Message" <> '' then begin
                Errortext := CheckRecord."Error Message";
                exit(false)
            end;
        end else begin
            Errortext := StrSubstNo(Text1000030, ExportProtocol.TableCaption(), ExportProtocol.Code);
            exit(false);
        end;

        res := true;
        OnAfterCheckAProposalLine(CheckRecord, Errortext, Warningstext, res);
    end;

    local procedure CheckOurBank(var ProposalLine: Record "Proposal Line"; var BankAccount: Record "Bank Account"): Boolean
    begin
        if not BankAccount.Get(ProposalLine."Our Bank No.") then begin
            Errortext := StrSubstNo(Text1000010, ProposalLine.FieldCaption("Our Bank No."));
            exit(false);
        end;

        if BankAccount.GetCreditLimit() < 0 then begin
            Errortext := StrSubstNo(Text1000021, ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Name" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Name"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Address" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Address"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder Post Code" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder Post Code"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        if BankAccount."Account Holder City" = '' then begin
            Errortext := StrSubstNo(Text1000023,
                BankAccount.FieldCaption("Account Holder City"), ProposalLine."Our Bank No.");
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckLedgerEntries(var ProposalLine: Record "Proposal Line") Result: Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        Customer: Record Customer;
        Employee: Record Employee;
        Vendor: Record Vendor;
    begin
        case ProposalLine."Account Type" of
            ProposalLine."Account Type"::Customer:
                begin
                    if not Customer.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Customer.TableCaption());
                        exit(false);
                    end;
                    CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.");
                    CustLedgerEntry.SetRange("Customer No.", ProposalLine."Account No.");
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                    CustLedgerEntry.SetRange(Open, true);
                    if CustLedgerEntry.FindFirst() then
                        Warningstext := StrSubstNo(Text1000025, Customer.TableCaption(), ProposalLine."Account No.");
                end;
            ProposalLine."Account Type"::Vendor:
                begin
                    if not Vendor.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Vendor.TableCaption());
                        exit(false);
                    end;
                    VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.");
                    VendorLedgerEntry.SetRange("Vendor No.", ProposalLine."Account No.");
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
                    VendorLedgerEntry.SetRange(Open, true);
                    if VendorLedgerEntry.FindFirst() then
                        Warningstext := StrSubstNo(Text1000025, Vendor.TableCaption(), ProposalLine."Account No.");
                end;
            ProposalLine."Account Type"::Employee:
                begin
                    if not Employee.Get(ProposalLine."Account No.") then begin
                        Errortext := StrSubstNo(Text1000024, ProposalLine.FieldCaption("Account No."), Employee.TableCaption());
                        exit(false);
                    end;
                    EmployeeLedgerEntry.SetCurrentKey("Document Type", "Employee No.");
                    EmployeeLedgerEntry.SetRange("Employee No.", ProposalLine."Account No.");
                    EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::"Credit Memo");
                    EmployeeLedgerEntry.SetRange(Open, true);
                    if EmployeeLedgerEntry.FindFirst() then
                        Warningstext := StrSubstNo(Text1000025, Employee.TableCaption(), ProposalLine."Account No.");
                end;
        end;

        Result := true;
        OnAfterCheckLedgerEntries(ProposalLine, Warningstext, Errortext, Result);
    end;

    [Scope('OnPrem')]
    procedure PaymentHistoryPresent(var Prop: Record "Proposal Line"; var PaymentHistory: Record "Payment History") Present: Boolean
    var
        TranMode: Record "Transaction Mode";
    begin
        TranMode.Get(ProposalLine."Account Type", ProposalLine."Transaction Mode");

        PaymentHistory.SetCurrentKey("Our Bank", "Export Protocol", Status, "User ID");
        PaymentHistory.SetRange("Our Bank", ProposalLine."Our Bank No.");
        PaymentHistory.SetRange("Export Protocol", TranMode."Export Protocol");
        PaymentHistory.SetRange(Status, PaymentHistory.Status::New);
        PaymentHistory.SetRange("User ID", UserId);

        exit(PaymentHistory.Find('-'));
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHistory(var ProposalLine: Record "Proposal Line"; var PaymentHistory: Record "Payment History")
    var
        TranMode: Record "Transaction Mode";
        OurBnk: Record "Bank Account";
        NoSeries: Codeunit "No. Series";
        DimManagement: Codeunit DimensionManagement;
    begin
        Clear(PaymentHistory);
        TranMode.Get(ProposalLine."Account Type", ProposalLine."Transaction Mode");
        TranMode.TestField("Run No. Series");

        PaymentHistory."Our Bank" := ProposalLine."Our Bank No.";
            PaymentHistory."No. Series" := TranMode."Run No. Series";
            PaymentHistory."Run No." := NoSeries.GetNextNo(PaymentHistory."No. Series", Today());


        PaymentHistory.Init();

        PaymentHistory.Status := PaymentHistory.Status::New;
        PaymentHistory."Creation Date" := Today;
        PaymentHistory."User ID" := UserId;

        TranMode.Get(ProposalLine."Account Type", ProposalLine."Transaction Mode");
        PaymentHistory."Export Protocol" := TranMode."Export Protocol";

        OurBnk.Get(ProposalLine."Our Bank No.");

        PaymentHistory."Account No." := OurBnk."Bank Account No.";
        PaymentHistory."Account Holder Name" := OurBnk."Account Holder Name";
        PaymentHistory."Account Holder Address" := OurBnk."Account Holder Address";
        PaymentHistory."Account Holder Post Code" := OurBnk."Account Holder Post Code";
        PaymentHistory."Account Holder City" := OurBnk."Account Holder City";
        PaymentHistory."Acc. Hold. Country/Region Code" := OurBnk."Acc. Hold. Country/Region Code";

        PaymentHistory."Dimension Set ID" := ProposalLine."Header Dimension Set ID";

        DimManagement.UpdateGlobalDimFromDimSetID(PaymentHistory."Dimension Set ID",
          PaymentHistory."Global Dimension 1 Code", PaymentHistory."Global Dimension 2 Code");

        PaymentHistory.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHistoryLine(var ProposalLine: Record "Proposal Line"; var PaymentHistory: Record "Payment History")
    var
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
    begin
        PaymentHistory."No. of Transactions" := PaymentHistory."No. of Transactions" + 1;
        if ProposalLine.Docket then
            PaymentHistory."Print Docket" := true;
        PaymentHistory.Modify(true);

        PaymentHistoryLine."Our Bank" := PaymentHistory."Our Bank";
        PaymentHistoryLine."Run No." := PaymentHistory."Run No.";
        PaymentHistoryLine."Line No." := PaymentHistory."No. of Transactions";
        PaymentHistoryLine.Status := PaymentHistoryLine.Status::New;

        PaymentHistoryLine."Account Type" := ProposalLine."Account Type";
        PaymentHistoryLine."Account No." := ProposalLine."Account No.";
        PaymentHistoryLine.Date := ProposalLine."Transaction Date";
        PaymentHistoryLine.Amount := ProposalLine.Amount;
        PaymentHistoryLine.Bank := ProposalLine.Bank;
        PaymentHistoryLine."Bank Account No." := ProposalLine."Bank Account No.";

        PaymentHistoryLine."Description 1" := ProposalLine."Description 1";
        PaymentHistoryLine."Description 2" := ProposalLine."Description 2";
        PaymentHistoryLine."Description 3" := ProposalLine."Description 3";
        PaymentHistoryLine."Description 4" := ProposalLine."Description 4";
        PaymentHistoryLine.Identification := ProposalLine.Identification;

        PaymentHistoryLine."Account Holder Name" := ProposalLine."Account Holder Name";
        PaymentHistoryLine."Account Holder Address" := ProposalLine."Account Holder Address";
        PaymentHistoryLine."Account Holder Post Code" := ProposalLine."Account Holder Post Code";
        PaymentHistoryLine."Account Holder City" := ProposalLine."Account Holder City";
        PaymentHistoryLine."Acc. Hold. Country/Region Code" := ProposalLine."Acc. Hold. Country/Region Code";
        PaymentHistoryLine."National Bank Code" := ProposalLine."National Bank Code";
        PaymentHistoryLine."SWIFT Code" := ProposalLine."SWIFT Code";
        PaymentHistoryLine.IBAN := ProposalLine.IBAN;
        PaymentHistoryLine."Direct Debit Mandate ID" := ProposalLine."Direct Debit Mandate ID";
        PaymentHistoryLine."Abbrev. National Bank Code" := ProposalLine."Abbrev. National Bank Code";
        PaymentHistoryLine."Bank Name" := ProposalLine."Bank Name";
        PaymentHistoryLine."Bank Address" := ProposalLine."Bank Address";
        PaymentHistoryLine."Bank City" := ProposalLine."Bank City";
        PaymentHistoryLine."Bank Country/Region" := ProposalLine."Bank Country/Region Code";
        PaymentHistoryLine."Transfer Cost Domestic" := ProposalLine."Transfer Cost Domestic";
        PaymentHistoryLine."Transfer Cost Foreign" := ProposalLine."Transfer Cost Foreign";

        PaymentHistoryLine."Currency Code" := ProposalLine."Currency Code";
        PaymentHistoryLine.Order := ProposalLine.Order;
        PaymentHistoryLine."Transaction Mode" := ProposalLine."Transaction Mode";
        PaymentHistoryLine.Docket := ProposalLine.Docket;

        PaymentHistoryLine."Nature of the Payment" := ProposalLine."Nature of the Payment";
        PaymentHistoryLine."Registration No. DNB" := ProposalLine."Registration No. DNB";
        PaymentHistoryLine."Description Payment" := ProposalLine."Description Payment";
        PaymentHistoryLine."Item No." := ProposalLine."Item No.";
        PaymentHistoryLine."Traders No." := ProposalLine."Traders No.";
        PaymentHistoryLine.Urgent := ProposalLine.Urgent;

        if ((PaymentHistoryLine.Order = PaymentHistoryLine.Order::Credit) and
            (PaymentHistoryLine."Account Type" = PaymentHistoryLine."Account Type"::Vendor)) or
           ((PaymentHistoryLine.Order = PaymentHistoryLine.Order::Credit) and
            (PaymentHistoryLine."Account Type" = PaymentHistoryLine."Account Type"::Customer)) or
           ((PaymentHistoryLine.Order = PaymentHistoryLine.Order::Credit) and
            (PaymentHistoryLine."Account Type" = PaymentHistoryLine."Account Type"::Employee))
        then
            PaymentHistoryLine."Payment/Receipt" := PaymentHistoryLine."Payment/Receipt"::Receipt
        else
            PaymentHistoryLine."Payment/Receipt" := PaymentHistoryLine."Payment/Receipt"::Payment;

        PaymentHistoryLine."Foreign Currency" := ProposalLine."Foreign Currency";
        PaymentHistoryLine."Foreign Amount" := ProposalLine."Foreign Amount";

        PaymentHistoryLine."Global Dimension 1 Code" := ProposalLine."Shortcut Dimension 1 Code";
        PaymentHistoryLine."Global Dimension 2 Code" := ProposalLine."Shortcut Dimension 2 Code";
        PaymentHistoryLine."Dimension Set ID" := ProposalLine."Dimension Set ID";
        if ((PaymentHistoryLine.Order = PaymentHistoryLine.Order::Credit) and
            (PaymentHistoryLine."Account Type" = PaymentHistoryLine."Account Type"::Customer))
        then
            UpdateDirectDebitMandate(PaymentHistoryLine);
        PaymentHistoryLine.Insert(true);

        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines");
        DetailLine.SetRange("Our Bank", ProposalLine."Our Bank No.");
        DetailLine.SetRange(Status, DetailLine.Status::Proposal);
        DetailLine.SetRange("Connect Batches", '');
        DetailLine.SetRange("Connect Lines", ProposalLine."Line No.");
        while DetailLine.FindFirst() do begin
            DetailLine.Status := DetailLine.Status::"In process";
            DetailLine."Connect Batches" := PaymentHistoryLine."Run No.";
            DetailLine."Connect Lines" := PaymentHistoryLine."Line No.";
            DetailLine.Modify(true);
        end;

        FinancialInterfaceTelebank.PostPaymReceived(GenJnlLine, PaymentHistoryLine, PaymentHistory);

        OnAfterCreatePaymentHistoryLine(ProposalLine, PaymentHistory, PaymentHistoryLine);
    end;

    [Scope('OnPrem')]
    procedure DeleteProposallines(var Prop: Record "Proposal Line")
    begin
        ProposalLine.Delete(true);
    end;

    procedure FinalError() Res: Text[125]
    begin
        exit(Errortext);
    end;

    procedure FinalWarning() Res: Text[125]
    begin
        exit(Warningstext);
    end;

    [Scope('OnPrem')]
    procedure GetAccountnumber() Acc: Text[30]
    begin
        exit(AccountNo);
    end;

    local procedure UpdateDirectDebitMandate(var PaymentHistoryLine: Record "Payment History Line")
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        if DirectDebitMandate.Get(PaymentHistoryLine."Direct Debit Mandate ID") then begin
            DirectDebitMandate.Validate("Debit Counter", DirectDebitMandate."Debit Counter" + 1);

            OnUpdateDirectDebitMandateOnBeforeModify(DirectDebitMandate, PaymentHistoryLine);
            DirectDebitMandate.Modify(true);

            PaymentHistoryLine.Validate("Direct Debit Mandate Counter", DirectDebitMandate."Debit Counter");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckLedgerEntries(ProposalLine: Record "Proposal Line"; var WarningsText: Text[125]; var ErrorText: Text[125]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAProposalLine(ProposalLine: Record "Proposal Line"; var ErrorText: Text[125]; var WarningsText: Text[125]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePaymentHistoryLine(var ProposalLine: Record "Proposal Line"; var PaymentHistory: Record "Payment History"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProposalLines(var ProposalLine: Record "Proposal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessProposalLines(var ProposalLine: Record "Proposal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowProcessLinesConfirm(ProposalLine: Record "Proposal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectDebitMandateOnBeforeModify(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;
}
