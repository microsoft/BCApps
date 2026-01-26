// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using System.IO;
using System.Utilities;

report 10618 "Trade Settlement 2017"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/TradeSettlement2017.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Trade Settlement from 2017';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(HeaderLine; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VATDateFilter; PeriodLbl + ': ' + VATDateFilter)
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
            column(TradesettlementVATInvstmntTaxCaption; TradesettlementVATInvstmntTaxCaptionLbl)
            {
            }
            column(IncludesclosedVATPeriodsCaption; IncludesclosedVATPeriodsCaptionLbl)
            {
            }
            column(PlusCaption; PlusCaptionLbl)
            {
            }
            column(MinusCaption; MinusCaptionLbl)
            {
            }
            column(EqualCaption; EqualCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(TotalPurchandSaleCaption; TotalPurchandSaleCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = sorting(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group");
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
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
                column(GroupTotal; TotalLbl)
                {
                }
                column(SubtotalText; SubtotalText)
                {
                }
                column(PageCaption; PageCaptionLbl)
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

                trigger OnAfterGetRecord()
                var
                    VATPostingSetup: Record "VAT Posting Setup";
                    VATCode: Record "VAT Reporting Code";
                begin
                    ShowGroupHeader := true;
                    ClearBases();

                    case "Base Amount Type" of
                        "Base Amount Type"::"With VAT":
                            BaseWithVAT := Base;
                        "Base Amount Type"::"Without VAT":
                            BaseWithoutVAT := Base;
                        "Base Amount Type"::"Outside Tax Area":
                            begin
                                BaseOutside := Base;
                                if Type = Type::Sale then
                                    BaseOutsideSales -= BaseOutside;
                            end;
                    end;

                    VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                    case Type of
                        Type::Sale:
                            if VATCode.Get(VATPostingSetup."Sale VAT Reporting Code") then
                                case VATCode."Trade Settlement 2017 Box No." of
                                    VATCode."Trade Settlement 2017 Box No."::"3":
                                        begin
                                            DomesticHighBase -= Base;
                                            DomesticHighAmount -= Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"4":
                                        begin
                                            DomesticMedBase -= Base;
                                            DomesticMedAmount -= Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"5":
                                        begin
                                            DomesticLowBase -= Base;
                                            DomesticLowAmount -= Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"6":
                                        DomesticNoVAT -= Base;
                                    VATCode."Trade Settlement 2017 Box No."::"8":
                                        ExportNoVAT -= Base;
                                end;
                        Type::Purchase:
                            if VATCode.Get(VATPostingSetup."Purch. VAT Reporting Code") then begin
                                case VATCode."Trade Settlement 2017 Box No." of
                                    VATCode."Trade Settlement 2017 Box No."::"7":
                                        begin
                                            DomesticRevChrgBase += Base;
                                            DomesticRevChrgAmount += Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"9":
                                        CalculateVATBaseAndAmount(ImportHighBase, ImportHighAmount);
                                    VATCode."Trade Settlement 2017 Box No."::"10":
                                        begin
                                            ImportMedBase += Base;
                                            ImportMedAmount += Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"11":
                                        ImportNoVAT += Base;
                                    VATCode."Trade Settlement 2017 Box No."::"12":
                                        CalculateVATBaseAndAmount(PurchRevChrgAbroadHighBase, PurchRevChrgAbroadHighAmount);
                                    VATCode."Trade Settlement 2017 Box No."::"13":
                                        begin
                                            PurchRevChrgDomesticHighBase += Base;
                                            PurchRevChrgDomesticHighAmount += Amount;
                                        end;
                                    VATCode."Trade Settlement 2017 Box No."::"14":
                                        DeductibleDomesticHigh += Amount;
                                    VATCode."Trade Settlement 2017 Box No."::"15":
                                        DeductibleDomesticMed += Amount;
                                    VATCode."Trade Settlement 2017 Box No."::"16":
                                        DeductibleDomesticLow += Amount;
                                    VATCode."Trade Settlement 2017 Box No."::"17":
                                        DeductibleImportHigh += Amount;
                                    VATCode."Trade Settlement 2017 Box No."::"18":
                                        DeductibleImportMed += Amount;
                                end;
                                if ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") and
                                   (VATCode."Trade Settlement 2017 Box No." <> VATCode."Trade Settlement 2017 Box No."::" ") and
                                   (VATCode."Reverse Charge Report Box No." <> VATCode."Reverse Charge Report Box No."::" ")
                                then
                                    case VATCode."Reverse Charge Report Box No." of
                                        VATCode."Reverse Charge Report Box No."::"14":
                                            DeductibleDomesticHigh += Amount;
                                        VATCode."Reverse Charge Report Box No."::"15":
                                            DeductibleDomesticMed += Amount;
                                        VATCode."Reverse Charge Report Box No."::"16":
                                            DeductibleDomesticLow += Amount;
                                        VATCode."Reverse Charge Report Box No."::"17":
                                            DeductibleImportHigh += Amount;
                                        VATCode."Reverse Charge Report Box No."::"18":
                                            DeductibleImportMed += Amount;
                                    end;
                            end;
                    end;
                    SubtotalText := StrSubstNo('%1 %2', TotalLbl, Type);

                    TotalTurnoverBase :=
                      DomesticLowBase + DomesticMedBase + DomesticHighBase + DomesticNoVAT + DomesticRevChrgBase +
                      ExportNoVAT + ImportMedBase + ImportHighBase + ImportNoVAT + PurchRevChrgAbroadHighBase;

                    TotalPayableReceivableAmount :=
                      DomesticLowAmount + DomesticMedAmount + DomesticHighAmount + DomesticRevChrgAmount +
                      ImportHighAmount + ImportMedAmount + PurchRevChrgAbroadHighAmount + PurchRevChrgDomesticHighAmount -
                      (DeductibleDomesticHigh + DeductibleDomesticMed + DeductibleDomesticLow + DeductibleImportHigh + DeductibleImportMed);
                end;

                trigger OnPostDataItem()
                begin
                    if TotalPayableReceivableAmount < 0 then
                        TaxTextStd := OutstandingTaxLbl
                    else
                        TaxTextStd := TaxToPayLbl;
                end;

                trigger OnPreDataItem()
                var
                    StartYear: Integer;
                    EndYear: Integer;
                    StartPeriod: Integer;
                    EndPeriod: Integer;
                begin
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
                    ClearBases();

                    CalculatePeriod(StartDate, StartPeriod, StartYear);
                    CalculatePeriod(EndDate, EndPeriod, EndYear);
                    SettledVATPeriod.SetRange("Period No.", StartPeriod, EndPeriod);
                    SettledVATPeriod.SetRange(Year, StartYear, EndYear);
                    SettledVATPeriod.SetRange(Closed, true);
                    ShowChangeHeader := SettledVATPeriod.Count <> 0;

                    case Selection of
                        Selection::Open:
                            IncludeText := StrSubstNo(IncludesVATEntriesLbl, OpenLbl);
                        Selection::Closed:
                            IncludeText := StrSubstNo(IncludesVATEntriesLbl, ClosedLbl);
                        Selection::"Open and Closed":
                            IncludeText := StrSubstNo(IncludesVATEntriesLbl, OpenAndClosedLbl);
                    end;

                    ShowGroupHeader := true;
                end;
            }
            dataitem(TotalLine; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(StandardTradesettlementCaption; StandardTradesettlementCaptionLbl)
                {
                }
                column(BoxA_LblCaption; BoxA_Lbl)
                {
                }
                column(Box1_TotalTurnover_NotCoveredByVATAct_LblCaption; Box1_TotalTurnover_NotCoveredByVATAct_Lbl)
                {
                }
                column(Box2_TotalTurnover_LblCaption; Box2_TotalTurnover_Lbl)
                {
                }
                column(BaseOutsideSales; BaseOutsideSales)
                {
                }
                column(TotalTurnoverBase; TotalTurnoverBase)
                {
                }
                column(BoxB_LblCaption; BoxB_Lbl)
                {
                }
                column(Box3_DomesticTurnover_Sale_High_LblCaption; '3. ' + DomesticTurnover_Sale_Lbl + HighLbl)
                {
                }
                column(Box4_DomesticTurnover_Sale_Medium_LblCaption; '4. ' + DomesticTurnover_Sale_Lbl + MediumLbl)
                {
                }
                column(Box5_DomesticTurnover_Sale_Low_LblCaption; '5. ' + DomesticTurnover_Sale_Lbl + LowLbl)
                {
                }
                column(Box6_DomesticTurnover_SaleZero_LblCaption; Box6_DomesticTurnover_SaleZero_Lbl)
                {
                }
                column(Box7_DomesticTurnover_ReverseCharge_LblCaption; Box7_DomesticTurnover_ReverseCharge_Lbl)
                {
                }
                column(DomesticHighBase; DomesticHighBase)
                {
                }
                column(DomesticMedBase; DomesticMedBase)
                {
                }
                column(DomesticLowBase; DomesticLowBase)
                {
                }
                column(DomesticNoVAT; DomesticNoVAT)
                {
                }
                column(DomesticRevChrgBase; DomesticRevChrgBase)
                {
                }
                column(DomesticHighAmount; DomesticHighAmount)
                {
                }
                column(DomesticMedAmount; DomesticMedAmount)
                {
                }
                column(DomesticLowAmount; DomesticLowAmount)
                {
                }
                column(DomesticRevChrgAmount; DomesticRevChrgAmount)
                {
                }
                column(BoxC_LblCaption; BoxC_Lbl)
                {
                }
                column(Box8_Export_SaleZero_LblCaption; Box8_Export_SaleZero_Lbl)
                {
                }
                column(ExportNoVAT; ExportNoVAT)
                {
                }
                column(BoxD_LblCaption; BoxD_Lbl)
                {
                }
                column(Box9_ImportPurch_High_LblCaption; '9. ' + ImportPurch_Lbl + HighLbl)
                {
                }
                column(Box10_ImportPurch_Medium_LblCaption; '10. ' + ImportPurch_Lbl + MediumLbl)
                {
                }
                column(Box11_ImportPurchZero_LblCaption; Box11_ImportPurchZero_Lbl)
                {
                }
                column(ImportHighBase; ImportHighBase)
                {
                }
                column(ImportMedBase; ImportMedBase)
                {
                }
                column(ImportNoVAT; ImportNoVAT)
                {
                }
                column(ImportHighAmount; ImportHighAmount)
                {
                }
                column(ImportMedAmount; ImportMedAmount)
                {
                }
                column(BoxE_LblCaption; BoxE_Lbl)
                {
                }
                column(Box12_ReverseCharge_Abroad_LblCaption; Box12_ReverseCharge_Abroad_Lbl)
                {
                }
                column(Box13_ReverseCharge_Domestic_LblCaption; Box13_ReverseCharge_Domestic_Lbl)
                {
                }
                column(PurchRevChrgAbroadHighBase; PurchRevChrgAbroadHighBase)
                {
                }
                column(PurchRevChrgDomesticHighBase; PurchRevChrgDomesticHighBase)
                {
                }
                column(PurchRevChrgAbroadHighAmount; PurchRevChrgAbroadHighAmount)
                {
                }
                column(PurchRevChrgDomesticHighAmount; PurchRevChrgDomesticHighAmount)
                {
                }
                column(BoxF_LblCaption; BoxF_Lbl)
                {
                }
                column(Box14_DomesticDeduction_High_LblCaption; '14. ' + DomesticDeduction_Lbl + HighLbl)
                {
                }
                column(Box15_DomesticDeduction_Medium_LblCaption; '15. ' + DomesticDeduction_Lbl + MediumLbl)
                {
                }
                column(Box16_DomesticDeduction_Low_LblCaption; '16. ' + DomesticDeduction_Lbl + LowLbl)
                {
                }
                column(DeductibleDomesticHigh; DeductibleDomesticHigh)
                {
                }
                column(DeductibleDomesticMed; DeductibleDomesticMed)
                {
                }
                column(DeductibleDomesticLow; DeductibleDomesticLow)
                {
                }
                column(BoxG_LblCaption; BoxG_Lbl)
                {
                }
                column(Box17_ImportDeductionHigh_LblCaption; '17. ' + ImportDeduction_Lbl + HighLbl)
                {
                }
                column(Box18_ImportDeduction_Medium_LblCaption; '18. ' + ImportDeduction_Lbl + MediumLbl)
                {
                }
                column(DeductibleImportHigh; DeductibleImportHigh)
                {
                }
                column(DeductibleImportMed; DeductibleImportMed)
                {
                }
                column(BoxH_LblCaption; BoxH_Lbl)
                {
                }
                column(Box19_VATPayableReceivableCaption; '19. ' + TaxTextStd)
                {
                }
                column(TotalPayableReceivableAmount; TotalPayableReceivableAmount)
                {
                }
            }
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
                        ToolTip = 'Specifies the number of the VAT settlement period.';

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
                        ToolTip = 'Specifies the year of the VAT settlement period.';

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
                        ToolTip = 'Specifies the starting date of the VAT settlement.';

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
                        ToolTip = 'Specifies the ending date of the VAT settlement.';

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
                        ToolTip = 'Specifies if VAT entries are shown in the report.';
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if the VAT settlement includes open, closed, or both open and closed VAT entries.';
                    }
                    group(XML)
                    {
                        Caption = 'XML';
                        field(ExportXML; ExportXML)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Export';
                            ToolTip = 'Specifies if the information in the report is exported to an XML file when you choose the Print or Preview buttons.';
                        }
                        field(ClientFileName; ClientFileName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'File Name';
                            Enabled = ExportXML;
                            ToolTip = 'Specifies XML file that information in the report is exported to.';

                            trigger OnAssistEdit()
                            begin
                                ClientFileName := XMLFileNameLbl;
                            end;
                        }

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

    trigger OnInitReport()
    begin
        ClientFileName := XMLFileNameLbl;
    end;

    trigger OnPreReport()
    begin
        if EndDate = 0D then
            "VAT Entry".SetFilter("VAT Reporting Date", '%1..', StartDate)
        else
            "VAT Entry".SetRange("VAT Reporting Date", StartDate, EndDate);
        VATDateFilter := "VAT Entry".GetFilter("VAT Reporting Date");

        CopyVATPostingSetupToTempVATPostingSetup();
    end;

    trigger OnPostReport()
    begin
        if ExportXML then
            ExportXMLFile();
    end;

    var
        SettledVATPeriod: Record "Settled VAT Period";
        VATPeriod: Record "VAT Period";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        SettlementPeriod: Integer;
        SettlementYear: Integer;
        StartDate: Date;
        EndDate: Date;
        Selection: Enum "VAT Statement Report Selection";
        VATDateFilter: Text;
        TotalTurnoverBase: Decimal;
        DomesticHighBase: Decimal;
        DomesticHighAmount: Decimal;
        DomesticMedBase: Decimal;
        DomesticMedAmount: Decimal;
        DomesticLowBase: Decimal;
        DomesticLowAmount: Decimal;
        DomesticNoVAT: Decimal;
        DomesticRevChrgBase: Decimal;
        DomesticRevChrgAmount: Decimal;
        ExportNoVAT: Decimal;
        ImportHighBase: Decimal;
        ImportHighAmount: Decimal;
        ImportMedBase: Decimal;
        ImportMedAmount: Decimal;
        ImportNoVAT: Decimal;
        PurchRevChrgAbroadHighBase: Decimal;
        PurchRevChrgAbroadHighAmount: Decimal;
        PurchRevChrgDomesticHighBase: Decimal;
        PurchRevChrgDomesticHighAmount: Decimal;
        DeductibleDomesticHigh: Decimal;
        DeductibleDomesticMed: Decimal;
        DeductibleDomesticLow: Decimal;
        DeductibleImportHigh: Decimal;
        DeductibleImportMed: Decimal;
        TotalPayableReceivableAmount: Decimal;
        TaxTextStd: Text;
        ShowVATEntries: Boolean;
        BaseWithVAT: Decimal;
        BaseWithoutVAT: Decimal;
        BaseOutside: Decimal;
        BaseOutsideSales: Decimal;
        LastPage: Boolean;
        ShowChangeHeader: Boolean;
        ShowGroupHeader: Boolean;
        SubtotalText: Text;
        TotalLbl: Label 'Total';
        PeriodLbl: Label 'Period';
        IncludesVATEntriesLbl: Label 'Includes %1 VAT entries', Comment = '%1 = Open/Closed/Open And Closed';
        OutstandingTaxLbl: Label 'Outstanding tax';
        TaxToPayLbl: Label 'Tax to pay';
        OpenLbl: Label 'Open';
        ClosedLbl: Label 'Closed';
        OpenAndClosedLbl: Label 'Open and Closed';
        IncludeText: Text;
        PageCaptionLbl: Label 'Page';
        IncludesclosedVATPeriodsCaptionLbl: Label 'Includes closed VAT periods';
        VATCaptionLbl: Label 'VAT';
        BaseWithVATCaptionLbl: Label 'Base with VAT';
        BaseWithoutVATCaptionLbl: Label 'Base without VAT';
        BaseOutsideCaptionLbl: Label 'Base outside Tax area';
        TotalPurchandSaleCaptionLbl: Label 'Total purchases and sales';
        PlusCaptionLbl: Label '+';
        MinusCaptionLbl: Label '-';
        EqualCaptionLbl: Label '=';
        StandardTradesettlementCaptionLbl: Label 'Standard trade settlement';
        TradesettlementVATInvstmntTaxCaptionLbl: Label 'Trade settlement VAT';
        EmptyStringCaptionLbl: Label '. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .';
        BoxA_Lbl: Label 'A. Total turnover and withdrawal based on import';
        BoxB_Lbl: Label 'B. Domestic turnover and withdrawal';
        BoxC_Lbl: Label 'C. Export';
        BoxD_Lbl: Label 'D. Import of goods';
        BoxE_Lbl: Label 'E. Purchase subject to reverse charge';
        BoxF_Lbl: Label 'F. Deduction of domestic input VAT';
        BoxG_Lbl: Label 'G. Deduction of import VAT';
        BoxH_Lbl: Label 'H. Total';
        Box1_TotalTurnover_NotCoveredByVATAct_Lbl: Label '1. Total turnover not covered by the VAT act';
        Box2_TotalTurnover_Lbl: Label '2. Total turnover and withdrawal covered by the VAT act and import';
        DomesticTurnover_Sale_Lbl: Label 'Domestic turnover and withdrawal, VAT';
        Box6_DomesticTurnover_SaleZero_Lbl: Label '6. Zero-rated domestic turnover and withdrawal';
        Box7_DomesticTurnover_ReverseCharge_Lbl: Label '7. Domestic turnover subject to reverse charge (emission trading and gold)';
        Box8_Export_SaleZero_Lbl: Label '8. Total zero-rated turnover due to export of goods and services';
        ImportPurch_Lbl: Label 'Import of goods, VAT';
        Box11_ImportPurchZero_Lbl: Label '11. Import of goods not subject to VAT';
        Box12_ReverseCharge_Abroad_Lbl: Label '12. Purchase of intangible services from abroad, VAT High';
        Box13_ReverseCharge_Domestic_Lbl: Label '13. Domestic purchases subject to reverse charge, VAT High';
        DomesticDeduction_Lbl: Label 'Deductible domestic input VAT';
        ImportDeduction_Lbl: Label 'Deductible import VAT';
        ExportXML: Boolean;
        ClientFileName: Text;
        HighLbl: Label ' High';
        MediumLbl: Label ' Medium';
        LowLbl: Label ' Low';
        XMLFileNameLbl: Label 'Trade Settlement from 2017';

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
    var
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
    begin
        PeriodNo := NorwegianVATTools.VATPeriodNo(DateInPeriod);
        PeriodYear := Date2DMY(DateInPeriod, 3);
    end;

    local procedure PrepareXMLData(var XMLVATBase: array[19] of Decimal; var XMLVATAmount: array[19] of Decimal)
    begin
        XMLVATBase[1] := BaseOutsideSales;
        XMLVATBase[2] := TotalTurnoverBase;
        XMLVATBase[3] := DomesticHighBase;
        XMLVATBase[4] := DomesticMedBase;
        XMLVATBase[5] := DomesticLowBase;
        XMLVATBase[6] := DomesticNoVAT;
        XMLVATBase[7] := DomesticRevChrgBase;
        XMLVATBase[8] := ExportNoVAT;
        XMLVATBase[9] := ImportHighBase;
        XMLVATBase[10] := ImportMedBase;
        XMLVATBase[11] := ImportNoVAT;
        XMLVATBase[12] := PurchRevChrgAbroadHighBase;
        XMLVATBase[13] := PurchRevChrgDomesticHighBase;
        XMLVATAmount[3] := DomesticHighAmount;
        XMLVATAmount[4] := DomesticMedAmount;
        XMLVATAmount[5] := DomesticLowAmount;
        XMLVATAmount[9] := ImportHighAmount;
        XMLVATAmount[10] := ImportMedAmount;
        XMLVATAmount[12] := PurchRevChrgAbroadHighAmount;
        XMLVATAmount[13] := PurchRevChrgDomesticHighAmount;
        XMLVATAmount[14] := DeductibleDomesticHigh;
        XMLVATAmount[15] := DeductibleDomesticMed;
        XMLVATAmount[16] := DeductibleDomesticLow;
        XMLVATAmount[17] := DeductibleImportHigh;
        XMLVATAmount[18] := DeductibleImportMed;
        XMLVATAmount[19] := TotalPayableReceivableAmount;
    end;

    local procedure ExportXMLFile()
    var
        FileManagement: Codeunit "File Management";
        TradeSettlement2017: XMLport "Trade Settlement 2017";
        ExportFile: File;
        OutStream: OutStream;
        ServerFileName: Text;
        XMLVATBase: array[19] of Decimal;
        XMLVATAmount: array[19] of Decimal;
    begin
        // Init XML File
        ServerFileName := FileManagement.ServerTempFileName('XML');
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);

        // Prepare XML Data
        PrepareXMLData(XMLVATBase, XMLVATAmount);
        TradeSettlement2017.SetParameters(SettlementYear, SettlementPeriod, XMLVATBase, XMLVATAmount);

        // Export
        TradeSettlement2017.SetDestination(OutStream);
        TradeSettlement2017.Export();
        ExportFile.Close();
        FileManagement.DownloadHandler(ServerFileName, '', '', '', FileManagement.CreateFileNameWithExtension(ClientFileName, '.xml'));
    end;

    local procedure CalculateVATBaseAndAmount(var Base: Decimal; var Amount: Decimal)
    begin
        TempVATPostingSetup.Get("VAT Entry"."VAT Bus. Posting Group", "VAT Entry"."VAT Prod. Posting Group");
        if not TempVATPostingSetup."Calc. Prop. Deduction VAT" then begin
            Base += "VAT Entry".Base;
            Amount += "VAT Entry".Amount;
        end else
            if TempVATPostingSetup."Proportional Deduction VAT %" = 0 then begin
                Base += "VAT Entry".Base;
                Amount += Round("VAT Entry".Base * TempVATPostingSetup."VAT %" / 100);
            end else begin
                Base += Round("VAT Entry".Base * 100 / TempVATPostingSetup."Proportional Deduction VAT %");
                Amount += Round("VAT Entry".Amount * 100 / TempVATPostingSetup."Proportional Deduction VAT %");
            end;
    end;

    local procedure CopyVATPostingSetupToTempVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.FindSet() then
            repeat
                TempVATPostingSetup.Init();
                TempVATPostingSetup := VATPostingSetup;
                TempVATPostingSetup.Insert();
            until VATPostingSetup.Next() = 0;
    end;

    local procedure ClearBases()
    begin
        Clear(BaseWithVAT);
        Clear(BaseWithoutVAT);
        Clear(BaseOutside);
    end;
}

