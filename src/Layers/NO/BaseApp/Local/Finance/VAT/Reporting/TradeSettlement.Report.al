// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;

report 10602 "Trade Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/TradeSettlement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Tradesettlement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group");
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VATDateFilter; Text1080000 + ': ' + VATDateFilter)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(IncludeText; IncludeText)
            {
            }
            column(ShowVATEntries; ShowVATEntries)
            {
            }
            column(ShowChangeHeader; ShowChangeHeader)
            {
            }
            column(LastPage; LastPage)
            {
            }
            column(VATBusPostGroup_VATEntry; "VAT Bus. Posting Group")
            {
            }
            column(VATProdPostGroup_VATEntry; "VAT Prod. Posting Group")
            {
            }
            column(Type_VATEntry; Type)
            {
            }
            column(ShowGroupHeader; ShowGroupHeader)
            {
            }
            column(BaseWithVAT; BaseWithVAT)
            {
            }
            column(PostDate_VATEntry; "Posting Date")
            {
            }
            column(DocNo_VATEntry; "Document No.")
            {
            }
            column(DocType_VATEntry; "Document Type")
            {
            }
            column(BilltoPaytoNo_VATEntry; "Bill-to/Pay-to No.")
            {
            }
            column(Amount_VATEntry; Amount)
            {
            }
            column(BaseWithoutVAT; BaseWithoutVAT)
            {
            }
            column(EntryNo_VATEntry; "Entry No.")
            {
            }
            column(Closed_VATEntry; Closed)
            {
            }
            column(BaseOutside; BaseOutside)
            {
            }
            column(SubtotalText; SubtotalText)
            {
            }
            column(GroupTotal; GroupTotal)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(TotalSaleBaseOutsideSales; TotalSale + BaseOutsideSales)
            {
            }
            column(TotalSale; TotalSale)
            {
            }
            column(SaleWithoutTax; SaleWithoutTax)
            {
            }
            column(SaleWithTaxHigh; SaleWithTaxHigh)
            {
            }
            column(SalesTaxHigh; SalesTaxHigh)
            {
            }
            column(SalesTaxLow; SalesTaxLow)
            {
            }
            column(SaleWithTaxLow; SaleWithTaxLow)
            {
            }
            column(SalesTaxServ; SalesTaxServ)
            {
            }
            column(SaleWithTaxServ; SaleWithTaxServ)
            {
            }
            column(PurchaseTaxHigh; PurchaseTaxHigh)
            {
            }
            column(PurchaseTaxLow; PurchaseTaxLow)
            {
            }
            column(OutstandingTaxStd; OutstandingTaxStd)
            {
            }
            column(V11TaxTextStd; '11. ' + TaxTextStd)
            {
            }
            column(PurchaseTaxMedium; PurchaseTaxMedium)
            {
            }
            column(SalesTaxMedium; SalesTaxMedium)
            {
            }
            column(SaleWithTaxMedium; SaleWithTaxMedium)
            {
            }
            column(GLSetupNonTaxable; GLSetup."Non-Taxable")
            {
            }
            column(V2TaxTextService; '2. ' + TaxTextService)
            {
            }
            column(OutstandingTaxServ; OutstandingTaxServ)
            {
            }
            column(VATWarning; VATWarning)
            {
            }
            column(TradesettlementVATInvstmntTaxCaption; TradesettlementVATInvstmntTaxCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(IncludesclosedVATPeriodsCaption; IncludesclosedVATPeriodsCaptionLbl)
            {
            }
            column(VATCaption; VATCaptionLbl)
            {
            }
            column(BaseWithVATCaption; BaseWithVATCaptionLbl)
            {
            }
            column(EntryNoCaption_VATEntry; FieldCaption("Entry No."))
            {
            }
            column(BilltoPaytoNoCaption_VATEntry; FieldCaption("Bill-to/Pay-to No."))
            {
            }
            column(DocTypeCaption_VATEntry; FieldCaption("Document Type"))
            {
            }
            column(DocNoCaption_VATEntry; FieldCaption("Document No."))
            {
            }
            column(PostDateCaption_VATEntry; FieldCaption("Posting Date"))
            {
            }
            column(ClosedCaption_VATEntry; FieldCaption(Closed))
            {
            }
            column(BaseWithoutVATCaption; BaseWithoutVATCaptionLbl)
            {
            }
            column(BaseOutsideCaption; BaseOutsideCaptionLbl)
            {
            }
            column(VATBusPostGroupCaption_VATEntry; FieldCaption("VAT Bus. Posting Group"))
            {
            }
            column(VATProdPostGroupCaption_VATEntry; FieldCaption("VAT Prod. Posting Group"))
            {
            }
            column(TypeCaption_VATEntry; FieldCaption(Type))
            {
            }
            column(TotalPurchandSaleCaption; TotalPurchandSaleCaptionLbl)
            {
            }
            column(TotalSaleBaseOutsideSalesCaption; TotalSaleBaseOutsideSalesCaptionLbl)
            {
            }
            column(TotalSaleCaption; TotalSaleCaptionLbl)
            {
            }
            column(SaleWithoutTaxCaption; SaleWithoutTaxCaptionLbl)
            {
            }
            column(SaleWithTaxHighCaption; SaleWithTaxHighCaptionLbl)
            {
            }
            column(PlusCaption; PlusCaptionLbl)
            {
            }
            column(SaleWithTaxLowCaption; SaleWithTaxLowCaptionLbl)
            {
            }
            column(SaleWithTaxServCaption; SaleWithTaxServCaptionLbl)
            {
            }
            column(PurchaseTaxHighCaption; PurchaseTaxHighCaptionLbl)
            {
            }
            column(MinusCaption; MinusCaptionLbl)
            {
            }
            column(PurchaseTaxLowCaption; PurchaseTaxLowCaptionLbl)
            {
            }
            column(EqualCaption; EqualCaptionLbl)
            {
            }
            column(StandardTradesettlementCaption; StandardTradesettlementCaptionLbl)
            {
            }
            column(PurchaseTaxMediumCaption; PurchaseTaxMediumCaptionLbl)
            {
            }
            column(SaleWithTaxMediumCaption; SaleWithTaxMediumCaptionLbl)
            {
            }
            column(TradesettlementforservimportCaption; TradesettlementforservimportCaptionLbl)
            {
            }
            column(SaleWithTaxServiceCaption; SaleWithTaxServiceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ShowGroupFooter := true;
                ShowGroupHeader := true;
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");

                case "Base Amount Type" of
                    "Base Amount Type"::"With VAT":
                        BaseWithVAT := Base;
                    "Base Amount Type"::"Without VAT":
                        BaseWithoutVAT := Base;
                    "Base Amount Type"::"Outside Tax Area":
                        begin
                            BaseOutside := Base;
                            if Type = Type::Sale then
                                BaseOutsideSales := BaseOutsideSales - BaseOutside;
                        end;
                end;

                if "Base Amount Type" <> "Base Amount Type"::"Outside Tax Area" then
                    case Type of
                        Type::Sale:
                            begin
                                TotalSale := TotalSale - Base;
                                case VATPostingSetup."VAT Settlement Rate" of
                                    VATPostingSetup."VAT Settlement Rate"::Low:
                                        SalesTaxLow := SalesTaxLow - Amount;
                                    VATPostingSetup."VAT Settlement Rate"::Medium:
                                        SalesTaxMedium := SalesTaxMedium - Amount;
                                    VATPostingSetup."VAT Settlement Rate"::Normal:
                                        SalesTaxHigh := SalesTaxHigh - Amount;
                                end;
                                case "Base Amount Type" of
                                    "Base Amount Type"::"With VAT":
                                        case VATPostingSetup."VAT Settlement Rate" of
                                            VATPostingSetup."VAT Settlement Rate"::Low:
                                                SaleWithTaxLow := SaleWithTaxLow - Base;
                                            VATPostingSetup."VAT Settlement Rate"::Medium:
                                                SaleWithTaxMedium := SaleWithTaxMedium - Base;
                                            VATPostingSetup."VAT Settlement Rate"::Normal:
                                                SaleWithTaxHigh := SaleWithTaxHigh - Base;
                                        end;
                                    "Base Amount Type"::"Without VAT":
                                        SaleWithoutTax := SaleWithoutTax - Base;
                                end;
                            end;
                        Type::Purchase:
                            begin
                                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then begin
                                    SalesTaxServ := SalesTaxServ + Amount;
                                    SaleWithTaxServ := SaleWithTaxServ + Base;
                                end;
                                case VATPostingSetup."VAT Settlement Rate" of
                                    VATPostingSetup."VAT Settlement Rate"::Low:
                                        PurchaseTaxLow := PurchaseTaxLow + Amount;
                                    VATPostingSetup."VAT Settlement Rate"::Medium:
                                        PurchaseTaxMedium := PurchaseTaxMedium + Amount;
                                    VATPostingSetup."VAT Settlement Rate"::Normal:
                                        PurchaseTaxHigh := PurchaseTaxHigh + Amount;
                                end;
                            end;
                    end;
                GroupTotal := 'Total';
                SubtotalText := StrSubstNo('Total %1', "VAT Entry".Type);

                SumTax := SalesTaxHigh + SalesTaxMedium + SalesTaxLow + SalesTaxServ;
                OutstandingTaxStd := SumTax - PurchaseTaxHigh - PurchaseTaxMedium - PurchaseTaxLow;
                if OutstandingTaxStd < 0 then
                    TaxTextStd := Text1080002
                else
                    TaxTextStd := Text1080003;

                OutstandingTaxServ := SalesTaxServ;
                if OutstandingTaxServ < 0 then begin
                    TaxTextService := Text1080002;
                    OutstandingTaxServ := -OutstandingTaxServ;
                end else
                    TaxTextService := Text1080003;

                VATWarning := '';
                if OutstandingTaxStd <> 0 then
                    VATWarning := Text1080007
            end;

            trigger OnPreDataItem()
            var
                StartYear: Integer;
                EndYear: Integer;
                StartPeriod: Integer;
                EndPeriod: Integer;
            begin
                GLSetup.Get();

                case Selection of
                    Selection::Open:
                        SetRange(Closed, false);
                    Selection::Closed:
                        SetRange(Closed, true);
                    Selection::"Open and Closed":
                        SetRange(Closed);
                end;
                SetFilter(Type, '%1|%2', Type::Purchase, Type::Sale);
                SetFilter("VAT Reporting Date", VATDateFilter);

                CalculatePeriod(StartDate, StartPeriod, StartYear);
                CalculatePeriod(EndDate, EndPeriod, EndYear);
                SettledVATPeriod.SetRange("Period No.", StartPeriod, EndPeriod);
                SettledVATPeriod.SetRange(Year, StartYear, EndYear);
                SettledVATPeriod.SetRange(Closed, true);
                ShowChangeHeader := SettledVATPeriod.Count <> 0;

                case Selection of
                    Selection::Open:
                        IncludeText := StrSubstNo(Text1080001, Text1080004);
                    Selection::Closed:
                        IncludeText := StrSubstNo(Text1080001, Text1080005);
                    Selection::"Open and Closed":
                        IncludeText := StrSubstNo(Text1080001, Text1080006);
                end;

                ShowGroupHeader := true;
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
                    field(SettlementPeriod; SettlementPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Period';
                        TableRelation = "VAT Period"."Period No.";
                        ToolTip = 'Specifies the VAT period to settle.';

                        trigger OnValidate()
                        begin
                            if SettlementYear = 0 then
                                SettlementYear := Date2DMY(Today, 3);
                            CalculateStartEnd(SettlementPeriod, SettlementYear, StartDate, EndDate);
                        end;
                    }
                    field(SettlementYear; SettlementYear)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Year';
                        ToolTip = 'Specifies the year for which you want to settle. By default, the current year is displayed.';

                        trigger OnValidate()
                        var
                            TempDate: Date;
                        begin
                            // Change from 2 to 4 digits
                            Evaluate(TempDate, StrSubstNo('0101%1', SettlementYear));
                            SettlementYear := Date2DMY(TempDate, 3);

                            if SettlementPeriod = 0 then
                                SettlementPeriod := 1;
                            CalculateStartEnd(SettlementPeriod, SettlementYear, StartDate, EndDate);
                        end;
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start date';
                        ToolTip = 'Specifies the start date for the period that you want to settle. By default, the start date for the period specified in the VAT Period field is displayed.';

                        trigger OnValidate()
                        begin
                            SettlementPeriod := 0;
                            SettlementYear := 0;
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End date';
                        ToolTip = 'Specifies the end date for the period that you want to settle. By default, the end date for the period specified in the VAT Period field is displayed.';

                        trigger OnValidate()
                        begin
                            SettlementPeriod := 0;
                            SettlementYear := 0;
                        end;
                    }
                    field(ShowVATEntries; ShowVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show VAT Entries';
                        ToolTip = 'Specifies if you want to print the individual VAT entries in the first part of the report. If this field is not selected, only the totals for the VAT posting groups will be displayed.';
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies which type of VAT entries you want to include in the trade settlement. Open: To settle a VAT period that has not been settled previously. Closed: To print information about VAT entries that you have settled previously. Open and Closed: To check all entries in a period.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            periodNo: Integer;
        begin
            CalculatePeriod(WorkDate(), periodNo, SettlementYear);
            Commit();
            SettlementPeriod := periodNo;
            CalculateStartEnd(SettlementPeriod, SettlementYear, StartDate, EndDate);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if EndDate = 0D then
            "VAT Entry".SetFilter("VAT Reporting Date", '%1..', StartDate)
        else
            "VAT Entry".SetRange("VAT Reporting Date", StartDate, EndDate);
        VATDateFilter := CopyStr("VAT Entry".GetFilter("VAT Reporting Date"), 1, 30);
    end;

    var
        VATPostingSetup: Record "VAT Posting Setup";
        SettledVATPeriod: Record "Settled VAT Period";
        VATPeriod: Record "VAT Period";
        GLSetup: Record "General Ledger Setup";
        VATTools: Codeunit "Norwegian VAT Tools";
        SettlementPeriod: Integer;
        SettlementYear: Integer;
        StartDate: Date;
        EndDate: Date;
        Selection: Enum "VAT Statement Report Selection";
        VATDateFilter: Text[30];
        TotalSale: Decimal;
        SaleWithTaxHigh: Decimal;
        SaleWithTaxMedium: Decimal;
        SaleWithTaxLow: Decimal;
        SaleWithTaxServ: Decimal;
        SaleWithoutTax: Decimal;
        SalesTaxHigh: Decimal;
        SalesTaxMedium: Decimal;
        SalesTaxLow: Decimal;
        SalesTaxServ: Decimal;
        SumTax: Decimal;
        PurchaseTaxHigh: Decimal;
        PurchaseTaxMedium: Decimal;
        PurchaseTaxLow: Decimal;
        OutstandingTaxStd: Decimal;
        OutstandingTaxServ: Decimal;
        TaxTextStd: Text[30];
        TaxTextService: Text[30];
        ShowVATEntries: Boolean;
        BaseWithVAT: Decimal;
        BaseWithoutVAT: Decimal;
        BaseOutside: Decimal;
        BaseOutsideSales: Decimal;
        LastPage: Boolean;
        ShowChangeHeader: Boolean;
        ShowGroupHeader: Boolean;
        ShowGroupFooter: Boolean;
        SubtotalText: Text[30];
        Text1080000: Label 'Period';
        Text1080001: Label 'Includes VAT Entries: %1';
        Text1080002: Label 'Outstanding Tax';
        Text1080003: Label 'Tax to pay';
        Text1080004: Label 'Open';
        Text1080005: Label 'Closed';
        Text1080006: Label 'Open and Closed';
        IncludeText: Text[50];
        Text1080007: Label 'Warning: VAT has been calculated in the period even though VAT Exemption has been used!';
        VATWarning: Text[250];
        GroupTotal: Text[30];
        PageCaptionLbl: Label 'Page';
        IncludesclosedVATPeriodsCaptionLbl: Label 'Includes closed VAT Periods';
        VATCaptionLbl: Label 'VAT';
        BaseWithVATCaptionLbl: Label 'Base with VAT';
        BaseWithoutVATCaptionLbl: Label 'Base without VAT';
        BaseOutsideCaptionLbl: Label 'Base outside Tax Area';
        TotalPurchandSaleCaptionLbl: Label 'Total Purchase and Sale';
        TotalSaleBaseOutsideSalesCaptionLbl: Label '1. Total sales innside and outside the VAT area';
        TotalSaleCaptionLbl: Label '2. Total sales innside the VAT area';
        SaleWithoutTaxCaptionLbl: Label '3. Sale without VAT';
        SaleWithTaxHighCaptionLbl: Label '4. Calculation base high rate, and calculated VAT';
        PlusCaptionLbl: Label '+';
        SaleWithTaxLowCaptionLbl: Label '6. Calculation base lov rate, and calculated VAT';
        SaleWithTaxServCaptionLbl: Label '7. Calculation base of imported services, and calculated VAT';
        PurchaseTaxHighCaptionLbl: Label '8. Purchase VAT, high rate';
        MinusCaptionLbl: Label '-';
        PurchaseTaxLowCaptionLbl: Label '10. Purchase VAT, low rate';
        EqualCaptionLbl: Label '=';
        StandardTradesettlementCaptionLbl: Label 'Standard Trade Settlement';
        PurchaseTaxMediumCaptionLbl: Label '9. Purchase VAT, medium rate';
        SaleWithTaxMediumCaptionLbl: Label '5. Calculation base medium rate, and calculated VAT';
        TradesettlementforservimportCaptionLbl: Label 'Trade Settlement for service import';
        SaleWithTaxServiceCaptionLbl: Label '1. Calculation base of imported services, and calculated VAT';
        TradesettlementVATInvstmntTaxCaptionLbl: Label 'Trade Settlement: VAT - Investment Tax';
        EmptyStringCaptionLbl: Label '.....................................................................................................................................................................................................................................................................................................';

    local procedure CalculateStartEnd(VatPeriodNo: Integer; Year: Integer; var StartDate: Date; var EndDate: Date)
    begin
        if VatPeriodNo = 0 then // Manual dates
            exit;

        VATPeriod.Get(VatPeriodNo);
        StartDate := DMY2Date(VATPeriod."Start Day", VATPeriod."Start Month", Year);
        if VATPeriod.Next() = 0 then begin
            VATPeriod.Find('-');
            Year := Year + 1;
        end;
        EndDate := DMY2Date(VATPeriod."Start Day", VATPeriod."Start Month", Year);
        EndDate := CalcDate('<-1D>', EndDate);
    end;

    local procedure CalculatePeriod(DateInPeriod: Date; var PeriodNo: Integer; var PeriodYear: Integer)
    begin
        PeriodNo := VATTools.VATPeriodNo(DateInPeriod);
        PeriodYear := Date2DMY(DateInPeriod, 3);
    end;
}

