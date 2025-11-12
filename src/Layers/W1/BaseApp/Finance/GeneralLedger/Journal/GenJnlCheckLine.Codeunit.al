// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.CostAccounting.Setup;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Security.User;
using System.Utilities;

codeunit 11 "Gen. Jnl.-Check Line"
{
    Permissions = tabledata "General Posting Setup" = rimd,
                  tabledata "Cost Accounting Setup" = R,
                  tabledata "Payment Terms" = R;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CostAccSetup: Record "Cost Accounting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        DimMgt: Codeunit DimensionManagement;
        CostAccMgt: Codeunit "Cost Account Mgt";
        ApplicationAreaMgmt: Codeunit System.Environment.Configuration."Application Area Mgmt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
#if not CLEAN25
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
#endif
        SkipFiscalYearCheck: Boolean;
        GenJnlTemplateFound: Boolean;
        OverrideDimErr: Boolean;
        LogErrorMode: Boolean;
        IsBatchMode: Boolean;
        IgnoreJournalTemplNameMandatoryCheck: Boolean;
        IsDeferralPostingAllowed: Boolean;

#pragma warning disable AA0074
        Text000: Label 'can only be a closing date for G/L entries';
        Text001: Label 'is not within your range of allowed posting dates';
#pragma warning disable AA0470
        Text002: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text003: Label 'must have the same sign as %1';
        Text004: Label 'You must not specify %1 when %2 is %3.';
        Text005: Label '%1 + %2 must be %3.';
        Text006: Label '%1 + %2 must be -%3.';
#pragma warning restore AA0470
        Text007: Label 'must be positive';
        Text008: Label 'must be negative';
#pragma warning disable AA0470
        Text009: Label 'must have a different sign than %1';
        Text010: Label '%1 %2 and %3 %4 is not allowed.';
        Text011: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text012: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DuplicateRecordErr: Label 'Document No. %1 already exists. It is not possible to calculate new deferrals for a Document No. that already exists.', Comment = '%1=Document No.';
        SpecifyGenPostingTypeErr: Label 'Posting to Account %1 must either be of type Purchase or Sale (see %2), because there are specified values in one of the following fields: %3, %4 , %5, or %6', comment = '%1 an G/L Account number;%2 = Gen. Posting Type; %3 = Gen. Bus. Posting Group; %4 = Gen. Prod. Posting Group; %5 = VAT Bus. Posting Group, %6 = VAT Prod. Posting Group';
        SalesDocAlreadyExistsErr: Label 'Sales %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        PurchDocAlreadyExistsErr: Label 'Purchase %1 %2 already exists.', Comment = '%1 = Document Type; %2 = Document No.';
        EmployeeBalancingDocTypeErr: Label 'must be empty or set to Payment when Balancing Account Type field is set to Employee';
        EmployeeAccountDocTypeErr: Label 'must be empty or set to Payment when Account Type field is set to Employee';
        GLAccCurrencyDoesNotMatchErr: Label 'The currency code %1 on general journal line does not match with the currency code %2 of G/L account %3.', Comment = '%1 and %2 - currency code, %3 - G/L Account No.';
        GLAccSourceCurrencyDoesNotMatchErr: Label 'The currency code %1 on general journal line does not match with the any source currency code of G/L account %2.', Comment = '%1 - currency code, %2 - G/L Account No.';
        GLAccSourceCurrencyDoesNotAllowedErr: Label 'The currency code %1 on general journal line does not allowed for posting to G/L account %2.', Comment = '%1 - currency code, %2 - G/L Account No.';

    procedure RunCheck(var GenJnlLine: Record "Gen. Journal Line")
    var
        ICGLAcount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCheck(GenJnlLine, OverrideDimErr, IsHandled);
        if IsHandled then
            exit;

        if LogErrorMode then begin
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, GenJnlLine.RecordId, 0, '');
        end;

        GLSetup.Get();
        if GenJnlLine.EmptyLine() then
            exit;

        if not GenJnlTemplateFound then begin
            if GenJnlTemplate.Get(GenJnlLine."Journal Template Name") then;
            GenJnlTemplateFound := true;
        end;

        CheckDates(GenJnlLine);
        GenJnlLine.ValidateSalesPersonPurchaserCode(GenJnlLine);

        TestDocumentNo(GenJnlLine);

        TestAccountAndBalAccountType(GenJnlLine);

        if GenJnlLine."Bal. Account No." = '' then
            GenJnlLine.TestField("Account No.", ErrorInfo.Create());

        CheckZeroAmount(GenJnlLine);

        if ((GenJnlLine.Amount < 0) xor (GenJnlLine."Amount (LCY)" < 0)) and (GenJnlLine.Amount <> 0) and (GenJnlLine."Amount (LCY)" <> 0) then
            GenJnlLine.FieldError("Amount (LCY)", ErrorInfo.Create(StrSubstNo(Text003, GenJnlLine.FieldCaption(Amount)), true));

        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account")
        then
            CheckAppliesToDocNo(GenJnlLine);

        if (GenJnlLine."Recurring Method" in
            [GenJnlLine."Recurring Method"::"B  Balance", GenJnlLine."Recurring Method"::"RB Reversing Balance"]) and
           (GenJnlLine."Currency Code" <> '')
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text004,
                        GenJnlLine.FieldCaption("Currency Code"), GenJnlLine.FieldCaption("Recurring Method"), GenJnlLine."Recurring Method"),
                    true,
                    GenJnlLine,
                    GenJnlLine.FieldNo("Recurring Method")));

        if GenJnlLine."Account No." <> '' then
            CheckAccountNo(GenJnlLine);

        if GenJnlLine."Bal. Account No." <> '' then
            CheckBalAccountNo(GenJnlLine);
        if GenJnlLine."IC Account No." <> '' then begin
            if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"G/L Account" then
                if ICGLAcount.Get(GenJnlLine."IC Account No.") then
                    ICGLAcount.TestField(Blocked, false, ErrorInfo.Create());
            if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"Bank Account" then
                if ICBankAccount.Get(GenJnlLine."IC Account No.") then
                    ICBankAccount.TestField(Blocked, false, ErrorInfo.Create());
        end;

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and
            (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account")) or
           ((GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Invoice) and
            (not
             ((GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") and
              CalcPmtDiscOnCrMemos(GenJnlLine."Payment Terms Code"))))
        then begin
            GenJnlLine.TestField("Pmt. Discount Date", 0D, ErrorInfo.Create());
            GenJnlLine.TestField("Payment Discount %", 0, ErrorInfo.Create());
        end;

        TestAppliesToID(GenJnlLine);

        if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Bank Account") and
           (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"Bank Account")
        then
            GenJnlLine.TestField("Bank Payment Type", GenJnlLine."Bank Payment Type"::" ", ErrorInfo.Create());

        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset") or
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Fixed Asset")
        then
            CODEUNIT.Run(CODEUNIT::"FA Jnl.-Check Line", GenJnlLine);

        if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Fixed Asset") and
           (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"Fixed Asset")
        then begin
            GenJnlLine.TestField("Depreciation Book Code", '', ErrorInfo.Create());
            GenJnlLine.TestField("FA Posting Type", 0, ErrorInfo.Create());
        end;

        if GenJnlLine."Deferral Code" <> '' then
            CheckPostedDeferralHeaderExist(GenJnlLine);

        if not OverrideDimErr then
            CheckDimensions(GenJnlLine);

#if not CLEAN25
        if FeatureKeyManagement.IsGLCurrencyRevaluationEnabled() then
#endif
        CheckCurrencyCode(GenJnlLine);

        if CostAccSetup.Get() then
            CostAccMgt.CheckValidCCAndCOInGLEntry(GenJnlLine."Dimension Set ID");

        OnAfterCheckGenJnlLine(GenJnlLine, ErrorMessageMgt);

        if LogErrorMode then
            ErrorMessageMgt.GetErrors(TempErrorMessage);
    end;

    local procedure TestDocumentNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestDocumentNo(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.TestField("Document No.", ErrorInfo.Create());
    end;

    local procedure TestAccountAndBalAccountType(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestAccountAndBalAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine."Account Type" in
                 [GenJnlLine."Account Type"::Customer,
                  GenJnlLine."Account Type"::Vendor,
                  GenJnlLine."Account Type"::"Fixed Asset",
                  GenJnlLine."Account Type"::"IC Partner"]) and
                (GenJnlLine."Bal. Account Type" in
                 [GenJnlLine."Bal. Account Type"::Customer,
                  GenJnlLine."Bal. Account Type"::Vendor,
                  GenJnlLine."Bal. Account Type"::"Fixed Asset",
                  GenJnlLine."Bal. Account Type"::"IC Partner"])
             then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                    Text002,
                    GenJnlLine.FieldCaption("Account Type"), GenJnlLine.FieldCaption("Bal. Account Type")),
                true,
                GenJnlLine,
                GenJnlLine.FieldNo("Account Type")));
    end;

    local procedure TestAppliesToID(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestAppliesToID(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Applies-to Doc. No." <> '' then
            GenJnlLine.TestField("Applies-to ID", '', ErrorInfo.Create());
    end;

    procedure GetErrors(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    local procedure CalcPmtDiscOnCrMemos(PaymentTermsCode: Code[10]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode <> '' then begin
            PaymentTerms.Get(PaymentTermsCode);
            exit(PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");
        end;
    end;

    procedure DateNotAllowed(PostingDate: Date): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDateNotAllowed(PostingDate, SetupRecordID));
    end;

    procedure DeferralPostingDateNotAllowed(PostingDate: Date): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDeferralPostingDateNotAllowed(PostingDate, SetupRecordID));
    end;

    procedure DateNotAllowed(PostingDate: Date; TemplateName: Code[20]): Boolean
    var
        SetupRecordID: RecordID;
    begin
        exit(IsDateNotAllowed(PostingDate, SetupRecordID, TemplateName));
    end;

    procedure IsDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed := not UserSetupManagement.IsPostingDateValidWithSetup(PostingDate, SetupRecordID);
        OnAfterDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure IsDeferralPostingDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDeferralPostingDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed := not UserSetupManagement.IsDeferralPostingDateValidWithSetup(PostingDate, SetupRecordID);
        OnAfterDeferralPostingDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure IsDateNotAllowed(PostingDate: Date; var SetupRecordID: RecordID; TemplateName: Code[20]) DateIsNotAllowed: Boolean
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDateNotAllowed(PostingDate, SetupRecordID, GenJnlBatch, DateIsNotAllowed, IsHandled);
        if IsHandled then
            exit;

        DateIsNotAllowed :=
          not UserSetupManagement.IsPostingDateValidWithGenJnlTemplateWithSetup(PostingDate, TemplateName, SetupRecordID);
        OnAfterDateNoAllowed(PostingDate, DateIsNotAllowed);
        exit(DateIsNotAllowed);
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    procedure SetSkipFiscalYearCheck(NewValue: Boolean)
    begin
        SkipFiscalYearCheck := NewValue;
    end;

    procedure ErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount > 0;
        OnBeforeErrorIfPositiveAmt(GenJnlLine, RaiseError);
        if RaiseError then
            GenJnlLine.FieldError(Amount, ErrorInfo.Create(Text008, true));
    end;

    procedure ErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        RaiseError: Boolean;
    begin
        RaiseError := GenJnlLine.Amount < 0;
        OnBeforeErrorIfNegativeAmt(GenJnlLine, RaiseError);
        if RaiseError then
            GenJnlLine.FieldError(Amount, ErrorInfo.Create(Text007, true));
    end;

    procedure SetOverDimErr()
    begin
        OverrideDimErr := true;
    end;

    procedure SetIgnoreJournalTemplNameMandatoryCheck()
    begin
        IgnoreJournalTemplNameMandatoryCheck := true;
    end;

    local procedure CheckDates(GenJnlLine: Record "Gen. Journal Line")
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DateCheckDone: Boolean;
        IsHandled: Boolean;
    begin
        GenJnlLine.TestField("Posting Date", ErrorInfo.Create());
        if GenJnlLine."Posting Date" <> NormalDate(GenJnlLine."Posting Date") then begin
            if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"G/L Account") or
               (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"G/L Account")
            then
                GenJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text000, true));
            if not SkipFiscalYearCheck then begin
                IsHandled := false;
                OnBeforeCheckPostingDateInFiscalYear(GenJnlLine, IsHandled);
                if not IsHandled then
                    AccountingPeriodMgt.CheckPostingDateInFiscalYear(GenJnlLine."Posting Date");
            end;
        end;

        if not IgnoreJournalTemplNameMandatoryCheck then
            if GLSetup."Journal Templ. Name Mandatory" then
                GenJnlLine.TestField("Journal Template Name", ErrorInfo.Create());
        if IsDeferralPostingAllowed then begin
            if DeferralPostingDateNotAllowed(GenJnlLine."Posting Date") then
                GenJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text001, true));
            DateCheckDone := true
        end;
        OnBeforeDateNotAllowed(GenJnlLine, DateCheckDone);
        if not DateCheckDone then
            if DateNotAllowed(GenJnlLine."Posting Date", GenJnlLine."Journal Template Name") then
                GenJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text001, true));

        if GenJnlLine."Document Date" <> 0D then
            if (GenJnlLine."Document Date" <> NormalDate(GenJnlLine."Document Date")) and
               ((GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"G/L Account") or
                (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"G/L Account"))
            then
                GenJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));

        if HasVAT(GenJnlLine) then
            CheckVATDate(GenJnlLine);
    end;

    local procedure CheckAccountNo(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartner: Record "IC Partner";
        CheckDone: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCheckAccountNo(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                begin
                    if (((GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') or
                        (GenJnlLine."VAT Bus. Posting Group" <> '') or (GenJnlLine."VAT Prod. Posting Group" <> '')) and
                        (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::" "))
                    then
                        Error(
                            ErrorInfo.Create(
                                StrSubstNo(
                                    SpecifyGenPostingTypeErr, GenJnlLine."Account No.", GenJnlLine.FieldCaption("Gen. Posting Type"),
                                    GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("Gen. Prod. Posting Group"),
                                    GenJnlLine.FieldCaption("VAT Bus. Posting Group"), GenJnlLine.FieldCaption("VAT Prod. Posting Group")),
                                true,
                                GenJnlLine,
                                GenJnlLine.FieldNo("Gen. Posting Type")));

                    CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                    if (GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" ") and
                       (GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Automatic VAT Entry")
                    then begin
                        if GenJnlLine."VAT Amount" + GenJnlLine."VAT Base Amount" <> GenJnlLine.Amount then
                            Error(
                                ErrorInfo.Create(
                                    StrSubstNo(
                                        Text005, GenJnlLine.FieldCaption("VAT Amount"), GenJnlLine.FieldCaption("VAT Base Amount"),
                                        GenJnlLine.FieldCaption(Amount)),
                                    true,
                                    GenJnlLine,
                                    GenJnlLine.FieldNo("VAT Amount")));
                        if GenJnlLine."Currency Code" <> '' then
                            if GenJnlLine."VAT Amount (LCY)" + GenJnlLine."VAT Base Amount (LCY)" <> GenJnlLine."Amount (LCY)" then
                                Error(
                                    ErrorInfo.Create(
                                        StrSubstNo(
                                            Text005, GenJnlLine.FieldCaption("VAT Amount (LCY)"),
                                            GenJnlLine.FieldCaption("VAT Base Amount (LCY)"), GenJnlLine.FieldCaption("Amount (LCY)")),
                                        true,
                                        GenJnlLine,
                                        GenJnlLine.FieldNo("VAT Amount (LCY)")));
                    end;
                end;
            GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor, GenJnlLine."Account Type"::Employee:
                begin
                    GenJnlLine.TestField("Gen. Posting Type", 0, ErrorInfo.Create());
                    GenJnlLine.TestField("Gen. Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Gen. Prod. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("VAT Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("VAT Prod. Posting Group", '', ErrorInfo.Create());

                    CheckAccountType(GenJnlLine);

                    CheckDocType(GenJnlLine);

                    if not GenJnlLine."System-Created Entry" and
                       (((GenJnlLine.Amount < 0) xor (GenJnlLine."Sales/Purch. (LCY)" < 0)) and (GenJnlLine.Amount <> 0) and (GenJnlLine."Sales/Purch. (LCY)" <> 0))
                    then
                        GenJnlLine.FieldError("Sales/Purch. (LCY)", ErrorInfo.Create(StrSubstNo(Text003, GenJnlLine.FieldCaption(Amount)), true));
                    CheckJobNoIsEmpty(GenJnlLine);

                    IsHandled := false;
                    OnCheckAccountNoOnBeforeCheckICPartner(GenJnlLine, IsHandled);
                    if not IsHandled then
                        CheckICPartner(GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine);
                end;
            GenJnlLine."Account Type"::"Bank Account":
                begin
                    GenJnlLine.TestField("Gen. Posting Type", 0, ErrorInfo.Create());
                    GenJnlLine.TestField("Gen. Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Gen. Prod. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("VAT Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("VAT Prod. Posting Group", '', ErrorInfo.Create());
                    CheckJobNoIsEmpty(GenJnlLine);
                    if (GenJnlLine.Amount < 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") then
                        GenJnlLine.TestField("Check Printed", true, ErrorInfo.Create());
                    CheckElectronicPaymentFields(GenJnlLine);
                end;
            GenJnlLine."Account Type"::"IC Partner":
                begin
                    ICPartner.Get(GenJnlLine."Account No.");
                    ICPartner.CheckICPartner();
                    if GenJnlLine."Journal Template Name" <> '' then begin
                        GenJournalTemplate.Get(GenJnlLine."Journal Template Name");
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            GenJnlLine.FieldError("Account Type", ErrorInfo.Create());
                    end;
                end;
        end;

        OnAfterCheckAccountNo(GenJnlLine);
    end;

    local procedure CheckBalAccountNo(GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        CheckDone: Boolean;
    begin
        OnBeforeCheckBalAccountNo(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        case GenJnlLine."Bal. Account Type" of
            GenJnlLine."Bal. Account Type"::"G/L Account":
                begin
                    if ((GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') or
                        (GenJnlLine."Bal. VAT Bus. Posting Group" <> '') or (GenJnlLine."Bal. VAT Prod. Posting Group" <> '')) and
                       not ApplicationAreaMgmt.IsSalesTaxEnabled()
                    then
                        GenJnlLine.TestField("Bal. Gen. Posting Type", ErrorInfo.Create());

                    CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine);

                    if (GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" ") and
                       (GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Automatic VAT Entry")
                    then begin
                        if GenJnlLine."Bal. VAT Amount" + GenJnlLine."Bal. VAT Base Amount" <> -GenJnlLine.Amount then
                            Error(
                                ErrorInfo.Create(
                                    StrSubstNo(
                                        Text006, GenJnlLine.FieldCaption("Bal. VAT Amount"), GenJnlLine.FieldCaption("Bal. VAT Base Amount"),
                                        GenJnlLine.FieldCaption(Amount)),
                                    true,
                                    GenJnlLine,
                                    GenJnlLine.FieldNo("Bal. VAT Amount")));
                        if GenJnlLine."Currency Code" <> '' then
                            if GenJnlLine."Bal. VAT Amount (LCY)" + GenJnlLine."Bal. VAT Base Amount (LCY)" <> -GenJnlLine."Amount (LCY)" then
                                Error(
                                    ErrorInfo.Create(
                                        StrSubstNo(
                                            Text006, GenJnlLine.FieldCaption("Bal. VAT Amount (LCY)"),
                                            GenJnlLine.FieldCaption("Bal. VAT Base Amount (LCY)"), GenJnlLine.FieldCaption("Amount (LCY)")),
                                                            true,
                                    GenJnlLine,
                                    GenJnlLine.FieldNo("Bal. VAT Amount (LCY)")));
                    end;
                end;
            GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor, GenJnlLine."Bal. Account Type"::Employee:
                begin
                    GenJnlLine.TestField("Bal. Gen. Posting Type", 0, ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. Gen. Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. Gen. Prod. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. VAT Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. VAT Prod. Posting Group", '', ErrorInfo.Create());

                    CheckBalAccountType(GenJnlLine);

                    CheckBalDocType(GenJnlLine);

                    if ((GenJnlLine.Amount > 0) xor (GenJnlLine."Sales/Purch. (LCY)" < 0)) and (GenJnlLine.Amount <> 0) and (GenJnlLine."Sales/Purch. (LCY)" <> 0) then
                        GenJnlLine.FieldError("Sales/Purch. (LCY)", ErrorInfo.Create(StrSubstNo(Text009, GenJnlLine.FieldCaption(Amount)), true));
                    CheckJobNoIsEmpty(GenJnlLine);

                    CheckICPartner(GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.", GenJnlLine."Document Type", GenJnlLine);
                end;
            GenJnlLine."Bal. Account Type"::"Bank Account":
                begin
                    GenJnlLine.TestField("Bal. Gen. Posting Type", 0, ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. Gen. Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. Gen. Prod. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. VAT Bus. Posting Group", '', ErrorInfo.Create());
                    GenJnlLine.TestField("Bal. VAT Prod. Posting Group", '', ErrorInfo.Create());
                    if (GenJnlLine.Amount > 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") then
                        GenJnlLine.TestField("Check Printed", true, ErrorInfo.Create());
                    CheckElectronicPaymentFields(GenJnlLine);
                end;
            GenJnlLine."Bal. Account Type"::"IC Partner":
                begin
                    ICPartner.Get(GenJnlLine."Bal. Account No.");
                    ICPartner.CheckICPartner();
                    if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                        GenJnlLine.FieldError("Bal. Account Type", ErrorInfo.Create());
                end;
        end;

        OnAfterCheckBalAccountNo(GenJnlLine);
    end;

    local procedure CheckElectronicPaymentFields(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckElectronicPaymentFields(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Electronic Payment") or
           (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Electronic Payment-IAT")
        then begin
            GenJnlLine.TestField("Exported to Payment File", true, ErrorInfo.Create());
            if CheckTransmitted(GenJnlLine) then
                GenJnlLine.TestField("Check Transmitted", true, ErrorInfo.Create());
        end;
    end;

    local procedure CheckTransmitted(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Bank Account" then
            if BankAccount.Get(GenJnlLine."Account No.") then
                exit(BankAccount."Check Transmitted");
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Bank Account" then
            if BankAccount.Get(GenJnlLine."Bal. Account No.") then
                exit(BankAccount."Check Transmitted");
        exit(false);
    end;

    local procedure CheckJobNoIsEmpty(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobNoIsEmpty(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Job No.", '', ErrorInfo.Create());
    end;

    procedure CheckSalesDocNoIsNotUsed(var GenJournalLine: Record "Gen. Journal Line")
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocNoIsNotUsed(GenJournalLine."Document Type".AsInteger(), GenJournalLine."Document No.", IsHandled, GenJournalLine, OldCustLedgEntry);
        if IsHandled then
            exit;

        OldCustLedgEntry.SetRange("Document No.", GenJournalLine."Document No.");
        OldCustLedgEntry.SetRange("Document Type", GenJournalLine."Document Type");
        OnCheckSalesDocNoIsNotUsedOnAfterSetFilters(GenJournalLine, OldCustLedgEntry);
        if not OldCustLedgEntry.IsEmpty() then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(SalesDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."),
                    true,
                    GenJournalLine));
    end;

    procedure CheckPurchDocNoIsNotUsed(var GenJournalLine: Record "Gen. Journal Line")
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDocNoIsNotUsed(GenJournalLine."Document Type".AsInteger(), GenJournalLine."Document No.", IsHandled, GenJournalLine);
        if IsHandled then
            exit;

        OldVendLedgEntry.SetRange("Document No.", GenJournalLine."Document No.");
        OldVendLedgEntry.SetRange("Document Type", GenJournalLine."Document Type");
        if not OldVendLedgEntry.IsEmpty() then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(PurchDocAlreadyExistsErr, GenJournalLine."Document Type", GenJournalLine."Document No."),
                    true,
                    GenJournalLine));
    end;

    procedure CheckDocType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsPayment: Boolean;
        IsHandled: Boolean;
        IsFinChargeMemoNeg: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::" ") and (not GenJnlLine."Financial Void") then begin
            if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee) and not
               (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::" "])
            then
                GenJnlLine.FieldError("Document Type", ErrorInfo.Create(EmployeeAccountDocTypeErr, true));

            IsFinChargeMemoNeg := (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Finance Charge Memo") and (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and (GenJnlLine.Amount < 0);
            IsPayment := GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::"Credit Memo"];
            if IsPayment xor ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) xor IsVendorPaymentToCrMemo(GenJnlLine)) xor IsFinChargeMemoNeg then
                ErrorIfNegativeAmt(GenJnlLine)
            else
                ErrorIfPositiveAmt(GenJnlLine);
        end;
    end;

    local procedure CheckBalDocType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsPayment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalDocType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::" " then begin
            if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee) and not
               (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::" "])
            then
                GenJnlLine.FieldError("Document Type", ErrorInfo.Create(EmployeeBalancingDocTypeErr, true));

            IsPayment := GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::"Credit Memo"];
            if IsPayment = (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) then
                ErrorIfNegativeAmt(GenJnlLine)
            else
                ErrorIfPositiveAmt(GenJnlLine);
        end;
    end;

    local procedure CheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        CheckDone: Boolean;
    begin
        OnBeforeCheckICPartner(AccountType, AccountNo, DocumentType.AsInteger(), CheckDone, GenJnlLine);
        if CheckDone then
            exit;

        case AccountType of
            AccountType::Customer:
                if Customer.Get(AccountNo) then begin
                    Customer.CheckBlockedCustOnJnls(Customer, DocumentType, true);
                    if (Customer."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and
                       ICPartner.Get(Customer."IC Partner Code")
                    then
                        ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                end;
            AccountType::Vendor:
                if Vendor.Get(AccountNo) then begin
                    Vendor.CheckBlockedVendOnJnls(Vendor, DocumentType, true);
                    if (Vendor."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and
                       ICPartner.Get(Vendor."IC Partner Code")
                    then
                        ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                end;
            AccountType::Employee:
                if Employee.Get(AccountNo) then
                    Employee.CheckBlockedEmployeeOnJnls(true)
        end;
    end;

    local procedure CheckDimensions(GenJnlLine: Record "Gen. Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        CheckDone: Boolean;
    begin
        OnBeforeCheckDimensions(GenJnlLine, CheckDone);
        if CheckDone then
            exit;

        if not DimMgt.CheckDimIDComb(GenJnlLine."Dimension Set ID") then
            ThrowGenJnlLineError(GenJnlLine, Text011, DimMgt.GetDimCombErr());

        TableID[1] := DimMgt.TypeToTableID1(GenJnlLine."Account Type".AsInteger());
        No[1] := GenJnlLine."Account No.";
        TableID[2] := DimMgt.TypeToTableID1(GenJnlLine."Bal. Account Type".AsInteger());
        No[2] := GenJnlLine."Bal. Account No.";
        TableID[3] := Database::Job;
        No[3] := GenJnlLine."Job No.";
        TableID[4] := Database::"Salesperson/Purchaser";
        No[4] := GenJnlLine."Salespers./Purch. Code";
        TableID[5] := Database::Campaign;
        No[5] := GenJnlLine."Campaign No.";

        CheckDone := false;
        OnCheckDimensionsOnAfterAssignDimTableIDs(GenJnlLine, TableID, No, CheckDone);

        if not CheckDone then
            if not DimMgt.CheckDimValuePosting(TableID, No, GenJnlLine."Dimension Set ID") then
                ThrowGenJnlLineError(GenJnlLine, Text012, DimMgt.GetDimValuePostingErr());
    end;

    local procedure CheckZeroAmount(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckZeroAmount(GenJnlLine, IsBatchMode, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine.NeedCheckZeroAmount() and not (GenJnlLine.IsRecurring() and IsBatchMode) then
            GenJnlLine.TestField(Amount, ErrorInfo.Create());
    end;

    procedure IsVendorPaymentToCrMemo(GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsVendorPaymentToCrMemo(GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit;

        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) and
            (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Payment) and
            (GenJournalLine."Applies-to Doc. Type" = GenJournalLine."Applies-to Doc. Type"::"Credit Memo") and
            (GenJournalLine."Applies-to Doc. No." <> '')
        then begin
            GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
            exit(GenJournalTemplate.Type = GenJournalTemplate.Type::Payments);
        end;
        exit(false);
    end;

    procedure ThrowGenJnlLineError(GenJournalLine: Record "Gen. Journal Line"; ErrorTemplate: Text; ErrorText: Text)
    begin
        if LogErrorMode then
            exit;

        if GenJournalLine."Line No." <> 0 then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        ErrorTemplate,
                        GenJournalLine.TableCaption, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.",
                        ErrorText),
                    true,
                    GenJournalLine));

        Error(
            ErrorInfo.Create(ErrorText, true, GenJournalLine));
    end;

    procedure SetBatchMode(NewBatchMode: Boolean)
    begin
        IsBatchMode := NewBatchMode;
    end;

    procedure CheckGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if GenJnlLine."System-Created Entry" or
            not (GenJnlLine."Gen. Posting Type" in [GenJnlLine."Gen. Posting Type"::Purchase, GenJnlLine."Gen. Posting Type"::Sale]) or
            not (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo"])
        then
            exit;

        if VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group") and
           VATPostingSetup."Adjust for Payment Discount"
        then
            GenJnlLine.TestField("Gen. Prod. Posting Group", ErrorInfo.Create());
    end;

    procedure CheckBalGenProdPostingGroupWhenAdjustForPmtDisc(GenJnlLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if GenJnlLine."System-Created Entry" or
            not (GenJnlLine."Bal. Gen. Posting Type" in [GenJnlLine."Bal. Gen. Posting Type"::Purchase, GenJnlLine."Bal. Gen. Posting Type"::Sale]) or
            not (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo"])
        then
            exit;

        if VATPostingSetup.Get(GenJnlLine."Bal. VAT Bus. Posting Group", GenJnlLine."Bal. VAT Prod. Posting Group") and
           VATPostingSetup."Adjust for Payment Discount"
        then
            GenJnlLine.TestField("Bal. Gen. Prod. Posting Group", ErrorInfo.Create());
    end;

    local procedure CheckAccountType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and
            (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Purchase)) or
           ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) and
            (GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::Sale))
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text010,
                        GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type",
                        GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine."Bal. Gen. Posting Type"),
                    true,
                    GenJnlLine));
    end;

    local procedure CheckBalAccountType(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) and
            (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase)) or
           ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) and
            (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Sale))
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text010,
                        GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type",
                        GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine."Gen. Posting Type"),
                    true,
                    GenJnlLine));
    end;

    procedure SetLogErrorMode(NewLogErrorMode: Boolean)
    begin
        LogErrorMode := NewLogErrorMode;
        if LogErrorMode then
            DimMgt.SetCollectErrorsMode();
    end;

    local procedure CheckAppliesToDocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAppliesToDocNo(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Applies-to Doc. No.", '', ErrorInfo.Create());
        GenJnlLine.TestField("Applies-to ID", '', ErrorInfo.Create());
    end;

    local procedure CheckVATDate(var GenJournalLine: Record "Gen. Journal Line")
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        IsHandled: Boolean;
        ThrowError: Boolean;
    begin
        IsHandled := false;
        // Posting of some document types do not catch errors with ErrorMessageMgt.
        // For these it is needed that we throw error with message directly to display to user
        ThrowError := GenJournalLine."Document Type" in [Enum::"Gen. Journal Document Type"::" ", Enum::"Gen. Journal Document Type"::"Finance Charge Memo", Enum::"Gen. Journal Document Type"::Reminder, Enum::"Gen. Journal Document Type"::"Credit Memo"];
        OnBeforeCheckVATDate(GenJournalLine, IsHandled);
        if not IsHandled then
            if not VATReportingDateMgt.IsValidDate(GenJournalLine, GenJournalLine.FieldNo("VAT Reporting Date"), ThrowError) then
                Error('');
    end;

    local procedure CheckCurrencyCode(GenJnlLine: Record "Gen. Journal Line")
    var
        ACYOnlyPosting: Boolean;
    begin
        ACYOnlyPosting :=
          (GLSetup."Additional Reporting Currency" <> '') and
          (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only") and
          (GenJnlLine."Currency Code" = GLSetup."Additional Reporting Currency");

        if (GenJnlLine."Currency Code" <> '') and (GenJnlLine."Currency Code" <> GLSetup."LCY Code") then begin
            CheckAccountCurrencyCode(
                GenJnlLine."Account No.", GenJnlLine."Account Type", GenJnlLine."Currency Code", ACYOnlyPosting);
            CheckAccountCurrencyCode(
                GenJnlLine."Bal. Account No.", GenJnlLine."Bal. Account Type", GenJnlLine."Currency Code", ACYOnlyPosting);
        end;
    end;

    local procedure CheckAccountCurrencyCode(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; CurrencyCode: Code[10]; ACYOnly: Boolean)
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if (AccountNo = '') or ACYOnly then
            exit;

        case AccountType of
            AccountType::"G/L Account":
                begin
                    GLAccount.Get(AccountNo);
                    CheckGLAccountSourceCurrency(GLAccount, CurrencyCode);
                end;
            AccountType::Customer:
                begin
                    Customer.Get(AccountNo);
                    CustomerPostingGroup.Get(Customer."Customer Posting Group");
                    GLAccount.Get(CustomerPostingGroup."Receivables Account");
                    CheckGLAccountSourceCurrency(GLAccount, CurrencyCode);
                end;
            AccountType::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    VendorPostingGroup.Get(Vendor."Vendor Posting Group");
                    GLAccount.Get(VendorPostingGroup."Payables Account");
                    CheckGLAccountSourceCurrency(GLAccount, CurrencyCode);
                end;
            AccountType::"Bank Account":
                begin
                    BankAccount.Get(AccountNo);
                    BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
                    GLAccount.Get(BankAccountPostingGroup."G/L Account No.");
                    CheckGLAccountSourceCurrency(GLAccount, CurrencyCode);
                end;
        end;
    end;

    internal procedure CheckGLAccountSourceCurrency(var GLAccount: Record "G/L Account"; CurrencyCode: Code[10])
    var
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        GLSetup.Get();
        case GLAccount."Source Currency Posting" of
            GLAccount."Source Currency Posting"::"Same Currency":
                if (CurrencyCode <> GLAccount."Source Currency Code") and
                    (GLAccount."Source Currency Code" <> '') and (GLAccount."Source Currency Code" <> GLSetup."LCY Code")
                then
                    Error(GLAccCurrencyDoesNotMatchErr, CurrencyCode, GLAccount."Source Currency Code", GLAccount."No.");
            GLAccount."Source Currency Posting"::"Multiple Currencies":
                if CurrencyCode <> '' then begin
                    GLAccountSourceCurrency.SetRange("G/L Account No.", GLAccount."No.");
                    GLAccountSourceCurrency.SetRange("Currency Code", CurrencyCode);
                    if GLAccountSourceCurrency.IsEmpty() then
                        Error(GLAccSourceCurrencyDoesNotMatchErr, CurrencyCode, GLAccount."No.");
                end;
            GLAccount."Source Currency Posting"::"LCY Only":
                if CurrencyCode <> '' then
                    Error(GLAccSourceCurrencyDoesNotAllowedErr, CurrencyCode, GLAccount."No.");
        end;
    end;

    local procedure CheckPostedDeferralHeaderExist(GenJnlLine: Record "Gen. Journal Line")
    var
        DeferralHeader: Record "Deferral Header";
        PostedDeferralHeader: Record "Posted Deferral Header";
        AccountNo: Code[20];
        ErrorTxt: Text;
    begin
        if not CheckDeferralHeaderExist(GenJnlLine) then
            exit;

        AccountNo := GetDeferralAccountNo(GenJnlLine);

        if PostedDeferralHeader.Get(
            DeferralHeader."Deferral Doc. Type"::"G/L",
            GenJnlLine."Document No.",
            AccountNo,
            0,
            '',
            GenJnlLine."Line No.")
        then begin
            ErrorTxt := StrSubstNo(DuplicateRecordErr, GenJnlLine."Document No.");
            Error(ErrorInfo.Create(ErrorTxt, true, GenJnlLine, GenJnlLine.FieldNo("Deferral Code")));
        end;
    end;

    local procedure CheckDeferralHeaderExist(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        DeferralHeader: Record "Deferral Header";
    begin
        if DeferralHeader.Get(
            DeferralHeader."Deferral Doc. Type"::"G/L",
            GenJnlLine."Journal Template Name",
            GenJnlLine."Journal Batch Name", 0, '',
            GenJnlLine."Line No.")
        then
            exit(true);
    end;

    local procedure GetDeferralAccountNo(GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        BankAcc: Record "Bank Account";
        BankAccPostingGr: Record "Bank Account Posting Group";
        GLAccountType: Enum "Gen. Journal Account Type";
        Account: Code[20];
        GLAccount: Code[20];
    begin
        if (GenJournalLine."Account No." = '') and (GenJournalLine."Bal. Account No." <> '') then begin
            GLAccount := GenJournalLine."Bal. Account No.";
            GLAccountType := GenJournalLine."Bal. Account Type";
        end else begin
            GLAccount := GenJournalLine."Account No.";
            GLAccountType := GenJournalLine."Account Type";
        end;

        case GLAccountType of
            GenJournalLine."Account Type"::Customer:
                begin
                    CustPostingGr.Get(GenJournalLine."Posting Group");
                    Account := CustPostingGr.GetReceivablesAccount();
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    VendPostingGr.Get(GenJournalLine."Posting Group");
                    Account := VendPostingGr.GetPayablesAccount();
                end;
            GenJournalLine."Account Type"::"Bank Account":
                begin
                    BankAcc.Get(GLAccount);
                    BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                    Account := BankAccPostingGr."G/L Account No.";
                end;
            else
                Account := GLAccount;
        end;

        exit(Account);
    end;

    internal procedure HasVAT(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        exit((GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" ") or
            (GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" "));
    end;

    procedure CheckDeferralPostingAllowed(DeferralPostingAllowed: Boolean)
    begin
        IsDeferralPostingAllowed := DeferralPostingAllowed;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDateNoAllowed(PostingDate: Date; var DateIsNotAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDeferralPostingDateNoAllowed(PostingDate: Date; var DateIsNotAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDateNotAllowed(GenJnlLine: Record "Gen. Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDateNotAllowed(PostingDate: Date; SetupRecordID: RecordId; GenJnlBatch: Record "Gen. Journal Batch"; var DateIsNotAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralPostingDateNotAllowed(PostingDate: Date; SetupRecordID: RecordId; GenJnlBatch: Record "Gen. Journal Batch"; var DateIsNotAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountNo(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDimensions(var GenJnlLine: Record "Gen. Journal Line"; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalDocType(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckICPartner(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Option; var CheckDone: Boolean; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckSalesDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line"; var OldCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPurchDocNoIsNotUsed(DocType: Option; DocNo: Code[20]; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeErrorIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeErrorIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line"; OverrideDimErr: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestAccountAndBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPostingDateInFiscalYear(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var GenJournalLine: Record "Gen. Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var CheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountType(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAppliesToDocNo(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckJobNoIsEmpty(GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckZeroAmount(GenJnlLine: Record "Gen. Journal Line"; IsBatchMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckElectronicPaymentFields(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIsVendorPaymentToCrMemo(GenJnlLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVATDate(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDocNoIsNotUsedOnAfterSetFilters(GenJournalLine: Record "Gen. Journal Line"; var OldCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAccountNoOnBeforeCheckICPartner(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;
}

