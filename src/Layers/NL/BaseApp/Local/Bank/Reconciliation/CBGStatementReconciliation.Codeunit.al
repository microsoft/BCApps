// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Statement;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

codeunit 11000006 "CBG Statement Reconciliation"
{

    trigger OnRun()
    var
        CBGStatement: Record "CBG Statement";
    begin
        ResetNumbers();
        if CBGStatement.Find('-') then
            repeat
                MatchCBGStatement(CBGStatement);
            until CBGStatement.Next() = 0;
    end;

    var
        Text1000000: Label 'Reconciliation\';
        Text1000001: Label 'Bank/Giro Journal\';
        Text1000002: Label 'Prepare reconciliation:     @1@@@@@@@@@@\';
        Text1000003: Label 'Process reconciliation:     @2@@@@@@@@@@\';
        Text1000004: Label 'CBGStatement numbers processed:   #3#######\';
        Text1000005: Label 'CBGStatement lines processed:     #4#######\';
        Text1000006: Label 'CBGStatement lines changed:       #5#######\';
        Text1000007: Label 'CBGStatement lines applied:       #6#######\';
        Text1000008: Label '1 CBGStatement number has been processed containing ';
        Text1000009: Label '1 CBGStatement line.\';
        Text1000010: Label '%1 lines.\';
        Text1000011: Label '%1 CBGStatement numbers have been processed with \';
        Text1000012: Label 'in total 1 CBGStatementline.\';
        Text1000013: Label 'in total %1 CBGStatementlines.\';
        Text1000014: Label 'Number of lines changed: %1.\';
        Text1000015: Label 'Number of lined applied: %1.';
        PaymentHistoryLine: Record "Payment History Line";
        TransactionMode: Record "Transaction Mode";
        TempBankAccount: Record "Bank Account" temporary;
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TempReconciliationBuffer: Record "Reconciliation Buffer" temporary;
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        Name: Code[80];
        Address: Code[80];
        City: Code[80];
        Identification: Code[80];
        NumberOfDocumentNumbers: Integer;
        NumberOfLinesProcessed: Integer;
        NumberOfLinesChanged: Integer;
        NumberOfLinesApplied: Integer;
        StatusWindowOpened: Boolean;
        Window: Dialog;
        HideMessages: Boolean;
        BankAccountCharsToKeep: Text[250];

    procedure MatchCBGStatement(CBGStatement: Record "CBG Statement")
    var
        CBGStatementLine: Record "CBG Statement Line";
        NumberOfLines: Integer;
        LineCounter: Integer;
    begin
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        NumberOfDocumentNumbers := NumberOfDocumentNumbers + 1;
        OnMatchCBGStatementOnBeforeCBGStatementLineFind(CBGStatementLine, CBGStatement);
        if CBGStatementLine.Find('-') then begin
            NumberOfLines := CBGStatementLine.Count();
            StatusWindowOpen();
            repeat
                LineCounter := LineCounter + 1;
                MatchCBGStatementLine(CBGStatement, CBGStatementLine);
                StatusWindowUpdate(2, Round(LineCounter / NumberOfLines * 10000, 1));
            until CBGStatementLine.Next() = 0;
            StatusWindowClose();
        end;

        OnAfterMatchCBGStatement(CBGStatement);
    end;

    [Scope('OnPrem')]
    procedure MatchCBGStatementLine(CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line")
    var
        RecChanged: Boolean;
        PaymentHistoryFound: Boolean;
        EntriesCount: Integer;
        EntryNo: Integer;
        strFilter: Text[250];
        IsHandled: Boolean;
    begin
        MakeTempfile();
        NumberOfLinesProcessed := NumberOfLinesProcessed + 1;
        RecChanged := false;
        ProcessPostDesRecDescription(CBGStatementLine);
        UpdateAccount(CBGStatementLine, NumberOfLinesChanged, RecChanged);
        PaymentHistoryFound := false;
        if Identification <> '' then begin
            PaymentHistoryLine.SetCurrentKey("Our Bank", Identification, Status);
            CBGStatementLine.TestField("Statement Type", CBGStatementLine."Statement Type"::"Bank Account");
            PaymentHistoryLine.SetRange("Our Bank", CBGStatementLine."Statement No.");
            PaymentHistoryLine.SetRange(Identification, Identification);
            PaymentHistoryLine.SetFilter(Status, '%1|%2',
              PaymentHistoryLine.Status::Transmitted, PaymentHistoryLine.Status::"Request for Cancellation");

            if PaymentHistoryLine.FindFirst() then
                if (PaymentHistoryLine.Amount = CBGStatementLine.Amount) and
                   ((CBGStatementLine."Account No." = '') or (CBGStatementLine."Account No." = PaymentHistoryLine."Account No."))
                then begin
                    CBGStatementLine.Identification := Identification;
                    case PaymentHistoryLine."Account Type" of
                        PaymentHistoryLine."Account Type"::Customer:
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Customer;
                        PaymentHistoryLine."Account Type"::Vendor:
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Vendor;
                        PaymentHistoryLine."Account Type"::Employee:
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Employee;
                    end;
                    PaymentHistoryFound := true;
                    CBGStatementLine.Validate("Account No.", PaymentHistoryLine."Account No.");
                    CBGStatementLine."Amount Settled" := PaymentHistoryLine.Amount;
                    CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Applied;
                    CBGStatementLine."Applies-to ID" := CBGStatementLine."New Applies-to ID"();
                    CBGStatementLine."Applies-to Doc. Type" := CBGStatementLine."Applies-to Doc. Type"::" ";
                    CBGStatementLine."Applies-to Doc. No." := '';
                    NumberOfLinesApplied := NumberOfLinesApplied + 1;
                    if RecChanged then
                        NumberOfLinesChanged := NumberOfLinesChanged - 1;
                    RecChanged := true;
                end;
        end;

        IsHandled := false;
        OnMatchCBGStatementLineOnAfterCheckIdentificationFilled(CBGStatement, CBGStatementLine, PaymentHistoryFound, NumberOfLinesApplied, NumberOfLinesChanged, RecChanged, IsHandled);

        if (not PaymentHistoryFound) and
           (CBGStatementLine.Identification = '') and
           (CBGStatementLine."Reconciliation Status" <> CBGStatementLine."Reconciliation Status"::Applied) and
            not IsHandled
        then
            if CBGStatementLine."Account No." <> '' then
                case CBGStatementLine."Account Type" of
                    CBGStatementLine."Account Type"::Customer:
                        begin
                            CustLedgerEntry.Reset();
                            CustLedgerEntry.SetCurrentKey("Customer No.", Open);
                            CustLedgerEntry.SetRange("Customer No.", CBGStatementLine."Account No.");
                            CustLedgerEntry.SetRange(Open, true);
                            CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Payment);
                            GetTransactionModeFilter(CBGStatementLine, strFilter, TransactionMode."Account Type"::Customer);
                            if strFilter <> '' then
                                CustLedgerEntry.SetFilter("Transaction Mode Code", strFilter);
                            OnMatchCBGStatementLineOnBeforeFindCustLedgEntries(CustLedgerEntry, CBGStatement, CBGStatementLine);
                            if CustLedgerEntry.FindSet() then
                                repeat
                                    CustLedgerEntry.CalcFields("Remaining Amount");
                                    if Abs(CBGStatementLine.Amount) =
                                       Abs(CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible")
                                    then begin
                                        EntriesCount += 1;
                                        EntryNo := CustLedgerEntry."Entry No.";
                                    end;
                                until (CustLedgerEntry.Next() = 0) or (EntriesCount > 1);
                            if EntriesCount = 1 then begin
                                CustLedgerEntry.Get(EntryNo);
                                CBGStatementLine."Applies-to Doc. Type" := CustLedgerEntry."Document Type";
                                CBGStatementLine."Applies-to Doc. No." := CustLedgerEntry."Document No.";
                                CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Applied;
                                NumberOfLinesApplied := NumberOfLinesApplied + 1;
                                if RecChanged then
                                    NumberOfLinesChanged := NumberOfLinesChanged - 1;
                                RecChanged := true;
                            end;
                        end;
                    CBGStatementLine."Account Type"::Vendor:
                        begin
                            VendorLedgerEntry.Reset();
                            VendorLedgerEntry.SetCurrentKey("Vendor No.", Open);
                            VendorLedgerEntry.SetRange("Vendor No.", CBGStatementLine."Account No.");
                            VendorLedgerEntry.SetRange(Open, true);
                            VendorLedgerEntry.SetFilter("Document Type", '<>%1', VendorLedgerEntry."Document Type"::Payment);
                            GetTransactionModeFilter(CBGStatementLine, strFilter, TransactionMode."Account Type"::Vendor);
                            if strFilter <> '' then
                                VendorLedgerEntry.SetFilter("Transaction Mode Code", strFilter);
                            OnMatchCBGStatementLineOnBeforeFindVendLedgEntries(VendorLedgerEntry, CBGStatement, CBGStatementLine);
                            if VendorLedgerEntry.FindSet() then
                                repeat
                                    VendorLedgerEntry.CalcFields("Remaining Amount");
                                    if Abs(CBGStatementLine.Amount) =
                                       Abs(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible")
                                    then begin
                                        EntriesCount += 1;
                                        EntryNo := VendorLedgerEntry."Entry No.";
                                    end;
                                until (VendorLedgerEntry.Next() = 0) or (EntriesCount > 1);
                            if EntriesCount = 1 then begin
                                VendorLedgerEntry.Get(EntryNo);
                                CBGStatementLine."Applies-to Doc. Type" := VendorLedgerEntry."Document Type";
                                CBGStatementLine."Applies-to Doc. No." := VendorLedgerEntry."Document No.";
                                CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Applied;
                                NumberOfLinesApplied := NumberOfLinesApplied + 1;
                                if RecChanged then
                                    NumberOfLinesChanged := NumberOfLinesChanged - 1;
                                RecChanged := true;
                            end;
                        end;
                    CBGStatementLine."Account Type"::Employee:
                        begin
                            EmployeeLedgerEntry.Reset();
                            EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open);
                            EmployeeLedgerEntry.SetRange("Employee No.", CBGStatementLine."Account No.");
                            EmployeeLedgerEntry.SetRange(Open, true);
                            EmployeeLedgerEntry.SetFilter("Document Type", '<>%1', EmployeeLedgerEntry."Document Type"::Payment);
                            GetTransactionModeFilter(CBGStatementLine, strFilter, TransactionMode."Account Type"::Employee);
                            if strFilter <> '' then
                                EmployeeLedgerEntry.SetFilter("Transaction Mode Code", strFilter);
                            OnMatchCBGStatementLineOnBeforeFindEmployeeLedgEntries(EmployeeLedgerEntry, CBGStatement, CBGStatementLine);
                            if EmployeeLedgerEntry.FindSet() then
                                repeat
                                    EmployeeLedgerEntry.CalcFields("Remaining Amount");
                                    if (CBGStatementLine.Credit = EmployeeLedgerEntry."Remaining Amount") or
                                       (-CBGStatementLine.Debit = EmployeeLedgerEntry."Remaining Amount")
                                    then begin
                                        EntriesCount += 1;
                                        EntryNo := EmployeeLedgerEntry."Entry No.";
                                    end;
                                until (EmployeeLedgerEntry.Next() = 0) or (EntriesCount > 1);
                            if EntriesCount = 1 then begin
                                EmployeeLedgerEntry.Get(EntryNo);
                                CBGStatementLine."Applies-to Doc. Type" := EmployeeLedgerEntry."Document Type";
                                CBGStatementLine."Applies-to Doc. No." := EmployeeLedgerEntry."Document No.";
                                CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Applied;
                                NumberOfLinesApplied := NumberOfLinesApplied + 1;
                                if RecChanged then
                                    NumberOfLinesChanged := NumberOfLinesChanged - 1;
                                RecChanged := true;
                            end;
                        end;
                end;

        OnMatchCBGStatementLineOnBeforeModify(
          CBGStatementLine, NumberOfLinesChanged, RecChanged, EntriesCount, EntryNo, CBGStatement, NumberOfLinesApplied, strFilter);

        if RecChanged then
            CBGStatementLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SplitAccountNumber(strBuf: Text[250])
    var
        AccNo: Text[30];
    begin
        if LocalFunctionalityMgt.CheckBankAccNo(CopyStr(strBuf, 1, 30), '', AccNo) then
            AddPossibleBankAccount(AccNo);
    end;

    [Scope('OnPrem')]
    procedure FindAccountNumber("Account Name": Code[80]; "Source Type": Integer; var Sourcenumber: Code[20]) Found: Boolean
    begin
        if "Account Name" = '' then
            exit(false);

        TempReconciliationBuffer.SetRange("Data Type", TempReconciliationBuffer."Data Type"::Bankaccount);
        TempReconciliationBuffer.SetRange("Source Type", "Source Type");
        TempReconciliationBuffer.SetRange(Word, "Account Name");
        if TempReconciliationBuffer.Find('-') then begin
            Sourcenumber := TempReconciliationBuffer."Source No.";
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindNAC(Name: Code[80]; Address: Code[80]; City: Code[80]; "Source Type": Integer; var SourcenumberFound: Code[20]) Found: Boolean
    var
        NameResultTemp: Record "Reconciliation Buffer" temporary;
        AddressResultTemp: Record "Reconciliation Buffer" temporary;
        CityResultTemp: Record "Reconciliation Buffer" temporary;
    begin
        Found := false;

        if (Name = '') or (Address = '') or (City = '') then
            exit(false);

        NameResultTemp.SetCurrentKey("Source Type", "Source No.");
        AddressResultTemp.SetCurrentKey("Source Type", "Source No.");
        CityResultTemp.SetCurrentKey("Source Type", "Source No.");

        TempReconciliationBuffer.SetRange("Source Type", "Source Type");
        TempReconciliationBuffer.SetRange("Data Type", TempReconciliationBuffer."Data Type"::Name);
        TempReconciliationBuffer.SetRange(Word, CopyStr(Name, 1, MaxStrLen(TempReconciliationBuffer.Word)));
        if TempReconciliationBuffer.Find('-') then
            repeat
                NameResultTemp := TempReconciliationBuffer;
                NameResultTemp.Insert();
            until TempReconciliationBuffer.Next() = 0;

        TempReconciliationBuffer.Reset();
        TempReconciliationBuffer.SetRange("Source Type", "Source Type");
        TempReconciliationBuffer.SetRange("Data Type", TempReconciliationBuffer."Data Type"::Street);
        TempReconciliationBuffer.SetRange(Word, CopyStr(Address, 1, MaxStrLen(TempReconciliationBuffer.Word)));
        if TempReconciliationBuffer.Find('-') then
            repeat
                NameResultTemp.SetRange("Source Type", TempReconciliationBuffer."Source Type");
                NameResultTemp.SetRange("Source No.", TempReconciliationBuffer."Source No.");
                if NameResultTemp.FindFirst() then begin
                    AddressResultTemp := NameResultTemp;
                    AddressResultTemp.Insert();
                end;
            until TempReconciliationBuffer.Next() = 0;

        TempReconciliationBuffer.Reset();
        TempReconciliationBuffer.SetRange("Source Type", "Source Type");
        TempReconciliationBuffer.SetRange("Data Type", TempReconciliationBuffer."Data Type"::City);
        TempReconciliationBuffer.SetRange(Word, CopyStr(City, 1, MaxStrLen(TempReconciliationBuffer.Word)));
        if TempReconciliationBuffer.Find('-') then
            repeat
                AddressResultTemp.SetRange("Source Type", TempReconciliationBuffer."Source Type");
                AddressResultTemp.SetRange("Source No.", TempReconciliationBuffer."Source No.");
                if AddressResultTemp.FindFirst() then begin
                    CityResultTemp := AddressResultTemp;
                    CityResultTemp.Insert();
                end;
            until TempReconciliationBuffer.Next() = 0;

        if CityResultTemp.Find('-') then begin
            SourcenumberFound := CityResultTemp."Source No.";
            Found := CityResultTemp.Next() = 0;
        end;
    end;

    local procedure MakeTempfile()
    var
        NumberRec: Integer;
        RecNumerator: Integer;
    begin
        BankAccountCharsToKeep := 'ABCDEFGHIJKLMNOPQRSTUVWYXZ0123456789';
        TempReconciliationBuffer.Reset();
        if not TempReconciliationBuffer.Find('-') then begin
            NumberRec := Customer.Count + Vendor.Count + CustomerBankAccount.Count + VendorBankAccount.Count + Employee.Count();

            if Customer.Find('-') then
                repeat
                    RecNumerator := RecNumerator + 1;
                    StatusWindowUpdate(1, Round(RecNumerator / NumberRec * 10000, 1));
                    InsertTempfileRecord(
                      Customer.Name, TempReconciliationBuffer."Source Type"::Customer, Customer."No.",
                      TempReconciliationBuffer."Data Type"::Name);
                    InsertTempfileRecord(
                      Customer.Address, TempReconciliationBuffer."Source Type"::Customer, Customer."No.",
                      TempReconciliationBuffer."Data Type"::Street);
                    InsertTempfileRecord(
                      Customer.City, TempReconciliationBuffer."Source Type"::Customer, Customer."No.",
                      TempReconciliationBuffer."Data Type"::City);
                until Customer.Next() = 0;

            if Vendor.Find('-') then
                repeat
                    RecNumerator := RecNumerator + 1;
                    StatusWindowUpdate(1, Round(RecNumerator / NumberRec * 10000, 1));
                    InsertTempfileRecord(
                      Vendor.Name, TempReconciliationBuffer."Source Type"::Vendor, Vendor."No.",
                      TempReconciliationBuffer."Data Type"::Name);
                    InsertTempfileRecord(
                      Vendor.Address, TempReconciliationBuffer."Source Type"::Vendor, Vendor."No.",
                      TempReconciliationBuffer."Data Type"::Street);
                    InsertTempfileRecord(
                      Vendor.City, TempReconciliationBuffer."Source Type"::Vendor, Vendor."No.",
                      TempReconciliationBuffer."Data Type"::City);
                until Vendor.Next() = 0;

            if Employee.Find('-') then
                repeat
                    RecNumerator := RecNumerator + 1;
                    StatusWindowUpdate(1, Round(RecNumerator / NumberRec * 10000, 1));
                    InsertTempfileRecord(
                      CopyStr(Employee.FullName(), 1, MaxStrLen(TempReconciliationBuffer.Word)),
                      TempReconciliationBuffer."Source Type"::Employee, Employee."No.",
                      TempReconciliationBuffer."Data Type"::Name);
                    InsertTempfileRecord(
                      Employee.Address, TempReconciliationBuffer."Source Type"::Employee, Employee."No.",
                      TempReconciliationBuffer."Data Type"::Street);
                    InsertTempfileRecord(
                      Employee.City, TempReconciliationBuffer."Source Type"::Employee, Employee."No.",
                      TempReconciliationBuffer."Data Type"::City);
                until Employee.Next() = 0;

            if CustomerBankAccount.Find('-') then
                repeat
                    RecNumerator := RecNumerator + 1;
                    StatusWindowUpdate(1, Round(RecNumerator / NumberRec * 10000, 1));

                    InsertTempfileRecord(
                      LocalFunctionalityMgt.CharacterFilter(CustomerBankAccount."Bank Account No.", BankAccountCharsToKeep),
                      TempReconciliationBuffer."Source Type"::Customer, CustomerBankAccount."Customer No.",
                      TempReconciliationBuffer."Data Type"::Bankaccount);
                    InsertTempfileRecord(
                      LocalFunctionalityMgt.CharacterFilter(CustomerBankAccount.IBAN, BankAccountCharsToKeep),
                      TempReconciliationBuffer."Source Type"::Customer, CustomerBankAccount."Customer No.",
                      TempReconciliationBuffer."Data Type"::Bankaccount);
                until CustomerBankAccount.Next() = 0;

            if VendorBankAccount.Find('-') then
                repeat
                    RecNumerator := RecNumerator + 1;
                    StatusWindowUpdate(1, Round(RecNumerator / NumberRec * 10000, 1));

                    InsertTempfileRecord(
                      LocalFunctionalityMgt.CharacterFilter(VendorBankAccount."Bank Account No.", BankAccountCharsToKeep),
                      TempReconciliationBuffer."Source Type"::Vendor, VendorBankAccount."Vendor No.",
                      TempReconciliationBuffer."Data Type"::Bankaccount);
                    InsertTempfileRecord(
                      LocalFunctionalityMgt.CharacterFilter(VendorBankAccount.IBAN, BankAccountCharsToKeep),
                      TempReconciliationBuffer."Source Type"::Vendor, VendorBankAccount."Vendor No.",
                      TempReconciliationBuffer."Data Type"::Bankaccount);
                until VendorBankAccount.Next() = 0;
        end;
    end;

    local procedure InsertTempfileRecord(Word: Code[250]; "Source Type": Integer; Sourcenumber: Code[20]; SortData: Integer)
    begin
        TempReconciliationBuffer.Word := CopyStr(Word, 1, MaxStrLen(TempReconciliationBuffer.Word));
        TempReconciliationBuffer."Source Type" := "Source Type";
        TempReconciliationBuffer."Source No." := Sourcenumber;
        TempReconciliationBuffer."Data Type" := SortData;
        if TempReconciliationBuffer.Insert(true) then;
    end;

    [Scope('OnPrem')]
    procedure StatusWindowOpen()
    begin
        if not StatusWindowOpened then begin
            Window.Open(Text1000000 +
              StrSubstNo(Text1000001 +
                Text1000002 +
                Text1000003 +
                Text1000004 +
                Text1000005 +
                Text1000006 +
                Text1000007));
            StatusWindowOpened := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure StatusWindowUpdate("Field": Integer; Value: Integer)
    begin
        if StatusWindowOpened then begin
            Window.Update(Field, Value);
            Window.Update(3, NumberOfDocumentNumbers);
            Window.Update(4, NumberOfLinesProcessed);
            Window.Update(5, NumberOfLinesChanged);
            Window.Update(6, NumberOfLinesApplied);
        end;
    end;

    [Scope('OnPrem')]
    procedure StatusWindowClose()
    var
        strFinalresult: Text[250];
    begin
        if StatusWindowOpened then begin
            Window.Close();

            if not HideMessages then begin
                if NumberOfDocumentNumbers = 1 then begin
                    strFinalresult := Text1000008;
                    if NumberOfLinesProcessed = 1 then
                        strFinalresult := strFinalresult + Text1000009
                    else
                        strFinalresult := strFinalresult + StrSubstNo(Text1000010, NumberOfLinesProcessed);
                end else begin
                    strFinalresult := StrSubstNo(Text1000011);
                    if NumberOfLinesProcessed = 1 then
                        strFinalresult := strFinalresult + Text1000012
                    else
                        strFinalresult := strFinalresult + StrSubstNo(Text1000013, NumberOfLinesProcessed);
                end;
                strFinalresult := strFinalresult + StrSubstNo(Text1000014, NumberOfLinesChanged);
                strFinalresult := strFinalresult + StrSubstNo(Text1000015, NumberOfLinesApplied);

                Message(strFinalresult);
            end;
            StatusWindowOpened := false;
            TempReconciliationBuffer.Reset();
            TempReconciliationBuffer.DeleteAll(false);
            ResetNumbers();
        end;
    end;

    procedure ResetNumbers()
    begin
        NumberOfDocumentNumbers := 0;
        NumberOfLinesProcessed := 0;
        NumberOfLinesChanged := 0;
        NumberOfLinesApplied := 0;
    end;

    local procedure GetTransactionModeFilter(var CBGStatementLine: Record "CBG Statement Line"; var TransactionModeFilter: Text[250]; Account_Type: Integer)
    var
        CBGStatement: Record "CBG Statement";
    begin
        TransactionModeFilter := '';
        if CBGStatement.Get(CBGStatementLine."Journal Template Name", CBGStatementLine."No.") then begin
            TransactionMode.SetRange("Account Type", Account_Type);
            TransactionMode.SetRange("Our Bank", CBGStatement."Account No.");
            if TransactionMode.Find('-') then begin
                TransactionModeFilter := '''''';
                repeat
                    TransactionModeFilter := TransactionModeFilter + '|' + TransactionMode.Code;
                until TransactionMode.Next() = 0;
            end;
        end;
    end;

    procedure SetHideMessages(HideMessages2: Boolean)
    begin
        HideMessages := HideMessages2;
    end;

    local procedure AddPossibleBankAccount(AccountNumber: Text[80])
    begin
        TempBankAccount.Init();
        TempBankAccount.Validate(TempBankAccount."No.", Format(TempBankAccount.Count + 1));
        TempBankAccount.IBAN := LocalFunctionalityMgt.CharacterFilter(AccountNumber, BankAccountCharsToKeep);
        TempBankAccount.Insert();
    end;

    local procedure ProcessPostDesRecDescription(CBGStatementLine: Record "CBG Statement Line")
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        TempBankAccount.DeleteAll();
        Clear(TempBankAccount);
        Clear(Name);
        Clear(Address);
        Clear(City);
        Clear(Identification);

        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatementLine."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", CBGStatementLine."No.");
        CBGStatementLineAddInfo.SetRange("CBG Statement Line No.", CBGStatementLine."Line No.");

        if CBGStatementLineAddInfo.FindSet() then
            repeat
                case CBGStatementLineAddInfo."Information Type" of
                    CBGStatementLineAddInfo."Information Type"::"Description and Sundries":
                        SplitAccountNumber(CBGStatementLineAddInfo.Description);
                    CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account":
                        AddPossibleBankAccount(CBGStatementLineAddInfo.Description);
                    CBGStatementLineAddInfo."Information Type"::"Name Acct. Holder":
                        Name := CBGStatementLineAddInfo.Description;
                    CBGStatementLineAddInfo."Information Type"::"Address Acct. Holder":
                        Address := CBGStatementLineAddInfo.Description;
                    CBGStatementLineAddInfo."Information Type"::"City Acct. Holder":
                        City := CBGStatementLineAddInfo.Description;
                    CBGStatementLineAddInfo."Information Type"::"Payment Identification":
                        Identification := CBGStatementLineAddInfo.Description;
                    else
                        OnProcessPostDesRecDescriptionCaseElse(CBGStatementLineAddInfo)
                end;
            until CBGStatementLineAddInfo.Next() = 0;
    end;

    local procedure UpdateAccount(var CBGStatementLine: Record "CBG Statement Line"; var NumberOfLinesChanged: Integer; var RecChanged: Boolean)
    begin
        OnBeforeUpdateAccount(CBGStatementLine, Identification, NumberOfLinesChanged, RecChanged);
        if CBGStatementLine."Account No." = '' then begin
            if TempBankAccount.FindFirst() then
                repeat
                    if CBGStatementLine.Credit > 0 then
                        if FindAccountNumber(TempBankAccount.IBAN, TempReconciliationBuffer."Source Type"::Customer, CBGStatementLine."Account No.") then begin
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Customer;
                            CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                            CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                            NumberOfLinesChanged := NumberOfLinesChanged + 1;
                            RecChanged := true;
                        end;

                    if not RecChanged and (CBGStatementLine.Credit <= 0) then
                        if FindAccountNumber(TempBankAccount.IBAN, TempReconciliationBuffer."Source Type"::Vendor, CBGStatementLine."Account No.") then begin
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Vendor;
                            CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                            CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                            NumberOfLinesChanged := NumberOfLinesChanged + 1;
                            RecChanged := true;
                        end;

                    if not RecChanged and (CBGStatementLine.Credit <= 0) then
                        if FindAccountNumber(TempBankAccount.IBAN, TempReconciliationBuffer."Source Type"::Employee, CBGStatementLine."Account No.") then begin
                            CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Employee;
                            CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                            CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                            NumberOfLinesChanged := NumberOfLinesChanged + 1;
                            RecChanged := true;
                        end;
                until TempBankAccount.Next() = 0;

            OnUpdateAccountOnBeforeFindNAC(CBGStatementLine, NumberOfLinesChanged, RecChanged);
            if not RecChanged then begin
                if CBGStatementLine.Credit > 0 then
                    if FindNAC(Name, Address, City, TempReconciliationBuffer."Source Type"::Customer, CBGStatementLine."Account No.") then begin
                        CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Customer;
                        CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                        CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                        NumberOfLinesChanged := NumberOfLinesChanged + 1;
                        RecChanged := true;
                    end;

                if not RecChanged and (CBGStatementLine.Credit <= 0) then
                    if FindNAC(Name, Address, City, TempReconciliationBuffer."Source Type"::Vendor, CBGStatementLine."Account No.") then begin
                        CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Vendor;
                        CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                        CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                        NumberOfLinesChanged := NumberOfLinesChanged + 1;
                        RecChanged := true;
                    end;

                if not RecChanged and (CBGStatementLine.Credit <= 0) then
                    if FindNAC(Name, Address, City, TempReconciliationBuffer."Source Type"::Employee, CBGStatementLine."Account No.") then begin
                        CBGStatementLine."Account Type" := CBGStatementLine."Account Type"::Employee;
                        CBGStatementLine.Validate("Account No.", CBGStatementLine."Account No.");
                        CBGStatementLine."Reconciliation Status" := CBGStatementLine."Reconciliation Status"::Changed;
                        NumberOfLinesChanged := NumberOfLinesChanged + 1;
                        RecChanged := true;
                    end;
            end;
        end;
        OnAfterUpdateAccount(CBGStatementLine, NumberOfLinesChanged, RecChanged);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchCBGStatement(var CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAccount(var CBGStatementLine: Record "CBG Statement Line"; var NumberOfLinesChanged: Integer; var RecChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAccount(var CBGStatementLine: Record "CBG Statement Line"; var Identification: Code[80]; var NumberOfLinesChanged: Integer; var RecChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementOnBeforeCBGStatementLineFind(var CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementLineOnAfterCheckIdentificationFilled(CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; PaymentHistoryFound: Boolean; var NumberOfLinesApplied: Integer; var NumberOfLinesChanged: Integer; var RecChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementLineOnBeforeFindCustLedgEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CBGStatement: Record "CBG Statement"; CBGStatementLine: Record "CBG Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementLineOnBeforeFindEmployeeLedgEntries(var EmployeeLedgEntry: Record "Employee Ledger Entry"; CBGStatement: Record "CBG Statement"; CBGStatementLine: Record "CBG Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementLineOnBeforeFindVendLedgEntries(var VendLedgEntry: Record "Vendor Ledger Entry"; CBGStatement: Record "CBG Statement"; CBGStatementLine: Record "CBG Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchCBGStatementLineOnBeforeModify(var CBGStatementLine: Record "CBG Statement Line"; var NumberOfLinesChanged: Integer; var RecChanged: Boolean; var EntriesCount: Integer; EntryNo: Integer; CBGStatement: Record "CBG Statement"; var NumberOfLinesApplied: Integer; var TransactionModeFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAccountOnBeforeFindNAC(var CBGStatementLine: Record "CBG Statement Line"; var NumberOfLinesChanged: Integer; var RecChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPostDesRecDescriptionCaseElse(CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.")
    begin
    end;
}

