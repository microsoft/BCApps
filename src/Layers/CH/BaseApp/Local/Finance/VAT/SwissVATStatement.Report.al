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
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using System.Reflection;
using System.Telemetry;
using System.Utilities;

report 26100 "Swiss VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/SwissVATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Swiss VAT Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            RequestFilterFields = "Statement Template Name", Name;
            column(FORMAT_TODAY_0_4_______FORMAT_TIME_; Format(Today, 0, 4) + '  ' + Format(Time))
            {
            }
            column(Heading; Heading)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Heading2; Heading2)
            {
            }
            column(Text010; Text010)
            {
            }
            column(VAT_Statement_SwitzerlandCaption; VAT_Statement_SwitzerlandCaptionLbl)
            {
            }
            column(VAT_Statement_Name_Statement_Template_Name; "Statement Template Name")
            {
            }
            column(VAT_Statement_Name_Name; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));
                column(VAT_Statement_Line_Line_No_; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "VAT Statement Cipher" <> '' then begin
                        TempVATStmtLine.Reset();
                        TempVATStmtLine.SetRange("VAT Statement Cipher", "VAT Statement Cipher");
                        if not TempVATStmtLine.FindFirst() then begin
                            TempVATStmtLine.Init();
                            TempVATStmtLine.TransferFields("VAT Statement Line");
                            TempVATStmtLine.Insert();
                        end else
                            Error(Text009, "VAT Statement Cipher", "Statement Template Name", "Statement Name");
                        if not TempVATReportLine.Get("VAT Statement Cipher", 0) then begin
                            TempVATReportLine."VAT Report No." := "VAT Statement Cipher";
                            TempVATReportLine.Insert();
                        end;
                    end;
                    CalcLineTotal("VAT Statement Line", TotalAmount, 0);
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;
                    SetCipherAmount("VAT Statement Cipher", Round(TotalAmount, 0.1));
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____200__; GetCipherAmount(VATCipherSetup."Total Revenue"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____205__; GetCipherAmount(VATCipherSetup."Revenue of Non-Tax. Services"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____220__; GetCipherAmount(VATCipherSetup."Deduction of Tax-Exempt"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____221__; GetCipherAmount(VATCipherSetup."Deduction of Services Abroad"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____225__; GetCipherAmount(VATCipherSetup."Deduction of Transfer"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____230__; GetCipherAmount(VATCipherSetup."Deduction of Non-Tax. Services"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____235__; GetCipherAmount(VATCipherSetup."Reduction in Payments"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____280__; GetCipherAmount(VATCipherSetup.Miscellaneous))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____289__; GetCipherAmount(VATCipherSetup."Total Deductions"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____299__; GetCipherAmount(VATCipherSetup."Total Taxable Revenue"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____300__; GetCipherAmount(VATCipherSetup."Tax Normal Rate Serv. Before"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____301__; GetCipherAmount(VATCipherSetup."Tax Normal Rate Serv. After"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____310__; GetCipherAmount(VATCipherSetup."Tax Reduced Rate Serv. Before"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____311__; GetCipherAmount(VATCipherSetup."Tax Reduced Rate Serv. After"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____340__; GetCipherAmount(VATCipherSetup."Tax Hotel Rate Serv. Before"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____341__; GetCipherAmount(VATCipherSetup."Tax Hotel Rate Serv. After"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____380__; GetCipherAmount(VATCipherSetup."Acquisition Tax Before"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____381__; GetCipherAmount(VATCipherSetup."Acquisition Tax After"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____400__; GetCipherAmount(VATCipherSetup."Input Tax on Material and Serv"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____405__; GetCipherAmount(VATCipherSetup."Input Tax on Investsments"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____410__; GetCipherAmount(VATCipherSetup."Deposit Tax"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____415__; GetCipherAmount(VATCipherSetup."Input Tax Corrections"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____420__; GetCipherAmount(VATCipherSetup."Input Tax Cutbacks"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____479__; GetCipherAmount(VATCipherSetup."Total Input Tax"))
                {
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____900__; GetCipherAmount(VATCipherSetup."Cash Flow Taxes"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____910__; GetCipherAmount(VATCipherSetup."Cash Flow Compensations"))
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Cipher500Amt; Cipher500Amt)
                {
                }
                column(ABS_Cipher510Amt_; Abs(Cipher510Amt))
                {
                }
                column(TaxCHF301; TaxCHF301)
                {
                }
                column(TaxCHF341; TaxCHF341)
                {
                }
                column(TaxCHF381; TaxCHF381)
                {
                }
                column(TaxCHF311; TaxCHF311)
                {
                }
                column(TaxCHF340; TaxCHF340)
                {
                }
                column(TaxCHF380; TaxCHF380)
                {
                }
                column(TaxCHF310; TaxCHF310)
                {
                }
                column(TaxCHF300; TaxCHF300)
                {
                }
                column(TaxCHF300_TaxCHF310_TaxCHF340_TaxCHF380_TaxCHF301_TaxCHF311_TaxCHF341_TaxCHF381; TaxCHF300 + TaxCHF310 + TaxCHF340 + TaxCHF380 + TaxCHF301 + TaxCHF311 + TaxCHF341 + TaxCHF381)
                {
                }
                column(FORMAT_NormalRateOld; GetVATRateTxt(NormalRateOld))
                {
                }
                column(FORMAT_ReducedRateOld; GetVATRateTxt(ReducedRateOld))
                {
                }
                column(FORMAT_HotelRateOld; GetVATRateTxt(HotelRateOld))
                {
                }
                column(FORMAT_NormalRateCur; GetVATRateTxt(NormalRateCur))
                {
                }
                column(FORMAT_ReducedRateCur; GetVATRateTxt(ReducedRateCur))
                {
                }
                column(FORMAT_HotelRateCur; GetVATRateTxt(HotelRateCur))
                {
                }
                column(Revenue_CHFCaption; Revenue_CHFCaptionLbl)
                {
                }
                column(Revenue_CHFCaption_Control1150006; Revenue_CHFCaption_Control1150006Lbl)
                {
                }
                column(CipherCaption; CipherCaptionLbl)
                {
                }
                column(V200Caption; VATCipherSetup."Total Revenue")
                {
                }
                column(V205Caption; VATCipherSetup."Revenue of Non-Tax. Services")
                {
                }
                column(V220Caption; VATCipherSetup."Deduction of Tax-Exempt")
                {
                }
                column(V221Caption; VATCipherSetup."Deduction of Services Abroad")
                {
                }
                column(V225Caption; VATCipherSetup."Deduction of Transfer")
                {
                }
                column(V230Caption; VATCipherSetup."Deduction of Non-Tax. Services")
                {
                }
                column(V235Caption; VATCipherSetup."Reduction in Payments")
                {
                }
                column(V280Caption; VATCipherSetup.Miscellaneous)
                {
                }
                column(V289Caption; VATCipherSetup."Total Deductions")
                {
                }
                column(V299Caption; VATCipherSetup."Total Taxable Revenue")
                {
                }
                column(V300Caption; VATCipherSetup."Tax Normal Rate Serv. Before")
                {
                }
                column(V301Caption; VATCipherSetup."Tax Normal Rate Serv. After")
                {
                }
                column(V310Caption; VATCipherSetup."Tax Reduced Rate Serv. Before")
                {
                }
                column(V311Caption; VATCipherSetup."Tax Reduced Rate Serv. After")
                {
                }
                column(V340Caption; VATCipherSetup."Tax Hotel Rate Serv. Before")
                {
                }
                column(V341Caption; VATCipherSetup."Tax Hotel Rate Serv. After")
                {
                }
                column(V380Caption; VATCipherSetup."Acquisition Tax Before")
                {
                }
                column(V381Caption; VATCipherSetup."Acquisition Tax After")
                {
                }
                column(V399Caption; VATCipherSetup."Total Owned Tax")
                {
                }
                column(V400Caption; VATCipherSetup."Input Tax on Material and Serv")
                {
                }
                column(V405Caption; VATCipherSetup."Input Tax on Investsments")
                {
                }
                column(V410Caption; VATCipherSetup."Deposit Tax")
                {
                }
                column(V415Caption; VATCipherSetup."Input Tax Corrections")
                {
                }
                column(V420Caption; VATCipherSetup."Input Tax Cutbacks")
                {
                }
                column(V479Caption; VATCipherSetup."Total Input Tax")
                {
                }
                column(V500Caption; VATCipherSetup."Tax Amount to Pay")
                {
                }
                column(V510Caption; VATCipherSetup."Credit of Taxable Person")
                {
                }
                column(V900Caption; VATCipherSetup."Cash Flow Taxes")
                {
                }
                column(V910Caption; VATCipherSetup."Cash Flow Compensations")
                {
                }
                column(Total_of_realized_resp_unrealized_revenue_Art_39_incl_revenue_from_transfers_in_the_rep_procedure_as_well_as_servLbl; Total_of_realized_resp_unrealized_revenue_Art_39_incl_revenue_from_transfers_in_the_rep_procedure_as_well_as_servLbl)
                {
                }
                column(In_cipher_200_included_revenue_from_non_taxable_services__Art__21__which_are_opted_for_Art__22Caption; In_cipher_200_included_revenue_from_non_taxable_services__Art__21__which_are_opted_for_Art__22CaptionLbl)
                {
                }
                column(Tax_exempt_services_among_others_exports_Art_23_tax_exempt_services_to_benefited_institutions_and_ppl_Art_107_Caption; Tax_exempt_services_among_others_exports_Art_23_tax_exempt_services_to_benefited_institutions_and_people_Art_107_Lbl)
                {
                }
                column(Services_abroadCaption; Services_abroadCaptionLbl)
                {
                }
                column(Transfer_in_the_reporting_procedure__Art__38__please_submit_Form__764_additionally_Caption; Transfer_in_the_reporting_procedure__Art__38__please_submit_Form__764_additionally_CaptionLbl)
                {
                }
                column(Non_taxable_services__Art__21__not_opted_for_Art__22Caption; Non_taxable_services__Art__21__not_opted_for_Art__22CaptionLbl)
                {
                }
                column(quoted_articles_are_related_to_VAT_law_from_12_06_2009_Caption; quoted_articles_are_related_to_VAT_law_from_12_06_2009_CaptionLbl)
                {
                }
                column(Reduction_in_paymentsCaption; Reduction_in_paymentsCaptionLbl)
                {
                }
                column(Total_220_to_280Caption; StrSubstNo(TotalCipherFromToLbl, VATCipherSetup."Deduction of Tax-Exempt", VATCipherSetup.Miscellaneous))
                {
                }
                column(MiscellaneousCaption; MiscellaneousCaptionLbl)
                {
                }
                column(EmptyStringCaption; EmptyStringCaptionLbl)
                {
                }
                column(cipher_200_minus_cipher_289_Caption; StrSubstNo(TaxTurnoverCipherLbl, VATCipherSetup."Total Revenue", VATCipherSetup."Total Deductions"))
                {
                }
                column(EmptyStringCaption_Control1150040; EmptyStringCaption_Control1150040Lbl)
                {
                }
                column(II__TAX_COMPUTATIONCaption; II__TAX_COMPUTATIONCaptionLbl)
                {
                }
                column(Tax_CHF___Rp_Caption; Tax_CHF___Rp_CaptionLbl)
                {
                }
                column(Revenue_CHFCaption_Control1150044; Revenue_CHFCaption_Control1150044Lbl)
                {
                }
                column(Services_at_normal_rateCaption; Services_at_normal_rateCaptionLbl)
                {
                }
                column(Services_at_reduced_rateCaption; Services_at_reduced_rateCaptionLbl)
                {
                }
                column(Services_at_hotel_rateCaption; Services_at_hotel_rateCaptionLbl)
                {
                }
                column(Acquisition_taxCaption; Acquisition_taxCaptionLbl)
                {
                }
                column(Ciphers_300_to_381Caption; StrSubstNo(CipherFromToLbl, VATCipherSetup."Tax Normal Rate Serv. Before", VATCipherSetup."Acquisition Tax After"))
                {
                }
                column(EmptyStringCaption_Control1150062; EmptyStringCaption_Control1150062Lbl)
                {
                }
                column(Tax_CHF___Rp_Caption_Control1150064; Tax_CHF___Rp_Caption_Control1150064Lbl)
                {
                }
                column(Input_tax_on_material_and_servicesCaption; Input_tax_on_material_and_servicesCaptionLbl)
                {
                }
                column(Total_owned_taxCaption; Total_owned_taxCaptionLbl)
                {
                }
                column(RateCaption; RateCaptionLbl)
                {
                }
                column(Input_tax_on_investments_and_other_operating_costsCaption; Input_tax_on_investments_and_other_operating_costsCaptionLbl)
                {
                }
                column(Deposit_tax__Art__32__please_submit_detailed_list_Caption; Deposit_tax__Art__32__please_submit_detailed_list_CaptionLbl)
                {
                }
                column(Total_taxable_revenueCaption; Total_taxable_revenueCaptionLbl)
                {
                }
                column(Input_tax_corrections__mixed_usage__Art__30___own_consumption__Art__31_Caption; Input_tax_corrections__mixed_usage__Art__30___own_consumption__Art__31_CaptionLbl)
                {
                }
                column(Total_400_to_420Caption; StrSubstNo(TotalCipherFromToLbl, VATCipherSetup."Input Tax on Material and Serv", VATCipherSetup."Input Tax Cutbacks"))
                {
                }
                column(Input_tax_cutbacks__Non_revenue_like_grants__visitor_s_taxes_etc___Art__33_para__2_Caption; Input_tax_cutbacks__Non_revenue_like_grants__visitor_s_taxes_etc___Art__33_para__2_CaptionLbl)
                {
                }
                column(EmptyStringCaption_Control1150085; EmptyStringCaption_Control1150085Lbl)
                {
                }
                column(Deductions_Caption; Deductions_CaptionLbl)
                {
                }
                column(Amount_to_be_paid_to_federal_tax_authoritiesCaption; Amount_to_be_paid_to_federal_tax_authoritiesCaptionLbl)
                {
                }
                column(EmptyStringCaption_Control1150090; EmptyStringCaption_Control1150090Lbl)
                {
                }
                column(Credit_of_taxable_personCaption; Credit_of_taxable_personCaptionLbl)
                {
                }
                column(EmptyStringCaption_Control1150094; EmptyStringCaption_Control1150094Lbl)
                {
                }
                column(I__REVENUECaption; I__REVENUECaptionLbl)
                {
                }
                column(III__OTHER_CASH_FLOW__Art__18_para__2_Caption; III__OTHER_CASH_FLOW__Art__18_para__2_CaptionLbl)
                {
                }
                column(Grants__visitor_s_taxes_and_similar__disposal_and_waterworks_contributionsCaption; Grants__visitor_s_taxes_and_similar__disposal_and_waterworks_contributionsCaptionLbl)
                {
                }
                column(Donations__dividends_compensation_etc_Caption; Donations__dividends_compensation_etc_CaptionLbl)
                {
                }
                column(Revenue_CHFCaption_Control1150127; Revenue_CHFCaption_Control1150127Lbl)
                {
                }
                column(Tax_CHF___Rp_Caption_Control1150128; Tax_CHF___Rp_Caption_Control1150128Lbl)
                {
                }
                column(EmptyStringCaption_Control1150130; EmptyStringCaption_Control1150130Lbl)
                {
                }
                column(EmptyStringCaption_Control1150135; EmptyStringCaption_Control1150135Lbl)
                {
                }
                column(EmptyStringCaption_Control1150131; EmptyStringCaption_Control1150131Lbl)
                {
                }
                column(EmptyStringCaption_Control1150132; EmptyStringCaption_Control1150132Lbl)
                {
                }
                column(EmptyStringCaption_Control1150133; EmptyStringCaption_Control1150133Lbl)
                {
                }
                column(EmptyStringCaption_Control1150134; EmptyStringCaption_Control1150134Lbl)
                {
                }
                column(EmptyStringCaption_Control1150136; EmptyStringCaption_Control1150136Lbl)
                {
                }
                column(EmptyStringCaption_Control1150137; EmptyStringCaption_Control1150137Lbl)
                {
                }
                column(EmptyStringCaption_Control1150138; EmptyStringCaption_Control1150138Lbl)
                {
                }
                column(EmptyStringCaption_Control1150139; EmptyStringCaption_Control1150139Lbl)
                {
                }
                column(EmptyStringCaption_Control1150143; EmptyStringCaption_Control1150143Lbl)
                {
                }
                column(EmptyStringCaption_Control1150142; EmptyStringCaption_Control1150142Lbl)
                {
                }
                column(EmptyStringCaption_Control1150141; EmptyStringCaption_Control1150141Lbl)
                {
                }
                column(EmptyStringCaption_Control1150140; EmptyStringCaption_Control1150140Lbl)
                {
                }
                column(EmptyStringCaption_Control1150144; EmptyStringCaption_Control1150144Lbl)
                {
                }
                column(EmptyStringCaption_Control1150145; EmptyStringCaption_Control1150145Lbl)
                {
                }
                column(EmptyStringCaption_Control1150146; EmptyStringCaption_Control1150146Lbl)
                {
                }
                column(EmptyStringCaption_Control1150147; EmptyStringCaption_Control1150147Lbl)
                {
                }
                column(EmptyStringCaption_Control1150148; EmptyStringCaption_Control1150148Lbl)
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(BottomSign_MainLbl; BottomSign_MainLbl)
                {
                }
                column(BottomSign_DateLbl; BottomSign_DateLbl)
                {
                }
                column(BottomSign_SignatureLbl; BottomSign_SignatureLbl)
                {
                }
                column(BottomSign_ContactLbl; BottomSign_ContactLbl)
                {
                }
                column(FromDateLbl; StrSubstNo(FromDateLbl, Format(EndDateOfOldRates + 1)))
                {
                }
                column(ToDateLbl; StrSubstNo(ToDateLbl, (EndDateOfOldRates)))
                {
                }

                trigger OnAfterGetRecord()
                var
                    TotalOwnedTax: Decimal;
                    TotalInputTax: Decimal;
                begin
                    TaxCHF300 := CalcCipherTaxAmount(VATCipherSetup."Tax Normal Rate Serv. Before", NormalRateOld);
                    TaxCHF310 := CalcCipherTaxAmount(VATCipherSetup."Tax Reduced Rate Serv. Before", ReducedRateOld);
                    TaxCHF340 := CalcCipherTaxAmount(VATCipherSetup."Tax Hotel Rate Serv. Before", HotelRateOld);
                    TaxCHF380 := CalcCipherTaxAmount(VATCipherSetup."Acquisition Tax Before", NormalRateOld);
                    TaxCHF301 := CalcCipherTaxAmount(VATCipherSetup."Tax Normal Rate Serv. After", NormalRateCur);
                    TaxCHF311 := CalcCipherTaxAmount(VATCipherSetup."Tax Reduced Rate Serv. After", ReducedRateCur);
                    TaxCHF341 := CalcCipherTaxAmount(VATCipherSetup."Tax Hotel Rate Serv. After", HotelRateCur);
                    TaxCHF381 := CalcCipherTaxAmount(VATCipherSetup."Acquisition Tax After", NormalRateCur);

                    TotalOwnedTax := TaxCHF300 + TaxCHF310 + TaxCHF340 + TaxCHF380 + TaxCHF301 + TaxCHF311 + TaxCHF341 + TaxCHF381;
                    TotalInputTax := GetCipherAmount(VATCipherSetup."Total Input Tax");
                    if (TotalOwnedTax - TotalInputTax) > 0 then
                        Cipher500Amt := TotalOwnedTax - TotalInputTax
                    else
                        Cipher510Amt := TotalOwnedTax - TotalInputTax;
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                GetCheckVATCipherSetup();
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
                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';

                            trigger OnValidate()
                            begin
                                StartDateOnAfterValidate();
                            end;
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the date to which the report or batch job processes information.';

                            trigger OnValidate()
                            begin
                                EndDateReqOnAfterValidate();
                            end;
                        }
                    }
                    field(ClosedRgstrNo; ClosedRgstrNo)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Closed with VAT Register No.';
                        ToolTip = 'Specifies the VAT Register that contains the posting source of the VAT adjusting entries. This option evaluates accounting periods that have already been settled. When you choose this option, you do not specify options in the following Include VAT Entries fields.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(LookUpClosedRgstrNo(Text));
                        end;

                        trigger OnValidate()
                        begin
                            ValidateClosedRgstrNo();
                        end;
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include VAT entries that are either open or closed, or both open and closed entries.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include VAT entries that are from the specified period or also include entries from before the period.';
                    }
                    field(NormalRatePct; NormalRateCur)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Normal Rate %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the standard VAT rate that applies to the time period.';
                    }
                    field(ReducedRatePct; ReducedRateCur)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Reduced Rate %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the reduced VAT for certain goods and services.';
                    }
                    field(HotelRatePct; HotelRateCur)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Hotel Rate %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the VAT rate for accommodation that applies to the time period.';
                    }
                    field(NormalRateOldPct; NormalRateOld)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Normal (Earlier Rate) %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the standard VAT rate that was applied before the time period.';
                    }
                    field(ReducedRateOldPct; ReducedRateOld)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Reduced (Earlier Rate) %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the reduced VAT rate that was applied to certain transactions before the time period.';
                    }
                    field(HotelRateOldPct; HotelRateOld)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Hotel (Earlier Rate) %';
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies the VAT rate for accommodation that was applied before the time period.';
                    }
                    field(EndDateOfOldRates; EndDateOfOldRates)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date of Earlier VAT Rates';
                        ToolTip = 'Specifies the last date on which VAT rates applied in an earlier period will be included.';

                        trigger OnValidate()
                        begin
                            if EndDateOfOldRates <> 0D then
                                EndDateOfOldRates := CalcDate('<CY>', EndDateOfOldRates)
                        end;
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SourceCodeSetup.Get();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;

        if ClosedRgstrNo = 0 then
            Heading2 := StrSubstNo(Text005, StartDate, EndDateReq)
        else begin
            EndDate := DMY2Date(31, 12, 9999);
            StartDate := 0D;
            Heading2 := StrSubstNo(Text008, ClosedRgstrNo);
            GLReg.Get(ClosedRgstrNo);
        end;

        VATStmtLine.SetRange("Date Filter", StartDate, EndDateReq);

        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text000
        else
            Heading := Text004;

        if (HotelRateCur = 0) or (ReducedRateCur = 0) or (NormalRateCur = 0) then
            Error(Text006);

        GetEndDateOfOldRates();
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HY7', CHVATTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('1000HY8', CHVATTok, 'CH VAT Statement Created and Printed');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CHVATTok: Label 'CH Creat and Print VAT Statement', Locked = true;
        Text000: Label 'VAT entries before and within the period';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2', Comment = '%1=Start Date;%2=End Date';
        VATStmtLine: Record "VAT Statement Line";
        GLReg: Record "G/L Register";
        SourceCodeSetup: Record "Source Code Setup";
        TempVATStmtLine: Record "VAT Statement Line" temporary;
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATCipherSetup: Record "VAT Cipher Setup";
        TempVATReportLine: Record "VAT Report Line" temporary;
        ErrorText: Text[80];
        Heading2: Text[80];
        Heading: Text[80];
        Amount: Decimal;
        NormalRateCur: Decimal;
        ReducedRateCur: Decimal;
        HotelRateCur: Decimal;
        NormalRateOld: Decimal;
        ReducedRateOld: Decimal;
        HotelRateOld: Decimal;
        TaxCHF300: Decimal;
        TaxCHF310: Decimal;
        TaxCHF340: Decimal;
        TaxCHF380: Decimal;
        TaxCHF301: Decimal;
        TaxCHF311: Decimal;
        TaxCHF341: Decimal;
        TaxCHF381: Decimal;
        TotalAmount: Decimal;
        RowNo: array[6] of Code[10];
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        Text006: Label 'VAT Rate Percent fields in the request form must not be zero';
        EndDateOfOldRates: Date;
        i: Integer;
        ClosedRgstrNo: Integer;
        Text007: Label 'GL Register No. %1 does not exists for source code %2';
        Text008: Label 'Closed by VAT Register No. %1';
        Text009: Label 'VAT Statement Cipher number %1 is defined more than one time in VAT Statement %2 %3', Comment = '%1=VAT Cipher;%2=Statement template name;%3=Statment Name';
        Text010: Label 'VAT 2010';
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        Cipher500Amt: Decimal;
        Cipher510Amt: Decimal;
        VAT_Statement_SwitzerlandCaptionLbl: Label 'VAT Statement Switzerland';
        Revenue_CHFCaptionLbl: Label 'Turnover CHF';
        Revenue_CHFCaption_Control1150006Lbl: Label 'Turnover CHF';
        CipherCaptionLbl: Label 'Ref.';
        Total_of_realized_resp_unrealized_revenue_Art_39_incl_revenue_from_transfers_in_the_rep_procedure_as_well_as_servLbl: Label 'Total amount of agreed or collected consideration incl. from supplies opted for taxation, transfer of supplies acc. to the notification procedure and supplies provided abroad (worldwide turnover)';
        In_cipher_200_included_revenue_from_non_taxable_services__Art__21__which_are_opted_for_Art__22CaptionLbl: Label 'Consideration reported in Ref. 200 from supplies exempt from the tax without credit (art. 21) where the option for their taxation according to art. 22 has been exercised';
        Tax_exempt_services_among_others_exports_Art_23_tax_exempt_services_to_benefited_institutions_and_people_Art_107_Lbl: Label 'Supplies exempt from the tax (e.g. export, art. 23) and supplies provided to institutional and individual beneficiaries that are exempt from liability for tax (art. 107 para. 1 lit. a)';
        Services_abroadCaptionLbl: Label 'Supplies provided abroad (place of supply is abroad)';
        Transfer_in_the_reporting_procedure__Art__38__please_submit_Form__764_additionally_CaptionLbl: Label 'Transfer of supplies according to the notification procedure (art. 38, please submit Form 764)';
        Non_taxable_services__Art__21__not_opted_for_Art__22CaptionLbl: Label 'Supplies provided on Swiss territory exempt from the tax without credit (art. 21) and where the option for their taxation according to art. 22 has not been exercised';
        quoted_articles_are_related_to_VAT_law_from_12_06_2009_CaptionLbl: Label '(Articles mentioned refer to the VAT Act of 12.06.2009)';
        Reduction_in_paymentsCaptionLbl: Label 'Reduction of consideration (discounts, rebates etc.)';
        CipherFromToLbl: Label '(Ref. %1 to %2)', Comment = '%1 from value; %2 to value';
        TotalCipherFromToLbl: Label 'Total Ref. %1 to %2', Comment = '%1 from value; %2 to value';
        TaxTurnoverCipherLbl: Label '(Ref. %1 minus Ref. %2)', Comment = '%1 tax amount; %2 deductions';
        MiscellaneousCaptionLbl: Label 'Miscellaneous (e.g. land value, purchase prices in case of margin taxation)';
        EmptyStringCaptionLbl: Label '=';
        EmptyStringCaption_Control1150040Lbl: Label '=';
        II__TAX_COMPUTATIONCaptionLbl: Label 'II. Tax Calculation';
        Tax_CHF___Rp_CaptionLbl: Label 'Tax Amount CHF / cent.';
        Revenue_CHFCaption_Control1150044Lbl: Label 'Supplies CHF';
        Services_at_normal_rateCaptionLbl: Label 'Standard';
        Services_at_reduced_rateCaptionLbl: Label 'Reduced';
        Services_at_hotel_rateCaptionLbl: Label 'Accommodation';
        Acquisition_taxCaptionLbl: Label 'Acquisition tax';
        EmptyStringCaption_Control1150062Lbl: Label '=';
        Tax_CHF___Rp_Caption_Control1150064Lbl: Label 'Tax Amount CHF / cent.';
        Input_tax_on_material_and_servicesCaptionLbl: Label 'Input tax on cost of materials and supplies of services';
        Total_owned_taxCaptionLbl: Label 'Total amount of tax due';
        Input_tax_on_investments_and_other_operating_costsCaptionLbl: Label 'Input tax on investments and other operating costs';
        Deposit_tax__Art__32__please_submit_detailed_list_CaptionLbl: Label 'De-taxation (art. 32, please enclose a detailed list)';
        Total_taxable_revenueCaptionLbl: Label 'Taxable turnover';
        Input_tax_corrections__mixed_usage__Art__30___own_consumption__Art__31_CaptionLbl: Label 'Correction of the input tax deduction: mixed use (art. 30), own use (art. 31)';
        Input_tax_cutbacks__Non_revenue_like_grants__visitor_s_taxes_etc___Art__33_para__2_CaptionLbl: Label 'Reduction of the input tax deduction: Flow of funds, which are not deemed to be consideration, such as subsidies, tourist charges (art. 33 para. 2)';
        EmptyStringCaption_Control1150085Lbl: Label '=';
        Deductions_CaptionLbl: Label 'Deductions:';
        Amount_to_be_paid_to_federal_tax_authoritiesCaptionLbl: Label 'Amount payable';
        EmptyStringCaption_Control1150090Lbl: Label '=';
        Credit_of_taxable_personCaptionLbl: Label 'Credit in favour of the taxable person';
        EmptyStringCaption_Control1150094Lbl: Label '=';
        I__REVENUECaptionLbl: Label 'I. Tunover';
        III__OTHER_CASH_FLOW__Art__18_para__2_CaptionLbl: Label 'III. OTHER CASH FLOWS (Art. 18 para. 2)';
        Grants__visitor_s_taxes_and_similar__disposal_and_waterworks_contributionsCaptionLbl: Label 'Subsidies, tourist funds collected by tourist offices, contributions from cantonal water, sewage or waste funds (art. 18 para. 2 lit. a to c)';
        Donations__dividends_compensation_etc_CaptionLbl: Label 'Donations, dividends, payments of damages etc. (art. 18 para. 2 lit. d to l)';
        Revenue_CHFCaption_Control1150127Lbl: Label 'Supplies CHF';
        Tax_CHF___Rp_Caption_Control1150128Lbl: Label 'Tax Amount CHF / cent.';
        RateCaptionLbl: Label 'Rate';
        BottomSign_MainLbl: Label 'The undersigned herewith confirms the accuracy of the afore-going data:';
        BottomSign_DateLbl: Label 'Date';
        BottomSign_SignatureLbl: Label 'Legally valid signature';
        BottomSign_ContactLbl: Label 'Contact person: Name, telephone number';
        FromDateLbl: Label 'from %1', Comment = '%1 date';
        ToDateLbl: Label 'to %1', Comment = '%1 date';
        EmptyStringCaption_Control1150130Lbl: Label '+';
        EmptyStringCaption_Control1150135Lbl: Label '-';
        EmptyStringCaption_Control1150131Lbl: Label '+';
        EmptyStringCaption_Control1150132Lbl: Label '+';
        EmptyStringCaption_Control1150133Lbl: Label '+';
        EmptyStringCaption_Control1150134Lbl: Label '+';
        EmptyStringCaption_Control1150136Lbl: Label '+';
        EmptyStringCaption_Control1150137Lbl: Label '+';
        EmptyStringCaption_Control1150138Lbl: Label '+';
        EmptyStringCaption_Control1150139Lbl: Label '+';
        EmptyStringCaption_Control1150143Lbl: Label '+';
        EmptyStringCaption_Control1150142Lbl: Label '+';
        EmptyStringCaption_Control1150141Lbl: Label '+';
        EmptyStringCaption_Control1150140Lbl: Label '+';
        EmptyStringCaption_Control1150144Lbl: Label '+';
        EmptyStringCaption_Control1150145Lbl: Label '+';
        EmptyStringCaption_Control1150146Lbl: Label '-';
        EmptyStringCaption_Control1150147Lbl: Label '-';
        EmptyStringCaption_Control1150148Lbl: Label '-';

    [Scope('OnPrem')]
    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    begin
        if Level = 0 then
            TotalAmount := 0;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLAcc.SetRange("VAT Reporting Date Filter", StartDate, EndDate);
                    Amount := 0;
                    if GLAcc.FindSet() and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAcc."Net Change", GLAcc."Additional-Currency Net Change");
                        until GLAcc.Next() = 0;
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                if ClosedRgstrNo = 0 then
                    CalcVATEntryAmount(VATStmtLine2)
                else
                    CalcVATRegisterAmount(VATStmtLine2);
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.FindSet() then
                        repeat
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                end;
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CalcTotalAmount(VATStmtLineAmt: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLineAmt."Calculate with" = 1 then
            Amount := -Amount;
        TotalAmount := TotalAmount + Amount;
    end;

    [Scope('OnPrem')]
    procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);
        exit(Amount + AmountToAdd);
    end;

    [Scope('OnPrem')]
    procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");
        exit('');
    end;

    [Scope('OnPrem')]
    procedure CalcVATRegisterAmount(VatStmtLineRgstrAmt: Record "VAT Statement Line")
    var
        BalVATEntry: Record "VAT Entry";
        VatEntry2: Record "VAT Entry";
        AddCurrAmt: Decimal;
    begin
        Amount := 0;
        GLReg.TestField("From VAT Entry No.");
        GLReg.TestField("To VAT Entry No.");
        BalVATEntry.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group");
        BalVATEntry.SetRange(Type, BalVATEntry.Type::Settlement);
        BalVATEntry.SetRange(Closed, true);
        BalVATEntry.SetRange("VAT Bus. Posting Group", VatStmtLineRgstrAmt."VAT Bus. Posting Group");
        BalVATEntry.SetRange("VAT Prod. Posting Group", VatStmtLineRgstrAmt."VAT Prod. Posting Group");
        BalVATEntry.SetRange("Entry No.", GLReg."From VAT Entry No.", GLReg."To VAT Entry No.");
        if BalVATEntry.FindSet() then
            repeat
                VatEntry2.SetCurrentKey("Closed by Entry No.");
                VatEntry2.SetRange("Closed by Entry No.", BalVATEntry."Entry No.");
                if VatEntry2.FindSet() then
                    repeat
                        if (VatEntry2.Type = VatStmtLineRgstrAmt."Gen. Posting Type") or
                           (VatStmtLineRgstrAmt."Gen. Posting Type" = "General Posting Type"::" ")
                        then
                            case VatStmtLineRgstrAmt."Amount Type" of
                                VatStmtLineRgstrAmt."Amount Type"::Amount:
                                    begin
                                        Amount := Amount + VatEntry2.Amount;
                                        AddCurrAmt := AddCurrAmt + VatEntry2."Additional-Currency Amount";
                                    end;
                                VatStmtLineRgstrAmt."Amount Type"::Base:
                                    begin
                                        Amount := Amount + VatEntry2.Base;
                                        AddCurrAmt := AddCurrAmt + VatEntry2."Additional-Currency Base";
                                    end;
                                VatStmtLineRgstrAmt."Amount Type"::"Unrealized Amount":
                                    begin
                                        Amount := Amount + VatEntry2."Unrealized Amount";
                                        AddCurrAmt := AddCurrAmt + VatEntry2."Add.-Currency Unrealized Amt.";
                                    end;
                                VatStmtLineRgstrAmt."Amount Type"::"Unrealized Base":
                                    begin
                                        Amount := Amount + VatEntry2."Unrealized Base";
                                        AddCurrAmt := AddCurrAmt + VatEntry2."Add.-Currency Unrealized Base";
                                    end;
                            end;
                    until VatEntry2.Next() = 0;
            until BalVATEntry.Next() = 0;
        if UseAmtsInAddCurr then
            Amount := Amount + AddCurrAmt;
        CalcTotalAmount(VatStmtLineRgstrAmt, TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcVATEntryAmount(VatStmtLineEntrAmt: Record "VAT Statement Line")
    begin
        VATEntry.Reset();
        if VATEntry.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date")
        then begin
            VATEntry.SetRange("VAT Bus. Posting Group", VatStmtLineEntrAmt."VAT Bus. Posting Group");
            VATEntry.SetRange("VAT Prod. Posting Group", VatStmtLineEntrAmt."VAT Prod. Posting Group");
        end else begin
            VATEntry.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "VAT Reporting Date");
            VATEntry.SetRange("Tax Jurisdiction Code", VatStmtLineEntrAmt."Tax Jurisdiction Code");
            VATEntry.SetRange("Use Tax", VatStmtLineEntrAmt."Use Tax");
        end;
        VATEntry.SetRange(Type, VatStmtLineEntrAmt."Gen. Posting Type");
        if (EndDateReq <> 0D) or (StartDate <> 0D) then
            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                VATEntry.SetRange("VAT Reporting Date", 0D, EndDate)
            else
                VATEntry.SetRange("VAT Reporting Date", StartDate, EndDate);
        case Selection of
            Selection::Open:
                VATEntry.SetRange(Closed, false);
            Selection::Closed:
                VATEntry.SetRange(Closed, true);
            else
                VATEntry.SetRange(Closed);
        end;
        case VatStmtLineEntrAmt."Amount Type" of
            VatStmtLineEntrAmt."Amount Type"::Amount:
                begin
                    VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                    Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                end;
            VatStmtLineEntrAmt."Amount Type"::Base:
                begin
                    VATEntry.CalcSums(Base, "Additional-Currency Base");
                    Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                end;
            VatStmtLineEntrAmt."Amount Type"::"Unrealized Amount":
                begin
                    VATEntry.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                    Amount := ConditionalAdd(0, VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                end;
            VatStmtLineEntrAmt."Amount Type"::"Unrealized Base":
                begin
                    VATEntry.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                    Amount := ConditionalAdd(0, VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                end;
            else
                VatStmtLineEntrAmt.TestField("Amount Type");
        end;
        CalcTotalAmount(VatStmtLineEntrAmt, TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure ValidateClosedRgstrNo()
    begin
        if ClosedRgstrNo <> 0 then begin
            GLReg.Reset();
            GLReg.SetRange("Source Code", SourceCodeSetup."VAT Settlement");
            GLReg.SetRange("No.", ClosedRgstrNo);
            if GLReg.IsEmpty() then
                Error(Text007, ClosedRgstrNo, SourceCodeSetup."VAT Settlement");
            StartDate := 0D;
            EndDateReq := 0D;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookUpClosedRgstrNo(var Text: Text[1024]): Boolean
    begin
        GLReg.Reset();
        GLReg.FilterGroup(2);
        GLReg.SetRange("Source Code", SourceCodeSetup."VAT Settlement");
        GLReg.FilterGroup(0);
        if PAGE.RunModal(PAGE::"G/L Registers", GLReg) = ACTION::LookupOK then begin
            Text := Format(GLReg."No.");
            exit(true);
        end;
    end;

    local procedure EndDateReqOnAfterValidate()
    begin
        if EndDateReq <> 0D then begin
            ClosedRgstrNo := 0;
            ValidateClosedRgstrNo();
            GetEndDateOfOldRates();
        end;
    end;

    local procedure StartDateOnAfterValidate()
    begin
        if StartDate <> 0D then begin
            ClosedRgstrNo := 0;
            ValidateClosedRgstrNo();
        end;
    end;

    local procedure CalcCipherTaxAmount(CipherCode: Code[20]; TaxPct: Decimal): Decimal
    begin
        exit(Round((GetCipherAmount(CipherCode) / 100) * TaxPct, 0.1, '='));
    end;

    local procedure GetCipherAmount(CipherCode: Code[20]): Decimal
    begin
        if TempVATReportLine.Get(CipherCode, 0) then
            exit(TempVATReportLine.Amount);
        exit(0);
    end;

    local procedure SetCipherAmount(CipherCode: Code[20]; Amount: Decimal)
    begin
        if not TempVATReportLine.Get(CipherCode, 0) then
            exit;

        TempVATReportLine.Amount := Amount;
        TempVATReportLine.Modify();
    end;

    local procedure GetCheckVATCipherSetup()
    var
        "Fields": Record "Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        VATCipherSetup.Get();
        RecordRef.GetTable(VATCipherSetup);
        Fields.SetRange(TableNo, DATABASE::"VAT Cipher Setup");
        Fields.SetFilter(ObsoleteState, '<>%1', Fields.ObsoleteState::Removed);
        Fields.SetFilter("No.", '>1&<2000000000');
        if Fields.FindSet() then
            repeat
                FieldRef := RecordRef.Field(Fields."No.");
                FieldRef.TestField();
            until Fields.Next() = 0;
    end;

    local procedure GetVATRateTxt(VATRate: Decimal): Text
    begin
        exit(StrSubstNo('%1%', VATRate));
    end;

    local procedure GetEndDateOfOldRates()
    begin
        if EndDateOfOldRates <> 0D then
            exit;
        if EndDateReq = 0D then
            EndDateOfOldRates := CalcDate('<-CY>', WorkDate()) - 1
        else
            EndDateOfOldRates := CalcDate('<-CY>', EndDateReq) - 1;
    end;
}

