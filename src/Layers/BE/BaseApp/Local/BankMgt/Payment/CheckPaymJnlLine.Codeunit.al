// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 2000001 CheckPaymJnlLine
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'There are payment journal lines with different posting dates.';
        Text002: Label ' is not within your range of allowed posting dates';
        GLSetup: Record "General Ledger Setup";
        ExportCheckErrorLog: Record "Export Check Error Log" temporary;
        TempGroupPmtJnlLine: Record "Payment Journal Line" temporary;
        Country: Record "Country/Region";
        BankAcc: Record "Bank Account";
        ErrorId: Integer;
        Text003: Label 'The export number series cannot be blank in export protocol %1.';
        Text004: Label 'There are no payment records to be processed.';
        Text005: Label 'The amount must be positive for %1 %2 and beneficiary bank account %3.', Comment = 'Parameter 1 - account type (,Customer,Vendor), 2 - account number, 3 - beneficiary bank account number.';
        Text006: Label 'The currency must be euro in payment journal line number %1.';
        Text007: Label 'The currency cannot be euro in payment journal line number %1.';
        Text010: Label 'The %1 field cannot be blank in payment journal line number %2.';
        Text011: Label 'The %1 field cannot be blank for bank account number %2 in payment journal line number %3.';
        Text012: Label 'The SEPA Allowed field cannot be %1 for country/region code %2 in payment journal line number %3.', Comment = 'Parameter 1 - boolean value, 2 - country\region code, 3 - integer number.';
        Text013: Label 'Company name cannot be blank.';
        Text014: Label 'The Name field cannot be blank for customer %1 in payment journal line number %2.';
        Text015: Label 'The Name field cannot be blank for vendor %1 in payment journal line number %2.';

    procedure CheckPostingDate(var PaymentJnlLine: Record "Payment Journal Line"; TemplateName: Code[20])
    var
        PaymJnlLine: Record "Payment Journal Line";
        CheckJnlLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        PaymJnlLine.Reset();
        PaymJnlLine.CopyFilters(PaymentJnlLine);
        if PaymJnlLine.Find('-') then
            PaymJnlLine.SetRange("Posting Date", PaymJnlLine."Posting Date");
        if PaymJnlLine.Count <> PaymentJnlLine.Count then
            Error(Text001);
        PaymJnlLine.SetRange("Posting Date");
        if PaymJnlLine.Find('-') then
            repeat
                PaymJnlLine.TestField("Posting Date");
                if CheckJnlLine.DateNotAllowed(PaymJnlLine."Posting Date", TemplateName) then
                    PaymJnlLine.FieldError("Posting Date", Text002);
            until PaymJnlLine.Next() = 0;
    end;

    procedure Init()
    begin
        GLSetup.Get();
        ClearErrorLog();
        TempGroupPmtJnlLine.Reset();
        TempGroupPmtJnlLine.DeleteAll();
    end;

    procedure ClearErrorLog()
    begin
        ExportCheckErrorLog.Reset();
        ExportCheckErrorLog.DeleteAll();
    end;

    procedure InsertErrorLog(ErrorMessage: Text[250])
    begin
        if ExportCheckErrorLog.FindLast() then
            ErrorId := ExportCheckErrorLog."Entry No." + 1
        else
            ErrorId := 1;

        ExportCheckErrorLog.Init();
        ExportCheckErrorLog."Entry No." := ErrorId;
        ExportCheckErrorLog."Error Message" := ErrorMessage;
        ExportCheckErrorLog.Insert();
    end;

    procedure ShowErrorLog()
    begin
        if not ExportCheckErrorLog.IsEmpty() then begin
            PAGE.Run(PAGE::"Export Check Error Logs", ExportCheckErrorLog);
            Error('');
        end;
    end;

    procedure CheckExportProtocol(ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Get(ExportProtocolCode);
        if ExportProtocol."Export No. Series" = '' then
            InsertErrorLog(StrSubstNo(Text003, ExportProtocol.Code));
    end;

    procedure ErrorNoPayments()
    begin
        InsertErrorLog(Text004);
    end;

    procedure FillGroupLineAmountBuf(PmtJnlLine: Record "Payment Journal Line")
    var
        LastLineNo: Integer;
    begin
        TempGroupPmtJnlLine.Reset();
        if TempGroupPmtJnlLine.FindLast() then
            LastLineNo := TempGroupPmtJnlLine."Line No.";

        TempGroupPmtJnlLine.SetRange("Account Type", PmtJnlLine."Account Type");
        TempGroupPmtJnlLine.SetRange("Account No.", PmtJnlLine."Account No.");
        TempGroupPmtJnlLine.SetRange("Bank Account", PmtJnlLine."Bank Account");
        TempGroupPmtJnlLine.SetRange("Beneficiary Bank Account", PmtJnlLine."Beneficiary Bank Account");
        TempGroupPmtJnlLine.SetRange("Separate Line", PmtJnlLine."Separate Line");
        OnFillGroupLineAmountBufOnAfterApplyFilters(TempGroupPmtJnlLine, PmtJnlLine);
        if not TempGroupPmtJnlLine.FindFirst() or PmtJnlLine."Separate Line" then begin
            TempGroupPmtJnlLine.Init();
            TempGroupPmtJnlLine."Line No." := LastLineNo + 1;
            TempGroupPmtJnlLine."Account Type" := PmtJnlLine."Account Type";
            TempGroupPmtJnlLine."Account No." := PmtJnlLine."Account No.";
            TempGroupPmtJnlLine."Bank Account" := PmtJnlLine."Bank Account";
            TempGroupPmtJnlLine."Beneficiary Bank Account" := PmtJnlLine."Beneficiary Bank Account";
            TempGroupPmtJnlLine."Separate Line" := PmtJnlLine."Separate Line";
            OnFillGroupLineAmountBufOnBeforeInsert(TempGroupPmtJnlLine, PmtJnlLine);
            TempGroupPmtJnlLine.Insert();
        end;
        TempGroupPmtJnlLine.Amount := TempGroupPmtJnlLine.Amount + PmtJnlLine.Amount;
        TempGroupPmtJnlLine.Modify();
    end;

    procedure CheckTotalLineAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTotalLineAmounts(TempGroupPmtJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempGroupPmtJnlLine.Reset();
        TempGroupPmtJnlLine.SetFilter(Amount, '<=%1', 0);
        if TempGroupPmtJnlLine.FindSet() then
            repeat
                InsertErrorLog(
                  StrSubstNo(Text005, TempGroupPmtJnlLine."Account Type", TempGroupPmtJnlLine."Account No.", TempGroupPmtJnlLine."Beneficiary Bank Account"));
            until TempGroupPmtJnlLine.Next() = 0;
    end;

    procedure ErrorIfCurrencyNotEuro(PmtJnlLine: Record "Payment Journal Line")
    begin
        if PmtJnlLine."Currency Code" <> GLSetup."Currency Euro" then
            InsertErrorLog(StrSubstNo(Text006, PmtJnlLine."Line No."));
    end;

    procedure ErrorIfCurrencyEuro(PmtJnlLine: Record "Payment Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorIfCurrencyEuro(PmtJnlLine, IsHandled);
        if IsHandled then
            exit;

        if PmtJnlLine."Currency Code" = GLSetup."Currency Euro" then
            InsertErrorLog(StrSubstNo(Text007, PmtJnlLine."Line No."));
    end;

    procedure CheckBankForSEPA(PmtJnlLine: Record "Payment Journal Line")
    begin
        if not ErrorEmptyFieldInLine(PmtJnlLine."Line No.", PmtJnlLine."Bank Account", PmtJnlLine.FieldCaption("Bank Account")) then begin
            GetBankAccount(PmtJnlLine."Bank Account");
            ErrorEmptyFieldInBank(PmtJnlLine, BankAcc.IBAN, BankAcc.FieldCaption(IBAN));
            ErrorEmptyFieldInBank(PmtJnlLine, BankAcc."SWIFT Code", BankAcc.FieldCaption("SWIFT Code"));

            if not ErrorEmptyFieldInBank(PmtJnlLine, BankAcc."Country/Region Code", BankAcc.FieldCaption("Country/Region Code")) then
                CheckSEPAAllowed(true, PmtJnlLine."Line No.", BankAcc."Country/Region Code");
        end;
    end;

    procedure CheckBeneficiaryBankForSEPA(PmtJnlLine: Record "Payment Journal Line"; EuroSEPA: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBeneficiaryBankForSEPA(PmtJnlLine, EuroSEPA, IsHandled);
        if IsHandled then
            exit;

        CheckIBANForSEPA(PmtJnlLine, EuroSEPA);
        if IsForeignBank(PmtJnlLine."Bank Account") then
            ErrorEmptyFieldInLine(PmtJnlLine."Line No.", PmtJnlLine."SWIFT Code", PmtJnlLine.FieldCaption("SWIFT Code"));

        if not ErrorEmptyFieldInLine(PmtJnlLine."Line No.", PmtJnlLine."Bank Country/Region Code", PmtJnlLine.FieldCaption("Bank Country/Region Code")) then
            CheckSEPAAllowed(EuroSEPA, PmtJnlLine."Line No.", PmtJnlLine."Bank Country/Region Code");
    end;

    local procedure CheckIBANForSEPA(PmtJnlLine: Record "Payment Journal Line"; EuroSEPA: Boolean)
    var
        IBANTransfer: Boolean;
    begin
        if EuroSEPA then
            ErrorEmptyFieldInLine(PmtJnlLine."Line No.", PmtJnlLine."Beneficiary IBAN", PmtJnlLine.FieldCaption("Beneficiary IBAN"))
        else begin
            GetCountry(PmtJnlLine."Bank Country/Region Code");
            IBANTransfer := (PmtJnlLine."Beneficiary IBAN" <> '') and Country."IBAN Country/Region";
            if not IBANTransfer then
                ErrorEmptyFieldInLine(PmtJnlLine."Line No.", PmtJnlLine."Beneficiary Bank Account No.", PmtJnlLine.FieldCaption("Beneficiary Bank Account No."));
        end;
    end;

    local procedure CheckSEPAAllowed(RequiredSEPAAllowed: Boolean; PmtJnlLineNo: Integer; CountryRegionCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSEPAAllowed(RequiredSEPAAllowed, PmtJnlLineNo, CountryRegionCode, IsHandled);
        if IsHandled then
            exit;

        GetCountry(CountryRegionCode);
        if not Country."SEPA Allowed" and RequiredSEPAAllowed then
            InsertErrorLog(StrSubstNo(Text012, Country."SEPA Allowed", CountryRegionCode, PmtJnlLineNo));
    end;

    local procedure ErrorEmptyFieldInLine(PmtJnlLineNo: Integer; Value: Text[50]; Caption: Text[30]): Boolean
    begin
        if Value = '' then begin
            InsertErrorLog(StrSubstNo(Text010, Caption, PmtJnlLineNo));
            exit(true);
        end;
    end;

    local procedure ErrorEmptyFieldInBank(PmtJnlLine: Record "Payment Journal Line"; Value: Text[50]; Caption: Text[30]): Boolean
    begin
        if Value = '' then begin
            InsertErrorLog(StrSubstNo(Text011, Caption, PmtJnlLine."Bank Account", PmtJnlLine."Line No."));
            exit(true);
        end;
    end;

    local procedure GetCountry(CountryCode: Code[10])
    begin
        if (Country.Code <> CountryCode) and (CountryCode <> '') then
            Country.Get(CountryCode);
    end;

    local procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if (BankAcc."No." <> BankAccCode) and (BankAccCode <> '') then
            BankAcc.Get(BankAccCode);
    end;

    procedure CheckCompanyName()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if DelChr(CompanyInfo.Name) = '' then
            InsertErrorLog(Text013);
    end;

    procedure CheckCustVendName(var PmtJnlLine: Record "Payment Journal Line")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case PmtJnlLine."Account Type" of
            PmtJnlLine."Account Type"::Vendor:
                if Vendor.Get(PmtJnlLine."Account No.") then
                    if DelChr(Vendor.Name) = '' then
                        InsertErrorLog(StrSubstNo(Text015, Vendor."No.", PmtJnlLine."Line No."));
            PmtJnlLine."Account Type"::Customer:
                if Customer.Get(PmtJnlLine."Account No.") then
                    if DelChr(Customer.Name) = '' then
                        InsertErrorLog(StrSubstNo(Text014, Customer."No.", PmtJnlLine."Line No."));
        end;
    end;

    local procedure IsForeignBank(BankAccNo: Code[20]): Boolean
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        if BankAccNo = '' then
            exit(false);
        BankAccount.Get(BankAccNo);
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code" <> BankAccount."Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTotalLineAmounts(var PaymentJournalLine: Record "Payment Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorIfCurrencyEuro(var PaymentJnlLine: Record "Payment Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSEPAAllowed(var RequiredSEPAAllowed: Boolean; PmtJnlLineNo: Integer; CountryRegionCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBeneficiaryBankForSEPA(var PaymentJournalLine: Record "Payment Journal Line"; var EuroSEPA: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGroupLineAmountBufOnAfterApplyFilters(var TempGroupPaymentJournalLine: Record "Payment Journal Line" temporary; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGroupLineAmountBufOnBeforeInsert(var TempGroupPaymentJournalLine: Record "Payment Journal Line" temporary; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;
}

