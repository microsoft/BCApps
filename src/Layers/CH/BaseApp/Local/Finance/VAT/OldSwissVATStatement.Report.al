// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Utilities;

report 11518 "Old Swiss VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/OldSwissVATStatement.rdlc';
    Caption = 'Swiss VAT Statement';
    Permissions = tabledata "Language Selection" = r;

    dataset
    {
        dataitem(SalesPurchaseLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            MaxIteration = 2;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(FilterTxt; FilterTxt)
            {
            }
            column(TotVATAmtMinusTotTaxAmtPlusServiceForeignAmt; TotalVATAmount - TotalTaxAmount + ServiceForeignAmount)
            {
            }
            column(TotalTaxBase; TotalTaxBase)
            {
            }
            column(TotalTaxAmount; TotalTaxAmount)
            {
            }
            column(TotalVATBase; TotalVATBase)
            {
            }
            column(TotVATAmtPlusServiceForeignAmt; TotalVATAmount + ServiceForeignAmount)
            {
            }
            column(NormVATAmountCalc; NormVATAmountCalc)
            {
            }
            column(NormalDiffAmount; NormalDiffAmount)
            {
            }
            column(ReducedVATAmountCalc; ReducedVATAmountCalc)
            {
            }
            column(SpecialVATAmountCalc; SpecialVATAmountCalc)
            {
            }
            column(ReducedDiffAmount; ReducedDiffAmount)
            {
            }
            column(SpecialDiffAmount; SpecialDiffAmount)
            {
            }
            column(ReducedRateVATAmount; ReducedRateVATAmount)
            {
            }
            column(SpecialRateVATAmount; SpecialRateVATAmount)
            {
            }
            column(NormalRateVATAmount; NormalRateVATAmount)
            {
            }
            column(NormalRateBaseAmount; NormalRateBaseAmount)
            {
            }
            column(ReducedRateBaseAmount; ReducedRateBaseAmount)
            {
            }
            column(SpecialRateBaseAmount; SpecialRateBaseAmount)
            {
            }
            column(NormalRatePerc; NormalRatePerc)
            {
            }
            column(ReducedRatePerc; ReducedRatePerc)
            {
            }
            column(SpecialRatePerc; SpecialRatePerc)
            {
            }
            column(NormalDiffAmtPlusReducedDiffAmtPlusSpecialDiffAmt; NormalDiffAmount + ReducedDiffAmount + SpecialDiffAmount)
            {
            }
            column(AmtCaption_VATEntry; "VAT Entry".FieldCaption(Amount))
            {
            }
            column(BaseCaption_VATEntry; "VAT Entry".FieldCaption(Base))
            {
            }
            column(EntryNoCaption_VATEntry; "VAT Entry".FieldCaption("Entry No."))
            {
            }
            column(AccountNumberCaption; AccountNumberCaptionLbl)
            {
            }
            column(DocNoCaption_VATEntry; "VAT Entry".FieldCaption("Document No."))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(VATStatementSwitzerlandCaption; VATStatementSwitzerlandCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(VATEntryExternalDocNoCaption; VATEntryExternalDocNoCaptionLbl)
            {
            }
            column(VATEntryTransactionNoCaption; VATEntryTransactionNoCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(PurchaseVATCaption; PurchaseVATCaptionLbl)
            {
            }
            column(ToSwissFederalTaxAdministrationPayableAmtCaption; ToSwissFederalTaxAdministrationPayableAmtCaptionLbl)
            {
            }
            column(VATSalesCaption; VATSalesCaptionLbl)
            {
            }
            column(NormalRateCaption; NormalRateCaptionLbl)
            {
            }
            column(ReducedRateCaption; ReducedRateCaptionLbl)
            {
            }
            column(SpecialRateCaption; SpecialRateCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            column(VATAmtCaption; VATAmtCaptionLbl)
            {
            }
            column(PostedVATAmtCaption; PostedVATAmtCaptionLbl)
            {
            }
            column(RoundingDiffAndRateChangeCaption; RoundingDiffAndRateChangeCaptionLbl)
            {
            }
            column(VATRateChangeCaption; VATRateChangeCaptionLbl)
            {
            }
            column(VATAmtCalculatedCaption; VATAmtCalculatedCaptionLbl)
            {
            }
            column(VATCaption; VATCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(VATBaseAmtCaption; VATBaseAmtCaptionLbl)
            {
            }
            dataitem("VAT Posting Setup"; "VAT Posting Setup")
            {
                DataItemTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                PrintOnlyIfDetail = true;
                column(TitleTxt; TitleTxt)
                {
                }
                column(ShowEntries; ShowEntries)
                {
                }
                column(VATGroupTxt; VATGroupTxt)
                {
                }
                column(VAT_VATPostingSetup; "VAT %")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(GLacc; GLacc)
                {
                }
                column(NewVATTxt; NewVATTxt)
                {
                }
                column(Base_VATEntry; "VAT Entry".Base)
                {
                }
                column(Amt_VATEntry; "VAT Entry".Amount)
                {
                }
                column(Total; TotalTxt + ' ' + TitleTxt)
                {
                }
                column(VATGroupTxtCaption; VATGroupTxtCaptionLbl)
                {
                }
                column(VATCaption_VATPostingSetup; FieldCaption("VAT %"))
                {
                }
                column(GLaccCaption; GLaccCaptionLbl)
                {
                }
                column(VATBusPostingGrp_VATPostingSetup; "VAT Bus. Posting Group")
                {
                }
                column(VATProdPostingGrp_VATPostingSetup; "VAT Prod. Posting Group")
                {
                }
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = sorting(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Jurisdiction Code");
                    column(EntryNo_VATEntry; "Entry No.")
                    {
                    }
                    column(PostingDate_VATEntry; Format("Posting Date"))
                    {
                    }
                    column(DocNo_VATEntry; "Document No.")
                    {
                    }
                    column(DocType_VATEntry; CopyStr(Format("Document Type"), 1, 1))
                    {
                    }
                    column(AccountNumber; AccountNumber)
                    {
                    }
                    column(BookTxt; BookTxt)
                    {
                    }
                    column(ExternalDocNo_VATEntry; "External Document No.")
                    {
                    }
                    column(AccountType; AccountType)
                    {
                    }
                    column(TransactionNo_VATEntry; "Transaction No.")
                    {
                    }
                    column(Type_VATEntry; CopyStr(Format(Type), 1, 4))
                    {
                    }
                    column(TransferCaption; TransferCaptionLbl)
                    {
                    }
                    column(TotalGroupCaption; TotalGroupCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        ExitLoop: Boolean;
                    begin
                        // Proceed VAT Entries inside Filter

                        if Sales then begin
                            Amount := -Amount;
                            Base := -Base;

                            if ("VAT Bus. Posting Group" = VAT040BusGr) and (VAT040BusGr <> '') then
                                NoVAT040 := NoVAT040 + Base;
                        end;

                        if not TempVATCurrencyAdjustmentBuffer.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then begin
                            TempVATCurrencyAdjustmentBuffer.Init();
                            TempVATCurrencyAdjustmentBuffer."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
                            TempVATCurrencyAdjustmentBuffer."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                            TempVATCurrencyAdjustmentBuffer.Insert();
                        end;
                        if Sales then begin
                            if not "Exchange Rate Adjustment" then
                                TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt." :=
                                  TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt." + Base;
                            TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt. Adj." :=
                              TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt. Adj." + Base;
                        end else begin
                            if not "Exchange Rate Adjustment" then
                                TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt." :=
                                  TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt." + Base;
                            TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt. Adj." :=
                              TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt. Adj." + Base;
                        end;
                        TempVATCurrencyAdjustmentBuffer.Modify();
                        if "Exchange Rate Adjustment" then
                            CurrencyAdjusted := true;

                        // PostingText
                        BookTxt := '';
                        AccountType := '';
                        AccountNumber := '';

                        // Get Customer- oder Vendorname
                        if "Bill-to/Pay-to No." <> '' then
                            if Sales then begin
                                if Customer.Get("Bill-to/Pay-to No.") then begin
                                    BookTxt := Customer.Name;
                                    AccountType := 'D';
                                    AccountNumber := "Bill-to/Pay-to No.";
                                end;
                            end else
                                if Vendor.Get("Bill-to/Pay-to No.") then begin
                                    BookTxt := Vendor.Name;
                                    AccountType := 'K';
                                    AccountNumber := "Bill-to/Pay-to No.";
                                end;

                        // If No Cus/Vend Name found, klook into GL/Ledger Entries
                        if (BookTxt = '') and (not "Exchange Rate Adjustment") then begin
                            "G/L Entry".Reset();
                            "G/L Entry".SetCurrentKey("Transaction No.");
                            "G/L Entry".SetRange("Transaction No.", "Transaction No.");
                            "G/L Entry".SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                            "G/L Entry".SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");

                            if Sales then
                                "G/L Entry".SetRange(Amount, -Base)
                            else
                                "G/L Entry".SetRange(Amount, Base);

                            if "G/L Entry".Find('-') then
                                repeat
                                    BookTxt := "G/L Entry".Description;
                                    AccountType := 'F';
                                    AccountNumber := "G/L Entry"."G/L Account No.";
                                    GLEntry2.Get("G/L Entry"."Entry No.");
                                    if GLEntry2.Mark() then
                                        "G/L Entry".Next()
                                    else begin
                                        ExitLoop := true;
                                        GLEntry2.Mark(true);
                                    end;
                                until ExitLoop;
                        end;

                        EntriesCounter := EntriesCounter + 1;
                        Window.Update(3, Format(EntriesCounter));

                        TmpBase := TmpBase + Base;
                        TmpBaseSetup := TmpBaseSetup + Base;
                        TmpAmount := TmpAmount + Amount;
                        TmpAmountSetup := TmpAmountSetup + Amount;

                        // Store SUM of the CalcFields for every Salesgroup for the Form
                        Base := TmpBase;
                        TmpBase := 0;
                        Amount := TmpAmount;
                        TmpAmount := 0;
                        if Sales then begin
                            case "VAT Posting Setup"."VAT %" of
                                0: // No VAT
                                    NoVATBaseAmount := NoVATBaseAmount + Base;
                                NormalRatePerc:
                                    begin
                                        NormalRateBaseAmount := NormalRateBaseAmount + Base;
                                        NormalRateVATAmount := NormalRateVATAmount + Amount;
                                    end;
                                ReducedRatePerc:
                                    begin
                                        ReducedRateBaseAmount := ReducedRateBaseAmount + Base;
                                        ReducedRateVATAmount := ReducedRateVATAmount + Amount;
                                    end;
                                SpecialRatePerc:
                                    begin
                                        SpecialRateBaseAmount := SpecialRateBaseAmount + Base;
                                        SpecialRateVATAmount := SpecialRateVATAmount + Amount;
                                    end;
                            end;

                            if "VAT Posting Setup"."VAT Calculation Type" = "VAT Posting Setup"."VAT Calculation Type"::"Full VAT" then
                                SalesFull := SalesFull + Amount;

                            // Sum own consumption
                            if OwnConsumptionBusGroup <> '' then
                                if "VAT Posting Setup"."VAT Bus. Posting Group" = OwnConsumptionBusGroup then
                                    OwnConsumptionBaseAmount := OwnConsumptionBaseAmount + Base;
                        end else begin
                            // Split Tax Mat/Betrieb based on GLAccount
                            if "VAT Posting Setup"."Purchase VAT Account" = InvFactTaxGLAcc then
                                InvFactTaxAmount := InvFactTaxAmount + Amount
                            else
                                MatServiceTaxAmount := MatServiceTaxAmount + Amount;

                            if ServiceForeignBusGr <> '' then
                                if "VAT Posting Setup"."VAT Bus. Posting Group" = ServiceForeignBusGr then
                                    if "VAT Posting Setup"."VAT Calculation Type" =
                                       "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT"
                                    then begin
                                        ServiceForeignBaseAmount := ServiceForeignBaseAmount + Base;
                                        ServiceForeignAmount := ServiceForeignAmount + Amount;
                                    end;
                        end;
                        NormVATAmountCalc := NormalRateBaseAmount / 100 * NormalRatePerc;
                        NormalDiffAmount := NormalRateVATAmount - NormVATAmountCalc;
                        ReducedVATAmountCalc := ReducedRateBaseAmount / 100 * ReducedRatePerc;
                        ReducedDiffAmount := ReducedRateVATAmount - ReducedVATAmountCalc;
                        SpecialVATAmountCalc := SpecialRateBaseAmount / 100 * SpecialRatePerc;
                        SpecialDiffAmount := SpecialRateVATAmount - SpecialVATAmountCalc;

                        if Sales then begin
                            TotalVATBase := TmpBaseSetup;
                            TotalVATAmount := NormVATAmountCalc + ReducedVATAmountCalc + SpecialVATAmountCalc + SalesFull;
                        end else begin
                            TotalTaxBase := TmpBaseSetup;
                            TotalTaxAmount := TmpAmountSetup;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        // proceed VAT Entries
                        Clear(Base);
                        Clear(Amount);
                        // SORTING(Type,Closed,VAT Bus. Posting Group,VAT Prod. Posting Group,Tax Jurisdiction Code) on Table View
                        SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                        SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");
                        if Sales then
                            SetRange(Type, Type::Sale)
                        else
                            SetRange(Type, Type::Purchase);

                        // Filter Open or Closed Entries
                        if OpenTillDate > 0D then begin
                            SetRange(Closed, false);
                            SetRange("Posting Date", 0D, OpenTillDate);
                        end else begin
                            BalanceVATEntry2.SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
                            BalanceVATEntry2.SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                            BalanceVATEntry2.SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");

                            FoundBalanceEntries := false;
                            if BalanceVATEntry2.Find('-') then
                                repeat
                                    SetRange("Closed by Entry No.", BalanceVATEntry2."Entry No.");
                                    SetRange(Closed, true);
                                    if Find('-') then
                                        if (Sales and (Type = Type::Sale)) or
                                           ((not Sales) and (Type = Type::Purchase))
                                        then
                                            FoundBalanceEntries := true;
                                until FoundBalanceEntries or (BalanceVATEntry2.Next() = 0);

                            if not FoundBalanceEntries then
                                CurrReport.Break();
                        end;
                        TmpBase := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    // go through all VAT combination
                    // Wrong Group (Sales/Purchase) will be skippen with PrintOnlyIfDetail
                    VATGroupTxt := "VAT Bus. Posting Group" + ' / ' + "VAT Prod. Posting Group";

                    if Sales then
                        GLacc := "VAT Posting Setup"."Sales VAT Account"
                    else
                        GLacc := "VAT Posting Setup"."Purchase VAT Account";

                    Window.Update(1, "VAT Bus. Posting Group");
                    Window.Update(2, "VAT Prod. Posting Group");
                end;

                trigger OnPostDataItem()
                begin
                    TmpAmountSetup := 0;
                    TmpBaseSetup := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // RUN VAT Setup 2 x. 1 = Sales, 2 = Purchase
                if Number = 1 then begin
                    TitleTxt := VATSalesTxt;
                    Sales := true;
                end else begin
                    TitleTxt := VATPurchaseTxt;
                    Sales := false;
                end;

                Window.Open(ProcessVATStatementMsg + BusinessPostingGroupMsg + ProductPostingGroupMsg + NumberOfEntriesMsg);
            end;

            trigger OnPreDataItem()
            var
                DateCreated: Date;
            begin
                GLSetup.Get();
                if GLSetup."Unrealized VAT" then
                    if not Confirm(UnrealizedVATQst, false, CompanyName) then
                        Error(ProcessCancelledErr);

                // Check, one field musst be filled
                if ((ClosedWithJournalnumber > 0) and (OpenTillDate > 0D)) or
                   ((ClosedWithJournalnumber = 0) and (OpenTillDate = 0D))
                then
                    Error(ProcessNotificationErr);

                // Check chosed Journal
                if ClosedWithJournalnumber > 0 then begin
                    GLRegister.Get(ClosedWithJournalnumber);

                    BalanceVATEntry2.SetRange(Type, BalanceVATEntry2.Type::Settlement);
                    if not BalanceVATEntry2.Find('-') then
                        Error(VATStatPostedErr);

                    // Has the chosed GLRegister Source Code to Balance VAT Entry?
                    if GLRegister."Source Code" <> BalanceVATEntry2."Source Code" then
                        Error(NotVATSettlementErr, GLRegister."No.", BalanceVATEntry2."Source Code");

                    if GLRegister.SystemCreatedAt <> 0DT then
                        DateCreated := DT2Date(GLRegister.SystemCreatedAt)
                    else
                        DateCreated := GLRegister."Creation Date";
                    FilterTxt := StrSubstNo(ClosedEntriesTxt, GLRegister."No.", DateCreated);
                end else
                    FilterTxt := StrSubstNo(OpenEntriesTxt, OpenTillDate);

                // Purchase VAT  GLAccount defined?
                if InvFactTaxGLAcc = '' then
                    if not Confirm(AccountNotDefinedQst) then
                        Error(ProcessCancelledErr);
            end;
        }
        dataitem(BalanceVATEntry; "VAT Entry")
        {
            DataItemTableView = sorting("Entry No.");
            column(Amt_BalanceVATEntries; Amount)
            {
            }
            column(Base_BalanceVATEntries; Base)
            {
            }
            column(EntryNo_BalanceVATEntries; "Entry No.")
            {
            }
            column(TransactionNo_BalanceVATEntries; "Transaction No.")
            {
            }
            column(DocNo_BalanceVATEntries; "Document No.")
            {
            }
            column(PostingDate_BalanceVATEntries; Format("Posting Date"))
            {
            }
            column(VATBusPostingGrp_BalanceVATEntries; "VAT Bus. Posting Group")
            {
            }
            column(VATProdPostingGrp_BalanceVATEntries; "VAT Prod. Posting Group")
            {
            }
            column(VATChargebackCaption; VATChargebackCaptionLbl)
            {
            }
            column(AmountCaption_BalanceVATEntries; FieldCaption(Amount))
            {
            }
            column(BaseCaption_BalanceVATEntries; FieldCaption(Base))
            {
            }
            column(EntryNoCaption_BalanceVATEntries; FieldCaption("Entry No."))
            {
            }
            column(VATEntryTransactionNoCaption_BalanceVATEntries; VATEntryTransactionNoCaptionLbl)
            {
            }
            column(DocNoCaption_BalanceVATEntries; FieldCaption("Document No."))
            {
            }
            column(GroupTextCaption; GroupTextCaptionLbl)
            {
            }
            column(VATStatementSwitzerlandChargebackCaption; VATStatementSwitzerlandChargebackCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(BalanceTaxLiabilityCaption; BalanceTaxLiabilityCaptionLbl)
            {
            }

            trigger OnPreDataItem()
            begin
                Clear(Base);
                Clear(Amount);
                SetRange("Entry No.", GLRegister."From VAT Entry No.", GLRegister."To VAT Entry No.");
            end;
        }
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Entry No.");
            column(ShowBalanceEntries; ShowBalanceEntries)
            {
            }
            column(EntryNo_GLEntry; "Entry No.")
            {
            }
            column(GLAcctNo_GLEntry; "G/L Account No.")
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date"))
            {
            }
            column(DocNo_GLEntry; "Document No.")
            {
            }
            column(Desc_GLEntry; Description)
            {
            }
            column(Amt_GLEntry; Amount)
            {
            }
            column(TransactionNo_GLEntry; "Transaction No.")
            {
            }
            column(Name_GLAcct; GLAccount.Name)
            {
            }
            column(GLChargebackCaption; GLChargebackCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                // Gett Account Name
                if not GLAccount.Get("G/L Account No.") then
                    GLAccount.Init();
            end;

            trigger OnPreDataItem()
            begin
                // all GL Entries of the Journal
                SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
            end;
        }
        dataitem(CurrAdj; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(ComapnyName_CurrAdj; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterTxt_CurrAdj; FilterTxt)
            {
            }
            column(TodayFormatted_CurrAdj; Format(Today, 0, 4))
            {
            }
            column(CurrencyAdjusted; CurrencyAdjusted)
            {
            }
            column(VATPurchBaseAmtAdj_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt. Adj.")
            {
            }
            column(VATPurchBaseAmt_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."VAT Purch. Base Amt.")
            {
            }
            column(VATSalesBaseAmtAdj_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt. Adj.")
            {
            }
            column(VATSalesBaseAmt_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."VAT Sales Base Amt.")
            {
            }
            column(GenProdPostingGrp_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."Gen. Prod. Posting Group")
            {
            }
            column(GenBusPostingGrp_TempVATCurrencyAdjustmentBuffer; TempVATCurrencyAdjustmentBuffer."Gen. Bus. Posting Group")
            {
            }
            column(VATStatementSwitzerlandChargebackCaption_CurrAdj; VATStatementSwitzerlandChargebackCaptionLbl)
            {
            }
            column(PageNoAdjCaption_CurrAdj; PageNoCaptionLbl)
            {
            }
            column(PurchInvBaseCaption; PurchInvBaseCaptionLbl)
            {
            }
            column(PurchAdjBaseCaption; PurchAdjBaseCaptionLbl)
            {
            }
            column(SalesAdjBaseCaption; SalesAdjBaseCaptionLbl)
            {
            }
            column(SalesInvBaseCaption; SalesInvBaseCaptionLbl)
            {
            }
            column(ProdPostGrCaption; ProdPostGrCaptionLbl)
            {
            }
            column(ExchangeRateAdjustmentsCaption; ExchangeRateAdjustmentsCaptionLbl)
            {
            }
            column(BusinessPostGrCaption; BusinessPostGrCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if NotFirstEntry then
                    if TempVATCurrencyAdjustmentBuffer.Next() = 0 then
                        CurrReport.Break();
                NotFirstEntry := true;
            end;

            trigger OnPreDataItem()
            begin
                if not CurrencyAdjusted then
                    CurrReport.Break();

                TempVATCurrencyAdjustmentBuffer.Find('-');
            end;
        }
        dataitem(VATStatementForm; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(TotalVATBaseMinusOwnConsumptionBaseAmt; TotalVATBase - OwnConsumptionBaseAmount)
            {
            }
            column(NoVAT043; NoVAT043)
            {
            }
            column(AssessableVolume; AssessableVolume)
            {
            }
            column(MatServiceTaxAmount; MatServiceTaxAmount)
            {
            }
            column(InvFactTaxAmount; InvFactTaxAmount)
            {
            }
            column(MinusToPayAssessableAmount; -ToPayAssessableAmount)
            {
            }
            column(TotalVATBase_VATStatementForm; TotalVATBase)
            {
            }
            column(NoVATBaseAmount; NoVATBaseAmount)
            {
            }
            column(ToPayAssessableAmount; ToPayAssessableAmount)
            {
            }
            column(TodayFormatted_VATStatementForm; Format(Today, 0, 4))
            {
            }
            column(VATRegNo_CompanyInformation; CompanyInformation."VAT Registration No.")
            {
            }
            column(OwnConsumptionBaseAmount; OwnConsumptionBaseAmount)
            {
            }
            column(ServiceForeignBaseAmount; ServiceForeignBaseAmount)
            {
            }
            column(ServiceForeignAmount; ServiceForeignAmount)
            {
            }
            column(NoVAT040; NoVAT040)
            {
            }
            column(OwnConsumptionBusGroup; OwnConsumptionBusGroup)
            {
            }
            column(SalesVolumeCaption; SalesVolumeCaptionLbl)
            {
            }
            column(ICaption; ICaptionLbl)
            {
            }
            column(TotAgreedHiresCaption; TotAgreedHiresCaptionLbl)
            {
            }
            column(DeductionsCaption; DeductionsCaptionLbl)
            {
            }
            column(ServicesInForeignCountriesCaption; ServicesInForeignCountriesCaptionLbl)
            {
            }
            column(AssessableVolumeCaption; AssessableVolumeCaptionLbl)
            {
            }
            column(IICaption; IICaptionLbl)
            {
            }
            column(TaxSettlementCaption; TaxSettlementCaptionLbl)
            {
            }
            column(DeliveriesServicesAndConsumptionCaption; DeliveriesServicesAndConsumptionCaptionLbl)
            {
            }
            column(SplitOfFigure60IntoTaxRateCaption; SplitOfFigure60IntoTaxRateCaptionLbl)
            {
            }
            column(AccommodationServicesCaption; AccommodationServicesCaptionLbl)
            {
            }
            column(TotalTaxCaption; TotalTaxCaptionLbl)
            {
            }
            column(AccountablePurchaseTaxCaption; AccountablePurchaseTaxCaptionLbl)
            {
            }
            column(MaterialAndServiceExpensesCaption; MaterialAndServiceExpensesCaptionLbl)
            {
            }
            column(InvestmentsAndRemainingOperatingExpenditureCaption; InvestmentsAndRemainingOperatingExpenditureCaptionLbl)
            {
            }
            column(TotalPurchaseVATCaption; TotalPurchaseVATCaptionLbl)
            {
            }
            column(AssetsOfTheTaxpayerCaption; AssetsOfTheTaxpayerCaptionLbl)
            {
            }
            column(LikeFigure060Caption; LikeFigure060CaptionLbl)
            {
            }
            column(Figure030Minus050Caption; Figure030Minus050CaptionLbl)
            {
            }
            column(Figure070until074Plus090Caption; Figure070until074Plus090CaptionLbl)
            {
            }
            column(Figure100Minus140Caption; Figure100Minus140CaptionLbl)
            {
            }
            column(Figure110Plus111Caption; Figure110Plus111CaptionLbl)
            {
            }
            column(Figure140Minus100Caption; Figure140Minus100CaptionLbl)
            {
            }
            column(VATStatementCaption; VATStatementCaptionLbl)
            {
            }
            column(TaxRateCaption; TaxRateCaptionLbl)
            {
            }
            column(V010Caption; V010CaptionLbl)
            {
            }
            column(FigureCaption; FigureCaptionLbl)
            {
            }
            column(V043To045Caption; V043To045CaptionLbl)
            {
            }
            column(V050Caption; V050CaptionLbl)
            {
            }
            column(V060Caption; V060CaptionLbl)
            {
            }
            column(V070Caption; V070CaptionLbl)
            {
            }
            column(V071Caption; V071CaptionLbl)
            {
            }
            column(V074Caption; V074CaptionLbl)
            {
            }
            column(V080Caption; V080CaptionLbl)
            {
            }
            column(V100Caption; V100CaptionLbl)
            {
            }
            column(V110Caption; V110CaptionLbl)
            {
            }
            column(V111Caption; V111CaptionLbl)
            {
            }
            column(V140Caption; V140CaptionLbl)
            {
            }
            column(VolumeFrCaption; VolumeFrCaptionLbl)
            {
            }
            column(TaxFrRpCaption; TaxFrRpCaptionLbl)
            {
            }
            column(VATNumberCaption; VATNumberCaptionLbl)
            {
            }
            column(ConsolidatedCaption; ConsolidatedCaptionLbl)
            {
            }
            column(V150Caption; V150CaptionLbl)
            {
            }
            column(V160Caption; V160CaptionLbl)
            {
            }
            column(OwnConsumptionCaption; OwnConsumptionCaptionLbl)
            {
            }
            column(V020Caption; V020CaptionLbl)
            {
            }
            column(PurchOfServicesFromForeignCountriesCaption; PurchOfServicesFromForeignCountriesCaptionLbl)
            {
            }
            column(V090Caption; V090CaptionLbl)
            {
            }
            column(TotalSalesVolumeCaption; TotalSalesVolumeCaptionLbl)
            {
            }
            column(V030Caption; V030CaptionLbl)
            {
            }
            column(TotalDeductionsCaption; TotalDeductionsCaptionLbl)
            {
            }
            column(V042Caption; V042CaptionLbl)
            {
            }
            column(V040Caption; V040CaptionLbl)
            {
            }
            column(PurchPriceOfItemsMarginTaxingCaption; PurchPriceOfItemsMarginTaxingCaptionLbl)
            {
            }
            column(TaxFreeVolumeCaption; TaxFreeVolumeCaptionLbl)
            {
            }
            column(SalesVolumeOutgoingInvoice; TotalVATBase - OwnConsumptionBaseAmount)
            {
            }
            column(SalesVolumeOwnConsumption; OwnConsumptionBaseAmount)
            {
            }
            column(SalesVolumeTotal; TotalVATBase)
            {
            }
            column(SalesVolumeTaxFree; NoVAT043)
            {
            }
            column(SalesVolumeTotalDeduction; NoVATBaseAmount)
            {
            }
            column(SalesVolumeAssessableVolume; AssessableVolume)
            {
            }
            column(DeliveriesNormalRateBaseAmount; NormalRateBaseAmount)
            {
            }
            column(DeliveriesNormVATAmountCalc; NormVATAmountCalc)
            {
            }
            column(DeliveriesReducedRateBaseAmount; ReducedRateBaseAmount)
            {
            }
            column(DeliveriesReducedVATAmountCalc; ReducedVATAmountCalc)
            {
            }
            column(AccomodationSpecialRateBaseAmount; SpecialRateBaseAmount)
            {
            }
            column(AccomodationSpecialVATAmountCalc; SpecialVATAmountCalc)
            {
            }
            column(VATStatementFormAssessableVolume; AssessableVolume)
            {
            }
            column(VATStatementFormTotalTax; TotalVATAmount + ServiceForeignAmount)
            {
            }

            trigger OnAfterGetRecord()
            begin
                // VAT Form Base
                CompanyInformation.Get();

                if TotalVATBase <> NormalRateBaseAmount + ReducedRateBaseAmount + SpecialRateBaseAmount + NoVATBaseAmount then
                    Message(WarningMsg);

                AssessableVolume := TotalVATBase - NoVATBaseAmount;
                ToPayAssessableAmount := TotalVATAmount - TotalTaxAmount + ServiceForeignAmount;

                NoVAT043 := NoVATBaseAmount - NoVAT040;
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
                    field(ClosedWithJournalnumber; ClosedWithJournalnumber)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Closed with Journal no.';
                        ToolTip = 'Specifies the general ledger journals that contain the posting source of the VAT adjusting entries. This field evaluates accounting periods that have already been settled.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            BalanceVATEntry2.SetRange(Type, BalanceVATEntry2.Type::Settlement);

                            if BalanceVATEntry2.Find('-') then
                                GLRegister.SetRange("Source Code", BalanceVATEntry2."Source Code");

                            if PAGE.RunModal(0, GLRegister) = ACTION::LookupOK then begin
                                ClosedWithJournalnumber := GLRegister."No.";
                                OpenTillDate := 0D;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if ClosedWithJournalnumber > 0 then
                                OpenTillDate := 0D;
                        end;
                    }
                    field(OpenTillDate; OpenTillDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open until date';
                        ToolTip = 'Specifies the last date for settling open or unsettled VAT entries.';

                        trigger OnValidate()
                        begin
                            if OpenTillDate > 0D then
                                ClosedWithJournalnumber := 0;
                        end;
                    }
                    field(ShowEntries; ShowEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Postings';
                        ToolTip = 'Specifies if all of the VAT entries for each group will be printed.';
                    }
                    field(ShowBalanceEntries; ShowBalanceEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Chargeback';
                        ToolTip = 'Specifies if you want to include VAT entries and general ledger entries with closed summary or tax reposted.';
                    }
                    field(NormalRatePerc; NormalRatePerc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Normal rate VAT %';
                        ToolTip = 'Specifies the standard VAT rate that applies to the time period.';
                    }
                    field(ReducedRatePerc; ReducedRatePerc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reduced rate VAT %';
                        ToolTip = 'Specifies the reduced VAT for certain goods and services.';
                    }
                    field(SpecialRatePerc; SpecialRatePerc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Special rate VAT %';
                        ToolTip = 'Specifies the current special tax rates used to assign the correct rates to the business and product groups defined in the VAT settings.';
                    }
                    field(InvFactTaxGLAcc; InvFactTaxGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Investment/Operating Purchase VAT G/L Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the general ledger account, typically account 1171, to filter the VAT groups that have prepaid taxes applied to investments and operating expenses. The other prepaid tax groups are recorded as prepaid taxes for materials and services.';
                    }
                    field(OwnConsumptionBusGroup; OwnConsumptionBusGroup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Own Consumption Bus. Group';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies the own consumption business group to include on the statement.';
                    }
                    field(ServiceForeignBusGr; ServiceForeignBusGr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Service Foreign Bus. Group';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies the service foreign business group to include on the statement.';
                    }
                    field(VAT040BusGr; VAT040BusGr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Bus. Group';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies the export business group to include on the statement.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // Set INIT Value
            if NormalRatePerc = 0 then begin
                ShowEntries := true;
                ShowBalanceEntries := true;
                NormalRatePerc := 7.6;
                ReducedRatePerc := 2.4;
                SpecialRatePerc := 3.6;
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if not (CurrReport.Language in [2055, 2064, 4108]) then begin
            Message(LocalLanguageMsg);
            CurrReport.Language := 2055;
        end;
        LanguageSelection.SetRange("Language ID", CurrReport.Language);
        if LanguageSelection.FindFirst() then
            CurrReport.FormatRegion := LanguageSelection."Language Tag";
    end;

    trigger OnPostReport()
    begin
        Window.Close();
        Message(VATStatProcessedMsg, EntriesCounter);
    end;

    trigger OnPreReport()
    begin
        if not (CurrReport.Language in [2055, 2064, 4108]) then begin
            Message(LocalLanguageMsg);
            CurrReport.Language := 2055;
        end;
        LanguageSelection.SetRange("Language ID", CurrReport.Language);
        if LanguageSelection.FindFirst() then
            CurrReport.FormatRegion := LanguageSelection."Language Tag";
    end;

    var
        GLRegister: Record "G/L Register";
        BalanceVATEntry2: Record "VAT Entry";
        CompanyInformation: Record "Company Information";
        LanguageSelection: Record "Language Selection";
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GLEntry2: Record "G/L Entry";
        TempVATCurrencyAdjustmentBuffer: Record "VAT Currency Adjustment Buffer" temporary;
        Window: Dialog;
        EntriesCounter: Integer;
        ClosedWithJournalnumber: Integer;
        OpenTillDate: Date;
        ShowEntries: Boolean;
        ShowBalanceEntries: Boolean;
        Sales: Boolean;
        FilterTxt: Text[120];
        TitleTxt: Text[50];
        VATGroupTxt: Text[50];
        BookTxt: Text[100];
        AccountType: Text[1];
        AccountNumber: Code[20];
        FoundBalanceEntries: Boolean;
        TotalVATAmount: Decimal;
        TotalVATBase: Decimal;
        TotalTaxAmount: Decimal;
        TotalTaxBase: Decimal;
        NormalRatePerc: Decimal;
        NormalRateBaseAmount: Decimal;
        NormalRateVATAmount: Decimal;
        ReducedRatePerc: Decimal;
        ReducedRateBaseAmount: Decimal;
        ReducedRateVATAmount: Decimal;
        SpecialRatePerc: Decimal;
        SpecialRateBaseAmount: Decimal;
        SpecialRateVATAmount: Decimal;
        NoVATBaseAmount: Decimal;
        NoVAT040: Decimal;
        NoVAT043: Decimal;
        InvFactTaxGLAcc: Code[20];
        MatServiceTaxAmount: Decimal;
        InvFactTaxAmount: Decimal;
        AssessableVolume: Decimal;
        ToPayAssessableAmount: Decimal;
        GLacc: Code[20];
        NewVATTxt: Text[80];
        ServiceForeignBusGr: Code[20];
        ServiceForeignBaseAmount: Decimal;
        ServiceForeignAmount: Decimal;
        OwnConsumptionBusGroup: Code[20];
        OwnConsumptionBaseAmount: Decimal;
        NormVATAmountCalc: Decimal;
        ReducedVATAmountCalc: Decimal;
        SpecialVATAmountCalc: Decimal;
        NormalDiffAmount: Decimal;
        ReducedDiffAmount: Decimal;
        SpecialDiffAmount: Decimal;
        VAT040BusGr: Code[20];
        SalesFull: Decimal;
        LocalLanguageMsg: Label 'This Report can only be executed in a local Swiss Language. Report Language will switch to Swiss German.';
        VATStatProcessedMsg: Label 'VAT Statement successfully processed with %1 Entries.';
        ProcessNotificationErr: Label 'You can process either open or already closed VAT entries. Therefore define either the field ''open until date'' or ''closed with Journal No.'' in the request form.';
        VATStatPostedErr: Label 'No VAT settlement has been posted so far.';
        NotVATSettlementErr: Label 'The selected G/L Journal %1 is not a VAT settlement, the sourcecode should be %2.';
        ClosedEntriesTxt: Label 'Closed Entires in Journal %1 from %2.';
        OpenEntriesTxt: Label 'Open Entries until %1.';
        ProcessCancelledErr: Label 'Process cancelled.';
        ProcessVATStatementMsg: Label 'Process VAT Statement\';
        BusinessPostingGroupMsg: Label 'Business Posting Group         #1######\';
        ProductPostingGroupMsg: Label 'Product Posting Group          #2######\';
        NumberOfEntriesMsg: Label 'Number of Entries              #3######';
        WarningMsg: Label 'Warning: The sum of the base amounts per VAT rate does not match with the sum of all base amounts.  Possibly the VAT rates are not correctly defined in the request from.';
        VATSalesTxt: Label 'VAT Sales';
        VATPurchaseTxt: Label 'VAT Purchase';
        TotalTxt: Label 'Total';
        AccountNotDefinedQst: Label 'In the request form window the G/L Account for investment/operating expenditure is not defined. This causes that the Purchase VAT on the account cannot be divided into the two categories material/service and investment/operating expenditure. However you can compute the allocation based on the account details. Start processing?';
        UnrealizedVATQst: Label 'You have activated the "Unrealized VAT" option in G/L Setup for company %1. This might be necessary if you work with Prepayment Invoices. Apart from that be aware this report can only be used if you calculate your VAT using the realized VAT method. Continue?';
        CurrencyAdjusted: Boolean;
        NotFirstEntry: Boolean;
        TmpBase: Decimal;
        TmpAmount: Decimal;
        TmpBaseSetup: Decimal;
        TmpAmountSetup: Decimal;
        AccountNumberCaptionLbl: Label 'Account';
        PostingDateCaptionLbl: Label 'Posting Date';
        PageNoCaptionLbl: Label 'Page';
        VATStatementSwitzerlandCaptionLbl: Label 'VAT Statement Switzerland';
        DescriptionCaptionLbl: Label 'Description';
        VATEntryExternalDocNoCaptionLbl: Label 'Ext. Document no.';
        VATEntryTransactionNoCaptionLbl: Label 'TN';
        TypeCaptionLbl: Label 'Type';
        PurchaseVATCaptionLbl: Label 'Purchase VAT';
        ToSwissFederalTaxAdministrationPayableAmtCaptionLbl: Label 'To Swiss Federal Tax Administration payable amount';
        VATSalesCaptionLbl: Label 'VAT Sales';
        NormalRateCaptionLbl: Label 'Normal rate';
        ReducedRateCaptionLbl: Label 'Reduced Rate';
        SpecialRateCaptionLbl: Label 'Special Rate';
        DifferenceCaptionLbl: Label 'Difference';
        VATAmtCaptionLbl: Label 'The difference between Amount and the sum of the VAT Amounts orginates because of rounding and VAT Rate change. ';
        PostedVATAmtCaptionLbl: Label 'Posted VAT Amount';
        RoundingDiffAndRateChangeCaptionLbl: Label 'Rounding difference and Rate change';
        VATRateChangeCaptionLbl: Label 'A possible Value in this row is only in the Case of a VAT Rate change. It is the Base for the correction Form.';
        VATAmtCalculatedCaptionLbl: Label 'VAT Amount calculated';
        VATCaptionLbl: Label 'VAT %';
        TotalCaptionLbl: Label 'Total';
        VATBaseAmtCaptionLbl: Label 'VAT Base Amount';
        VATGroupTxtCaptionLbl: Label 'VAT Group';
        GLaccCaptionLbl: Label 'G/L Account';
        TransferCaptionLbl: Label 'Transfer';
        TotalGroupCaptionLbl: Label 'Total Group';
        VATChargebackCaptionLbl: Label 'VAT chargeback';
        GroupTextCaptionLbl: Label 'Group / Text';
        VATStatementSwitzerlandChargebackCaptionLbl: Label 'VAT Statement Switzerland - Chargeback';
        AccountCaptionLbl: Label 'Account';
        BalanceTaxLiabilityCaptionLbl: Label 'Balance (Tax liability)';
        GLChargebackCaptionLbl: Label 'G/L Chargeback';
        BalanceCaptionLbl: Label 'Balance';
        PurchInvBaseCaptionLbl: Label 'Purchase Inv. Base';
        PurchAdjBaseCaptionLbl: Label 'Purchase Adj. Base';
        SalesAdjBaseCaptionLbl: Label 'Sales Adj. Base';
        SalesInvBaseCaptionLbl: Label 'Sales Inv. Base';
        ProdPostGrCaptionLbl: Label 'Prod. Post. Gr.';
        ExchangeRateAdjustmentsCaptionLbl: Label 'Exchange Rate Adjustments';
        BusinessPostGrCaptionLbl: Label 'Bus. Post. Gr.';
        SalesVolumeCaptionLbl: Label 'SALES VOLUME';
        ICaptionLbl: Label 'I.', Locked = true;
        TotAgreedHiresCaptionLbl: Label 'Total agreed hires (outgoing invoice)';
        DeductionsCaptionLbl: Label 'Deductions';
        ServicesInForeignCountriesCaptionLbl: Label 'Export, performedt Services in foreign countries';
        AssessableVolumeCaptionLbl: Label 'Assessable Volume';
        IICaptionLbl: Label 'II.', Locked = true;
        TaxSettlementCaptionLbl: Label 'TAX SETTLEMENT';
        DeliveriesServicesAndConsumptionCaptionLbl: Label 'Deliveries, Services and own Consumption';
        SplitOfFigure60IntoTaxRateCaptionLbl: Label 'Split of Figure 60 into Tax Rate';
        AccommodationServicesCaptionLbl: Label 'Accommodation Services';
        TotalTaxCaptionLbl: Label 'Total Tax';
        AccountablePurchaseTaxCaptionLbl: Label 'Accountable Purchase Tax on';
        MaterialAndServiceExpensesCaptionLbl: Label 'Material and Service expenses';
        InvestmentsAndRemainingOperatingExpenditureCaptionLbl: Label 'Investments and remaining operating expenditure';
        TotalPurchaseVATCaptionLbl: Label 'Total Purchase VAT';
        AssetsOfTheTaxpayerCaptionLbl: Label 'Assets of the taxpayer';
        LikeFigure060CaptionLbl: Label '(like figure 060)';
        Figure030Minus050CaptionLbl: Label '(Figure 030 minus 050)';
        Figure070until074Plus090CaptionLbl: Label '(Figure 070 until 074 + 090)';
        Figure100Minus140CaptionLbl: Label '(Figure 100 minus 140)';
        Figure110Plus111CaptionLbl: Label '(Figure 110 + 111)';
        Figure140Minus100CaptionLbl: Label '(Figure 140 minus 100)';
        VATStatementCaptionLbl: Label 'This summary is the base for the Swiss VAT Statement based on unrealized VAT. It must be supplemented if necessary with data of own consumption and special deductions and be transferred to the official form.';
        TaxRateCaptionLbl: Label 'Tax rate';
        V010CaptionLbl: Label '010';
        FigureCaptionLbl: Label 'Figure';
        V043To045CaptionLbl: Label '043 - 045';
        V050CaptionLbl: Label '050';
        V060CaptionLbl: Label '060';
        V070CaptionLbl: Label '070';
        V071CaptionLbl: Label '071';
        V074CaptionLbl: Label '074';
        V080CaptionLbl: Label '080';
        V100CaptionLbl: Label '100';
        V110CaptionLbl: Label '110';
        V111CaptionLbl: Label '111';
        V140CaptionLbl: Label '140';
        VolumeFrCaptionLbl: Label 'Volume Fr.';
        TaxFrRpCaptionLbl: Label 'Tax Fr. / Rp.';
        VATNumberCaptionLbl: Label 'VAT Number';
        ConsolidatedCaptionLbl: Label '(consolidated)';
        V150CaptionLbl: Label '150';
        V160CaptionLbl: Label '160';
        OwnConsumptionCaptionLbl: Label 'Own Consumption';
        V020CaptionLbl: Label '020';
        PurchOfServicesFromForeignCountriesCaptionLbl: Label 'Purchase of services from foreign countries';
        V090CaptionLbl: Label '090';
        TotalSalesVolumeCaptionLbl: Label 'Total Sales Volume';
        V030CaptionLbl: Label '030';
        TotalDeductionsCaptionLbl: Label 'Total Deductions';
        V042CaptionLbl: Label '042';
        V040CaptionLbl: Label '040';
        PurchPriceOfItemsMarginTaxingCaptionLbl: Label 'Purchase price of items (Margin Taxing)';
        TaxFreeVolumeCaptionLbl: Label 'Tax Free Volume';
}

