// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Posting;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Telemetry;

codeunit 12 "Gen. Jnl.-Post Line"
{
    Permissions = TableData "G/L Account" = r,
                  TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  tabledata "Customer Posting Group" = R,
                  TableData "Vendor Ledger Entry" = rimd,
                  tabledata "Vendor Posting Group" = R,
                  TableData "G/L Register" = Rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = Rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Check Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = Rimd,
                  TableData "Detailed Vendor Ledg. Entry" = Rimd,
                  TableData "Line Fee Note on Report Hist." = rim,
                  TableData "Employee Ledger Entry" = Rimd,
                  TableData "Detailed Employee Ledger Entry" = Rimd,
                  tabledata "Source Code Setup" = R,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Purchases & Payables Setup" = R,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "FA Register" = rimd,
                  TableData "Maintenance Ledger Entry" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GlobalGLEntry: Record "G/L Entry";
        TempGLEntryBuf: Record "G/L Entry" temporary;
        TempGLEntryVAT: Record "G/L Entry" temporary;
        TempGLEntryPreview: Record "G/L Entry" temporary;
        GLReg: Record "G/L Register";
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        VATEntry: Record "VAT Entry";
        TaxDetail: Record "Tax Detail";
        UnrealizedCustLedgEntry: Record "Cust. Ledger Entry";
        UnrealizedVendLedgEntry: Record "Vendor Ledger Entry";
        TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        DeferralDocType: Enum "Deferral Document Type";
        LastDocType: Enum "Gen. Journal Document Type";
        AddCurrencyCode: Code[10];
        JournalsSourceCodesList: List of [Code[10]];
        LastDocNo: Code[20];
        FiscalYearStartDate: Date;
        CurrencyDate: Date;
        LastDate: Date;
        BalanceCheckAmount: Decimal;
        BalanceCheckAmount2: Decimal;
        BalanceCheckAddCurrAmount: Decimal;
        BalanceCheckAddCurrAmount2: Decimal;
        BalanceCheckSrcCurrAmount: Decimal;
        BalanceCheckSrcCurrAmount2: Decimal;
        CurrentBalance: Decimal;
        TotalAddCurrAmount: Decimal;
        TotalAmount: Decimal;
        UnrealizedRemainingAmountCust: Decimal;
        UnrealizedRemainingAmountVend: Decimal;
        AmountRoundingPrecision: Decimal;
        AddCurrGLEntryVATAmt: Decimal;
        CurrencyFactor: Decimal;
        FirstEntryNo: Integer;
        NextEntryNo: Integer;
        NextVATEntryNo: Integer;
        FirstNewVATEntryNo: Integer;
        FirstTransactionNo: Integer;
        NextTransactionNo: Integer;
        NextConnectionNo: Integer;
        NextCheckEntryNo: Integer;
        InsertedTempGLEntryVAT: Integer;
        GLEntryNo: Integer;
        UseCurrFactorOnly: Boolean;
        NonAddCurrCodeOccured: Boolean;
        FADimAlreadyChecked: Boolean;
        OverrideDimErr: Boolean;
        JobLine: Boolean;
        CheckUnrealizedCust: Boolean;
        CheckUnrealizedVend: Boolean;
        GLSetupRead: Boolean;
        PreviewMode: Boolean;
        GLEntryInconsistent: Boolean;
        MultiplePostingGroups: Boolean;
        SourceCodeSetupRead: Boolean;
        IsGLRegInserted: Boolean;
        IgnoreJournalTemplNameMandatoryCheck: Boolean;

        NeedsRoundingErr: Label '%1 needs to be rounded', Comment = '%1 - amount';
        PurchaseAlreadyExistsErr: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type; %2 = Document No.';
        BankPaymentTypeMustNotBeFilledErr: Label 'Bank Payment Type must not be filled if Currency Code is different in Gen. Journal Line and Bank Account.';
        DocNoMustBeEnteredErr: Label 'Document No. must be entered when Bank Payment Type is %1.', Comment = '%1 - option value';
        CheckAlreadyExistsErr: Label 'Check %1 already exists for this Bank Account.', Comment = '%1 - document no.';
        ResidualRoundingErr: Label 'Residual caused by rounding of %1', Comment = '%1 - amount';
        DimensionUsedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5.', Comment = '%1 - table caption, %2 - template name, %3 - batch name, %4 - line no., %5 - error message';
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for deferrals for your company. Check the user setup for the allowed deferrals posting dates.', Comment = '%1=The date passed in for the posting date.';
        DescriptionMustNotBeBlankErr: Label 'When %1 is selected for %2, %3 must have a value.', Comment = '%1: Field Omit Default Descr. in Jnl., %2 G/L Account No, %3 Description';
        NoDeferralScheduleErr: Label 'You must create a deferral schedule if a deferral template is selected. Line: %1, Deferral Template: %2.', Comment = '%1=The line number of the general ledger transaction, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The line number of the general ledger transaction, %2=The Deferral Template Code';

    /// <summary>
    /// Returns the G/L Register that has been created during the posting process.
    /// </summary>
    /// <param name="NewGLReg">Retun value: G/L Register that has been created during the posting process.</param>
    procedure GetGLReg(var NewGLReg: Record "G/L Register")
    begin
        NewGLReg := GLReg;
    end;

    /// <summary>
    /// Wrapper for the main procedure which checks and posts the journal line.
    /// As a result G/L Entries and Register are created along with other related ledger entries.
    /// </summary>
    /// <param name="GenJnlLine2">Return value: General Journal Line that is being be posted.</param>
    /// <returns>No. of the last General Ledger Entry that has been created.</returns>
    procedure RunWithCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithCheck(GenJnlLine, GenJnlLine2, GLEntryNo, IsHandled);
        if IsHandled then
            exit(GLEntryNo);

        GenJnlLine.Copy(GenJnlLine2);
        Code(GenJnlLine, true);
        OnAfterRunWithCheck(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
        exit(GLEntryNo);
    end;

    /// <summary>
    /// Wrapper for the main procedure posts the journal line without checking it.
    /// As a result G/L Entries and Register are created along with other related ledger entries.
    /// </summary>
    /// <param name="GenJnlLine2">Return value: General Journal Line that is being be posted.</param>
    /// <returns>No. of the last General Ledger Entry that has been created.</returns>
    procedure RunWithoutCheck(var GenJnlLine2: Record "Gen. Journal Line"): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithoutCheck(GenJnlLine, GenJnlLine2, GLEntryNo, isHandled);
        if IsHandled then
            exit(GLEntryNo);

        GenJnlLine.Copy(GenJnlLine2);
        Code(GenJnlLine, false);
        OnAfterRunWithoutCheck(GenJnlLine);
        GenJnlLine2 := GenJnlLine;
        exit(GLEntryNo);
    end;

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean)
    var
        Balancing: Boolean;
        IsTransactionConsistent: Boolean;
        IsPosted: Boolean;
    begin
        IsPosted := false;
        OnBeforeCode(GenJnlLine, CheckLine, IsPosted, GLReg, GLEntryNo);
        if IsPosted then
            exit;

        GetJournalsSourceCode();

        if GenJnlLine.EmptyLine() then begin
            InitLastDocDate(GenJnlLine);
            exit;
        end;

        if GenJnlLine."VAT Reporting Date" = 0D then begin
            GLSetup.Get();
            if (GenJnlLine."Document Date" = 0D) and (GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date") then
                GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date"
            else
                GenJnlLine."VAT Reporting Date" := GLSetup.GetVATDate(GenJnlLine."Posting Date", GenJnlLine."Document Date");
        end;

        CheckGenJnlLine(GenJnlLine, CheckLine);
        OnCodeOnAfterCheckGenJnlLine(GenJnlLine, CheckLine);

        AmountRoundingPrecision := InitAmounts(GenJnlLine);

        if GenJnlLine."Bill-to/Pay-to No." = '' then
            case true of
                GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor]:
                    GenJnlLine."Bill-to/Pay-to No." := GenJnlLine."Account No.";
                GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor]:
                    GenJnlLine."Bill-to/Pay-to No." := GenJnlLine."Bal. Account No.";
            end;
        if GenJnlLine."Document Date" = 0D then
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";
        if GenJnlLine."Due Date" = 0D then
            GenJnlLine."Due Date" := GenJnlLine."Posting Date";

        FindJobLineSign(GenJnlLine);

        OnBeforeStartOrContinuePosting(GenJnlLine, LastDocType.AsInteger(), LastDocNo, LastDate, NextEntryNo);

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        OnCodeOnAfterStartOrContinuePosting(GenJnlLine, LastDocType, LastDocNo, LastDate, NextEntryNo);

        if GenJnlLine."Account No." <> '' then begin
            if (GenJnlLine."Bal. Account No." <> '') and
               (not GenJnlLine."System-Created Entry") and
               (GenJnlLine."Account Type" in
                [GenJnlLine."Account Type"::Customer,
                 GenJnlLine."Account Type"::Vendor,
                 GenJnlLine."Account Type"::"Fixed Asset"])
            then begin
                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);
                OnCodeOnAfterRunExhangeAccGLJournalLine(GenJnlLine, Balancing, NextEntryNo, JobLine);
                Balancing := true;
            end;

            PostGenJnlLine(GenJnlLine, Balancing);
        end;

        if GenJnlLine."Bal. Account No." <> '' then begin
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);
            OnCodeOnAfterRunExhangeAccGLJournalLine(GenJnlLine, Balancing, NextEntryNo, JobLine);
            PostGenJnlLine(GenJnlLine, not Balancing);
        end;

        CheckPostUnrealizedVAT(GenJnlLine, true);

        CreateDeferralScheduleFromGL(GenJnlLine, Balancing);

        OnCodeOnBeforeFinishPosting(GenJnlLine, Balancing, FirstEntryNo);
        IsTransactionConsistent := FinishPosting(GenJnlLine);

        OnAfterGLFinishPosting(
            GlobalGLEntry, GenJnlLine, IsTransactionConsistent, FirstTransactionNo, GLReg, TempGLEntryBuf,
            NextEntryNo, NextTransactionNo);

        GLEntryInconsistent := not IsTransactionConsistent;
    end;

    /// <summary>
    /// Specifies if the General Ledger Entries that have been created during the posting process are inconsistent.
    /// </summary>
    /// <returns>True if the G/L Entry is inconsistent, false otherwise.</returns>
    procedure IsGLEntryInconsistent(): Boolean
    begin
        exit(GLEntryInconsistent);
    end;

    /// <summary>
    /// Shows a list of all inconsistent G/L Entries that has been produced during the posting.
    /// </summary>
    procedure ShowInconsistentEntries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowInconsistentEntries(TempGLEntryPreview, IsHandled);
        if IsHandled then
            exit;

        Page.Run(Page::"G/L Entries Preview", TempGLEntryPreview);
    end;

    local procedure CheckGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; CheckLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenJnlLine(GenJournalLine, CheckLine, OverrideDimErr, IsHandled);
        if IsHandled then
            exit;

        if CheckLine then begin
            if OverrideDimErr then
                GenJnlCheckLine.SetOverDimErr();
            if IgnoreJournalTemplNameMandatoryCheck then
                GenJnlCheckLine.SetIgnoreJournalTemplNameMandatoryCheck();
            OnCheckGenJnlLineOnBeforeRunCheck(GenJournalLine);
            GenJnlCheckLine.RunCheck(GenJournalLine);
        end;
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
        OnBeforePostGenJnlLine(GenJnlLine, Balancing);

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                PostGLAcc(GenJnlLine, Balancing);
            GenJnlLine."Account Type"::Customer:
                PostCust(GenJnlLine, Balancing);
            GenJnlLine."Account Type"::Vendor:
                PostVend(GenJnlLine, Balancing);
            GenJnlLine."Account Type"::Employee:
                PostEmployee(GenJnlLine);
            GenJnlLine."Account Type"::"Bank Account":
                PostBankAcc(GenJnlLine, Balancing);
            GenJnlLine."Account Type"::"Fixed Asset":
                PostFixedAsset(GenJnlLine);
            GenJnlLine."Account Type"::"IC Partner":
                PostICPartner(GenJnlLine);
        end;

        OnAfterPostGenJnlLine(GenJnlLine, Balancing);
    end;

    local procedure InitAmounts(var GenJnlLine: Record "Gen. Journal Line"): Decimal
    var
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitAmounts(GenJnlLine, Currency, IsHandled);
        if IsHandled then
            exit(Currency."Amount Rounding Precision");

        if GenJnlLine."Currency Code" = '' then begin
            Currency.InitRoundingPrecision();
            GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
            GenJnlLine."VAT Amount (LCY)" := GenJnlLine."VAT Amount";
            GenJnlLine."VAT Base Amount (LCY)" := GenJnlLine."VAT Base Amount";
        end else begin
            Currency.Get(GenJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
            if (not GenJnlLine."System-Created Entry") or GenJnlLine."Financial Void" then begin
                GenJnlLine."Source Currency Code" := GenJnlLine."Currency Code";
                GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
                if GenJnlLine."VAT Calculation Type" = GenJnlLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
                    VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group");
                    GenJnlLine."Source Curr. VAT Base Amount" := GenJnlLine.Amount;
                    GenJnlLine."Source Curr. VAT Amount" :=
                        Round(
                            GenJnlLine.Amount * VATPostingSetup."VAT %" / 100,
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                end else begin
                    GenJnlLine."Source Curr. VAT Base Amount" := GenJnlLine."VAT Base Amount";
                    GenJnlLine."Source Curr. VAT Amount" := GenJnlLine."VAT Amount";
                end;
            end;
        end;
        if GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None then begin
            IsHandled := false;
            OnInitAmountsOnAddCurrencyPostingNone(GenJnlLine, IsHandled);
            if not IsHandled then begin
                if GenJnlLine.Amount <> Round(GenJnlLine.Amount, Currency."Amount Rounding Precision") then
                    GenJnlLine.FieldError(
                      GenJnlLine.Amount,
                      StrSubstNo(NeedsRoundingErr, GenJnlLine.Amount));
                if GenJnlLine."Amount (LCY)" <> Round(GenJnlLine."Amount (LCY)") then
                    GenJnlLine.FieldError(
                      GenJnlLine."Amount (LCY)",
                      StrSubstNo(NeedsRoundingErr, GenJnlLine."Amount (LCY)"));
            end;
        end;
        exit(Currency."Amount Rounding Precision");
    end;

    /// <summary>
    /// Assignes information (Document Type, Document No., Posting Date) fron Gen. Journal Line to the global variables.
    /// </summary>
    /// <param name="GenJnlLine">General Journal Line from which information is taken.</param>
    procedure InitLastDocDate(GenJnlLine: Record "Gen. Journal Line")
    begin
        LastDocType := GenJnlLine."Document Type";
        LastDocNo := GenJnlLine."Document No.";
        LastDate := GenJnlLine."Posting Date";

        OnAfterInitLastDocDate(GenJnlLine);
    end;

    local procedure InitNextEntryNo()
    var
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitNextEntryNo(GLEntry, NextEntryNo, NextTransactionNo, IsHandled);
        if IsHandled then
            exit;

        GLEntry.LockTable();
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);
        NextEntryNo := LastEntryNo + 1;
        NextTransactionNo := LastTransactionNo + 1;

        OnAfterInitNextEntryNo(GLEntry, NextEntryNo, NextTransactionNo);
    end;

    /// <summary>
    /// Initializes the G/L Entry for posting VAT depending on the VAT Posting of the Gen. Journal Line.
    /// </summary>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    /// <param name="GLEntry">Return value: G/L Entry initialized with information for VAT.</param>
    /// <param name="VATPostingSetup">Return value: VAT Posting Setup applicable to Gen. Journal Line that is being posted. Record is retrieved in this procedure and returned.</param>
    procedure InitVAT(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        LCYCurrency: Record Currency;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitVAT(GenJnlLine, GLEntry, VATPostingSetup, IsHandled, LCYCurrency, AddCurrencyCode, AddCurrGLEntryVATAmt);
        if IsHandled then
            exit;

        LCYCurrency.InitRoundingPrecision();
        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then begin
            VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group");
            VATPostingSetup.TestField(Blocked, false);
            IsHandled := false;
            OnInitVATOnBeforeVATPostingSetupCheck(GenJnlLine, GLEntry, VATPostingSetup, IsHandled);
            if not IsHandled then
                GenJnlLine.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
            case GenJnlLine."VAT Posting" of
                GenJnlLine."VAT Posting"::"Automatic VAT Entry":
                    begin
                        GLEntry.CopyPostingGroupsFromGenJnlLine(GenJnlLine);
                        case GenJnlLine."VAT Calculation Type" of
                            GenJnlLine."VAT Calculation Type"::"Normal VAT":
                                begin
                                    IsHandled := false;
                                    OnInitVATOnVATCalculationTypeNormal(GenJnlLine, IsHandled, GLEntry, VATPostingSetup);
                                    if not IsHandled then
                                        if GenJnlLine."VAT Difference" <> 0 then begin
                                            GLEntry.Amount := GenJnlLine."VAT Base Amount (LCY)";
                                            GLEntry."VAT Amount" := GenJnlLine."Amount (LCY)" - GLEntry.Amount;
                                            GLEntry."Additional-Currency Amount" := GenJnlLine."Source Curr. VAT Base Amount";
                                            if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                                AddCurrGLEntryVATAmt := GenJnlLine."Source Curr. VAT Amount"
                                            else
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                        end else begin
                                            GLEntry."VAT Amount" :=
                                              Round(
                                                GenJnlLine."Amount (LCY)" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());
                                            OnInitVATOnAfterSetGLEntryVATAmountForNormalVAT(GenJnlLine, GLEntry);
                                            GLEntry.Amount := GenJnlLine."Amount (LCY)" - GLEntry."VAT Amount";
                                            if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                                AddCurrGLEntryVATAmt :=
                                                  Round(
                                                    GenJnlLine."Source Currency Amount" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
                                                    AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection())
                                            else
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                            GLEntry."Additional-Currency Amount" := GenJnlLine."Source Currency Amount" - AddCurrGLEntryVATAmt;
                                        end;
                                end;
                            GenJnlLine."VAT Calculation Type"::"Reverse Charge VAT":
                                case GenJnlLine."Gen. Posting Type" of
                                    GenJnlLine."Gen. Posting Type"::Purchase:
                                        if GenJnlLine."VAT Difference" <> 0 then begin
                                            GLEntry."VAT Amount" := GenJnlLine."VAT Amount (LCY)";
                                            if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                                AddCurrGLEntryVATAmt := GenJnlLine."Source Curr. VAT Amount"
                                            else
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                        end else begin
                                            GLEntry."VAT Amount" :=
                                              Round(
                                                GLEntry.Amount * VATPostingSetup."VAT %" / 100,
                                                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());
                                            if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                                AddCurrGLEntryVATAmt :=
                                                  Round(
                                                    GLEntry."Additional-Currency Amount" * VATPostingSetup."VAT %" / 100,
                                                    AddCurrency."Amount Rounding Precision", AddCurrency.VATRoundingDirection())
                                            else
                                                AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                        end;
                                    GenJnlLine."Gen. Posting Type"::Sale:
                                        begin
                                            GLEntry."VAT Amount" := 0;
                                            AddCurrGLEntryVATAmt := 0;
                                        end;
                                end;
                            GenJnlLine."VAT Calculation Type"::"Full VAT":
                                begin
                                    IsHandled := false;
                                    OnInitVATOnBeforeTestFullVATAccount(GenJnlLine, GLEntry, VATPostingSetup, IsHandled);
                                    if not IsHandled then
                                        case GenJnlLine."Gen. Posting Type" of
                                            GenJnlLine."Gen. Posting Type"::Sale:
                                                GenJnlLine.TestField("Account No.", VATPostingSetup.GetSalesAccount(false));
                                            GenJnlLine."Gen. Posting Type"::Purchase:
                                                GenJnlLine.TestField("Account No.", VATPostingSetup.GetPurchAccount(false));
                                        end;
                                    GLEntry.Amount := 0;
                                    GLEntry."Additional-Currency Amount" := 0;
                                    GLEntry."VAT Amount" := GenJnlLine."Amount (LCY)";
                                    if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                        AddCurrGLEntryVATAmt := GenJnlLine."Source Currency Amount"
                                    else
                                        AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GenJnlLine."Amount (LCY)");
                                end;
                            GenJnlLine."VAT Calculation Type"::"Sales Tax":
                                begin
                                    if (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Purchase) and
                                       GenJnlLine."Use Tax"
                                    then begin
                                        GLEntry."VAT Amount" :=
                                          Round(
                                            SalesTaxCalculate.CalculateTax(
                                              GenJnlLine."Tax Area Code", GenJnlLine."Tax Group Code", GenJnlLine."Tax Liable",
                                              GenJnlLine."Posting Date", GenJnlLine."Amount (LCY)", GenJnlLine.Quantity, 0));
                                        OnAfterSalesTaxCalculateCalculateTax(GenJnlLine, GLEntry, LCYCurrency);
                                        GLEntry.Amount := GenJnlLine."Amount (LCY)";
                                    end else begin
                                        GLEntry.Amount :=
                                          Round(
                                            SalesTaxCalculate.ReverseCalculateTax(
                                              GenJnlLine."Tax Area Code", GenJnlLine."Tax Group Code", GenJnlLine."Tax Liable",
                                              GenJnlLine."Posting Date", GenJnlLine."Amount (LCY)", GenJnlLine.Quantity, 0));
                                        OnAfterSalesTaxCalculateReverseCalculateTax(GenJnlLine, GLEntry, LCYCurrency);
                                        GLEntry."VAT Amount" := GenJnlLine."Amount (LCY)" - GLEntry.Amount;
                                    end;
                                    GLEntry."Additional-Currency Amount" := GenJnlLine."Source Currency Amount";
                                    if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                                        AddCurrGLEntryVATAmt := GenJnlLine."Source Curr. VAT Amount"
                                    else
                                        AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GLEntry."VAT Amount");
                                end;
                        end;
                    end;
                GenJnlLine."VAT Posting"::"Manual VAT Entry":
                    if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::Settlement then begin
                        GLEntry.CopyPostingGroupsFromGenJnlLine(GenJnlLine);
                        GLEntry."VAT Amount" := GenJnlLine."VAT Amount (LCY)";
                        if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                            AddCurrGLEntryVATAmt := GenJnlLine."Source Curr. VAT Amount"
                        else
                            AddCurrGLEntryVATAmt := CalcLCYToAddCurr(GenJnlLine."VAT Amount (LCY)");
                    end;
            end;
        end;

        GLEntry."Source Currency VAT Amount" := CalcAmountSrcCurr(GenJnlLine, GLEntry."VAT Amount");
        GLEntry."Additional-Currency Amount" :=
          GLCalcAddCurrency(GLEntry.Amount, GLEntry."Additional-Currency Amount", GLEntry."Additional-Currency Amount", true, GenJnlLine);
        NonDeductibleVAT.CopyNonDedVATAmountFromGenJnlLineToGLEntry(GLEntry, GenJnlLine);

        OnAfterInitVAT(GenJnlLine, GLEntry, VATPostingSetup, AddCurrGLEntryVATAmt);
    end;

    /// <summary>
    /// Creates and inserts VAT Entries for the Gen. Journal Line that is being posted.
    /// If Gen. Journal Line requires Sales Tax, VAT Entries are created and inserted for each Tax Line that is needed.
    /// </summary>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    /// <param name="GLEntry">G/L Entry for which VAT Entry should be created.</param>
    /// <param name="VATPostingSetup">VAT Posting Setup applicable to Gen. Journal Line that is being posted.</param>
    procedure PostVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup")
    var
        TaxDetail2: Record "Tax Detail";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATBase: Decimal;
        VATBase2: Decimal;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        SrcCurrSalesTaxBaseAmount: Decimal;
        RemSrcCurrVATAmount: Decimal;
        SalesTaxBaseAmount: Decimal;
        TaxDetailFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostVAT(GenJnlLine, GLEntry, VATPostingSetup, IsHandled, AddCurrGLEntryVATAmt, NextConnectionNo, TaxDetail);
        if IsHandled then
            exit;

        case GenJnlLine."VAT Calculation Type" of
            GenJnlLine."VAT Calculation Type"::"Normal VAT",
            GenJnlLine."VAT Calculation Type"::"Reverse Charge VAT",
            GenJnlLine."VAT Calculation Type"::"Full VAT":
                begin
                    if GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Automatic VAT Entry" then
                        GenJnlLine."VAT Base Amount (LCY)" := GLEntry.Amount;
                    if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Settlement then
                        AddCurrGLEntryVATAmt := GenJnlLine."Source Curr. VAT Amount";
                    InsertVAT(
                      GenJnlLine, VATPostingSetup,
                      GLEntry.Amount, GLEntry."VAT Amount", GenJnlLine."VAT Base Amount (LCY)", GenJnlLine."Source Currency Code",
                      GLEntry."Additional-Currency Amount", AddCurrGLEntryVATAmt, GenJnlLine."Source Curr. VAT Base Amount");
                    NextConnectionNo := NextConnectionNo + 1;
                end;
            GenJnlLine."VAT Calculation Type"::"Sales Tax":
                begin
                    case GenJnlLine."VAT Posting" of
                        GenJnlLine."VAT Posting"::"Automatic VAT Entry":
                            SalesTaxBaseAmount := GLEntry.Amount;
                        GenJnlLine."VAT Posting"::"Manual VAT Entry":
                            SalesTaxBaseAmount := GenJnlLine."VAT Base Amount (LCY)";
                    end;
                    if (GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Manual VAT Entry") and
                       (GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Settlement)
                    then
                        InsertVAT(
                          GenJnlLine, VATPostingSetup,
                          GLEntry.Amount, GLEntry."VAT Amount", GenJnlLine."VAT Base Amount (LCY)", GenJnlLine."Source Currency Code",
                          GenJnlLine."Source Curr. VAT Base Amount", GenJnlLine."Source Curr. VAT Amount", GenJnlLine."Source Curr. VAT Base Amount")
                    else begin
                        Clear(SalesTaxCalculate);
                        SalesTaxCalculate.InitSalesTaxLines(
                          GenJnlLine."Tax Area Code", GenJnlLine."Tax Group Code", GenJnlLine."Tax Liable",
                          SalesTaxBaseAmount, GenJnlLine.Quantity, GenJnlLine."Posting Date", GLEntry."VAT Amount");
                        OnAfterSalesTaxCalculateInitSalesTaxLines(GenJnlLine, GLEntry, SalesTaxBaseAmount);
                        SrcCurrVATAmount := 0;
                        SrcCurrVATBase := 0;
                        SrcCurrSalesTaxBaseAmount := CalcLCYToAddCurr(SalesTaxBaseAmount);
                        RemSrcCurrVATAmount := AddCurrGLEntryVATAmt;
                        VATAmount2 := 0;
                        VATBase2 := 0;
                        TaxDetailFound := false;
                        while SalesTaxCalculate.GetSalesTaxLine(TaxDetail2, VATAmount, VATBase) do begin
                            RemSrcCurrVATAmount := RemSrcCurrVATAmount - SrcCurrVATAmount;
                            if TaxDetailFound then
                                InsertVAT(
                                  GenJnlLine, VATPostingSetup,
                                  SalesTaxBaseAmount, VATAmount2, VATBase2, GenJnlLine."Source Currency Code",
                                  SrcCurrSalesTaxBaseAmount, SrcCurrVATAmount, SrcCurrVATBase);
                            TaxDetailFound := true;
                            TaxDetail := TaxDetail2;
                            VATAmount2 := VATAmount;
                            VATBase2 := VATBase;
                            SrcCurrVATAmount := CalcLCYToAddCurr(VATAmount);
                            SrcCurrVATBase := CalcLCYToAddCurr(VATBase);
                        end;
                        if TaxDetailFound then
                            InsertVAT(
                              GenJnlLine, VATPostingSetup,
                              SalesTaxBaseAmount, VATAmount2, VATBase2, GenJnlLine."Source Currency Code",
                              SrcCurrSalesTaxBaseAmount, RemSrcCurrVATAmount, SrcCurrVATBase);
                        InsertSummarizedVAT(GenJnlLine);
                    end;
                end;
        end;

        OnAfterPostVAT(GenJnlLine, GLEntry, VATPostingSetup, TaxDetail, NextConnectionNo, AddCurrGLEntryVATAmt, AddCurrencyCode, UseCurrFactorOnly);
    end;

    /// <summary>
    /// Creates and inserts VAT Entry for the Gen. Journal Line that is being posted. 
    /// If Calculation Type is Sales Tax, VAT Entries are filled with Tax related information.
    /// VAT Posting Parameter is created to be used for the VAT Entry.
    /// </summary>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    /// <param name="VATPostingSetup">VAT Posting Setup applicable to Gen. Journal Line that is being posted.</param>
    /// <param name="GLEntryAmount">Amount that is used for the new VAT Entry Amount if Gen. Posting Type is Settlement.</param>
    /// <param name="GLEntryVATAmount">Amount that is used for the new VAT Entry Amount if Gen. Posting Type is not Settlement.</param>
    /// <param name="GLEntryBaseAmount">Amount that is used for the new VAT Entry Base.</param>
    /// <param name="SrcCurrCode">Currency Code that has been used for the posting transaction (empty if local currency).</param>
    /// <param name="SrcCurrGLEntryAmt">Determines new VAT Entry amount after exhange to foreign currency.</param>
    /// <param name="SrcCurrGLEntryVATAmt">The VAT Amount to be used for additional currency.</param>
    /// <param name="SrcCurrGLEntryBaseAmt">The VAT base to be used for additional currency.</param>
    procedure InsertVAT(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; GLEntryAmount: Decimal; GLEntryVATAmount: Decimal; GLEntryBaseAmount: Decimal; SrcCurrCode: Code[10]; SrcCurrGLEntryAmt: Decimal; SrcCurrGLEntryVATAmt: Decimal; SrcCurrGLEntryBaseAmt: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATPostingParameters: Record "VAT Posting Parameters";
        VATAmount: Decimal;
        VATBase: Decimal;
        SrcCurrVATAmount: Decimal;
        SrcCurrVATBase: Decimal;
        VATDifferenceLCY: Decimal;
        SrcCurrVATDifference: Decimal;
        NonDedVATDiffACY: Decimal;
        UnrealizedVAT: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVAT(
          GenJnlLine, VATEntry, UnrealizedVAT, AddCurrencyCode, VATPostingSetup, GLEntryAmount, GLEntryVATAmount, GLEntryBaseAmount,
          SrcCurrCode, SrcCurrGLEntryAmt, SrcCurrGLEntryVATAmt, SrcCurrGLEntryBaseAmt, IsHandled);
        if IsHandled then
            exit;

        VATEntry.Init();
        VATEntry.CopyFromGenJnlLine(GenJnlLine);
        VATEntry."Entry No." := NextVATEntryNo;
        VATEntry."EU Service" := VATPostingSetup."EU Service";
        VATEntry."Transaction No." := NextTransactionNo;
        VATEntry."Sales Tax Connection No." := NextConnectionNo;
        VATEntry.SetVATDateFromGenJnlLine(GenJnlLine);
        OnInsertVATOnAfterAssignVATEntryFields(GenJnlLine, VATEntry, CurrExchRate);

        if GenJnlLine."VAT Difference" = 0 then
            VATDifferenceLCY := 0
        else
            if GenJnlLine."Currency Code" = '' then
                VATDifferenceLCY := GenJnlLine."VAT Difference"
            else
                VATDifferenceLCY :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine."VAT Difference",
                      CurrExchRate.ExchangeRate(GenJnlLine."Posting Date", GenJnlLine."Currency Code")));

        OnInsertVATOnAfterCalcVATDifferenceLCY(GenJnlLine, VATEntry, VATDifferenceLCY, CurrExchRate);

        if GenJnlLine."VAT Calculation Type" = GenJnlLine."VAT Calculation Type"::"Sales Tax" then
            UpdateVATEntryTaxDetails(GenJnlLine, VATEntry, TaxDetail, TaxJurisdiction);

        if AddCurrencyCode <> '' then
            if AddCurrencyCode <> SrcCurrCode then begin
                SrcCurrGLEntryAmt := ExchangeAmtLCYToFCY2(GLEntryAmount);
                SrcCurrGLEntryVATAmt := ExchangeAmtLCYToFCY2(GLEntryVATAmount);
                SrcCurrGLEntryBaseAmt := ExchangeAmtLCYToFCY2(GLEntryBaseAmount);
                SrcCurrVATDifference := ExchangeAmtLCYToFCY2(VATDifferenceLCY);
                NonDedVATDiffACY := ExchangeAmtLCYToFCY2(GenJnlLine."Non-Deductible VAT Diff.");
            end else begin
                SrcCurrVATDifference := GenJnlLine."VAT Difference";
                NonDedVATDiffACY := GenJnlLine."Non-Deductible VAT Diff.";
            end;

        UnrealizedVAT := SetUnrealizedVAT(GenJnlLine, VATPostingSetup, TaxJurisdiction);

        // VAT for VAT entry
        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then begin
            case GenJnlLine."VAT Posting" of
                GenJnlLine."VAT Posting"::"Automatic VAT Entry":
                    begin
                        VATAmount := GLEntryVATAmount;
                        VATBase := GLEntryBaseAmount;
                        SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                        SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                        NonDeductibleVAT.AdjustVATAmountsFromGenJnlLine(
                            VATAmount, VATBase, SrcCurrVATAmount, SrcCurrVATBase, GenJnlLine);
                    end;
                GenJnlLine."VAT Posting"::"Manual VAT Entry":
                    begin
                        if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Settlement then begin
                            VATAmount := GLEntryAmount;
                            SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                            VATEntry.Closed := true;
                        end else begin
                            VATAmount := GLEntryVATAmount;
                            SrcCurrVATAmount := SrcCurrGLEntryVATAmt;
                        end;
                        VATBase := GLEntryBaseAmount;
                        SrcCurrVATBase := SrcCurrGLEntryBaseAmt;
                        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::Settlement then
                            NonDeductibleVAT.AdjustVATAmountsFromGenJnlLine(
                                VATAmount, VATBase, SrcCurrVATAmount, SrcCurrVATBase, GenJnlLine);
                    end;
            end;

            OnInsertVATOnAfterSetVATAmounts(GenJnlLine, VATEntry, GLEntryAmount, GLEntryVATAmount, VATAmount, GLEntryBaseAmount, VATBase, SrcCurrGLEntryAmt, SrcCurrGLEntryVATAmt, SrcCurrVATAmount, SrcCurrGLEntryBaseAmt, SrcCurrVATBase);

            if UnrealizedVAT then begin
                VATEntry.Amount := 0;
                VATEntry.Base := 0;
                VATEntry."Unrealized Amount" := VATAmount;
                VATEntry."Unrealized Base" := VATBase;
                VATEntry."Remaining Unrealized Amount" := VATEntry."Unrealized Amount";
                VATEntry."Remaining Unrealized Base" := VATEntry."Unrealized Base";
            end else begin
                VATEntry.Amount := VATAmount;
                VATEntry.Base := VATBase;
                VATEntry."Unrealized Amount" := 0;
                VATEntry."Unrealized Base" := 0;
                VATEntry."Remaining Unrealized Amount" := 0;
                VATEntry."Remaining Unrealized Base" := 0;
            end;
            NonDeductibleVAT.SetNonDedVATInVATEntry(VATEntry, GenJnlLine."Non-Deductible VAT Base LCY", GenJnlLine."Non-Deductible VAT Amount LCY", GenJnlLine."Non-Deductible VAT Base ACY", GenJnlLine."Non-Deductible VAT Amount ACY", GenJnlLine."Non-Deductible VAT Diff.", NonDedVATDiffACY);

            if AddCurrencyCode = '' then begin
                VATEntry."Additional-Currency Base" := 0;
                VATEntry."Additional-Currency Amount" := 0;
                VATEntry."Add.-Currency Unrealized Amt." := 0;
                VATEntry."Add.-Currency Unrealized Base" := 0;
                NonDeductibleVAT.ClearNonDedVATACYInVATEntry(VATEntry);
            end else
                if UnrealizedVAT then begin
                    VATEntry."Additional-Currency Base" := 0;
                    VATEntry."Additional-Currency Amount" := 0;
                    VATEntry."Add.-Currency Unrealized Base" := SrcCurrVATBase;
                    VATEntry."Add.-Currency Unrealized Amt." := SrcCurrVATAmount;
                end else begin
                    VATEntry."Additional-Currency Base" := SrcCurrVATBase;
                    VATEntry."Additional-Currency Amount" := SrcCurrVATAmount;
                    VATEntry."Add.-Currency Unrealized Base" := 0;
                    VATEntry."Add.-Currency Unrealized Amt." := 0;
                end;
            VATEntry."Add.-Curr. Rem. Unreal. Amount" := VATEntry."Add.-Currency Unrealized Amt.";
            VATEntry."Add.-Curr. Rem. Unreal. Base" := VATEntry."Add.-Currency Unrealized Base";
            VATEntry."VAT Difference" := VATDifferenceLCY;
            VATEntry."Add.-Curr. VAT Difference" := SrcCurrVATDifference;
            if GenJnlLine."System-Created Entry" then
                VATEntry."Base Before Pmt. Disc." := GenJnlLine."VAT Base Before Pmt. Disc."
            else
                VATEntry."Base Before Pmt. Disc." := GLEntryAmount;

            OnBeforeInsertVATEntry(VATEntry, GenJnlLine, NextVATEntryNo, TempGLEntryVATEntryLink, TempGLEntryBuf, GLReg);
            VATEntry.Insert(true);
            TempGLEntryVATEntryLink.InsertLinkSelf(TempGLEntryBuf."Entry No.", VATEntry."Entry No.");
            NextVATEntryNo := NextVATEntryNo + 1;
            OnAfterInsertVATEntry(GenJnlLine, VATEntry, TempGLEntryBuf."Entry No.", NextVATEntryNo, TempGLEntryVATEntryLink);
        end;

        // VAT for G/L entry/entries
        VATPostingParameters.InsertRecord(
            GenJnlLine, VATPostingSetup, GLEntryVATAmount, SrcCurrGLEntryVATAmt, SrcCurrCode, UnrealizedVAT, VATAmount, SrcCurrVATAmount, GenJnlLine."Non-Deductible VAT Amount LCY", GenJnlLine."Non-Deductible VAT Amount ACY");
        InsertVATForGLEntry(
            GenJnlLine, VATPostingSetup, TaxJurisdiction,
            VATPostingParameters);

        OnAfterInsertVAT(
          GenJnlLine, VATEntry, UnrealizedVAT, AddCurrencyCode, VATPostingSetup, GLEntryAmount, GLEntryVATAmount, GLEntryBaseAmount,
          SrcCurrCode, SrcCurrGLEntryAmt, SrcCurrGLEntryVATAmt, SrcCurrGLEntryBaseAmt, AddCurrGLEntryVATAmt,
          NextConnectionNo, NextVATEntryNo, NextTransactionNo, TempGLEntryBuf."Entry No.");
    end;

    local procedure SetUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; TaxJurisdiction: Record "Tax Jurisdiction") UnrealizedVAT: Boolean
    begin
        UnrealizedVAT :=
            (((VATPostingSetup."Unrealized VAT Type" > 0) and
            (VATPostingSetup."VAT Calculation Type" in
                [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
                VATPostingSetup."VAT Calculation Type"::"Full VAT"])) or
            ((TaxJurisdiction."Unrealized VAT Type" > 0) and
            (VATPostingSetup."VAT Calculation Type" in
                [VATPostingSetup."VAT Calculation Type"::"Sales Tax"]))) and
            IsNotPayment(GenJnlLine."Document Type");
        if GLSetup."Prepayment Unrealized VAT" and not GLSetup."Unrealized VAT" and
            (VATPostingSetup."Unrealized VAT Type" > 0)
        then
            UnrealizedVAT := GenJnlLine.Prepayment;

        OnAfterSetUnrealizedVAT(GenJnlLine, VATPostingSetup, UnrealizedVAT);
    end;

    local procedure InsertVATForGLEntry(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; TaxJurisdiction: Record "Tax Jurisdiction"; VATPostingParameters: Record "VAT Posting Parameters")
    var
        GLEntryVATAmountNotEmpty: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVATForGLEntryFromBuffer(GenJnlLine, VATPostingSetup, VATPostingParameters, IsHandled, VATEntry, TaxJurisdiction, AddCurrencyCode);
        if IsHandled then
            exit;

        GLEntryVATAmountNotEmpty := (VATPostingParameters."Full VAT Amount" <> 0) or (NonDeductibleVAT.GetNonDeductibleVATAmount(GenJnlLine) <> 0);
        OnInsertVATOnBeforeVATForGLEntry(GenJnlLine, GLEntryVATAmountNotEmpty);
        if GLEntryVATAmountNotEmpty or
           ((VATPostingParameters."Full VAT Amount ACY" <> 0) and (VATPostingParameters."Source Currency Code" = AddCurrencyCode))
        then
            case GenJnlLine."Gen. Posting Type" of
                GenJnlLine."Gen. Posting Type"::Purchase:
                    case VATPostingSetup."VAT Calculation Type" of
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                        VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            CreateNormalVATGLEntries(GenJnlLine, VATPostingSetup, VATPostingParameters);
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            CreateReverseChargeVATGLEntries(GenJnlLine, VATPostingSetup, VATPostingParameters);
                        VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            if GenJnlLine."Use Tax" then begin
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(VATPostingParameters."Unrealized VAT"), '',
                                  VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true);
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), '',
                                  -VATPostingParameters."Full VAT Amount", -VATPostingParameters."Full VAT Amount ACY", true);
                            end else
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(VATPostingParameters."Unrealized VAT"), '',
                                  VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true);
                    end;
                GenJnlLine."Gen. Posting Type"::Sale:
                    case VATPostingSetup."VAT Calculation Type" of
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                      VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            CreateGLEntry(
                                GenJnlLine, VATPostingSetup.GetSalesAccount(VATPostingParameters."Unrealized VAT"),
                                VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true,
                                CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Full VAT Amount"));
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            ;
                        VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                            InitGLEntryVAT(
                                GenJnlLine, TaxJurisdiction.GetSalesAccount(VATPostingParameters."Unrealized VAT"), '',
                                VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true);
                    end;
            end;
    end;

    local procedure CreateNormalVATGLEntries(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATPostingParameters: Record "VAT Posting Parameters")
    var
        LastNextEntryNo: Integer;
    begin
        OnBeforeCreateNormalVATGLEntries(GenJnlLine, VATPostingSetup);

        if VATPostingParameters."Unrealized VAT" or (VATPostingParameters."Non-Deductible VAT %" <> 100) then
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetPurchAccount(VATPostingParameters."Unrealized VAT"),
                VATPostingParameters."Deductible VAT Amount", VATPostingParameters."Deductible VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Deductible VAT Amount"));
        if VATPostingParameters."Non-Deductible VAT %" <> 0 then
            if VATPostingParameters."Non-Ded. Purchase VAT Account" = '' then begin
                if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then begin
                    LastNextEntryNo := NextEntryNo;
                    CreateGLEntry(
                        GenJnlLine, GenJnlLine."FA G/L Account No.",
                        VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                        CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
                    PostFAJnlLineWithGLEntryBufUpdate(GenJnlLine, VATPostingParameters, LastNextEntryNo);
                end else
                    CreateGLEntry(
                        GenJnlLine, GenJnlLine."Account No.",
                        VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                        CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
            end else begin
                LastNextEntryNo := NextEntryNo;
                CreateGLEntry(
                    GenJnlLine, VATPostingParameters."Non-Ded. Purchase VAT Account",
                    VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                    CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
                if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
                    PostFAJnlLineWithGLEntryBufUpdate(GenJnlLine, VATPostingParameters, LastNextEntryNo);
            end;

        OnAfterCreateNormalVATGLEntries(GenJnlLine);
    end;

    local procedure CreateReverseChargeVATGLEntries(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATPostingParameters: Record "VAT Posting Parameters")
    var
        LastNextEntryNo: Integer;
    begin
        if VATPostingParameters."Unrealized VAT" or not (NonDeductibleVAT.IsNonDeductibleVATEnabled()) then begin
            OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToPurchAcc(
                GenJnlLine, VATPostingSetup, VATPostingParameters."Unrealized VAT", VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true);
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetPurchAccount(VATPostingParameters."Unrealized VAT"), VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Full VAT Amount"));
            OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToRevChargeAcc(
                GenJnlLine, VATPostingSetup, VATPostingParameters."Unrealized VAT", VATPostingParameters."Full VAT Amount", VATPostingParameters."Full VAT Amount ACY", true);
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), -VATPostingParameters."Full VAT Amount", -VATPostingParameters."Full VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, -VATPostingParameters."Full VAT Amount"));
            exit;
        end;
        if VATPostingParameters."Non-Deductible VAT %" <> 100 then begin
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetPurchAccount(VATPostingParameters."Unrealized VAT"), VATPostingParameters."Deductible VAT Amount", VATPostingParameters."Deductible VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), -VATPostingParameters."Deductible VAT Amount", -VATPostingParameters."Deductible VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, -VATPostingParameters."Non-Deductible VAT Amount"));
        end;
        if VATPostingParameters."Non-Deductible VAT %" = 0 then
            exit;
        if VATPostingParameters."Non-Ded. Purchase VAT Account" = '' then begin
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then begin
                LastNextEntryNo := NextEntryNo;
                CreateGLEntry(
                    GenJnlLine, GenJnlLine."FA G/L Account No.", VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                    CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
                if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
                    PostFAJnlLineWithGLEntryBufUpdate(GenJnlLine, VATPostingParameters, LastNextEntryNo);
                CreateGLEntry(
                    GenJnlLine, VATPostingSetup.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), -VATPostingParameters."Non-Deductible VAT Amount", -VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                    CalcAmountSrcCurr(GenJnlLine, -VATPostingParameters."Non-Deductible VAT Amount"));
            end else begin
                CreateGLEntry(
                    GenJnlLine, VATPostingSetup.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), -VATPostingParameters."Non-Deductible VAT Amount", -VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                    CalcAmountSrcCurr(GenJnlLine, -VATPostingParameters."Non-Deductible VAT Amount"));
                CreateGLEntry(
                    GenJnlLine, GenJnlLine."Account No.", VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                    CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
            end;
        end else begin
            LastNextEntryNo := NextEntryNo;
            CreateGLEntry(
                GenJnlLine, VATPostingParameters."Non-Ded. Purchase VAT Account", VATPostingParameters."Non-Deductible VAT Amount", VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount"));
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
                PostFAJnlLineWithGLEntryBufUpdate(GenJnlLine, VATPostingParameters, LastNextEntryNo);
            CreateGLEntry(
                GenJnlLine, VATPostingSetup.GetRevChargeAccount(VATPostingParameters."Unrealized VAT"), -VATPostingParameters."Non-Deductible VAT Amount", -VATPostingParameters."Non-Deductible VAT Amount ACY", true,
                CalcAmountSrcCurr(GenJnlLine, -VATPostingParameters."Non-Deductible VAT Amount"));
        end;
    end;

    local procedure PostFAJnlLineWithGLEntryBufUpdate(GenJnlLine: Record "Gen. Journal Line"; VATPostingParameters: Record "VAT Posting Parameters"; LastNextEntryNo: Integer)
    var
        TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary;
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
    begin
        if not NonDeductibleVAT.UseNonDeductibleVATAmountForFixedAssetCost() then
            exit;
        GenJnlLine."Non-Ded. VAT FA Cost" := true;
        FAJnlPostLine.GenJnlPostLine(GenJnlLine, VATPostingParameters."Non-Deductible VAT Amount", 0, NextTransactionNo, LastNextEntryNo, GLReg."No.");
        GenJnlLine."Non-Ded. VAT FA Cost" := false;
        if FAJnlPostLine.FindFirstGLAcc(TempFAGLPostingBuffer) then begin
            TempGLEntryBuf."FA Entry Type" := TempFAGLPostingBuffer."FA Entry Type";
            TempGLEntryBuf."FA Entry No." := TempFAGLPostingBuffer."FA Entry No.";
            TempGLEntryBuf.Modify();
        end;
    end;

    /// <summary>
    /// Creates G/L Entries for VAT. If summarization is needed, before creating new entry existing ones in TempGLEntryVAT.
    /// buffer are checked. If entry in the buffer for the same G/L Account and Bal. Account already exists, just the amount is increased.
    /// </summary>
    /// <param name="SummarizeGLEntries">Flag if entries should be summarized.</param>
    /// <param name="GLEntry">G/L Entry for which VAT G/L Entry should be created or adjusted.</param>
    procedure SummarizeVAT(SummarizeGLEntries: Boolean; GLEntry: Record "G/L Entry")
    var
        InsertedTempVAT: Boolean;
    begin
        InsertedTempVAT := false;
        if SummarizeGLEntries then
            if TempGLEntryVAT.FindSet() then
                repeat
                    if (TempGLEntryVAT."G/L Account No." = GLEntry."G/L Account No.") and
                       (TempGLEntryVAT."Bal. Account No." = GLEntry."Bal. Account No.")
                    then begin
                        TempGLEntryVAT.Amount := TempGLEntryVAT.Amount + GLEntry.Amount;
                        TempGLEntryVAT."Additional-Currency Amount" :=
                          TempGLEntryVAT."Additional-Currency Amount" + GLEntry."Additional-Currency Amount";
                        TempGLEntryVAT.Modify();
                        InsertedTempVAT := true;
                    end;
                until (TempGLEntryVAT.Next() = 0) or InsertedTempVAT;
        if not InsertedTempVAT or not SummarizeGLEntries then begin
            TempGLEntryVAT := GLEntry;
            TempGLEntryVAT."Entry No." :=
              TempGLEntryVAT."Entry No." + InsertedTempGLEntryVAT;
            TempGLEntryVAT.Insert();
            InsertedTempGLEntryVAT := InsertedTempGLEntryVAT + 1;
        end;
    end;

    /// <summary>
    /// Inserts summarized VAT G/L Entries for the Gen. Journal Line that is being posted.
    /// Summarized entries are taken from TempGLEntryVAT buffer.
    /// </summary>
    /// <remarks>
    /// Global G/L Entry buffer for VAT is cleared at the end of procedure.
    /// </remarks>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    procedure InsertSummarizedVAT(GenJnlLine: Record "Gen. Journal Line")
    begin
        if TempGLEntryVAT.FindSet() then begin
            repeat
                InsertGLEntry(GenJnlLine, TempGLEntryVAT, true);
                OnInsertSummarizedVATOnAfterInsertGLEntry(GenJnlLine, TempGLEntryVAT, NextEntryNo);
            until TempGLEntryVAT.Next() = 0;
            TempGLEntryVAT.DeleteAll();
            InsertedTempGLEntryVAT := 0;
        end;
        NextConnectionNo := NextConnectionNo + 1;
    end;

    local procedure CheckDescriptionForGL(GLAccount: Record "G/L Account"; Description: Text[100])
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLAccount."Omit Default Descr. in Jnl." then
            if DelChr(Description, '=', ' ') = '' then
                Error(
                    DescriptionMustNotBeBlankErr,
                    GLAccount.FieldCaption("Omit Default Descr. in Jnl."),
                    GLAccount."No.",
                    GLEntry.FieldCaption(Description));
    end;

    local procedure PostGLAcc(GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGLAcc(GenJnlLine, GLEntry, GLEntryNo, IsHandled, TempGLEntryBuf);
        if not IsHandled then begin
            GLAcc.Get(GenJnlLine."Account No.");
            InitGLEntry(
                GenJnlLine, GLEntry, GenJnlLine."Account No.", GenJnlLine."Amount (LCY)",
                GenJnlLine."Source Currency Amount", true, GenJnlLine."System-Created Entry",
                CalcAmountSrcCurr(GenJnlLine, GenJnlLine."VAT Base Amount (LCY)"));
            OnPostGLAccOnAfterInitGLEntry(GenJnlLine, GLEntry);
            CheckGLAccDirectPosting(GenJnlLine, GLAcc);
            CheckDescriptionForGL(GLAcc, GenJnlLine.Description);
            GLEntry."Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
            GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
            GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
            GLEntry."No. Series" := GenJnlLine."Posting No. Series";
            GLEntry."Journal Templ. Name" := GenJnlLine."Journal Template Name";
            if GenJnlLine."Additional-Currency Posting" =
               GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only"
            then begin
                GLEntry."Additional-Currency Amount" := GenJnlLine.Amount;
                GLEntry.Amount := 0;
            end;
            // Store Entry No. to global variable for return:
            GLEntryNo := GLEntry."Entry No.";
            InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
            IsHandled := false;
            OnPostGLAccOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled, Balancing);
            if not IsHandled then
                if not ((GenJnlLine."Deferral Code" <> '') and (GenJnlLine.Amount = 0)) then
                    InsertGLEntry(GenJnlLine, GLEntry, true);
            IsHandled := false;
            OnPostGLAccOnBeforePostJob(GenJnlLine, GLEntry, IsHandled, Balancing);
            if not IsHandled then
                PostJob(GenJnlLine, GLEntry);
            PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
            OnPostGLAccOnBeforeDeferralPosting(GenJnlLine);
            DeferralPosting(GenJnlLine."Deferral Code", GenJnlLine."Source Code", GenJnlLine."Account No.", GenJnlLine, Balancing);
        end;

        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
        OnAfterPostGLAcc(GenJnlLine, TempGLEntryBuf, NextEntryNo, NextTransactionNo, Balancing, GLEntry, VATPostingSetup, TempGLEntryVATEntryLink);
    end;

    local procedure PostCust(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
        Cust: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        ReceivablesAccount: Code[20];
        DtldLedgEntryInserted: Boolean;
        ShouldCheckDocNo: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostCust(GenJournalLine, Balancing, IsHandled);
        if not IsHandled then begin
            SalesSetup.Get();

            Cust.Get(GenJournalLine."Account No.");
            Cust.CheckBlockedCustOnJnls(Cust, GenJournalLine, true);
            Cust.TestField("Customer Posting Group");
            if GenJournalLine."Posting Group" = '' then
                GenJournalLine."Posting Group" := Cust."Customer Posting Group"
            else
                if GenJournalLine."Posting Group" <> Cust."Customer Posting Group" then
                    Cust.CheckAllowMultiplePostingGroups();

            OnPostCustOnBeforeGetCustomerPostingGroup(GenJournalLine);
            GetCustomerPostingGroup(GenJournalLine, CustPostingGr);
            ReceivablesAccount := GetCustomerReceivablesAccount(GenJournalLine, CustPostingGr);
            OnPostCustOnAfterAssignReceivablesAccount(GenJournalLine, CustPostingGr, ReceivablesAccount);

            DtldCustLedgEntry.LockTable();
            CustLedgEntry.LockTable();
            OnPostCustOnBeforeInitCustLedgEntry(GenJournalLine, CustLedgEntry, CVLedgEntryBuf, TempDtldCVLedgEntryBuf, CustPostingGr);
            InitCustLedgEntry(GenJournalLine, CustLedgEntry);
            OnPostCustOnAfterInitCustLedgEntry(GenJournalLine, CustLedgEntry, Cust, CustPostingGr);

            if not Cust."Block Payment Tolerance" then
                CalcPmtTolerancePossible(
                    GenJournalLine, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Pmt. Disc. Tolerance Date",
                    CustLedgEntry."Max. Payment Tolerance");

            TempDtldCVLedgEntryBuf.DeleteAll();
            TempDtldCVLedgEntryBuf.Init();
            OnPostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine(GenJournalLine, CustLedgEntry, Cust, GLReg, CVLedgEntryBuf);
            TempDtldCVLedgEntryBuf.CopyFromGenJnlLine(GenJournalLine);
            OnPostCustOnAfterTempDtldCVLedgEntryBufCopyFromGenJnlLine(GenJournalLine, TempDtldCVLedgEntryBuf);
            TempDtldCVLedgEntryBuf."CV Ledger Entry No." := CustLedgEntry."Entry No.";
            OnPostCustOnBeforeCopyFromCustLedgEntry(CVLedgEntryBuf, GenJournalLine, Cust);
            CVLedgEntryBuf.CopyFromCustLedgEntry(CustLedgEntry);

            IsHandled := false;
            OnPostCustOnBeforeInsertDtldCVLedgEntry(GenJournalLine, TempDtldCVLedgEntryBuf, CVLedgEntryBuf, CustLedgEntry, IsHandled);
            if not IsHandled then
                TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, true);
            CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
            CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;
            OnPostCustOnAfterCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJournalLine, Cust, CustLedgEntry, TempDtldCVLedgEntryBuf);

            CalcPmtDiscPossible(GenJournalLine, CVLedgEntryBuf);

            if GenJournalLine."Currency Code" <> '' then begin
                GenJournalLine.TestField("Currency Factor");
                CVLedgEntryBuf."Original Currency Factor" := GenJournalLine."Currency Factor"
            end else
                CVLedgEntryBuf."Original Currency Factor" := 1;
            CVLedgEntryBuf."Adjusted Currency Factor" := CVLedgEntryBuf."Original Currency Factor";
            OnPostCustOnAfterAssignCurrencyFactors(CVLedgEntryBuf, GenJournalLine);

            // Check the document no.
            if GenJournalLine."Recurring Method" = GenJournalLine."Recurring Method"::" " then begin
                ShouldCheckDocNo := IsNotPayment(GenJournalLine."Document Type");
                OnPostCustOnAfterCalcShouldCheckDocNo(GenJournalLine, ShouldCheckDocNo);
                if ShouldCheckDocNo then begin
                    GenJnlCheckLine.CheckSalesDocNoIsNotUsed(GenJournalLine);
                    CheckSalesExtDocNo(GenJournalLine);
                end;
            end;

            // Post application
            ApplyCustLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJournalLine, Cust);

            // Post customer entry
            CustLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
            IsHandled := false;
            OnPostCustOnBeforeResetCustLedgerEntryAppliesToFields(CustLedgEntry, IsHandled);
            if not IsHandled then begin
                CustLedgEntry."Amount to Apply" := 0;
                CustLedgEntry."Applies-to Doc. No." := '';
                CustLedgEntry."Applies-to ID" := '';
            end;
            if SalesSetup."Copy Customer Name to Entries" then
                CustLedgEntry."Customer Name" := Cust.Name;
            OnBeforeCustLedgEntryInsert(CustLedgEntry, GenJournalLine, GLReg, TempDtldCVLedgEntryBuf, NextEntryNo);
            CustLedgEntry.Insert(true);

            CustLedgEntry.CopyLinks(GenJournalLine);

            // Post detailed customer entries
            DtldLedgEntryInserted := PostDtldCustLedgEntries(GenJournalLine, TempDtldCVLedgEntryBuf, CustPostingGr, true);

            OnAfterCustLedgEntryInsert(CustLedgEntry, GenJournalLine, DtldLedgEntryInserted, PreviewMode);
#if not CLEAN25
            OnAfterCustLedgEntryInsertInclPreviewMode(CustLedgEntry, GenJournalLine, DtldLedgEntryInserted, PreviewMode);
#endif
            // Post Reminder Terms - Note About Line Fee on Report
            LineFeeNoteOnReportHist.Save(CustLedgEntry);

            if DtldLedgEntryInserted then
                if IsTempGLEntryBufEmpty() then
                    DtldCustLedgEntry.SetZeroTransNo(NextTransactionNo);

            DeferralPosting(GenJournalLine."Deferral Code", GenJournalLine."Source Code", ReceivablesAccount, GenJournalLine, Balancing);

            OnMoveGenJournalLine(GenJournalLine, CustLedgEntry.RecordId);
        end;
        OnAfterPostCust(GenJournalLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostVend(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        Vend: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        PayablesAccount: Code[20];
        DtldLedgEntryInserted: Boolean;
        CheckExtDocNoHandled: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostVend(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();

        Vend.Get(GenJournalLine."Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, GenJournalLine."Document Type", true);
        Vend.TestField("Vendor Posting Group");
        if GenJournalLine."Posting Group" = '' then
            GenJournalLine."Posting Group" := Vend."Vendor Posting Group"
        else
            if GenJournalLine."Posting Group" <> Vend."Vendor Posting Group" then
                Vend.CheckAllowMultiplePostingGroups();
        GetVendorPostingGroup(GenJournalLine, VendPostingGr);

        IsHandled := false;
        OnPostVendOnBeforeGetVendorPayablesAccount(GenJournalLine, VendPostingGr, VendPostingGr."Payables Account", IsHandled);
        if not IsHandled then
            PayablesAccount := GetVendorPayablesAccount(GenJournalLine, VendPostingGr);

        OnPostVendOnAfterAssignPayablesAccount(GenJournalLine, VendPostingGr, PayablesAccount);

        DtldVendLedgEntry.LockTable();
        VendLedgEntry.LockTable();
        OnPostVendOnBeforeInitVendLedgEntry(GenJournalLine, VendLedgEntry, CVLedgEntryBuf, TempDtldCVLedgEntryBuf, VendPostingGr);
        InitVendLedgEntry(GenJournalLine, VendLedgEntry);

        OnPostVendOnAfterInitVendLedgEntry(GenJournalLine, VendLedgEntry, Vend);
        if not Vend."Block Payment Tolerance" then
            CalcPmtTolerancePossible(
                GenJournalLine, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Pmt. Disc. Tolerance Date",
                VendLedgEntry."Max. Payment Tolerance");

        TempDtldCVLedgEntryBuf.DeleteAll();
        TempDtldCVLedgEntryBuf.Init();
        OnPostVendOnBeforeCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJournalLine, Vend);
        TempDtldCVLedgEntryBuf.CopyFromGenJnlLine(GenJournalLine);
        TempDtldCVLedgEntryBuf."CV Ledger Entry No." := VendLedgEntry."Entry No.";
        OnPostVendAfterTempDtldCVLedgEntryBufInit(GenJournalLine, TempDtldCVLedgEntryBuf);

        CVLedgEntryBuf.CopyFromVendLedgEntry(VendLedgEntry);
        TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, true);
        CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
        CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;
        OnPostVendOnAfterCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJournalLine);

        CalcPmtDiscPossible(GenJournalLine, CVLedgEntryBuf);

        if GenJournalLine."Currency Code" <> '' then begin
            GenJournalLine.TestField("Currency Factor");
            CVLedgEntryBuf."Adjusted Currency Factor" := GenJournalLine."Currency Factor"
        end else
            CVLedgEntryBuf."Adjusted Currency Factor" := 1;
        CVLedgEntryBuf."Original Currency Factor" := CVLedgEntryBuf."Adjusted Currency Factor";
        OnPostVendOnAfterAssignCurrencyFactors(CVLedgEntryBuf, GenJournalLine);

        // Check the document no.
        if GenJournalLine."Recurring Method" = GenJournalLine."Recurring Method"::" " then
            if IsNotPayment(GenJournalLine."Document Type") then begin
                GenJnlCheckLine.CheckPurchDocNoIsNotUsed(GenJournalLine);
                OnBeforeCheckPurchExtDocNo(GenJournalLine, VendLedgEntry, CVLedgEntryBuf, CheckExtDocNoHandled);
                if not CheckExtDocNoHandled then
                    CheckPurchExtDocNo(GenJournalLine);
            end;

        // Post application
        ApplyVendLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJournalLine, Vend);

        // Post vendor entry
        VendLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
        VendLedgEntry."Amount to Apply" := 0;
        VendLedgEntry."Applies-to Doc. No." := '';
        VendLedgEntry."Applies-to ID" := '';
        if PurchSetup."Copy Vendor Name to Entries" then
            VendLedgEntry."Vendor Name" := Vend.Name;
        OnBeforeVendLedgEntryInsert(VendLedgEntry, GenJournalLine, GLReg);
        VendLedgEntry.Insert(true);

        VendLedgEntry.CopyLinks(GenJournalLine);

        // Post detailed vendor entries
        OnPostVendOnBeforePostDtldVendLedgEntries(VendLedgEntry, GenJournalLine, TempDtldCVLedgEntryBuf, NextEntryNo);
        DtldLedgEntryInserted := PostDtldVendLedgEntries(GenJournalLine, TempDtldCVLedgEntryBuf, VendPostingGr, true);


        OnAfterVendLedgEntryInsert(VendLedgEntry, GenJournalLine, DtldLedgEntryInserted, PreviewMode);
#if not CLEAN25
        OnAfterVendLedgEntryInsertInclPreviewMode(VendLedgEntry, GenJournalLine, DtldLedgEntryInserted, PreviewMode);
#endif        

        if DtldLedgEntryInserted then
            if IsTempGLEntryBufEmpty() then
                DtldVendLedgEntry.SetZeroTransNo(NextTransactionNo);
        DeferralPosting(GenJournalLine."Deferral Code", GenJournalLine."Source Code", PayablesAccount, GenJournalLine, Balancing);

        OnMoveGenJournalLine(GenJournalLine, VendLedgEntry.RecordId);
        OnAfterPostVend(GenJournalLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostEmployee(GenJnlLine: Record "Gen. Journal Line")
    var
        Employee: Record Employee;
        EmployeePostingGr: Record "Employee Posting Group";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        DtldLedgEntryInserted: Boolean;
    begin
        Employee.Get(GenJnlLine."Account No.");
        Employee.CheckBlockedEmployeeOnJnls(true);
        Employee.TestField("Employee Posting Group");
        if GenJnlLine."Posting Group" = '' then
            GenJnlLine."Posting Group" := Employee."Employee Posting Group"
        else
            if GenJnlLine."Posting Group" <> Employee."Employee Posting Group" then
                Employee.CheckAllowMultiplePostingGroups();

        EmployeePostingGr.Get(GenJnlLine."Posting Group");

        DtldEmplLedgEntry.LockTable();
        EmployeeLedgerEntry.LockTable();

        InitEmployeeLedgerEntry(GenJnlLine, EmployeeLedgerEntry);

        TempDtldCVLedgEntryBuf.DeleteAll();
        TempDtldCVLedgEntryBuf.Init();
        TempDtldCVLedgEntryBuf.CopyFromGenJnlLine(GenJnlLine);
        TempDtldCVLedgEntryBuf."CV Ledger Entry No." := EmployeeLedgerEntry."Entry No.";
        CVLedgEntryBuf.CopyFromEmplLedgEntry(EmployeeLedgerEntry);
        TempDtldCVLedgEntryBuf.InsertDtldCVLedgEntry(TempDtldCVLedgEntryBuf, CVLedgEntryBuf, true);
        CVLedgEntryBuf.Open := CVLedgEntryBuf."Remaining Amount" <> 0;
        CVLedgEntryBuf.Positive := CVLedgEntryBuf."Remaining Amount" > 0;
        OnPostEmployeeOnAfterCopyCVLedgEntryBuf(CVLedgEntryBuf, GenJnlLine);

        if GenJnlLine."Currency Code" <> '' then begin
            GenJnlLine.TestField("Currency Factor");
            CVLedgEntryBuf."Adjusted Currency Factor" := GenJnlLine."Currency Factor"
        end else
            CVLedgEntryBuf."Adjusted Currency Factor" := 1;
        CVLedgEntryBuf."Original Currency Factor" := CVLedgEntryBuf."Adjusted Currency Factor";
        OnPostEmployeeOnAfterAssignCurrencyFactors(CVLedgEntryBuf, GenJnlLine);

        // Post application
        ApplyEmplLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Employee);

        // Post employee entry
        EmployeeLedgerEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
        EmployeeLedgerEntry."Amount to Apply" := 0;
        EmployeeLedgerEntry."Applies-to Doc. No." := '';
        EmployeeLedgerEntry."Applies-to ID" := '';
        OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert(GenJnlLine, EmployeeLedgerEntry, GLReg);
        EmployeeLedgerEntry.Insert(true);

        EmployeeLedgerEntry.CopyLinks(GenJnlLine);

        // Post detailed employee entries
        DtldLedgEntryInserted := PostDtldEmplLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, EmployeePostingGr, true);
        OnPostEmployeeOnAfterPostDtldEmplLedgEntries(GenJnlLine, EmployeeLedgerEntry, DtldLedgEntryInserted);

        // Posting GL Entry
        if DtldLedgEntryInserted then
            if IsTempGLEntryBufEmpty() then
                DtldEmplLedgEntry.SetZeroTransNo(NextTransactionNo);
        OnMoveGenJournalLine(GenJnlLine, EmployeeLedgerEntry.RecordId);
    end;

    local procedure PostBankAcc(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        CheckLedgEntry2: Record "Check Ledger Entry";
        BankAccPostingGr: Record "Bank Account Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostBankAcc(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        BankAcc.Get(GenJnlLine."Account No.");
        BankAcc.TestField(Blocked, false);
        IsHandled := false;
        OnPostBankAccOnBeforeCheckCurrencyCode(GenJnlLine, BankAcc, IsHandled);
        if not IsHandled then
            if GenJnlLine."Currency Code" = '' then
                BankAcc.TestField("Currency Code", '')
            else
                if BankAcc."Currency Code" <> '' then
                    GenJnlLine.TestField("Currency Code", BankAcc."Currency Code");

        IsHandled := false;
        OnBeforeCheckBankAccPostingGroup(GLSetup, GenJnlLine, IsHandled);
        if not IsHandled then begin
            BankAcc.TestField("Bank Acc. Posting Group");
            BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
        end;

        BankAccLedgEntry.LockTable();

        OnPostBankAccOnBeforeInitBankAccLedgEntry(GenJnlLine, CurrencyFactor, NextEntryNo, NextTransactionNo, BankAccPostingGr);

        InitBankAccLedgEntry(GenJnlLine, BankAccLedgEntry);

        BankAccLedgEntry."Bank Acc. Posting Group" := BankAcc."Bank Acc. Posting Group";
        BankAccLedgEntry."Currency Code" := BankAcc."Currency Code";
        if BankAcc."Currency Code" <> '' then
            BankAccLedgEntry.Amount := GenJnlLine.Amount
        else
            BankAccLedgEntry.Amount := GenJnlLine."Amount (LCY)";
        BankAccLedgEntry."Amount (LCY)" := GenJnlLine."Amount (LCY)";
        BankAccLedgEntry.Open := GenJnlLine.Amount <> 0;
        BankAccLedgEntry."Remaining Amount" := BankAccLedgEntry.Amount;
        BankAccLedgEntry.Positive := GenJnlLine.Amount > 0;
        BankAccLedgEntry.UpdateDebitCredit(GenJnlLine.Correction);
        OnPostBankAccOnBeforeBankAccLedgEntryInsert(BankAccLedgEntry, GenJnlLine, BankAcc, TempGLEntryBuf, NextTransactionNo, GLReg, Balancing);
        BankAccLedgEntry.Insert(true);
        OnPostBankAccOnAfterBankAccLedgEntryInsert(BankAccLedgEntry, GenJnlLine, BankAcc);

        BankAccLedgEntry.CopyLinks(GenJnlLine);

        if ((GenJnlLine.Amount <= 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") and GenJnlLine."Check Printed") or
           ((GenJnlLine.Amount < 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Manual Check"))
        then begin
            IsHandled := false;
            OnPostBankAccOnBeforeModifyCheckLedgerEntry(GenJnlLine, IsHandled);
            if not IsHandled then
                if BankAcc."Currency Code" <> GenJnlLine."Currency Code" then
                    Error(BankPaymentTypeMustNotBeFilledErr);
            case GenJnlLine."Bank Payment Type" of
                GenJnlLine."Bank Payment Type"::"Computer Check":
                    begin
                        GenJnlLine.TestField("Check Printed", true);
                        CheckLedgEntry.LockTable();
                        CheckLedgEntry.Reset();
                        CheckLedgEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
                        CheckLedgEntry.SetRange("Bank Account No.", GenJnlLine."Account No.");
                        CheckLedgEntry.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Printed);
                        CheckLedgEntry.SetRange("Check No.", GenJnlLine."Document No.");
                        OnPostBankAccOnAfterCheckLedgEntrySetFilters(CheckLedgEntry, GenJnlLine);
                        if CheckLedgEntry.FindSet() then
                            repeat
                                CheckLedgEntry2 := CheckLedgEntry;
                                CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Posted;
                                CheckLedgEntry2."Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
                                OnPostBankAccOnBeforeCheckLedgEntry2Modify(CheckLedgEntry, BankAccLedgEntry, CheckLedgEntry2);
                                CheckLedgEntry2.Modify();
                            until CheckLedgEntry.Next() = 0;
                    end;
                GenJnlLine."Bank Payment Type"::"Manual Check":
                    begin
                        if GenJnlLine."Document No." = '' then
                            Error(DocNoMustBeEnteredErr, GenJnlLine."Bank Payment Type");
                        CheckLedgEntry.Reset();
                        if NextCheckEntryNo = 0 then begin
                            CheckLedgEntry.LockTable();
                            if CheckLedgEntry.FindLast() then
                                NextCheckEntryNo := CheckLedgEntry."Entry No." + 1
                            else
                                NextCheckEntryNo := 1;
                        end;

                        CheckLedgEntry.SetRange("Bank Account No.", GenJnlLine."Account No.");
                        CheckLedgEntry.SetFilter(
                          "Entry Status", '%1|%2|%3',
                          CheckLedgEntry."Entry Status"::Printed,
                          CheckLedgEntry."Entry Status"::Posted,
                          CheckLedgEntry."Entry Status"::"Financially Voided");
                        CheckLedgEntry.SetRange("Check No.", GenJnlLine."Document No.");
                        if not CheckLedgEntry.IsEmpty() then
                            Error(CheckAlreadyExistsErr, GenJnlLine."Document No.");

                        InitCheckLedgEntry(BankAccLedgEntry, CheckLedgEntry);
                        CheckLedgEntry."Bank Payment Type" := CheckLedgEntry."Bank Payment Type"::"Manual Check";
                        if BankAcc."Currency Code" <> '' then
                            CheckLedgEntry.Amount := -GenJnlLine.Amount
                        else
                            CheckLedgEntry.Amount := -GenJnlLine."Amount (LCY)";
                        OnPostBankAccOnBeforeCheckLedgEntryInsert(CheckLedgEntry, BankAccLedgEntry, GenJnlLine, BankAcc);
                        CheckLedgEntry.Insert(true);
                        OnPostBankAccOnAfterCheckLedgEntryInsert(CheckLedgEntry, BankAccLedgEntry, GenJnlLine, BankAcc);
                        NextCheckEntryNo := NextCheckEntryNo + 1;
                    end;
            end;
        end;

        IsHandled := false;
        OnPostBankAccOnCheckingBankAccPostingGrGLAccountNo(GenJnlLine, BankAccPostingGr, IsHandled);
        if not IsHandled then
            BankAccPostingGr.TestField("G/L Account No.");

        IsHandled := false;
        OnPostBankAccOnBeforeCreateGLEntryBalAcc(GenJnlLine, BankAccPostingGr, BankAcc, NextEntryNo, IsHandled);
        if not IsHandled then
            CreateGLEntryBalAcc(
              GenJnlLine, BankAccPostingGr."G/L Account No.", GenJnlLine."Amount (LCY)", GenJnlLine."Source Currency Amount",
              GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
        DeferralPosting(GenJnlLine."Deferral Code", GenJnlLine."Source Code", BankAccPostingGr."G/L Account No.", GenJnlLine, Balancing);
        OnMoveGenJournalLine(GenJnlLine, BankAccLedgEntry.RecordId);

        OnAfterPostBankAcc(GenJnlLine, Balancing, TempGLEntryBuf, NextEntryNo, NextTransactionNo);
    end;

    local procedure PostFixedAsset(GenJnlLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary;
        FAGLPostBuf: Record "FA G/L Posting Buffer";
        VATPostingSetup: Record "VAT Posting Setup";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        FAAutomaticEntry: Codeunit "FA Automatic Entry";
        ShortcutDim1Code: Code[20];
        ShortcutDim2Code: Code[20];
        OriginalGLAccNo: Code[20];
        Correction2: Boolean;
        NetDisposalNo: Integer;
        DimensionSetID: Integer;
        VATEntryGLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFixedAsset(GenJnlLine, IsHandled);
        if not IsHandled then begin
            InitGLEntry(
                GenJnlLine, GLEntry, '', GenJnlLine."Amount (LCY)", GenJnlLine."Source Currency Amount", true, GenJnlLine."System-Created Entry",
                CalcAmountSrcCurr(GenJnlLine, GenJnlLine."Amount (LCY)"));
            GLEntry."Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
            GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
            GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
            InitVAT(GenJnlLine, GLEntry, VATPostingSetup);
            GLEntry2 := GLEntry;
            IsHandled := false;
            OnPostFixedAssetOnBeforeGenJnlPostLine(GenJnlLine, GLEntry2, NextTransactionNo, NextEntryNo, GLReg, IsHandled);
            if not IsHandled then
                FAJnlPostLine.GenJnlPostLine(
                    GenJnlLine, GLEntry2.Amount, GLEntry2."VAT Amount", NextTransactionNo, NextEntryNo, GLReg."No.");
            ShortcutDim1Code := GenJnlLine."Shortcut Dimension 1 Code";
            ShortcutDim2Code := GenJnlLine."Shortcut Dimension 2 Code";
            DimensionSetID := GenJnlLine."Dimension Set ID";
            Correction2 := GenJnlLine.Correction;
            OnPostFixedAssetOnAfterSaveGenJnlLineValues(GenJnlLine);
            VATEntryGLEntryNo := 0;
            if FAJnlPostLine.FindFirstGLAcc(TempFAGLPostBuf) then
                repeat
                    GenJnlLine."Shortcut Dimension 1 Code" := TempFAGLPostBuf."Global Dimension 1 Code";
                    GenJnlLine."Shortcut Dimension 2 Code" := TempFAGLPostBuf."Global Dimension 2 Code";
                    GenJnlLine."Dimension Set ID" := TempFAGLPostBuf."Dimension Set ID";
                    GenJnlLine.Correction := TempFAGLPostBuf.Correction;

                    OnPostFixedAssetOnBeforeInitGLEntryFromTempFAGLPostBuf(GenJnlLine, TempFAGLPostBuf);
                    FADimAlreadyChecked := TempFAGLPostBuf."FA Posting Group" <> '';
                    CheckDimValueForDisposal(GenJnlLine, TempFAGLPostBuf."Account No.");
                    if TempFAGLPostBuf."Original General Journal Line" then begin
                        InitGLEntry(
                            GenJnlLine, GLEntry, TempFAGLPostBuf."Account No.", TempFAGLPostBuf.Amount, GLEntry2."Additional-Currency Amount", true, true,
                            CalcAmountSrcCurr(GenJnlLine, TempFAGLPostBuf.Amount));
                        OriginalGLAccNo := TempFAGLPostBuf."Account No.";
                    end else begin
                        CheckNonAddCurrCodeOccurred('');
                        InitGLEntry(
                            GenJnlLine, GLEntry, TempFAGLPostBuf."Account No.", TempFAGLPostBuf.Amount, 0, false, true,
                            CalcAmountSrcCurr(GenJnlLine, TempFAGLPostBuf.Amount));
                    end;
                    FADimAlreadyChecked := false;
                    GLEntry.CopyPostingGroupsFromGLEntry(GLEntry2);
                    GLEntry."VAT Amount" := GLEntry2."VAT Amount";
                    GLEntry."Bal. Account Type" := GLEntry2."Bal. Account Type";
                    GLEntry."Bal. Account No." := GLEntry2."Bal. Account No.";
                    GLEntry."FA Entry Type" := TempFAGLPostBuf."FA Entry Type";
                    GLEntry."FA Entry No." := TempFAGLPostBuf."FA Entry No.";
                    if TempFAGLPostBuf."Net Disposal" then
                        NetDisposalNo := NetDisposalNo + 1
                    else
                        NetDisposalNo := 0;
                    if TempFAGLPostBuf."Automatic Entry" and not TempFAGLPostBuf."Net Disposal" then
                        FAAutomaticEntry.AdjustGLEntry(GLEntry);
                    if NetDisposalNo > 1 then
                        GLEntry."VAT Amount" := 0;
                    if TempFAGLPostBuf."FA Posting Group" <> '' then begin
                        FAGLPostBuf := TempFAGLPostBuf;
                        FAGLPostBuf."Entry No." := NextEntryNo;
                        FAGLPostBuf.Insert();
                    end;
                    IsHandled := false;
                    OnPostFixedAssetOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled, TempFAGLPostBuf, GLEntry2, NextEntryNo, TempGLEntryVATEntryLink);
                    if not IsHandled then
                        InsertGLEntry(GenJnlLine, GLEntry, true);
                    if (VATEntryGLEntryNo = 0) and (GLEntry."Gen. Posting Type" <> GLEntry."Gen. Posting Type"::" ") then
                        VATEntryGLEntryNo := GLEntry."Entry No.";
                until FAJnlPostLine.GetNextGLAcc(TempFAGLPostBuf) = 0;
            GenJnlLine."Shortcut Dimension 1 Code" := ShortcutDim1Code;
            GenJnlLine."Shortcut Dimension 2 Code" := ShortcutDim2Code;
            OnPostFixedAssetOnAfterSetGenJnlLineShortcutDimCodes(GenJnlLine);
            GenJnlLine."Dimension Set ID" := DimensionSetID;
            GenJnlLine.Correction := Correction2;
            GenJnlLine."FA G/L Account No." := OriginalGLAccNo;
            if GenJnlLine."FA G/L Account No." = '' then
                GenJnlLine."FA G/L Account No." := GLEntry."G/L Account No.";
            OnPostFixedAssetOnBeforeAssignGLEntry(GenJnlLine, GLEntry, GLEntry2);
            GLEntry := GLEntry2;
            if VATEntryGLEntryNo = 0 then
                VATEntryGLEntryNo := GLEntry."Entry No.";
            TempGLEntryBuf."Entry No." := VATEntryGLEntryNo; // Used later in InsertVAT(): GLEntryVATEntryLink.InsertLink(TempGLEntryBuf."Entry No.",VATEntry."Entry No.")
            OnPostFixedAssetOnBeforePostVAT(GenJnlLine);
            PostVAT(GenJnlLine, GLEntry, VATPostingSetup);
            FAJnlPostLine.UpdateRegNo(GLReg."No.");
        end;
        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
        OnAfterPostFixedAsset(GenJnlLine, TempGLEntryVATEntryLink);
    end;

    /// <summary>
    /// Wrapper procedure for external call of PostFixedAssetPostFixedAsset, which is used for posting a Gen. Journal Line with Account Type Fixed Asset.
    /// G/L Entries, VAT Entries and FA Ledger Entries are created.
    /// </summary>
    /// <remarks>
    /// In the procedure there is no check if Account Type is Fixed Asset.
    /// </remarks>
    /// <param name="GenJnlLine">General Journal Line that is being posted.</param>
    procedure RunPostFixedAsset(GenJnlLine: Record "Gen. Journal Line")
    begin
        // Wrapper procedure for exetrrnal call of PostFixedAsset
        PostFixedAsset(GenJnlLine);
    end;

    local procedure PostICPartner(GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        AccountNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostICPartner(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Account No." <> ICPartner.Code then
            ICPartner.Get(GenJnlLine."Account No.");
        if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") xor (GenJnlLine.Amount > 0) then begin
            ICPartner.TestField("Receivables Account");
            AccountNo := ICPartner."Receivables Account";
        end else begin
            ICPartner.TestField("Payables Account");
            AccountNo := ICPartner."Payables Account";
        end;

        IsHandled := false;
        OnPostICPartnerOnBeforeCreateGLEntryBalAcc(GenJnlLine, NextEntryNo, IsHandled);
        if not IsHandled then
            CreateGLEntryBalAcc(
              GenJnlLine, AccountNo, GenJnlLine."Amount (LCY)", GenJnlLine."Source Currency Amount",
              GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
    end;

    local procedure FindJobLineSign(GenJnlLine: Record "Gen. Journal Line")
    begin
        JobLine := (GenJnlLine."Job No." <> '');
        OnAfterFindJobLineSign(GenJnlLine, JobLine);
    end;

    /// <summary>
    /// Wrapper procedure for external call of PostJob, which is used for posting a gen. journal line with account type job.
    /// G/l entries, job entries, usage related ledger entries (resourse or item and value), possibly warehouse entries are created.
    /// </summary>
    /// <remarks>
    /// Procedure should not be called externally.
    /// Global variable determining if the gen. journal line is related to the job is set in the procedure.
    /// </remarks>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="GLEntry">G/l entry created for the gen. journal line.</param>
    procedure PostJob(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    var
        JobPostLine: Codeunit "Job Post-Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostJob(GenJnlLine, GLEntry, JobLine, IsHandled);
        if IsHandled then
            exit;

        if JobLine then begin
            JobLine := false;
            JobPostLine.PostGenJnlLine(GenJnlLine, GLEntry);
        end;
    end;

    /// <summary>
    /// Initialize global variables and G/L Register for new posting batch, locks needed tables.
    /// </summary>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    procedure StartPosting(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        OnBeforeStartPosting(GenJnlLine);

        InitNextEntryNo();
        FirstTransactionNo := NextTransactionNo;

        InitLastDocDate(GenJnlLine);
        CurrentBalance := 0;

        FiscalYearStartDate := AccountingPeriodMgt.GetPeriodStartingDate();

        GetGLSetup();

        if not GenJnlTemplate.Get(GenJnlLine."Journal Template Name") then
            GenJnlTemplate.Init();

        OnStartPostingOnBeforeSetNextVatEntryNo(VATEntry);
        VATEntry.LockTable();
        if VATEntry.FindLast() then
            NextVATEntryNo := VATEntry."Entry No." + 1
        else
            NextVATEntryNo := 1;
        OnStartPostingOnAfterSetNextVatEntryNo(VATEntry, NextVATEntryNo);

        NextConnectionNo := 1;
        FirstNewVATEntryNo := NextVATEntryNo;

        GLReg.LockTable();
        if GLReg.FindLast() then
            GLReg."No." := GLReg."No." + 1
        else
            GLReg."No." := 1;
        GLReg.Init();
        GLReg."From Entry No." := NextEntryNo;
        GLReg."From VAT Entry No." := NextVATEntryNo;
        GLReg."Source Code" := GenJnlLine."Source Code";
        GLReg."Journal Templ. Name" := GenJnlTemplate.Name;
        GLReg."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        GLReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLReg."User ID"));
        IsGLRegInserted := false;

        OnAfterInitGLRegister(GLReg, GenJnlLine);

        GetCurrencyExchRate(GenJnlLine);
        TempGLEntryBuf.DeleteAll();
        TempGLEntryPreview.DeleteAll();
        CalculateCurrentBalance(
          GenJnlLine."Account No.", GenJnlLine."Bal. Account No.", GenJnlLine.IncludeVATAmount(), GenJnlLine."Amount (LCY)", GenJnlLine."VAT Amount");

        OnAfterStartPosting(GenJnlLine);
    end;

    /// <summary>
    /// If new transaction needs to be started, Unrealized VAT is check and posted, global values initialized for the new transaction. 
    /// Currency is updated for the new Gen. Journal Line that is being posted, current Balance of the posting is updated.
    /// </summary>
    /// <param name="GenJnlLine">Gen. Journal Line that is being posted.</param>
    procedure ContinuePosting(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeContinuePosting(GenJnlLine, GLReg, NextEntryNo, NextTransactionNo, IsHandled);
        if IsHandled then
            exit;

        if NextTransactionNoNeeded(GenJnlLine) then begin
            CheckPostUnrealizedVAT(GenJnlLine, false);
            IsHandled := false;
            OnContinuePostingOnIncreaseNextTransactionNo(GenJnlLine, NextTransactionNo, IsHandled);
            if not IsHandled then
                NextTransactionNo := NextTransactionNo + 1;
            InitLastDocDate(GenJnlLine);
            FirstNewVATEntryNo := NextVATEntryNo;
        end;

        OnContinuePostingOnBeforeCalculateCurrentBalance(GenJnlLine, NextTransactionNo);

        GetCurrencyExchRate(GenJnlLine);
        TempGLEntryBuf.DeleteAll();
        if not GLEntryInconsistent then
            TempGLEntryPreview.DeleteAll();
        CalculateCurrentBalance(
          GenJnlLine."Account No.", GenJnlLine."Bal. Account No.", GenJnlLine.IncludeVATAmount(),
          GenJnlLine."Amount (LCY)", GenJnlLine."VAT Amount");
    end;

    local procedure NextTransactionNoNeeded(GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        LastDocTypeOption: Option;
        NewTransaction: Boolean;
    begin
        NewTransaction :=
            (LastDocType <> GenJnlLine."Document Type") or (LastDocNo <> GenJnlLine."Document No.") or
            (LastDate <> GenJnlLine."Posting Date") or ((CurrentBalance = 0) and (TotalAddCurrAmount = 0)) and not GenJnlLine."System-Created Entry";
        LastDocTypeOption := LastDocType.AsInteger();
        OnNextTransactionNoNeeded(GenJnlLine, LastDocTypeOption, LastDocNo, LastDate, CurrentBalance, TotalAddCurrAmount, NewTransaction);
        LastDocType := "Gen. Journal Document Type".FromInteger(LastDocTypeOption);
        exit(NewTransaction);
    end;

    /// <summary>
    /// Checks if transaction is balanced for both local and additional currencies, inserts all G/L Entries that were created for the Gen. Journal Line. 
    /// If posting is performed for application purpose, original Customer and Vendor Ledger Entries are updated to reflect that.
    /// Cost journal line is posted if cost accounting setup is setup for this purpose.
    /// </summary>
    /// <param name="GenJournalLine">Gen. Journal Line that is being posted.</param>
    /// <returns>True if balance of the transaction is balanced for both local and additional currencies.</returns>
    procedure FinishPosting(GenJournalLine: Record "Gen. Journal Line") IsTransactionConsistent: Boolean
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        TransferGlEntriesToCA: Codeunit "Transfer GL Entries to CA";
        IsTransactionConsistentExternal: Boolean;
    begin
        OnBeforeFinishPosting(GenJournalLine, TempGLEntryBuf);

        IsTransactionConsistent :=
          (BalanceCheckAmount = 0) and (BalanceCheckAmount2 = 0) and
          (BalanceCheckAddCurrAmount = 0) and (BalanceCheckAddCurrAmount2 = 0) and
          (BalanceCheckSrcCurrAmount = 0) and (BalanceCheckSrcCurrAmount2 = 0);

        IsTransactionConsistentExternal := IsTransactionConsistent;
        GlobalGLEntry.Consistent(IsTransactionConsistent);

        OnAfterSettingIsTransactionConsistent(GenJournalLine, IsTransactionConsistentExternal);

        IsTransactionConsistent := IsTransactionConsistent and IsTransactionConsistentExternal;

        if TempGLEntryBuf.FindSet() then begin
            repeat
                TempGLEntryPreview := TempGLEntryBuf;
                TempGLEntryPreview.Insert();
                GlobalGLEntry := TempGLEntryBuf;
                if AddCurrencyCode = '' then begin
                    GlobalGLEntry."Additional-Currency Amount" := 0;
                    GlobalGLEntry."Add.-Currency Debit Amount" := 0;
                    GlobalGLEntry."Add.-Currency Credit Amount" := 0;
                end;
                GlobalGLEntry."Prior-Year Entry" := GlobalGLEntry."Posting Date" < FiscalYearStartDate;
                OnBeforeInsertGlobalGLEntry(GlobalGLEntry, GenJournalLine, GLReg, FiscalYearStartDate);
                GlobalGLEntry.Insert(true);
                if GlobalGLEntry."Source Currency Code" <> '' then
                    InsertGLAccountSourceCurrency(GlobalGLEntry);
                OnAfterInsertGlobalGLEntry(GlobalGLEntry, TempGLEntryBuf, NextEntryNo, GenJournalLine);

                GlobalGLEntry.CopyLinks(GenJournalLine);
            until TempGLEntryBuf.Next() = 0;

            GLReg."To VAT Entry No." := NextVATEntryNo - 1;
            GLReg."To Entry No." := GlobalGLEntry."Entry No.";
            UpdateGLReg(IsTransactionConsistent, GenJournalLine);
            SetGLAccountNoInVATEntries();
        end;

        GlobalGLEntry.Consistent(IsTransactionConsistent);

        if CostAccountingSetup.Get() then
            if CostAccountingSetup."Auto Transfer from G/L" then
                TransferGlEntriesToCA.GetGLEntries();

        OnFinishPostingOnBeforeResetFirstEntryNo(GlobalGLEntry, NextEntryNo, FirstEntryNo, GenJournalLine);
        FirstEntryNo := 0;

        if IsTransactionConsistent then
            UpdateAppliedCVLedgerEntries();

        OnAfterFinishPosting(GlobalGLEntry, GLReg, IsTransactionConsistent, GenJournalLine);
    end;

    local procedure UpdateGLReg(IsTransactionConsistent: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGLReg(IsTransactionConsistent, IsGLRegInserted, GLReg, IsHandled, GenJnlLine, GlobalGLEntry, FirstNewVATEntryNo);
        if IsHandled then
            exit;

        if IsTransactionConsistent then
            if IsGLRegInserted then
                GLReg.Modify()
            else begin
                GLReg.Insert();
                IsGLRegInserted := true;
            end;
    end;

    local procedure UpdateAppliedCVLedgerEntries()
    var
        VendorLedgerEntryApplied: Record "Vendor Ledger Entry";
        CustLedgEntryApplied: Record "Cust. Ledger Entry";
    begin
        if TempVendorLedgerEntry.FindSet() then begin
            repeat
                if VendorLedgerEntryApplied.Get(TempVendorLedgerEntry."Entry No.") then begin
                    VendorLedgerEntryApplied."Applies-to ID" := '';
                    VendorLedgerEntryApplied."Amount to Apply" := 0;
                    VendorLedgerEntryApplied.Modify();
                end;
            until TempVendorLedgerEntry.Next() = 0;
            TempVendorLedgerEntry.DeleteAll();
        end;
        if TempCustLedgEntry.FindSet() then begin
            repeat
                if CustLedgEntryApplied.Get(TempCustLedgEntry."Entry No.") then begin
                    CustLedgEntryApplied."Applies-to ID" := '';
                    CustLedgEntryApplied."Amount to Apply" := 0;
                    CustLedgEntryApplied.Modify();
                end;
            until TempCustLedgEntry.Next() = 0;
            TempCustLedgEntry.DeleteAll();
        end;
    end;

    local procedure InsertGLAccountSourceCurrency(var GLEntry: Record "G/L Entry")
    var
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        if not GLAccountSourceCurrency.Get(GLEntry."G/L Account No.", GLEntry."Source Currency Code") then begin
            GLAccountSourceCurrency.Init();
            GLAccountSourceCurrency."G/L Account No." := GLEntry."G/L Account No.";
            GLAccountSourceCurrency."Currency Code" := GLEntry."Source Currency Code";
            GLAccountSourceCurrency.Insert();
        end;
    end;

    local procedure PostUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line")
    begin
        if CheckUnrealizedCust then begin
            CustUnrealizedVAT(GenJnlLine, UnrealizedCustLedgEntry, UnrealizedRemainingAmountCust);
            CheckUnrealizedCust := false;
        end;
        if CheckUnrealizedVend then begin
            VendUnrealizedVAT(GenJnlLine, UnrealizedVendLedgEntry, UnrealizedRemainingAmountVend);
            CheckUnrealizedVend := false;
        end;
    end;

    local procedure CheckPostUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; CheckCurrentBalance: Boolean)
    begin
        if CheckCurrentBalance and (CurrentBalance = 0) or not CheckCurrentBalance then
            PostUnrealizedVAT(GenJnlLine)
    end;

    /// <summary>
    /// Initializes g/l entry from gen. journal line.
    /// </summary>
    /// <remarks>
    /// If g/l account used for posting has restricted dimensions, error is raised.
    /// If g/l account selected for the gen. journal line is blocked or have different posting type.
    /// </remarks>
    /// <param name="GenJnlLine">general journal line that is being posted.</param>
    /// <param name="GLEntry">Return value: g/l entry that is being created.</param>
    /// <param name="GLAccNo">G/l account that will be used to create e/l entry.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="UseAmountAddCurr">Determines if amount in the field "Additional-Currency Amount" should be used for the new g/l entry or should it be caculated.</param>
    /// <param name="SystemCreatedEntry">Determines if g/l entry is created by the system.</param>
    procedure InitGLEntry(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; SystemCreatedEntry: Boolean)
    begin
        InitGLEntry(GenJnlLine, GLEntry, GLAccNo, Amount, AmountAddCurr, UseAmountAddCurr, SystemCreatedEntry, 0);
    end;

    procedure InitGLEntry(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; SystemCreatedEntry: Boolean; AmountSrcCurr: Decimal)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGLEntry(GenJnlLine, GLAccNo, SystemCreatedEntry, Amount, AmountAddCurr, FADimAlreadyChecked, IsHandled, GLEntry, UseAmountAddCurr, NextEntryNo, NextTransactionNo);
        if not IsHandled then begin
            if GLAccNo <> '' then begin
                GLAcc.Get(GLAccNo);

                IsHandled := false;
                OnInitGLEntryOnBeforeCheckGLAccountBlocked(GenJnlLine, GLAcc, IsHandled);
                if not IsHandled then
                    GLAcc.TestField(Blocked, false);
                GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);

                // Check the Value Posting field on the G/L Account if it is not checked already in Codeunit 11
                if (not
                    ((GLAccNo = GenJnlLine."Account No.") and
                    (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account")) or
                    ((GLAccNo = GenJnlLine."Bal. Account No.") and
                    (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account"))) and
                not FADimAlreadyChecked
                then begin
                    OnInitGLEntryOnBeforeCheckGLAccDimError(GenJnlLine, GLAcc);
                    CheckGLAccDimError(GenJnlLine, GLAccNo);
                end;
            end;

            GLEntry.Init();
            GLEntry.CopyFromGenJnlLine(GenJnlLine);
            GLEntry."Entry No." := NextEntryNo;
            GLEntry."Transaction No." := NextTransactionNo;
            GLEntry."G/L Account No." := GLAccNo;
            GLEntry."System-Created Entry" := SystemCreatedEntry;
            GLEntry.Amount := Amount;
            GLEntry."Additional-Currency Amount" :=
                GLCalcAddCurrency(Amount, AmountAddCurr, GLEntry."Additional-Currency Amount", UseAmountAddCurr, GenJnlLine);

            if GLEntry."G/L Account No." <> '' then begin
                GLAcc.Get(GLEntry."G/L Account No.");
                GenJnlCheckLine.CheckGLAccountSourceCurrency(GLAcc, GenJnlLine."Source Currency Code");
            end;
            GLEntry."Source Currency Code" := GenJnlLine."Source Currency Code";
            if not GenJnlLine."Zero Src. Curr. Amount" then
                GLEntry."Source Currency Amount" := AmountSrcCurr;
        end;

        OnAfterInitGLEntry(GLEntry, GenJnlLine, Amount, AmountAddCurr, UseAmountAddCurr, CurrencyFactor, GLReg);
    end;

    /// <summary>
    /// Initializes g/l entry from gen. journal line and summarizes VAT g/l entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="AccNo">G/l account that will be used for new g/l entry.</param>
    /// <param name="BalAccNo">Account that will be used for new g/l entry as the balancing account.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="UseAmtAddCurr">Determines if amount in the field "Additional-Currency Amount" should be used for the new g/l entry or should it be caculated.</param>
    procedure InitGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; BalAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmtAddCurr: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeInitGLEntryVAT(GenJnlLine, GLEntry);
        if UseAmtAddCurr then
            InitGLEntry(
                GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true,
                CalcAmountSrcCurr(GenJnlLine, Amount))
        else begin
            InitGLEntry(
                GenJnlLine, GLEntry, AccNo, Amount, 0, false, true,
                CalcAmountSrcCurr(GenJnlLine, Amount));
            GLEntry."Additional-Currency Amount" := AmountAddCurr;
            GLEntry."Bal. Account No." := BalAccNo;
        end;
        OnInitGLEntryVATOnBeforeSummarizeVAT(GenJnlLine, GLEntry, VATEntry);
        SummarizeVATFromInitGLEntryVAT(GLEntry, Amount);
        OnAfterInitGLEntryVAT(GenJnlLine, GLEntry);
    end;

    local procedure SummarizeVATFromInitGLEntryVAT(var GLEntry: Record "G/L Entry"; Amount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummarizeVATFromInitGLEntryVAT(GLEntry, Amount, IsHandled);
        if IsHandled then
            exit;

        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry);
    end;

    procedure InitGLEntryVATCopy(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; BalAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATEntry: Record "VAT Entry"): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeInitGLEntryVATCopy(GenJnlLine, GLEntry, VATEntry, NextEntryNo);
        InitGLEntry(
            GenJnlLine, GLEntry, AccNo, Amount, 0, false, true,
            CalcAmountSrcCurr(GenJnlLine, Amount));
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."Bal. Account No." := BalAccNo;
        GLEntry.CopyPostingGroupsFromVATEntry(VATEntry);
        OnInitGLEntryVATCopyOnBeforeSummarizeVAT(GenJnlLine, GLEntry, VATEntry);
        SummarizeVAT(GLSetup."Summarize G/L Entries", GLEntry);
        OnAfterInitGLEntryVATCopy(GenJnlLine, GLEntry);

        exit(GLEntry."Entry No.");
    end;

    /// <summary>
    /// Updates the amounts of the g/l entry and adds it to the TempGLEntryBuffer to be inserted.
    /// </summary>
    /// <remarks>
    /// If g/l entry amount is not properly rounded, error is raised.
    /// </remarks>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="GLEntry">G/l entry that needs to be inserted.</param>
    /// <param name="CalcAddCurrResiduals">Determined if residual rounding amount should be posted as a separate g/l entry.</param>
    procedure InsertGLEntry(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; CalcAddCurrResiduals: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertGlEntry(GenJnlLine, GLEntry, IsHandled);
        if not IsHandled then begin
            GLEntry.TestField("G/L Account No.");

            IsHandled := false;
            OnInsertGLEntryOnBeforeCheckAmountRounding(GLEntry, IsHandled, GenJnlLine);
            if not IsHandled then
                if GLEntry.Amount <> Round(GLEntry.Amount) then
                    GLEntry.FieldError(GLEntry.Amount, StrSubstNo(NeedsRoundingErr, GLEntry.Amount));

            OnInsertGLEntryOnBeforeUpdateCheckAmounts(GLSetup, GLEntry, BalanceCheckAmount, BalanceCheckAmount2, BalanceCheckAddCurrAmount, BalanceCheckAddCurrAmount2);
            UpdateCheckAmounts(
              GLEntry."Posting Date", GLEntry.Amount, GLEntry."Additional-Currency Amount", GLEntry."Source Currency Amount",
              BalanceCheckAmount, BalanceCheckAmount2, BalanceCheckAddCurrAmount, BalanceCheckAddCurrAmount2, BalanceCheckSrcCurrAmount, BalanceCheckSrcCurrAmount2);

            GLEntry.UpdateDebitCredit(GenJnlLine.Correction);

            OnInsertGLEntryOnBeforeAssignTempGLEntryBuf(GLEntry, GenJnlLine, GLReg);

            TempGLEntryBuf := GLEntry;

            OnBeforeInsertGLEntryBuffer(
                TempGLEntryBuf, GenJnlLine, BalanceCheckAmount, BalanceCheckAmount2, BalanceCheckAddCurrAmount, BalanceCheckAddCurrAmount2,
                NextEntryNo, TotalAmount, TotalAddCurrAmount, GLEntry);

            TempGLEntryBuf.Insert();

            if FirstEntryNo = 0 then
                FirstEntryNo := TempGLEntryBuf."Entry No.";
            IncrNextEntryNo();

            if CalcAddCurrResiduals then
                HandleAddCurrResidualGLEntry(GenJnlLine, GLEntry);

        end;

        OnAfterInsertGLEntry(GLEntry, GenJnlLine, TempGLEntryBuf, CalcAddCurrResiduals);
    end;

    /// <summary>
    /// Initializes the g/l entry from the general journal line and adds it to the TempGLEntryBuffer to be inserted.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="AccNo">G/l account that will be used for new g/l entry.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="UseAmtAddCurr">Determines if amount in the field "Additional-Currency Amount" should be used for the new g/l entry or should it be caculated.</param>
    procedure CreateGLEntry(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    begin
        CreateGLEntry(GenJnlLine, AccNo, Amount, AmountAddCurr, UseAmountAddCurr, 0);
    end;

    procedure CreateGLEntry(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; UseAmountAddCurr: Boolean; AmountSrcCurr: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        if (AddCurrencyCode <> '') and MultiplePostingGroups then
            UseAmountAddCurr := true;
        if UseAmountAddCurr then
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true, AmountSrcCurr)
        else begin
            InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, false, true, AmountSrcCurr);
            GLEntry."Additional-Currency Amount" := AmountAddCurr;
        end;
        OnCreateGLEntryOnBeforeInsertGLEntry(GenJnlLine, GLEntry, VATEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);

        OnAfterCreateGLEntry(GenJnlLine, GLEntry, NextEntryNo);
    end;

    /// <summary>
    /// Initializes the g/l entry from the general journal line. Fills balance account information and adds it to the TempGLEntryBuffer to be inserted.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="AccNo">G/l account that will be used for new g/l entry.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="BalAccType">Balance account type to be used for the g/l entry.</param>
    /// <param name="BalAccNo">Balance account no. to be used for the g/l entry.</param>
    procedure CreateGLEntryBalAcc(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeCreateGLEntryBalAcc(GenJnlLine, AccNo, Amount, AmountAddCurr, BalAccType, BalAccNo);
        InitGLEntry(
            GenJnlLine, GLEntry, AccNo, Amount, AmountAddCurr, true, true,
            CalcAmountSrcCurr(GenJnlLine, Amount));
        GLEntry."Bal. Account Type" := BalAccType;
        GLEntry."Bal. Account No." := BalAccNo;
        InsertGLEntry(GenJnlLine, GLEntry, true);
        OnMoveGenJournalLine(GenJnlLine, GLEntry.RecordId);
        OnAfterCreateGLEntryBalAcc(GenJnlLine, GLEntry);
    end;

    local procedure CreateGLEntryGainLoss(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; UseAmountAddCurr: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        SetPostingDimensions(GenJnlLine, AccNo);
        InitGLEntry(GenJnlLine, GLEntry, AccNo, Amount, 0, UseAmountAddCurr, true, 0);
        OnBeforeCreateGLEntryGainLossInsertGLEntry(GenJnlLine, GLEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);
    end;

    /// <summary>
    /// Initializes the g/l entry from the general journal line and detailed cv. ledger entry buffer, adds the g/l entry to the TempGLEntryBuffer to be inserted.
    /// Inserts vat entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="AccNo">G/l account that will be used for new g/l entry.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="VATAmount">Vat amount that will be used for g/l entry.</param>
    /// <param name="DtldCVLedgEntryBuf">DtldCVLedgerEntry Buffer that holds the information about posting groups and tax information that will be used for g/l entry creation.</param>
    procedure CreateGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeCreateGLEntryVAT(GenJnlLine, DtldCVLedgEntryBuf);
        InitGLEntry(
            GenJnlLine, GLEntry, AccNo, Amount, 0, false, true,
            CalcAmountSrcCurr(GenJnlLine, Amount));
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, DtldCVLedgEntryBuf."Gen. Posting Type".AsInteger());
        OnCreateGLEntryVATOnBeforeInsertGLEntry(GenJnlLine, GLEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    /// <summary>
    /// Initializes the g/l entry from the general journal line and detailed cv. ledger entry buffer, adds the g/l entry to the TempGLEntryBuffer to be inserted.
    /// Collects needed adjustments, inserts vat entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that is being posted.</param>
    /// <param name="AccNo">G/l account that will be used for new g/l entry.</param>
    /// <param name="Amount">Amount that will be used for g/l entry (in local currency).</param>
    /// <param name="AmountAddCurr">Amount that will be used for g/l entry (in additional currency).</param>
    /// <param name="VATAmount">Vat amount that will be used for g/l entry.</param>
    /// <param name="DtldCVLedgEntryBuf">DtldCVLedgerEntry Buffer that holds the information about posting groups and tax information that will be used for g/l entry creation.</param>
    /// <param name="AdjAmount">Return value: the adjustment amount for the g/l entry.</param>
    procedure CreateGLEntryVATCollectAdj(GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATAmount: Decimal; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var AdjAmount: array[4] of Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        OnBeforeCreateGLEntryVATCollectAdj(GenJnlLine, DtldCVLedgEntryBuf);
        InitGLEntry(
            GenJnlLine, GLEntry, AccNo, Amount, 0, false, true,
            CalcAmountSrcCurr(GenJnlLine, Amount));
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry."VAT Amount" := VATAmount;
        GlEntry."Non-Deductible VAT Amount" := -DtldCVLedgEntryBuf."Non-Deductible VAT Amount LCY";
        GlEntry."Non-Deductible VAT Amount ACY" := -DtldCVLedgEntryBuf."Non-Deductible VAT Amount ACY";

        GLEntry.CopyPostingGroupsFromDtldCVBuf(DtldCVLedgEntryBuf, DtldCVLedgEntryBuf."Gen. Posting Type".AsInteger());
        InsertGLEntry(GenJnlLine, GLEntry, true);
        CollectAdjustment(AdjAmount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
        InsertVATEntriesFromTemp(DtldCVLedgEntryBuf, GLEntry);
    end;

    local procedure CreateGLEntryFromVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATAccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; VATEntry: Record "VAT Entry"): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        InitGLEntry(
            GenJnlLine, GLEntry, VATAccNo, Amount, 0, false, true,
            CalcAmountSrcCurr(GenJnlLine, Amount));
        GLEntry."Additional-Currency Amount" := AmountAddCurr;
        GLEntry.CopyPostingGroupsFromVATEntry(VATEntry);
        OnBeforeInsertGLEntryFromVATEntry(GLEntry, VATEntry);
        InsertGLEntry(GenJnlLine, GLEntry, true);
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateDeferralScheduleFromGL(var GenJournalLine: Record "Gen. Journal Line"; IsBalancing: Boolean)
    begin
        if (GenJournalLine."Account No." <> '') and (GenJournalLine."Deferral Code" <> '') then
            if ((GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor])
                and (JournalsSourceCodesList.Contains(GenJournalLine."Source Code"))) or
               (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"])
            then begin
                if not IsBalancing then
                    CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJournalLine);
                DeferralUtilities.CreateScheduleFromGL(GenJournalLine, FirstEntryNo);
            end;
    end;

    local procedure UpdateCheckAmounts(PostingDate: Date; Amount: Decimal; AddCurrAmount: Decimal; SrcCurrAmount: Decimal; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var BalanceCheckSrcCurrAmount: Decimal; var BalanceCheckSrcCurrAmount2: Decimal)
    begin
        if PostingDate = NormalDate(PostingDate) then begin
            BalanceCheckAmount :=
              BalanceCheckAmount + Amount * ((PostingDate - 00000101D) mod 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + Amount * ((PostingDate - 00000101D) mod 98 + 1);
        end else begin
            BalanceCheckAmount :=
              BalanceCheckAmount + Amount * ((NormalDate(PostingDate) - 00000101D + 50) mod 99 + 1);
            BalanceCheckAmount2 :=
              BalanceCheckAmount2 + Amount * ((NormalDate(PostingDate) - 00000101D + 50) mod 98 + 1);
        end;

        if AddCurrencyCode <> '' then
            if PostingDate = NormalDate(PostingDate) then begin
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount + AddCurrAmount * ((PostingDate - 00000101D) mod 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 + AddCurrAmount * ((PostingDate - 00000101D) mod 98 + 1);
            end else begin
                BalanceCheckAddCurrAmount :=
                  BalanceCheckAddCurrAmount +
                  AddCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 99 + 1);
                BalanceCheckAddCurrAmount2 :=
                  BalanceCheckAddCurrAmount2 +
                  AddCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 98 + 1);
            end
        else begin
            BalanceCheckAddCurrAmount := 0;
            BalanceCheckAddCurrAmount2 := 0;
        end;

        GetGLSetup();
        if GLSetup."Check Source Curr. Consistency" then
            if PostingDate = NormalDate(PostingDate) then begin
                BalanceCheckSrcCurrAmount += SrcCurrAmount * ((PostingDate - 00000101D) mod 99 + 1);
                BalanceCheckSrcCurrAmount2 += SrcCurrAmount * ((PostingDate - 00000101D) mod 98 + 1);
            end else begin
                BalanceCheckSrcCurrAmount += SrcCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 99 + 1);
                BalanceCheckSrcCurrAmount2 += SrcCurrAmount * ((NormalDate(PostingDate) - 00000101D + 50) mod 98 + 1);
            end
        else begin
            BalanceCheckSrcCurrAmount := 0;
            BalanceCheckSrcCurrAmount2 := 0;
        end;
    end;

    local procedure CalcPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        PaymentDiscountDateWithGracePeriod: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf, IsHandled, AmountRoundingPrecision);
        if IsHandled then
            exit;

        if GenJnlLine."Amount (LCY)" <> 0 then begin
            PaymentDiscountDateWithGracePeriod := CVLedgEntryBuf."Pmt. Discount Date";
            GLSetup.GetRecordOnce();
            if PaymentDiscountDateWithGracePeriod <> 0D then
                PaymentDiscountDateWithGracePeriod :=
                  CalcDate(GLSetup."Payment Discount Grace Period", PaymentDiscountDateWithGracePeriod);
            if (PaymentDiscountDateWithGracePeriod >= CVLedgEntryBuf."Posting Date") or
               (PaymentDiscountDateWithGracePeriod = 0D)
            then begin
                if GLSetup."Pmt. Disc. Excl. VAT" then begin
                    if GenJnlLine."Sales/Purch. (LCY)" = 0 then
                        CVLedgEntryBuf."Original Pmt. Disc. Possible" := (GenJnlLine."Amount (LCY)" + TotalVATAmountOnJnlLines(GenJnlLine)) * GenJnlLine.Amount / GenJnlLine."Amount (LCY)"
                    else
                        CVLedgEntryBuf."Original Pmt. Disc. Possible" := GenJnlLine."Sales/Purch. (LCY)" * GenJnlLine.Amount / GenJnlLine."Amount (LCY)"
                end else
                    CVLedgEntryBuf."Original Pmt. Disc. Possible" := GenJnlLine.Amount;
                OnCalcPmtDiscPossibleOnBeforeOriginalPmtDiscPossible(GenJnlLine, CVLedgEntryBuf, AmountRoundingPrecision);
                CVLedgEntryBuf."Original Pmt. Disc. Possible" :=
                    Round(CVLedgEntryBuf."Original Pmt. Disc. Possible" * GenJnlLine."Payment Discount %" / 100, AmountRoundingPrecision);
            end;
            CVLedgEntryBuf."Remaining Pmt. Disc. Possible" := CVLedgEntryBuf."Original Pmt. Disc. Possible";
        end;

        OnAfterCalcPmtDiscPossible(GenJnlLine, CVLedgEntryBuf);
    end;

    local procedure CalcPmtTolerancePossible(GenJnlLine: Record "Gen. Journal Line"; PmtDiscountDate: Date; var PmtDiscToleranceDate: Date; var MaxPaymentTolerance: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtTolerancePossible(GenJnlLine, PmtDiscountDate, PmtDiscToleranceDate, MaxPaymentTolerance, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo"] then begin
            if PmtDiscountDate <> 0D then
                PmtDiscToleranceDate := CalcDate(GLSetup."Payment Discount Grace Period", PmtDiscountDate)
            else
                PmtDiscToleranceDate := PmtDiscountDate;

            case GenJnlLine."Account Type" of
                GenJnlLine."Account Type"::Customer:
                    PaymentToleranceMgt.CalcMaxPmtTolerance(GenJnlLine."Document Type", GenJnlLine."Currency Code", GenJnlLine.Amount, GenJnlLine."Amount (LCY)", 1, MaxPaymentTolerance);
                GenJnlLine."Account Type"::Vendor:
                    PaymentToleranceMgt.CalcMaxPmtTolerance(GenJnlLine."Document Type", GenJnlLine."Currency Code", GenJnlLine.Amount, GenJnlLine."Amount (LCY)", -1, MaxPaymentTolerance);
            end;
        end;
    end;

    local procedure CalcPmtTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtTol: Decimal;
        PmtTolLCY: Decimal;
        PmtTolAddCurr: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolAmtToBeApplied, IsHandled);
        if IsHandled then
            exit;

        if OldCVLedgEntryBuf2."Accepted Payment Tolerance" = 0 then
            exit;

        PmtTol := -OldCVLedgEntryBuf2."Accepted Payment Tolerance";
        PmtTolAmtToBeApplied := PmtTolAmtToBeApplied + PmtTol;
        PmtTolLCY :=
            Round((NewCVLedgEntryBuf."Original Amount" + PmtTol) / NewCVLedgEntryBuf."Original Currency Factor") -
            NewCVLedgEntryBuf."Original Amt. (LCY)";

        OnCalcPmtToleranceOnAfterAssignPmtDisc(
            PmtTol, PmtTolLCY, PmtTolAmtToBeApplied, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
            NewCVLedgEntryBuf, DtldCVLedgEntryBuf, NextTransactionNo, FirstNewVATEntryNo);

        OldCVLedgEntryBuf."Accepted Payment Tolerance" := 0;
        OldCVLedgEntryBuf."Pmt. Tolerance (LCY)" := -PmtTolLCY;

        if NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode then
            PmtTolAddCurr := PmtTol
        else
            PmtTolAddCurr := CalcLCYToAddCurr(PmtTolLCY);

        if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtTolLCY <> 0) then
            CalcPmtDiscIfAdjVAT(
                NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolLCY, PmtTolAddCurr,
                NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)");

        OnBeforeInitDetailedCVLedgEntryBufCalcPmtTolerance(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
            DtldCVLedgEntryBuf, GenJnlLine, PmtTolAmtToBeApplied, NextTransactionNo, FirstNewVATEntryNo, PmtTol, PmtTolLCY, PmtTolAddCurr);
        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
            GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance", PmtTol, PmtTolLCY, PmtTolAddCurr, 0, 0, 0);

        OnAfterCalcPmtTolerance(DtldCVLedgEntryBuf, OldCVLedgEntryBuf2, PmtTol, PmtTolLCY, GenJnlLine);
    end;

    local procedure CalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; PmtTolAmtToBeApplied: Decimal; ApplnRoundingPrecision: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDisc: Decimal;
        PmtDiscLCY: Decimal;
        PmtDiscAddCurr: Decimal;
        MinimalPossibleLiability: Decimal;
        PaymentExceedsLiability: Boolean;
        ToleratedPaymentExceedsLiability: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtTolAmtToBeApplied, IsHandled,
            ApplnRoundingPrecision, NextTransactionNo, FirstNewVATEntryNo, AddCurrencyCode);
        if IsHandled then
            exit;

        MinimalPossibleLiability := Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date"));
        OnAfterCalcMinimalPossibleLiability(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability);

        PaymentExceedsLiability := Abs(OldCVLedgEntryBuf2."Amount to Apply") >= MinimalPossibleLiability;
        OnAfterCalcPaymentExceedsLiability(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability, PaymentExceedsLiability);

        ToleratedPaymentExceedsLiability :=
            Abs(NewCVLedgEntryBuf."Remaining Amount" + PmtTolAmtToBeApplied) >= MinimalPossibleLiability;
        OnAfterCalcToleratedPaymentExceedsLiability(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, MinimalPossibleLiability,
            ToleratedPaymentExceedsLiability, PmtTolAmtToBeApplied);

        if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, true, true) and
            ((OldCVLedgEntryBuf2."Amount to Apply" = 0) or PaymentExceedsLiability) or
            (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
             (OldCVLedgEntryBuf2."Amount to Apply" <> 0) and PaymentExceedsLiability and ToleratedPaymentExceedsLiability))
        then begin
            PmtDisc := -OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date");
            PmtDiscLCY :=
              Round(
                (NewCVLedgEntryBuf."Original Amount" + PmtDisc) / NewCVLedgEntryBuf."Original Currency Factor") -
              NewCVLedgEntryBuf."Original Amt. (LCY)";

            OnCalcPmtDiscOnAfterAssignPmtDisc(PmtDisc, PmtDiscLCY, OldCVLedgEntryBuf, OldCVLedgEntryBuf2);

            OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscLCY;

            if (NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode) and (AddCurrencyCode <> '') then
                PmtDiscAddCurr := PmtDisc
            else
                PmtDiscAddCurr := CalcLCYToAddCurr(PmtDiscLCY);

            OnAfterCalcPmtDiscount(
                NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
                PmtTolAmtToBeApplied, PmtDisc, PmtDiscLCY, PmtDiscAddCurr);

            if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtDiscLCY <> 0) then
                CalcPmtDiscIfAdjVAT(
                  NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtDiscLCY, PmtDiscAddCurr,
                  NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)");

            OnCalcPmtDiscBeforeInitDetailedCVLedgEntryBuff(GenJnlLine, IsHandled);
            if not IsHandled then
                DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                    GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
                    DtldCVLedgEntryBuf."Entry Type"::"Payment Discount", PmtDisc, PmtDiscLCY, PmtDiscAddCurr, 0, 0, 0);

            OnCalcPmtDiscOnAfterCalcPmtDisc(DtldCVLedgEntryBuf, OldCVLedgEntryBuf2, PmtDisc, PmtDiscLCY, GenJnlLine);
        end;
    end;

    local procedure CalcPmtDiscIfAdjVAT(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        DtldCVLedgEntryBuf2: Record "Detailed CV Ledg. Entry Buffer";
        OriginalAmountAddCurr: Decimal;
        PmtDiscRounding: Decimal;
        PmtDiscRoundingAddCurr: Decimal;
        PmtDiscFactorLCY: Decimal;
        PmtDiscFactorAddCurr: Decimal;
        VATBase: Decimal;
        VATBaseAddCurr: Decimal;
        VATAmount: Decimal;
        VATAmountAddCurr: Decimal;
        TotalVATAmount: Decimal;
        NonDedVATBase: Decimal;
        NonDedVATBaseAddCurr: Decimal;
        NonDedVATAmount: Decimal;
        NonDedVATAmountAddCurr: Decimal;
        NonDedTotalVATAmount: Decimal;
        NonDedTotalVATAmountACY: Decimal;
        NonDedReverseChargeVATBasePmtDisc: Decimal;
        NonDedReverseChargeVATBasePmtDiscACY: Decimal;
        LastConnectionNo: Integer;
        VATEntryModifier: Integer;
    begin
        if OldCVLedgEntryBuf."Original Amt. (LCY)" = 0 then
            exit;

        if (AddCurrencyCode = '') or (AddCurrencyCode = OldCVLedgEntryBuf."Currency Code") then
            OriginalAmountAddCurr := OldCVLedgEntryBuf.Amount
        else
            OriginalAmountAddCurr := CalcLCYToAddCurr(OldCVLedgEntryBuf."Original Amt. (LCY)");

        PmtDiscRounding := PmtDiscLCY2;
        PmtDiscFactorLCY := PmtDiscLCY2 / OldCVLedgEntryBuf."Original Amt. (LCY)";
        if OriginalAmountAddCurr <> 0 then
            PmtDiscFactorAddCurr := PmtDiscAddCurr2 / OriginalAmountAddCurr
        else
            PmtDiscFactorAddCurr := 0;

        NonDedTotalVATAmount := 0;
        NonDedTotalVATAmountACY := 0;

        VATEntry2.ReadIsolation := IsolationLevel::ReadUncommitted;
        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", OldCVLedgEntryBuf."Transaction No.");
        if OldCVLedgEntryBuf."Transaction No." = NextTransactionNo then
            VATEntry2.SetRange("Entry No.", 0, FirstNewVATEntryNo - 1);

        OnCalcPmtDiscIfAdjVATOnBeforeVATEntryFind(
            GenJnlLine, OldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2,
            PmtDiscLCY2, PmtDiscAddCurr2, PmtDiscFactorLCY, PmtDiscFactorAddCurr);

        if VATEntry2.FindSet() then begin
            TotalVATAmount := 0;
            LastConnectionNo := 0;
            repeat
                OnCalcPmtDiscAdjVATAmountsOnBeforeProcessVATEntry(GenJnlLine, OldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2);

                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATEntry2."VAT Calculation Type" =
                   VATEntry2."VAT Calculation Type"::"Sales Tax"
                then begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    VATPostingSetup."Adjust for Payment Discount" :=
                      TaxJurisdiction."Adjust for Payment Discount";
                end;
                if VATPostingSetup."Adjust for Payment Discount" then begin
                    if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                        if LastConnectionNo <> 0 then begin
                            DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                            DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                            DtldCVLedgEntryBuf."Non-Deductible VAT Amount LCY" := -NonDedTotalVATAmount;
                            DtldCVLedgEntryBuf."Non-Deductible VAT Amount ACY" := -NonDedTotalVATAmountACY;
                            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, false);
                            OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAdjForPaymentDiscount(DtldCVLedgEntryBuf, OldCVLedgEntryBuf);
                            InsertSummarizedVAT(GenJnlLine);
                        end;

                        CalcPmtDiscVATBases(VATEntry2, VATBase, VATBaseAddCurr, NonDedVATBase, NonDedVATBaseAddCurr);

                        VATBase :=
                            CalcAmtMultipliedByFactorWithRounding(
                                PmtDiscRounding, PmtDiscLCY2, VATBase, PmtDiscFactorLCY);
                        NonDedVATBase :=
                            CalcAmtMultipliedByFactorWithRounding(
                                PmtDiscRounding, PmtDiscLCY2, NonDedVATBase, PmtDiscFactorLCY);

                        PmtDiscRoundingAddCurr := PmtDiscRoundingAddCurr + VATBaseAddCurr * PmtDiscFactorAddCurr;
                        VATBaseAddCurr := Round(CalcLCYToAddCurr(VATBase), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATBaseAddCurr;

                        PmtDiscRoundingAddCurr := PmtDiscRoundingAddCurr + NonDedVATBaseAddCurr * PmtDiscFactorAddCurr;
                        NonDedVATBaseAddCurr := Round(CalcLCYToAddCurr(NonDedVATBase), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + NonDedVATBaseAddCurr;

                        OnCalcPmtDiscIfAdjVATOnAfterCalcPmtDiscVATBases(VATEntry2, OldCVLedgEntryBuf, VATBase, VATBaseAddCurr, PmtDiscLCY2, PmtDiscAddCurr2);

                        DtldCVLedgEntryBuf2.Init();
                        DtldCVLedgEntryBuf2."Posting Date" := GenJnlLine."Posting Date";
                        DtldCVLedgEntryBuf2."Document Type" := GenJnlLine."Document Type";
                        DtldCVLedgEntryBuf2."Document No." := GenJnlLine."Document No.";
                        DtldCVLedgEntryBuf2.Amount := 0;
                        DtldCVLedgEntryBuf2."Amount (LCY)" := -VATBase;
                        if VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Normal VAT" then
                            DtldCVLedgEntryBuf2."Amount (LCY)" -= NonDedVATBase;
                        if VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Reverse Charge VAT" then begin
                            NonDedReverseChargeVATBasePmtDisc += NonDedVATBase;
                            NonDedReverseChargeVATBasePmtDiscACY += NonDedVATBaseAddCurr;
                        end;
                        DtldCVLedgEntryBuf2."Entry Type" := EntryType;
                        case EntryType of
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                VATEntryModifier := 1000000;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                VATEntryModifier := 2000000;
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                VATEntryModifier := 3000000;
                        end;
                        DtldCVLedgEntryBuf2.CopyFromCVLedgEntryBuf(NewCVLedgEntryBuf);
                        // The total payment discount in currency is posted on the entry made in
                        // the function CalcPmtDisc.
                        DtldCVLedgEntryBuf2."User ID" := CopyStr(UserId(), 1, MaxStrLen(DtldCVLedgEntryBuf2."User ID"));
                        DtldCVLedgEntryBuf2."Additional-Currency Amount" := -VATBaseAddCurr;
                        OnCalcPmtDiscIfAdjVATCopyFields(DtldCVLedgEntryBuf2, OldCVLedgEntryBuf, GenJnlLine);
                        DtldCVLedgEntryBuf2.CopyPostingGroupsFromVATEntry(VATEntry2);
                        TotalVATAmount := 0;
                        LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                    end;

                    OnBeforeCalcPmtDiscVATAmounts(VATEntry2, DtldCVLedgEntryBuf2, GenJnlLine);
                    CalcPmtDiscVATAmounts(
                        VATEntry2, VATBase, VATBaseAddCurr, NonDedVATBase, NonDedVATBaseAddCurr,
                        VATAmount, VATAmountAddCurr, NonDedVATAmount, NonDedVATAmountAddCurr,
                        PmtDiscRounding, PmtDiscFactorLCY, PmtDiscLCY2, PmtDiscAddCurr2);
                    if VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Normal VAT" then
                        DtldCVLedgEntryBuf2."Amount (LCY)" -= NonDedVATAmount;
                    OnCalcPmtDiscIfAdjVATOnAfterCalcPmtDiscVATAmounts(
                        VATEntry2, OldCVLedgEntryBuf, VATBase, VATBaseAddCurr, VATAmount, VATAmountAddCurr, PmtDiscLCY2, PmtDiscAddCurr2);

                    TotalVATAmount := TotalVATAmount + VATAmount;
                    NonDedTotalVATAmount := NonDedTotalVATAmount + NonDedVATAmount;
                    NonDedTotalVATAmountACY := NonDedTotalVATAmountACY + NonDedVATAmountAddCurr;

                    if (PmtDiscAddCurr2 <> 0) and (PmtDiscLCY2 = 0) then begin
                        VATAmountAddCurr := VATAmountAddCurr - PmtDiscAddCurr2;
                        PmtDiscAddCurr2 := 0;
                    end;

                    // Post VAT
                    // VAT for VAT entry
                    if VATEntry2.Type <> VATEntry2.Type::" " then
                        InsertPmtDiscVATForVATEntry(
                            GenJnlLine, TempVATEntry, VATEntry2, VATEntryModifier,
                            VATAmount, VATAmountAddCurr, VATBase, VATBaseAddCurr,
                            NonDedVATAmount, NonDedVATAmountAddCurr, NonDedVATBase, NonDedVATBaseAddCurr,
                            PmtDiscFactorLCY, PmtDiscFactorAddCurr);

                    OnCalcPmtDiscIfAdjVATOnBeforeInsertPmtDiscVATForGLEntry(VATEntry, VATEntry2, DtldCVLedgEntryBuf2);
                    // VAT for G/L entry/entries
                    InsertPmtDiscVATForGLEntry(
                        GenJnlLine, DtldCVLedgEntryBuf, NewCVLedgEntryBuf, VATEntry2,
                        VATPostingSetup, TaxJurisdiction, EntryType, VATAmount, VATAmountAddCurr, NonDedVATAmount, NonDedVATAmountAddCurr);
                end;
            until VATEntry2.Next() = 0;

            if LastConnectionNo <> 0 then begin
                DtldCVLedgEntryBuf := DtldCVLedgEntryBuf2;
                DtldCVLedgEntryBuf."VAT Amount (LCY)" := -TotalVATAmount;
                DtldCVLedgEntryBuf."Non-Deductible VAT Amount LCY" := -NonDedTotalVATAmount;
                DtldCVLedgEntryBuf."Non-Deductible VAT Amount ACY" := -NonDedTotalVATAmountACY;
                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAfterLoop(DtldCVLedgEntryBuf, OldCVLedgEntryBuf);
                InsertSummarizedVAT(GenJnlLine);
            end;
            PmtDiscLCY2 -= NonDedReverseChargeVATBasePmtDisc;
            PmtDiscAddCurr2 -= NonDedReverseChargeVATBasePmtDiscACY;
        end;

        OnAfterCalcPmtDiscIfAdjVAT(NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, PmtDiscLCY2, PmtDiscAddCurr2);
    end;

    local procedure CalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer)
    var
        PmtDiscTol: Decimal;
        PmtDiscTolLCY: Decimal;
        PmtDiscTolAddCurr: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPmtDiscTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not OldCVLedgEntryBuf2."Accepted Pmt. Disc. Tolerance" then
            exit;

        PmtDiscTol := -OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
        PmtDiscTolLCY :=
          Round(
            (NewCVLedgEntryBuf."Original Amount" + PmtDiscTol) / NewCVLedgEntryBuf."Original Currency Factor") -
          NewCVLedgEntryBuf."Original Amt. (LCY)";

        OnAfterCalcPmtDiscTolerance(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
          PmtDiscTol, PmtDiscTolLCY, PmtDiscTolAddCurr);

        OldCVLedgEntryBuf."Pmt. Disc. Given (LCY)" := -PmtDiscTolLCY;

        if NewCVLedgEntryBuf."Currency Code" = AddCurrencyCode then
            PmtDiscTolAddCurr := PmtDiscTol
        else
            PmtDiscTolAddCurr := CalcLCYToAddCurr(PmtDiscTolLCY);

        if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." and (PmtDiscTolLCY <> 0) then
            CalcPmtDiscIfAdjVAT(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, PmtDiscTolLCY, PmtDiscTolAddCurr,
              NextTransactionNo, FirstNewVATEntryNo, DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)");

        OnCalcPmtDiscToleranceBeforeInitDetailedCVLedgEntryBuff(GenJnlLine, IsHandled);
        if not IsHandled then
            DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
                DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance", PmtDiscTol, PmtDiscTolLCY, PmtDiscTolAddCurr, 0, 0, 0);

        OnAfterCalcPmtDiscToleranceProc(DtldCVLedgEntryBuf, OldCVLedgEntryBuf, PmtDiscTol, PmtDiscTolLCY, GenJnlLine);
    end;

    local procedure CalcPmtDiscVATBases(VATEntry2: Record "VAT Entry"; var VATBase: Decimal; var VATBaseAddCurr: Decimal; var NonDeductibleVATBase: Decimal; var NonDeductibleVATBaseAddCurr: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
            VATEntry2."VAT Calculation Type"::"Full VAT":
                begin
                    VATBase :=
                      VATEntry2.Base + VATEntry2."Unrealized Base";
                    VATBaseAddCurr :=
                      VATEntry2."Additional-Currency Base" +
                      VATEntry2."Add.-Currency Unrealized Base";
                    NonDeductibleVAT.GetNonDeductibleVATBaseBothCurrencies(NonDeductibleVATBase, NonDeductibleVATBaseAddCurr, VATEntry2);
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey("Transaction No.");
                    VATEntry.SetRange("Transaction No.", VATEntry2."Transaction No.");
                    VATEntry.SetRange("Sales Tax Connection No.", VATEntry2."Sales Tax Connection No.");
                    VATEntry := VATEntry2;
                    repeat
                        if VATEntry.Base < 0 then
                            VATEntry.SetFilter(Base, '>%1', VATEntry.Base)
                        else
                            VATEntry.SetFilter(Base, '<%1', VATEntry.Base);
                    until not VATEntry.FindLast();
                    VATEntry.Reset();
                    VATBase :=
                      VATEntry.Base + VATEntry."Unrealized Base";
                    VATBaseAddCurr :=
                      VATEntry."Additional-Currency Base" +
                      VATEntry."Add.-Currency Unrealized Base";
                end;
        end;
        OnAfterCalcPmtDiscVATBases(VATEntry2, VATBase, VATBaseAddCurr, NonDeductibleVATBase, NonDeductibleVATBaseAddCurr);
    end;

    local procedure CalcPmtDiscVATAmounts(VATEntry2: Record "VAT Entry"; VATBase: Decimal; VATBaseAddCurr: Decimal; NonDedVATBase: Decimal; NonDedVATBaseAddCurr: Decimal; var VATAmount: Decimal; var VATAmountAddCurr: Decimal; var NonDedVATAmount: Decimal; var NonDedVATAmountAddCurr: Decimal; var PmtDiscRounding: Decimal; PmtDiscFactorLCY: Decimal; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal)
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
          VATEntry2."VAT Calculation Type"::"Full VAT":
                if (VATEntry2.Amount + VATEntry2."Unrealized Amount" + VATEntry2."Non-Deductible VAT Amount" <> 0) or
                   (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." + VATEntry2."Non-Deductible VAT Amount ACY" <> 0)
                then begin
                    if (VATBase = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        VATAmount := 0
                    else
                        VATAmount :=
                            CalcAmtMultipliedByFactorWithRounding(
                                PmtDiscRounding, PmtDiscLCY2, VATEntry2.Amount + VATEntry2."Unrealized Amount", PmtDiscFactorLCY);
                    if (VATBaseAddCurr = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        VATAmountAddCurr := 0
                    else begin
                        VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                    end;
                    if (NonDedVATBase = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        NonDedVATAmount := 0
                    else
                        NonDedVATAmount :=
                            CalcAmtMultipliedByFactorWithRounding(
                                PmtDiscRounding, PmtDiscLCY2, VATEntry2."Non-Deductible VAT Amount", PmtDiscFactorLCY);
                    if (NonDedVATBaseAddCurr = 0) and
                       (VATEntry2."VAT Calculation Type" <> VATEntry2."VAT Calculation Type"::"Full VAT")
                    then
                        NonDedVATAmountAddCurr := 0
                    else begin
                        NonDedVATAmountAddCurr := Round(CalcLCYToAddCurr(NonDedVATAmount), AddCurrency."Amount Rounding Precision");
                        PmtDiscAddCurr2 := PmtDiscAddCurr2 + NonDedVATAmountAddCurr;
                    end;
                end else begin
                    VATAmount := 0;
                    VATAmountAddCurr := 0;
                end;
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                begin
                    VATAmount :=
                        Round((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                    VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                    NonDedVATAmount :=
                        Round(VATEntry2."Non-Deductible VAT Amount" * PmtDiscFactorLCY);
                    NonDedVATAmountAddCurr := Round(CalcLCYToAddCurr(NonDedVATAmount), AddCurrency."Amount Rounding Precision");
                    if PmtDiscLCY2 = 0 then
                        PmtDiscAddCurr2 := 0
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                if (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax" then begin
                    VATAmount :=
                      Round((VATEntry2.Amount + VATEntry2."Unrealized Amount") * PmtDiscFactorLCY);
                    VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                end else
                    if (VATEntry2.Amount + VATEntry2."Unrealized Amount" <> 0) or
                       (VATEntry2."Additional-Currency Amount" + VATEntry2."Add.-Currency Unrealized Amt." <> 0)
                    then begin
                        if VATBase = 0 then
                            VATAmount := 0
                        else
                            VATAmount :=
                                CalcAmtMultipliedByFactorWithRounding(
                                    PmtDiscRounding, PmtDiscLCY2, VATEntry2.Amount + VATEntry2."Unrealized Amount", PmtDiscFactorLCY);

                        if VATBaseAddCurr = 0 then
                            VATAmountAddCurr := 0
                        else begin
                            VATAmountAddCurr := Round(CalcLCYToAddCurr(VATAmount), AddCurrency."Amount Rounding Precision");
                            PmtDiscAddCurr2 := PmtDiscAddCurr2 + VATAmountAddCurr;
                        end;
                    end else begin
                        VATAmount := 0;
                        VATAmountAddCurr := 0;
                    end;
        end;
    end;

    local procedure CalcAmtMultipliedByFactorWithRounding(var Rounding: Decimal; var TotalAmount: Decimal; SourceAmount: Decimal; Factor: Decimal) Result: Decimal
    begin
        Rounding := Rounding + SourceAmount * Factor;
        Result := Round(Rounding - TotalAmount);
        TotalAmount := TotalAmount + Result;
    end;

    local procedure CalcAmountSrcCurr(var GenJnlLine: Record "Gen. Journal Line"; AmountLCY: Decimal): Decimal
    var
        SrcCurrencyFactor: Decimal;
        LocalAmountRoundingPrecision: Decimal;
    begin
        if GenJnlLine."Currency Factor" = 0 then
            SrcCurrencyFactor := CurrExchRate.ExchangeRate(GenJnlLine."Posting Date", GenJnlLine."Source Currency Code")
        else
            SrcCurrencyFactor := GenJnlLine."Currency Factor";

        // Ensure AmountRoundingPrecision is initialized when called externally
        if AmountRoundingPrecision = 0 then
            LocalAmountRoundingPrecision := GetSourceCurrency(GenJnlLine."Source Currency Code")
        else
            LocalAmountRoundingPrecision := AmountRoundingPrecision;

        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
                GenJnlLine."Posting Date", GenJnlLine."Source Currency Code", AmountLCY, SrcCurrencyFactor), LocalAmountRoundingPrecision));
    end;

    local procedure InsertPmtDiscVATForVATEntry(GenJnlLine: Record "Gen. Journal Line"; var TempVATEntry: Record "VAT Entry" temporary; VATEntry2: Record "VAT Entry"; VATEntryModifier: Integer; VATAmount: Decimal; VATAmountAddCurr: Decimal; VATBase: Decimal; VATBaseAddCurr: Decimal; NonDedVATAmount: Decimal; NonDedVATAmountAddCurr: Decimal; NonDedVATBase: Decimal; NonDedVATBaseAddCurr: Decimal; PmtDiscFactorLCY: Decimal; PmtDiscFactorAddCurr: Decimal)
    var
        TempVATEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Entry No.", VATEntryModifier, VATEntryModifier + 999999);
        if TempVATEntry.FindLast() then
            TempVATEntryNo := TempVATEntry."Entry No." + 1
        else
            TempVATEntryNo := VATEntryModifier + 1;
        TempVATEntry := VATEntry2;
        TempVATEntry."Entry No." := TempVATEntryNo;
        TempVATEntry.CopyPostingDataFromGenJnlLine(GenJnlLine);
        TempVATEntry.SetVATDateFromGenJnlLine(GenJnlLine);
        TempVATEntry."Transaction No." := NextTransactionNo;
        TempVATEntry."Sales Tax Connection No." := NextConnectionNo;
        TempVATEntry."Unrealized Amount" := 0;
        TempVATEntry."Unrealized Base" := 0;
        TempVATEntry."Remaining Unrealized Amount" := 0;
        TempVATEntry."Remaining Unrealized Base" := 0;
        TempVATEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(TempVATEntry."User ID"));
        TempVATEntry."Closed by Entry No." := 0;
        TempVATEntry.Closed := false;
        TempVATEntry."Internal Ref. No." := '';
        TempVATEntry.Amount := VATAmount;
        TempVATEntry."Additional-Currency Amount" := VATAmountAddCurr;
        NonDeductibleVAT.SetNonDeductibleVATAmount(TempVATEntry, NonDedVATAmount, NonDedVATAmountAddCurr);
        TempVATEntry."VAT Difference" := 0;
        TempVATEntry."Add.-Curr. VAT Difference" := 0;
        TempVATEntry."Add.-Currency Unrealized Amt." := 0;
        TempVATEntry."Add.-Currency Unrealized Base" := 0;
        if VATEntry2."Tax on Tax" then begin
            TempVATEntry.Base :=
              Round((VATEntry2.Base + VATEntry2."Unrealized Base") * PmtDiscFactorLCY);
            TempVATEntry."Additional-Currency Base" :=
              Round(
                (VATEntry2."Additional-Currency Base" +
                 VATEntry2."Add.-Currency Unrealized Base") * PmtDiscFactorAddCurr,
                AddCurrency."Amount Rounding Precision");
        end else begin
            TempVATEntry.Base := VATBase;
            TempVATEntry."Additional-Currency Base" := VATBaseAddCurr;
            NonDeductibleVAT.SetNonDeductibleVATBase(TempVATEntry, NonDedVATBase, NonDedVATBaseAddCurr);
        end;
        TempVATEntry."Base Before Pmt. Disc." := VATEntry.Base;

        if AddCurrencyCode = '' then begin
            TempVATEntry."Additional-Currency Base" := 0;
            TempVATEntry."Additional-Currency Amount" := 0;
            TempVATEntry."Add.-Currency Unrealized Amt." := 0;
            TempVATEntry."Add.-Currency Unrealized Base" := 0;
        end;
        TempVATEntry."G/L Acc. No." := '';
        OnBeforeInsertTempVATEntry(TempVATEntry, GenJnlLine, VATEntry2, VATAmount, VATBase);
        TempVATEntry.Insert();
    end;

    local procedure InsertPmtDiscVATForGLEntry(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; VATEntry2: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var TaxJurisdiction: Record "Tax Jurisdiction"; EntryType: Enum "Detailed CV Ledger Entry Type"; VATAmount: Decimal; VATAmountAddCurr: Decimal; NonDedVATAmount: Decimal; NonDedVATAmountAddCurr: Decimal)
    var
        IsHandled: Boolean;
    begin
        DtldCVLedgEntryBuf.Init();
        DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(NewCVLedgEntryBuf);
        case EntryType of
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)";
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)";
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                DtldCVLedgEntryBuf."Entry Type" :=
                  DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)";
        end;
        DtldCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        DtldCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        DtldCVLedgEntryBuf."Document No." := GenJnlLine."Document No.";
        OnInsertPmtDiscVATForGLEntryOnAfterCopyFromGenJnlLine(DtldCVLedgEntryBuf, GenJnlLine);
        DtldCVLedgEntryBuf.Amount := 0;
        DtldCVLedgEntryBuf."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
        DtldCVLedgEntryBuf."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
        DtldCVLedgEntryBuf."Tax Jurisdiction Code" := VATEntry2."Tax Jurisdiction Code";
        // The total payment discount in currency is posted on the entry made in
        // the function CalcPmtDisc.
        DtldCVLedgEntryBuf."User ID" := CopyStr(UserId(), 1, MaxStrLen(DtldCVLedgEntryBuf."User ID"));
        DtldCVLedgEntryBuf."Use Additional-Currency Amount" := true;

        IsHandled := false;
        OnBeforeInsertPmtDiscVATForGLEntry(DtldCVLedgEntryBuf, GenJnlLine, VATEntry2, VATPostingSetup, VATAmount, VATAmountAddCurr, NewCVLedgEntryBuf, TempGLEntryVAT, IsHandled, NonDedVATAmount, NonDedVATAmountAddCurr);
        if not IsHandled then
            case VATEntry2.Type of
                VATEntry2.Type::Purchase:
                    case VATEntry2."VAT Calculation Type" of
                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                        VATEntry2."VAT Calculation Type"::"Full VAT":
                            begin
                                InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetPurchAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                            end;
                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetPurchAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), '',
                                  -VATAmount, -VATAmountAddCurr, false);
                                if NonDedVATAmount <> 0 then begin
                                    InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetPurchAccount(false), '',
                                    NonDedVATAmount, NonDedVATAmountAddCurr, false);
                                    InitGLEntryVAT(GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), '',
                                    -NonDedVATAmount, -NonDedVATAmountAddCurr, false);
                                end;
                            end;
                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                            if VATEntry2."Use Tax" then begin
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetRevChargeAccount(false), '',
                                  -VATAmount, -VATAmountAddCurr, false);
                            end else begin
                                InitGLEntryVAT(GenJnlLine, TaxJurisdiction.GetPurchAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                            end;
                    end;
                VATEntry2.Type::Sale:
                    case VATEntry2."VAT Calculation Type" of
                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                        VATEntry2."VAT Calculation Type"::"Full VAT":
                            begin
                                InitGLEntryVAT(
                                  GenJnlLine, VATPostingSetup.GetSalesAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                            end;
                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                            ;
                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                            begin
                                InitGLEntryVAT(
                                  GenJnlLine, TaxJurisdiction.GetSalesAccount(false), '',
                                  VATAmount, VATAmountAddCurr, false);
                                DtldCVLedgEntryBuf."Amount (LCY)" := -VATAmount;
                                DtldCVLedgEntryBuf."Additional-Currency Amount" := -VATAmountAddCurr;
                                DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, NewCVLedgEntryBuf, true);
                            end;
                    end;
            end;

        OnAfterInsertPmtDiscVATForGLEntry(DtldCVLedgEntryBuf, GenJnlLine);
    end;

    local procedure CalcCurrencyApplnRounding(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; ApplnRoundingPrecision: Decimal)
    var
        ApplnRounding: Decimal;
        ApplnRoundingLCY: Decimal;
    begin
        if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf."Currency Code" then
            exit;

        ApplnRounding := -(NewCVLedgEntryBuf."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount");
        ApplnRoundingLCY := Round(ApplnRounding / NewCVLedgEntryBuf."Adjusted Currency Factor");

        if (ApplnRounding = 0) or (Abs(ApplnRounding) > ApplnRoundingPrecision) then
            exit;

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding", ApplnRounding, ApplnRoundingLCY, ApplnRounding, 0, 0, 0);
    end;

    local procedure FindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; ApplnRoundingPrecision: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindAmtForAppln(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount, AppliedAmountLCY, OldAppliedAmount, IsHandled,
          ApplnRoundingPrecision, VATEntry);
        if IsHandled then
            exit;

        if OldCVLedgEntryBuf2.GetFilter(Positive) <> '' then begin
            if OldCVLedgEntryBuf2."Amount to Apply" <> 0 then begin
                if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
                    (Abs(OldCVLedgEntryBuf2."Amount to Apply") >=
                     Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")))
                then begin
                    AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
                    OnAfterSetAppliedAmountFromRemainingAmount(OldCVLedgEntryBuf2, AppliedAmount, GenJournalLine)
                end else
                    AppliedAmount := -OldCVLedgEntryBuf2."Amount to Apply"
            end else
                AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
        end else
            if OldCVLedgEntryBuf2."Amount to Apply" <> 0 then
                if (PaymentToleranceMgt.CheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, false) and
                    (Abs(OldCVLedgEntryBuf2."Amount to Apply") >=
                     Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date"))) and
                    (Abs(NewCVLedgEntryBuf."Remaining Amount") >=
                     Abs(
                       ABSMin(
                         OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date"),
                         OldCVLedgEntryBuf2."Amount to Apply")))) or
                   OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance"
                then begin
                    AppliedAmount := -OldCVLedgEntryBuf2."Remaining Amount";
                    OnAfterSetAppliedAmountFromRemainingAmountOnEmptyFilter(OldCVLedgEntryBuf2, AppliedAmount, GenJournalLine);
                    OldCVLedgEntryBuf."Accepted Pmt. Disc. Tolerance" := false;
                end else
                    AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Amount to Apply")
            else
                AppliedAmount := ABSMin(NewCVLedgEntryBuf."Remaining Amount", -OldCVLedgEntryBuf2."Remaining Amount");

        if (Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply") < ApplnRoundingPrecision) and
           (ApplnRoundingPrecision <> 0) and
           (OldCVLedgEntryBuf2."Amount to Apply" <> 0)
        then
            AppliedAmount := AppliedAmount - (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Amount to Apply");

        if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" then begin
            AppliedAmountLCY := Round(AppliedAmount / OldCVLedgEntryBuf."Original Currency Factor");
            OldAppliedAmount := AppliedAmount;
        end else begin
            // Management of posting in multiple currencies
            if AppliedAmount = -OldCVLedgEntryBuf2."Remaining Amount" then
                OldAppliedAmount := -OldCVLedgEntryBuf."Remaining Amount"
            else
                OldAppliedAmount :=
                  CurrExchRate.ExchangeAmount(
                    AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                    OldCVLedgEntryBuf2."Currency Code", NewCVLedgEntryBuf."Posting Date");

            if NewCVLedgEntryBuf."Currency Code" <> '' then
                // Post the realized gain or loss on the NewCVLedgEntryBuf
                AppliedAmountLCY := Round(OldAppliedAmount / OldCVLedgEntryBuf."Original Currency Factor")
            else
                // Post the realized gain or loss on the OldCVLedgEntryBuf
                AppliedAmountLCY := Round(AppliedAmount / NewCVLedgEntryBuf."Original Currency Factor");
        end;

        OnAfterFindAmtForAppln(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount,
          AppliedAmountLCY, OldAppliedAmount, AmountRoundingPrecision, VATEntry);
    end;

    /// <summary>
    /// Calculates unrealized gains and losses, if there are any then detailed CV ledger entries are created.
    /// </summary>
    /// <param name="CVLedgEntryBuf">Return value: CV ledger entry buffer that detailed entries are created for. In the procedure amounts are modified to reflect the application.</param>
    /// <param name="TempDtldCVLedgEntryBuf">Return value: Buffer where created CV ledger entries should be inserted to.</param>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="AppliedAmount">Amount that is being applied.</param>
    /// <param name="RemainingAmountBeforeAppln">Remaining amount on the ledger entry that the application is performed to.</param>
    procedure CalcCurrencyUnrealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; RemainingAmountBeforeAppln: Decimal)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        UnRealizedGainLossLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCurrencyUnrealizedGainLoss(
          CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, RemainingAmountBeforeAppln, IsHandled);
        if IsHandled then
            exit;

        if (CVLedgEntryBuf."Currency Code" = '') or (RemainingAmountBeforeAppln = 0) then
            exit;

        // Calculate Unrealized GainLoss
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Customer:
                UnRealizedGainLossLCY :=
                    Round(
                        DtldCustLedgEntry.GetUnrealizedGainLossAmount(CVLedgEntryBuf."Entry No.") *
                        Abs(AppliedAmount / RemainingAmountBeforeAppln));
            GenJnlLine."Account Type"::Employee:
                UnRealizedGainLossLCY :=
                    Round(
                        DtldEmplLedgEntry.GetUnrealizedGainLossAmount(CVLedgEntryBuf."Entry No.") *
                        Abs(AppliedAmount / RemainingAmountBeforeAppln));
            else
                UnRealizedGainLossLCY :=
                    Round(
                        DtldVendLedgEntry.GetUnrealizedGainLossAmount(CVLedgEntryBuf."Entry No.") *
                        Abs(AppliedAmount / RemainingAmountBeforeAppln));
        end;

        if UnRealizedGainLossLCY <> 0 then
            if UnRealizedGainLossLCY < 0 then
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss", 0, -UnRealizedGainLossLCY, 0, 0, 0, 0)
            else
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain", 0, -UnRealizedGainLossLCY, 0, 0, 0, 0);
    end;

    local procedure CalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal)
    var
        RealizedGainLossLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCurrencyRealizedGainLoss(
          CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY, IsHandled);
        if IsHandled then
            exit;

        if CVLedgEntryBuf."Currency Code" = '' then
            exit;

        RealizedGainLossLCY := AppliedAmountLCY - Round(AppliedAmount / CVLedgEntryBuf."Original Currency Factor");
        OnAfterCalcCurrencyRealizedGainLoss(CVLedgEntryBuf, AppliedAmount, AppliedAmountLCY, RealizedGainLossLCY);

        if RealizedGainLossLCY <> 0 then
            if RealizedGainLossLCY < 0 then
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Realized Loss", 0, RealizedGainLossLCY, 0, 0, 0, 0)
            else
                TempDtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
                  GenJnlLine, CVLedgEntryBuf, TempDtldCVLedgEntryBuf,
                  TempDtldCVLedgEntryBuf."Entry Type"::"Realized Gain", 0, RealizedGainLossLCY, 0, 0, 0, 0);
    end;

    local procedure CalcApplication(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal; OldAppliedAmount: Decimal; PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var AllApplied: Boolean)
    var
        IsHandled: Boolean;
        ShouldSetClosedFields: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAplication(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine,
          AppliedAmount, AppliedAmountLCY, OldAppliedAmount, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, AllApplied, IsHandled);
        if IsHandled then
            exit;

        OnCalcApplicationOnBeforeCheckAppliedAmount(GenJnlLine, AppliedAmount, IsHandled);
        if not IsHandled then
            if AppliedAmount = 0 then
                exit;

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::Application, OldAppliedAmount, AppliedAmountLCY, 0,
          NewCVLedgEntryBuf."Entry No.", PrevOldCVLedgEntryBuf."Remaining Pmt. Disc. Possible",
          PrevOldCVLedgEntryBuf."Max. Payment Tolerance");

        OnAfterInitOldDtldCVLedgEntryBuf(
          DtldCVLedgEntryBuf, NewCVLedgEntryBuf, OldCVLedgEntryBuf, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, GenJnlLine);

        OldCVLedgEntryBuf.Open := OldCVLedgEntryBuf."Remaining Amount" <> 0;

        OnCalcApplicationOnAfterFillOldCVLedgEntryBufOpen(GenJnlLine, OldCVLedgEntryBuf);

        if not OldCVLedgEntryBuf.Open then
            OldCVLedgEntryBuf.SetClosedFields(
              NewCVLedgEntryBuf."Entry No.", GenJnlLine."Posting Date",
              -OldAppliedAmount, -AppliedAmountLCY, NewCVLedgEntryBuf."Currency Code", -AppliedAmount)
        else
            AllApplied := false;

        DtldCVLedgEntryBuf.InitDetailedCVLedgEntryBuf(
          GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf,
          DtldCVLedgEntryBuf."Entry Type"::Application, -AppliedAmount, -AppliedAmountLCY, 0,
          NewCVLedgEntryBuf."Entry No.", PrevNewCVLedgEntryBuf."Remaining Pmt. Disc. Possible",
          PrevNewCVLedgEntryBuf."Max. Payment Tolerance");

        OnAfterInitNewDtldCVLedgEntryBuf(
          DtldCVLedgEntryBuf, NewCVLedgEntryBuf, OldCVLedgEntryBuf, PrevNewCVLedgEntryBuf, PrevOldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf.Open := NewCVLedgEntryBuf."Remaining Amount" <> 0;
        ShouldSetClosedFields := not NewCVLedgEntryBuf.Open and not AllApplied;
        OnCalcApplicationOnAfterCalcShouldSetClosedFields(NewCVLedgEntryBuf, ShouldSetClosedFields);
        if ShouldSetClosedFields then
            NewCVLedgEntryBuf.SetClosedFields(
              OldCVLedgEntryBuf."Entry No.", GenJnlLine."Posting Date",
              AppliedAmount, AppliedAmountLCY, OldCVLedgEntryBuf."Currency Code", OldAppliedAmount);

        if not NewCVLedgEntryBuf.Open then
            NewCVLedgEntryBuf."Closed at Date" := GenJnlLine."Posting Date";

        OnAfterCalcApplication(GenJnlLine, DtldCVLedgEntryBuf);
    end;

    /// <summary>
    /// Calculates the difference in local currency between the actual remaining amount of the c/v ledger entry and the remaining amount based on the adjusted currency factor. 
    /// If there is a difference then detailed CV ledger entries are created and posted to equate the difference.
    /// </summary>
    /// <param name="CVLedgEntryBuf">Cv ledger entry that the adjustment should be calculated for.</param>
    /// <param name="DtldCVLedgEntryBuf">Buffer table for detailed vendor ledger entries to be posted.</param>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    procedure CalcAmtLCYAdjustment(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line")
    var
        AdjustedAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAmtLCYAdjustment(CVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if CVLedgEntryBuf."Currency Code" = '' then
            exit;

        AdjustedAmountLCY :=
          Round(CVLedgEntryBuf."Remaining Amount" / CVLedgEntryBuf."Adjusted Currency Factor");

        if AdjustedAmountLCY <> CVLedgEntryBuf."Remaining Amt. (LCY)" then begin
            DtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
            DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(CVLedgEntryBuf);
            DtldCVLedgEntryBuf."Entry Type" :=
              DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount";
            DtldCVLedgEntryBuf."Amount (LCY)" := AdjustedAmountLCY - CVLedgEntryBuf."Remaining Amt. (LCY)";
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, false);
        end;
    end;

    local procedure InitBankAccLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        OnBeforeInitBankAccLedgEntry(BankAccLedgEntry, GenJnlLine);

        BankAccLedgEntry.Init();
        BankAccLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        BankAccLedgEntry."Entry No." := NextEntryNo;
        BankAccLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitBankAccLedgEntry(BankAccLedgEntry, GenJnlLine);
    end;

    local procedure InitCheckLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry"; var CheckLedgEntry: Record "Check Ledger Entry")
    begin
        OnBeforeInitCheckEntry(BankAccLedgEntry, CheckLedgEntry);

        CheckLedgEntry.Init();
        CheckLedgEntry.CopyFromBankAccLedgEntry(BankAccLedgEntry);
        CheckLedgEntry."Entry No." := NextCheckEntryNo;

        OnAfterInitCheckLedgEntry(CheckLedgEntry, BankAccLedgEntry);
    end;

    local procedure InitCustLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        OnBeforeInitCustLedgEntry(CustLedgEntry, GenJnlLine);

        CustLedgEntry.Init();
        CustLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        CustLedgEntry."Entry No." := NextEntryNo;
        CustLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitCustLedgEntry(CustLedgEntry, GenJnlLine, GLReg);
    end;

    local procedure InitVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        OnBeforeInitVendLedgEntry(VendLedgEntry, GenJnlLine);

        VendLedgEntry.Init();
        VendLedgEntry.CopyFromGenJnlLine(GenJnlLine);
        VendLedgEntry."Entry No." := NextEntryNo;
        VendLedgEntry."Transaction No." := NextTransactionNo;

        OnAfterInitVendLedgEntry(VendLedgEntry, GenJnlLine, GLReg);
    end;

    local procedure InitEmployeeLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        OnBeforeInitEmployeeLedgEntry(EmployeeLedgerEntry, GenJnlLine);

        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry.CopyFromGenJnlLine(GenJnlLine);
        EmployeeLedgerEntry."Entry No." := NextEntryNo;
        EmployeeLedgerEntry."Transaction No." := NextTransactionNo;

        OnAfterInitEmployeeLedgerEntry(EmployeeLedgerEntry, GenJnlLine);
    end;

    local procedure InsertDtldCustLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; Offset: Integer)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDtldCustLedgEntryProcedure(GenJnlLine, DtldCVLedgEntryBuf, DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        DtldCustLedgEntry.Init();
        DtldCustLedgEntry.TransferFields(DtldCVLedgEntryBuf);
        DtldCustLedgEntry."Entry No." := Offset + DtldCVLedgEntryBuf."Entry No.";
        DtldCustLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        DtldCustLedgEntry."Reason Code" := GenJnlLine."Reason Code";
        DtldCustLedgEntry."Source Code" := GenJnlLine."Source Code";
        DtldCustLedgEntry."Transaction No." := NextTransactionNo;
        CustLedgerEntry2.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
        DtldCustLedgEntry."Posting Group" := CustLedgerEntry2."Customer Posting Group";
        DtldCustLedgEntry.UpdateDebitCredit(GenJnlLine.Correction);
        OnBeforeInsertDtldCustLedgEntry(DtldCustLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, GLReg);
        DtldCustLedgEntry.Insert(true);
        OnAfterInsertDtldCustLedgEntry(DtldCustLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, Offset);
    end;

    local procedure InsertDtldVendLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; Offset: Integer)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDtldVendLedgEntryProcedure(GenJnlLine, DtldCVLedgEntryBuf, DtldVendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        DtldVendLedgEntry.Init();
        DtldVendLedgEntry.TransferFields(DtldCVLedgEntryBuf);
        DtldVendLedgEntry."Entry No." := Offset + DtldCVLedgEntryBuf."Entry No.";
        DtldVendLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        DtldVendLedgEntry."Reason Code" := GenJnlLine."Reason Code";
        DtldVendLedgEntry."Source Code" := GenJnlLine."Source Code";
        DtldVendLedgEntry."Transaction No." := NextTransactionNo;
        VendorLedgerEntry2.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
        DtldVendLedgEntry."Posting Group" := VendorLedgerEntry2."Vendor Posting Group";
        DtldVendLedgEntry.UpdateDebitCredit(GenJnlLine.Correction);
        OnBeforeInsertDtldVendLedgEntry(DtldVendLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, GLReg);
        DtldVendLedgEntry.Insert(true);
        OnAfterInsertDtldVendLedgEntry(DtldVendLedgEntry, GenJnlLine, DtldCVLedgEntryBuf, Offset);
    end;

    local procedure InsertDtldEmplLedgEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; Offset: Integer)
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        DtldEmplLedgEntry.Init();
        DtldEmplLedgEntry.TransferFields(DtldCVLedgEntryBuf);
        DtldEmplLedgEntry."Entry No." := Offset + DtldCVLedgEntryBuf."Entry No.";
        DtldEmplLedgEntry."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        DtldEmplLedgEntry."Reason Code" := GenJnlLine."Reason Code";
        DtldEmplLedgEntry."Source Code" := GenJnlLine."Source Code";
        DtldEmplLedgEntry."Transaction No." := NextTransactionNo;
        EmployeeLedgerEntry2.Get(DtldCVLedgEntryBuf."CV Ledger Entry No.");
        DtldEmplLedgEntry."Posting Group" := EmployeeLedgerEntry2."Employee Posting Group";
        DtldEmplLedgEntry.UpdateDebitCredit(GenJnlLine.Correction);
        OnBeforeInsertDtldEmplLedgEntry(DtldEmplLedgEntry, GenJnlLine, DtldCVLedgEntryBuf);
        DtldEmplLedgEntry.Insert(true);
    end;

    /// <summary>
    /// Prepares and posts customer ledger entries needed for the application. Detailed customer ledger entries are created and posted for both
    /// the old and the new customer ledger entry.
    /// </summary>
    /// <remarks>
    /// If the gen. journal line does not allow application or customer/gen. journal line is not setup for application, application is not performed.
    /// </remarks>
    /// <param name="NewCVLedgEntryBuf">Return value: Buffer to collect customer ledger entries that has been created for the application.</param>
    /// <param name="DtldCVLedgEntryBuf">Return value: Buffer to collect detailed customer ledger entries that has been created for the application.</param>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="Cust">Customer that the customer ledger entries are created for.</param>
    procedure ApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer)
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        Completed: Boolean;
        AppliedAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
        AllApplied: Boolean;
        IsAmountToApplyCheckHandled: Boolean;
        ShouldUpdateCalcInterest: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyCustLedgEntry(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Cust, IsAmountToApplyCheckHandled, IsHandled);
        if IsHandled then
            exit;
        if not IsAmountToApplyCheckHandled then
            if NewCVLedgEntryBuf."Amount to Apply" = 0 then
                exit;

        AllApplied := true;
        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') and
           not
           ((Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") and
            GenJnlLine."Allow Application")
        then
            exit;

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        ApplyingDate := GenJnlLine."Posting Date";

        OnApplyCustLedgEntryOnBeforePrepareTempCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, DtldCVLedgEntryBuf, NextEntryNo);
        if not PrepareTempCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldCustLedgEntry, Cust, ApplyingDate) then
            exit;

        GenJnlLine."Posting Date" := ApplyingDate;
        OnApplyCustLedgEntryOnAfterSetApplyingDate(ApplyingDate);
        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        repeat
            TempOldCustLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            TempOldCustLedgEntry.CopyFilter(Positive, OldCVLedgEntryBuf.Positive);
            OnApplyCustLedgEntryOnBeforeCopyFromCustLedgEntry(GenJnlLine, OldCVLedgEntryBuf, TempOldCustLedgEntry, NewCVLedgEntryBuf);
            OldCVLedgEntryBuf.CopyFromCustLedgEntry(TempOldCustLedgEntry);

            PostApply(
              GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2,
              Cust."Block Payment Tolerance", AllApplied, AppliedAmount, PmtTolAmtToBeApplied);

            ShouldUpdateCalcInterest := not OldCVLedgEntryBuf.Open;
            OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromOldBuf(OldCVLedgEntryBuf, NewCVLedgEntryBuf, Cust, ShouldUpdateCalcInterest);
            if ShouldUpdateCalcInterest then begin
                UpdateCalcInterest(OldCVLedgEntryBuf);
                UpdateCalcInterest(OldCVLedgEntryBuf, NewCVLedgEntryBuf);
            end;

            if (OldCVLedgEntryBuf."Currency Code" = NewCVLedgEntryBuf."Currency Code") and (OldCVLedgEntryBuf."Applies-to ID" = '') then
                OldCVLedgEntryBuf."Amount to Apply" := 0;
            OnApplyCustLedgEntryOnBeforeCopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf, AppliedAmount, GenJnlLine);
            TempOldCustLedgEntry.CopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf);
            OldCustLedgEntry := TempOldCustLedgEntry;
            if GenJnlLine."On Hold" = OldCustLedgEntry."On Hold" then
                OldCustLedgEntry."On Hold" := '';
            if OldCustLedgEntry."Amount to Apply" = 0 then
                OldCustLedgEntry."Applies-to ID" := ''
            else begin
                TempCustLedgEntry := OldCustLedgEntry;
                if TempCustLedgEntry.Insert() then;
            end;
            OldCustLedgEntry.Modify();

            OnAfterOldCustLedgEntryModify(OldCustLedgEntry, GenJnlLine, TempCustLedgEntry, DtldCVLedgEntryBuf);

            IsHandled := false;
            OnApplyCustLedgEntryOnBeforeCustUnrealizedVAT(TempOldCustLedgEntry, IsHandled);
            if not IsHandled then
                if GLSetup."Unrealized VAT" or
                   (GLSetup."Prepayment Unrealized VAT" and TempOldCustLedgEntry.Prepayment)
                then
                    if IsNotPayment(TempOldCustLedgEntry."Document Type") then begin
                        TempOldCustLedgEntry.RecalculateAmounts(
                          NewCVLedgEntryBuf."Currency Code", TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        OnApplyCustLedgEntryOnAfterRecalculateAmounts(TempOldCustLedgEntry, OldCustLedgEntry, NewCVLedgEntryBuf, GenJnlLine);
                        CustUnrealizedVAT(
                          GenJnlLine,
                          TempOldCustLedgEntry,
                          CurrExchRate.ExchangeAmount(
                            AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                            TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"));
                    end;

            OnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete(TempOldCustLedgEntry, NewCVLedgEntryBuf, GenJnlLine, Cust, NextEntryNo, GLReg, AppliedAmount, OldCVLedgEntryBuf);
            TempOldCustLedgEntry.Delete();

            OnApplyCustLedgerEntryOnBeforeSetCompleted(GenJnlLine, OldCustLedgEntry, NewCVLedgEntryBuf, AppliedAmount);

            Completed := FindNextOldCustLedgEntryToApply(GenJnlLine, TempOldCustLedgEntry, NewCVLedgEntryBuf);
        until Completed;

        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CalcSums("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        ShouldUpdateCalcInterest := not NewCVLedgEntryBuf.Open;
        OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromNewBuf(OldCVLedgEntryBuf, NewCVLedgEntryBuf, Cust, ShouldUpdateCalcInterest);
        if ShouldUpdateCalcInterest then
            UpdateCalcInterest(NewCVLedgEntryBuf);

        IsHandled := false;
        OnApplyCustLedgEntryOnBeforeUnrealizedVAT(NewCVLedgEntryBuf, IsHandled);
        if not IsHandled then
            if GLSetup."Unrealized VAT" or
               (GLSetup."Prepayment Unrealized VAT" and NewCVLedgEntryBuf.Prepayment)
            then
                if IsNotPayment(NewCVLedgEntryBuf."Document Type") and
                   (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0)
                then begin
                    NewCustLedgEntry.CopyFromCVLedgEntryBuffer(NewCVLedgEntryBuf);
                    CheckUnrealizedCust := true;
                    UnrealizedCustLedgEntry := NewCustLedgEntry;
                    UnrealizedCustLedgEntry.CalcFields("Amount (LCY)", "Original Amt. (LCY)");
                    UnrealizedRemainingAmountCust := NewCustLedgEntry."Remaining Amount" - NewRemainingAmtBeforeAppln;
                end;

        OnAfterApplyCustLedgEntry(GenJnlLine, NewCVLedgEntryBuf, OldCustLedgEntry, NewRemainingAmtBeforeAppln);
    end;

    local procedure FindNextOldCustLedgEntryToApply(GenJnlLine: Record "Gen. Journal Line"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer") Completed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindNextOldCustLedgEntryToApply(GenJnlLine, TempOldCustLedgEntry, NewCVLedgEntryBuf, Completed, IsHandled);
        if IsHandled then
            exit(Completed);

        if GenJnlLine."Applies-to Doc. No." <> '' then
            Completed := true
        else
            if TempOldCustLedgEntry.GetFilter(Positive) <> '' then
                if TempOldCustLedgEntry.Next() = 1 then
                    Completed := false
                else begin
                    TempOldCustLedgEntry.SetRange(Positive);
                    TempOldCustLedgEntry.Find('-');
                    TempOldCustLedgEntry.CalcFields("Remaining Amount");
                    Completed := TempOldCustLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                end
            else
                if NewCVLedgEntryBuf.Open then
                    Completed := TempOldCustLedgEntry.Next() = 0
                else
                    Completed := true;
    end;

    /// <summary>
    /// Stand-alone procedure to post (from check to finish) application gen. journal line for the customer ledger entries.
    /// G/l entries, vat entries, customer ledger entries and detailed customer ledger entries are created and posted.
    /// </summary>
    /// <param name="GenJnlLinePostApply">Gen. journal line that should be posted for application purpose.</param>
    /// <param name="CustLedgEntryPostApply">Customer ledger entry that the new application should be applied to.</param>
    procedure CustPostApplyCustLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var CustLedgEntryPostApply: Record "Cust. Ledger Entry")
    var
        Cust: Record Customer;
        CustPostingGr: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        DtldLedgEntryInserted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustPostApplyCustLedgEntry(GenJnlLinePostApply, CustLedgEntryPostApply, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine := GenJnlLinePostApply;
        CustLedgEntry.TransferFields(CustLedgEntryPostApply);
        OnCustPostApplyCustLedgEntryOnAfterCustLedgEntryTransferFields(CustLedgEntry, GenJnlLine);
        GenJnlLine."Source Currency Code" := CustLedgEntryPostApply."Currency Code";
        GenJnlLine."Applies-to ID" := CustLedgEntryPostApply."Applies-to ID";

        AmountRoundingPrecision := GetSourceCurrency(GenJnlLine."Source Currency Code");

        IsHandled := false;
        OnCustPostApplyCustLedgEntryOnBeforeRunCheck(GenJnlLine, CustLedgEntryPostApply, CustLedgEntry, IsHandled);
        if not IsHandled then
            GenJnlCheckLine.RunCheck(GenJnlLine);

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        Cust.Get(CustLedgEntry."Customer No.");
        Cust.CheckBlockedCustOnJnls(Cust, GenJnlLine."Document Type", true);

        OnCustPostApplyCustLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Cust);

        if GenJnlLine."Posting Group" = '' then begin
            Cust.TestField("Customer Posting Group");
            GenJnlLine."Posting Group" := Cust."Customer Posting Group";
        end;
        CustPostingGr.Get(GenJnlLine."Posting Group");
        GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr);

        DtldCustLedgEntry.LockTable();
        CustLedgEntry.LockTable();

        // Post the application
        CustLedgEntry.CalcFields(
          Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
          "Original Amount", "Original Amt. (LCY)");
        OnCustPostApplyCustLedgEntryOnBeforeCopyFromCustLedgEntry(GenJnlLine, CVLedgEntryBuf, CustLedgEntry);
        CVLedgEntryBuf.CopyFromCustLedgEntry(CustLedgEntry);
        OnCustPostApplyCustLedgEntryOnBeforeApplyCustLedgEntry(CustLedgEntry, GenJnlLine, CVLedgEntryBuf);
        ApplyCustLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Cust);
        OnCustPostApplyCustLedgEntryOnAfterApplyCustLedgEntry(GenJnlLine, TempDtldCVLedgEntryBuf);
        CustLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
        OnCustPostApplyCustLedgEntryOnBeforeModifyCustLedgEntry(CustLedgEntry, CVLedgEntryBuf);
        CustLedgEntry.Modify();

        // Post the Dtld customer entry
        OnCustPostApplyCustLedgEntryOnBeforePostDtldCustLedgEntries(CustLedgEntry);
        DtldLedgEntryInserted := PostDtldCustLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, CustPostingGr, false);

        OnCustPostApplyCustLedgEntryOnBeforeCheckPostUnrealizedVAT(GenJnlLine, TempDtldCVLedgEntryBuf, DtldLedgEntryInserted);
        CheckPostUnrealizedVAT(GenJnlLine, true);

        if DtldLedgEntryInserted then
            if IsTempGLEntryBufEmpty() then
                DtldCustLedgEntry.SetZeroTransNo(NextTransactionNo);

        OnCustPostApplyCustLedgEntryOnBeforeFinishPosting(GenJnlLine, CustLedgEntry);

        FinishPosting(GenJnlLine);

        OnAfterCustPostApplyCustLedgEntry(GenJnlLine, GLReg, CustLedgEntry);
    end;

    local procedure PrepareTempCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; Cust: Record Customer; var ApplyingDate: Date): Boolean
    var
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        RemainingAmount: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareTempCustledgEntry(GenJnlLine, NewCVLedgEntryBuf, Cust, ApplyingDate, Result, IsHandled, TempOldCustLedgEntry);
        if IsHandled then
            exit(Result);

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            // Find the entry to be applied to
            OldCustLedgEntry.Reset();
            OldCustLedgEntry.SetLoadFields(Positive, "Posting Date", "Currency Code");
            OldCustLedgEntry.SetCurrentKey("Document No.");
            OldCustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldCustLedgEntry.SetRange("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SetRange(Open, true);
            OnPrepareTempCustLedgEntryOnAfterSetFilters(OldCustLedgEntry, GenJnlLine, NewCVLedgEntryBuf, NextEntryNo);
            OldCustLedgEntry.FindFirst();
            OnPrepareTempCustLedgEntryOnBeforeTestPositive(GenJnlLine, IsHandled);
            if not IsHandled then
                if not ((GenJnlLine.Amount < 0) and
                        (GenJnlLine."Document Type" = GenJnlLine."Document Type"::" ") and
                        (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and
                        (GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Finance Charge Memo") and
                        (GenJnlLine."Applies-to Doc. No." <> '')) then
                    OldCustLedgEntry.TestField(Positive, not NewCVLedgEntryBuf.Positive);

            if OldCustLedgEntry."Posting Date" > ApplyingDate then
                ApplyingDate := OldCustLedgEntry."Posting Date";
            OnPrepareTempCustLedgEntryOnBeforeCheckAgainstApplnCurrencyWithAppliesToDocNo(GenJnlLine, NewCVLedgEntryBuf, OldCustLedgEntry);
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code", OldCustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
            TempOldCustLedgEntry := OldCustLedgEntry;
            OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(TempOldCustLedgEntry, GenJnlLine);
            TempOldCustLedgEntry.Insert();
        end else begin
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldCustLedgEntry.Reset();
            OldCustLedgEntry.SetLoadFields("Posting Date", "Currency Code", "Applies-to ID");
            OldCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            OldCustLedgEntry.SetRange("Customer No.", NewCVLedgEntryBuf."CV No.");
            OldCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            OldCustLedgEntry.SetRange(Open, true);
            OldCustLedgEntry.SetFilter("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            if not (Cust."Application Method" = Cust."Application Method"::"Apply to Oldest") then
                OldCustLedgEntry.SetFilter("Amount to Apply", '<>%1', 0);

            if Cust."Application Method" = Cust."Application Method"::"Apply to Oldest" then
                OldCustLedgEntry.SetFilter("Posting Date", '..%1', GenJnlLine."Posting Date");

            // Check Cust Ledger Entry and add to Temp.
            SalesSetup.Get();
            if SalesSetup."Appln. between Currencies" = SalesSetup."Appln. between Currencies"::None then
                OldCustLedgEntry.SetRange("Currency Code", NewCVLedgEntryBuf."Currency Code");
            OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId(OldCustLedgEntry, GenJnlLine, NewCVLedgEntryBuf, Cust);
            if OldCustLedgEntry.FindSet(false) then
                repeat
                    OnPrepareTempCustLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, NewCVLedgEntryBuf, OldCustLedgEntry);
                    if GenJnlApply.CheckAgainstApplnCurrency(
                         NewCVLedgEntryBuf."Currency Code", OldCustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, false)
                    then begin
                        if (OldCustLedgEntry."Posting Date" > ApplyingDate) and (OldCustLedgEntry."Applies-to ID" <> '') then
                            ApplyingDate := OldCustLedgEntry."Posting Date";
                        TempOldCustLedgEntry := OldCustLedgEntry;
                        OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(TempOldCustLedgEntry, GenJnlLine);
                        TempOldCustLedgEntry.Insert();
                    end;
                until OldCustLedgEntry.Next() = 0;

            TempOldCustLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            if TempOldCustLedgEntry.Find('-') then begin
                RemainingAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldCustLedgEntry.SetRange(Positive);
                TempOldCustLedgEntry.Find('-');
                repeat
                    TempOldCustLedgEntry.CalcFields("Remaining Amount");
                    TempOldCustLedgEntry.RecalculateAmounts(
                      TempOldCustLedgEntry."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    if PaymentToleranceMgt.CheckCalcPmtDiscCVCust(NewCVLedgEntryBuf, TempOldCustLedgEntry, 0, false, false) then
                        TempOldCustLedgEntry."Remaining Amount" -= TempOldCustLedgEntry.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date");
                    RemainingAmount += TempOldCustLedgEntry."Remaining Amount";
                until TempOldCustLedgEntry.Next() = 0;
                TempOldCustLedgEntry.SetRange(Positive, RemainingAmount < 0);
            end else
                TempOldCustLedgEntry.SetRange(Positive);

            OnPrepareTempCustLedgEntryOnBeforeExit(GenJnlLine, NewCVLedgEntryBuf, TempOldCustLedgEntry);
            exit(TempOldCustLedgEntry.Find('-'));
        end;
        exit(true);
    end;

    /// <summary>
    /// Posts all detailed customer ledger entries that are stored in DtldCVLedgEntryBuf. Creates g/l entry for the total amounts.
    /// </summary>
    /// <remarks>
    /// DtldCVLedgEntryBuf is cleared after the procedure is finished.
    /// </remarks>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="DtldCVLedgEntryBuf">Detailed customer ledger entries to be inserted and posted.</param>
    /// <param name="CustPostingGr">Customer posting group to be used for detailed cust. ledger entries.</param>
    /// <param name="LedgEntryInserted">Flag if customer ledger entries have already been created in the same transaction.</param>
    /// <returns>True if any detailed customer ledger entries has been created.</returns>
    procedure PostDtldCustLedgEntries(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; LedgEntryInserted: Boolean) DtldLedgEntryInserted: Boolean
    var
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AdjAmount: array[4] of Decimal;
        DtldCustLedgEntryNoOffset: Integer;
        SaveEntryNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforePostDtldCustLedgEntries(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, LedgEntryInserted);

        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::Customer then
            exit;

        if DtldCustLedgEntry.FindLast() then
            DtldCustLedgEntryNoOffset := DtldCustLedgEntry."Entry No."
        else
            DtldCustLedgEntryNoOffset := 0;

        OnPostDtldCustLedgEntriesOnAfterSetDtldCustLedgEntryNoOffset(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, LedgEntryInserted, NextEntryNo);

        MultiplePostingGroups := CheckCustMultiplePostingGroups(DtldCVLedgEntryBuf);

        DtldCVLedgEntryBuf.Reset();
        OnAfterSetDtldCustLedgEntryNoOffset(DtldCVLedgEntryBuf, DtldCustLedgEntryNoOffset);
        if DtldCVLedgEntryBuf.FindSet() then begin
            IsHandled := false;
            OnPostDtldCustLedgEntriesOnBeforeNextEntryNo(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, LedgEntryInserted, NextEntryNo, SaveEntryNo, IsHandled);
            if not IsHandled then
                if LedgEntryInserted then begin
                    SaveEntryNo := NextEntryNo;
                    IncrNextEntryNo();
                end;
            repeat
                InsertDtldCustLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, DtldCustLedgEntry, DtldCustLedgEntryNoOffset);
                IsHandled := false;
                OnPostDtldCustLedgEntriesOnBeforeUpdateTotalAmounts(GenJnlLine, DtldCustLedgEntry, IsHandled, DtldCVLedgEntryBuf);
                if not IsHandled then
                    UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);
                IsHandled := false;
                OnPostDtldCustLedgEntriesOnBeforePostDtldCustLedgEntry(DtldCVLedgEntryBuf, AddCurrencyCode, GenJnlLine, CustPostingGr, AdjAmount, IsHandled, NextEntryNo, DtldCustLedgEntry, LedgEntryInserted);
                if not IsHandled then
                    if ((DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or
                        (DtldCVLedgEntryBuf."VAT Amount (LCY)" <> 0)) or
                       ((AddCurrencyCode <> '') and (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                    then
                        PostDtldCustLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, AdjAmount);
            until DtldCVLedgEntryBuf.Next() = 0;
        end;

        IsHandled := false;
        OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmountsV19(
            CustPostingGr, DtldCVLedgEntryBuf,
            GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr), LedgEntryInserted, AddCurrencyCode, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmounts(
              GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetCustomerReceivablesAccount(GenJnlLine, CustPostingGr), LedgEntryInserted);

        OnPostDtldCustLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);

        DtldLedgEntryInserted := not DtldCVLedgEntryBuf.IsEmpty();
        DtldCVLedgEntryBuf.DeleteAll();
    end;

    local procedure PostDtldCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; var AdjAmount: array[4] of Decimal)
    var
        AccNo: Code[20];
    begin
        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetCustDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldCustLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, CustPostingGr, 0, false);
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, false);
    end;

    local procedure PostDtldCustLedgEntryUnapply(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; OriginalTransactionNo: Integer)
    var
        AdjAmount: array[4] of Decimal;
        AccNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldCustLedgEntryUnapply(GenJournalLine, DetailedCVLedgEntryBuffer, CustPostingGr, OriginalTransactionNo, IsHandled);
        if IsHandled then
            exit;

        if (DetailedCVLedgEntryBuffer."Amount (LCY)" = 0) and
           (DetailedCVLedgEntryBuffer."VAT Amount (LCY)" = 0) and
           ((AddCurrencyCode = '') or (DetailedCVLedgEntryBuffer."Additional-Currency Amount" = 0))
        then
            exit;

        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetCustDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldCustLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, CustPostingGr, OriginalTransactionNo, true);
        DetailedCVLedgEntryBuffer."Gen. Posting Type" := DetailedCVLedgEntryBuffer."Gen. Posting Type"::Sale;
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, true);
    end;

    local procedure GetDtldCustLedgEntryAccNo(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGr: Record "Customer Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean) AccountNo: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
        Currency: Record Currency;
        AmountCondition: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDtldCustLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, CustPostingGr, OriginalTransactionNo, Unapply, VATEntry, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        AmountCondition := IsDebitAmount(DtldCVLedgEntryBuf, Unapply);
        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                ;
            DtldCVLedgEntryBuf."Entry Type"::Application:
                ;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                begin
                    GetCurrency(Currency, DtldCVLedgEntryBuf."Currency Code");
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                begin
                    DtldCVLedgEntryBuf.TestField("Gen. Prod. Posting Group");
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                exit(CustPostingGr.GetApplRoundingAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                exit(CustPostingGr.GetRoundingAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                case GLSetup."Pmt. Disc. Tolerance Posting" of
                    GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                        exit(CustPostingGr.GetPmtToleranceAccount(AmountCondition));
                    GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                        exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                case GLSetup."Payment Tolerance Posting" of
                    GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                        exit(CustPostingGr.GetPmtToleranceAccount(AmountCondition));
                    GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                        exit(CustPostingGr.GetPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                begin
                    DtldCVLedgEntryBuf.TestField("Gen. Prod. Posting Group");
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    case GLSetup."Payment Tolerance Posting" of
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(GenPostingSetup.GetSalesPmtToleranceAccount(AmountCondition));
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                    end;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                begin
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    case GLSetup."Pmt. Disc. Tolerance Posting" of
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(GenPostingSetup.GetSalesPmtToleranceAccount(AmountCondition));
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            exit(GenPostingSetup.GetSalesPmtDiscountAccount(AmountCondition));
                    end;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
          DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
          DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                if Unapply then
                    PostDtldCustVATAdjustment(GenJnlLine, DtldCVLedgEntryBuf, OriginalTransactionNo);
            else
                DtldCVLedgEntryBuf.FieldError("Entry Type");
        end;
    end;

    local procedure CustUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry2: Record "Cust. Ledger Entry"; SettledAmount: Decimal)
    var
        VATEntry2: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        SalesVATAccount: Code[20];
        SalesVATUnrealAccount: Code[20];
        LastConnectionNo: Integer;
        GLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustUnrealizedVAT(GenJnlLine, CustLedgEntry2, SettledAmount, IsHandled);
        if IsHandled then
            exit;

        PaidAmount := CustLedgEntry2."Amount (LCY)" - CustLedgEntry2."Remaining Amt. (LCY)";
        OnCustUnrealizedVATOnAfterCalcPaidAmount(GenJnlLine, CustLedgEntry2, SettledAmount, PaidAmount);
        VATEntry2.ReadIsolation := IsolationLevel::ReadUncommitted;
        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", CustLedgEntry2."Transaction No.");

        OnCustUnrealizedVATOnAfterSetFilterForVATEntry2(VATEntry2);

        if VATEntry2.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"]
                then
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"]
                then
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            until VATEntry2.Next() = 0;
        if VATEntry2.FindSet() then begin
            LastConnectionNo := 0;
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                    InsertSummarizedVAT(GenJnlLine);
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                end;

                VATPart :=
                  VATEntry2.GetUnrealizedVATPart(
                    Round(SettledAmount / CustLedgEntry2.GetAdjustedCurrencyFactor()),
                    PaidAmount,
                    CustLedgEntry2."Amount (LCY)",
                    TotalUnrealVATAmountFirst,
                    TotalUnrealVATAmountLast);

                OnCustUnrealizedVATOnAfterVATPartCalculation(
                  GenJnlLine, CustLedgEntry2, PaidAmount, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast, SettledAmount, VATEntry2);

                if VATPart > 0 then begin
                    case VATEntry2."VAT Calculation Type" of
                        VATEntry2."VAT Calculation Type"::"Normal VAT",
                        VATEntry2."VAT Calculation Type"::"Reverse Charge VAT",
                        VATEntry2."VAT Calculation Type"::"Full VAT":
                            begin
                                SalesVATAccount := VATPostingSetup.GetSalesAccount(false);
                                SalesVATUnrealAccount := VATPostingSetup.GetSalesAccount(true);
                            end;
                        VATEntry2."VAT Calculation Type"::"Sales Tax":
                            begin
                                TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                                SalesVATAccount := TaxJurisdiction.GetSalesAccount(false);
                                SalesVATUnrealAccount := TaxJurisdiction.GetSalesAccount(true);
                            end;
                    end;

                    OnCustUnrealizedVATOnAfterSetSalesVATAccounts(VATEntry2, VATPostingSetup, SalesVATAccount, SalesVATUnrealAccount);

                    if VATPart = 1 then begin
                        VATAmount := VATEntry2."Remaining Unrealized Amount";
                        VATBase := VATEntry2."Remaining Unrealized Base";
                        VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                        VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                    end else begin
                        VATAmount := Round(VATEntry2."Remaining Unrealized Amount" * VATPart, GLSetup."Amount Rounding Precision");
                        VATBase := Round(VATEntry2."Remaining Unrealized Base" * VATPart, GLSetup."Amount Rounding Precision");
                        VATAmountAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        VATBaseAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                    end;

                    IsHandled := false;
                    OnCustUnrealizedVATOnBeforeInitGLEntryVAT(
                      GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, IsHandled, SalesVATUnrealAccount, CustLedgEntry2, SettledAmount);
                    if not IsHandled then
                        InitGLEntryVAT(
                            GenJnlLine, SalesVATUnrealAccount, SalesVATAccount, -VATAmount, -VATAmountAddCurr, false);

                    GLEntryNo :=
                      InitGLEntryVATCopy(GenJnlLine, SalesVATAccount, SalesVATUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2);

                    OnCustUnrealizedVATOnBeforePostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo, VATPart);
                    PostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo);
                end;
            until VATEntry2.Next() = 0;

            InsertSummarizedVAT(GenJnlLine);
        end;
    end;

    /// <summary>
    /// Prepares and posts vendor ledger entries needed for the application. Detailed vendor ledger entries are created and posted for both
    /// the old and the new vendor ledger entry.
    /// </summary>
    /// <param name="NewCVLedgEntryBuf">Return value: Buffer to collect vendor ledger entries that has been created for the application.</param>
    /// <param name="DtldCVLedgEntryBuf">Return value: Buffer to collect detailed vendor ledger entries that has been created for the application.</param>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="Vend">Vendor that the vendor ledger entries are created for.</param>
    procedure ApplyVendLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; Vend: Record Vendor)
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        Completed: Boolean;
        AppliedAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
        AllApplied: Boolean;
        IsAmountToApplyCheckHandled: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyVendLedgEntry(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, Vend, IsAmountToApplyCheckHandled, IsHandled);
        if IsHandled then
            exit;

        if not IsAmountToApplyCheckHandled then
            if NewCVLedgEntryBuf."Amount to Apply" = 0 then
                exit;

        AllApplied := true;
        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') and
           not
           ((Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") and
            GenJnlLine."Allow Application")
        then
            exit;

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        ApplyingDate := GenJnlLine."Posting Date";

        if not PrepareTempVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry, Vend, ApplyingDate) then
            exit;

        GenJnlLine."Posting Date" := ApplyingDate;
        // Apply the new entry (Payment) to the old entries (Invoices) one at a time
        repeat
            TempOldVendLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            OnApplyVendLedgEntryOnBeforeCopyFromVendLedgEntry(GenJnlLine, OldCVLedgEntryBuf, TempOldVendLedgEntry, NewCVLedgEntryBuf);
            OldCVLedgEntryBuf.CopyFromVendLedgEntry(TempOldVendLedgEntry);
            TempOldVendLedgEntry.CopyFilter(Positive, OldCVLedgEntryBuf.Positive);

            PostApply(
              GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2,
              Vend."Block Payment Tolerance", AllApplied, AppliedAmount, PmtTolAmtToBeApplied);

            // Update the Old Entry
            TempOldVendLedgEntry.CopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf);
            OldVendLedgEntry := TempOldVendLedgEntry;
            if GenJnlLine."On Hold" = OldVendLedgEntry."On Hold" then
                OldVendLedgEntry."On Hold" := '';
            OldVendLedgEntry."Amount to Apply" := OldCVLedgEntryBuf."Amount to Apply";
            if OldVendLedgEntry."Amount to Apply" = 0 then
                OldVendLedgEntry."Applies-to ID" := ''
            else begin
                TempVendorLedgerEntry := OldVendLedgEntry;
                if TempVendorLedgerEntry.Insert() then;
            end;
            OnApplyVendLedgEntryOnBeforeOldVendLedgEntryModify(GenJnlLine, OldVendLedgEntry, NewCVLedgEntryBuf, AppliedAmount);
            OldVendLedgEntry.Modify();

            OnAfterOldVendLedgEntryModify(OldVendLedgEntry, GenJnlLine, TempVendorLedgerEntry, DtldCVLedgEntryBuf);

            IsHandled := false;
            OnApplyVendLedgEntryOnBeforeVendUnrealizedVAT(TempOldVendLedgEntry, IsHandled);
            if not IsHandled then
                if GLSetup."Unrealized VAT" or
                   (GLSetup."Prepayment Unrealized VAT" and TempOldVendLedgEntry.Prepayment)
                then
                    if IsNotPayment(TempOldVendLedgEntry."Document Type") then begin
                        TempOldVendLedgEntry.RecalculateAmounts(
                          NewCVLedgEntryBuf."Currency Code", TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date");
                        OnApplyVendLedgEntryOnAfterRecalculateAmounts(TempOldVendLedgEntry, OldVendLedgEntry, NewCVLedgEntryBuf, GenJnlLine);
                        VendUnrealizedVAT(
                          GenJnlLine,
                          TempOldVendLedgEntry,
                          CurrExchRate.ExchangeAmount(
                            AppliedAmount, NewCVLedgEntryBuf."Currency Code",
                            TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Posting Date"));
                    end;

            OnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete(GenJnlLine, TempOldVendLedgEntry, AppliedAmount, NewCVLedgEntryBuf, OldCVLedgEntryBuf);
            TempOldVendLedgEntry.Delete();

            Completed := FindNextOldVendLedgEntryToApply(GenJnlLine, TempOldVendLedgEntry, NewCVLedgEntryBuf);
        until Completed;

        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CalcSums("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;
        IsHandled := false;
        OnApplyVendLedgEntryOnBeforeUnrealizedVAT(GenJnlLine, NewCVLedgEntryBuf, NewVendLedgEntry, IsHandled);
        if not IsHandled then
            if GLSetup."Unrealized VAT" or
               (GLSetup."Prepayment Unrealized VAT" and NewCVLedgEntryBuf.Prepayment)
            then
                if IsNotPayment(NewCVLedgEntryBuf."Document Type") and
                   (NewRemainingAmtBeforeAppln - NewCVLedgEntryBuf."Remaining Amount" <> 0)
                then begin
                    NewVendLedgEntry.CopyFromCVLedgEntryBuffer(NewCVLedgEntryBuf);
                    CheckUnrealizedVend := true;
                    UnrealizedVendLedgEntry := NewVendLedgEntry;
                    UnrealizedVendLedgEntry.CalcFields("Amount (LCY)", "Original Amt. (LCY)");
                    UnrealizedRemainingAmountVend := -(NewRemainingAmtBeforeAppln - NewVendLedgEntry."Remaining Amount");
                end;

        OnAfterApplyVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf, OldVendLedgEntry, NewRemainingAmtBeforeAppln);
    end;

    local procedure FindNextOldVendLedgEntryToApply(GenJnlLine: Record "Gen. Journal Line"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer") Completed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindNextOldVendLedgEntryToApply(GenJnlLine, TempOldVendLedgEntry, NewCVLedgEntryBuf, Completed, IsHandled);
        if IsHandled then
            exit(Completed);

        if GenJnlLine."Applies-to Doc. No." <> '' then
            Completed := true
        else
            if TempOldVendLedgEntry.GetFilter(Positive) <> '' then
                if TempOldVendLedgEntry.Next() = 1 then
                    Completed := false
                else begin
                    TempOldVendLedgEntry.SetRange(Positive);
                    TempOldVendLedgEntry.Find('-');
                    TempOldVendLedgEntry.CalcFields("Remaining Amount");
                    Completed := TempOldVendLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                end
            else
                if NewCVLedgEntryBuf.Open then
                    Completed := TempOldVendLedgEntry.Next() = 0
                else
                    Completed := true;
    end;

    /// <summary>
    /// Prepares and posts employee ledger entries needed for the application. Detailed employee ledger entries are created and posted for both
    /// the old and the new employee ledger entry.
    /// </summary>
    /// <param name="NewCVLedgEntryBuf">Return value: Buffer to collect employee ledger entries that has been created for the application.</param>
    /// <param name="DtldCVLedgEntryBuf">Return value: Buffer to collect detailed employee ledger entries that has been created for the application.</param>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="Employee">Employee that the employee ledger entries are created for.</param>
    procedure ApplyEmplLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; Employee: Record Employee)
    var
        OldEmplLedgEntry: Record "Employee Ledger Entry";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        TempOldEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        Completed: Boolean;
        AppliedAmount: Decimal;
        NewRemainingAmtBeforeAppln: Decimal;
        ApplyingDate: Date;
        PmtTolAmtToBeApplied: Decimal;
        AllApplied: Boolean;
    begin
        if NewCVLedgEntryBuf."Amount to Apply" = 0 then
            exit;

        AllApplied := true;
        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') and
           not
           ((Employee."Application Method" = Employee."Application Method"::"Apply to Oldest") and
            GenJnlLine."Allow Application")
        then
            exit;

        PmtTolAmtToBeApplied := 0;
        NewRemainingAmtBeforeAppln := NewCVLedgEntryBuf."Remaining Amount";
        NewCVLedgEntryBuf2 := NewCVLedgEntryBuf;

        ApplyingDate := GenJnlLine."Posting Date";

        if not PrepareTempEmplLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldEmplLedgEntry, Employee, ApplyingDate) then
            exit;

        GenJnlLine."Posting Date" := ApplyingDate;

        // Apply the new entry (Payment) to the old entries one at a time
        repeat
            TempOldEmplLedgEntry.CalcFields(
              Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
              "Original Amount", "Original Amt. (LCY)");
            OldCVLedgEntryBuf.CopyFromEmplLedgEntry(TempOldEmplLedgEntry);
            TempOldEmplLedgEntry.CopyFilter(Positive, OldCVLedgEntryBuf.Positive);

            PostApply(
              GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2,
              true, AllApplied, AppliedAmount, PmtTolAmtToBeApplied);

            // Update the Old Entry
            TempOldEmplLedgEntry.CopyFromCVLedgEntryBuffer(OldCVLedgEntryBuf);
            OldEmplLedgEntry := TempOldEmplLedgEntry;
            OldEmplLedgEntry."Applies-to ID" := '';
            OldEmplLedgEntry."Amount to Apply" := 0;
            OnApplyEmplLedgEntryOnBeforeOldEmplLedgEntryModify(GenJnlLine, OldEmplLedgEntry, NewCVLedgEntryBuf, AppliedAmount);
            OldEmplLedgEntry.Modify();

            TempOldEmplLedgEntry.Delete();

            Completed := FindNextOldEmplLedgEntryToApply(GenJnlLine, TempOldEmplLedgEntry, NewCVLedgEntryBuf);
        until Completed;

        DtldCVLedgEntryBuf.SetCurrentKey("CV Ledger Entry No.", "Entry Type");
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", NewCVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange(
          "Entry Type",
          DtldCVLedgEntryBuf."Entry Type"::Application);
        DtldCVLedgEntryBuf.CalcSums("Amount (LCY)", Amount);

        CalcCurrencyUnrealizedGainLoss(
          NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf.Amount, NewRemainingAmtBeforeAppln);

        CalcAmtLCYAdjustment(NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);

        NewCVLedgEntryBuf."Applies-to ID" := '';
        NewCVLedgEntryBuf."Amount to Apply" := 0;

        OnAfterApplyEmplLedgEntry(GenJnlLine, NewCVLedgEntryBuf, OldEmplLedgEntry);
    end;

    local procedure FindNextOldEmplLedgEntryToApply(GenJnlLine: Record "Gen. Journal Line"; var TempOldEmplLedgEntry: Record "Employee Ledger Entry" temporary; NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer") Completed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindNextOldEmplLedgEntryToApply(GenJnlLine, TempOldEmplLedgEntry, NewCVLedgEntryBuf, Completed, IsHandled);
        if IsHandled then
            exit(Completed);

        if GenJnlLine."Applies-to Doc. No." <> '' then
            Completed := true
        else
            if TempOldEmplLedgEntry.GetFilter(Positive) <> '' then
                if TempOldEmplLedgEntry.Next() = 1 then
                    Completed := false
                else begin
                    TempOldEmplLedgEntry.SetRange(Positive);
                    TempOldEmplLedgEntry.Find('-');
                    TempOldEmplLedgEntry.CalcFields("Remaining Amount");
                    Completed := TempOldEmplLedgEntry."Remaining Amount" * NewCVLedgEntryBuf."Remaining Amount" >= 0;
                end
            else
                if NewCVLedgEntryBuf.Open then
                    Completed := TempOldEmplLedgEntry.Next() = 0
                else
                    Completed := true;
    end;

    /// <summary>
    /// Stand-alone procedure to post (from check to finish) application gen. journal line for the vendor ledger entries.
    /// G/l entries, vat entries, vendor ledger entries and detailed vendor ledger entries are created and posted.
    /// </summary>
    /// <param name="GenJnlLinePostApply">Gen. journal line that should be posted for application purpose.</param>
    /// <param name="VendLedgEntryPostApply">Vendor ledger entry that the new application should be applied to.</param>
    procedure VendPostApplyVendLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var VendLedgEntryPostApply: Record "Vendor Ledger Entry")
    var
        Vend: Record Vendor;
        VendPostingGr: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        DtldLedgEntryInserted: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeVendPostApplyVendLedgEntry(GenJnlLinePostApply, VendLedgEntryPostApply);

        GenJnlLine := GenJnlLinePostApply;
        VendLedgEntry.TransferFields(VendLedgEntryPostApply);
        OnVendPostApplyVendLedgEntryOnAfterVendLedgEntryTransferFields(VendLedgEntry, GenJnlLine);
        GenJnlLine."Source Currency Code" := VendLedgEntryPostApply."Currency Code";
        GenJnlLine."Applies-to ID" := VendLedgEntryPostApply."Applies-to ID";

        AmountRoundingPrecision := GetSourceCurrency(GenJnlLine."Source Currency Code");

        IsHandled := false;
        OnVendPostApplyVendLedgEntryOnBeforeRunCheck(GenJnlLine, IsHandled);
        if not IsHandled then
            GenJnlCheckLine.RunCheck(GenJnlLine);

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        Vend.Get(VendLedgEntry."Vendor No.");
        Vend.CheckBlockedVendOnJnls(Vend, GenJnlLine."Document Type", true);

        OnVendPostApplyVendLedgEntryOnBeforeCheckPostingGroup(GenJnlLine, Vend);
        if GenJnlLine."Posting Group" = '' then begin
            Vend.TestField("Vendor Posting Group");
            GenJnlLine."Posting Group" := Vend."Vendor Posting Group";
        end;
        GetVendorPostingGroup(GenJnlLine, VendPostingGr);
        IsHandled := false;
        OnBeforeGetVendorPayablesAccount(GenJnlLine, VendPostingGr, VendPostingGr."Payables Account", IsHandled);
        if not IsHandled then
            VendPostingGr.GetPayablesAccount();

        DtldVendLedgEntry.LockTable();
        VendLedgEntry.LockTable();

        // Post the application
        VendLedgEntry.CalcFields(
          Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
          "Original Amount", "Original Amt. (LCY)");
        OnVendPostApplyVendLedgEntryOnBeforeCopyFromVendLedgEntry(GenJnlLine, CVLedgEntryBuf, VendLedgEntry);
        CVLedgEntryBuf.CopyFromVendLedgEntry(VendLedgEntry);
        OnVendPostApplyVendLedgEntryOnBeforeApplyVendLedgEntry(VendLedgEntry, GenJnlLine, CVLedgEntryBuf);
        ApplyVendLedgEntry(CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Vend);
        OnVendPostApplyVendLedgEntryOnAfterApplyVendLedgEntry(GenJnlLine, TempDtldCVLedgEntryBuf);
        VendLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
        VendLedgEntry.Modify(true);
        // Post Dtld vendor entry
        OnVendPostApplyVendLedgEntryOnBeforePostDtldVendLedgEntries(VendLedgEntry);
        DtldLedgEntryInserted := PostDtldVendLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, VendPostingGr, false);

        OnVendPostApplyVendLedgEntryOnBeforeCheckPostUnrealizedVAT(GenJnlLine, TempDtldCVLedgEntryBuf, DtldLedgEntryInserted);
        CheckPostUnrealizedVAT(GenJnlLine, true);

        if DtldLedgEntryInserted then
            if IsTempGLEntryBufEmpty() then
                DtldVendLedgEntry.SetZeroTransNo(NextTransactionNo);

        OnVendPostApplyVendLedgEntryOnBeforeFinishPosting(GenJnlLine, VendLedgEntry);

        FinishPosting(GenJnlLine);
        OnAfterVendPostApplyVendLedgEntry(GenJnlLine, GLReg);
    end;

    /// <summary>
    /// Stand-alone procedure to post (from check to finish) application gen. journal line for the employee ledger entries.
    /// G/l entries, vat entries, employee ledger entries and detailed employee ledger entries are created and posted.
    /// </summary>
    /// <param name="GenJnlLinePostApply">Gen. journal line that should be posted for application purpose.</param>
    /// <param name="EmplLedgEntryPostApply">Employee ledger entry that the new application should be applied to.</param>
    procedure EmplPostApplyEmplLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var EmplLedgEntryPostApply: Record "Employee Ledger Entry")
    var
        Empl: Record Employee;
        EmplPostingGr: Record "Employee Posting Group";
        EmplLedgEntry: Record "Employee Ledger Entry";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        DtldLedgEntryInserted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEmplPostApplyEmplLedgEntry(GenJnlLinePostApply, EmplLedgEntryPostApply, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine := GenJnlLinePostApply;
        EmplLedgEntry.TransferFields(EmplLedgEntryPostApply);
        GenJnlLine."Source Currency Code" := EmplLedgEntryPostApply."Currency Code";
        GenJnlLine."Applies-to ID" := EmplLedgEntryPostApply."Applies-to ID";

        AmountRoundingPrecision := GetSourceCurrency(GenJnlLine."Source Currency Code");

        GenJnlCheckLine.RunCheck(GenJnlLine);

        if NextEntryNo = 0 then
            StartPosting(GenJnlLine)
        else
            ContinuePosting(GenJnlLine);

        Empl.Get(EmplLedgEntry."Employee No.");

        if GenJnlLine."Posting Group" = '' then begin
            Empl.TestField("Employee Posting Group");
            GenJnlLine."Posting Group" := Empl."Employee Posting Group";
        end;
        EmplPostingGr.Get(GenJnlLine."Posting Group");
        IsHandled := false;
        OnBeforeGetEmployeePayablesAccount(GenJnlLine, EmplPostingGr, EmplPostingGr."Payables Account", IsHandled);
        if not IsHandled then
            EmplPostingGr.GetPayablesAccount();

        DtldEmplLedgEntry.LockTable();
        EmplLedgEntry.LockTable();

        // Post the application
        EmplLedgEntry.CalcFields(
          Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)",
          "Original Amount", "Original Amt. (LCY)");
        CVLedgEntryBuf.CopyFromEmplLedgEntry(EmplLedgEntry);
        ApplyEmplLedgEntry(
          CVLedgEntryBuf, TempDtldCVLedgEntryBuf, GenJnlLine, Empl);
        EmplLedgEntry.CopyFromCVLedgEntryBuffer(CVLedgEntryBuf);
        EmplLedgEntry.Modify(true);

        // Post Dtld vendor entry
        DtldLedgEntryInserted := PostDtldEmplLedgEntries(GenJnlLine, TempDtldCVLedgEntryBuf, EmplPostingGr, false);

        CheckPostUnrealizedVAT(GenJnlLine, true);

        if DtldLedgEntryInserted then
            if IsTempGLEntryBufEmpty() then
                DtldEmplLedgEntry.SetZeroTransNo(NextTransactionNo);

        FinishPosting(GenJnlLine);
    end;

    local procedure PrepareTempVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary; Vend: Record Vendor; var ApplyingDate: Date): Boolean
    var
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        RemainingAmount: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareTempVendLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry, Vend, ApplyingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            // Find the entry to be applied to
            OldVendLedgEntry.Reset();
            OldVendLedgEntry.SetLoadFields(Positive, "Posting Date", "Currency Code");
            OldVendLedgEntry.SetCurrentKey("Document No.");
            OldVendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldVendLedgEntry.SetRange("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SetRange(Open, true);
            OnPrepareTempVendLedgEntryOnAfterSetFilters(OldVendLedgEntry, GenJnlLine, NewCVLedgEntryBuf);
            OldVendLedgEntry.FindFirst();
            IsHandled := false;
            OnPrepareTempVendLedgEntryOnBeforeTestPositive(GenJnlLine, IsHandled);
            if not IsHandled then
                OldVendLedgEntry.TestField(Positive, not NewCVLedgEntryBuf.Positive);
            if OldVendLedgEntry."Posting Date" > ApplyingDate then
                ApplyingDate := OldVendLedgEntry."Posting Date";
            OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrencyWithAppliesToDocNo(GenJnlLine, NewCVLedgEntryBuf, OldVendLedgEntry);
            GenJnlApply.CheckAgainstApplnCurrency(
              NewCVLedgEntryBuf."Currency Code", OldVendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
            TempOldVendLedgEntry := OldVendLedgEntry;
            OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(TempOldVendLedgEntry, GenJnlLine);
            TempOldVendLedgEntry.Insert();
        end else begin
            // Find the first old entry (Invoice) which the new entry (Payment) should apply to
            OldVendLedgEntry.Reset();
            OldVendLedgEntry.SetLoadFields("Posting Date", "Currency Code", "Applies-to ID");
            OldVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            TempOldVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            OldVendLedgEntry.SetRange("Vendor No.", NewCVLedgEntryBuf."CV No.");
            OldVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            OldVendLedgEntry.SetRange(Open, true);
            OldVendLedgEntry.SetFilter("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            if not (Vend."Application Method" = Vend."Application Method"::"Apply to Oldest") then
                OldVendLedgEntry.SetFilter("Amount to Apply", '<>%1', 0);

            if Vend."Application Method" = Vend."Application Method"::"Apply to Oldest" then
                OldVendLedgEntry.SetFilter("Posting Date", '..%1', GenJnlLine."Posting Date");

            // Check and Move Ledger Entries to Temp
            PurchSetup.Get();
            if PurchSetup."Appln. between Currencies" = PurchSetup."Appln. between Currencies"::None then
                OldVendLedgEntry.SetRange("Currency Code", NewCVLedgEntryBuf."Currency Code");
            OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo(OldVendLedgEntry, GenJnlLine, NewCVLedgEntryBuf, Vend);
            if OldVendLedgEntry.FindSet(false) then
                repeat
                    OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, NewCVLedgEntryBuf, OldVendLedgEntry);
                    if GenJnlApply.CheckAgainstApplnCurrency(
                         NewCVLedgEntryBuf."Currency Code", OldVendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, false)
                    then begin
                        if (OldVendLedgEntry."Posting Date" > ApplyingDate) and (OldVendLedgEntry."Applies-to ID" <> '') then
                            ApplyingDate := OldVendLedgEntry."Posting Date";
                        TempOldVendLedgEntry := OldVendLedgEntry;
                        OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(TempOldVendLedgEntry, GenJnlLine);
                        TempOldVendLedgEntry.Insert();
                    end;
                until OldVendLedgEntry.Next() = 0;

            TempOldVendLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            if TempOldVendLedgEntry.Find('-') then begin
                RemainingAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldVendLedgEntry.SetRange(Positive);
                TempOldVendLedgEntry.Find('-');
                repeat
                    TempOldVendLedgEntry.CalcFields("Remaining Amount");
                    TempOldVendLedgEntry.RecalculateAmounts(
                      TempOldVendLedgEntry."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    if PaymentToleranceMgt.CheckCalcPmtDiscCVVend(NewCVLedgEntryBuf, TempOldVendLedgEntry, 0, false, false) then
                        TempOldVendLedgEntry."Remaining Amount" -= TempOldVendLedgEntry.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date");
                    RemainingAmount += TempOldVendLedgEntry."Remaining Amount";
                until TempOldVendLedgEntry.Next() = 0;
                TempOldVendLedgEntry.SetRange(Positive, RemainingAmount < 0);
            end else
                TempOldVendLedgEntry.SetRange(Positive);

            OnPrepareTempVendLedgEntryOnBeforeExit(GenJnlLine, NewCVLedgEntryBuf, TempOldVendLedgEntry);
            exit(TempOldVendLedgEntry.Find('-'));
        end;
        exit(true);
    end;

    local procedure PrepareTempEmplLedgEntry(GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempOldEmplLedgEntry: Record "Employee Ledger Entry" temporary; Employee: Record Employee; var ApplyingDate: Date): Boolean
    var
        OldEmplLedgEntry: Record "Employee Ledger Entry";
        RemainingAmount: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepareTempEmplLedgEntry(GenJnlLine, NewCVLedgEntryBuf, TempOldEmplLedgEntry, Employee, ApplyingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            // Find the entry to be applied to
            OldEmplLedgEntry.Reset();
            OldEmplLedgEntry.SetCurrentKey("Document No.");
            OldEmplLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            OldEmplLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            OldEmplLedgEntry.SetRange("Employee No.", NewCVLedgEntryBuf."CV No.");
            OldEmplLedgEntry.SetRange(Open, true);
            OldEmplLedgEntry.FindFirst();
            IsHandled := false;
            OnPrepareTempVendLedgEntryOnBeforeTestPositive(GenJnlLine, IsHandled);
            if not IsHandled then
                OldEmplLedgEntry.TestField(Positive, not NewCVLedgEntryBuf.Positive);

            if OldEmplLedgEntry."Posting Date" > ApplyingDate then
                ApplyingDate := OldEmplLedgEntry."Posting Date";
            TempOldEmplLedgEntry := OldEmplLedgEntry;
            OnPrepareTempEmplLedgEntryOnAppDocNoOnBeforeTempOldEmplLedgEntryInsert(TempOldEmplLedgEntry, GenJnlLine);
            TempOldEmplLedgEntry.Insert();
        end else begin
            // Find the first old entry which the new entry (Payment) should apply to
            OldEmplLedgEntry.Reset();
            OldEmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open, Positive);
            TempOldEmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open, Positive);
            OldEmplLedgEntry.SetRange("Employee No.", NewCVLedgEntryBuf."CV No.");
            OldEmplLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            OldEmplLedgEntry.SetRange(Open, true);
            OldEmplLedgEntry.SetFilter("Entry No.", '<>%1', NewCVLedgEntryBuf."Entry No.");
            if not (Employee."Application Method" = Employee."Application Method"::"Apply to Oldest") then
                OldEmplLedgEntry.SetFilter("Amount to Apply", '<>%1', 0);

            if Employee."Application Method" = Employee."Application Method"::"Apply to Oldest" then
                OldEmplLedgEntry.SetFilter("Posting Date", '..%1', GenJnlLine."Posting Date");

            OnPrepareTempEmplLedgEntryOnAfterSetFiltersByAppliesToId(OldEmplLedgEntry, GenJnlLine, NewCVLedgEntryBuf, Employee);
            if OldEmplLedgEntry.FindSet(false) then
                repeat
                    if (OldEmplLedgEntry."Posting Date" > ApplyingDate) and (OldEmplLedgEntry."Applies-to ID" <> '') then
                        ApplyingDate := OldEmplLedgEntry."Posting Date";
                    TempOldEmplLedgEntry := OldEmplLedgEntry;
                    OnPrepareTempEmplLedgEntryOnAppToIDOnBeforeTempOldEmplLedgEntryInsert(TempOldEmplLedgEntry, GenJnlLine);
                    TempOldEmplLedgEntry.Insert();
                until OldEmplLedgEntry.Next() = 0;

            TempOldEmplLedgEntry.SetRange(Positive, NewCVLedgEntryBuf."Remaining Amount" > 0);

            if TempOldEmplLedgEntry.Find('-') then begin
                RemainingAmount := NewCVLedgEntryBuf."Remaining Amount";
                TempOldEmplLedgEntry.SetRange(Positive);
                TempOldEmplLedgEntry.Find('-');
                repeat
                    TempOldEmplLedgEntry.CalcFields("Remaining Amount");
                    TempOldEmplLedgEntry.RecalculateAmounts(
                      TempOldEmplLedgEntry."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");
                    OnPrepareTempEmplLedgEntryOnBeforeUpdateRemainingAmount(TempOldEmplLedgEntry, NewCVLedgEntryBuf);
                    RemainingAmount += TempOldEmplLedgEntry."Remaining Amount";
                until TempOldEmplLedgEntry.Next() = 0;
                TempOldEmplLedgEntry.SetRange(Positive, RemainingAmount < 0);
            end else
                TempOldEmplLedgEntry.SetRange(Positive);
            exit(TempOldEmplLedgEntry.Find('-'));
        end;
        exit(true);
    end;

    /// <summary>
    /// Posts all detailed vendor ledger entries that are stored in DtldCVLedgEntryBuf. Creates g/l entry for the total amounts.
    /// </summary>
    /// <remarks>
    /// DtldCVLedgEntryBuf is cleared after the procedure is finished.
    /// </remarks>
    /// <param name="GenJournalLine">Gen. journal line that is being posted.</param>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed vendor ledger entries to be inserted and posted.</param>
    /// <param name="VendPostingGr">Vendor posting group to be used for detailed vendor ledger entries.</param>
    /// <param name="LedgEntryInserted">Flag if vendor ledger entries have already been created in the same transaction.</param>
    /// <returns>True if any detailed vendor ledger entries has been created.</returns>
    procedure PostDtldVendLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; LedgEntryInserted: Boolean) DtldLedgEntryInserted: Boolean
    var
        TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        AdjAmount: array[4] of Decimal;
        DtldVendLedgEntryNoOffset: Integer;
        SaveEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GenJournalLine."Account Type" <> GenJournalLine."Account Type"::Vendor then
            exit;

        OnPostDtldVendLedgEntriesOnBeforeSetDtldVendLedgEntryNoOffset(GenJournalLine, DetailedVendorLedgEntry);

        if DetailedVendorLedgEntry.FindLast() then
            DtldVendLedgEntryNoOffset := DetailedVendorLedgEntry."Entry No."
        else
            DtldVendLedgEntryNoOffset := 0;

        OnPostDtldVendLedgEntriesOnAfterSetDtldVendLedgEntryNoOffset(GenJournalLine, DetailedVendorLedgEntry, DtldVendLedgEntryNoOffset);

        MultiplePostingGroups := CheckVendMultiplePostingGroups(DetailedCVLedgEntryBuffer);

        DetailedCVLedgEntryBuffer.Reset();
        OnAfterSetDtldVendLedgEntryNoOffset(DetailedCVLedgEntryBuffer, DtldVendLedgEntryNoOffset);
        if DetailedCVLedgEntryBuffer.FindSet() then begin
            if LedgEntryInserted then begin
                SaveEntryNo := NextEntryNo;
                IncrNextEntryNo();
            end;
            repeat
                InsertDtldVendLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, DetailedVendorLedgEntry, DtldVendLedgEntryNoOffset);
                IsHandled := false;
                OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts(GenJournalLine, DetailedVendorLedgEntry, IsHandled, DetailedCVLedgEntryBuffer);
                if not IsHandled then
                    UpdateTotalAmounts(TempDimensionPostingBuffer, GenJournalLine."Dimension Set ID", DetailedCVLedgEntryBuffer);
                IsHandled := false;
                OnPostDtldVendLedgEntriesOnBeforePostDtldVendLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, VendPostingGr, AdjAmount, IsHandled, LedgEntryInserted);
                if not IsHandled then
                    if ((DetailedCVLedgEntryBuffer."Amount (LCY)" <> 0) or
                        (DetailedCVLedgEntryBuffer."VAT Amount (LCY)" <> 0)) or
                       ((AddCurrencyCode <> '') and (DetailedCVLedgEntryBuffer."Additional-Currency Amount" <> 0))
                    then
                        PostDtldVendLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, VendPostingGr, AdjAmount);
                OnPostDtldVendLedgEntriesOnAfterPostDtldVendLedgEntry(DetailedCVLedgEntryBuffer, DetailedVendorLedgEntry, LedgEntryInserted);
            until DetailedCVLedgEntryBuffer.Next() = 0;
        end;

        IsHandled := false;
        OnPostDtldVendLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(VendPostingGr, DetailedCVLedgEntryBuffer, GenJournalLine, TempDimensionPostingBuffer, AdjAmount, SaveEntryNo, LedgEntryInserted, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmounts(
                GenJournalLine, TempDimensionPostingBuffer, AdjAmount, SaveEntryNo, GetVendorPayablesAccount2(DetailedCVLedgEntryBuffer, GenJournalLine, VendPostingGr), LedgEntryInserted);

        OnPostDtldVendLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);

        DtldLedgEntryInserted := not DetailedCVLedgEntryBuffer.IsEmpty();
        DetailedCVLedgEntryBuffer.DeleteAll();
    end;

    local procedure PostDtldVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; var AdjAmount: array[4] of Decimal)
    var
        AccNo: Code[20];
    begin
        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetVendDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldVendLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, VendPostingGr, 0, false);
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, false);
    end;

    local procedure PostDtldVendLedgEntryUnapply(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; OriginalTransactionNo: Integer)
    var
        AccNo: Code[20];
        AdjAmount: array[4] of Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldVendLedgEntryUnapply(GenJournalLine, DetailedCVLedgEntryBuffer, VendPostingGr, OriginalTransactionNo, IsHandled);
        if IsHandled then
            exit;

        if (DetailedCVLedgEntryBuffer."Amount (LCY)" = 0) and
           (DetailedCVLedgEntryBuffer."VAT Amount (LCY)" = 0) and
           ((AddCurrencyCode = '') or (DetailedCVLedgEntryBuffer."Additional-Currency Amount" = 0))
        then
            exit;

        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetVendDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldVendLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, VendPostingGr, OriginalTransactionNo, true);
        DetailedCVLedgEntryBuffer."Gen. Posting Type" := DetailedCVLedgEntryBuffer."Gen. Posting Type"::Purchase;
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, true);
    end;

    local procedure GetDtldVendLedgEntryAccNo(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean) AccountNo: Code[20]
    var
        Currency: Record Currency;
        GenPostingSetup: Record "General Posting Setup";
        AmountCondition: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDtldVendLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, VendPostingGr, OriginalTransactionNo, Unapply, VATEntry, AccountNo, IsHandled);
        if IsHandled then
            exit;

        AmountCondition := IsDebitAmount(DtldCVLedgEntryBuf, Unapply);
        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                ;
            DtldCVLedgEntryBuf."Entry Type"::Application:
                ;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                begin
                    GetCurrency(Currency, DtldCVLedgEntryBuf."Currency Code");
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount":
                exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                begin
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                exit(VendPostingGr.GetApplRoundingAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                exit(VendPostingGr.GetRoundingAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance":
                case GLSetup."Pmt. Disc. Tolerance Posting" of
                    GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                        exit(VendPostingGr.GetPmtToleranceAccount(AmountCondition));
                    GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                        exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance":
                case GLSetup."Payment Tolerance Posting" of
                    GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                        exit(VendPostingGr.GetPmtToleranceAccount(AmountCondition));
                    GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                        exit(VendPostingGr.GetPmtDiscountAccount(AmountCondition));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                begin
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    case GLSetup."Payment Tolerance Posting" of
                        GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(GenPostingSetup.GetPurchPmtToleranceAccount(AmountCondition));
                        GLSetup."Payment Tolerance Posting"::"Payment Discount Accounts":
                            exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                    end;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                begin
                    GenPostingSetup.Get(DtldCVLedgEntryBuf."Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
                    case GLSetup."Pmt. Disc. Tolerance Posting" of
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts":
                            exit(GenPostingSetup.GetPurchPmtToleranceAccount(AmountCondition));
                        GLSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts":
                            exit(GenPostingSetup.GetPurchPmtDiscountAccount(AmountCondition));
                    end;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
          DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
          DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                if Unapply then
                    PostDtldVendVATAdjustment(GenJnlLine, DtldCVLedgEntryBuf, OriginalTransactionNo);
            else
                DtldCVLedgEntryBuf.FieldError("Entry Type");
        end;
    end;

    local procedure PostDtldEmplLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; EmplPostingGr: Record "Employee Posting Group"; var AdjAmount: array[4] of Decimal)
    var
        AccNo: Code[20];
    begin
        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetEmplDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldEmplLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, EmplPostingGr, 0, false);
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, false);
    end;

    local procedure PostDtldEmplLedgEntryUnapply(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; EmplPostingGr: Record "Employee Posting Group"; OriginalTransactionNo: Integer)
    var
        AccNo: Code[20];
        AdjAmount: array[4] of Decimal;
    begin
        if (DetailedCVLedgEntryBuffer."Amount (LCY)" = 0) and
           ((AddCurrencyCode = '') or (DetailedCVLedgEntryBuffer."Additional-Currency Amount" = 0))
        then
            exit;

        if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" = DetailedCVLedgEntryBuffer."Entry Type"::Application) then
            AccNo := GetEmplDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer)
        else
            AccNo := GetDtldEmplLedgEntryAccNo(GenJournalLine, DetailedCVLedgEntryBuffer, EmplPostingGr, OriginalTransactionNo, true);
        DetailedCVLedgEntryBuffer."Gen. Posting Type" := DetailedCVLedgEntryBuffer."Gen. Posting Type"::Purchase;
        PostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, AdjAmount, true);
    end;

    local procedure GetDtldEmplLedgEntryAccNo(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; EmplPostingGr: Record "Employee Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean) AccountNo: Code[20]
    var
        Currency: Record Currency;
        AmountCondition: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDtldEmplLedgEntryAccNo(GenJnlLine, DtldCVLedgEntryBuf, EmplPostingGr, OriginalTransactionNo, Unapply, AccountNo, IsHandled);
        if IsHandled then
            exit;

        AmountCondition := IsDebitAmount(DtldCVLedgEntryBuf, Unapply);
        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Initial Entry":
                ;
            DtldCVLedgEntryBuf."Entry Type"::Application:
                ;
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                begin
                    GetCurrency(Currency, DtldCVLedgEntryBuf."Currency Code");
                    CheckNonAddCurrCodeOccurred(Currency.Code);
                    exit(Currency.GetGainLossAccount(DtldCVLedgEntryBuf));
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding":
                exit(EmplPostingGr.GetApplRoundingAccount(AmountCondition));
            DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount":
                exit(EmplPostingGr.GetRoundingAccount(AmountCondition));
            else
                DtldCVLedgEntryBuf.FieldError("Entry Type");
        end;
    end;

    local procedure GetCustDtldCVLedgEntryBufferAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
        CustomerPostingGroup.Get(CustLedgerEntry."Customer Posting Group");
        exit(GetCustomerReceivablesAccount(GenJournalLine, CustomerPostingGroup));
    end;

    local procedure GetVendDtldCVLedgEntryBufferAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
        VendorPostingGroup.Get(VendorLedgerEntry."Vendor Posting Group");
        exit(GetVendorPayablesAccount(GenJournalLine, VendorPostingGroup));
    end;

    local procedure GetEmplDtldCVLedgEntryBufferAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Code[20]
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeeLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
        EmployeePostingGroup.Get(EmployeeLedgerEntry."Employee Posting Group");
        exit(GetEmployeePayablesAccount(GenJournalLine, EmployeePostingGroup));
    end;

    /// <summary>
    /// Posts all detailed employee ledger entries that are stored in DtldCVLedgEntryBuf. Creates g/l entry for the total amounts.
    /// </summary>
    /// <remarks>
    /// DtldCVLedgEntryBuf is cleared after the procedure is finished.
    /// </remarks>
    /// <param name="GenJournalLine">Gen. journal line that is being posted.</param>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed employee ledger entries to be inserted and posted.</param>
    /// <param name="EmplPostingGr">Employee posting group to be used for detailed employee ledger entries.</param>
    /// <param name="LedgEntryInserted">Flag if employee ledger entries have already been created in the same transaction.</param>
    /// <returns>True if any detailed employee ledger entries has been created.</returns>
    procedure PostDtldEmplLedgEntries(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; EmplPostingGr: Record "Employee Posting Group"; LedgEntryInserted: Boolean) DtldLedgEntryInserted: Boolean
    var
        TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary;
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        AdjAmount: array[4] of Decimal;
        DtldEmplLedgEntryNoOffset: Integer;
        SaveEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if GenJnlLine."Account Type" <> GenJnlLine."Account Type"::Employee then
            exit;

        if DtldEmplLedgEntry.FindLast() then
            DtldEmplLedgEntryNoOffset := DtldEmplLedgEntry."Entry No."
        else
            DtldEmplLedgEntryNoOffset := 0;

        MultiplePostingGroups := CheckEmplMultiplePostingGroups(DtldCVLedgEntryBuf);

        DtldCVLedgEntryBuf.Reset();
        OnAfterSetDtldEmplLedgEntryNoOffset(DtldCVLedgEntryBuf, DtldEmplLedgEntryNoOffset);
        if DtldCVLedgEntryBuf.FindSet() then begin
            if LedgEntryInserted then begin
                SaveEntryNo := NextEntryNo;
                IncrNextEntryNo();
            end;
            repeat
                InsertDtldEmplLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, DtldEmplLedgEntry, DtldEmplLedgEntryNoOffset);
                IsHandled := false;
                OnPostDtldEmplLedgEntriesOnBeforeUpdateTotalAmounts(GenJnlLine, DtldCVLedgEntryBuf, DtldEmplLedgEntry, IsHandled);
                if not IsHandled then
                    UpdateTotalAmounts(TempDimPostingBuffer, GenJnlLine."Dimension Set ID", DtldCVLedgEntryBuf);
                IsHandled := false;
                OnPostDtldEmplLedgEntriesOnAfterUpdateTotalAmounts(GenJnlLine, DtldCVLedgEntryBuf, DtldEmplLedgEntry);
                if not IsHandled then
                    if (DtldCVLedgEntryBuf."Amount (LCY)" <> 0) or
                       ((AddCurrencyCode <> '') and (DtldCVLedgEntryBuf."Additional-Currency Amount" <> 0))
                    then
                        PostDtldEmplLedgEntry(GenJnlLine, DtldCVLedgEntryBuf, EmplPostingGr, AdjAmount);
            until DtldCVLedgEntryBuf.Next() = 0;
        end;

        IsHandled := false;
        OnPostDtldEmplLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(EmplPostingGr, DtldCVLedgEntryBuf, GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, LedgEntryInserted, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmounts(
              GenJnlLine, TempDimPostingBuffer, AdjAmount, SaveEntryNo, GetEmployeePayablesAccount(GenJnlLine, EmplPostingGr), LedgEntryInserted);

        OnPostDtldEmplLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);

        DtldLedgEntryInserted := not DtldCVLedgEntryBuf.IsEmpty();
        DtldCVLedgEntryBuf.DeleteAll();
    end;

    /// <summary>
    /// Depending on the detailed customer/vendor ledger entry type, creates g/l entry and other entries for the detailed customer/vendor ledger entry.
    /// If general journal line is created not for the unapplication purpose, adjustments can be collected.
    /// </summary>
    /// <param name="GenJournalLine">Gen. journal line that is being posted.</param>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed customer/vendor ledger entry to post.</param>
    /// <param name="AccNo">G/l account to be used for g/l entry.</param>
    /// <param name="AdjAmount">Return value: array for adjustments.</param>
    /// <param name="Unapply">Flag if the posting is for unapplication.</param>
    procedure PostDtldCVLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; AccNo: Code[20]; var AdjAmount: array[4] of Decimal; Unapply: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        EmployeePostingGroup: Record "Employee Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        AccNo2: Code[20];
        AccNo3: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldCVLedgEntry(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, Unapply, AdjAmount, IsHandled, AddCurrencyCode, MultiplePostingGroups);
        if IsHandled then
            exit;

        case DetailedCVLedgEntryBuffer."Entry Type" of
            DetailedCVLedgEntryBuffer."Entry Type"::"Initial Entry":
                ;
            DetailedCVLedgEntryBuffer."Entry Type"::Application:
                if MultiplePostingGroups then
                    CreateGLEntry(
                        GenJournalLine, AccNo, DetailedCVLedgEntryBuffer."Amount (LCY)", 0, DetailedCVLedgEntryBuffer."Currency Code" = AddCurrencyCode,
                        CalcAmountSrcCurr(GenJournalLine, DetailedCVLedgEntryBuffer."Amount (LCY)"));
            DetailedCVLedgEntryBuffer."Entry Type"::"Unrealized Loss",
            DetailedCVLedgEntryBuffer."Entry Type"::"Unrealized Gain",
            DetailedCVLedgEntryBuffer."Entry Type"::"Realized Loss",
            DetailedCVLedgEntryBuffer."Entry Type"::"Realized Gain":
                begin
                    IsHandled := false;
                    OnPostDtldCVLedgEntryOnBeforeCreateGLEntryGainLoss(GenJournalLine, DetailedCVLedgEntryBuffer, Unapply, AccNo, IsHandled, AdjAmount, AddCurrencyCode, MultiplePostingGroups);
                    if not IsHandled then
                        CreateGLEntryGainLoss(GenJournalLine, AccNo, -DetailedCVLedgEntryBuffer."Amount (LCY)", DetailedCVLedgEntryBuffer."Currency Code" = AddCurrencyCode);

                    if MultiplePostingGroups and (DetailedCVLedgEntryBuffer."Entry Type" in [DetailedCVLedgEntryBuffer."Entry Type"::"Unrealized Loss", DetailedCVLedgEntryBuffer."Entry Type"::"Unrealized Gain"]) then begin
                        case GenJournalLine."Account Type" of
                            GenJournalLine."Account Type"::Customer:
                                begin
                                    GetCustomerPostingGroup(GenJournalLine, CustomerPostingGroup);
                                    AccNo2 := GetCustDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer);
                                    AccNo3 := GetCustomerReceivablesAccount(GenJournalLine, CustomerPostingGroup);
                                end;
                            GenJournalLine."Account Type"::Vendor:
                                begin
                                    GetVendorPostingGroup(GenJournalLine, VendorPostingGroup);
                                    AccNo2 := GetVendDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer);
                                    AccNo3 := GetVendorPayablesAccount(GenJournalLine, VendorPostingGroup);
                                end;
                            GenJournalLine."Account Type"::Employee:
                                begin
                                    EmployeePostingGroup.Get(GenJournalLine."Posting Group");
                                    AccNo2 := GetEmplDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer);
                                    AccNo3 := GetEmployeePayablesAccount(GenJournalLine, EmployeePostingGroup);
                                end;
                        end;
                        CreateGLEntryGainLoss(GenJournalLine, AccNo2, DetailedCVLedgEntryBuffer."Amount (LCY)", DetailedCVLedgEntryBuffer."Currency Code" = AddCurrencyCode);
                        CreateGLEntryGainLoss(GenJournalLine, AccNo3, -DetailedCVLedgEntryBuffer."Amount (LCY)", DetailedCVLedgEntryBuffer."Currency Code" = AddCurrencyCode);
                    end;

                    if not Unapply then
                        CollectAdjustment(AdjAmount, -DetailedCVLedgEntryBuffer."Amount (LCY)", 0);
                end;
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount",
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Tolerance",
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount Tolerance":
                begin
                    PostDtldCVLedgEntryCreateGLEntryPmtDiscTol(GenJournalLine, DetailedCVLedgEntryBuffer, AccNo, Unapply);
                    if not Unapply then
                        CollectAdjustment(AdjAmount, -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount");
                end;
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount (VAT Excl.)",
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Tolerance (VAT Excl.)",
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                begin
                    if not Unapply then
                        CreateGLEntryVATCollectAdj(
                          GenJournalLine, AccNo, -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount", -DetailedCVLedgEntryBuffer."VAT Amount (LCY)", DetailedCVLedgEntryBuffer,
                          AdjAmount)
                    else
                        CreateGLEntryVAT(
                          GenJournalLine, AccNo, -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount", -DetailedCVLedgEntryBuffer."VAT Amount (LCY)", DetailedCVLedgEntryBuffer);
                    OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTolVATExcl(DetailedCVLedgEntryBuffer, TempGLEntryBuf);
                end;
            DetailedCVLedgEntryBuffer."Entry Type"::"Appln. Rounding":
                if DetailedCVLedgEntryBuffer."Amount (LCY)" <> 0 then begin
                    CreateGLEntry(
                        GenJournalLine, AccNo, -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount", true,
                        CalcAmountSrcCurr(GenJournalLine, -DetailedCVLedgEntryBuffer."Amount (LCY)"));
                    if not Unapply then
                        CollectAdjustment(AdjAmount, -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount");
                end;
            DetailedCVLedgEntryBuffer."Entry Type"::"Correction of Remaining Amount":
                if DetailedCVLedgEntryBuffer."Amount (LCY)" <> 0 then begin
                    CreateGLEntry(
                        GenJournalLine, AccNo, -DetailedCVLedgEntryBuffer."Amount (LCY)", 0, false,
                        CalcAmountSrcCurr(GenJournalLine, -DetailedCVLedgEntryBuffer."Amount (LCY)"));
                    if not Unapply then
                        CollectAdjustment(AdjAmount, -DetailedCVLedgEntryBuffer."Amount (LCY)", 0);
                end;
            DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount (VAT Adjustment)",
                DetailedCVLedgEntryBuffer."Entry Type"::"Payment Tolerance (VAT Adjustment)",
                DetailedCVLedgEntryBuffer."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                ;
            else
                DetailedCVLedgEntryBuffer.FieldError(DetailedCVLedgEntryBuffer."Entry Type");
        end;

        OnAfterPostDtldCVLedgEntry(
            GenJournalLine, DetailedCVLedgEntryBuffer, Unapply, AccNo,
            AdjAmount, NextEntryNo, AddCurrencyCode, MultiplePostingGroups);
    end;

    local procedure PostDtldCVLedgEntryCreateGLEntryPmtDiscTol(var GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var AccNo: Code[20]; var Unapply: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDtldCVLedgEntryCreateGLEntryPmtDiscTol(GenJnlLine, DtldCVLedgEntryBuf, Unapply, AccNo, IsHandled);
        if IsHandled then
            exit;

        CreateGLEntry(
            GenJnlLine, AccNo, -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
            CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
        OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTol(DtldCVLedgEntryBuf, TempGLEntryBuf);
    end;

    local procedure PostDtldCustVATAdjustment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OriginalTransactionNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        DtldCVLedgEntryBuf.FindVATEntry(VATEntry, OriginalTransactionNo);
        OnPostDtldCustVATAdjustmentOnAfterFindVATEntry(GenJnlLine, DtldCVLedgEntryBuf);

        case VATPostingSetup."VAT Calculation Type" of
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Full VAT":
                begin
                    VATPostingSetup.Get(DtldCVLedgEntryBuf."VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                    CreateGLEntry(
                        GenJnlLine, VATPostingSetup.GetSalesAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                        CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                end;
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                ;
            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                begin
                    DtldCVLedgEntryBuf.TestField("Tax Jurisdiction Code");
                    TaxJurisdiction.Get(DtldCVLedgEntryBuf."Tax Jurisdiction Code");
                    CreateGLEntry(
                        GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                        CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                end;
        end;
        OnAfterPostDtldCustVATAdjustment(GenJnlLine, DtldCVLedgEntryBuf);
    end;

    local procedure PostDtldVendVATAdjustment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OriginalTransactionNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        IsHandled: Boolean;
    begin
        DtldCVLedgEntryBuf.FindVATEntry(VATEntry, OriginalTransactionNo);
        OnPostDtldVendVATAdjustmentOnAfterFindVATEntry(DtldCVLedgEntryBuf, VATEntry);

        case VATPostingSetup."VAT Calculation Type" of
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Full VAT":
                begin
                    VATPostingSetup.Get(DtldCVLedgEntryBuf."VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                    IsHandled := false;
                    OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntryForNormalOrFullVAT(DtldCVLedgEntryBuf, VATEntry, GenJnlLine, IsHandled);
                    if not IsHandled then
                        CreateGLEntry(
                            GenJnlLine, VATPostingSetup.GetPurchAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                            CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                end;
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                begin
                    VATPostingSetup.Get(DtldCVLedgEntryBuf."VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
                    VATPostingSetup.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
                    IsHandled := false;
                    OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntryReverseChargeVATInPostDtldVendVATAdjustment(DtldCVLedgEntryBuf, VATEntry, GenJnlLine, IsHandled);
                    if not IsHandled then begin
                        CreateGLEntry(
                            GenJnlLine, VATPostingSetup.GetPurchAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                            CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                        CreateGLEntry(
                            GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), DtldCVLedgEntryBuf."Amount (LCY)", DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                            CalcAmountSrcCurr(GenJnlLine, DtldCVLedgEntryBuf."Amount (LCY)"));
                    end;
                end;
            VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                begin
                    TaxJurisdiction.Get(DtldCVLedgEntryBuf."Tax Jurisdiction Code");
                    IsHandled := false;
                    OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntrySalesTaxInPostDtldVendVATAdjustment(DtldCVLedgEntryBuf, VATEntry, GenJnlLine, IsHandled);
                    if not isHandled then
                        if DtldCVLedgEntryBuf."Use Tax" then begin
                            CreateGLEntry(
                                GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                                CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                            CreateGLEntry(
                                GenJnlLine, TaxJurisdiction.GetRevChargeAccount(false), DtldCVLedgEntryBuf."Amount (LCY)", DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                                CalcAmountSrcCurr(GenJnlLine, DtldCVLedgEntryBuf."Amount (LCY)"));
                        end else
                            CreateGLEntry(
                                GenJnlLine, TaxJurisdiction.GetPurchAccount(false), -DtldCVLedgEntryBuf."Amount (LCY)", -DtldCVLedgEntryBuf."Additional-Currency Amount", false,
                                CalcAmountSrcCurr(GenJnlLine, -DtldCVLedgEntryBuf."Amount (LCY)"));
                end;
        end;
        OnAfterPostDtldVendVATAdjustment(GenJnlLine, VATPostingSetup, DtldCVLedgEntryBuf, VATEntry);
    end;

    local procedure VendUnrealizedVAT(GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry2: Record "Vendor Ledger Entry"; SettledAmount: Decimal)
    var
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPart: Decimal;
        VATAmount: Decimal;
        VATBase: Decimal;
        VATAmountAddCurr: Decimal;
        VATBaseAddCurr: Decimal;
        PaidAmount: Decimal;
        TotalUnrealVATAmountFirst: Decimal;
        TotalUnrealVATAmountLast: Decimal;
        PurchVATAccount: Code[20];
        PurchVATUnrealAccount: Code[20];
        PurchReverseAccount: Code[20];
        PurchReverseUnrealAccount: Code[20];
        LastConnectionNo: Integer;
        GLEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendUnrealizedVAT(GenJnlLine, VendLedgEntry2, SettledAmount, IsHandled);
        if IsHandled then
            exit;

        VATEntry2.ReadIsolation := IsolationLevel::ReadUncommitted;
        VATEntry2.Reset();
        VATEntry2.SetCurrentKey("Transaction No.");
        VATEntry2.SetRange("Transaction No.", VendLedgEntry2."Transaction No.");

        OnVendUnrealizedVATOnAfterSetFilterForVATEntry2(VATEntry2);

        PaidAmount := -VendLedgEntry2."Amount (LCY)" + VendLedgEntry2."Remaining Amt. (LCY)";
        if VATEntry2.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::Last, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)"]
                then
                    TotalUnrealVATAmountLast := TotalUnrealVATAmountLast - VATEntry2."Remaining Unrealized Amount";
                if VATPostingSetup."Unrealized VAT Type" in
                   [VATPostingSetup."Unrealized VAT Type"::First, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)"]
                then
                    TotalUnrealVATAmountFirst := TotalUnrealVATAmountFirst - VATEntry2."Remaining Unrealized Amount";
            until VATEntry2.Next() = 0;

        OnVendUnrealizedVATOnAfterCalcTotalUnrealVATAmount(VATEntry2, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast);

        if VATEntry2.FindSet() then begin
            LastConnectionNo := 0;
            repeat
                VATPostingSetup.Get(VATEntry2."VAT Bus. Posting Group", VATEntry2."VAT Prod. Posting Group");
                if LastConnectionNo <> VATEntry2."Sales Tax Connection No." then begin
                    InsertSummarizedVAT(GenJnlLine);
                    LastConnectionNo := VATEntry2."Sales Tax Connection No.";
                end;

                IsHandled := false;
                OnVendUnrealizedVATOnBeforeGetUnrealizedVATPart(GenJnlLine, VendLedgEntry2, PaidAmount, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast, SettledAmount, VATEntry2, VATPart, IsHandled);
                if not IsHandled then
                    VATPart :=
                      VATEntry2.GetUnrealizedVATPart(
                        Round(SettledAmount / VendLedgEntry2.GetAdjustedCurrencyFactor()),
                        PaidAmount,
                        VendLedgEntry2."Amount (LCY)",
                        TotalUnrealVATAmountFirst,
                        TotalUnrealVATAmountLast);

                OnVendUnrealizedVATOnAfterVATPartCalculation(
                  GenJnlLine, VendLedgEntry2, PaidAmount, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast, SettledAmount, VATEntry2);

                if VATPart > 0 then begin
                    GetVendUnrealizedVATAccounts(VATEntry2, VATPostingSetup, PurchVATAccount, PurchVATUnrealAccount, PurchReverseAccount, PurchReverseUnrealAccount);

                    if VATPart = 1 then begin
                        VATAmount := VATEntry2."Remaining Unrealized Amount";
                        VATBase := VATEntry2."Remaining Unrealized Base";
                        VATAmountAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Amount";
                        VATBaseAddCurr := VATEntry2."Add.-Curr. Rem. Unreal. Base";
                    end else begin
                        VATAmount := Round(VATEntry2."Remaining Unrealized Amount" * VATPart, GLSetup."Amount Rounding Precision");
                        VATBase := Round(VATEntry2."Remaining Unrealized Base" * VATPart, GLSetup."Amount Rounding Precision");
                        VATAmountAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Amount" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                        VATBaseAddCurr :=
                          Round(
                            VATEntry2."Add.-Curr. Rem. Unreal. Base" * VATPart,
                            AddCurrency."Amount Rounding Precision");
                    end;

                    OnVendUnrealizedVATOnBeforeInitGLEntryVAT(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, VendLedgEntry2, SettledAmount);

                    if (VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Sales Tax") and
                       (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax"
                    then begin
                        InitGLEntryVAT(
                          GenJnlLine, PurchReverseUnrealAccount, PurchReverseAccount, -VATAmount, -VATAmountAddCurr, false);
                        GLEntryNo :=
                          InitGLEntryVATCopy(
                            GenJnlLine, PurchReverseAccount, PurchReverseUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2);
                    end else begin
                        IsHandled := false;
                        OnBeforeInitGLEntryVATOnVendUnrealizedVAT(VATEntry2, GenJnlLine, NextEntryNo, IsHandled);
                        if not IsHandled then begin
                            InitGLEntryVAT(
                              GenJnlLine, PurchVATUnrealAccount, PurchVATAccount, -VATAmount, -VATAmountAddCurr, false);
                            GLEntryNo :=
                              InitGLEntryVATCopy(GenJnlLine, PurchVATAccount, PurchVATUnrealAccount, VATAmount, VATAmountAddCurr, VATEntry2);
                        end;
                    end;

                    IsHandled := false;
                    OnBeforeInitGLEntryVATOnVendUnrealizedVATForRevChargeVAT(VATEntry2, GenJnlLine, NextEntryNo, IsHandled);
                    if not IsHandled then
                        if VATEntry2."VAT Calculation Type" = VATEntry2."VAT Calculation Type"::"Reverse Charge VAT" then begin
                            InitGLEntryVAT(
                                GenJnlLine, PurchReverseUnrealAccount, PurchReverseAccount, VATAmount, VATAmountAddCurr, false);
                            GLEntryNo :=
                                InitGLEntryVATCopy(GenJnlLine, PurchReverseAccount, PurchReverseUnrealAccount, -VATAmount, -VATAmountAddCurr, VATEntry2);
                        end;

                    OnVendUnrealizedVATOnBeforePostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo, VATPart);
                    PostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, VATAmountAddCurr, VATBaseAddCurr, GLEntryNo);
                end;
            until VATEntry2.Next() = 0;

            InsertSummarizedVAT(GenJnlLine);
        end;
    end;

    local procedure GetVendUnrealizedVATAccounts(var VATEntry2: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; var PurchVATAccount: Code[20]; var PurchVATUnrealAccount: Code[20]; var PurchReverseAccount: Code[20]; var PurchReverseUnrealAccount: Code[20])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        case VATEntry2."VAT Calculation Type" of
            VATEntry2."VAT Calculation Type"::"Normal VAT",
            VATEntry2."VAT Calculation Type"::"Full VAT":
                begin
                    PurchVATAccount := VATPostingSetup.GetPurchAccount(false);
                    PurchVATUnrealAccount := VATPostingSetup.GetPurchAccount(true);
                end;
            VATEntry2."VAT Calculation Type"::"Reverse Charge VAT":
                begin
                    PurchVATAccount := VATPostingSetup.GetPurchAccount(false);
                    PurchVATUnrealAccount := VATPostingSetup.GetPurchAccount(true);
                    PurchReverseAccount := VATPostingSetup.GetRevChargeAccount(false);
                    PurchReverseUnrealAccount := VATPostingSetup.GetRevChargeAccount(true);
                end;
            VATEntry2."VAT Calculation Type"::"Sales Tax":
                if (VATEntry2.Type = VATEntry2.Type::Purchase) and VATEntry2."Use Tax" then begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    PurchVATAccount := TaxJurisdiction.GetPurchAccount(false);
                    PurchVATUnrealAccount := TaxJurisdiction.GetPurchAccount(true);
                    PurchReverseAccount := TaxJurisdiction.GetRevChargeAccount(false);
                    PurchReverseUnrealAccount := TaxJurisdiction.GetRevChargeAccount(true);
                end else begin
                    TaxJurisdiction.Get(VATEntry2."Tax Jurisdiction Code");
                    PurchVATAccount := TaxJurisdiction.GetPurchAccount(false);
                    PurchVATUnrealAccount := TaxJurisdiction.GetPurchAccount(true);
                end;
        end;

        OnAfterGetVendUnrealizedVATAccounts(VATEntry2, VATPostingSetup, PurchVATAccount, PurchVATUnrealAccount, PurchReverseAccount, PurchReverseUnrealAccount);
    end;

    procedure PostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal; VATAmountAddCurr: Decimal; VATBaseAddCurr: Decimal; GLEntryNo: Integer)
    begin
        OnBeforePostUnrealVATEntry(GenJnlLine, VATEntry);
        VATEntry.LockTable();
        VATEntry := VATEntry2;
        VATEntry."Entry No." := NextVATEntryNo;
        VATEntry.CopyPostingDataFromGenJnlLine(GenJnlLine);
        VATEntry.SetVATDateFromGenJnlLine(GenJnlLine);
        VATEntry.Amount := VATAmount;
        VATEntry.Base := VATBase;
        VATEntry."Additional-Currency Amount" := VATAmountAddCurr;
        VATEntry."Additional-Currency Base" := VATBaseAddCurr;
        VATEntry.SetUnrealAmountsToZero();
        VATEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(VATEntry."User ID"));
        VATEntry."Closed by Entry No." := 0;
        VATEntry.Closed := false;
        VATEntry."Transaction No." := NextTransactionNo;
        VATEntry."Sales Tax Connection No." := NextConnectionNo;
        VATEntry."Unrealized VAT Entry No." := VATEntry2."Entry No.";
        VATEntry."Base Before Pmt. Disc." := VATEntry.Base;
        VATEntry."G/L Acc. No." := '';
        OnBeforeInsertPostUnrealVATEntry(VATEntry, GenJnlLine, VATEntry2);
        VATEntry.Insert(true);
        OnPostUnrealVATEntryOnBeforeInsertLinkSelf(TempGLEntryVATEntryLink, VATEntry, GLEntryNo, NextVATEntryNo);
        TempGLEntryVATEntryLink.InsertLinkSelf(GLEntryNo + 1, NextVATEntryNo);
        NextVATEntryNo := NextVATEntryNo + 1;

        VATEntry2."Remaining Unrealized Amount" :=
          VATEntry2."Remaining Unrealized Amount" - VATEntry.Amount;
        VATEntry2."Remaining Unrealized Base" :=
          VATEntry2."Remaining Unrealized Base" - VATEntry.Base;
        VATEntry2."Add.-Curr. Rem. Unreal. Amount" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Amount" - VATEntry."Additional-Currency Amount";
        VATEntry2."Add.-Curr. Rem. Unreal. Base" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Base" - VATEntry."Additional-Currency Base";
        VATEntry2.Modify();
        OnAfterPostUnrealVATEntry(GenJnlLine, VATEntry2, VATAmount, VATBase, GLEntryNo, NextEntryNo, NextVATEntryNo);
    end;

    /// <summary>
    /// Posts application entry to and applies it to the already existing customer/vendor/employee ledger entry.
    /// In the process g/l entries and detailed entries are created, existing customer/vendor/employee ledger entries are updated.
    /// </summary>
    /// <param name="GenJnlLine">Gen. journal line that is being posted.</param>
    /// <param name="DtldCVLedgEntryBuf">Detailed ledger entries that has to be created to perform the application.</param>
    /// <param name="OldCVLedgEntryBuf">Customer/vendor/employee ledger entrie that the application is made to.</param>
    /// <param name="NewCVLedgEntryBuf">New customer/vendor/employee ledger entry that might have been adjusted through events.</param>
    /// <param name="NewCVLedgEntryBuf2">Original new customer/vendor/employee ledger entry.</param>
    /// <param name="BlockPaymentTolerance">Flag is payment tolerance should be checked.</param>
    /// <param name="AllApplied">Flag that determines if more applications can be made.</param>
    /// <param name="AppliedAmount">Amount that should be used for the application.</param>
    /// <param name="PmtTolAmtToBeApplied">Payment tolerance amount to be applied.</param>
    procedure PostApply(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; BlockPaymentTolerance: Boolean; AllApplied: Boolean; var AppliedAmount: Decimal; var PmtTolAmtToBeApplied: Decimal)
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf3: Record "CV Ledger Entry Buffer";
        OldRemainingAmtBeforeAppln: Decimal;
        ApplnRoundingPrecision: Decimal;
        AppliedAmountLCY: Decimal;
        OldAppliedAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforePostApply(GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2);

        OldRemainingAmtBeforeAppln := OldCVLedgEntryBuf."Remaining Amount";
        OldCVLedgEntryBuf3 := OldCVLedgEntryBuf;

        // Management of posting in multiple currencies
        OldCVLedgEntryBuf2 := OldCVLedgEntryBuf;
        OldCVLedgEntryBuf.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        ApplnRoundingPrecision := GetApplnRoundPrecision(NewCVLedgEntryBuf, OldCVLedgEntryBuf);

        OldCVLedgEntryBuf2.RecalculateAmounts(
          OldCVLedgEntryBuf2."Currency Code", NewCVLedgEntryBuf."Currency Code", NewCVLedgEntryBuf."Posting Date");

        OnPostApplyOnAfterRecalculateAmounts(
            OldCVLedgEntryBuf2, OldCVLedgEntryBuf, NewCVLedgEntryBuf, GenJnlLine, DtldCVLedgEntryBuf, AddCurrencyCode, NextTransactionNo, NextVATEntryNo);

        if not BlockPaymentTolerance then
            CalcPmtTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              PmtTolAmtToBeApplied, NextTransactionNo, FirstNewVATEntryNo);

        CalcPmtDisc(
          NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
          PmtTolAmtToBeApplied, ApplnRoundingPrecision, NextTransactionNo, FirstNewVATEntryNo);

        if not BlockPaymentTolerance then
            CalcPmtDiscTolerance(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine,
              NextTransactionNo, FirstNewVATEntryNo);

        IsHandled := false;
        OnBeforeCalcCurrencyApplnRounding(
          GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, OldCVLedgEntryBuf3,
          NewCVLedgEntryBuf, NewCVLedgEntryBuf2, IsHandled);
        if not IsHandled then
            CalcCurrencyApplnRounding(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, GenJnlLine, ApplnRoundingPrecision);

        IsHandled := false;
        OnPostApplyOnAfterCalcCurrencyApplnRounding(GenJnlLine, NewCVLedgEntryBuf, NewCVLedgEntryBuf2, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, DtldCVLedgEntryBuf, AppliedAmount, PmtTolAmtToBeApplied, IsHandled);
        if not IsHandled then begin
            FindAmtForAppln(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2,
              AppliedAmount, AppliedAmountLCY, OldAppliedAmount, ApplnRoundingPrecision, GenJnlLine);

            OnPostApplyOnAfterFindAmtForApplnOnBeforeCalcCurrencyUnrealizedGainLoss(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, AppliedAmount,
              AppliedAmountLCY, OldAppliedAmount, AmountRoundingPrecision, VATEntry);

            CalcCurrencyUnrealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, OldRemainingAmtBeforeAppln);

            CalcCurrencyRealizedGainLoss(
              NewCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, AppliedAmount, AppliedAmountLCY);

            CalcCurrencyRealizedGainLoss(
              OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine, -OldAppliedAmount, -AppliedAmountLCY);

            CalcApplication(
              NewCVLedgEntryBuf, OldCVLedgEntryBuf, DtldCVLedgEntryBuf,
              GenJnlLine, AppliedAmount, AppliedAmountLCY, OldAppliedAmount,
              NewCVLedgEntryBuf2, OldCVLedgEntryBuf3, AllApplied);

            PaymentToleranceMgt.CalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, GLSetup);

            CalcAmtLCYAdjustment(OldCVLedgEntryBuf, DtldCVLedgEntryBuf, GenJnlLine);
        end;

        OnAfterPostApply(GenJnlLine, DtldCVLedgEntryBuf, OldCVLedgEntryBuf, NewCVLedgEntryBuf, NewCVLedgEntryBuf2);
    end;

    /// <summary>
    /// Creates and posts un-applying entry for currently applied detailed customer ledger entry.
    /// G/l entry with unapplied amount is created as part of the process
    /// Related customer ledger entry is being updated as part of the process
    /// Unrealized vat is posted
    /// </summary>
    /// <remarks>
    /// Customer, detailed customer ledger and vat entries are being locked
    /// </remarks>
    /// <param name="GenJournalLine">Gen. journal line being posted.</param>
    /// <param name="DetailedCustLedgEntry">Detailed ledger entry that is currently applied</param>
    procedure UnapplyCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLineToPost: Record "Gen. Journal Line";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        VATEntry: Record "VAT Entry";
        TempVATEntry2: Record "VAT Entry" temporary;
        CurrencyLCY: Record Currency;
        TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary;
        AdjAmount: array[4] of Decimal;
        NextDtldLedgEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        PmtDiscTolExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnapplyCustLedgEntry(GenJournalLine, DetailedCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        GenJournalLineToPost.TransferFields(GenJournalLine);
        if GenJournalLineToPost."Document Date" = 0D then
            GenJournalLineToPost."Document Date" := GenJournalLineToPost."Posting Date";

        AmountRoundingPrecision := GetSourceCurrency(GenJournalLine."Source Currency Code");

        if NextEntryNo = 0 then
            StartPosting(GenJournalLineToPost)
        else
            ContinuePosting(GenJournalLineToPost);

        ReadGLSetup(GLSetup);

        Customer.Get(DetailedCustLedgEntry."Customer No.");
        Customer.CheckBlockedCustOnJnls(Customer, GenJournalLine."Document Type"::Payment, true);

        OnUnapplyCustLedgEntryOnBeforeCheckPostingGroup(GenJournalLineToPost, Customer);
        CustomerPostingGroup.Get(GenJournalLineToPost."Posting Group");
        GetCustomerReceivablesAccount(GenJournalLineToPost, CustomerPostingGroup);

        VATEntry.LockTable();
        DetailedCustLedgEntry.LockTable();
        CustLedgerEntry.LockTable();

        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);

        DetailedCustLedgEntry2.Reset();
        DetailedCustLedgEntry2.FindLast();
        NextDtldLedgEntryNo := DetailedCustLedgEntry2."Entry No." + 1;
        OnUnapplyCustLedgEntryOnAfterGetNextDtldLedgEntryNo(GenJournalLine);

        if DetailedCustLedgEntry."Transaction No." = 0 then begin
            DetailedCustLedgEntry2.SetCurrentKey("Application No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry2.SetRange("Application No.", DetailedCustLedgEntry."Application No.");
        end else begin
            DetailedCustLedgEntry2.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry2.SetRange("Transaction No.", DetailedCustLedgEntry."Transaction No.");
        end;
        DetailedCustLedgEntry2.SetRange("Customer No.", DetailedCustLedgEntry."Customer No.");
        MultiplePostingGroups := CheckDetCustLedgEntryMultiplePostingGrOnBeforeUnapply(DetailedCustLedgEntry2, DetailedCustLedgEntry);
        DetailedCustLedgEntry2.SetFilter("Entry Type", '>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        OnUnapplyCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(DetailedCustLedgEntry2, DetailedCustLedgEntry);
        if DetailedCustLedgEntry."Transaction No." <> 0 then begin
            UnapplyVATEntries := false;
            DetailedCustLedgEntry2.FindSet();
            repeat
                DetailedCustLedgEntry2.TestField(Unapplied, false);
                if IsVATAdjustment(DetailedCustLedgEntry2."Entry Type") then
                    UnapplyVATEntries := true;
                if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." then
                    if IsVATExcluded(DetailedCustLedgEntry2."Entry Type") then
                        UnapplyVATEntries := true;
                if DetailedCustLedgEntry2."Entry Type" = DetailedCustLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)" then
                    PmtDiscTolExists := true;
            until DetailedCustLedgEntry2.Next() = 0;

            OnUnapplyCustLedgEntryOnBeforePostUnapply(DetailedCustLedgEntry, DetailedCustLedgEntry2);

            PostUnapply(
              GenJournalLineToPost, VATEntry, VATEntry.Type::Sale,
              DetailedCustLedgEntry."Customer No.", DetailedCustLedgEntry."Transaction No.", UnapplyVATEntries, TempVATEntry);

            OnUnapplyCustLedgEntryOnAfterPostUnapply(GenJournalLineToPost, DetailedCustLedgEntry, DetailedCustLedgEntry2);

            if PmtDiscTolExists then
                ProcessTempVATEntryCust(DetailedCustLedgEntry2, TempVATEntry)
            else begin
                DetailedCustLedgEntry2.SetRange("Entry Type", DetailedCustLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)");
                ProcessTempVATEntryCust(DetailedCustLedgEntry2, TempVATEntry);
                DetailedCustLedgEntry2.SetRange("Entry Type", DetailedCustLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)");
                ProcessTempVATEntryCust(DetailedCustLedgEntry2, TempVATEntry);
                DetailedCustLedgEntry2.SetFilter("Entry Type", '>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
            end;
        end;

        // Look one more time
        if DetailedCustLedgEntry."Transaction No." = 0 then
            DetailedCustLedgEntry2.SetCurrentKey("Application No.", "Customer No.", "Entry Type")
        else
            DetailedCustLedgEntry2.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");

        OnOnUnapplyCustLedgEntryOnBeforeSecondLook(DetailedCustLedgEntry2, NextDtldLedgEntryNo);
        DetailedCustLedgEntry2.FindSet();
        TempDimensionPostingBuffer.DeleteAll();
        repeat
            IsHandled := false;
            OnOnUnapplyCustLedgEntryOnBeforeProcessDetailedCustLedgEntry2InLoop(DetailedCustLedgEntry2, IsHandled);
            if not IsHandled then begin
                CheckDetailedCustLedgEntryUnapply(DetailedCustLedgEntry2);
                InsertDtldCustLedgEntryUnapply(
                    GenJournalLineToPost, NewDetailedCustLedgEntry, DetailedCustLedgEntry2, NextDtldLedgEntryNo, CustomerPostingGroup);

                DetailedCVLedgEntryBuffer.Init();
                DetailedCVLedgEntryBuffer.TransferFields(NewDetailedCustLedgEntry);
                OnUnapplyCustLedgEntryOnAfterFillDtldCVLedgEntryBuf(GenJournalLineToPost, DetailedCVLedgEntryBuffer);
                if CustomerPostingGroup.Code <> DetailedCustLedgEntry2."Posting Group" then
                    CustomerPostingGroup.Get(DetailedCustLedgEntry2."Posting Group");
                SetAddCurrForUnapplication(DetailedCVLedgEntryBuffer);
                CurrencyLCY.InitRoundingPrecision();

                if (DetailedCustLedgEntry2."Transaction No." <> 0) and IsVATExcluded(DetailedCustLedgEntry2."Entry Type") then begin
                    UnapplyExcludedVAT(
                      TempVATEntry2, DetailedCustLedgEntry2."Transaction No.", DetailedCustLedgEntry2."VAT Bus. Posting Group",
                      DetailedCustLedgEntry2."VAT Prod. Posting Group", DetailedCustLedgEntry2."Gen. Prod. Posting Group");
                    DetailedCVLedgEntryBuffer."VAT Amount (LCY)" :=
                      CalcVATAmountFromVATEntry(DetailedCVLedgEntryBuffer."Amount (LCY)", TempVATEntry2, CurrencyLCY);
                end;
                IsHandled := false;
                OnOnUnapplyCustLedgEntryOnBeforeUpdateTotalAmounts(IsHandled, GenJournalLineToPost, DetailedCVLedgEntryBuffer);
                if not IsHandled then begin
                    UpdateTotalAmounts(TempDimensionPostingBuffer, GenJournalLineToPost."Dimension Set ID", DetailedCVLedgEntryBuffer);
                    OnUnapplyCustLedgEntryOnAfterUpdateTotals(GenJournalLineToPost, DetailedCVLedgEntryBuffer);

                    if not (DetailedCVLedgEntryBuffer."Entry Type" in [
                                                                DetailedCVLedgEntryBuffer."Entry Type"::"Initial Entry",
                                                                DetailedCVLedgEntryBuffer."Entry Type"::Application])
                    then
                        CollectAdjustment(AdjAmount,
                          -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount");
                end;

                PostDtldCustLedgEntryUnapply(
                  GenJournalLineToPost, DetailedCVLedgEntryBuffer, CustomerPostingGroup, DetailedCustLedgEntry2."Transaction No.");

                OnUnapplyCustLedgEntryOnBeforeUpdateDetailedCustLedgEntry(DetailedCustLedgEntry2, DetailedCVLedgEntryBuffer);

                DetailedCustLedgEntry2.Unapplied := true;
                DetailedCustLedgEntry2."Unapplied by Entry No." := NewDetailedCustLedgEntry."Entry No.";
                DetailedCustLedgEntry2.Modify();

                OnUnapplyCustLedgEntryOnBeforeUpdateCustLedgEntry(DetailedCustLedgEntry2, DetailedCVLedgEntryBuffer);
                UpdateCustLedgEntry(DetailedCustLedgEntry2);
                OnUnapplyCustLedgEntryOnAfterUpdateCustLedgEntry(GenJournalLine, DetailedCustLedgEntry2, NewDetailedCustLedgEntry, CustomerPostingGroup, GlobalGLEntry);
            end;
        until DetailedCustLedgEntry2.Next() = 0;

        IsHandled := false;
        OnBeforeCreateGLEntriesForTotalAmountsUnapplyV19(DetailedCustLedgEntry, CustomerPostingGroup, GenJournalLineToPost, TempDimensionPostingBuffer, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmountsUnapply(
                GenJournalLineToPost, TempDimensionPostingBuffer, GetCustomerReceivablesAccount(GenJournalLineToPost, CustomerPostingGroup));

        OnUnapplyCustLedgEntryOnAfterCreateGLEntriesForTotalAmounts(GenJournalLine, DetailedCustLedgEntry, GLReg);

        if IsTempGLEntryBufEmpty() then
            DetailedCustLedgEntry.SetZeroTransNo(NextTransactionNo);
        CheckPostUnrealizedVAT(GenJournalLineToPost, true);

        OnUnapplyCustLedgEntryOnBeforeFinishPosting(GenJournalLine, GlobalGLEntry, CustomerPostingGroup);
        FinishPosting(GenJournalLineToPost);
    end;

    local procedure CheckDetailedCustLedgEntryUnapply(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        DetailedCustLedgEntry.TestField(Unapplied, false);

        if DetailedCustLedgEntry."Posting Group" = '' then begin
            CustLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
            CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
            DetailedCustLedgEntry."Posting Group" := CustLedgerEntry."Customer Posting Group";
            DetailedCustLedgEntry.Modify();
        end;
    end;

    /// <summary>
    /// Creates and posts un-applying entry for currently applied detailed vendor ledger entry.
    /// G/l entry with unapplied amount is created as part of the process
    /// Related vendor ledger entry is being updated as part of the process
    /// Unrealized vat is posted
    /// </summary>
    /// <remarks>
    /// Vendor, detailed vendor ledger and vat entries are being locked
    /// </remarks>
    /// <param name="GenJournalLine">Gen. journal line being posted.</param>
    /// <param name="DetailedVendorLedgEntry">Detailed ledger entry that is currently applied</param>
    procedure UnapplyVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GenJournalLineToPost: Record "Gen. Journal Line";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        VATEntry: Record "VAT Entry";
        TempVATEntry2: Record "VAT Entry" temporary;
        CurrencyLCY: Record Currency;
        TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary;
        AdjAmount: array[4] of Decimal;
        NextDtldLedgEntryNo: Integer;
        UnapplyVATEntries: Boolean;
        PmtDiscTolExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnapplyVendLedgEntry(GenJournalLine, DetailedVendorLedgEntry, IsHandled);
        if IsHandled then
            exit;

        GenJournalLineToPost.TransferFields(GenJournalLine);
        if GenJournalLineToPost."Document Date" = 0D then
            GenJournalLineToPost."Document Date" := GenJournalLineToPost."Posting Date";

        AmountRoundingPrecision := GetSourceCurrency(GenJournalLine."Source Currency Code");

        if NextEntryNo = 0 then
            StartPosting(GenJournalLineToPost)
        else
            ContinuePosting(GenJournalLineToPost);

        ReadGLSetup(GLSetup);

        Vendor.Get(DetailedVendorLedgEntry."Vendor No.");
        Vendor.CheckBlockedVendOnJnls(Vendor, GenJournalLine."Document Type"::Payment, true);

        OnUnapplyVendLedgEntryOnBeforeCheckPostingGroup(GenJournalLineToPost, Vendor);
        GetVendorPostingGroup(GenJournalLineToPost, VendorPostingGroup);
        VendorPostingGroup.GetPayablesAccount();

        VATEntry.LockTable();
        DetailedVendorLedgEntry.LockTable();
        VendorLedgerEntry.LockTable();

        DetailedVendorLedgEntry.TestField("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);

        DetailedVendorLedgEntry2.Reset();
        DetailedVendorLedgEntry2.FindLast();
        NextDtldLedgEntryNo := DetailedVendorLedgEntry2."Entry No." + 1;
        if DetailedVendorLedgEntry."Transaction No." = 0 then begin
            DetailedVendorLedgEntry2.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DetailedVendorLedgEntry2.SetRange("Application No.", DetailedVendorLedgEntry."Application No.");
        end else begin
            DetailedVendorLedgEntry2.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DetailedVendorLedgEntry2.SetRange("Transaction No.", DetailedVendorLedgEntry."Transaction No.");
        end;
        DetailedVendorLedgEntry2.SetRange("Vendor No.", DetailedVendorLedgEntry."Vendor No.");
        MultiplePostingGroups := CheckDetVendLedgEntryMultiplePostingGrOnBeforeUnapply(DetailedVendorLedgEntry2, DetailedVendorLedgEntry);
        DetailedVendorLedgEntry2.SetFilter("Entry Type", '>%1', DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        OnUnapplyVendLedgEntryOnAfterFilterSourceEntries(DetailedVendorLedgEntry, DetailedVendorLedgEntry2);
        if DetailedVendorLedgEntry."Transaction No." <> 0 then begin
            UnapplyVATEntries := false;
            DetailedVendorLedgEntry2.FindSet();
            repeat
                DetailedVendorLedgEntry2.TestField(Unapplied, false);
                if IsVATAdjustment(DetailedVendorLedgEntry2."Entry Type") then
                    UnapplyVATEntries := true;
                if not GLSetup."Pmt. Disc. Excl. VAT" and GLSetup."Adjust for Payment Disc." then
                    if IsVATExcluded(DetailedVendorLedgEntry2."Entry Type") then
                        UnapplyVATEntries := true;
                if DetailedVendorLedgEntry2."Entry Type" = DetailedVendorLedgEntry2."Entry Type"::"Payment Discount Tolerance (VAT Excl.)" then
                    PmtDiscTolExists := true;
            until DetailedVendorLedgEntry2.Next() = 0;

            OnUnapplyVendLedgEntryOnBeforePostUnapply(DetailedVendorLedgEntry, DetailedVendorLedgEntry2);

            PostUnapply(
              GenJournalLineToPost, VATEntry, VATEntry.Type::Purchase,
              DetailedVendorLedgEntry."Vendor No.", DetailedVendorLedgEntry."Transaction No.", UnapplyVATEntries, TempVATEntry);

            OnUnapplyVendLedgEntryOnAfterPostUnapply(GenJournalLineToPost, DetailedVendorLedgEntry, DetailedVendorLedgEntry2);

            if PmtDiscTolExists then
                ProcessTempVATEntryVend(DetailedVendorLedgEntry2, TempVATEntry)
            else begin
                DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::"Payment Tolerance (VAT Excl.)");
                ProcessTempVATEntryVend(DetailedVendorLedgEntry2, TempVATEntry);
                DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::"Payment Discount (VAT Excl.)");
                ProcessTempVATEntryVend(DetailedVendorLedgEntry2, TempVATEntry);
                DetailedVendorLedgEntry2.SetFilter("Entry Type", '>%1', DetailedVendorLedgEntry2."Entry Type"::"Initial Entry");
            end;
        end;

        // Look one more time
        OnUnapplyVendLedgEntryOnBeforeSecondLook(DetailedVendorLedgEntry2, NextDtldLedgEntryNo);
        DetailedVendorLedgEntry2.FindSet();
        TempDimensionPostingBuffer.DeleteAll();
        repeat
            CheckDetailedVendLedgEntryUnapply(DetailedVendorLedgEntry2);
            InsertDtldVendLedgEntryUnapply(GenJournalLineToPost, NewDetailedVendorLedgEntry, DetailedVendorLedgEntry2, NextDtldLedgEntryNo);

            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(NewDetailedVendorLedgEntry);
            OnUnapplyVendLedgEntryOnAfterFillDtldCVLedgEntryBuf(GenJournalLineToPost, DetailedCVLedgEntryBuffer);
            if VendorPostingGroup.Code <> DetailedVendorLedgEntry2."Posting Group" then
                VendorPostingGroup.Get(DetailedVendorLedgEntry2."Posting Group");
            SetAddCurrForUnapplication(DetailedCVLedgEntryBuffer);
            CurrencyLCY.InitRoundingPrecision();

            if (DetailedVendorLedgEntry2."Transaction No." <> 0) and IsVATExcluded(DetailedVendorLedgEntry2."Entry Type") then begin
                UnapplyExcludedVAT(
                  TempVATEntry2, DetailedVendorLedgEntry2."Transaction No.", DetailedVendorLedgEntry2."VAT Bus. Posting Group",
                  DetailedVendorLedgEntry2."VAT Prod. Posting Group", DetailedVendorLedgEntry2."Gen. Prod. Posting Group");
                DetailedCVLedgEntryBuffer."VAT Amount (LCY)" :=
                  CalcVATAmountFromVATEntry(DetailedCVLedgEntryBuffer."Amount (LCY)", TempVATEntry2, CurrencyLCY);
            end;
            IsHandled := false;
            OnUnapplyVendLedgEntryOnBeforeUpdateTotalAmounts(IsHandled, GenJournalLineToPost, DetailedCVLedgEntryBuffer);
            if not IsHandled then begin
                UpdateTotalAmounts(TempDimensionPostingBuffer, GenJournalLineToPost."Dimension Set ID", DetailedCVLedgEntryBuffer);

                if not (DetailedCVLedgEntryBuffer."Entry Type" in [
                                                            DetailedCVLedgEntryBuffer."Entry Type"::"Initial Entry",
                                                            DetailedCVLedgEntryBuffer."Entry Type"::Application])
                then
                    CollectAdjustment(AdjAmount,
                      -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount");
            end;

            PostDtldVendLedgEntryUnapply(
              GenJournalLineToPost, DetailedCVLedgEntryBuffer, VendorPostingGroup, DetailedVendorLedgEntry2."Transaction No.");

            OnUnapplyVendLedgEntryOnBeforeUpdateDetailedVendLedgEntry2(DetailedVendorLedgEntry2, DetailedCVLedgEntryBuffer);

            DetailedVendorLedgEntry2.Unapplied := true;
            DetailedVendorLedgEntry2."Unapplied by Entry No." := NewDetailedVendorLedgEntry."Entry No.";
            DetailedVendorLedgEntry2.Modify();

            OnUnapplyVendLedgEntryOnBeforeUpdateVendLedgEntry(DetailedVendorLedgEntry2, DetailedCVLedgEntryBuffer);
            UpdateVendLedgEntry(DetailedVendorLedgEntry2);
        until DetailedVendorLedgEntry2.Next() = 0;

        IsHandled := false;
        OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendorV19(DetailedVendorLedgEntry, VendorPostingGroup, GenJournalLineToPost, TempDimensionPostingBuffer, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmountsUnapply(GenJournalLineToPost, TempDimensionPostingBuffer, GetVendorPayablesAccount(GenJournalLineToPost, VendorPostingGroup));

        OnUnapplyVendLedgEntryOnAfterCreateGLEntriesForTotalAmounts(GenJournalLine, DetailedVendorLedgEntry, GLReg);

        if IsTempGLEntryBufEmpty() then
            DetailedVendorLedgEntry.SetZeroTransNo(NextTransactionNo);
        CheckPostUnrealizedVAT(GenJournalLineToPost, true);

        FinishPosting(GenJournalLineToPost);

        OnAfterUnapplyVendLedgEntry(GenJournalLine, DetailedVendorLedgEntry);
    end;

    local procedure CheckDetailedVendLedgEntryUnapply(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        DetailedVendorLedgEntry.TestField(Unapplied, false);

        if DetailedVendorLedgEntry."Posting Group" = '' then begin
            VendorLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
            VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
            DetailedVendorLedgEntry."Posting Group" := VendorLedgerEntry."Vendor Posting Group";
            DetailedVendorLedgEntry.Modify();
        end;
    end;

    /// <summary>
    /// Creates and posts un-applying entry for currently applied detailed employee ledger entry.
    /// G/l entry with unapplied amount is created as part of the process
    /// Related employee ledger entry is being updated as part of the process
    /// </summary>
    /// <remarks>
    /// Employee and detailed employee ledger entries are being locked
    /// </remarks>
    /// <param name="GenJournalLine">Gen. journal line being posted.</param>
    /// <param name="DetailedEmployeeLedgerEntry">Detailed Employee Ledger Entry that is currently applied</param>
    procedure UnapplyEmplLedgEntry(GenJournalLine: Record "Gen. Journal Line"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        GenJournalLineToPost: Record "Gen. Journal Line";
        DetailedEmployeeLedgerEntry2: Record "Detailed Employee Ledger Entry";
        NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        CurrencyLCY: Record Currency;
        TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary;
        AdjAmount: array[4] of Decimal;
        NextDtldLedgEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnapplyEmplLedgEntry(GenJournalLine, DetailedEmployeeLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        GenJournalLineToPost.TransferFields(GenJournalLine);
        if GenJournalLineToPost."Document Date" = 0D then
            GenJournalLineToPost."Document Date" := GenJournalLineToPost."Posting Date";

        AmountRoundingPrecision := GetSourceCurrency(GenJournalLine."Source Currency Code");

        if NextEntryNo = 0 then
            StartPosting(GenJournalLineToPost)
        else
            ContinuePosting(GenJournalLineToPost);

        ReadGLSetup(GLSetup);

        Employee.Get(DetailedEmployeeLedgerEntry."Employee No.");
        Employee.CheckBlockedEmployeeOnJnls(true);
        EmployeePostingGroup.Get(GenJournalLineToPost."Posting Group");
        EmployeePostingGroup.GetPayablesAccount();

        DetailedEmployeeLedgerEntry.LockTable();
        EmployeeLedgerEntry.LockTable();

        DetailedEmployeeLedgerEntry.TestField("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::Application);

        DetailedEmployeeLedgerEntry2.Reset();
        DetailedEmployeeLedgerEntry2.FindLast();
        NextDtldLedgEntryNo := DetailedEmployeeLedgerEntry2."Entry No." + 1;
        if DetailedEmployeeLedgerEntry."Transaction No." = 0 then begin
            DetailedEmployeeLedgerEntry2.SetCurrentKey("Application No.", "Employee No.", "Entry Type");
            DetailedEmployeeLedgerEntry2.SetRange("Application No.", DetailedEmployeeLedgerEntry."Application No.");
        end else begin
            DetailedEmployeeLedgerEntry2.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
            DetailedEmployeeLedgerEntry2.SetRange("Transaction No.", DetailedEmployeeLedgerEntry."Transaction No.");
        end;
        DetailedEmployeeLedgerEntry2.SetRange("Employee No.", DetailedEmployeeLedgerEntry."Employee No.");
        MultiplePostingGroups := CheckDetEmplLedgEntryMultiplePostingGrOnBeforeUnapply(DetailedEmployeeLedgerEntry2, DetailedEmployeeLedgerEntry);
        DetailedEmployeeLedgerEntry2.SetFilter("Entry Type", '>%1', DetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry");

        OnUnapplyEmplLedgEntryOnAfterFilterSourceEntries(DetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry2);
        // Look one more time
        DetailedEmployeeLedgerEntry2.FindSet();
        TempDimensionPostingBuffer.DeleteAll();
        repeat
            DetailedEmployeeLedgerEntry.TestField(Unapplied, false);
            UpdateEmployeePostingGroup(DetailedEmployeeLedgerEntry2);
            InsertDtldEmplLedgEntryUnapply(GenJournalLineToPost, NewDetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry2, NextDtldLedgEntryNo);

            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(NewDetailedEmployeeLedgerEntry);
            if EmployeePostingGroup.Code <> DetailedEmployeeLedgerEntry2."Posting Group" then
                EmployeePostingGroup.Get(DetailedEmployeeLedgerEntry2."Posting Group");
            SetAddCurrForUnapplication(DetailedCVLedgEntryBuffer);
            CurrencyLCY.InitRoundingPrecision();
            IsHandled := false;
            OnUnapplyEmplLedgEntryOnBeforeUpdateTotalAmounts(GenJournalLineToPost, DetailedCVLedgEntryBuffer, IsHandled);
            if not IsHandled then begin
                UpdateTotalAmounts(TempDimensionPostingBuffer, GenJournalLineToPost."Dimension Set ID", DetailedCVLedgEntryBuffer);

                if not (DetailedCVLedgEntryBuffer."Entry Type" in [
                                                            DetailedCVLedgEntryBuffer."Entry Type"::"Initial Entry",
                                                            DetailedCVLedgEntryBuffer."Entry Type"::Application])
                then
                    CollectAdjustment(AdjAmount,
                      -DetailedCVLedgEntryBuffer."Amount (LCY)", -DetailedCVLedgEntryBuffer."Additional-Currency Amount");
            end;

            PostDtldEmplLedgEntryUnapply(
                GenJournalLineToPost, DetailedCVLedgEntryBuffer, EmployeePostingGroup, DetailedEmployeeLedgerEntry2."Transaction No.");

            DetailedEmployeeLedgerEntry2.Unapplied := true;
            DetailedEmployeeLedgerEntry2."Unapplied by Entry No." := NewDetailedEmployeeLedgerEntry."Entry No.";
            DetailedEmployeeLedgerEntry2.Modify();

            UpdateEmplLedgEntry(DetailedEmployeeLedgerEntry2);
        until DetailedEmployeeLedgerEntry2.Next() = 0;

        IsHandled := false;
        OnBeforeCreateGLEntriesForTotalAmountsUnapplyEmployee(DetailedEmployeeLedgerEntry, EmployeePostingGroup, GenJournalLineToPost, TempDimensionPostingBuffer, IsHandled);
        if not IsHandled then
            CreateGLEntriesForTotalAmountsUnapply(GenJournalLineToPost, TempDimensionPostingBuffer, GetEmployeePayablesAccount(GenJournalLineToPost, EmployeePostingGroup));

        if IsTempGLEntryBufEmpty() then
            DetailedEmployeeLedgerEntry.SetZeroTransNo(NextTransactionNo);

        FinishPosting(GenJournalLineToPost);

        OnAfterUnapplyEmplLedgEntry(GenJournalLine, DetailedEmployeeLedgerEntry);
    end;

    local procedure UpdateEmployeePostingGroup(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        if DetailedEmployeeLedgerEntry."Posting Group" = '' then begin
            EmployeeLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
            EmployeeLedgerEntry.Get(DetailedEmployeeLedgerEntry."Employee Ledger Entry No.");
            DetailedEmployeeLedgerEntry."Posting Group" := EmployeeLedgerEntry."Employee Posting Group";
            DetailedEmployeeLedgerEntry.Modify();
        end;
    end;

    local procedure UnapplyExcludedVAT(var TempVATEntry: Record "VAT Entry" temporary; TransactionNo: Integer; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        TempVATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        TempVATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        TempVATEntry.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        if not TempVATEntry.FindFirst() then begin
            TempVATEntry.Reset();
            if TempVATEntry.FindLast() then
                TempVATEntry."Entry No." := TempVATEntry."Entry No." + 1
            else
                TempVATEntry."Entry No." := 1;
            TempVATEntry.Init();
            TempVATEntry."VAT Bus. Posting Group" := VATBusPostingGroup;
            TempVATEntry."VAT Prod. Posting Group" := VATProdPostingGroup;
            TempVATEntry."Gen. Prod. Posting Group" := GenProdPostingGroup;
            VATEntry.SetCurrentKey("Transaction No.");
            VATEntry.SetRange("Transaction No.", TransactionNo);
            VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
            VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
            VATEntry.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
            if VATEntry.FindSet() then
                repeat
                    if VATEntry."Unrealized VAT Entry No." = 0 then begin
                        TempVATEntry.Base := TempVATEntry.Base + VATEntry.Base;
                        TempVATEntry.Amount := TempVATEntry.Amount + VATEntry.Amount;
                    end;
                until VATEntry.Next() = 0;
            Clear(VATEntry);
            TempVATEntry.Insert();
        end;
    end;

    local procedure PostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry"): Integer
    var
        VATEntry2: Record "VAT Entry";
        AmountAddCurr: Decimal;
        GLEntryNoFromVAT: Integer;
    begin
        OnBeforePostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry);

        AmountAddCurr := CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        CreateGLEntry(
            GenJnlLine, GetPostingAccountNo(VATPostingSetup, VATEntry, true), VATEntry.Amount, AmountAddCurr, false,
            CalcAmountSrcCurr(GenJnlLine, VATEntry.Amount));
        GLEntryNoFromVAT :=
          CreateGLEntryFromVATEntry(
            GenJnlLine, GetPostingAccountNo(VATPostingSetup, VATEntry, false), -VATEntry.Amount, -AmountAddCurr, VATEntry);

        VATEntry2.Get(VATEntry."Unrealized VAT Entry No.");
        VATEntry2."Remaining Unrealized Amount" := VATEntry2."Remaining Unrealized Amount" - NewVATEntry.Amount;
        VATEntry2."Remaining Unrealized Base" := VATEntry2."Remaining Unrealized Base" - NewVATEntry.Base;
        VATEntry2."Add.-Curr. Rem. Unreal. Amount" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Amount" - NewVATEntry."Additional-Currency Amount";
        VATEntry2."Add.-Curr. Rem. Unreal. Base" :=
          VATEntry2."Add.-Curr. Rem. Unreal. Base" - NewVATEntry."Additional-Currency Base";
        OnPostUnrealVATByUnapplyOnBeforeVATEntryModify(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry, VATEntry2, GLEntryNoFromVAT);
        VATEntry2.Modify();

        OnAfterPostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, NewVATEntry);

        exit(GLEntryNoFromVAT);
    end;

    local procedure PostPmtDiscountVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; ReverseChargeVATAccNo: Code[20]; VATAccNo: Code[20]; VATEntry: Record "VAT Entry")
    var
        AmountAddCurr: Decimal;
    begin
        OnBeforePostPmtDiscountVATByUnapply(GenJnlLine, VATEntry);

        AmountAddCurr := CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount);
        CreateGLEntry(
            GenJnlLine, ReverseChargeVATAccNo, VATEntry.Amount, AmountAddCurr, false,
            CalcAmountSrcCurr(GenJnlLine, VATEntry.Amount));
        CreateGLEntry(
            GenJnlLine, VATAccNo, -VATEntry.Amount, -AmountAddCurr, false,
            CalcAmountSrcCurr(GenJnlLine, -VATEntry.Amount));

        OnAfterPostPmtDiscountVATByUnapply(GenJnlLine, VATEntry);
    end;

    local procedure PostUnapply(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; VATEntryType: Enum "General Posting Type"; BilltoPaytoNo: Code[20]; TransactionNo: Integer; UnapplyVATEntries: Boolean; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry2: Record "VAT Entry";
        AccNo: Code[20];
        TempVATEntryNo: Integer;
        GLEntryNoFromVAT: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUnapply(GenJnlLine, VATEntry, VATEntryType, BilltoPaytoNo, TransactionNo, UnapplyVATEntries, TempVATEntry, IsHandled, NextVATEntryNo);
        if IsHandled then
            exit;

        TempVATEntryNo := 1;
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.", "Transaction No.");
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.SetRange("Bill-to/Pay-to No.", BilltoPaytoNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);
        OnPostUnapplyOnAfterVATEntrySetFilters(VATEntry, GenJnlLine);
        if VATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                OnPostUnapplyOnBeforeUnapplyVATEntry(VATEntry, UnapplyVATEntries);
                if UnapplyVATEntries or (VATEntry."Unrealized VAT Entry No." <> 0) then begin
                    InsertTempVATEntry(GenJnlLine, VATEntry, TempVATEntryNo, TempVATEntry);
                    if VATEntry."Unrealized VAT Entry No." <> 0 then begin
                        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                        if VATPostingSetup."VAT Calculation Type" in
                           [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                            VATPostingSetup."VAT Calculation Type"::"Full VAT"]
                        then
                            GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry)
                        else
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then begin
                                GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry);
                                CreateGLEntry(
                                    GenJnlLine, VATPostingSetup.GetRevChargeAccount(true),
                                    -VATEntry.Amount, CalcAddCurrForUnapplication(VATEntry."Posting Date", -VATEntry.Amount), false,
                                    CalcAmountSrcCurr(GenJnlLine, -VATEntry.Amount));
                                CreateGLEntry(
                                    GenJnlLine, VATPostingSetup.GetRevChargeAccount(false),
                                    VATEntry.Amount, CalcAddCurrForUnapplication(VATEntry."Posting Date", VATEntry.Amount), false,
                                    CalcAmountSrcCurr(GenJnlLine, -VATEntry.Amount));
                            end else
                                GLEntryNoFromVAT := PostUnrealVATByUnapply(GenJnlLine, VATPostingSetup, VATEntry, TempVATEntry);
                        VATEntry2 := TempVATEntry;
                        VATEntry2."Entry No." := NextVATEntryNo;
                        OnPostUnapplyOnBeforeVATEntryInsert(VATEntry2, GenJnlLine, VATEntry);
                        VATEntry2.Insert();
                        OnPostUnapplyOnAfterVATEntryInsert(VATEntry2, GenJnlLine, VATEntry);
                        if GLEntryNoFromVAT <> 0 then
                            TempGLEntryVATEntryLink.InsertLinkSelf(GLEntryNoFromVAT, VATEntry2."Entry No.");
                        GLEntryNoFromVAT := 0;
                        TempVATEntry.Delete();
                        IncrNextVATEntryNo();
                    end;

                    if VATPostingSetup."Adjust for Payment Discount" and not IsNotPayment(VATEntry."Document Type") and
                       (VATPostingSetup."VAT Calculation Type" =
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT") and
                       (VATEntry."Unrealized VAT Entry No." = 0) and UnapplyVATEntries and (VATEntry.Amount <> 0)
                    then begin
                        case VATEntryType of
                            VATEntry.Type::Sale:
                                AccNo := VATPostingSetup.GetSalesAccount(false);
                            VATEntry.Type::Purchase:
                                AccNo := VATPostingSetup.GetPurchAccount(false);
                        end;
                        PostPmtDiscountVATByUnapply(GenJnlLine, VATPostingSetup.GetRevChargeAccount(false), AccNo, VATEntry);
                    end;
                end;
            until VATEntry.Next() = 0;
    end;

    local procedure CalcAddCurrForUnapplication(Date: Date; Amt: Decimal): Decimal
    var
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if AddCurrencyCode = '' then
            exit;

        AddCurrency.Get(AddCurrencyCode);
        AddCurrency.TestField("Amount Rounding Precision");

        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              Date, AddCurrencyCode, Amt, CurrExchRate.ExchangeRate(Date, AddCurrencyCode)),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure CalcVATAmountFromVATEntry(AmountLCY: Decimal; var VATEntry: Record "VAT Entry"; CurrencyLCY: Record Currency) VATAmountLCY: Decimal
    begin
        if (AmountLCY = VATEntry.Base) or (VATEntry.Base = 0) then begin
            VATAmountLCY := VATEntry.Amount;
            VATEntry.Delete();
        end else begin
            VATAmountLCY :=
              Round(
                VATEntry.Amount * AmountLCY / VATEntry.Base,
                CurrencyLCY."Amount Rounding Precision",
                CurrencyLCY.VATRoundingDirection());
            VATEntry.Base := VATEntry.Base - AmountLCY;
            VATEntry.Amount := VATEntry.Amount - VATAmountLCY;
            VATEntry.Modify();
        end;
    end;

    local procedure InsertDtldCustLedgEntryUnapply(GenJnlLine: Record "Gen. Journal Line"; var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NextDtldLedgEntryNo: Integer; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        NewDtldCustLedgEntry := OldDtldCustLedgEntry;
        NewDtldCustLedgEntry."Entry No." := NextDtldLedgEntryNo;
        NewDtldCustLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewDtldCustLedgEntry."Transaction No." := NextTransactionNo;
        NewDtldCustLedgEntry."Application No." := 0;
        NewDtldCustLedgEntry.Amount := -OldDtldCustLedgEntry.Amount;
        NewDtldCustLedgEntry."Amount (LCY)" := -OldDtldCustLedgEntry."Amount (LCY)";
        NewDtldCustLedgEntry."Debit Amount" := -OldDtldCustLedgEntry."Debit Amount";
        NewDtldCustLedgEntry."Credit Amount" := -OldDtldCustLedgEntry."Credit Amount";
        NewDtldCustLedgEntry."Debit Amount (LCY)" := -OldDtldCustLedgEntry."Debit Amount (LCY)";
        NewDtldCustLedgEntry."Credit Amount (LCY)" := -OldDtldCustLedgEntry."Credit Amount (LCY)";
        NewDtldCustLedgEntry.Unapplied := true;
        NewDtldCustLedgEntry."Unapplied by Entry No." := OldDtldCustLedgEntry."Entry No.";
        NewDtldCustLedgEntry."Document No." := GenJnlLine."Document No.";
        NewDtldCustLedgEntry."Source Code" := GenJnlLine."Source Code";
        NewDtldCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDtldCustLedgEntry."User ID"));
        NewDtldCustLedgEntry."Posting Group" := OldDtldCustLedgEntry."Posting Group";
        OnBeforeInsertDtldCustLedgEntryUnapply(NewDtldCustLedgEntry, GenJnlLine, OldDtldCustLedgEntry, GLReg);
        NewDtldCustLedgEntry.Insert(true);
        NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;

        OnAfterInsertDtldCustLedgEntryUnapply(CustomerPostingGroup, OldDtldCustLedgEntry, GenJnlLine, NewDtldCustLedgEntry);
    end;

    local procedure InsertDtldVendLedgEntryUnapply(GenJnlLine: Record "Gen. Journal Line"; var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var NextDtldLedgEntryNo: Integer)
    begin
        NewDtldVendLedgEntry := OldDtldVendLedgEntry;
        NewDtldVendLedgEntry."Entry No." := NextDtldLedgEntryNo;
        NewDtldVendLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewDtldVendLedgEntry."Transaction No." := NextTransactionNo;
        NewDtldVendLedgEntry."Application No." := 0;
        NewDtldVendLedgEntry.Amount := -OldDtldVendLedgEntry.Amount;
        NewDtldVendLedgEntry."Amount (LCY)" := -OldDtldVendLedgEntry."Amount (LCY)";
        NewDtldVendLedgEntry."Debit Amount" := -OldDtldVendLedgEntry."Debit Amount";
        NewDtldVendLedgEntry."Credit Amount" := -OldDtldVendLedgEntry."Credit Amount";
        NewDtldVendLedgEntry."Debit Amount (LCY)" := -OldDtldVendLedgEntry."Debit Amount (LCY)";
        NewDtldVendLedgEntry."Credit Amount (LCY)" := -OldDtldVendLedgEntry."Credit Amount (LCY)";
        NewDtldVendLedgEntry.Unapplied := true;
        NewDtldVendLedgEntry."Unapplied by Entry No." := OldDtldVendLedgEntry."Entry No.";
        NewDtldVendLedgEntry."Document No." := GenJnlLine."Document No.";
        NewDtldVendLedgEntry."Source Code" := GenJnlLine."Source Code";
        NewDtldVendLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDtldVendLedgEntry."User ID"));
        NewDtldVendLedgEntry."Posting Group" := OldDtldVendLedgEntry."Posting Group";
        OnBeforeInsertDtldVendLedgEntryUnapply(NewDtldVendLedgEntry, GenJnlLine, OldDtldVendLedgEntry, GLReg);
        NewDtldVendLedgEntry.Insert(true);
        NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;
        OnAfterInsertDtldVendLedgEntryUnapply(OldDtldVendLedgEntry, GenJnlLine, NewDtldVendLedgEntry);
    end;

    local procedure InsertDtldEmplLedgEntryUnapply(GenJnlLine: Record "Gen. Journal Line"; var NewDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; OldDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; var NextDtldLedgEntryNo: Integer)
    begin
        NewDtldEmplLedgEntry := OldDtldEmplLedgEntry;
        NewDtldEmplLedgEntry."Entry No." := NextDtldLedgEntryNo;
        NewDtldEmplLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewDtldEmplLedgEntry."Transaction No." := NextTransactionNo;
        NewDtldEmplLedgEntry."Application No." := 0;
        NewDtldEmplLedgEntry.Amount := -OldDtldEmplLedgEntry.Amount;
        NewDtldEmplLedgEntry."Amount (LCY)" := -OldDtldEmplLedgEntry."Amount (LCY)";
        NewDtldEmplLedgEntry."Debit Amount" := -OldDtldEmplLedgEntry."Debit Amount";
        NewDtldEmplLedgEntry."Credit Amount" := -OldDtldEmplLedgEntry."Credit Amount";
        NewDtldEmplLedgEntry."Debit Amount (LCY)" := -OldDtldEmplLedgEntry."Debit Amount (LCY)";
        NewDtldEmplLedgEntry."Credit Amount (LCY)" := -OldDtldEmplLedgEntry."Credit Amount (LCY)";
        NewDtldEmplLedgEntry.Unapplied := true;
        NewDtldEmplLedgEntry."Unapplied by Entry No." := OldDtldEmplLedgEntry."Entry No.";
        NewDtldEmplLedgEntry."Document No." := GenJnlLine."Document No.";
        NewDtldEmplLedgEntry."Source Code" := GenJnlLine."Source Code";
        NewDtldEmplLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDtldEmplLedgEntry."User ID"));
        NewDtldEmplLedgEntry."Posting Group" := OldDtldEmplLedgEntry."Posting Group";
        OnBeforeInsertDtldEmplLedgEntryUnapply(NewDtldEmplLedgEntry, GenJnlLine, OldDtldEmplLedgEntry);
        NewDtldEmplLedgEntry.Insert(true);
        NextDtldLedgEntryNo := NextDtldLedgEntryNo + 1;
    end;

    local procedure InsertTempVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var TempVATEntryNo: Integer; var TempVATEntry: Record "VAT Entry" temporary)
    begin
        TempVATEntry := VATEntry;
        TempVATEntry."Entry No." := TempVATEntryNo;
        TempVATEntryNo := TempVATEntryNo + 1;
        TempVATEntry."Closed by Entry No." := 0;
        TempVATEntry.Closed := false;
        TempVATEntry.CopyAmountsFromVATEntry(VATEntry, true);
        TempVATEntry."Posting Date" := GenJnlLine."Posting Date";
        TempVATEntry."Document Date" := GenJnlLine."Document Date";
        TempVATEntry."VAT Reporting Date" := GenJnlLine."VAT Reporting Date";
        TempVATEntry."Document No." := GenJnlLine."Document No.";
        TempVATEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(TempVATEntry."User ID"));
        TempVATEntry."Transaction No." := NextTransactionNo;
        TempVATEntry."G/L Acc. No." := '';
        OnInsertTempVATEntryOnBeforeInsert(TempVATEntry, GenJnlLine, VATEntry);
        TempVATEntry.Insert();
    end;

    local procedure SetGLAccountNoInVATEntries();
    var
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        if TempGLEntryVATEntryLink.FindSet() then
            repeat
                GLEntryVATEntryLink.InsertLinkSelf(TempGLEntryVATEntryLink."G/L Entry No.", TempGLEntryVATEntryLink."VAT Entry No.");
            until TempGLEntryVATEntryLink.Next() = 0;

        TempGLEntryVATEntryLink.DeleteAll();
    end;

    local procedure ProcessTempVATEntry(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATEntrySaved: Record "VAT Entry";
        VATBaseSum: array[3] of Decimal;
        DeductedVATBase: Decimal;
        EntryNoBegin: array[3] of Integer;
        i: Integer;
        SummarizedVAT: Boolean;
    begin
        if not (DtldCVLedgEntryBuf."Entry Type" in
                [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"])
        then
            exit;

        DeductedVATBase := 0;
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Entry No.", 0, 999999);
        TempVATEntry.SetRange("Gen. Bus. Posting Group", DtldCVLedgEntryBuf."Gen. Bus. Posting Group");
        TempVATEntry.SetRange("Gen. Prod. Posting Group", DtldCVLedgEntryBuf."Gen. Prod. Posting Group");
        TempVATEntry.SetRange("VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Bus. Posting Group");
        TempVATEntry.SetRange("VAT Prod. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
        if TempVATEntry.FindSet() then
            repeat
                case true of
                    SummarizedVAT and (VATBaseSum[3] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 4;
                    SummarizedVAT and (VATBaseSum[2] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 3;
                    SummarizedVAT and (VATBaseSum[1] + TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase):
                        i := 2;
                    TempVATEntry.Base = DtldCVLedgEntryBuf."Amount (LCY)" - DeductedVATBase:
                        i := 1;
                    else
                        i := 0;
                end;
                if i > 0 then begin
                    TempVATEntry.Reset();
                    if i > 1 then begin
                        if EntryNoBegin[i - 1] < TempVATEntry."Entry No." then
                            TempVATEntry.SetRange("Entry No.", EntryNoBegin[i - 1], TempVATEntry."Entry No.")
                        else
                            TempVATEntry.SetRange("Entry No.", TempVATEntry."Entry No.", EntryNoBegin[i - 1]);
                    end else
                        TempVATEntry.SetRange("Entry No.", TempVATEntry."Entry No.");
                    TempVATEntry.FindSet();
                    repeat
                        VATEntrySaved := TempVATEntry;
                        case DtldCVLedgEntryBuf."Entry Type" of
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 3000000);
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 2000000);
                            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                                TempVATEntry.Rename(TempVATEntry."Entry No." + 1000000);
                        end;
                        TempVATEntry := VATEntrySaved;
                        DeductedVATBase += TempVATEntry.Base;
                    until TempVATEntry.Next() = 0;
                    for i := 1 to 3 do begin
                        VATBaseSum[i] := 0;
                        EntryNoBegin[i] := 0;
                        SummarizedVAT := false;
                    end;
                    TempVATEntry.SetRange("Entry No.", 0, 999999);
                end else begin
                    VATBaseSum[3] += TempVATEntry.Base;
                    VATBaseSum[2] := VATBaseSum[1] + TempVATEntry.Base;
                    VATBaseSum[1] := TempVATEntry.Base;
                    if EntryNoBegin[3] > 0 then
                        EntryNoBegin[3] := TempVATEntry."Entry No.";
                    EntryNoBegin[2] := EntryNoBegin[1];
                    EntryNoBegin[1] := TempVATEntry."Entry No.";
                    SummarizedVAT := true;
                end;
            until TempVATEntry.Next() = 0;
    end;

    local procedure ProcessTempVATEntryCust(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        DetailedCustLedgEntry.SetCurrentKey("Entry No.");
        if not DetailedCustLedgEntry.FindSet() then
            exit;
        repeat
            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(DetailedCustLedgEntry);
            ProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
            OnProcessTempVATEntryCustOnAfterProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure ProcessTempVATEntryVend(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var TempVATEntry: Record "VAT Entry" temporary)
    var
        DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
    begin
        if not DetailedVendorLedgEntry.FindSet() then
            exit;
        repeat
            DetailedCVLedgEntryBuffer.Init();
            DetailedCVLedgEntryBuffer.TransferFields(DetailedVendorLedgEntry);
            ProcessTempVATEntry(DetailedCVLedgEntryBuffer, TempVATEntry);
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure UpdateCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if DtldCustLedgEntry."Entry Type" <> DtldCustLedgEntry."Entry Type"::Application then
            exit;

        CustLedgEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
        CustLedgEntry."Remaining Pmt. Disc. Possible" := DtldCustLedgEntry."Remaining Pmt. Disc. Possible";
        CustLedgEntry."Max. Payment Tolerance" := DtldCustLedgEntry."Max. Payment Tolerance";
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        if not CustLedgEntry.Open then begin
            CustLedgEntry.Open := true;
            CustLedgEntry."Closed by Entry No." := 0;
            CustLedgEntry."Closed at Date" := 0D;
            CustLedgEntry."Closed by Amount" := 0;
            CustLedgEntry."Closed by Amount (LCY)" := 0;
            CustLedgEntry."Closed by Currency Code" := '';
            CustLedgEntry."Closed by Currency Amount" := 0;
            CustLedgEntry."Pmt. Disc. Given (LCY)" := 0;
            CustLedgEntry."Pmt. Tolerance (LCY)" := 0;
            CustLedgEntry."Calculate Interest" := false;
        end;

        OnBeforeCustLedgEntryModify(CustLedgEntry, DtldCustLedgEntry);
        CustLedgEntry.Modify();

        OnAfterUpdateCustLedgEntry(DtldCustLedgEntry, TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
    end;

    local procedure UpdateVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::Application then
            exit;

        VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
        VendLedgEntry."Remaining Pmt. Disc. Possible" := DtldVendLedgEntry."Remaining Pmt. Disc. Possible";
        VendLedgEntry."Max. Payment Tolerance" := DtldVendLedgEntry."Max. Payment Tolerance";
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        if not VendLedgEntry.Open then begin
            VendLedgEntry.Open := true;
            VendLedgEntry."Closed by Entry No." := 0;
            VendLedgEntry."Closed at Date" := 0D;
            VendLedgEntry."Closed by Amount" := 0;
            VendLedgEntry."Closed by Amount (LCY)" := 0;
            VendLedgEntry."Closed by Currency Code" := '';
            VendLedgEntry."Closed by Currency Amount" := 0;
            VendLedgEntry."Pmt. Disc. Rcd.(LCY)" := 0;
            VendLedgEntry."Pmt. Tolerance (LCY)" := 0;
            VendLedgEntry."Applies-to Ext. Doc. No." := '';
        end;

        OnBeforeVendLedgEntryModify(VendLedgEntry, DtldVendLedgEntry);
        VendLedgEntry.Modify();

        OnAfterUpdateVendLedgEntry(DtldVendLedgEntry, TempGLEntryBuf, GlobalGLEntry, NextTransactionNo);
    end;

    local procedure UpdateEmplLedgEntry(DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        if DtldEmplLedgEntry."Entry Type" <> DtldEmplLedgEntry."Entry Type"::Application then
            exit;

        EmplLedgEntry.Get(DtldEmplLedgEntry."Employee Ledger Entry No.");
        if not EmplLedgEntry.Open then begin
            EmplLedgEntry.Open := true;
            EmplLedgEntry."Closed by Entry No." := 0;
            EmplLedgEntry."Closed at Date" := 0D;
            EmplLedgEntry."Closed by Amount" := 0;
            EmplLedgEntry."Closed by Amount (LCY)" := 0;
            EmplLedgEntry."Closed by Currency Code" := '';
            EmplLedgEntry."Closed by Currency Amount" := 0;
        end;

        OnBeforeEmplLedgEntryModify(EmplLedgEntry, DtldEmplLedgEntry);
        EmplLedgEntry.Modify();
    end;

    local procedure UpdateCalcInterest(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        if CustLedgEntry.Get(CVLedgEntryBuf."Closed by Entry No.") then begin
            CVLedgEntryBuf2.TransferFields(CustLedgEntry);
            UpdateCalcInterest(CVLedgEntryBuf, CVLedgEntryBuf2);
        end;
        CustLedgEntry.SetCurrentKey("Closed by Entry No.");
        CustLedgEntry.SetRange("Closed by Entry No.", CVLedgEntryBuf."Entry No.");
        OnUpdateCalcInterestOnAfterCustLedgEntrySetFilters(CustLedgEntry, CVLedgEntryBuf);
        if CustLedgEntry.FindSet() then
            repeat
                CVLedgEntryBuf2.TransferFields(CustLedgEntry);
                UpdateCalcInterest(CVLedgEntryBuf, CVLedgEntryBuf2);
            until CustLedgEntry.Next() = 0;
    end;

    local procedure UpdateCalcInterest(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var CVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
        if CVLedgEntryBuf."Due Date" < CVLedgEntryBuf2."Document Date" then
            CVLedgEntryBuf."Calculate Interest" := true;
    end;

    procedure GLCalcAddCurrency(Amount: Decimal; AddCurrAmount: Decimal; OldAddCurrAmount: Decimal; UseAddCurrAmount: Boolean; GenJnlLine: Record "Gen. Journal Line") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        if (AddCurrencyCode <> '') and
           (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None)
        then begin
            if (GenJnlLine."Source Currency Code" = AddCurrencyCode) and UseAddCurrAmount then
                exit(AddCurrAmount);

            IsHandled := false;
            OnGLCalcAddCurrencyPostingNone(GenJnlLine, Amount, AddCurrency, Result, IsHandled);
            if IsHandled then
                exit(Result);
            exit(ExchangeAmtLCYToFCY2(Amount));
        end;
        exit(OldAddCurrAmount);
    end;

    local procedure HandleAddCurrResidualGLEntry(GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry")
    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        if AddCurrencyCode = '' then
            exit;

        TotalAddCurrAmount := TotalAddCurrAmount + GLEntry2."Additional-Currency Amount";
        TotalAmount := TotalAmount + GLEntry2.Amount;

        if (GenJnlLine."Additional-Currency Posting" = GenJnlLine."Additional-Currency Posting"::None) and
           (TotalAmount = 0) and (TotalAddCurrAmount <> 0) and
           CheckNonAddCurrCodeOccurred(GenJnlLine."Source Currency Code")
        then begin
            GLEntry.Init();
            GLEntry.CopyFromGenJnlLine(GenJnlLine);
            GLEntry."External Document No." := '';
            GLEntry.Description :=
              CopyStr(
                StrSubstNo(
                  ResidualRoundingErr,
                  GLEntry.FieldCaption("Additional-Currency Amount")),
                1, MaxStrLen(GLEntry.Description));
            GLEntry."Source Type" := GLEntry."Source Type"::" ";
            GLEntry."Source No." := '';
            GLEntry."Job No." := '';
            GLEntry.Quantity := 0;
            GLEntry."Entry No." := NextEntryNo;
            GLEntry."Transaction No." := NextTransactionNo;
            if TotalAddCurrAmount < 0 then
                GLEntry."G/L Account No." := AddCurrency."Residual Losses Account"
            else
                GLEntry."G/L Account No." := AddCurrency."Residual Gains Account";
            GLEntry.Amount := 0;
            GLEntry."System-Created Entry" := true;
            GLEntry."Additional-Currency Amount" := -TotalAddCurrAmount;
            GLAcc.Get(GLEntry."G/L Account No.");
            GLAcc.TestField(Blocked, false);
            GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
            IsHandled := false;
            OnHandleAddCurrResidualGLEntryOnBeforeInsertGLEntry(GenJnlLine, GLEntry, TempGLEntryBuf, NextEntryNo, IsHandled);
            if not IsHandled then
                InsertGLEntry(GenJnlLine, GLEntry, false);

            CheckGLAccDimError(GenJnlLine, GLEntry."G/L Account No.");

            TotalAddCurrAmount := 0;
        end;

        OnAfterHandleAddCurrResidualGLEntry(GenJnlLine, GLEntry2);
    end;

    /// <summary>
    /// Converts amount to additional reporting currency
    /// </summary>
    /// <remarks>
    /// If additional reporting currency is not set, conversion is not performed.
    /// </remarks>
    /// <param name="AmountLCY">Amount in local currency</param>
    /// <returns>Amount in additional reporting currency</returns>
    procedure CalcLCYToAddCurr(AmountLCY: Decimal): Decimal
    begin
        if AddCurrencyCode = '' then
            exit;

        exit(ExchangeAmtLCYToFCY2(AmountLCY));
    end;

    local procedure GetCurrencyExchRate(GenJnlLine: Record "Gen. Journal Line")
    var
        NewCurrencyDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCurrencyExchRate(GenJnlLine, AddCurrencyCode, UseCurrFactorOnly, CurrencyDate, CurrencyFactor, IsHandled);
        if IsHandled then
            exit;

        if AddCurrencyCode = '' then
            exit;

        AddCurrency.Get(AddCurrencyCode);
        AddCurrency.TestField("Amount Rounding Precision");
        AddCurrency.TestField("Residual Gains Account");
        AddCurrency.TestField("Residual Losses Account");

        NewCurrencyDate := GenJnlLine."Posting Date";
        if GenJnlLine."Reversing Entry" then
            NewCurrencyDate := NewCurrencyDate - 1;
        OnGetCurrencyExchRateOnAfterSetNewCurrencyDate(GenJnlLine, NewCurrencyDate);
        if (NewCurrencyDate <> CurrencyDate) or
           UseCurrFactorOnly
        then begin
            UseCurrFactorOnly := false;
            CurrencyDate := NewCurrencyDate;
            CurrencyFactor :=
              CurrExchRate.ExchangeRate(CurrencyDate, AddCurrencyCode);
        end;
        if (GenJnlLine."FA Add.-Currency Factor" <> 0) and
           (GenJnlLine."FA Add.-Currency Factor" <> CurrencyFactor)
        then begin
            UseCurrFactorOnly := true;
            CurrencyDate := 0D;
            CurrencyFactor := GenJnlLine."FA Add.-Currency Factor";
        end;

        OnAfterGetCurrencyExchRate(GenJnlLine, NewCurrencyDate, CurrencyDate, UseCurrFactorOnly, CurrencyFactor);
    end;

    /// <summary>
    /// Converts amount from local to foreign currency.
    /// </summary>
    /// <param name="Amount">Amount to be converted</param>
    /// <returns>Amount in foreign currency</returns>
    procedure ExchangeAmtLCYToFCY2(Amount: Decimal): Decimal
    begin
        if UseCurrFactorOnly then
            exit(
              Round(
                CurrExchRate.ExchangeAmtLCYToFCYOnlyFactor(Amount, CurrencyFactor),
                AddCurrency."Amount Rounding Precision"));
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              CurrencyDate, AddCurrencyCode, Amount, CurrencyFactor),
            AddCurrency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Checks and returns if the currency code is different than additional reporting currency
    /// </summary>
    /// <param name="CurrencyCode">Currency Code to be checked</param>
    /// <returns>True if Currency Code passed as a parameter is different than additional reporting currency</returns>
    procedure CheckNonAddCurrCodeOccurred(CurrencyCode: Code[10]): Boolean
    begin
        NonAddCurrCodeOccured :=
          NonAddCurrCodeOccured or (AddCurrencyCode <> CurrencyCode);
        exit(NonAddCurrCodeOccured);
    end;

    local procedure TotalVATAmountOnJnlLines(GenJnlLine: Record "Gen. Journal Line") TotalVATAmount: Decimal
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.SetRange("Source Code", GenJnlLine."Source Code");
        GenJnlLine2.SetRange("Document No.", GenJnlLine."Document No.");
        GenJnlLine2.SetRange("Posting Date", GenJnlLine."Posting Date");
        GenJnlLine2.CalcSums(GenJnlLine2."VAT Amount (LCY)", GenJnlLine2."Bal. VAT Amount (LCY)");
        TotalVATAmount := GenJnlLine2."VAT Amount (LCY)" - GenJnlLine2."Bal. VAT Amount (LCY)";
        exit(TotalVATAmount);
    end;

    /// <summary>
    /// Sets parameter ReverseGLReg to the same value as global variable GLReg with reversed set to true.
    /// </summary>
    /// <remarks>
    /// Global variable GLReg stores information of the g/l register that being created
    /// </remarks>
    /// <param name="ReverseGLReg">Return Value: General ledger register to be reversed</param>
    procedure SetGLRegReverse(var ReverseGLReg: Record "G/L Register")
    begin
        GLReg.Reversed := true;
        ReverseGLReg := GLReg;
    end;

    local procedure InsertVATEntriesFromTemp(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GLEntry: Record "G/L Entry")
    var
        Complete: Boolean;
        LinkedAmount: Decimal;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange("Gen. Bus. Posting Group", GLEntry."Gen. Bus. Posting Group");
        TempVATEntry.SetRange("Gen. Prod. Posting Group", GLEntry."Gen. Prod. Posting Group");
        TempVATEntry.SetRange("VAT Bus. Posting Group", GLEntry."VAT Bus. Posting Group");
        TempVATEntry.SetRange("VAT Prod. Posting Group", GLEntry."VAT Prod. Posting Group");
        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)":
                begin
                    FirstEntryNo := 1000000;
                    LastEntryNo := 1999999;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)":
                begin
                    FirstEntryNo := 2000000;
                    LastEntryNo := 2999999;
                end;
            DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)":
                begin
                    FirstEntryNo := 3000000;
                    LastEntryNo := 3999999;
                end;
        end;
        TempVATEntry.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
        if TempVATEntry.FindSet() then
            repeat
                VATEntry := TempVATEntry;
                VATEntry."Entry No." := NextVATEntryNo;
                OnInsertVATEntriesFromTempOnBeforeVATEntryInsert(VATEntry, TempVATEntry, GLReg, GLEntry);
                VATEntry.Insert(true);
                NextVATEntryNo := NextVATEntryNo + 1;
                if VATEntry."Unrealized VAT Entry No." = 0 then
                    TempGLEntryVATEntryLink.InsertLinkSelf(GLEntry."Entry No.", VATEntry."Entry No.");
                LinkedAmount += VATEntry.Amount + VATEntry.Base;
                Complete := LinkedAmount = -(DtldCVLedgEntryBuf."Amount (LCY)" + DtldCVLedgEntryBuf."VAT Amount (LCY)");
                LastEntryNo := TempVATEntry."Entry No.";
            until Complete or (TempVATEntry.Next() = 0);

        TempVATEntry.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
        TempVATEntry.DeleteAll();
    end;

    /// <summary>
    /// Returns smaller value of the two parameters passed to the procedure.
    /// </summary>
    /// <param name="Decimal1">Value to compare</param>
    /// <param name="Decimal2">Value to compare</param>
    /// <returns>Smaller of the two passed parameters</returns>
    procedure ABSMin(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        if Abs(Decimal1) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure GetApplnRoundPrecision(NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"): Decimal
    var
        ApplnCurrency: Record Currency;
    begin
        if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf."Currency Code" then
            exit(0);

        ApplnCurrency.Initialize(NewCVLedgEntryBuf."Currency Code");
        if NewCVLedgEntryBuf."Currency Code" <> '' then
            exit(ApplnCurrency."Appln. Rounding Precision");

        GetGLSetup();
        exit(GLSetup."Appln. Rounding Precision");
    end;

    /// <summary>
    /// Retrieves general ledger setup if it wasn't retrieved before.
    /// Global variable to store additional reporting currency is set from general ledger setup.
    /// </summary>
    procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;

        GLSetup.Get();
        GLSetupRead := true;

        AddCurrencyCode := GLSetup."Additional Reporting Currency";
        OnAfterGetGLSetup(GLSetup, GLSetupRead, AddCurrencyCode);
    end;

    local procedure ReadGLSetup(var NewGLSetup: Record "General Ledger Setup")
    begin
        NewGLSetup := GLSetup;
    end;

    procedure GetSourceCodeSetup()
    begin
        if SourceCodeSetupRead then
            exit;

        SourceCodeSetup.Get();
        SourceCodeSetupRead := true;
    end;

    local procedure CheckSalesExtDocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesExtDocNo(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if not SalesSetup."Ext. Doc. No. Mandatory" then
            exit;

        if GenJnlLine."Document Type" in
           [GenJnlLine."Document Type"::Invoice,
            GenJnlLine."Document Type"::"Credit Memo",
            GenJnlLine."Document Type"::Payment,
            GenJnlLine."Document Type"::Refund,
            GenJnlLine."Document Type"::" "]
        then
            GenJnlLine.TestField("External Document No.");
    end;

    local procedure CheckPurchExtDocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        VendorMgt: Codeunit "Vendor Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchExtDocNoProcedure(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if not (PurchSetup."Ext. Doc. No. Mandatory" or (GenJnlLine."External Document No." <> '')) then
            exit;

        GenJnlLine.TestField("External Document No.");
        OldVendLedgEntry.Reset();
        VendorMgt.SetFilterForExternalDocNo(
          OldVendLedgEntry, GenJnlLine."Document Type", GenJnlLine."External Document No.",
          GenJnlLine."Account No.", GenJnlLine."Document Date");
        if not OldVendLedgEntry.IsEmpty() then
            Error(
              PurchaseAlreadyExistsErr,
              GenJnlLine."Document Type", GenJnlLine."External Document No.");
    end;

    /// <summary>
    /// Check dimension restrictions on gen. journal line that relates to g/l account.
    /// </summary>
    /// <remarks>
    /// Only gen. journal lines that have amount are checked
    /// FA Posting Type must be equal to disposal on gen. journal line
    /// </remarks>
    /// <param name="GenJnlLine">gen. journal line being posted</param>
    /// <param name="GLAccNo">g/l account no. to be checked</param>
    procedure CheckDimValueForDisposal(GenJnlLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimValueForDisposal(GenJnlLine, AccountNo, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine.Amount = 0) or (GenJnlLine."Amount (LCY)" = 0)) and
           (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Disposal)
        then begin
            TableID[1] := DimMgt.TypeToTableID1(GenJnlLine."Account Type"::"G/L Account".AsInteger());
            AccNo[1] := AccountNo;
            if not DimMgt.CheckDimValuePosting(TableID, AccNo, GenJnlLine."Dimension Set ID") then
                Error(DimMgt.GetDimValuePostingErr());
        end;
    end;

    /// <summary>
    /// Sets the global variable OverrideDimErr for the current instance of the codeunit.
    /// If OverrideDimErr is not set dimension check is performed before posting gen. journal line 
    /// </summary>
    procedure SetOverDimErr()
    begin
        OverrideDimErr := true;
    end;

    /// <summary>
    /// Sets the Preview Mode for the current instance of the codeunit.
    /// Preview Mode ensures no transactions are committed to the database.
    /// </summary>
    /// <param name="NewPreviewMode">The new value for the Preview Mode.</param>
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    /// <summary>
    /// Check dimension restrictions on gen. journal line that relates to g/l account.
    /// </summary>
    /// <remarks>
    /// Only gen. journal lines that have amount and currency are checked
    /// g/l account must be same as specified on currency realized/unrealized gain/loss
    /// </remarks>
    /// <param name="GenJnlLine">gen. journal line being posted</param>
    /// <param name="GLAccNo">g/l account no. to be checked</param>
    procedure CheckGLAccDimError(GenJnlLine: Record "Gen. Journal Line"; GLAccNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDimError(GenJnlLine, GLAccNo, IsHandled);
        if IsHandled then
            exit;

        if ((GenJnlLine.Amount = 0) and (GenJnlLine."Amount (LCY)" = 0)) and (not IsGainLossAccount(GenJnlLine."Source Currency Code", GLAccNo)) then
            exit;

        TableID[1] := DATABASE::"G/L Account";
        AccNo[1] := GLAccNo;
        if DimMgt.CheckDimValuePosting(TableID, AccNo, GenJnlLine."Dimension Set ID") then begin
            OnAfterCheckGLAccDimError(GenJnlLine);
            exit;
        end;

        if GenJnlLine."Line No." <> 0 then
            Error(
              DimensionUsedErr,
              GenJnlLine.TableCaption(), GenJnlLine."Journal Template Name",
              GenJnlLine."Journal Batch Name", GenJnlLine."Line No.",
              DimMgt.GetDimValuePostingErr());

        Error(DimMgt.GetDimValuePostingErr());
    end;

    /// <summary>
    /// Sets the global variable IgnoreJournalTemplNameMandatoryCheck for the current instance of the codeunit.
    /// If IgnoreJournalTemplNameMandatoryCheck is not set "Journal Templ. Name Mandatory" check is performed before gen. journal line 
    /// </summary>
    procedure SetIgnoreJournalTemplNameMandatoryCheck()
    begin
        IgnoreJournalTemplNameMandatoryCheck := true;
    end;

    local procedure IsGainLossAccount(CurrencyCode: Code[10]; GLAccNo: Code[20]): Boolean
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit(false);

        if not Currency.Get(CurrencyCode) then
            exit(false);

        case true of
            Currency."Realized Gains Acc." = GLAccNo,
            Currency."Realized Losses Acc." = GLAccNo,
            Currency."Unrealized Gains Acc." = GLAccNo,
            Currency."Unrealized Losses Acc." = GLAccNo:
                exit(true);
        end;
    end;

    local procedure CheckGLAccDirectPosting(GenJnlLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccDirectPosting(GenJnlLine, GLAcc, IsHandled);
        if IsHandled then
            exit;

        if not GenJnlLine."System-Created Entry" then
            if GenJnlLine."Posting Date" = NormalDate(GenJnlLine."Posting Date") then
                GLAcc.TestField("Direct Posting", true);
    end;

    local procedure CalculateCurrentBalance(AccountNo: Code[20]; BalAccountNo: Code[20]; InclVATAmount: Boolean; AmountLCY: Decimal; VATAmount: Decimal)
    begin
        if (AccountNo <> '') and (BalAccountNo <> '') then
            exit;

        if AccountNo = BalAccountNo then
            exit;

        if not InclVATAmount then
            VATAmount := 0;

        if BalAccountNo <> '' then
            CurrentBalance -= AmountLCY + VATAmount
        else
            CurrentBalance += AmountLCY + VATAmount;
    end;

    /// <summary>
    /// Retrieves currency record based on the currency code.
    /// </summary>
    /// <param name="Currency">Return Value: Currency record</param>
    /// <param name="CurrencyCode">Currency code for record to be retrieved</param>
    procedure GetCurrency(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        if Currency.Code <> CurrencyCode then
            if CurrencyCode = '' then
                Clear(Currency)
            else
                Currency.Get(CurrencyCode);
    end;

    local procedure GetSourceCurrency(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        exit(Currency."Amount Rounding Precision");
    end;

    /// <summary>
    /// Populates the array AdjAmount with gen. journal lines value amount and additional currency amount.
    /// </summary>
    /// <remarks>
    /// If amount and additional currency amount values are positive array elements 1 (one) and 2 (two) are populated.
    /// For negative values array elements 3 (three) and 4 (four) are populated
    /// </remarks>
    /// <param name="AdjAmount">Return Value: array of adjustment amounts</param>
    /// <param name="Amount">Gen. journal line amount</param>
    /// <param name="AmountAddCurr">Gen. journal line amount in additional currency</param>
    procedure CollectAdjustment(var AdjAmount: array[4] of Decimal; Amount: Decimal; AmountAddCurr: Decimal)
    var
        Offset: Integer;
    begin
        Offset := GetAdjAmountOffset(Amount, AmountAddCurr);
        AdjAmount[Offset] += Amount;
        AdjAmount[Offset + 1] += AmountAddCurr;
    end;

    procedure HandleDtldAdjustment(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; AdjAmount: array[4] of Decimal; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        if not PostDtldAdjustment(
             GenJnlLine, GLEntry, AdjAmount,
             TotalAmountLCY, TotalAmountAddCurr, GLAccNo,
             GetAdjAmountOffset(TotalAmountLCY, TotalAmountAddCurr))
        then begin
            IsHandled := false;
            OnHandleDtldAdjustmentOnBeforeInitGLEntry(GenJnlLine, GLEntry, TotalAmountLCY, TotalAmountAddCurr, GLAccNo, IsHandled);
            if not IsHandled then
                if GenJnlLine."Source Currency Code" = AddCurrencyCode then
                    InitGLEntry(
                        GenJnlLine, GLEntry, GLAccNo, TotalAmountLCY, TotalAmountAddCurr, true, true, TotalAmountAddCurr)
                else
                    InitGLEntry(
                        GenJnlLine, GLEntry, GLAccNo, TotalAmountLCY, TotalAmountAddCurr, true, true,
                        CalcAmountSrcCurr(GenJnlLine, TotalAmountLCY));
        end;
    end;

    local procedure PostDtldAdjustment(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; AdjAmount: array[4] of Decimal; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAcc: Code[20]; ArrayIndex: Integer): Boolean
    var
        IsHandled: Boolean;
    begin
        if (GenJnlLine."Bal. Account No." <> '') and
           ((AdjAmount[ArrayIndex] <> 0) or (AdjAmount[ArrayIndex + 1] <> 0)) and
           ((TotalAmountLCY + AdjAmount[ArrayIndex] <> 0) or (TotalAmountAddCurr + AdjAmount[ArrayIndex + 1] <> 0))
        then begin
            IsHandled := false;
            OnPostDtldAdjustmentOnBeforeCreateGLEntryBalAcc(GenJnlLine, GLAcc, AdjAmount, ArrayIndex, IsHandled, NextEntryNo);
            if not IsHandled then begin
                GenJnlLine."Zero Src. Curr. Amount" := true;
                CreateGLEntryBalAcc(
                    GenJnlLine, GLAcc, -AdjAmount[ArrayIndex], -AdjAmount[ArrayIndex + 1],
                    GenJnlLine."Bal. Account Type", GenJnlLine."Bal. Account No.");
                GenJnlLine."Zero Src. Curr. Amount" := false;
            end;
            InitGLEntry(
                GenJnlLine, GLEntry, GLAcc, TotalAmountLCY + AdjAmount[ArrayIndex],
                TotalAmountAddCurr + AdjAmount[ArrayIndex + 1], true, true,
                CalcAmountSrcCurr(GenJnlLine, TotalAmountLCY + AdjAmount[ArrayIndex]));
            AdjAmount[ArrayIndex] := 0;
            AdjAmount[ArrayIndex + 1] := 0;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Returns offset of adjustment amount.
    /// If amount positive and amount in additional currency is greater than 0 (zero) return value will be 1. If not - return value will be 3.
    /// </summary>
    /// <param name="Amount">gen. journal line amount</param>
    /// <param name="AmountACY">gen. journal amount (in additional currency)</param>
    /// <returns>Adjustment amount offset</returns>
    procedure GetAdjAmountOffset(Amount: Decimal; AmountACY: Decimal): Integer
    begin
        if (Amount > 0) or (Amount = 0) and (AmountACY > 0) then
            exit(1);
        exit(3);
    end;

    /// <summary>
    /// Returns next entry no. that should be used when creating ledger (i.e. general, customer, vendor, etc.) entries.
    /// </summary>
    /// <returns>Returns next entry no. to be used for posting</returns>
    procedure GetNextEntryNo(): Integer
    begin
        exit(NextEntryNo);
    end;

    /// <summary>
    /// Returns next transaction no. that should be used when creating ledger (i.e. general, customer, vendor, etc.) entries.
    /// </summary>
    /// <returns>Returns next transaction no. to be used for posting</returns>
    procedure GetNextTransactionNo(): Integer
    begin
        exit(NextTransactionNo);
    end;

    /// <summary>
    /// Return next vat entry no. that should be used when creating next vat entry.
    /// </summary>
    /// <returns>Next vat entry no. to be used for posting</returns>
    procedure GetNextVATEntryNo(): Integer
    begin
        exit(NextVATEntryNo);
    end;

    /// <summary>
    /// Increases global variable NextVATEntryNo by 1 (one).
    /// </summary>
    /// <remarks>
    /// Variable NextVATEntryNo is used as entry no. when creating vat entries
    /// </remarks>
    procedure IncrNextVATEntryNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncrNextVATEntryNo(NextVATEntryNo, IsHandled);
        if IsHandled then
            exit;
        NextVATEntryNo := NextVATEntryNo + 1;
    end;

    /// <summary>
    /// Increases global variable NextEntryNo by 1 (one).
    /// </summary>
    /// <remarks>
    /// Variable NextEntryNo is used as entry no. when creating ledger entries
    /// </remarks>
    procedure IncrNextEntryNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncrNextEntryNo(NextEntryNo, IsHandled);
        if IsHandled then
            exit;
        NextEntryNo := NextEntryNo + 1;
    end;

    local procedure IsNotPayment(DocumentType: Enum "Gen. Journal Document Type") Result: Boolean
    begin
        Result := DocumentType in [DocumentType::Invoice,
                              DocumentType::"Credit Memo",
                              DocumentType::"Finance Charge Memo",
                              DocumentType::Reminder];

        OnAfterIsNotPayment(DocumentType, Result);
    end;

    /// <summary>
    /// Procedure to check if global temporary/buffer table TempGLEntryBuf is empty.
    /// </summary>
    /// <returns>True if global temporary/buffer table TempGLEntryBuf is empty</returns>
    procedure IsTempGLEntryBufEmpty(): Boolean
    begin
        exit(TempGLEntryBuf.IsEmpty);
    end;

    local procedure IsVATAdjustment(EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
    begin
        exit(EntryType in [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Adjustment)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Adjustment)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)"]);
    end;

    local procedure IsVATExcluded(EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
    begin
        exit(EntryType in [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)",
                           DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"]);
    end;

    local procedure UpdateVATEntryTaxDetails(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail"; var TaxJurisdiction: Record "Tax Jurisdiction")
    begin
        if TaxDetail."Tax Jurisdiction Code" <> '' then
            TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::Settlement then begin
            VATEntry."Tax Group Used" := TaxDetail."Tax Group Code";
            VATEntry."Tax Type" := TaxDetail."Tax Type";
            VATEntry."Tax on Tax" := TaxDetail."Calculate Tax on Tax";
        end;
        VATEntry."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";

        OnAfterUpdateVATEntryTaxDetails(VATEntry, TaxDetail);
    end;

    /// <summary>
    /// Parameter GLEntryNo is updated with value of parameter SavedEntryNo.
    /// Global variable NextEntryNo is decreased by 1 (one).
    /// </summary>
    /// <remarks>
    /// Variable NextEntryNo is used as entry no. when creating ledger entries
    /// </remarks>
    /// <param name="GLEntryNo">Existing value for g/l entry no.</param>
    /// <param name="SavedEntryNo">New value for g/l entry no.</param>
    procedure UpdateGLEntryNo(var GLEntryNo: Integer; var SavedEntryNo: Integer)
    begin
        if SavedEntryNo <> 0 then begin
            GLEntryNo := SavedEntryNo;
            NextEntryNo := NextEntryNo - 1;
            SavedEntryNo := 0;
        end;
    end;

    /// <summary>
    /// Creates/updates temporary/buffer table TempDimPostingBuffer with amount and amount in additional currency based on dimension set id.
    /// The procedure should be used to aggregate amounts by dimensions.
    /// </summary>
    /// <param name="TempDimPostingBuffer">Return Value: temporary buffer table to store amounts based on dimension set id.</param>
    /// <param name="DimSetID">Dimension set id of the transaction</param>
    /// <param name="DtldCVLedgEntryBuf">Buffer table for detailed customer/vendor ledger entries to be posted.</param>
    procedure UpdateTotalAmounts(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; DimSetID: Integer; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateTotalAmountsV19(
          TempDimPostingBuffer, DimSetID, DtldCVLedgEntryBuf."Amount (LCY)", DtldCVLedgEntryBuf."Additional-Currency Amount", IsHandled,
          DtldCVLedgEntryBuf);
        if IsHandled then
            exit;

        TempDimPostingBuffer.SetRange(TempDimPostingBuffer."Dimension Set ID", DimSetID);
        if TempDimPostingBuffer.FindFirst() then begin
            TempDimPostingBuffer.Amount += DtldCVLedgEntryBuf."Amount (LCY)";
            TempDimPostingBuffer."Amount (ACY)" += DtldCVLedgEntryBuf."Additional-Currency Amount";
            TempDimPostingBuffer.Modify();
        end else begin
            TempDimPostingBuffer.Init();
            TempDimPostingBuffer."Dimension Set ID" := DimSetID;
            TempDimPostingBuffer.Amount := DtldCVLedgEntryBuf."Amount (LCY)";
            TempDimPostingBuffer."Amount (ACY)" := DtldCVLedgEntryBuf."Additional-Currency Amount";
            TempDimPostingBuffer.Insert();
        end;
        OnAfterUpdateTotalAmounts(TempDimPostingBuffer, DtldCVLedgEntryBuf);
    end;

    local procedure CreateGLEntriesForTotalAmountsUnapply(GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; GLAccNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateGLEntriesForTotalAmountsUnapplyProcedure(GenJnlLine, TempDimPostingBuffer, GLAccNo, IsHandled);
        if IsHandled then
            exit;

        TempDimPostingBuffer.SetRange(TempDimPostingBuffer."Dimension Set ID");
        if TempDimPostingBuffer.FindSet() then
            repeat
                if (TempDimPostingBuffer.Amount <> 0) or
                   (TempDimPostingBuffer."Amount (ACY)" <> 0) and (GLSetup."Additional Reporting Currency" <> '')
                then begin
                    IsHandled := false;
                    OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeUpdateGenJnlLineDim(IsHandled);
                    if not IsHandled then
                        DimMgt.UpdateGenJnlLineDim(GenJnlLine, TempDimPostingBuffer."Dimension Set ID");
                    OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntryV19(GenJnlLine, TempDimPostingBuffer, GLAccNo);
                    CreateGLEntry(
                        GenJnlLine, GLAccNo, TempDimPostingBuffer.Amount, TempDimPostingBuffer."Amount (ACY)", true, 0);
                end;
            until TempDimPostingBuffer.Next() = 0;
    end;

    local procedure CreateGLEntriesForTotalAmounts(GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmountBuf: array[4] of Decimal; SavedEntryNo: Integer; GLAccNo: Code[20]; LedgEntryInserted: Boolean)
    var
        DimMgt: Codeunit DimensionManagement;
        GLEntryInserted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateGLEntriesForTotalAmountsV19(TempDimPostingBuffer, GenJnlLine, GLAccNo, IsHandled, AdjAmountBuf, SavedEntryNo, LedgEntryInserted);
        if IsHandled then
            exit;

        GLEntryInserted := false;

        TempDimPostingBuffer.Reset();
        if TempDimPostingBuffer.FindSet() then
            repeat
                if (TempDimPostingBuffer.Amount <> 0) or (TempDimPostingBuffer."Amount (ACY)" <> 0) and (AddCurrencyCode <> '') then begin
                    IsHandled := false;
                    OnCreateGLEntriesForTotalAmountsOnBeforeUpdateGenJnlLineDim(IsHandled);
                    if not IsHandled then
                        DimMgt.UpdateGenJnlLineDim(GenJnlLine, TempDimPostingBuffer."Dimension Set ID");
                    OnBeforeCreateGLEntryForTotalAmountsForDimPostBuf(GenJnlLine, TempDimPostingBuffer, GLAccNo);
                    CreateGLEntryForTotalAmounts(GenJnlLine, TempDimPostingBuffer.Amount, TempDimPostingBuffer."Amount (ACY)", AdjAmountBuf, SavedEntryNo, GLAccNo);
                    GLEntryInserted := true;
                end;
            until TempDimPostingBuffer.Next() = 0;

        if not GLEntryInserted and LedgEntryInserted then
            CreateGLEntryForTotalAmounts(GenJnlLine, 0, 0, AdjAmountBuf, SavedEntryNo, GLAccNo);
    end;

    local procedure CreateGLEntryForTotalAmounts(GenJnlLine: Record "Gen. Journal Line"; Amount: Decimal; AmountACY: Decimal; AdjAmountBuf: array[4] of Decimal; var SavedEntryNo: Integer; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        HandleDtldAdjustment(GenJnlLine, GLEntry, AdjAmountBuf, Amount, AmountACY, GLAccNo);
        GLEntry."Bal. Account Type" := GenJnlLine."Bal. Account Type";
        GLEntry."Bal. Account No." := GenJnlLine."Bal. Account No.";
        UpdateGLEntryNo(GLEntry."Entry No.", SavedEntryNo);

        IsHandled := false;
        OnCreateGLEntryForTotalAmountsOnBeforeInsertGLEntry(GenJnlLine, GLEntry, IsHandled, TempGLEntryVATEntryLink);
        if IsHandled then
            exit;

        InsertGLEntry(GenJnlLine, GLEntry, true);
    end;

    /// <summary>
    /// Updates additional-currency amount on buffer table DtldCVLedgEntryBuf when un-application of customer/vendor ledger entries is posted.
    /// </summary>
    /// <remarks>
    /// Amount is only updated for buffer table entry with type other than application, unrealized/realized gain/loss or correction of remaining amount
    /// </remarks>
    /// <param name="DtldCVLedgEntryBuf">Buffer table for detailed customer/vendor ledger entries to be posted.</param>
    procedure SetAddCurrForUnapplication(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
        if not (DtldCVLedgEntryBuf."Entry Type" in
                [DtldCVLedgEntryBuf."Entry Type"::Application, DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss",
                 DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain", DtldCVLedgEntryBuf."Entry Type"::"Realized Loss",
                 DtldCVLedgEntryBuf."Entry Type"::"Realized Gain", DtldCVLedgEntryBuf."Entry Type"::"Correction of Remaining Amount"])
        then
            if (DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::"Appln. Rounding") or
               ((AddCurrencyCode <> '') and (AddCurrencyCode = DtldCVLedgEntryBuf."Currency Code"))
            then
                DtldCVLedgEntryBuf."Additional-Currency Amount" := DtldCVLedgEntryBuf.Amount
            else
                DtldCVLedgEntryBuf."Additional-Currency Amount" := CalcAddCurrForUnapplication(DtldCVLedgEntryBuf."Posting Date", DtldCVLedgEntryBuf."Amount (LCY)");
    end;

    /// <summary>
    /// Checks if multiple customer posting groups exists on customer ledger entries that relate to detailed entries being created.
    /// </summary>
    /// <remarks>
    /// The check is only performed when customer ledger entries are being applied.
    /// </remarks>
    /// <param name="DetailedCVLedgEntryBuffer">Buffer table for detailed customer ledger entries to be posted.</param>
    /// <returns>Returns true if multiple customer posting groups exists for customer ledger entries being applied</returns>
    procedure CheckCustMultiplePostingGroups(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostingGroup: Code[20];
        IsHandled: Boolean;
        IsMultiplePostingGroups: Boolean;
    begin
        OnBeforeCheckCustMultiplePostingGroups(DetailedCVLedgEntryBuffer, IsMultiplePostingGroups, IsHandled);
        if IsHandled then
            exit(IsMultiplePostingGroups);
        PostingGroup := '';
        DetailedCVLedgEntryBuffer.Reset();
        DetailedCVLedgEntryBuffer.SetRange("Entry Type", DetailedCVLedgEntryBuffer."Entry Type"::Application);
        if DetailedCVLedgEntryBuffer.FindSet() then
            repeat
                CustLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
                if (PostingGroup <> '') and (PostingGroup <> CustLedgerEntry."Customer Posting Group") then
                    exit(true);
                PostingGroup := CustLedgerEntry."Customer Posting Group";
            until DetailedCVLedgEntryBuffer.Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Checks if multiple vendor posting groups exists on vendor ledger entries that relate to detailed entries being created.
    /// </summary>
    /// <remarks>
    /// The check is only performed when vendor ledger entries are being applied.
    /// </remarks>
    /// <param name="DetailedCVLedgEntryBuffer">Buffer table for detailed vendor ledger entries to be posted.</param>
    /// <returns>Returns true if multiple vendor posting groups exists for vendor ledger entries being applied</returns>
    procedure CheckVendMultiplePostingGroups(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostingGroup: Code[20];
        IsHandled: Boolean;
        IsMultiplePostingGroups: Boolean;
    begin
        OnBeforeCheckVendMultiplePostingGroups(DetailedCVLedgEntryBuffer, IsMultiplePostingGroups, IsHandled);
        if IsHandled then
            exit(IsMultiplePostingGroups);
        PostingGroup := '';
        DetailedCVLedgEntryBuffer.Reset();
        DetailedCVLedgEntryBuffer.SetRange("Entry Type", DetailedCVLedgEntryBuffer."Entry Type"::Application);
        if DetailedCVLedgEntryBuffer.FindSet() then
            repeat
                VendorLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
                if (PostingGroup <> '') and (PostingGroup <> VendorLedgerEntry."Vendor Posting Group") then
                    exit(true);
                PostingGroup := VendorLedgerEntry."Vendor Posting Group";
            until DetailedCVLedgEntryBuffer.Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Checks if multiple employee posting groups exists on employee ledger entries that relate to detailed entries being created.
    /// </summary>
    /// <remarks>
    /// The check is only performed when employee ledger entries are being applied.
    /// </remarks>
    /// <param name="DetailedCVLedgEntryBuffer">Buffer table for detailed employee ledger entries to be posted.</param>
    /// <returns>Returns true if multiple employee posting groups exists for employee ledger entries being applied</returns>
    procedure CheckEmplMultiplePostingGroups(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"): Boolean
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PostingGroup: Code[20];
    begin
        PostingGroup := '';
        DetailedCVLedgEntryBuffer.Reset();
        DetailedCVLedgEntryBuffer.SetRange("Entry Type", DetailedCVLedgEntryBuffer."Entry Type"::Application);
        if DetailedCVLedgEntryBuffer.FindSet() then
            repeat
                EmployeeLedgerEntry.Get(DetailedCVLedgEntryBuffer."CV Ledger Entry No.");
                if (PostingGroup <> '') and (PostingGroup <> EmployeeLedgerEntry."Employee Posting Group") then
                    exit(true);
                PostingGroup := EmployeeLedgerEntry."Employee Posting Group";
            until DetailedCVLedgEntryBuffer.Next() = 0;
        exit(false);
    end;

    local procedure CheckDetCustLedgEntryMultiplePostingGrOnBeforeUnapply(var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    var
        IsHandled: Boolean;
        MultiplePostingGroupsDetected: Boolean;
    begin
        OnBeforeCheckDetCustLedgEntryMultiplePostingGrOnBeforeUnapply(DetailedCustLedgEntry2, DetailedCustLedgEntry, MultiplePostingGroupsDetected, IsHandled);
        if IsHandled then
            exit(MultiplePostingGroupsDetected);

        DetailedCustLedgEntry2.SetRange("Entry Type", DetailedCustLedgEntry2."Entry Type"::Application);
        DetailedCustLedgEntry2.FindSet();
        repeat
            if DetailedCustLedgEntry2."Posting Group" <> DetailedCustLedgEntry."Posting Group" then
                exit(true);
        until DetailedCustLedgEntry2.Next() = 0;
        exit(false);
    end;

    local procedure CheckDetVendLedgEntryMultiplePostingGrOnBeforeUnapply(var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"): Boolean
    var
        IsHandled: Boolean;
        MultiplePostingGroupsDetected: Boolean;
    begin
        OnBeforeCheckDetVendLedgEntryMultiplePostingGrOnBeforeUnapply(DetailedVendorLedgEntry2, DetailedVendorLedgEntry, MultiplePostingGroupsDetected, IsHandled);
        if IsHandled then
            exit(MultiplePostingGroupsDetected);

        DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::Application);
        DetailedVendorLedgEntry2.FindSet();
        repeat
            if DetailedVendorLedgEntry2."Posting Group" <> DetailedVendorLedgEntry."Posting Group" then
                exit(true);
        until DetailedVendorLedgEntry2.Next() = 0;
        exit(false);
    end;

    local procedure CheckDetEmplLedgEntryMultiplePostingGrOnBeforeUnapply(var DetailedEmployeeLedgerEntry2: Record "Detailed Employee Ledger Entry"; var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"): Boolean
    begin
        DetailedEmployeeLedgerEntry2.SetRange("Entry Type", DetailedEmployeeLedgerEntry2."Entry Type"::Application);
        DetailedEmployeeLedgerEntry2.FindSet();
        repeat
            if DetailedEmployeeLedgerEntry2."Posting Group" <> DetailedEmployeeLedgerEntry."Posting Group" then
                exit(true);
        until DetailedEmployeeLedgerEntry2.Next() = 0;
        exit(false);
    end;

    local procedure PostDeferral(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        TempDeferralLine: Record "Deferral Line" temporary;
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
        GLEntry: Record "G/L Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralUtilities: Codeunit "Deferral Utilities";
        PerPostDate: Date;
        PeriodicCount: Integer;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        EmptyDeferralLine: Boolean;
        IsHandled: Boolean;
        DeferralSourceCode: Code[10];
        NonDeductibleVATPct: Decimal;
        VATAmountRounding: Decimal;
        PositiveNDVATAmountRounding: Decimal;
        NegativeNDVATAmountRounding: Decimal;
    begin
        IsHandled := false;
        OnBeforePostDeferral(GenJournalLine, AccountNo, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Source Type" in [GenJournalLine."Source Type"::Vendor, GenJournalLine."Source Type"::Customer] then
            // Purchasing and Sales, respectively
            // We can create these types directly from the GL window, need to make sure we don't already have a deferral schedule
            // created for this GL Trx before handing it off to sales/purchasing subsystem
            if not JournalsSourceCodesList.Contains(GenJournalLine."Source Code") then begin
                PostDeferralPostBuffer(GenJournalLine);
                exit;
            end;

        if DeferralHeader.Get(DeferralDocType::"G/L", GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.") then begin
            EmptyDeferralLine := false;
            // Get the range of detail records for this schedule
            DeferralUtilities.FilterDeferralLines(
              DeferralLine, DeferralDocType::"G/L".AsInteger(), GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.");
            if DeferralLine.FindSet() then
                repeat
                    if DeferralLine.Amount = 0 then
                        EmptyDeferralLine := true;
                until (DeferralLine.Next() = 0) or EmptyDeferralLine;
            if EmptyDeferralLine then
                Error(ZeroDeferralAmtErr, GenJournalLine."Line No.", GenJournalLine."Deferral Code");
            DeferralHeader."Amount to Defer (LCY)" :=
                Round(CurrExchRate.ExchangeAmtFCYToLCY(GenJournalLine."Posting Date", GenJournalLine."Currency Code", DeferralHeader."Amount to Defer", GenJournalLine."Currency Factor"));
            DeferralHeader.Modify();
            DeferralUtilities.RoundDeferralAmount(
                DeferralHeader, GenJournalLine."Currency Code", GenJournalLine."Currency Factor", GenJournalLine."Posting Date", AmtToDefer, AmtToDeferACY);
        end;

        DeferralTemplate.Get(GenJournalLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralTemplate.TestField("Deferral %");

        // Get the Deferral Header table so we know the amount to defer...
        // Assume straight GL posting
        if DeferralHeader.Get(DeferralDocType::"G/L", GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.") then
            // Get the range of detail records for this schedule
            DeferralUtilities.FilterDeferralLines(
                  DeferralLine, DeferralDocType::"G/L".AsInteger(), GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.")
        else
            Error(NoDeferralScheduleErr, GenJournalLine."Line No.", GenJournalLine."Deferral Code");

        DeferralSourceCode := GetGeneralDeferralSourceCode();
        InitGLEntry(
            GenJournalLine, GLEntry, AccountNo, -DeferralHeader."Amount to Defer (LCY)", -DeferralHeader."Amount to Defer", true, true,
            CalcAmountSrcCurr(GenJournalLine, -DeferralHeader."Amount to Defer (LCY)"));
        GLEntry.Description := SetDeferralDescription(GenJournalLine, DeferralLine, AccountNo);
        GLEntry."Source Code" := DeferralSourceCode;
        OnPostDeferralOnBeforeInsertGLEntryForGLAccount(GenJournalLine, DeferralLine, GLEntry, GLReg."No.");
        InsertGLEntry(GenJournalLine, GLEntry, true);

        InitGLEntry(
            GenJournalLine, GLEntry, DeferralTemplate."Deferral Account", DeferralHeader."Amount to Defer (LCY)", DeferralHeader."Amount to Defer", true, true,
            CalcAmountSrcCurr(GenJournalLine, DeferralHeader."Amount to Defer (LCY)"));
        GLEntry.Description := SetDeferralDescription(GenJournalLine, DeferralLine, DeferralTemplate."Deferral Account");
        GLEntry."Source Code" := DeferralSourceCode;
        OnPostDeferralOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine, DeferralLine, GLEntry);
        InsertGLEntry(GenJournalLine, GLEntry, true);

        if VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then
            NonDeductibleVATPct := NonDeductibleVAT.GetNonDeductibleVATPct(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group", DeferralDocType);
        OnPostDeferralOnAfterGetNonDeductibleVATPct(GenJournalLine, DeferralDocType, NonDeductibleVATPct);
        DeferralPostingBuffer.InitFromDeferralLine(DeferralLine);
        DeferralPostingBuffer."Posting Date" := GenJournalLine."Posting Date";
        DeferralPostingBuffer."G/L Account" := DeferralTemplate."Deferral Account";
        DeferralPostingBuffer."Deferral Account" := AccountNo;
        DeferralPostingBuffer.Description := SetDeferralDescriptionFromDeferralLine(DeferralLine, DeferralTemplate."Deferral Account");
        DeferralPostingBuffer."Amount (LCY)" := DeferralHeader."Amount to Defer (LCY)";
        DeferralPostingBuffer.Amount := DeferralHeader."Amount to Defer";
        InsertDeferralNonDeductibleVATGLEntries(
            NonDeductibleVATPct, DeferralPostingBuffer, VATPostingSetup, GenJournalLine, DeferralTemplate,
            VATAmountRounding, PositiveNDVATAmountRounding, NegativeNDVATAmountRounding);
        VATAmountRounding := 0;
        PositiveNDVATAmountRounding := 0;
        NegativeNDVATAmountRounding := 0;

        // Here we want to get the Deferral Details table range and loop through them...
        if DeferralLine.FindSet() then
            repeat
                TempDeferralLine := DeferralLine;
                TempDeferralLine.Insert();
            until DeferralLine.Next() = 0;
        if TempDeferralLine.FindSet() then begin
            PeriodicCount := 1;
            repeat
                PerPostDate := TempDeferralLine."Posting Date";
                CheckDeferralPostingDate(DeferralUtilities, PerPostDate);

                InitGLEntry(
                    GenJournalLine, GLEntry, AccountNo, TempDeferralLine."Amount (LCY)", TempDeferralLine.Amount, true, true,
                    CalcAmountSrcCurr(GenJournalLine, TempDeferralLine."Amount (LCY)"));
                GLEntry."Posting Date" := PerPostDate;
                GLEntry.Description := SetDeferralDescriptionFromDeferralLine(TempDeferralLine, AccountNo);
                GLEntry."Source Code" := DeferralSourceCode;
                OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount(GenJournalLine, TempDeferralLine, GLEntry);
                InsertGLEntry(GenJournalLine, GLEntry, true);

                InitGLEntry(
                    GenJournalLine, GLEntry, DeferralTemplate."Deferral Account", -TempDeferralLine."Amount (LCY)", -TempDeferralLine.Amount, true, true,
                    CalcAmountSrcCurr(GenJournalLine, -TempDeferralLine."Amount (LCY)"));
                GLEntry."Posting Date" := PerPostDate;
                GLEntry.Description := SetDeferralDescriptionFromDeferralLine(TempDeferralLine, DeferralTemplate."Deferral Account");
                GLEntry."Source Code" := DeferralSourceCode;
                OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount(GenJournalLine, TempDeferralLine, GLEntry);
                InsertGLEntry(GenJournalLine, GLEntry, true);

                DeferralPostingBuffer.InitFromDeferralLine(TempDeferralLine);
                DeferralPostingBuffer."G/L Account" := AccountNo;
                DeferralPostingBuffer."Deferral Account" := DeferralTemplate."Deferral Account";
                DeferralPostingBuffer.Description := SetDeferralDescriptionFromDeferralLine(TempDeferralLine, DeferralTemplate."Deferral Account");
                InsertDeferralNonDeductibleVATGLEntries(
                    NonDeductibleVATPct, DeferralPostingBuffer, VATPostingSetup, GenJournalLine, DeferralTemplate,
                    VATAmountRounding, PositiveNDVATAmountRounding, NegativeNDVATAmountRounding);

                PeriodicCount := PeriodicCount + 1;
                OnPostDeferralOnAfterInsertGLEntry(GenJournalLine, TempDeferralLine);
            until TempDeferralLine.Next() = 0;
            OnPostDeferralOnAfterTempDeferralLineLoopCompleted(GenJournalLine, TempDeferralLine, DeferralTemplate, DeferralHeader);
        end else
            Error(NoDeferralScheduleErr, GenJournalLine."Line No.", GenJournalLine."Deferral Code");

        OnAfterPostDeferral(GenJournalLine, TempGLEntryBuf, AccountNo);
    end;

    local procedure CheckDeferralPostingDate(var DeferralUtilities: Codeunit "Deferral Utilities"; PostingDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeferralPostDate(PostingDate, IsHandled);
        if IsHandled then
            exit;

        if DeferralUtilities.IsDateNotAllowed(PostingDate) then
            Error(InvalidPostingDateErr, PostingDate);
    end;

    local procedure PostDeferralPostBuffer(GenJournalLine: Record "Gen. Journal Line")
    var
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        NonDeductibleVATPct: Decimal;
        VATAmountRounding: Decimal;
        PositiveNDVATAmountRounding: Decimal;
        NegativeNDVATAmountRounding: Decimal;
        PostDate: Date;
        IsHandled: Boolean;
        DeferralSourceCode: Code[10];
    begin
        IsHandled := false;
        OnBeforePostDeferralPostBuffer(GenJournalLine, IsHandled);
        if not IsHandled then begin
            if GenJournalLine."Source Type" = GenJournalLine."Source Type"::Customer then begin
                DeferralDocType := DeferralDocType::Sales;
                DeferralSourceCode := GetSalesDeferralSourceCode();
            end else begin
                DeferralDocType := DeferralDocType::Purchase;
                DeferralSourceCode := GetPurchaseDeferralSourceCode();
            end;
            DeferralPostingBuffer.SetRange("Deferral Doc. Type", DeferralDocType);
            DeferralPostingBuffer.SetRange("Document No.", GenJournalLine."Document No.");
            DeferralPostingBuffer.SetRange("Deferral Line No.", GenJournalLine."Deferral Line No.");
            OnPostDeferralPostBufferOnAfterSetFilters(DeferralPostingBuffer, GenJournalLine, GLReg."No.", NextTransactionNo);
            if VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then
                NonDeductibleVATPct := NonDeductibleVAT.GetNonDeductibleVATPct(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group", DeferralDocType);
            if DeferralPostingBuffer.FindSet() then begin
                DeferralTemplate.Get(DeferralPostingBuffer."Deferral Code");
                repeat
                    OnPostDeferralPostBufferOnAfterFindDeferalPostingBuffer(GenJournalLine, DeferralPostingBuffer, NonDeductibleVATPct);
                    PostDate := DeferralPostingBuffer."Posting Date";
                    IsHandled := false;
                    OnPostDeferralPostBufferOnAfterSetPostDate(DeferralPostingBuffer, IsHandled);
                    if not IsHandled then
                        if DeferralUtilities.IsDateNotAllowed(PostDate) then
                            Error(InvalidPostingDateErr, PostDate);
                    // When no sales/purch amount is entered, the offset was already posted
                    if (DeferralPostingBuffer."Sales/Purch Amount" <> 0) or (DeferralPostingBuffer."Sales/Purch Amount (LCY)" <> 0) then begin
                        InitGLEntry(
                            GenJournalLine, GLEntry, DeferralPostingBuffer."G/L Account",
                            DeferralPostingBuffer."Sales/Purch Amount (LCY)", DeferralPostingBuffer."Sales/Purch Amount", true, true,
                            CalcAmountSrcCurr(GenJournalLine, DeferralPostingBuffer."Sales/Purch Amount (LCY)"));
                        GLEntry."Posting Date" := PostDate;
                        GLEntry.Description := SetDeferralDescriptionFromDeferralPostingBuffer(DeferralPostingBuffer, DeferralPostingBuffer."G/L Account");
                        GLEntry.CopyFromDeferralPostBuffer(DeferralPostingBuffer);
                        GLEntry."Source Code" := DeferralSourceCode;
                        OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount(GenJournalLine, DeferralPostingBuffer, GLEntry);
                        InsertGLEntry(GenJournalLine, GLEntry, true);
                    end;

                    if DeferralPostingBuffer.Amount <> 0 then begin
                        InitGLEntry(
                            GenJournalLine, GLEntry, DeferralPostingBuffer."Deferral Account",
                            -DeferralPostingBuffer."Amount (LCY)", -DeferralPostingBuffer.Amount, true, true,
                            CalcAmountSrcCurr(GenJournalLine, -DeferralPostingBuffer."Amount (LCY)"));
                        GLEntry."Posting Date" := PostDate;
                        GLEntry.Description := SetDeferralDescriptionFromDeferralPostingBuffer(DeferralPostingBuffer, DeferralPostingBuffer."Deferral Account");
                        GLEntry."Source Code" := DeferralSourceCode;
                        OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount(GenJournalLine, DeferralPostingBuffer, GLEntry);
                        InsertGLEntry(GenJournalLine, GLEntry, true);
                        OnPostDeferralPostBufferOnAfterInsertGLEntry(GenJournalLine, DeferralPostingBuffer);
                    end;
                    InsertDeferralNonDeductibleVATGLEntries(
                        NonDeductibleVATPct, DeferralPostingBuffer, VATPostingSetup, GenJournalLine, DeferralTemplate,
                        VATAmountRounding, PositiveNDVATAmountRounding, NegativeNDVATAmountRounding);
                until DeferralPostingBuffer.Next() = 0;
                OnPostDeferralPosBufferOnBeforeDeleteDeferralPostBuffer(GenJournalLine, DeferralPostingBuffer);
                DeferralPostingBuffer.DeleteAll();
            end;
        end;

        OnAfterPostDeferralPostBuffer(GenJournalLine);
    end;

    /// <summary>
    /// Removes deferral header and line associated with gen. journal line.
    /// </summary>
    /// <remarks>
    /// Deferrals are only removed if line no. on gen. journal line is specified (not 0).
    /// </remarks>
    /// <param name="GenJournalLine">General journal line that is being be posted.</param>
    procedure RemoveDeferralSchedule(GenJournalLine: Record "Gen. Journal Line")
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        // Removing deferral schedule after all deferrals for this line have been posted successfully
        DeferralUtilities.DeferralCodeOnDelete(
            Enum::"Deferral Document Type"::"G/L".AsInteger(),
            GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 0, '', GenJournalLine."Line No.");
    end;

    local procedure InsertDeferralNonDeductibleVATGLEntries(NonDeductibleVATPct: Decimal; DeferralPostingBuffer: Record "Deferral Posting Buffer"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLine: Record "Gen. Journal Line"; DeferralTemplate: Record "Deferral Template"; var VATAmountRounding: Decimal; var PositiveNDVATAmountRounding: Decimal; var NegativeNDVATAmountRounding: Decimal)
    var
        GLEntry: Record "G/L Entry";
        NonDeductibleVATAmount: Decimal;
        VATAmount: Decimal;
        UnroundedVATAmount: Decimal;
        DeferralVATAmountRounding: Decimal;
        PostingGLAccountNo: Code[20];
        DeferralGLAccountNo: Code[20];
        Sign: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDeferralNonDeductibleVATGLEntries(NonDeductibleVATPct, DeferralPostingBuffer, VATPostingSetup, GenJournalLine, DeferralTemplate, VATAmountRounding, PositiveNDVATAmountRounding, NegativeNDVATAmountRounding, IsHandled);
        if IsHandled then
            exit;

        if NonDeductibleVATPct = 0 then
            exit;

        if DeferralTemplate."Deferral Account" <> DeferralPostingBuffer."Deferral Account" then begin
            DeferralGLAccountNo := DeferralPostingBuffer."G/L Account";
            PostingGLAccountNo := DeferralPostingBuffer."Deferral Account";
            DeferralVATAmountRounding := PositiveNDVATAmountRounding;
            Sign := 1;
        end else begin
            DeferralGLAccountNo := DeferralPostingBuffer."Deferral Account";
            PostingGLAccountNo := DeferralPostingBuffer."G/L Account";
            DeferralVATAmountRounding := NegativeNDVATAmountRounding;
            Sign := -1;
        end;

        UnroundedVATAmount := VATAmountRounding + DeferralPostingBuffer."Amount (LCY)" * VATPostingSetup."VAT %" / 100;
        VATAmount := Round(UnroundedVATAmount, GLSetup."Amount Rounding Precision");
        VATAmountRounding := UnroundedVATAmount - VATAmount;

        NonDeductibleVATAmount :=
          Sign * NonDeductibleVAT.GetNonDeductibleAmount(
            VATAmount,
            NonDeductibleVATPct,
            GLSetup."Amount Rounding Precision", DeferralVATAmountRounding);

        if Sign = 1 then
            PositiveNDVATAmountRounding := DeferralVATAmountRounding
        else
            NegativeNDVATAmountRounding := DeferralVATAmountRounding;

        InitGLEntry(
            GenJournalLine, GLEntry, DeferralGLAccountNo, NonDeductibleVATAmount, NonDeductibleVATAmount, true, true,
            CalcAmountSrcCurr(GenJournalLine, NonDeductibleVATAmount));
        GLEntry."Posting Date" := DeferralPostingBuffer."Posting Date";
        GLEntry.Description := DeferralPostingBuffer.Description;
        GLEntry.CopyFromDeferralPostBuffer(DeferralPostingBuffer);
        InsertGLEntry(GenJournalLine, GLEntry, true);

        InitGLEntry(
            GenJournalLine, GLEntry, NonDeductibleVAT.GetNonDeductibleVATAccForDeferrals(DeferralDocType, PostingGLAccountNo, VATPostingSetup),
            -NonDeductibleVATAmount, -NonDeductibleVATAmount, true, true,
            CalcAmountSrcCurr(GenJournalLine, -NonDeductibleVATAmount));
        GLEntry."Posting Date" := DeferralPostingBuffer."Posting Date";
        GLEntry.Description := DeferralPostingBuffer.Description;
        GLEntry.CopyFromDeferralPostBuffer(DeferralPostingBuffer);
        InsertGLEntry(GenJournalLine, GLEntry, true);
    end;

    local procedure GetJournalsSourceCode()
    begin
        GetSourceCodeSetup();
        JournalsSourceCodesList.Add(SourceCodeSetup."General Journal");
        JournalsSourceCodesList.Add(SourceCodeSetup."Purchase Journal");
        JournalsSourceCodesList.Add(SourceCodeSetup."Sales Journal");

        OnAfterGetJournalsSourceCode(JournalsSourceCodesList);
    end;

    local procedure GetGeneralDeferralSourceCode(): Code[10]
    begin
        GetSourceCodeSetup();
        SourceCodeSetup.TestField("General Deferral");
        exit(SourceCodeSetup."General Deferral");
    end;

    local procedure GetSalesDeferralSourceCode(): Code[10]
    begin
        GetSourceCodeSetup();
        SourceCodeSetup.TestField("Sales Deferral");
        exit(SourceCodeSetup."Sales Deferral");
    end;

    local procedure GetPurchaseDeferralSourceCode(): Code[10]
    begin
        GetSourceCodeSetup();
        SourceCodeSetup.TestField("Purchase Deferral");
        exit(SourceCodeSetup."Purchase Deferral");
    end;

    procedure DeferralPosting(DeferralCode: Code[10]; SourceCode: Code[10]; AccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeferralPosting(DeferralCode, SourceCode, AccountNo, GenJournalLine, Balancing, IsHandled);
        if IsHandled then
            exit;

        if DeferralCode <> '' then begin
            // Sales and purchasing could have negative amounts, so check for them first...
            if (not JournalsSourceCodesList.Contains(SourceCode)) and
             (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor])
            then
                PostDeferralPostBuffer(GenJournalLine)
            else
                // Pure GL trx, only post deferrals if it is not a balancing entry
                if not Balancing then
                    PostDeferral(GenJournalLine, AccountNo);
            FeatureTelemetry.LogUptake('0000KLB', 'Deferral', Enum::"Feature Uptake Status"::Used);
            FeatureTelemetry.LogUsage('0000KLC', 'Deferral', 'Deferral Posted');
        end;
    end;

    local procedure SetDeferralDescription(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; GLAccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
        DeferralDescription: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDeferralDescription(GenJournalLine, DeferralLine, DeferralDescription, IsHandled, GLAccountNo);
        if IsHandled then
            exit(DeferralDescription);

        DeferralDescription := GenJournalLine.Description;
        GLAccount.Get(GLAccountNo);
        CheckDescriptionForGL(GLAccount, DeferralDescription);

        exit(DeferralDescription);
    end;

    local procedure SetDeferralDescriptionFromDeferralLine(DeferralLine: Record "Deferral Line"; GLAccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
        DeferralDescription: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDeferralDescriptionFromDeferralLine(DeferralLine, DeferralDescription, IsHandled, GLAccountNo);
        if IsHandled then
            exit(DeferralDescription);

        DeferralDescription := DeferralLine.Description;
        GLAccount.Get(GLAccountNo);
        CheckDescriptionForGL(GLAccount, DeferralDescription);

        exit(DeferralDescription);
    end;

    local procedure SetDeferralDescriptionFromDeferralPostingBuffer(DeferralPostingBuffer: Record "Deferral Posting Buffer"; GLAccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
        DeferralDescription: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDeferralDescriptionFromDeferralPostingBuffer(DeferralPostingBuffer, DeferralDescription, IsHandled, GLAccountNo);
        if IsHandled then
            exit(DeferralDescription);

        DeferralDescription := DeferralPostingBuffer.Description;
        GLAccount.Get(GLAccountNo);
        CheckDescriptionForGL(GLAccount, DeferralDescription);

        exit(DeferralDescription);
    end;

    local procedure SetPostingDimensions(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        case GLSetup."App. Dimension Posting" of
            GLSetup."App. Dimension Posting"::"No Dimensions":
                begin
                    GenJnlLine."Shortcut Dimension 1 Code" := '';
                    GenJnlLine."Shortcut Dimension 2 Code" := '';
                    GenJnlLine."Dimension Set ID" := 0;
                end;
            GLSetup."App. Dimension Posting"::"G/L Account Dimensions":
                begin
                    DimMgt.AddDimSource(
                        DefaultDimSource, DimMgt.TypeToTableID1(GenJournalAccountType::"G/L Account".AsInteger()), AccNo, true);
                    GenJnlLine.Validate("Dimension Set ID",
                        DimMgt.GetRecDefaultDimID(
                            GenJnlLine, 0, DefaultDimSource, GenJnlLine."Source Code",
                            GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code", 0, 0));
                end;
        end;
    end;

    local procedure GetPostingAccountNo(VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; UnrealizedVAT: Boolean): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then begin
            VATEntry.TestField("Tax Jurisdiction Code");
            TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    exit(TaxJurisdiction.GetSalesAccount(UnrealizedVAT));
                VATEntry.Type::Purchase:
                    begin
                        if VATEntry."Use Tax" then
                            exit(TaxJurisdiction.GetRevChargeAccount(UnrealizedVAT));
                        exit(TaxJurisdiction.GetPurchAccount(UnrealizedVAT));
                    end;
            end;
        end;

        case VATEntry.Type of
            VATEntry.Type::Sale:
                exit(VATPostingSetup.GetSalesAccount(UnrealizedVAT));
            VATEntry.Type::Purchase:
                exit(VATPostingSetup.GetPurchAccount(UnrealizedVAT));
        end;
    end;

    local procedure IsDebitAmount(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountCondition: Boolean;
        EntryAmount: Decimal;
    begin
        VATAmountCondition :=
            DtldCVLedgEntryBuf."Entry Type" in
                [DtldCVLedgEntryBuf."Entry Type"::"Payment Discount (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Tolerance (VAT Excl.)",
                 DtldCVLedgEntryBuf."Entry Type"::"Payment Discount Tolerance (VAT Excl.)"];
        if VATAmountCondition then begin
            VATPostingSetup.Get(DtldCVLedgEntryBuf."VAT Bus. Posting Group", DtldCVLedgEntryBuf."VAT Prod. Posting Group");
            VATAmountCondition := VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT";
        end;
        if VATAmountCondition then
            EntryAmount := DtldCVLedgEntryBuf."VAT Amount (LCY)"
        else
            EntryAmount := DtldCVLedgEntryBuf."Amount (LCY)";
        if Unapply then
            exit(EntryAmount > 0);
        exit(EntryAmount <= 0);
    end;

    local procedure GetVendorPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Get(GenJournalLine."Posting Group");
        OnAfterGetVendorPostingGroup(GenJournalLine, VendorPostingGroup);
    end;

    local procedure GetCustomerPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        CustomerPostingGroup.Get(GenJournalLine."Posting Group");
        OnAfterGetCustomerPostingGroup(GenJournalLine, CustomerPostingGroup);
    end;

    local procedure GetCustomerReceivablesAccount(GenJournalLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group") ReceivablesAccount: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerReceivablesAccount(GenJournalLine, CustomerPostingGroup, ReceivablesAccount, IsHandled);
        if not IsHandled then
            ReceivablesAccount := CustomerPostingGroup.GetReceivablesAccount();
        OnAfterGetCustomerReceivablesAccount(GenJournalLine, CustomerPostingGroup, ReceivablesAccount);
    end;

    local procedure GetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group") PayablesAccount: Code[20]
    begin
        PayablesAccount := VendorPostingGroup.GetPayablesAccount();
        OnAfterGetVendorPayablesAccount(GenJournalLine, VendorPostingGroup, PayablesAccount);
    end;

    local procedure GetEmployeePayablesAccount(GenJournalLine: Record "Gen. Journal Line"; EmployeePostingGroup: Record "Employee Posting Group") PayablesAccount: Code[20]
    begin
        PayablesAccount := EmployeePostingGroup.GetPayablesAccount();
        OnAfterGetEmployeePayablesAccount(GenJournalLine, EmployeePostingGroup, PayablesAccount);
    end;

    /// <summary>
    /// Sets the new value for global variable FADimAlreadyChecked.
    /// </summary>
    /// <remarks>
    /// If this value is not set (false) the dimensions are checked for restrictions when initializing new g/l entry
    /// </remarks>
    /// <param name="NewFADimAlreadyChecked">New value for global variable FADimAlreadyChecked</param>
    procedure SetFADimAlreadyChecked(NewFADimAlreadyChecked: Boolean)
    begin
        FADimAlreadyChecked := NewFADimAlreadyChecked;
    end;

    /// <summary>
    /// Sets entry no. of the global temporary/buffer table TempGLEntryBuf.
    /// </summary>
    /// <remarks>
    /// TempGLEntryBuf is a global temporary/buffer table used to accumulate all the g/l entries that will be posted
    /// </remarks>
    /// <param name="NewTempGLEntryBufEntryNo">New entry no.</param>
    procedure SetTempGLEntryBufEntryNo(NewTempGLEntryBufEntryNo: Integer)
    begin
        TempGLEntryBuf."Entry No." := NewTempGLEntryBufEntryNo;
    end;

    local procedure GetVendorPayablesAccount2(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var GenJournalLine: Record "Gen. Journal Line"; VendPostingGr: Record "Vendor Posting Group"): Code[20]
    begin
        if MultiplePostingGroups then begin
            DetailedCVLedgEntryBuffer.Reset();
            DetailedCVLedgEntryBuffer.SetFilter("Entry Type", '%1|%2', DetailedCVLedgEntryBuffer."Entry Type"::"Realized Gain", DetailedCVLedgEntryBuffer."Entry Type"::"Realized Loss");
            if DetailedCVLedgEntryBuffer.FindFirst() then
                exit(GetVendDtldCVLedgEntryBufferAccNo(GenJournalLine, DetailedCVLedgEntryBuffer));

            exit(GetVendorPayablesAccount(GenJournalLine, VendPostingGr));
        end else
            exit(GetVendorPayablesAccount(GenJournalLine, VendPostingGr));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunWithCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line"; var GLEntryNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunWithoutCheck(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line"; var GLEntryNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCode(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean; var IsPosted: Boolean; var GLReg: Record "G/L Register"; var GLEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDimError(var GenJournalLine: Record "Gen. Journal Line"; GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccDirectPosting(var GenJournalLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeferralPostDate(PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchExtDocNo(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartPosting(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccNo: Code[20]; Amount: Decimal; AmountAddCurr: Decimal; var BalAccType: Enum "Gen. Journal Account Type"; var BalAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateGLEntryBalAcc(GenJnlLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeApplyVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntryVATOnBeforeInsertGLEntry(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeStartOrContinuePosting(var GenJnlLine: Record "Gen. Journal Line"; LastDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder; LastDocNo: Code[20]; LastDate: Date; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterStartOrContinuePosting(var GenJournalLine: Record "Gen. Journal Line"; LastDocType: Enum "Gen. Journal Document Type"; LastDocNo: Code[20]; LastDate: Date; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitGLEntryVATCopyOnBeforeSummarizeVAT(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntryOnBeforeInsertGLEntry(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContinuePosting(var GenJournalLine: Record "Gen. Journal Line"; var GLRegister: Record "G/L Register"; var NextEntryNo: Integer; var NextTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustUnrealizedVAT(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; SettledAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostFixedAsset(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostGLAcc(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var GLEntryNo: Integer; var IsHandled: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostVAT(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; var AddCurrGLEntryVATAmt: Decimal; var NextConnectionNo: Integer; var TaxDetail: Record "Tax Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPmtDiscountVATByUnapply(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVend(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var Handled: Boolean; var ApplnRoundingPrecision: Decimal; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendUnrealizedVAT(var GenJnlLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; SettledAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var DtldLedgEntryInserted: Boolean; PreviewMode: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('This event is obsolete. Use OnAfterCustLedgEntryInsert instead.', '25.0')]
    [IntegrationEvent(true, false)]
    local procedure OnAfterCustLedgEntryInsertInclPreviewMode(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldLedgEntryInserted: Boolean; PreviewMode: Boolean)
    begin
    end;
#endif


    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnAfterCalcVATDifferenceLCY(GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var VATDifferenceLCY: Decimal; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnAfterSetVATAmounts(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var GLEntryAmount: Decimal; var GLEntryVATAmount: Decimal; var VATAmount: Decimal; var GLEntryBaseAmount: Decimal; var VATBase: Decimal; var SrcCurrGLEntryAmt: Decimal; var SrcCurrGLEntryVATAmt: Decimal; var SrcCurrVATAmount: Decimal; var SrcCurrGLEntryBaseAmt: Decimal; var SrcCurrVATBase: Decimal);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var DtldLedgEntryInserted: Boolean; PreviewMode: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('This event is obsolete. Use OnAfterVendLedgEntryInsert instead.', '25.0')]
    [IntegrationEvent(true, false)]
    local procedure OnAfterVendLedgEntryInsertInclPreviewMode(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var DtldLedgEntryInserted: Boolean; PreviewMode: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindAmtForAppln(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var ApplnRoundingPrecision: Decimal; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobLineSign(var GenJnlLine: Record "Gen. Journal Line"; var IsJobLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrAmount: Decimal; UseAddCurrAmount: Boolean; var CurrencyFactor: Decimal; var GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLRegister(var GLRegister: Record "G/L Register"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCustLedgEntryUnapply(var CustomerPostingGroup: Record "Customer Posting Group"; var OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlLine: Record "Gen. Journal Line"; var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGlobalGLEntry(var GLEntry: Record "G/L Entry"; var TempGLEntryBuf: Record "G/L Entry"; var NextEntryNo: Integer; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGLEntry(GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; TempGLEntryBuf: Record "G/L Entry" temporary; CalcAddCurrResiduals: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVAT(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var AddCurrGLEntryVATAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var UnrealizedVAT: Boolean; var AddCurrencyCode: Code[10]; var VATPostingSetup: Record "VAT Posting Setup"; var GLEntryAmount: Decimal; var GLEntryVATAmount: Decimal; var GLEntryBaseAmount: Decimal; var SrcCurrCode: Code[10]; var SrcCurrGLEntryAmt: Decimal; var SrcCurrGLEntryVATAmt: Decimal; var SrcCurrGLEntryBaseAmt: Decimal; AddCurrGLEntryVATAmt: Decimal; var NextConnectionNo: Integer; var NextVATEntryNo: Integer; var NextTransactionNo: Integer; TempGLEntryBufEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; GLEntryNo: Integer; var NextEntryNo: Integer; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsNotPayment(DocumentType: Enum "Gen. Journal Document Type"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostBankAcc(var GenJnlLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunWithCheck(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunWithoutCheck(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostPmtDiscountVATByUnapply(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOldCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforeCustUnrealizedVAT(CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforeUnrealizedVAT(CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; var IsAmountToApplyCheckHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOldVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeApplyVendLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Vend: Record Vendor; var IsAmountToApplyCheckHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryProcedure(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryUnapply(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldEmplLedgEntry(var DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldEmplLedgEntryUnapply(var NewDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntryProcedure(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntryUnapply(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGlobalGLEntry(var GlobalGLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register"; FiscalYearStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempVATEntry(var TempVATEntry: Record "VAT Entry" temporary; GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAmounts(var GenJnlLine: Record "Gen. Journal Line"; var Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitCheckEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitEmployeeLedgEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; SystemCreatedEntry: Boolean; Amount: Decimal; AmountAddCurr: Decimal; FADimAlreadyChecked: Boolean; var IsHandled: Boolean; var GLEntry: Record "G/L Entry"; UseAmountAddCurr: Boolean; NextEntryNo: Integer; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitVAT(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; var LCYCurrency: Record Currency; var AddCurrencyCode: Code[10]; var AddCurrGLEntryVATAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntryFromVATEntry(var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var UnrealizedVAT: Boolean; var AddCurrencyCode: Code[10]; var VATPostingSetup: Record "VAT Posting Setup"; var GLEntryAmount: Decimal; var GLEntryVATAmount: Decimal; var GLEntryBaseAmount: Decimal; var SrcCurrCode: Code[10]; var SrcCurrGLEntryAmt: Decimal; var SrcCurrGLEntryVATAmt: Decimal; var SrcCurrGLEntryBaseAmt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertVATForGLEntryFromBuffer(var GenJnlLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; VATPostingParameters: Record "VAT Posting Parameters"; var IsHandled: Boolean; var VATEntry: Record "VAT Entry"; TaxJurisdiction: Record "Tax Jurisdiction"; AddCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVATEntry(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var NextVATEntryNo: Integer; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary; var TempGLEntryBuf: Record "G/L Entry" temporary; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostUnrealVATEntry(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishPosting(var GlobalGLEntry: Record "G/L Entry"; var GLRegister: Record "G/L Register"; var IsTransactionConsistent: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGLFinishPosting(GLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; var IsTransactionConsistent: Boolean; FirstTransactionNo: Integer; var GLRegister: Record "G/L Register"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextTransactionNoNeeded(GenJnlLine: Record "Gen. Journal Line"; LastDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder; LastDocNo: Code[20]; LastDate: Date; CurrentBalance: Decimal; CurrentBalanceACY: Decimal; var NewTransaction: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer; Balancing: Boolean; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup"; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscOnAfterAssignPmtDisc(var PmtDisc: Decimal; var PmtDiscLCY: Decimal; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscOnAfterCalcPmtDisc(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var PmtDisc: Decimal; var PmtDiscLCY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtToleranceOnAfterAssignPmtDisc(var PmtTol: Decimal; var PmtTolLCY: Decimal; var PmtTolAmtToBeApplied: Decimal; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextTransactionNo: Integer; var FirstNewVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATCopyFields(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDeferral(var GenJournalLine: Record "Gen. Journal Line"; var TempGLEntryBuf: Record "G/L Entry" temporary; AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDeferral(var GenJournalLine: Record "Gen. Journal Line"; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJob(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; var IsJobLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsV19(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; GenJournalLine: Record "Gen. Journal Line"; var GLAccNo: Code[20]; var IsHandled: Boolean; AdjAmountBuf: array[4] of Decimal; SavedEntryNo: Integer; LedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyProcedure(GenJournalLine: Record "Gen. Journal Line"; var TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary; GLAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDtldCVLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Unapply: Boolean; AccNo: Code[20]; AdjAmount: array[4] of Decimal; var NextEntryNo: Integer; AddCurrencyCode: Code[10]; MultiplePostingGroups: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDtldVendVATAdjustment(GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldCVLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var AccNo: Code[20]; var Unapply: Boolean; var AdjAmount: array[4] of Decimal; var IsHandled: Boolean; AddCurrencyCode: Code[10]; MultiplePostingGroups: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldCVLedgEntryCreateGLEntryPmtDiscTol(var GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var Unapply: Boolean; var AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostCust(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostVend(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATPostingSetup: Record "VAT Posting Setup"; var TaxDetail: Record "Tax Detail"; var NextConnectionNo: Integer; var AddCurrGLEntryVATAmt: Decimal; AddCurrencyCode: Code[10]; UseCurrFactorOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmtLCYAdjustment(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAplication(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var AllApplied: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplicationOnBeforeCheckAppliedAmount(GenJournalLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var IsHandled: Boolean; ApplnRoundingPrecision: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer; AddCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextOldCustLedgEntryToApply(var GenJournalLine: Record "Gen. Journal Line"; var TempOldCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Completed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextOldEmplLedgEntryToApply(var GenJournalLine: Record "Gen. Journal Line"; var TempOldEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Completed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextOldVendLedgEntryToApply(var GenJournalLine: Record "Gen. Journal Line"; var TempOldVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var Completed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyExchRate(var GenJournalLine: Record "Gen. Journal Line"; var AddCurrencyCode: Code[10]; var UseCurrFactorOnly: Boolean; var CurrencyDate: Date; var CurrencyFactor: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDtldCustLedgEntryAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var CustomerPostingGroup: Record "Customer Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var VATEntry: Record "VAT Entry"; var AccountNo: code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetDtldVendLedgEntryAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var VendorPostingGroup: Record "Vendor Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var VATEntry: Record "VAT Entry"; var AccountNo: code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDtldEmplLedgEntryAccNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var EmployeePostingGroup: Record "Employee Posting Group"; OriginalTransactionNo: Integer; Unapply: Boolean; var AccountNo: code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerReceivablesAccount(GenJournalLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group"; var ReceivablesAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcMinimalPossibleLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPaymentExceedsLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal; var PaymentExceedsLiability: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscVATAmounts(var VATEntry: Record "VAT Entry"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnAfterCalcPmtDiscVATBases(var VATEntry: Record "VAT Entry"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATBase: Decimal; var VATBaseAddCurr: Decimal; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscVATBases(VATEntry2: Record "VAT Entry"; var VATBase: Decimal; var VATBaseAddCurr: Decimal; var NonDeductibleVATBase: Decimal; var NonDeductibleVATBaseAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnAfterCalcPmtDiscVATAmounts(var VATEntry: Record "VAT Entry"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATBase: Decimal; var VATBaseAddCurr: Decimal; var VATAmount: Decimal; var VATAmountAddCurr: Decimal; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscIfAdjVAT(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcToleratedPaymentExceedsLiability(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var MinimalPossibleLiability: Decimal; var ToleratedPaymentExceedsLiability: Boolean; var PmtTolAmtToBeApplied: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscount(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; var PmtDisc: Decimal; var PmtDiscLCY: Decimal; var PmtDiscAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var PmtDiscTol: Decimal; var PmtDiscTolLCY: Decimal; var PmtDiscTolAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtDiscToleranceProc(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PmtDiscTol: Decimal; var PmtDiscTolLCY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPmtTolerance(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var PmtTol: Decimal; var PmtTolLCY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOldDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevNewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var PrevOldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplicationOnAfterFillOldCVLedgEntryBufOpen(var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplicationOnAfterCalcShouldSetClosedFields(CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var ShouldSetClosedFields: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSettingIsTransactionConsistent(GenJournalLine: Record "Gen. Journal Line"; var IsTransactionConsistent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyApplnRounding(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf3: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCurrencyUnrealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var GenJnlLine: Record "Gen. Journal Line"; var AppliedAmount: Decimal; var RemainingAmountBeforeAppln: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtDiscPossible(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var IsHandled: Boolean; RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustPostApplyCustLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var CustLedgEntryPostApply: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntryPostApply: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendPostApplyVendLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var VendLedgEntryPostApply: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApply(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApply(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGLReg(IsTransactionConsistent: Boolean; var IsGLRegInserted: Boolean; var GLReg: Record "G/L Register"; var IsHandled: Boolean; var GenJnlLine: Record "Gen. Journal Line"; GlobalGLEntry: Record "G/L Entry"; FirstNewVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalAmountsV19(var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var DimSetID: Integer; var AmountToCollect: Decimal; var AmountACYToCollect: Decimal; var IsHandled: Boolean; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertPmtDiscVATForGLEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup"; VATAmount: Decimal; VATAmountAddCurr: Decimal; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempGLEntryVAT: Record "G/L Entry" temporary; var IsHandled: Boolean; NonDedVATAmount: Decimal; NonDedVATAmountAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntryGainLossInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyV19(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var CustomerPostingGroup: Record "Customer Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempIDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyVendorV19(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendorPostingGroup: Record "Vendor Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVAT(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLEntryVAT(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVATCopy(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATEntry: Record "VAT Entry"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGLEntryVATCopy(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostUnapply(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; VATEntryType: Enum "General Posting Type"; BilltoPaytoNo: Code[20]; TransactionNo: Integer; UnapplyVATEntries: Boolean; var TempVATEntry: Record "VAT Entry" temporary; var IsHandled: Boolean; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnrealVATEntry(GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; VATAmount: Decimal; VATBase: Decimal; GLEntryNo: Integer; var NextEntryNo: Integer; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleAddCurrResidualGLEntry(GenJournalLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCurrencyRealizedGainLoss(var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal; AppliedAmountLCY: Decimal; var RealizedGainLossLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnapplyVendLedgEntry(GenJournalLine2: Record "Gen. Journal Line"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnapplyEmplLedgEntry(GenJournalLine2: Record "Gen. Journal Line"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalAmounts(var TempDimPostingBuffer: Record "Dimension Posting Buffer"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateInitSalesTaxLines(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; SalesTaxBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATEntryTaxDetails(var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterRecalculateAmounts(var TempOldCustLedgerEntry: Record "Cust. Ledger Entry" temporary; OldCustLedgerEntry: Record "Cust. Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromOldBuf(var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; Cust: Record Customer; var ShouldUpdateCalcInterest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforeCopyFromCVLedgEntryBuffer(var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforeCopyFromCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterCalcShouldUpdateCalcInterestFromNewBuf(var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; Cust: Record Customer; var ShouldUpdateCalcInterest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnBeforePrepareTempCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryOnAfterSetApplyingDate(ApplyingDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgerEntryOnBeforeSetCompleted(var GenJournalLine: Record "Gen. Journal Line"; var OldCustLedgEntry: Record "Cust. Ledger Entry"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnAfterRecalculateAmounts(var TempOldVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; OldVendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeUnrealizedVAT(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete(var GenJournalLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; AppliedAmount: Decimal; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeCopyFromVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeOldVendLedgEntryModify(GenJnlLine: Record "Gen. Journal Line"; var OldVendLedgEntry: Record "Vendor Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryOnBeforeVendUnrealizedVAT(VendLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyEmplLedgEntryOnBeforeOldEmplLedgEntryModify(GenJnlLine: Record "Gen. Journal Line"; var OldEmplLedgEntry: Record "Employee Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntryForTotalAmountsForDimPostBuf(var GenJnlLine: Record "Gen. Journal Line"; TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryModify(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmplLedgEntryModify(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareTempCustledgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Customer: Record Customer; var ApplyingDate: Date; var Result: Boolean; var IsHandled: Boolean; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareTempVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary; Vend: Record Vendor; var ApplyingDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareTempEmplLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; Employee: Record Employee; var ApplyingDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeTestPositive(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDeferralDescription(GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var DeferralDescription: Text[100]; var IsHandled: Boolean; GLAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDeferralDescriptionFromDeferralLine(DeferralLine: Record "Deferral Line"; var DeferralDescription: Text[100]; var IsHandled: Boolean; GLAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDeferralDescriptionFromDeferralPostingBuffer(DeferralPostingBuffer: Record "Deferral Posting Buffer"; var DeferralDescription: Text[100]; var IsHandled: Boolean; GLAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummarizeVATFromInitGLEntryVAT(var GLEntry: Record "G/L Entry"; Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeVATEntryFind(var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATEntry: Record "VAT Entry"; var PmtDiscLCY2: Decimal; var PmtDiscAddCurr2: Decimal; var PmtDiscFactorLCY: Decimal; var PmtDiscFactorAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscAdjVATAmountsOnBeforeProcessVATEntry(var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAfterLoop(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertSummarizedVATAdjForPaymentDiscount(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcPmtDiscIfAdjVATOnBeforeInsertPmtDiscVATForGLEntry(var VATEntry: Record "VAT Entry"; VATEntry2: Record "VAT Entry"; DtldCVLedgEntryBuf2: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeCreateGLEntryV19(var GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var GLAccNo: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGLEntryForTotalAmountsOnBeforeInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnAfterRunExhangeAccGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var NextEntryNo: Integer; var JobLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; FirstEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnContinuePostingOnBeforeCalculateCurrentBalance(var GenJournalLine: Record "Gen. Journal Line"; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnAfterCustLedgEntryTransferFields(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforePostDtldCustLedgEntries(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinishPostingOnBeforeResetFirstEntryNo(var GLEntry: Record "G/L Entry"; NextEntryNo: Integer; FirstEntryNo: Integer; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnHandleAddCurrResidualGLEntryOnBeforeInsertGLEntry(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var TempGLEntryBuf: Record "G/L Entry"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleDtldAdjustmentOnBeforeInitGLEntry(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; TotalAmountLCY: Decimal; TotalAmountAddCurr: Decimal; GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnAfterSetGLEntryVATAmountForNormalVAT(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnBeforeVATPostingSetupCheck(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnBeforeTestFullVATAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeCheckAmountRounding(var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeAssignTempGLEntryBuf(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPmtDiscVATForGLEntryOnAfterCopyFromGenJnlLine(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempVATEntryOnBeforeInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; SourceVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATEntriesFromTempOnBeforeVATEntryInsert(var VATEntry: Record "VAT Entry"; TempVATEntry: Record "VAT Entry" temporary; GLRegister: Record "G/L Register"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnAfterAssignVATEntryFields(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToPurchAcc(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVAT: Boolean; VATAmount: Decimal; VATAmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeCreateGLEntryForReverseChargeVATToRevChargeAcc(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVAT: Boolean; var VATAmount: Decimal; var VATAmountAddCurr: Decimal; UseAmountAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATOnBeforeVATForGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntryVATAmountNotEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostApplyOnAfterRecalculateAmounts(var OldCVLedgerEntryBuffer2: Record "CV Ledger Entry Buffer"; var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; AddCurrencyCode: Code[10]; NextTransactionNo: Integer; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostBankAccOnAfterBankAccLedgEntryInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeBankAccLedgEntryInsert(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextTransactionNo: Integer; GLRegister: Record "G/L Register"; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeCheckLedgEntry2Modify(var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var CheckLedgerEntry2: Record "Check Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnAfterCheckLedgEntryInsert(var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeCheckLedgEntryInsert(var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeInitBankAccLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CurrencyFactor: Decimal; var NextEntryNo: Integer; var NextTransactionNo: Integer; var BankAccPostingGr: Record "Bank Account Posting Group")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostBankAccOnAfterCheckLedgEntrySetFilters(var CheckLedgEntry: Record "Check Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeModifyCheckLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnAfterCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; CustLedgEntry: Record "Cust. Ledger Entry"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnAfterInitCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; Cust: Record Customer; CustPostingGr: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnAfterCalcShouldCheckDocNo(var GenJournalLine: Record "Gen. Journal Line"; var ShouldCheckDocNo: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnBeforeInitCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var CustPostingGr: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnAfterTempDtldCVLedgEntryBufCopyFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Cust: Record Customer; GLReg: Record "G/L Register"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnBeforeCopyFromCustLedgEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeCopyFromCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostEmployeeOnAfterCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostVendOnBeforeInitVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var VendPostingGr: Record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendAfterTempDtldCVLedgEntryBufInit(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnBeforeCopyCVLedgEntryBuf(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostVendOnBeforeGetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group"; var PayablesAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldCVLedgEntryOnBeforeCreateGLEntryGainLoss(var GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var Unapply: Boolean; var AccNo: Code[20]; var IsHandled: Boolean; var AdjAmount: array[4] of Decimal; AddCurrencyCode: Code[10]; MultiplePostingGroups: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTol(DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCVLedgEntryOnAfterCreateGLEntryPmtDiscTolVATExcl(DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; TempGLEntryBuf: Record "G/L Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforeCreateGLEntriesForTotalAmountsV19(var CustPostingGr: Record "Customer Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmount: array[4] of Decimal; SaveEntryNo: Integer; GLAccNo: Code[20]; LedgerEntryInserted: Boolean; AddCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldEmplLedgEntriesOnBeforeUpdateTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldEmplLedgEntriesOnAfterUpdateTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldEmplLedgEntriesOnAfterCreateGLEntriesForTotalAmounts(var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(var VendPostingGr: Record "Vendor Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; var TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmountBuf: array[4] of Decimal; SavedEntryNo: Integer; LedgEntryInserted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldEmplLedgEntriesOnBeforeCreateGLEntriesForTotalAmounts(var EmplPostingGr: Record "Employee Posting Group"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; var TempDimensionPostingBuffer: Record "Dimension Posting Buffer" temporary; AdjAmountBuf: array[4] of Decimal; SavedEntryNo: Integer; LedgEntryInserted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendVATAdjustmentOnAfterFindVATEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGLAccOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGLAccOnAfterInitGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGLAccOnBeforeDeferralPosting(var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnAfterSaveGenJnlLineValues(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostFixedAssetOnBeforeAssignGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostFixedAssetOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary; GLEntry2: Record "G/L Entry"; NextEntyNo: Integer; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFixedAsset(var GenJournalLine: Record "Gen. Journal Line"; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforePostVAT(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforeInitGLEntryFromTempFAGLPostBuf(var GenJournalLine: Record "Gen. Journal Line"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforeGenJnlPostLine(GenJournalLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; NextTransactionNo: Integer; NextGLEntryNo: Integer; GLReg: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryForGLAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry"; GLRegisterNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryForDeferralAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDeferralOnAfterInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; TempDeferralLine: Record "Deferral Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDeferralOnAfterTempDeferralLineLoopCompleted(var GenJournalLine: Record "Gen. Journal Line"; TempDeferralLine: Record "Deferral Line" temporary; DeferralTemplate: Record "Deferral Template"; DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount(var GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnAfterSetFilters(var DeferralPostBuffer: Record "Deferral Posting Buffer"; GenJournalLine: Record "Gen. Journal Line"; GLRegisterNo: Integer; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDeferralPostBufferOnAfterInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDeferralPosBufferOnBeforeDeleteDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var DeferralPostBuffer: Record "Deferral Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostEmployeeOnAfterPostDtldEmplLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var DtldLedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnBeforeUnapplyVATEntry(var VATEntry: Record "VAT Entry"; var UnapplyVATEntry: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostUnapplyOnBeforeVATEntryInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; OrigVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnAfterSetFilters(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeExit(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeTestPositive(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempEmplLedgEntryOnAppToIDOnBeforeTempOldEmplLedgEntryInsert(var EmplLedgEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempEmplLedgEntryOnAppDocNoOnBeforeTempOldEmplLedgEntryInsert(var EmplLedgEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempEmplLedgEntryOnAfterSetFiltersByAppliesToId(var OldEmplLedgEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Employee: Record Employee)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFilters(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeExit(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempOldVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeTempOldVendLedgEntryInsert(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterCreateGLEntriesForTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterPostUnapply(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforePostUnapply(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterUpdateTotals(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeUpdateCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterCreateGLEntriesForTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterFilterSourceEntries(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterPostUnapply(var GenJournalLine: Record "Gen. Journal Line"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforePostUnapply(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeUpdateVendLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyEmplLedgEntryOnBeforeUpdateTotalAmounts(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterVATPartCalculation(GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; PaidAmount: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; SettledAmount: Decimal; VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterCalcPaidAmount(GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry2: Record "Cust. Ledger Entry"; SettledAmount: Decimal; var PaidAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnBeforeInitGLEntryVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; var IsHandled: Boolean; var SalesVATUnrealAccount: Code[20]; CustLedgerEntry: Record "Cust. Ledger Entry"; SettledAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterSetSalesVATAccounts(var VATEntry: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup"; var SalesVATAccount: Code[20]; var SalesVATUnrealAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnAfterVendLedgEntryTransferFields(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeCheckPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group"; var PayablesAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmployeePayablesAccount(GenJournalLine: Record "Gen. Journal Line"; EmployeePostingGroup: Record "Employee Posting Group"; var PayablesAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforePostDtldVendLedgEntries(var VendorLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeCheckPostUnrealizedVAT(var GenJournalLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var DtldLedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnAfterVATPartCalculation(GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; PaidAmount: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; SettledAmount: Decimal; VATEntry2: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnBeforeInitGLEntryVAT(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; VendorLedgerEntry: Record "Vendor Ledger Entry"; SettledAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ToRecordID: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLastDocDate(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var TempGLEntryBuf: Record "G/L Entry" temporary; var GlobalGLEntry: Record "G/L Entry"; NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete(var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var Cust: Record Customer; NextEntryNo: Integer; GLReg: Record "G/L Register"; AppliedAmount: Decimal; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnrealVATByUnapply(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscPossibleOnBeforeOriginalPmtDiscPossible(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; AmountRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCustLedgEntry: Record "Cust. Ledger Entry"; NewRemainingAmtBeforeAppln: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldVendLedgEntry: Record "Vendor Ledger Entry"; NewRemainingAmtBeforeAppln: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterApplyEmplLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldEmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerReceivablesAccount(GenJournalLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group"; var ReceivablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var CustomerPostingGroup: Record "Customer Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorPostingGroup(GenJournalLine: Record "Gen. Journal Line"; var VendorPostingGroup: Record "Vendor Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorPayablesAccount(GenJournalLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group"; var PayablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmployeePayablesAccount(GenJournalLine: Record "Gen. Journal Line"; EmployeePostingGroup: Record "Employee Posting Group"; var PayablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendUnrealizedVATAccounts(VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; var PurchVATAccount: Code[20]; var PurchVATUnrealAccount: Code[20]; var PurchReverseAccount: Code[20]; var PurchReverseUnrealAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnapplyOnAfterVATEntryInsert(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; OrigVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCalcInterestOnAfterCustLedgEntrySetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnAfterCalcTotalUnrealVATAmount(var VATEntry2: Record "VAT Entry"; var TotalUnrealVATAmountFirst: Decimal; var TotalUnrealVATAmountLast: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCustUnrealizedVATOnBeforePostUnrealVATEntry(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; var GLEntryNo: Integer; VATPart: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVendUnrealizedVATOnBeforePostUnrealVATEntry(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry2: Record "VAT Entry"; var VATAmount: Decimal; var VATBase: Decimal; var VATAmountAddCurr: Decimal; var VATBaseAddCurr: Decimal; var GLEntryNo: Integer; VATPart: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostUnrealVATByUnapplyOnBeforeVATEntryModify(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VATEntry: Record "VAT Entry"; NewVATEntry: Record "VAT Entry"; var VATEntry2: Record "VAT Entry"; var GLEntryNoFromVAT: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPmtTolerancePossible(GenJnlLine: Record "Gen. Journal Line"; PmtDiscountDate: Date; var PmtDiscToleranceDate: Date; var MaxPaymentTolerance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeferralPosting(DeferralCode: Code[10]; SourceCode: Code[10]; var AccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesExtDocNo(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchExtDocNoProcedure(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostICPartner(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterStartPosting(GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnAfterAssignCurrencyFactors(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterAssignCurrencyFactors(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostEmployeeOnAfterAssignCurrencyFactors(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitAmountsOnAddCurrencyPostingNone(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterInitVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertSummarizedVATOnAfterInsertGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempGLEntryVAT: Record "G/L Entry" temporary; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostBankAccOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; BankAccPostingGr: Record "Bank Account Posting Group"; BankAccount: Record "Bank Account"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnAfterSetGenJnlLineShortcutDimCodes(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostICPartnerOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGlEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateGLEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplication(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCustPostApplyCustLedgEntryOnAfterApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustPostApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var GLReg: Record "G/L Register"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDtldCustLedgEntryNoOffset(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldCustLedgEntryNoOffset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforeUpdateTotalAmounts(var GenJnlLine: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforePostDtldCustLedgEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; AddCurrencyCode: Code[10]; var GenJnlLine: Record "Gen. Journal Line"; CustPostingGr: Record "Customer Posting Group"; AdjAmount: array[4] of Decimal; var IsHandled: Boolean; var NextEntryNo: Integer; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; LedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVendPostApplyVendLedgEntryOnAfterApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeCopyFromVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendPostApplyVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; GLReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeUpdateTotalAmounts(var GenJnlLine: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforePostDtldVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; AdjAmount: array[4] of Decimal; var IsHandled: Boolean; LedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnAfterPostDtldVendLedgEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; LedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnUnapplyCustLedgEntryOnBeforeSecondLook(var DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; NextDtldLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterFillDtldCVLedgEntryBuf(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnUnapplyCustLedgEntryOnBeforeUpdateTotalAmounts(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDtldVendLedgEntryNoOffset(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldVendLedgEntryNoOffset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeSecondLook(var DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; NextDtldLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnAfterFillDtldCVLedgEntryBuf(var GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeUpdateTotalAmounts(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessTempVATEntryCustOnAfterProcessTempVATEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var TempVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLCalcAddCurrencyPostingNone(var GenJnlLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrency: Record Currency; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCurrencyExchRateOnAfterSetNewCurrencyDate(var GenJnlLine: Record "Gen. Journal Line"; var NewCurrencyDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCurrencyExchRate(var GenJnlLine: Record "Gen. Journal Line"; NewCurrencyDate: Date; CurrencyDate: Date; UseCurrFactorOnly: Boolean; var CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldAdjustmentOnBeforeCreateGLEntryBalAcc(var GenJnlLine: Record "Gen. Journal Line"; GLAcc: Code[20]; AdjAmount: array[4] of Decimal; ArrayIndex: Integer; var IsHandled: Boolean; NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitVATOnVATCalculationTypeNormal(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var GLEntry: Record "G/L Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostVendOnBeforePostDtldVendLedgEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnContinuePostingOnIncreaseNextTransactionNo(var GenJnlLine: Record "Gen. Journal Line"; var NextTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostEmployeeOnBeforeEmployeeLedgerEntryInsert(var GenJnlLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnBeforeResetCustLedgerEntryAppliesToFields(var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendOnAfterAssignPayablesAccount(GenJnlLine: Record "Gen. Journal Line"; VendorPostingGroup: Record "Vendor Posting Group"; var PayablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnAfterAssignReceivablesAccount(GenJnlLine: Record "Gen. Journal Line"; CustomerPostingGroup: Record "Customer Posting Group"; var ReceivablesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValueForDisposal(var GenJnlLine: Record "Gen. Journal Line"; AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUnrealizedVAT(var GenJnlLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var UnrealizedVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPmtDiscVATForGLEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustVATAdjustmentOnAfterFindVATEntry(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDtldCustVATAdjustment(GenJnlLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowInconsistentEntries(TempGLEntryPrevie: Record "G/L Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitGLEntryOnBeforeCheckGLAccDimError(var GenJnlLine: Record "Gen. Journal Line"; var GLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnAfterSetPostDate(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmplPostApplyEmplLedgEntry(var GenJnlLinePostApply: Record "Gen. Journal Line"; var EmplLedgEntryPostApply: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnapplyVendLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnapplyCustLedgEntry(GenJnlLine2: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean; var OverrideDimErr: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnapplyEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustMultiplePostingGroups(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var IsMultiplePostingGroups: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendMultiplePostingGroups(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var IsMultiplePostingGroups: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempEmplLedgEntryOnBeforeUpdateRemainingAmount(var TempOldEmployeeLedgerEntry: Record "Employee Ledger Entry"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntryReverseChargeVATInPostDtldVendVATAdjustment(DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntrySalesTaxInPostDtldVendVATAdjustment(DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnrealVATEntryOnBeforeInsertLinkSelf(var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary; var VATEntry: record "VAT Entry"; var GLEntryNo: Integer; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBankAcc(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntryVAT(var GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLEntryVATCollectAdj(var GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeCheckAgainstApplnCurrencyWithAppliesToDocNo(GenJournalLine: Record "Gen. Journal Line"; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; OldCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempCustLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; OldCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrencyWithAppliesToDocNo(GenJournalLine: Record "Gen. Journal Line"; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; OldVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; OldVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVATOnVendUnrealizedVAT(var VATEntry: Record "VAT Entry"; var GenJournalLine: Record "Gen. Journal Line"; var NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGLEntryVATOnVendUnrealizedVATForRevChargeVAT(var VATEntry: Record "VAT Entry"; var GenJournalLine: Record "Gen. Journal Line"; var NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitGLEntryVATOnBeforeSummarizeVAT(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnAfterSetFilterForVATEntry2(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustUnrealizedVATOnAfterSetFilterForVATEntry2(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDtldVendVATAdjustmentOnBeforeCreateGLEntryForNormalOrFullVAT(DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldVendLedgEntryUnapply(GenJournalLine: Record "Gen. Journal Line"; DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VendPostingGr: Record "Vendor Posting Group"; OriginalTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyVendLedgEntryOnBeforeUpdateDetailedVendLedgEntry2(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldVendLedgEntryUnapply(var OldDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var GenJnlLine: Record "Gen. Journal Line"; var NewDetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDtldCustLedgEntryUnapply(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustPostingGroup: Record "Customer Posting Group"; OriginalTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeUpdateDetailedCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DetailedCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateNormalVATGLEntries(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckGenJnlLineOnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostGLAccOnBeforePostJob(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; Balancing: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateGLEntriesForTotalAmountsUnapplyOnBeforeUpdateGenJnlLineDim(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetJournalsSourceCode(var JournalsSourceCodesList: List of [Code[10]])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateGLEntriesForTotalAmountsOnBeforeUpdateGenJnlLineDim(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnStartPostingOnBeforeSetNextVatEntryNo(var VatEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnStartPostingOnAfterSetNextVatEntryNo(var VatEntry: Record "VAT Entry"; var NextVATEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGLEntryOnBeforeUpdateCheckAmounts(GeneralLedgerSetup: Record "General Ledger Setup"; var GLEntry: Record "G/L Entry"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralPostBufferOnAfterFindDeferalPostingBuffer(var GenJournalLine: Record "Gen. Journal Line"; var DeferralPostingBuffer: Record "Deferral Posting Buffer"; var NonDeductibleVATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDeferralNonDeductibleVATGLEntries(var NonDeductibleVATPct: Decimal; DeferralPostingBuffer: Record "Deferral Posting Buffer"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLine: Record "Gen. Journal Line"; DeferralTemplate: Record "Deferral Template"; var VATAmountRounding: Decimal; var PositiveNDVATAmountRounding: Decimal; var NegativeNDVATAmountRounding: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterUpdateCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerPostingGroup: Record "Customer Posting Group"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnBeforeGetCustomerPostingGroup(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnBeforeFinishPosting(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry"; CustomerPostingGroup: Record "Customer Posting Group");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCustOnBeforeInsertDtldCVLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var TempDetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnBeforeNextEntryNo(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustomerPostingGroup: Record "Customer Posting Group"; LedgEntryInserted: Boolean; var NextEntryNo: Integer; var SavedEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnCheckingBankAccPostingGrGLAccountNo(var GenJournalLine: Record "Gen. Journal Line"; BankAccPostingGr: Record "Bank Account Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDtldCustLedgEntries(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustomerPostingGroup: Record "Customer Posting Group"; LedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitGLEntryOnBeforeCheckGLAccountBlocked(GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyCustLedgEntryOnAfterGetNextDtldLedgEntryNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldCustLedgEntriesOnAfterSetDtldCustLedgEntryNoOffset(var GenJournalLine: Record "Gen. Journal Line"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CustomerPostingGroup: Record "Customer Posting Group"; LedgEntryInserted: Boolean; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApplyOnAfterCalcCurrencyApplnRounding(GenJournalLine: Record "Gen. Journal Line"; var NewCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var NewCVLedgerEntryBuffer2: Record "CV Ledger Entry Buffer"; var OldCVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var OldCVLedgerEntryBuffer2: Record "CV Ledger Entry Buffer"; var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var AppliedAmount: Decimal; var PmtTolAmtToBeApplied: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeApplyCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeModifyCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeCheckPostUnrealizedVAT(var GenJournalLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; var DtldLedgEntryInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnUnapplyCustLedgEntryOnBeforeProcessDetailedCustLedgEntry2InLoop(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnBeforeSetDtldVendLedgEntryNoOffset(var GenJournalLine: Record "Gen. Journal Line"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDtldVendLedgEntriesOnAfterSetDtldVendLedgEntryNoOffset(var GenJournalLine: Record "Gen. Journal Line"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DtldVendLedgEntryNoOffset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendUnrealizedVATOnBeforeGetUnrealizedVATPart(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; PaidAmount: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; SettledAmount: Decimal; VATEntry2: Record "VAT Entry"; var VATPart: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAppliedAmountFromRemainingAmount(var CVLedgEntryBuffer: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAppliedAmountFromRemainingAmountOnEmptyFilter(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscBeforeInitDetailedCVLedgEntryBuff(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPmtDiscToleranceBeforeInitDetailedCVLedgEntryBuff(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDetVendLedgEntryMultiplePostingGrOnBeforeUnapply(var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var MultiplePostingGroupsDetected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDetCustLedgEntryMultiplePostingGrOnBeforeUnapply(var DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var MultiplePostingGroupsDetected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBankAccOnBeforeCheckCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNormalVATGLEntries(GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCust(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitNextEntryNo(var GLEntry: Record "G/L Entry"; var NextEntryNo: Integer; var NextTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNextEntryNo(var GLEntry: Record "G/L Entry"; var NextEntryNo: Integer; var NextTransactionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDeferralOnAfterGetNonDeductibleVATPct(GenJournalLine: Record "Gen. Journal Line"; DeferralDocType: Enum "Deferral Document Type"; var NonDeductibleVATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLSetup(var GLSetup: Record "General Ledger Setup"; var GLSetupRead: Boolean; AddCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDtldEmplLedgEntryNoOffset(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var DtldCustLedgEntryNoOffset: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnapplyEmplLedgEntryOnAfterFilterSourceEntries(var DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; var DetailedEmployeeLedgEntry2: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankAccPostingGroup(GeneralLedgerSetup: Record "General Ledger Setup"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAccDimError(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDetailedCVLedgEntryBufCalcPmtTolerance(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line"; var PmtTolAmtToBeApplied: Decimal; NextTransactionNo: Integer; FirstNewVATEntryNo: Integer; var PmtTol: Decimal; var PmtTolLCY: Decimal; var PmtTolAddCurr: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnAfterCheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGLEntriesForTotalAmountsUnapplyEmployee(DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; var EmployeePostingGroup: Record "Employee Posting Group"; GenJournalLine: Record "Gen. Journal Line"; var TempDimPostingBuffer: Record "Dimension Posting Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrNextVATEntryNo(var NextVATEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrNextEntryNo(var NextEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApplyOnAfterFindAmtForApplnOnBeforeCalcCurrencyUnrealizedGainLoss(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; var AppliedAmount: Decimal; var AppliedAmountLCY: Decimal; var OldAppliedAmount: Decimal; var ApplnRoundingPrecision: Decimal; var VATEntry: Record "VAT Entry")
    begin
    end;
}
