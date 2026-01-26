// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Utilities;
#if not CLEAN27
using System.Environment.Configuration;
#endif
using System.Utilities;

/// <summary>
/// Calculates VAT settlement amounts for a specified period and posts VAT settlement entries to General Ledger.
/// Processes open VAT entries by posting setup and transfers amounts to designated VAT settlement accounts.
/// </summary>
report 20 "Calc. and Post VAT Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/CalcandPostVATSettlement.rdlc';
    AdditionalSearchTerms = 'settle vat value added tax,report vat value added tax';
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate and Post VAT Settlement';
    Permissions = TableData "VAT Entry" = rimd;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            column(PostSettlement; PostSettlement)
            {
            }
            column(PeriodVATDateFilter; StrSubstNo(Text005, VATDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(GLAccSettleNo; GLAccSettle."No.")
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(PrintVATEntries; PrintVATEntries)
            {
            }
            column(VATPostingSetupCptnFilter; "VAT Posting Setup".TableCaption + ': ' + VATPostingSetupFilter)
            {
            }
            column(VATPostingSetupFilter; VATPostingSetupFilter)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(TotalSaleAmtTotalPurchAmt; -(TotalSaleAmount + TotalPurchaseAmount))
            {
                AutoFormatType = 1;
            }
            column(TotalSaleAmount; TotalSaleAmount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(PeriodOutputVATYearOutputVATAdvAmt; PeriodOutputVATYearOutputVATAdvAmt)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(TotalPurchaseAmount; -TotalPurchaseAmount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(PeriodInputVATYearInputVAT; PeriodInputVATYearInputVAT)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(FinalUndVATAmnt; FinalUndVATAmnt)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(TotalSaleRounded; TotalSaleRounded)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(TotalPurchRounded; TotalPurchRounded)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(VATToPay; VATToPay)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(VATBusPostGr_VATPostingSetup; "VAT Bus. Posting Group")
            {
            }
            column(VATProdPostGr_VATPostingSetup; "VAT Prod. Posting Group")
            {
            }
            column(TestReportnotpostedCaption; TestReportnotpostedCaptionLbl)
            {
            }
            column(CalcandPostVATSettlementCaption; CalcandPostVATSettlementCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(GLAccSettleNoCaption; GLAccSettleNoCaptionLbl)
            {
            }
            column(VATEntryPostingDateCaption; VATEntryPostingDateCaptionLbl)
            {
            }
            column(VATEntryDocumentTypeCaption; VATEntryDocumentTypeCaptionLbl)
            {
            }
            column(TotalSaleAmountTotalPurchaseAmountCaption; TotalSaleAmountTotalPurchaseAmountCaptionLbl)
            {
            }
            column(TotalSaleAmountCaption; TotalSaleAmountCaptionLbl)
            {
            }
            column(TotalPurchaseAmountCaption; TotalPurchaseAmountCaptionLbl)
            {
            }
            column(PriorPeriodOutputVATCaption; PriorPeriodVATEntryPriorPeriodOutputVATPriorPeriodVATEntryPriorYearOutputVATPriorPeriodVATEntryAdvancedAmountCaptionLbl)
            {
            }
            column(PriorPeriodInputVATCaption; PriorPeriodVATEntryPriorPeriodInputVATPriorPeriodVATEntryPriorYearInputVATCaptionLbl)
            {
            }
            column(FinalUndVATAmntCaption; FinalUndVATAmntCaptionLbl)
            {
            }
            column(TotalSaleRoundedCaption; TotalSaleRoundedCaptionLbl)
            {
            }
            column(TotalPurchRoundedCaption; TotalPurchRoundedCaptionLbl)
            {
            }
            column(VATToPayCaption; VATToPayCaptionLbl)
            {
            }
            column(VATEntryDocumentNoCaption; "VAT Entry".FieldCaption("Document No."))
            {
            }
            column(VATEntryTypeCaption; "VAT Entry".FieldCaption(Type))
            {
            }
            column(VATEntryBaseCaption; "VAT Entry".FieldCaption(Base))
            {
            }
            column(VATEntryAmountCaption; "VAT Entry".FieldCaption(Amount))
            {
            }
            column(VATEntryEntryNoCaption; "VAT Entry".FieldCaption("Entry No."))
            {
            }
            column(VATEntryNondeductibleAmountCaption; "VAT Entry".FieldCaption("Nondeductible Amount"))
            {
            }
            column(VATEntryNondeductibleBaseCaption; "VAT Entry".FieldCaption("Nondeductible Base"))
            {
            }
            column(VATEntryRemainingUnrealizedBaseCaption; "VAT Entry".FieldCaption("Remaining Unrealized Base"))
            {
            }
            column(VATEntryRemainingUnrealizedAmountCaption; "VAT Entry".FieldCaption("Remaining Unrealized Amount"))
            {
            }
            dataitem("Activity Code Loop"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ActivityCode; activitycodefilter)
                {
                }
                dataitem("Closing G/L and VAT Entry"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATBusPostGr1_VATPostingSetup; "VAT Posting Setup"."VAT Bus. Posting Group")
                    {
                    }
                    column(VATProdPostGr1_VATPostingSetup; "VAT Posting Setup"."VAT Prod. Posting Group")
                    {
                    }
                    column(VATEntryGetFilterType; VATEntry.GetFilter(Type))
                    {
                    }
                    column(VATEntryGetFilterTaxJurisdictionCode; VATEntry.GetFilter("Tax Jurisdiction Code"))
                    {
                    }
                    column(VATEntryGetFilterUseTax; VATEntry.GetFilter("Use Tax"))
                    {
                    }
                    column(Number_IntegerLine; Number)
                    {
                    }
                    dataitem("VAT Entry"; "VAT Entry")
                    {
                        DataItemTableView = sorting(Type, Closed) where(Closed = const(false), Type = filter(Purchase | Sale));
                        column(PostingDate_VATEntry; Format("Posting Date"))
                        {
                        }
                        column(DocumentNo_VATEntry; "Document No.")
                        {
                            IncludeCaption = false;
                        }
                        column(DocumentType_VATEntry; "Document Type")
                        {
                        }
                        column(Type_VATEntry; Type)
                        {
                            IncludeCaption = false;
                        }
                        column(Base_VATEntry; Base)
                        {
                            AutoFormatExpression = GetCurrency();
                            AutoFormatType = 1;
                            IncludeCaption = false;
                        }
                        column(Amount_VATEntry; Amount)
                        {
                            AutoFormatExpression = GetCurrency();
                            AutoFormatType = 1;
                            IncludeCaption = false;
                        }
                        column(EntryNo_VATEntry; "Entry No.")
                        {
                            IncludeCaption = false;
                        }
                        column(NondeductibleAmount_VATEntry; "Nondeductible Amount")
                        {
                            IncludeCaption = false;
                        }
                        column(NondeductibleBase_VATEntry; "Nondeductible Base")
                        {
                            IncludeCaption = false;
                        }
                        column(RemUnrealizedAmt_VATEntry; "Remaining Unrealized Amount")
                        {
                            IncludeCaption = false;
                        }
                        column(RemUnrealizedBase_VATEntry; "Remaining Unrealized Base")
                        {
                            IncludeCaption = false;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TotalVATNondeducAmnt += "Nondeductible Amount";
                            TotalVATNondeducBase += "Nondeductible Base";
                            TotalVATNondeducBaseAmt += "Nondeductible Base";
                            TotalRemainUnrealBaseAmt += "Remaining Unrealized Base";
                            TotalRemainUnrealAmt += "Remaining Unrealized Amount";

                            OnBeforeCheckPrintVATEntries("VAT Entry");
                            if not PrintVATEntries then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            "VAT Entry".CopyFilters(VATEntry);
                            TotalVATNondeducAmnt := 0;
                            TotalVATNondeducBase := 0;
                            TotalVATNondeducBaseAmt := 0;
                            TotalRemainUnrealBaseAmt := 0;
                            TotalRemainUnrealAmt := 0;
                        end;
                    }
                    dataitem("Close VAT Entries"; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        MaxIteration = 1;
                        column(PostingDate1; Format(PostingDate))
                        {
                        }
                        column(GenJnlLineDocumentNo; GenJnlLine."Document No.")
                        {
                        }
                        column(GenJnlLineVATBaseAmount; GenJnlLine."VAT Base Amount")
                        {
                            AutoFormatExpression = GetCurrency();
                            AutoFormatType = 1;
                        }
                        column(GenJnlLineVATAmount; GenJnlLine."VAT Amount")
                        {
                            AutoFormatExpression = GetCurrency();
                            AutoFormatType = 1;
                        }
                        column(NextVATEntryNo; NextVATEntryNo)
                        {
                        }
                        column(TotalVATNondeducBase; TotalVATNondeducBase)
                        {
                        }
                        column(TotalVATNondeducAmnt; TotalVATNondeducAmnt)
                        {
                        }
                        column(TotalVATNondeducBaseAmt; TotalVATNondeducBaseAmt)
                        {
                        }
                        column(TotalRemainUnrealBaseAmt; TotalRemainUnrealBaseAmt)
                        {
                        }
                        column(TotalRemainUnrealAmt; TotalRemainUnrealAmt)
                        {
                        }
                        column(GenJnlLine2Amount; GenJnlLine2.Amount)
                        {
                            AutoFormatExpression = GetCurrency();
                            AutoFormatType = 1;
                        }
                        column(GenJnlLine2DocumentNo; GenJnlLine2."Document No.")
                        {
                        }
                        column(ReversingEntry; ReversingEntry)
                        {
                        }
                        column(GenJnlLineVATBaseAmountCaption; GenJnlLineVATBaseAmountCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            IsPostingAllowed: Boolean;
                        begin
                            // Calculate amount and base
                            VATEntry.CalcSums(
                            Base, Amount,
                            "Additional-Currency Base", "Additional-Currency Amount");

                            ReversingEntry := false;
                            // Balancing entries to VAT accounts
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            case VATType of
                                VATEntry.Type::Purchase:
                                    GenJnlLine.Description :=
                                    DelChr(
                                        StrSubstNo(
                                        Text007,
                                        "VAT Posting Setup"."VAT Bus. Posting Group",
                                        "VAT Posting Setup"."VAT Prod. Posting Group"),
                                        '>');
                                VATEntry.Type::Sale:
                                    GenJnlLine.Description :=
                                    DelChr(
                                        StrSubstNo(
                                        Text008,
                                        "VAT Posting Setup"."VAT Bus. Posting Group",
                                        "VAT Posting Setup"."VAT Prod. Posting Group"),
                                        '>');
                            end;
                            SetVatPostingSetupToGenJnlLine(GenJnlLine, "VAT Posting Setup");
                            GenJnlLine."Deductible %" := 100;
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Operation Occurred Date" := PostingDate;
                            if GLSetup."Use Activity Code" then
                                GenJnlLine."Activity Code" := ActivityCode.Code;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                            GenJnlLine."Document No." := DocNo;
                            GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                            GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                            case "VAT Posting Setup"."VAT Calculation Type" of
                                "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                                "VAT Posting Setup"."VAT Calculation Type"::"Full VAT":
                                    begin
                                        case VATType of
                                            VATEntry.Type::Purchase:
                                                begin
                                                    GenJnlLine."Account No." := "VAT Posting Setup".GetPurchAccount(false);
                                                    TotalPurchaseAmount := -VATEntry.Amount + TotalPurchaseAmount;
                                                    AddToTotals(TotalPurchaseAmountPerActivity, ActivityCode.Code, -VATEntry.Amount);
                                                end;
                                            VATEntry.Type::Sale:
                                                begin
                                                    GenJnlLine."Account No." := "VAT Posting Setup".GetSalesAccount(false);
                                                    TotalSaleAmount := -VATEntry.Amount + TotalSaleAmount;
                                                    AddToTotals(TotalSaleAmountPerActivity, ActivityCode.Code, -VATEntry.Amount);
                                                end;
                                        end;
                                        GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                        CopyAmounts(GenJnlLine, VATEntry);
                                        if (PostSettlement) and (GenJnlLine."VAT Amount" <> 0) then
                                            GenJnlPostLine.Run(GenJnlLine);
                                        VATAmount := VATAmount + VATEntry.Amount;
                                        VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                        AddToTotals(VATAmountPerActivity, ActivityCode.Code, VATEntry.Amount);
                                    end;
                                "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT":
                                    case VATType of
                                        VATEntry.Type::Purchase:
                                            begin
                                                TotalPurchaseAmount := -VATEntry.Amount + TotalPurchaseAmount;
                                                GenJnlLine."Account No." := "VAT Posting Setup".GetPurchAccount(false);
                                                GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                                CopyAmounts(GenJnlLine, VATEntry);
                                                if (PostSettlement) and (GenJnlLine."VAT Amount" <> 0) then
                                                    GenJnlPostLine.Run(GenJnlLine);
                                                VATAmount := VATAmount + VATEntry.Amount;
                                                VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                                AddToTotals(VATAmountPerActivity, ActivityCode.Code, VATEntry.Amount);
                                            end;
                                        VATEntry.Type::Sale:
                                            begin
                                                TotalSaleAmount := -VATEntry.Amount + TotalSaleAmount;
                                                GenJnlLine."Account No." := "VAT Posting Setup".GetRevChargeAccount(false);
                                                GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                                GenJnlLine."Deductible %" := 100;
                                                CopyAmounts(GenJnlLine, VATEntry);
                                                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Settlement;
                                                if (PostSettlement) and (GenJnlLine."VAT Amount" <> 0) then
                                                    GenJnlPostLine.Run(GenJnlLine);
                                                VATAmount := VATAmount + VATEntry.Amount;
                                                VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                                AddToTotals(VATAmountPerActivity, ActivityCode.Code, VATEntry.Amount);
                                            end;
                                    end;
                                "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                                    begin
                                        TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
                                        GenJnlLine."Tax Area Code" := TaxJurisdiction.Code;
                                        GenJnlLine."Use Tax" := VATEntry."Use Tax";
                                        case VATType of
                                            VATEntry.Type::Purchase:
                                                if VATEntry."Use Tax" then begin
                                                    TaxJurisdiction.TestField("Tax Account (Purchases)");
                                                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Purchases)";
                                                    GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                                    CopyAmounts(GenJnlLine, VATEntry);
                                                    if PostSettlement then
                                                        GenJnlPostLine.Run(GenJnlLine);

                                                    TaxJurisdiction.TestField("Reverse Charge (Purchases)");
                                                    CreateGenJnlLine(GenJnlLine2, TaxJurisdiction."Reverse Charge (Purchases)");
                                                    GenJnlLine2."Tax Area Code" := TaxJurisdiction.Code;
                                                    GenJnlLine2."Use Tax" := VATEntry."Use Tax";
                                                    if PostSettlement then
                                                        GenJnlPostLine.Run(GenJnlLine2);
                                                    ReversingEntry := true;
                                                end else begin
                                                    TaxJurisdiction.TestField("Tax Account (Purchases)");
                                                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Purchases)";
                                                    GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                                    CopyAmounts(GenJnlLine, VATEntry);
                                                    if PostSettlement then
                                                        GenJnlPostLine.Run(GenJnlLine);
                                                    VATAmount := VATAmount + VATEntry.Amount;
                                                    VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                                    AddToTotals(VATAmountPerActivity, ActivityCode.Code, VATEntry.Amount);
                                                end;
                                            VATEntry.Type::Sale:
                                                begin
                                                    TaxJurisdiction.TestField("Tax Account (Sales)");
                                                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Sales)";
                                                    GenJnlLine.Validate(Amount, -VATEntry.Amount);
                                                    CopyAmounts(GenJnlLine, VATEntry);
                                                    if PostSettlement then
                                                        GenJnlPostLine.Run(GenJnlLine);
                                                    VATAmount := VATAmount + VATEntry.Amount;
                                                    VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                                    AddToTotals(VATAmountPerActivity, ActivityCode.Code, VATEntry.Amount);
                                                end;
                                        end;
                                    end;
                            end;
                            IsPostingAllowed := ("VAT Posting Setup"."VAT Calculation Type" = "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax") or (GenJnlLine."VAT Amount" <> 0);
                            NextVATEntryNo := GetSettlementVATEntryNo(PostSettlement, IsPostingAllowed);

                            // Close current VAT entries
                            if PostSettlement then begin
                                CloseVATEntriesOnPostSettlement(VATEntry, NextVATEntryNo);
                                UpdateVATPeriodOnSettlementVATEntry(NextVATEntryNo);
                            end;

                            FinalUndVATAmnt += TotalVATNondeducAmnt;

                            TotalSaleRounded := FiscalRoundAmount(PeriodOutputVATYearOutputVATAdvAmt + TotalSaleAmount);
                            TotalPurchRounded := FiscalRoundAmount(PeriodInputVATYearInputVAT - TotalPurchaseAmount);

                            VATToPay := 0;
                            if (TotalSaleRounded - TotalPurchRounded) > 0 then
                                VATToPay := TotalSaleRounded - TotalPurchRounded;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATEntry.Reset();
                        if GLSetup."Use Activity Code" then
                            VATEntry.SetFilter("Activity Code", '%1', ActivityCode.Code);
                        VATEntry.SetRange(Type, VATType);
                        VATEntry.SetRange(Closed, false);
                        VATEntry.SetFilter("Operation Occurred Date", VATDateFilter);
                        VATEntry.SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");
                        if CountryRegionFilter <> '' then
                            VATEntry.SetFilter("Country/Region Code", CountryRegionFilter);
                        VATEntry.SetRange("Tax Liable", false);
                        VATEntry.SetRange("VAT Period", '');

                        OnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters("VAT Posting Setup", VATEntry, "VAT Entry");

                        case "VAT Posting Setup"."VAT Calculation Type" of
                            "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"Full VAT":
                                begin
                                    VATEntry.SetCurrentKey(Type, Closed, "Tax Liable", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Operation Occurred Date", "VAT Period");
                                    if FindFirstEntry then begin
                                        if not VATEntry.Find('-') then
                                            repeat
                                                VATType := "General Posting Type".FromInteger((VATType.AsInteger() + 1));
                                                VATEntry.SetRange(Type, VATType);
                                                OnClosingGLAndVATEntryOnAfterGetRecordOnNormalVATOnAfterVATEntrySetFilter("VAT Posting Setup", VATType, VATEntry, FindFirstEntry);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                        FindFirstEntry := false;
                                    end else
                                        if VATEntry.Next() = 0 then
                                            repeat
                                                VATType := "General Posting Type".FromInteger((VATType.AsInteger() + 1));
                                                VATEntry.SetRange(Type, VATType);
                                                OnClosingGLAndVATEntryOnAfterGetRecordOnNormalVATOnAfterVATEntrySetFilter("VAT Posting Setup", VATType, VATEntry, FindFirstEntry);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    if VATType.AsInteger() < VATEntry.Type::Settlement.AsInteger() then
                                        VATEntry.Find('+');
                                end;
                            "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                                begin
                                    VATEntry.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                                    if FindFirstEntry then begin
                                        if not VATEntry.Find('-') then
                                            repeat
                                                VATType := "General Posting Type".FromInteger((VATType.AsInteger() + 1));
                                                VATEntry.SetRange(Type, VATType);
                                                OnClosingGLAndVATEntryOnAfterGetRecordOnSalesTaxOnAfterVATEntrySetFilter("VAT Posting Setup", VATType, VATEntry, FindFirstEntry);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                        FindFirstEntry := false;
                                    end else begin
                                        VATEntry.SetRange("Tax Jurisdiction Code");
                                        VATEntry.SetRange("Use Tax");
                                        if VATEntry.Next() = 0 then
                                            repeat
                                                VATType := "General Posting Type".FromInteger((VATType.AsInteger() + 1));
                                                VATEntry.SetRange(Type, VATType);
                                                OnClosingGLAndVATEntryOnAfterGetRecordOnSalesTaxOnAfterVATEntrySetFilter("VAT Posting Setup", VATType, VATEntry, FindFirstEntry);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    end;
                                    if VATType.AsInteger() < VATEntry.Type::Settlement.AsInteger() then begin
                                        VATEntry.SetRange("Tax Jurisdiction Code", VATEntry."Tax Jurisdiction Code");
                                        VATEntry.SetRange("Use Tax", VATEntry."Use Tax");
                                        VATEntry.Find('+');
                                    end;
                                end;
                        end;

                        if VATType = VATEntry.Type::Settlement then
                            CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        VATType := VATEntry.Type::Purchase;
                        FindFirstEntry := true;
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;

                    trigger OnAfterGetRecord()
                    begin
                        if (VATBusPostingGroup = "VAT Posting Setup"."VAT Bus. Posting Group") and
                           (VATProdPostingGroup = "VAT Posting Setup"."VAT Prod. Posting Group")
                        then begin
                            if (TotalSaleRounded - TotalPurchRounded) < 0 then
                                CreditNextPeriod := -(TotalSaleRounded - TotalPurchRounded);
                            if (TotalSaleRounded - TotalPurchRounded) > 0 then
                                if (TotalSaleRounded - TotalPurchRounded) <= GLSetup."Minimum VAT Payable" then
                                    DebitNextPeriod := TotalSaleRounded - TotalPurchRounded;
                        end;
                    end;
                }
                trigger OnAfterGetRecord()
                begin
                    if (Number = 1) and GLSetup."Use Activity Code" then begin
                        if ActivityCodeFilter <> '' then
                            ActivityCode.SetFilter(Code, ActivityCodeFilter);
                        ActivityCode.FindSet();
                    end;
                    if (Number = 2) and not GLSetup."Use Activity Code" then
                        CurrReport.Break();
                    if (Number >= 2) and GLSetup."Use Activity Code" then
                        if ActivityCode.Next() = 0 then
                            CurrReport.Break();
                end;
            }

            trigger OnPostDataItem()
            begin
                // Post to settlement account
                if VATAmount <> 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    GenJnlLine.Validate("Account No.", GLAccSettle."No.");
                    GenJnlLine."Posting Date" := PostingDate;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                    GenJnlLine."Document No." := DocNo;
                    GenJnlLine.Description := Text004;
                    GenJnlLine.Validate(Amount, VATAmount);
                    GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
                    GenJnlLine."Source Currency Amount" := VATAmountAddCurr;
                    GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    GenJnlLine."Operation Occurred Date" := PostingDate;
                    if PostSettlement then begin
                        GenJnlPostLine.Run(GenJnlLine);

                        NewVATAmount := TotalPurchRounded - TotalSaleRounded;
                        if NewVATAmount > 0 then
                            CreditNextPeriod := NewVATAmount
                        else
                            // VAT Settlement
                            if -NewVATAmount <= GLSetup."Minimum VAT Payable" then
                                DebitNextPeriod := NewVATAmount;

                        // Post Rounding Amount to Settlement Account
                        RoundAmount := -VATAmount -
                          (FiscalRoundAmount(TotalSaleAmount) + FiscalRoundAmount(TotalPurchaseAmount));

                        if RoundAmount <> 0 then begin
                            GenJnlLine.Init();
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            GenJnlLine.Validate("Account No.", GLAccSettle."No.");
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                            GenJnlLine."Document No." := DocNo;
                            GenJnlLine.Description := Text1130006;
                            GenJnlLine.Validate(Amount, RoundAmount);
                            GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                            GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                            GenJnlLine."Operation Occurred Date" := PostingDate;
                            GenJnlPostLine.Run(GenJnlLine);
                            // Post Rounding Amount to Settlement Account
                            GenJnlLine.Init();
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            if RoundAmount > 0 then
                                GenJnlLine.Validate("Account No.", GLAccPosRounding."No.")
                            else
                                GenJnlLine.Validate("Account No.", GLAccNegRounding."No.");
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                            GenJnlLine."Document No." := DocNo;
                            GenJnlLine.Description := Text1130006;
                            GenJnlLine.Validate(Amount, -RoundAmount);
                            GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                            GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                            GenJnlLine."Operation Occurred Date" := PostingDate;
                            GenJnlPostLine.Run(GenJnlLine);
                        end;
#if not CLEAN27
                        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then
                            UpdatePeriodicSettlementVATEntryActivityCode()
                        else
                            UpdatePeriodicSettlementVATEntry();
#else
                        UpdatePeriodicSettlementVATEntryActivityCode();
#endif
                    end;
                end else begin
                    OnVATPostingSetupOnPostDataItemOnBeforePostSettlement(GenJnlLine);
                    if PostSettlement then
#if not CLEAN27
                        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then
                            UpdatePeriodicSettlementVATEntryActivityCode()
                        else
                            UpdatePeriodicSettlementVATEntry();
#else
                        UpdatePeriodicSettlementVATEntryActivityCode();
#endif
                end;
                OnVATPostingSetupOnAfterOnPostDataItem(GenJnlLine, PostSettlement);
            end;

            trigger OnPreDataItem()
            begin
                GLEntry.LockTable(); // Avoid deadlock with function 12
                if GLEntry.FindLast() then;
                VATEntry.LockTable();
                VATEntry.Reset();
                NextVATEntryNo := VATEntry.GetLastEntryNo();

                SourceCodeSetup.Get();
                GLSetup.Get();
                VATAmount := 0;
                VATAmountAddCurr := 0;
                TotalSaleAmount := 0;
                TotalPurchaseAmount := 0;
                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(AllAmountsAreInTxt, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(AllAmountsAreInTxt, GLSetup."LCY Code");
                end;

                if FindLast() then begin
                    VATBusPostingGroup := "VAT Bus. Posting Group";
                    VATProdPostingGroup := "VAT Prod. Posting Group";
                end;
            end;
        }
        dataitem(Total; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(DebitNextPeriodCaption; DebitNextPeriodCaptionLbl)
            {
            }
            column(CreditNextPeriodCaption; CreditNextPeriodCaptionLbl)
            {
            }
            column(VATAmountAddCurrCaption; VATAmountAddCurrCaptionLbl)
            {
            }
            column(DebitNextPeriod; DebitNextPeriod)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(CreditNextPeriod; CreditNextPeriod)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(VATAmountAddCurr; VATAmountAddCurr)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
        }
        dataitem(VATPlafondPeriod; "VAT Plafond Period")
        {
            DataItemTableView = sorting(Year);
            column(RemainingVATPlafondAmount; PrevPlafondAmount - UsedPlafondAmount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(UsedPlafondAmount; UsedPlafondAmount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(PrevPlafondAmount; PrevPlafondAmount)
            {
                AutoFormatExpression = GetCurrency();
                AutoFormatType = 1;
            }
            column(VATPlafondPeriodYear; Year)
            {
            }
            column(RemainingVATPlafondAmountCaption; RemainingVATPlafondAmountCaptionLbl)
            {
            }
            column(UsedPlafondAmountCaption; UsedPlafondAmountCaptionLbl)
            {
            }
            column(PrevPlafondAmountCaption; PrevPlafondAmountCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcAmounts(EntrdStartDate, EndDateReq, UsedPlafondAmount, PrevPlafondAmount);
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Year, Date2DMY(EndDateReq, 3));
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Calc. and Post VAT Settlement';
        AboutText = 'The **Calculate and Post Tax Settlement** report calculates VAT based on posted entries and generates a journal to record the VAT settlement. Use it for automating VAT processing at the end of a filing period (typically monthly or quarterly) by posting the net VAT due or refundable, helping streamline tax reporting and compliance.';
        SaveValues = true;
        ShowFilter = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; EntrdStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date in the period from which VAT entries are processed in the batch job.';

                        trigger OnValidate()
                        begin
                            if (GLSetup."Last Settlement Date" <> 0D) then
                                if not ((EntrdStartDate - GLSetup."Last Settlement Date") = 1) then Error(Text1130007, GLSetup."Last Settlement Date");

                            CalculateEndDate();
                        end;
                    }
                    field(EndingDate; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        Editable = false;
                        ToolTip = 'Specifies the last date in the period from which VAT entries are processed in the batch job. ';
                    }
                    field(PostingDt; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date on which the transfer to the VAT account is posted. This field must be filled in.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a document number. This field must be filled in.';
                    }
                    field(SettlementAcc; GLAccSettle."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the number of the VAT settlement account. Select the field to see the chart of account. This field must be filled in.';

                        trigger OnValidate()
                        begin
                            if GLAccSettle."No." <> '' then begin
                                GLAccSettle.Find();
                                GLAccSettle.CheckGLAcc();
                            end;
                        end;
                    }
                    field(GLGainsAccount; GLAccPosRounding."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Gains Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the general ledger account for gains.';
                    }
                    field(GLLossesAccount; GLAccNegRounding."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Losses Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the general ledger account for losses.';
                    }
                    field(ShowVATEntries; PrintVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show VAT Entries';
                        ToolTip = 'Specifies if you want the report that is printed during the batch job to contain the individual VAT entries. If you do not choose to print the VAT entries, the settlement amount is shown only for each VAT posting group.';
                    }
                    field(Post; PostSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies if you want the program to post the transfer to the VAT settlement account automatically. If you do not choose to post the transfer, the batch job only prints a test report, and Test Report (not Posted) appears on the report.';
                    }
                    field(AmtsinAddReportingCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                    field("Country/Region Filter"; CountryRegionFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region Filter';
                        ToolTip = 'Specifies the country/region to filter the VAT entries.';
                        Importance = Additional;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            CountryRegion: Record "Country/Region";
                            CountriesRegions: Page "Countries/Regions";
                        begin
                            CountriesRegions.LookupMode(true);
                            if CountriesRegions.RunModal() = Action::LookupOK then begin
                                CountriesRegions.GetRecord(CountryRegion);
                                CountryRegionFilter := CountryRegion.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field("Activity Code Filter"; ActivityCodeFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Activity Code Filter';
                        ToolTip = 'Specifies the activity code to filter the VAT settlement.';
                        Importance = Additional;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ActivityCodeRec: Record "Activity Code";
                            ActivityCodesPage: Page "Activity Codes";
                        begin
                            ActivityCodesPage.LookupMode(true);
                            if ActivityCodesPage.RunModal() = Action::LookupOK then begin
                                ActivityCodesPage.GetRecord(ActivityCodeRec);
                                ActivityCodeFilter := ActivityCodeRec.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetGLSetup();
            GLSetup.TestField("Last Settlement Date");
            if GLSetup."Last Settlement Date" <> 0D then begin
                EntrdStartDate := GLSetup."Last Settlement Date" + 1;
                CalculateEndDate();
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if GenJnlPostLine.IsGLEntryInconsistent() then
            GenJnlPostLine.ShowInconsistentEntries();
        OnAfterPostReport();
    end;

    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        OnBeforePreReport("VAT Posting Setup", PostSettlement, GLAccSettle, DocNo);

        GetGLSetup();
        if EndDateReq = 0D then
            Error(Text1130000);

        ITReportManagement.CheckSalesDocNoGaps(EndDateReq, true, false);
        ITReportManagement.CheckPurchDocNoGaps(EndDateReq, true, false);

        if PostSettlement then begin
            if EntrdStartDate <= GLSetup."Last Settlement Date" then
                Error(Text1130001, GLSetup."Last Settlement Date");
            if PostingDate = 0D then
                Error(Text000);
            if PostingDate < EndDateReq then
                Error(Text1130002);
            if DocNo = '' then
                Error(Text001);
            if GLAccSettle."No." = '' then
                Error(Text002);
            GLAccSettle.Find();
            if GLAccPosRounding."No." = '' then
                Error(Text1130003);
            GLAccPosRounding.Find();
            if GLAccNegRounding."No." = '' then
                Error(Text1130004);
            GLAccNegRounding.Find();
        end;

        if EntrdStartDate > EndDateReq then
            Error(Text1130005);

        if PostSettlement and not Initialized then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                CurrReport.Quit();

        VATPostingSetupFilter := "VAT Posting Setup".GetFilters();
        if EntrdStartDate = 0D then
            VATEntry.SetFilter("Operation Occurred Date", '..%1', EndDateReq)
        else
            VATEntry.SetRange("Operation Occurred Date", EntrdStartDate, EndDateReq);
        VATDateFilter := VATEntry.GetFilter("Operation Occurred Date");
        Clear(GenJnlPostLine);
        VATPeriod := Format(Date2DMY(EndDateReq, 3)) + '/' +
                     ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0');

#if not CLEAN27
        if FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled() then begin
            if VATSetup.Get() then;
            if VATSetup."Per Activity Code Settl. Entry" then begin
                GLSetup.TestField("Use Activity Code");
                ValidatePreviousEntrySplit();
            end;

            InitializeTotals();
        end else begin
            PriorPeriodVATEntry.SetRange("VAT Period", Format(Date2DMY(EntrdStartDate, 3)) + '/' +
            ConvertStr(Format(Date2DMY(EntrdStartDate, 2), 2), ' ', '0'),
            Format(Date2DMY(EndDateReq, 3)) + '/' + ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'));
            if PriorPeriodVATEntry.FindSet() then begin
                repeat
                    PeriodInputVATYearInputVAT +=
                    PriorPeriodVATEntry."Prior Period Input VAT" + PriorPeriodVATEntry."Prior Year Input VAT" +
                    PriorPeriodVATEntry."Advanced Amount";

                    PeriodOutputVATYearOutputVATAdvAmt +=
                    PriorPeriodVATEntry."Prior Period Output VAT" + PriorPeriodVATEntry."Prior Year Output VAT";
                until PriorPeriodVATEntry.Next() = 0;
                TotalSaleRounded := FiscalRoundAmount(PeriodOutputVATYearOutputVATAdvAmt + TotalSaleAmount);
                TotalPurchRounded := FiscalRoundAmount(PeriodInputVATYearInputVAT - TotalPurchaseAmount);
            end;
        end;
#else
        if VATSetup.Get() then;
        if VATSetup."Per Activity Code Settl. Entry" then begin
            GLSetup.TestField("Use Activity Code");
            ValidatePreviousEntrySplit();
        end;

        InitializeTotals();
#endif
        if PostSettlement then
            GenJnlPostLine.SetIgnoreJournalTemplNameMandatoryCheck();
        OnAfterPreReport("VAT Entry");
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        GLSetup: Record "General Ledger Setup";
        ActivityCode: Record "Activity Code";
        VATSetup: Record "VAT Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
#if not CLEAN27
        FeatureManagementIT: Codeunit "Feature Management IT";
#endif
        PrintVATEntries: Boolean;
        NextVATEntryNo: Integer;
        LastVATEntryNo: Integer;
        DocNo: Code[20];
        VATType: Enum "General Posting Type";
        VATAmount: Decimal;
        VATAmountAddCurr: Decimal;
        FindFirstEntry: Boolean;
        ReversingEntry: Boolean;
        Initialized: Boolean;
        VATPostingSetupFilter: Text;
        VATDateFilter: Text;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[30];
        CountryRegionFilter: Text;
        ActivityCodeFilter: Text;
#if not CLEAN27
        PriorPeriodVATEntry: Record "Periodic Settlement VAT Entry";
        PriorPeriodVATEntry2: Record "Periodic Settlement VAT Entry";
#endif
        Data: Record Date;
        GLAccPosRounding: Record "G/L Account";
        GLAccNegRounding: Record "G/L Account";
        VATPeriod: Code[10];
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        TotalSaleAmount: Decimal;
        TotalPurchaseAmount: Decimal;
        TotalPurchRounded: Decimal;
        TotalSaleRounded: Decimal;
        VATAmountPerActivity, TotalSaleAmountPerActivity, TotalPurchaseAmountPerActivity, TotalPurchRoundedPerActivity, TotalSaleRoundedPerActivity : Dictionary of [Code[6], Decimal];
        CreditNextPeriod: Decimal;
        DebitNextPeriod: Decimal;
        NewVATAmount: Decimal;
        RoundAmount: Decimal;
        VATToPay: Decimal;
        TotalVATNondeducAmnt: Decimal;
        FinalUndVATAmnt: Decimal;
        TotalVATNondeducBase: Decimal;
        PrevPlafondAmount: Decimal;
        UsedPlafondAmount: Decimal;
        GLSetupGet: Boolean;
        TotalVATNondeducBaseAmt: Decimal;
        TotalRemainUnrealBaseAmt: Decimal;
        TotalRemainUnrealAmt: Decimal;
        PeriodInputVATYearInputVAT: Decimal;
        PeriodOutputVATYearOutputVATAdvAmt: Decimal;
#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document no.';
        Text002: Label 'Enter the settlement account.';
        Text003: Label 'Do you want to calculate and post the VAT Settlement?';
        Text004: Label 'VAT Settlement';
#pragma warning disable AA0470
        Text005: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AllAmountsAreInTxt: Label 'All amounts are in %1.', Comment = '%1 = Currency Code';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'Purchase VAT settlement: #1######## #2########';
        Text008: Label 'Sales VAT settlement  : #1######## #2########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TestReportnotpostedCaptionLbl: Label 'Test Report (Not Posted)';
        CalcandPostVATSettlementCaptionLbl: Label 'Calc. and Post VAT Settlement';
        DocNoCaptionLbl: Label 'Document No.';
        GLAccSettleNoCaptionLbl: Label 'Settlement Account';
        VATEntryPostingDateCaptionLbl: Label 'Posting Date';
        VATEntryDocumentTypeCaptionLbl: Label 'Doc Type';
        TotalSaleAmountTotalPurchaseAmountCaptionLbl: Label 'VAT';
        TotalSaleAmountCaptionLbl: Label 'Output VAT';
        PriorPeriodVATEntryPriorPeriodOutputVATPriorPeriodVATEntryPriorYearOutputVATPriorPeriodVATEntryAdvancedAmountCaptionLbl: Label 'Prior Period Output VAT';
        TotalPurchaseAmountCaptionLbl: Label 'Input VAT';
        PriorPeriodVATEntryPriorPeriodInputVATPriorPeriodVATEntryPriorYearInputVATCaptionLbl: Label 'Prior Period Input VAT';
        FinalUndVATAmntCaptionLbl: Label 'Nondeductible Amount';
        TotalSaleRoundedCaptionLbl: Label 'Output VAT (Rounded)';
        TotalPurchRoundedCaptionLbl: Label 'Input VAT (Rounded)';
        VATToPayCaptionLbl: Label 'Total VAT to pay (if positive)';
        DebitNextPeriodCaptionLbl: Label 'Next Period Output VAT';
        CreditNextPeriodCaptionLbl: Label 'Next Period Input VAT';
        VATAmountAddCurrCaptionLbl: Label 'Total';
        GenJnlLineVATBaseAmountCaptionLbl: Label 'Settlement';
        RemainingVATPlafondAmountCaptionLbl: Label 'Remaining VAT Plafond Amount';
        UsedPlafondAmountCaptionLbl: Label 'Used VAT Plafond Amount';
        PrevPlafondAmountCaptionLbl: Label 'Previous VAT Plafond Amount';
        Text1130000: Label 'Please enter the ending date.';
        Text1130001: Label 'Start Date must be greaten than the last Settlement Date :%1';
        Text1130002: Label 'Posting Date cannot be less than the Ending Date';
        Text1130003: Label 'Please enter the G/L Gains  Account';
        Text1130004: Label 'Please enter the G/L Losses Account';
        Text1130005: Label 'Ending Date cannot be less than Starting Date';
        Text1130006: Label 'VAT Settlement Rounding +/-';
        Text1130007: Label 'The last settlement date is %1';
        Text1130008: Label 'The %1 in %2 must not be Blank';
        SplitValidationErr: Label 'Before using Per Activity Code Settlement Entry, you must split the previous entries amounts per activity code manually using "Split Periodic Entry" action on Periodic VAT Settlemnt List page.';

    protected var
        GLAccSettle: Record "G/L Account";
        PostSettlement: Boolean;
        EntrdStartDate: Date;
        EndDateReq: Date;
        PostingDate: Date;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPostingDate: Date; NewDocNo: Code[20]; NewSettlementAcc: Code[20]; NewPosRoundAcc: Code[20]; NewNegRoundAcc: Code[20]; ShowVATEntries: Boolean; Post: Boolean)
    begin
        EntrdStartDate := NewStartDate;
        EndDateReq := NewEndDate;
        PostingDate := NewPostingDate;
        DocNo := NewDocNo;
        GLAccSettle."No." := NewSettlementAcc;
        GLAccPosRounding."No." := NewPosRoundAcc;
        GLAccNegRounding."No." := NewNegRoundAcc;
        PrintVATEntries := ShowVATEntries;
        PostSettlement := Post;
        Initialized := true;
    end;

    local procedure AddToTotals(TotalDictionary: Dictionary of [Code[6], Decimal]; ActivityCodeParam: Code[6]; Amount: Decimal)
    begin
        if not VATSetup."Per Activity Code Settl. Entry" then
            exit;

        if TotalDictionary.ContainsKey(ActivityCodeParam) then
            TotalDictionary.Set(ActivityCodeParam, TotalDictionary.Get(ActivityCodeParam) + Amount)
        else
            TotalDictionary.Add(ActivityCodeParam, Amount);
    end;

    local procedure GetTotalOrZero(TotalDictionary: Dictionary of [Code[6], Decimal]; ActivityCodeParam: Code[6]): Decimal
    begin
        if TotalDictionary.ContainsKey(ActivityCodeParam) then
            exit(TotalDictionary.Get(ActivityCodeParam));
        exit(0);
    end;

    local procedure SafeSet(ToDictionary: Dictionary of [Code[6], Decimal]; ActivityCodeKey: Code[6]; Value: Decimal)
    begin
        if ToDictionary.ContainsKey(ActivityCodeKey) then
            ToDictionary.Set(ActivityCodeKey, Value)
        else
            ToDictionary.Add(ActivityCodeKey, Value);
    end;

    local procedure InitializeTotals()
    var
        ActivityCodeLocal: Record "Activity Code";
    begin
        if VATSetup."Per Activity Code Settl. Entry" then begin
            if ActivityCodeLocal.FindSet() then
                repeat
                    InitializeValuesFromPriorPeriodEntry(ActivityCodeLocal.Code);
                until ActivityCodeLocal.Next() = 0;
        end else
            InitializeValuesFromPriorPeriodEntry();
    end;

    local procedure InitializeValuesFromPriorPeriodEntry()
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
    begin
        PeriodicVATSettlementEntry.SetRange("VAT Period", Format(Date2DMY(EntrdStartDate, 3)) + '/' + ConvertStr(Format(Date2DMY(EntrdStartDate, 2), 2), ' ', '0'), Format(Date2DMY(EndDateReq, 3)) + '/' + ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'));
        if PeriodicVATSettlementEntry.FindSet() then begin
            repeat
                PeriodInputVATYearInputVAT += PeriodicVATSettlementEntry."Prior Period Input VAT" + PeriodicVATSettlementEntry."Prior Year Input VAT" + PeriodicVATSettlementEntry."Advanced Amount";
                PeriodOutputVATYearOutputVATAdvAmt += PeriodicVATSettlementEntry."Prior Period Output VAT" + PeriodicVATSettlementEntry."Prior Year Output VAT";
            until PeriodicVATSettlementEntry.Next() = 0;
            TotalSaleRounded := FiscalRoundAmount(PeriodOutputVATYearOutputVATAdvAmt + TotalSaleAmount);
            TotalPurchRounded := FiscalRoundAmount(PeriodInputVATYearInputVAT - TotalPurchaseAmount);
        end;
    end;

    local procedure InitializeValuesFromPriorPeriodEntry(ActivityCodeParam: Code[6])
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        TempInputVAT, TempOutputVAT : Decimal;
    begin
        PeriodicVATSettlementEntry.SetRange("VAT Period", Format(Date2DMY(EntrdStartDate, 3)) + '/' + ConvertStr(Format(Date2DMY(EntrdStartDate, 2), 2), ' ', '0'), Format(Date2DMY(EndDateReq, 3)) + '/' + ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'));
        PeriodicVATSettlementEntry.SetRange("Activity Code", ActivityCodeParam);
        if PeriodicVATSettlementEntry.FindSet() then begin
            repeat
                TempInputVAT += PeriodicVATSettlementEntry."Prior Period Input VAT" + PeriodicVATSettlementEntry."Prior Year Input VAT" + PeriodicVATSettlementEntry."Advanced Amount";
                PeriodInputVATYearInputVAT += PeriodicVATSettlementEntry."Prior Period Input VAT" + PeriodicVATSettlementEntry."Prior Year Input VAT" + PeriodicVATSettlementEntry."Advanced Amount";
                TempOutputVAT += PeriodicVATSettlementEntry."Prior Period Output VAT" + PeriodicVATSettlementEntry."Prior Year Output VAT";
                PeriodOutputVATYearOutputVATAdvAmt += PeriodicVATSettlementEntry."Prior Period Output VAT" + PeriodicVATSettlementEntry."Prior Year Output VAT";
            until PeriodicVATSettlementEntry.Next() = 0;
            TotalPurchRounded += FiscalRoundAmount(PeriodInputVATYearInputVAT);
            SafeSet(TotalPurchRoundedPerActivity, ActivityCodeParam, FiscalRoundAmount(TempInputVAT));
            TotalSaleRounded += FiscalRoundAmount(PeriodOutputVATYearOutputVATAdvAmt);
            SafeSet(TotalSaleRoundedPerActivity, ActivityCodeParam, FiscalRoundAmount(TempOutputVAT));
        end;
    end;

    procedure InitializeRequest2(NewUseAmtsInAddCurr: Boolean)
    begin
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    /// <summary>
    /// Sets the initialization status for the VAT settlement report.
    /// Controls whether the report parameters have been properly configured.
    /// </summary>
    /// <param name="NewInitialized">True if report is initialized with parameters</param>
    procedure SetInitialized(NewInitialized: Boolean)
    begin
        Initialized := NewInitialized;
    end;

    local procedure CopyAmounts(var GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry")
    begin
        GenJournalLine.Amount := -VATEntry.Amount;
        GenJournalLine."VAT Amount" := -VATEntry.Amount;
        GenJournalLine."VAT Base Amount" := -VATEntry.Base;
        GenJournalLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
        GenJournalLine."Source Currency Amount" := -VATEntry."Additional-Currency Amount";
        GenJournalLine."Source Curr. VAT Amount" := -VATEntry."Additional-Currency Amount";
        GenJournalLine."Source Curr. VAT Base Amount" := -VATEntry."Additional-Currency Base";
        OnAfterCopyAmounts(GenJournalLine, VATEntry);
    end;

    local procedure CreateGenJnlLine(var GenJnlLine2: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        Clear(GenJnlLine2);
        GenJnlLine2."System-Created Entry" := true;
        GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
        GenJnlLine2.Description := GenJnlLine.Description;
        GenJnlLine2."Posting Date" := PostingDate;
        GenJnlLine2."Document Type" := GenJnlLine2."Document Type"::" ";
        GenJnlLine2."Document No." := DocNo;
        GenJnlLine2."Source Code" := SourceCodeSetup."VAT Settlement";
        GenJnlLine2."VAT Posting" := GenJnlLine2."VAT Posting"::"Manual VAT Entry";
        GenJnlLine2."Account No." := AccountNo;
        GenJnlLine2.Amount := VATEntry.Amount;
        GenJnlLine2."Source Currency Code" := GLSetup."Additional Reporting Currency";
        GenJnlLine2."Source Currency Amount" := VATEntry."Additional-Currency Amount";
    end;

    [Scope('OnPrem')]
    procedure FiscalRoundAmount(AmountToRound: Decimal) Amount: Decimal
    begin
        if GLSetup."Settlement Round. Factor" <> 0 then
            Amount := Round(AmountToRound, GLSetup."Settlement Round. Factor")
        else
            Error(Text1130008, GLSetup.FieldCaption("Settlement Round. Factor"), GLSetup.TableCaption());
    end;

    [Scope('OnPrem')]
    procedure CalculateEndDate()
    begin
        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                Data."Period Type" := Data."Period Type"::Month;
            GLSetup."VAT Settlement Period"::Quarter:
                Data."Period Type" := Data."Period Type"::Quarter;
        end;

        if Data.Get(Data."Period Type", EntrdStartDate) then
            if Data.Find('>') then begin
                EndDateReq := Data."Period Start" - 1;
                PostingDate := EndDateReq;
            end;
    end;

    [Scope('OnPrem')]
    procedure GetGLSetup()
    begin
        if not GLSetupGet then begin
            GLSetup.Get();
            GLSetupGet := true;
        end;
    end;

#if not CLEAN27
    local procedure UpdatePeriodicSettlementVATEntry()
    var
        DateFormula: DateFormula;
        IsNewYear: Boolean;
    begin
        if PriorPeriodVATEntry.Get(Format(Date2DMY(EndDateReq, 3)) + '/' +
          ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'))
        then begin
            if (NewVATAmount = 0) and (VATAmount = 0) then begin
                if CreditNextPeriod <> 0 then
                    PriorPeriodVATEntry."VAT Settlement" := CreditNextPeriod
                else
                    PriorPeriodVATEntry."VAT Settlement" := DebitNextPeriod;
            end else
                PriorPeriodVATEntry."VAT Settlement" := NewVATAmount;

            PriorPeriodVATEntry."VAT Period Closed" := true;
            PriorPeriodVATEntry.Modify();
        end else begin
            PriorPeriodVATEntry."VAT Period" := Format(Date2DMY(EndDateReq, 3)) + '/' +
              ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0');
            PriorPeriodVATEntry."VAT Settlement" := NewVATAmount;
            PriorPeriodVATEntry."VAT Period Closed" := true;
            PriorPeriodVATEntry.Insert(true);
        end;

        // Post Rounding Amount to G/L Gains or Losses Account
        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                Evaluate(DateFormula, '<1D>');
            GLSetup."VAT Settlement Period"::Quarter:
                Evaluate(DateFormula, '<CQ+1Q>');
        end;

        PriorPeriodVATEntry2.Init();
        PriorPeriodVATEntry2."VAT Period" :=
          Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 3)) + '/' +
          ConvertStr(Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 2), 2), ' ', '0');
        PriorPeriodVATEntry2.Insert();

        IsNewYear := Date2DMY(CalcDate(DateFormula, EndDateReq), 3) <> Date2DMY(EndDateReq, 3);
        if (TotalSaleAmount = 0) and (TotalPurchaseAmount = 0) then
            if (PriorPeriodVATEntry."Prior Period Input VAT" <> 0) or (PriorPeriodVATEntry."Prior Year Input VAT" <> 0) then
                CreditNextPeriod := PriorPeriodVATEntry."Prior Period Input VAT" + PriorPeriodVATEntry."Prior Year Input VAT"
            else
                DebitNextPeriod := PriorPeriodVATEntry."Prior Period Output VAT" + PriorPeriodVATEntry."Prior Year Output VAT";

        if CreditNextPeriod <> 0 then
            if IsNewYear then
                PriorPeriodVATEntry2."Prior Year Input VAT" := CreditNextPeriod
            else
                PriorPeriodVATEntry2."Prior Period Input VAT" := CreditNextPeriod
        else
            if DebitNextPeriod <> 0 then
                if IsNewYear then
                    PriorPeriodVATEntry2."Prior Year Output VAT" := Abs(DebitNextPeriod)
                else
                    PriorPeriodVATEntry2."Prior Period Output VAT" := Abs(DebitNextPeriod);

        PriorPeriodVATEntry2.Modify(true);
        GLSetup."Last Settlement Date" := EndDateReq;
        GLSetup.Modify();
    end;
#endif

    local procedure UpdatePeriodicSettlementVATEntryActivityCode()
    var
        ActivityCodeLocal: Record "Activity Code";
        PriorPeriodVATEntry: Record "Periodic VAT Settlement Entry";
        PriorPeriodVATEntry2: Record "Periodic VAT Settlement Entry";
        DateFormula: DateFormula;
        IsNewYear: Boolean;
        NewVATAmount: Decimal;
    begin
        if VATSetup."Per Activity Code Settl. Entry" then begin
            if ActivityCodeLocal.Findset() then
                repeat
                    UpdatePeriodicSettlementVATEntry(ActivityCodeLocal.Code);
                until ActivityCodeLocal.Next() = 0;
            exit;
        end;

        if PriorPeriodVATEntry.Get(Format(Date2DMY(EndDateReq, 3)) + '/' +
          ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'))
        then begin
            NewVATAmount := TotalPurchRounded - TotalSaleRounded;

            if (NewVATAmount = 0) and (VATAmount = 0) then begin
                if CreditNextPeriod <> 0 then
                    PriorPeriodVATEntry."VAT Settlement" := CreditNextPeriod
                else
                    PriorPeriodVATEntry."VAT Settlement" := DebitNextPeriod;
            end else
                PriorPeriodVATEntry."VAT Settlement" := NewVATAmount;

            PriorPeriodVATEntry."VAT Period Closed" := true;
            PriorPeriodVATEntry.Modify();
        end else begin
            PriorPeriodVATEntry."VAT Period" := Format(Date2DMY(EndDateReq, 3)) + '/' +
              ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0');
            PriorPeriodVATEntry."VAT Settlement" := NewVATAmount;
            PriorPeriodVATEntry."VAT Period Closed" := true;
            PriorPeriodVATEntry.Insert(true);
        end;

        // Post Rounding Amount to G/L Gains or Losses Account
        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                Evaluate(DateFormula, '<1D>');
            GLSetup."VAT Settlement Period"::Quarter:
                Evaluate(DateFormula, '<CQ+1Q>');
        end;

        PriorPeriodVATEntry2.Init();
        PriorPeriodVATEntry2."VAT Period" :=
          Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 3)) + '/' +
          ConvertStr(Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 2), 2), ' ', '0');
        PriorPeriodVATEntry2.Insert();

        IsNewYear := Date2DMY(CalcDate(DateFormula, EndDateReq), 3) <> Date2DMY(EndDateReq, 3);
        if (TotalSaleAmount = 0) and (TotalPurchaseAmount = 0) then
            if (PriorPeriodVATEntry."Prior Period Input VAT" <> 0) or (PriorPeriodVATEntry."Prior Year Input VAT" <> 0) then
                CreditNextPeriod := PriorPeriodVATEntry."Prior Period Input VAT" + PriorPeriodVATEntry."Prior Year Input VAT"
            else
                DebitNextPeriod := PriorPeriodVATEntry."Prior Period Output VAT" + PriorPeriodVATEntry."Prior Year Output VAT";

        if CreditNextPeriod <> 0 then
            if IsNewYear then
                PriorPeriodVATEntry2."Prior Year Input VAT" := CreditNextPeriod
            else
                PriorPeriodVATEntry2."Prior Period Input VAT" := CreditNextPeriod
        else
            if DebitNextPeriod <> 0 then
                if IsNewYear then
                    PriorPeriodVATEntry2."Prior Year Output VAT" := Abs(DebitNextPeriod)
                else
                    PriorPeriodVATEntry2."Prior Period Output VAT" := Abs(DebitNextPeriod);

        PriorPeriodVATEntry2.Modify(true);
        GLSetup."Last Settlement Date" := EndDateReq;
        GLSetup.Modify();
    end;

    local procedure UpdatePeriodicSettlementVATEntry(ActivityCode: Code[6])
    var
        PeriodicVATSettlementEntryPrior: Record "Periodic VAT Settlement Entry";
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        DateFormula: DateFormula;
        IsNewYear: Boolean;
        NewVATAmount: Decimal;
        CreditNextPeriod: Decimal;
        DebitNextPeriod: Decimal;
    begin
        SafeSet(TotalSaleRoundedPerActivity, ActivityCode, FiscalRoundAmount(GetTotalOrZero(TotalSaleRoundedPerActivity, ActivityCode) + GetTotalOrZero(TotalSaleAmountPerActivity, ActivityCode)));
        SafeSet(TotalPurchRoundedPerActivity, ActivityCode, FiscalRoundAmount(GetTotalOrZero(TotalPurchRoundedPerActivity, ActivityCode) - GetTotalOrZero(TotalPurchaseAmountPerActivity, ActivityCode)));

        NewVATAmount := GetTotalOrZero(TotalPurchRoundedPerActivity, ActivityCode) - GetTotalOrZero(TotalSaleRoundedPerActivity, ActivityCode);
        if NewVATAmount > 0 then
            CreditNextPeriod := NewVATAmount
        else
            // VAT Settlement
            if -NewVATAmount <= GLSetup."Minimum VAT Payable" then
                DebitNextPeriod := NewVATAmount;

        if PeriodicVATSettlementEntryPrior.Get(Format(Date2DMY(EndDateReq, 3)) + '/' + ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0'), ActivityCode)
        then begin
            if (NewVATAmount = 0) and (VATAmount = 0) then begin
                if CreditNextPeriod <> 0 then
                    PeriodicVATSettlementEntryPrior."VAT Settlement" := CreditNextPeriod
                else
                    PeriodicVATSettlementEntryPrior."VAT Settlement" := DebitNextPeriod;
            end else
                PeriodicVATSettlementEntryPrior."VAT Settlement" := NewVATAmount;

            PeriodicVATSettlementEntryPrior."VAT Period Closed" := true;
            PeriodicVATSettlementEntryPrior.Modify();
        end else begin
            PeriodicVATSettlementEntryPrior."VAT Period" := Format(Date2DMY(EndDateReq, 3)) + '/' +
              ConvertStr(Format(Date2DMY(EndDateReq, 2), 2), ' ', '0');
            PeriodicVATSettlementEntryPrior."Activity Code" := ActivityCode;
            PeriodicVATSettlementEntryPrior."VAT Settlement" := NewVATAmount;
            PeriodicVATSettlementEntryPrior."VAT Period Closed" := true;
            PeriodicVATSettlementEntryPrior.Insert(true);
        end;

        // Post Rounding Amount to G/L Gains or Losses Account
        case GLSetup."VAT Settlement Period" of
            GLSetup."VAT Settlement Period"::Month:
                Evaluate(DateFormula, '<1D>');
            GLSetup."VAT Settlement Period"::Quarter:
                Evaluate(DateFormula, '<CQ+1Q>');
        end;

        PeriodicVATSettlementEntry.Init();
        PeriodicVATSettlementEntry."VAT Period" := Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 3)) + '/' + ConvertStr(Format(Date2DMY(CalcDate(DateFormula, EndDateReq), 2), 2), ' ', '0');
        PeriodicVATSettlementEntry."Activity Code" := ActivityCode;
        PeriodicVATSettlementEntry.Insert();

        IsNewYear := Date2DMY(CalcDate(DateFormula, EndDateReq), 3) <> Date2DMY(EndDateReq, 3);
        if (GetTotalOrZero(TotalSaleAmountPerActivity, ActivityCode) = 0) and (GetTotalOrZero(TotalPurchaseAmountPerActivity, ActivityCode) = 0) then
            if (PeriodicVATSettlementEntryPrior."Prior Period Input VAT" <> 0) or (PeriodicVATSettlementEntryPrior."Prior Year Input VAT" <> 0) then
                CreditNextPeriod := PeriodicVATSettlementEntryPrior."Prior Period Input VAT" + PeriodicVATSettlementEntryPrior."Prior Year Input VAT"
            else
                DebitNextPeriod := PeriodicVATSettlementEntryPrior."Prior Period Output VAT" + PeriodicVATSettlementEntryPrior."Prior Year Output VAT";

        if CreditNextPeriod <> 0 then
            if IsNewYear then
                PeriodicVATSettlementEntry."Prior Year Input VAT" := CreditNextPeriod
            else
                PeriodicVATSettlementEntry."Prior Period Input VAT" := CreditNextPeriod
        else
            if DebitNextPeriod <> 0 then
                if IsNewYear then
                    PeriodicVATSettlementEntry."Prior Year Output VAT" := Abs(DebitNextPeriod)
                else
                    PeriodicVATSettlementEntry."Prior Period Output VAT" := Abs(DebitNextPeriod);

        PeriodicVATSettlementEntry.Modify(true);
        GLSetup."Last Settlement Date" := EndDateReq;
        GLSetup.Modify();
    end;

    local procedure SetVatPostingSetupToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Settlement;
        GenJnlLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GenJnlLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GenJnlLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
    end;

    local procedure CloseVATEntriesOnPostSettlement(var VATEntry: Record "VAT Entry"; NextVATEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCloseVATEntriesOnPostSettlement(VATEntry, NextVATEntryNo, IsHandled);
        if IsHandled then
            exit;

        VATEntry.ModifyAll("Closed by Entry No.", NextVATEntryNo);
        VATEntry.ModifyAll(Closed, true);

        VATEntry.SetRange(Closed, true);
        VATEntry.ModifyAll("VAT Period", VATPeriod);
        VATEntry.SetRange(Closed, false);
    end;

    local procedure GetSettlementVATEntryNo(PostVATSettlement: Boolean; IsPostingAllowed: Boolean): Integer
    var
        NextAvailableVATEntryNo: Integer;
        LastPostedVATEntryNo: Integer;
    begin
        if not IsPostingAllowed then
            exit(0);

        if PostVATSettlement then begin
            NextAvailableVATEntryNo := GenJnlPostLine.GetNextVATEntryNo();
            if NextAvailableVATEntryNo <> 0 then
                LastPostedVATEntryNo := NextAvailableVATEntryNo - 1;
            exit(LastPostedVATEntryNo);
        end;

        RestoreNextVATEntryNo();
        NextVATEntryNo += 1;
        SaveNextVATEntryNo();
        exit(NextVATEntryNo);
    end;

    local procedure GetVATPeriodTextFromDate(InputDate: Date): Text[10]
    begin
        exit(Format(Date2DMY(InputDate, 3)) + '/' + ConvertStr(Format(Date2DMY(InputDate, 2), 2), ' ', '0'));
    end;

    local procedure SaveNextVATEntryNo()
    begin
        LastVATEntryNo := NextVATEntryNo;
    end;

    local procedure RestoreNextVATEntryNo()
    begin
        if LastVATEntryNo <> 0 then
            NextVATEntryNo := LastVATEntryNo;
    end;

    local procedure UpdateVATPeriodOnSettlementVATEntry(SettlementVATEntryNo: Integer)
    var
        SttlmtVATEntry: Record "VAT Entry";
    begin
        if SttlmtVATEntry.Get(SettlementVATEntryNo) then begin
            SttlmtVATEntry.Validate("VAT Period", VATPeriod);
            SttlmtVATEntry.Modify(true);
        end;
    end;

    local procedure ValidatePreviousEntrySplit()
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        PeriodicVATSettlement: Codeunit "Periodic VAT Settlement";
    begin
        if PeriodicVATSettlementEntry.Get(GetVATPeriodTextFromDate(EndDateReq), '') then
            if not PeriodicVATSettlement.ValidateSplit(GetVATPeriodTextFromDate(EndDateReq)) then
                Error(SplitValidationErr);
    end;

    /// <summary>
    /// Integration event raised after VAT settlement report processing is complete.
    /// Enables custom cleanup operations and finalization logic after settlement posting.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPreReport(var VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking VAT entries for print output.
    /// Enables custom filtering and validation of VAT entries included in settlement report.
    /// </summary>
    /// <param name="VATEntry">VAT entry record to validate for report inclusion</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport()
    begin
    end;

    /// <summary>
    /// Integration event raised before posting general journal line for reverse charge VAT settlement.
    /// Enables custom amount calculations and journal line modifications for reverse charge scenarios.
    /// </summary>
    /// <param name="GenJnlLine">General journal line being prepared for reverse charge VAT posting</param>
    /// <param name="VATEntry">Source VAT entry for reverse charge calculation</param>
    /// <param name="VATAmount">VAT amount in local currency</param>
    /// <param name="VATAmountAddCurr">VAT amount in additional reporting currency</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrintVATEntries(var VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before VAT settlement report execution begins.
    /// Enables custom setup validation and parameter modification before settlement processing starts.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record defining settlement processing rules</param>
    /// <param name="PostSettlement">Whether settlement entries will be posted to General Ledger</param>
    /// <param name="GLAccountSettle">G/L account designated for VAT settlement entries</param>
    /// <param name="DocNo">Document number for settlement journal entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var VATPostingSetup: Record "VAT Posting Setup"; PostSettlement: Boolean; GLAccountSettle: Record "G/L Account"; var DocNo: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before closing VAT entries during settlement posting.
    /// Enables custom validation and modification of VAT entries before they are marked as closed.
    /// </summary>
    /// <param name="VATEntry">VAT entry being processed for closure</param>
    /// <param name="NextVATEntryNo">Next available VAT entry number for new entries</param>
    /// <param name="IsHandled">Set to true to skip standard VAT entry closure processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseVATEntriesOnPostSettlement(var VATEntry: Record "VAT Entry"; NextVATEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('The event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrementGenPostingType(OldGenPostingType: Enum "General Posting Type"; var NewGenPostingType: Enum "General Posting Type")
    begin
    end;
#endif

    /// <summary>
    /// Integration event raised after setting VAT entry filters during settlement processing.
    /// Enables custom filter modifications and VAT entry selection logic for closing operations.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup defining processing context</param>
    /// <param name="VATEntry">Primary VAT entry record with applied filters</param>
    /// <param name="VATEntry2">Secondary VAT entry record for additional filtering</param>
    [IntegrationEvent(true, false)]
    local procedure OnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters(VATPostingSetup: Record "VAT Posting Setup"; var VATEntry: Record "VAT Entry"; var VATEntry2: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting VAT entry filters for normal VAT processing during settlement.
    /// Enables custom filter adjustments and VAT entry selection logic for normal VAT scenarios.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup defining processing context</param>
    /// <param name="VATType">General posting type being processed</param>
    /// <param name="VATEntry">VAT entry record with applied filters</param>
    /// <param name="FindFirstEntry">Whether to find the first entry in the filtered set</param>
    [IntegrationEvent(false, false)]
    local procedure OnClosingGLAndVATEntryOnAfterGetRecordOnNormalVATOnAfterVATEntrySetFilter(VATPostingSetup: Record "VAT Posting Setup"; VATType: enum "General Posting Type"; var VATEntry: Record "VAT Entry"; FindFirstEntry: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting VAT entry filters for sales tax processing during settlement.
    /// Enables custom filter adjustments and VAT entry selection logic for sales tax scenarios.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup defining processing context</param>
    /// <param name="VATType">General posting type being processed</param>
    /// <param name="VATEntry">VAT entry record with applied filters</param>
    /// <param name="FindFirstEntry">Whether to find the first entry in the filtered set</param>
    [IntegrationEvent(false, false)]
    local procedure OnClosingGLAndVATEntryOnAfterGetRecordOnSalesTaxOnAfterVATEntrySetFilter(VATPostingSetup: Record "VAT Posting Setup"; VATType: enum "General Posting Type"; var VATEntry: Record "VAT Entry"; FindFirstEntry: Boolean)
    begin
    end;

#if not CLEAN27
    /// <summary>
    /// Integration event raised before running general journal posting line during VAT settlement.
    /// Enables custom validation and modification of journal lines before posting to General Ledger.
    /// </summary>
    /// <param name="GenJnlLine">General journal line being prepared for posting</param>
    [Obsolete('The event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
#endif

    /// <summary>
    /// Integration event raised after copying amounts from VAT entry to general journal line.
    /// Enables custom amount calculations and journal line adjustments during settlement processing.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with copied amounts</param>
    /// <param name="VATEntry">Source VAT entry providing amount data</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAmounts(var GenJournalLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after processing VAT posting setup data item during settlement.
    /// Enables custom finalization logic and data validation after VAT posting setup processing.
    /// </summary>
    /// <param name="GenJnlLine">General journal line created during processing</param>
    /// <param name="PostSettlement">Whether settlement entries are being posted to General Ledger</param>
    [IntegrationEvent(false, false)]
    local procedure OnVATPostingSetupOnAfterOnPostDataItem(GenJnlLine: Record "Gen. Journal Line"; PostSettlement: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before posting settlement entry during VAT posting setup processing.
    /// Enables custom validation and modification of journal lines before settlement posting.
    /// </summary>
    /// <param name="GenJnlLine">General journal line being prepared for posting</param>
    [IntegrationEvent(false, false)]
    local procedure OnVATPostingSetupOnPostDataItemOnBeforePostSettlement(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}
