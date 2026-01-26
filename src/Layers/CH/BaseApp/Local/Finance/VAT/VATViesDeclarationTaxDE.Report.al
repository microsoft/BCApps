// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.Utilities;

report 11007 "VAT-Vies Declaration Tax - DE"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/VATViesDeclarationTaxDE.rdlc';
    Caption = 'VAT- VIES Declaration (Form)';

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group") where(Type = const(Sale));
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

            trigger OnAfterGetRecord()
            var
                VATRegNo: Text[20];
            begin
                if "EU Service" then
                    if "VAT Entry"."VAT Reporting Date" < 20100101D then
                        Error(Text11000, FieldCaption("VAT Reporting Date"), 20100101D);
                if "VAT Registration No." = '' then begin
                    Cust.Get("VAT Entry"."Bill-to/Pay-to No.");
                    Cust.TestField("VAT Registration No.");
                    VATRegNo := Cust."VAT Registration No."
                end else
                    VATRegNo := "VAT Registration No.";

                if (EndDate <> 0D) or (StartDate <> 0D) then
                    TempVATEntry.SetRange("VAT Reporting Date", StartDate, EndDate);
                TempVATEntry.SetRange(Type, Type::Sale);
                TempVATEntry.SetRange("Country/Region Code", "Country/Region Code");
                TempVATEntry.SetRange("VAT Registration No.", VATRegNo);
                TempVATEntry.SetRange("EU 3-Party Trade", "EU 3-Party Trade");
                TempVATEntry.SetRange("EU Service", "EU Service");
                if TempVATEntry.Find('-') then begin
                    TempVATEntry.Base := TempVATEntry.Base + Base;
                    TempVATEntry."Additional-Currency Base" := TempVATEntry."Additional-Currency Base" + "Additional-Currency Base";
                    TempVATEntry.Modify();
                end else begin
                    TempVATEntry := "VAT Entry";
                    TempVATEntry."VAT Registration No." := VATRegNo;
                    TempVATEntry.Insert();
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                CompanyInfo.TestField("VAT Registration No.");

                TempVATEntry.SetCurrentKey(Type, "Country/Region Code", "VAT Registration No.");
            end;
        }
        dataitem(CustVATEntry; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CorrectedNotification; CorrectedNotification)
            {
            }
            column(QuarterValue__Caption; QuarterValue + ' ' + Format(Year))
            {
            }
            column(COPYSTR_TempVATEntry__VAT_Registration_No___1_2_; CopyStr(TempVATEntry."VAT Registration No.", 1, 2))
            {
            }
            column(COPYSTR_TempVATEntry__VAT_Registration_No___3_STRLEN_TempVATEntry__VAT_Registration_No____; CopyStr(TempVATEntry."VAT Registration No.", 3, StrLen(TempVATEntry."VAT Registration No.")))
            {
            }
            column(ROUND__SalesToCust_1_; Round(-SalesToCust, 1))
            {
                DecimalPlaces = 0 : 0;
            }
            column(Number; Number)
            {
            }
            column(EU3PartyTrade; TempVATEntry."EU 3-Party Trade")
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(AdditionalCurrencyBase; Round(-TempVATEntry."Additional-Currency Base", 1))
            {
                DecimalPlaces = 0 : 0;
            }
            column(Base; Round(-TempVATEntry.Base, 1))
            {
                DecimalPlaces = 0 : 0;
            }
            column(SalesToCust; SalesToCust)
            {
                DecimalPlaces = 0 : 0;
            }
            column(EUService; TempVATEntry."EU Service")
            {
            }
            column(ROUND__SalesToCust_1__Control1140081; Round(-SalesToCust, 1))
            {
                DecimalPlaces = 0 : 0;
            }
            column(COPYSTR_TempVATEntry__VAT_Registration_No___3_STRLEN_TempVATEntry__VAT_Registration_No_____Control1140083; CopyStr(TempVATEntry."VAT Registration No.", 3, StrLen(TempVATEntry."VAT Registration No.")))
            {
            }
            column(COPYSTR_TempVATEntry__VAT_Registration_No___1_2__Control1140085; CopyStr(TempVATEntry."VAT Registration No.", 1, 2))
            {
            }
            column(Number_Control1140087; Number)
            {
            }
            column(ROUND__SalesToCust_3_Caption; Round(-SalesToCust, 1))
            {
                DecimalPlaces = 0 : 0;
            }
            column(TempVATEntry__VAT_Registration_No_New_Caption; CopyStr(TempVATEntry."VAT Registration No.", 3, StrLen(TempVATEntry."VAT Registration No.")))
            {
            }
            column(VAT_Registration_No_New_Caption; CopyStr(TempVATEntry."VAT Registration No.", 1, 2))
            {
            }
            column(Number_New_Caption; Number)
            {
            }
            column(ErrorText; ErrorText)
            {
            }
            column(Bitte_beachten_Caption; Bitte_beachten_CaptionLbl)
            {
            }
            column(Enclosure_Sheet_No_Caption; Enclosure_Sheet_No_CaptionLbl)
            {
            }
            column(Meldungder_Caption; Meldungder_CaptionLbl)
            {
            }
            column(VAT_RegistrationCaption; VAT_RegistrationCaptionLbl)
            {
            }
            column(Number__VAT_Reg__No__Caption; Number__VAT_Reg__No__CaptionLbl)
            {
            }
            column(V01Caption; V01CaptionLbl)
            {
            }
            column(V02Caption; V02CaptionLbl)
            {
            }
            column(of_the_Summary_Notification_for_the_Reporting_PeriodCaption; of_the_Summary_Notification_for_the_Reporting_PeriodCaptionLbl)
            {
            }
            column(LineCaption; LineCaptionLbl)
            {
            }
            column(V1Caption_Control1140037; V1Caption_Control1140037Lbl)
            {
            }
            column(V2Caption_Control1140038; V2Caption_Control1140038Lbl)
            {
            }
            column(V3Caption_Control1140039; V3Caption_Control1140039Lbl)
            {
            }
            column(Country_CodeCaption; Country_CodeCaptionLbl)
            {
            }
            column(Base_TotalCaption; Base_TotalCaptionLbl)
            {
            }
            column(full_EURCaption; full_EURCaptionLbl)
            {
            }
            column(CtCaption; CtCaptionLbl)
            {
            }
            column("Sonstige_Leistungen__falls_JA__bitte_1_auswählen_Caption"; Sonstige_Leistungen__falls_JA__bitte_1_auswahlen_CaptionLbl)
            {
            }
            column(CorrectionCaption; CorrectionCaptionLbl)
            {
            }
            column(if_yes__please_enter__1__Caption; if_yes__please_enter__1__CaptionLbl)
            {
            }
            column(V03Caption; V03CaptionLbl)
            {
            }
            column(VAT_Reg__No_Caption; VAT_Reg__No_CaptionLbl)
            {
            }
            column(of_the_customer_entrepreneur_in_another_member_stateCaption; of_the_customer_entrepreneur_in_another_member_stateCaptionLbl)
            {
            }
            column(Sonstige1_Caption; Sonstige1_CaptionLbl)
            {
            }
            column("Dreiecksgeschäfte__falls_JA__bitte_2_auswählen_Caption"; Dreiecksgeschafte__falls_JA__bitte_2_auswahlen_CaptionLbl)
            {
            }
            column(EmptyStringCaption_Control1140205; EmptyStringCaption_Control1140205Lbl)
            {
            }
            column(V1Caption_0_Caption; V1Caption_0_CaptionLbl)
            {
            }
            column(V1Caption_2_Caption; V1Caption_2_CaptionLbl)
            {
            }
            column(V1Caption_1_Caption; V1Caption_1_CaptionLbl)
            {
            }
            column(ErrorTextCaption; ErrorTextCaptionLbl)
            {
            }
            column(Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191Caption; Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number > 1 then
                    TempVATEntry.Next();
                if UseAmtsInAddCurr then
                    SalesToCust := TempVATEntry."Additional-Currency Base"
                else
                    SalesToCust := TempVATEntry.Base;

                TempVATEntry.TestField("Country/Region Code");
                Country.Get("VAT Entry"."Country/Region Code");
                Country.TestField("EU Country/Region Code");
            end;

            trigger OnPreDataItem()
            begin
                TempVATEntry.Reset();
                TempVATEntry.SetCurrentKey(Type, "Country/Region Code", "VAT Registration No.");
                if not TempVATEntry.Find('-') then
                    CurrReport.Break();
                SetRange(Number, 1, TempVATEntry.Count);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(CompanyInfo__VAT_Registration_No___Control1140094; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CorrectedNotification_Control1140166; CorrectedNotification)
            {
            }
            column(DateSignature; Format(DateSignature))
            {
            }
            column(QuarterValue2__Caption; QuarterValue + ' ' + Format(Year))
            {
            }
            column(ChangeToMonthlyReportingMark; ChangeToMonthlyReportingMark)
            {
            }
            column(RevokeMonthlyReportingMark; RevokeMonthlyReportingMark)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(VAT_RegistrationCaption_Control1140092; VAT_RegistrationCaption_Control1140092Lbl)
            {
            }
            column(Number__VAT_Reg__No__Caption_Control1140093; Number__VAT_Reg__No__Caption_Control1140093Lbl)
            {
            }
            column(V01Caption_Control1140096; V01Caption_Control1140096Lbl)
            {
            }
            column(Summary_NotificationCaption; Summary_NotificationCaptionLbl)
            {
            }
            column(Federal_Office_for_FinancesCaption; Federal_Office_for_FinancesCaptionLbl)
            {
            }
            column(regarding_EU_shipments__and_EU_3_Party_TradeCaption; regarding_EU_shipments__and_EU_3_Party_TradeCaptionLbl)
            {
            }
            column(Dienstsitz_Saarlouis__Caption; Dienstsitz_Saarlouis__CaptionLbl)
            {
            }
            column(V66738_SaarlouisCaption; V66738_SaarlouisCaptionLbl)
            {
            }
            column(Reporting_PeriodCaption; Reporting_PeriodCaptionLbl)
            {
            }
            column(cp__figure_III_1__and_III_2__of_the_instructionsCaption; cp__figure_III_1__and_III_2__of_the_instructionsCaptionLbl)
            {
            }
            column(Entrepreneur___Type_and_Address___Phone_No_Caption; Entrepreneur___Type_and_Address___Phone_No_CaptionLbl)
            {
            }
            column(Do_not_fill_in__X___but_add_the_year_Caption; Do_not_fill_in__X___but_add_the_year_CaptionLbl)
            {
            }
            column(V02Caption_Control1140113; V02Caption_Control1140113Lbl)
            {
            }
            column(Phone_No_Caption; Phone_No_CaptionLbl)
            {
            }
            column(CorrectionCaption_Control1140134; CorrectionCaption_Control1140134Lbl)
            {
            }
            column(if_yes__please_enter__1__Caption_Control1140135; if_yes__please_enter__1__Caption_Control1140135Lbl)
            {
            }
            column(V03Caption_Control1140137; V03Caption_Control1140137Lbl)
            {
            }
            column(No__of_SheetsCaption; No__of_SheetsCaptionLbl)
            {
            }
            column(Enclosure_SheetCaption; Enclosure_SheetCaptionLbl)
            {
            }
            column(V04Caption; V04CaptionLbl)
            {
            }
            column(I_confirm_that_I_have_stated_the_information_in_this_summary_notification_truthfully_and_in_all_conscience_Caption; I_confirm_that_I_have_stated_the_information_in_this_summary_notification_truthfully_and_in_all_conscience_CaptionLbl)
            {
            }
            column(Note_Caption; Note_CaptionLbl)
            {
            }
            column(The_following_persons_were_involved_in_the_creation_of_this_summary_notification_Caption; The_following_persons_were_involved_in_the_creation_of_this_summary_notification_CaptionLbl)
            {
            }
            column(Name__Address__Phone_No_Caption; Name__Address__Phone_No_CaptionLbl)
            {
            }
            column(Date__personal_Signature_of_EntrepreneurCaption; Date__personal_Signature_of_EntrepreneurCaptionLbl)
            {
            }
            column(Note_according_to_the_regulations_of_data_protection_laws_Caption; Note_according_to_the_regulations_of_data_protection_laws_CaptionLbl)
            {
            }
            column(The_data_that_is_required_in_this_summary_notification_are_required; The_data_that_is_required_in_this_summary_according_to_the_149_etc_German_Fiscal_Code_AO_and_Lbl)
            {
            }
            column(Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191Caption_Control1140178; Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191Caption_Control1140178Lbl)
            {
            }
            column(Please__specify_only_one_reporting_period_Caption; Please__specify_only_one_reporting_period_CaptionLbl)
            {
            }
            column(cp____18_a_Par___1__S__5_UStG_Caption; cp____18_a_Par___1__S__5_UStG_CaptionLbl)
            {
            }
            column(I_don_t__make_use_of_the_regularization_included_in___18a_Abs__1_Satz_2__Caption; I_don_t_make_use_of_the_regularization_included_in_18a_Abs_1_Satz_2_I_will_submit_the_EU_Sales_List_on_a_monthLbl)
            {
            }
            column(Revokement_of_my_announcement_according_to___18a_Abs__1_UStGCaption; Revokement_of_my_announcement_according_to___18a_Abs__1_UStGCaptionLbl)
            {
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

                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(RepPeriod; RepPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Reporting Period';
                            OptionCaption = 'January,February,March,April,May,June,July,August,September,October,November,December,1. Quarter,2. Quarter,3. Quarter,4. Quarter,Jan/Feb,April/May,July/Aug,Oct/Nov,Calendar Year';
                            ToolTip = 'Specifies the time period that the report applies to. This can be a month, a two-month period, a quarter, or the calendar year.';
                        }
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        }
                        field(EndingDate; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT entries in the report.';
                        }
                    }
                    field(DateSignature; DateSignature)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date of Signature';
                        ToolTip = 'Specifies when the declaration was signed.';
                    }
                    field(CorrectedNotification; CorrectedNotification)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Corrected Notification';
                        ToolTip = 'Specifies whether it is a corrected notification. You should only transmit a corrected notification after a notification for this period has been transmitted electronically or in written form before. On the other hand you must select this check box, if you have already transmitted another notification for this period before.';
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
                    }
                    field(ChangeToMonthlyReporting; ChangeToMonthlyReporting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Change to monthly reporting';
                        ToolTip = 'Specifies that your company has sales of more than 100,000 EURO per quarter and that you must migrate from a quarterly report to a monthly report. Important: Only select this field the first time that you submit a monthly report.';

                        trigger OnValidate()
                        begin
                            if ChangeToMonthlyReporting then begin
                                RevokeMonthlyReporting := false;
                                ChangeToMonthlyReportingMark := 'X';
                                RevokeMonthlyReportingMark := '';
                            end;
                        end;
                    }
                    field(RevokeMonthlyReporting; RevokeMonthlyReporting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Revoke monthly reporting';
                        ToolTip = 'Specifies If you want to switch from monthly reporting to another reporting period. For example, if you have previously submitted monthly declarations but the EU sales are less than 100,000 EURO per quarter, then select this check box and then select one of the quarters in the Reporting Period field.';

                        trigger OnValidate()
                        begin
                            if RevokeMonthlyReporting then begin
                                ChangeToMonthlyReporting := false;
                                RevokeMonthlyReportingMark := 'X';
                                ChangeToMonthlyReportingMark := '';
                            end;
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
            ChangeToMonthlyReporting := false;
            RevokeMonthlyReporting := false;
        end;
    }

    labels
    {
        The_one_who_disregards_his_obligation_according_to___18_a_Sales_VAT_Laws__UStG__purposely_or_carelessly = 'The one who disregards his obligation according to ?18 a Sales VAT Laws (UStG) purposely or carelessly and so does not, does not correctly or does not completely provide a summary notification or does not provide resp. correct it in time, improperly.';
        The_administrative_offence_can_be_avenged_with_a_fine_up_to_five_thousand_Euro____26_a_UStGCaption = 'The administrative offence can be avenged with a fine up to five thousand Euro (?26 a UStG).';
    }

    trigger OnPreReport()
    begin
        if (StartDate = 0D) or (EndDate = 0D) then begin
            if "VAT Entry".GetRangeMin("VAT Reporting Date") = 0D then
                "VAT Entry".FieldError("VAT Reporting Date");
            if "VAT Entry".GetRangeMax("VAT Reporting Date") = 0D then
                "VAT Entry".FieldError("VAT Reporting Date");

            StartDate := "VAT Entry".GetRangeMin("VAT Reporting Date");
            EndDate := "VAT Entry".GetRangeMax("VAT Reporting Date");
        end;
        GetYearFromVatEntry();
        "VAT Entry".SetRange(Type, "VAT Entry".Type::Sale);

        QuarterValue := ReportingPeriodText(RepPeriod);
    end;

    var
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        Cust: Record Customer;
        TempVATEntry: Record "VAT Entry" temporary;
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        SalesToCust: Decimal;
        ErrorText: Text[250];
        Year: Integer;
        RepPeriod: Option January,February,March,April,May,June,July,August,September,October,November,December,"1. Quarter","2. Quarter","3. Quarter","4. Quarter","Jan/Feb","April/May","July/Aug","Oct/Nov","Calendar Year";
        DateSignature: Date;
        StartDate: Date;
        EndDate: Date;
        CorrectedNotification: Boolean;
        UseAmtsInAddCurr: Boolean;
        QuarterValue: Text[30];
        Text11000: Label '%1 must not be less than %2 for Services.';
        ChangeToMonthlyReporting: Boolean;
        RevokeMonthlyReporting: Boolean;
        ChangeToMonthlyReportingMark: Text[1];
        RevokeMonthlyReportingMark: Text[1];
        Bitte_beachten_CaptionLbl: Label 'Bitte beachten!';
        Enclosure_Sheet_No_CaptionLbl: Label 'Enclosure Sheet No.';
        Meldungder_CaptionLbl: Label 'Meldung der Warenlieferungen (? 18a Abs. 4 Nr. 1 u. 2 UStG) vom Inland in das übrige Gemeinschaftsgebiet, der sonstigen Leistungen (? 18a Abs. 4 Satz 1 Nr. 3 UStG) und der Lieferungen i.S.d. ? 25b Abs. 2 UStG im Rahmen innergemeinschaftlicher Dreiecksgeschäfte (? 18a Abs. 4 Satz 1 Nr. 4 UStG)';
        VAT_RegistrationCaptionLbl: Label 'VAT Registration';
        Number__VAT_Reg__No__CaptionLbl: Label 'Number (VAT Reg. No.)';
        V01CaptionLbl: Label '01';
        V02CaptionLbl: Label '02';
        of_the_Summary_Notification_for_the_Reporting_PeriodCaptionLbl: Label 'of the Summary Notification for the Reporting Period', Comment = 'Enclosure Sheet No. of the Summary Notification for the Reporting Period.';
        LineCaptionLbl: Label 'Line';
        V1Caption_Control1140037Lbl: Label '1';
        V2Caption_Control1140038Lbl: Label '2';
        V3Caption_Control1140039Lbl: Label '3';
        Country_CodeCaptionLbl: Label 'Country Code';
        Base_TotalCaptionLbl: Label 'Base Total';
        full_EURCaptionLbl: Label 'Full EUR.', Comment = 'Full value in EUR.';
        CtCaptionLbl: Label 'Ct';
        Sonstige_Leistungen__falls_JA__bitte_1_auswahlen_CaptionLbl: Label 'Sonstige Leistungen (falls JA, bitte 1 auswählen)';
        CorrectionCaptionLbl: Label 'Correction';
        if_yes__please_enter__1__CaptionLbl: Label '(if yes, please enter "1")';
        V03CaptionLbl: Label '03';
        VAT_Reg__No_CaptionLbl: Label 'VAT Reg. No.';
        of_the_customer_entrepreneur_in_another_member_stateCaptionLbl: Label 'of the customer/entrepreneur\in another member state', Comment = 'VAT Reg. No. of the customer/entrepreneur\in another member state.';
        Sonstige1_CaptionLbl: Label 'Sonstige Leistungen bzw. Dreiecks- geschäfte sind in Spalte 3 extra zu kennzeichnen. Bei unterschiedlichen Leistungen andenselben Unternehmer ist jeweilseine gesonderte Zeile zu benutzen.';
        Dreiecksgeschafte__falls_JA__bitte_2_auswahlen_CaptionLbl: Label 'Dreiecksgeschäfte (falls JA, bitte 2 auswählen)';
        EmptyStringCaption_Control1140205Lbl: Label '----------------------------------------------';
        V1Caption_0_CaptionLbl: Label '0';
        V1Caption_2_CaptionLbl: Label '2';
        V1Caption_1_CaptionLbl: Label '1';
        ErrorTextCaptionLbl: Label 'Warning!';
        Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191CaptionLbl: Label 'Microsoft Deutschland GmbH - BfF - 8. April 1998 - S7427 a- ZU 23 - SW/191';
        VAT_RegistrationCaption_Control1140092Lbl: Label 'VAT Registration';
        Number__VAT_Reg__No__Caption_Control1140093Lbl: Label 'Number (VAT Reg. No.)';
        V01Caption_Control1140096Lbl: Label '01';
        Summary_NotificationCaptionLbl: Label 'Summary Notification';
        Federal_Office_for_FinancesCaptionLbl: Label 'Federal Office for Finances';
        regarding_EU_shipments__and_EU_3_Party_TradeCaptionLbl: Label 'Regarding EU shipments \ and EU 3-Party Trade';
        Dienstsitz_Saarlouis__CaptionLbl: Label '- Dienstsitz Saarlouis -';
        V66738_SaarlouisCaptionLbl: Label '66738 Saarlouis';
        Reporting_PeriodCaptionLbl: Label 'Reporting Period';
        cp__figure_III_1__and_III_2__of_the_instructionsCaptionLbl: Label 'CP. figure III.1. and III.2. of the instructions';
        Entrepreneur___Type_and_Address___Phone_No_CaptionLbl: Label 'Entrepreneur - Type and Address - Phone No.';
        Do_not_fill_in__X___but_add_the_year_CaptionLbl: Label 'Do not fill in "X", but add the year)';
        V02Caption_Control1140113Lbl: Label '02';
        Phone_No_CaptionLbl: Label 'Phone No.';
        CorrectionCaption_Control1140134Lbl: Label 'Correction';
        if_yes__please_enter__1__Caption_Control1140135Lbl: Label '(if yes, please enter "1")';
        V03Caption_Control1140137Lbl: Label '03';
        No__of_SheetsCaptionLbl: Label 'No. of Sheets';
        Enclosure_SheetCaptionLbl: Label 'Enclosure Sheet';
        V04CaptionLbl: Label '04';
        I_confirm_that_I_have_stated_the_information_in_this_summary_notification_truthfully_and_in_all_conscience_CaptionLbl: Label 'I confirm that I have stated the information in this summary notification truthfully and in all conscience.';
        Note_CaptionLbl: Label 'Note:';
        The_following_persons_were_involved_in_the_creation_of_this_summary_notification_CaptionLbl: Label 'The following persons were involved in the creation of this summary notification:';
        Name__Address__Phone_No_CaptionLbl: Label 'Name, Address, Phone No.';
        Date__personal_Signature_of_EntrepreneurCaptionLbl: Label 'Date, personal Signature of Entrepreneur';
        Note_according_to_the_regulations_of_data_protection_laws_CaptionLbl: Label 'Note according to the regulations of data protection laws:';
        The_data_that_is_required_in_this_summary_according_to_the_149_etc_German_Fiscal_Code_AO_and_Lbl: Label 'The data that is required in this summary notification\are required according to the ?? 149 etc. German Fiscal Code (AO) and\? 18a UStG.\The statement of phone numbers is optional.';
        Microsoft_Deutschland_GmbH___BfF___8__April_1998___S7427_a__ZU_23___SW_191Caption_Control1140178Lbl: Label 'Microsoft Deutschland GmbH - BfF - 8. April 1998 - S7427 a- ZU 23 - SW/191';
        Please__specify_only_one_reporting_period_CaptionLbl: Label '(Please, specify only one reporting period.';
        cp____18_a_Par___1__S__5_UStG_CaptionLbl: Label '(cp. ? 18 a Par. (1) S. 5 UStG)';
        I_don_t_make_use_of_the_regularization_included_in_18a_Abs_1_Satz_2_I_will_submit_the_EU_Sales_List_on_a_monthLbl: Label 'I don''t  make use of the regularization included in ? 18a Abs. 1 Rate 2. In future I will submit the EU Sales List on a monthly base. This announcement is binding for me until the time of revokement, but for the duration of 12 months in minimum.';
        Revokement_of_my_announcement_according_to___18a_Abs__1_UStGCaptionLbl: Label 'Revokement of my announcement according to ? 18a Abs. 1 UStG';

    [Scope('OnPrem')]
    procedure ReportingPeriodText(ReportingPeriod: Integer): Text[30]
    begin
        case ReportingPeriod of
            0:
                exit('Januar');
            1:
                exit('Februar');
            2:
                exit('März');
            3:
                exit('April');
            4:
                exit('Mai');
            5:
                exit('Juni');
            6:
                exit('Juli');
            7:
                exit('August');
            8:
                exit('September');
            9:
                exit('Oktober');
            10:
                exit('November');
            11:
                exit('Dezember');
            12:
                exit('1. Quartal');
            13:
                exit('2. Quartal');
            14:
                exit('3. Quartal');
            15:
                exit('4. Quartal');
            16:
                exit('Jan/Feb');
            17:
                exit('April/Mai');
            18:
                exit('Juli/Aug');
            19:
                exit('Okt/Nov');
            20:
                exit('Kalenderjahr');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetIndicatorCode(EU3rdPartyTrade: Boolean; EUService: Boolean): Integer
    begin
        if EUService then
            exit(1);
        if EU3rdPartyTrade then
            exit(2);
    end;

    local procedure GetYearFromVatEntry()
    begin
        Year := Date2DMY(EndDate, 3);
    end;
}

