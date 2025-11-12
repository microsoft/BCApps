// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Security.User;
using System.Globalization;
using System.Utilities;

report 122 "Reminder - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reminder/ReminderTest.rdlc';
    Caption = 'Reminder - Test';
    WordMergeDataItem = "Reminder Header";

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';
            column(Reminder_Header_No_; "No.")
            {
            }
            column(ShowMIRLines; ShowMIRLines)
            {
            }
            column(ContactPhoneNoLbl; ContactPhoneNoLbl)
            {
            }
            column(ContactMobilePhoneNoLbl; ContactMobilePhoneNoLbl)
            {
            }
            column(ContactEmailLbl; ContactEmailLbl)
            {
            }
            column(ContactPhoneNo; PrimaryContact."Phone No.")
            {
            }
            column(ContactMobilePhoneNo; PrimaryContact."Mobile Phone No.")
            {
            }
            column(ContactEmail; PrimaryContact."E-mail")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TextPage; TextPageLbl)
                {
                }
                column(STRSUBSTNO_Text008_ReminderHeaderFilter_; StrSubstNo(Text008, ReminderHeaderFilter))
                {
                }
                column(ReminderHeaderFilter; ReminderHeaderFilter)
                {
                }
                column(STRSUBSTNO___1__2___Reminder_Header___No___Cust_Name_; StrSubstNo('%1 %2', "Reminder Header"."No.", Cust.Name))
                {
                }
                column(CustAddr_8_; CustAddr[8])
                {
                }
                column(CustAddr_7_; CustAddr[7])
                {
                }
                column(CustAddr_6_; CustAddr[6])
                {
                }
                column(CustAddr_5_; CustAddr[5])
                {
                }
                column(CustAddr_4_; CustAddr[4])
                {
                }
                column(CustAddr_3_; CustAddr[3])
                {
                }
                column(CustAddr_2_; CustAddr[2])
                {
                }
                column(CustAddr_1_; CustAddr[1])
                {
                }
                column(Reminder_Header___Reminder_Terms_Code_; "Reminder Header"."Reminder Terms Code")
                {
                }
                column(Reminder_Header___Reminder_Level_; "Reminder Header"."Reminder Level")
                {
                }
                column(Reminder_Header___Document_Date_; Format("Reminder Header"."Document Date"))
                {
                }
                column(Reminder_Header___Posting_Date_; Format("Reminder Header"."Posting Date"))
                {
                }
                column(Reminder_Header___Post_Interest_; Format("Reminder Header"."Post Interest"))
                {
                }
                column(Reminder_Header___VAT_Registration_No__; "Reminder Header"."VAT Registration No.")
                {
                }
                column(Reminder_Header___Your_Reference_; "Reminder Header"."Your Reference")
                {
                }
                column(Reminder_Header___Post_Additional_Fee_; Format("Reminder Header"."Post Additional Fee"))
                {
                }
                column(Reminder_Header___Post_Additional_Fee_per_Line; Format("Reminder Header"."Post Add. Fee per Line"))
                {
                }
                column(Reminder_Header___Fin__Charge_Terms_Code_; "Reminder Header"."Fin. Charge Terms Code")
                {
                }
                column(Reminder_Header___Due_Date_; Format("Reminder Header"."Due Date"))
                {
                }
                column(Reminder_Header___Customer_No__; "Reminder Header"."Customer No.")
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(Reminder___TestCaption; Reminder___TestCaptionLbl)
                {
                }
                column(Reminder_Header___Reminder_Terms_Code_Caption; "Reminder Header".FieldCaption("Reminder Terms Code"))
                {
                }
                column(Reminder_Header___Reminder_Level_Caption; "Reminder Header".FieldCaption("Reminder Level"))
                {
                }
                column(Reminder_Header___Document_Date_Caption; Reminder_Header___Document_Date_CaptionLbl)
                {
                }
                column(Reminder_Header___Posting_Date_Caption; Reminder_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Reminder_Header___Post_Interest_Caption; CaptionClassTranslate("Reminder Header".FieldCaption("Post Interest")))
                {
                }
                column(Reminder_Header___Post_Additional_Fee_Caption; CaptionClassTranslate("Reminder Header".FieldCaption("Post Additional Fee")))
                {
                }
                column(Reminder_Header___Post_Additional_Fee_per_Line_Caption; CaptionClassTranslate("Reminder Header".FieldCaption("Post Add. Fee per Line")))
                {
                }
                column(Reminder_Header___Fin__Charge_Terms_Code_Caption; "Reminder Header".FieldCaption("Fin. Charge Terms Code"))
                {
                }
                column(Reminder_Header___Due_Date_Caption; Reminder_Header___Due_Date_CaptionLbl)
                {
                }
                column(Reminder_Header___Customer_No__Caption; "Reminder Header".FieldCaption("Customer No."))
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        Clear(DimText);
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                exit;
                            end;
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        DimSetEntry.SetRange("Dimension Set ID", "Reminder Header"."Dimension Set ID");
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem("Reminder Line"; "Reminder Line")
                {
                    DataItemLink = "Reminder No." = field("No.");
                    DataItemLinkReference = "Reminder Header";
                    DataItemTableView = sorting("Reminder No.", "Line No.") where("Line Type" = filter(<> "Not Due"));
                    column(Reminder_Line_Description; Description)
                    {
                    }
                    column(Reminder_Line__Type; Type)
                    {
                    }
                    column(Reminder_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Reminder_Line__Original_Amount_; "Original Amount")
                    {
                    }
                    column(Reminder_Line__Remaining_Amount_; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Reminder_Line__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(Reminder_Line__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Reminder_Line__Document_Type_; "Document Type")
                    {
                    }
                    column(NNC_TotalLCYVATAmount; NNC_TotalLCYVATAmount)
                    {
                    }
                    column(NNC_VATAmount; NNC_VATAmount)
                    {
                    }
                    column(NNC_TotalLCY; NNC_TotalLCY)
                    {
                    }
                    column(NNC_Interest; NNC_Interest)
                    {
                    }
                    column(Reminder_Line__No__; "No.")
                    {
                    }
                    column(Text009; Text009Lbl)
                    {
                    }
                    column(Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100__1; (ReminderInterestAmount + "VAT Amount" + "Reminder Header"."Additional Fee" - AddFeeInclVAT) / (VATInterest / 100 + 1))
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Remaining_Amount_VATInterest_100____Reminder_Header___Additional_Fee____AddFeeInclVAT; "Remaining Amount" + ReminderInterestAmount)
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(Reminder_Header___Additional_Fee_; "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(Remaining_Amount____ReminderInterestAmount____VAT_Amount_; "Remaining Amount" + ReminderInterestAmount + "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Reminder_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Reminder_Line__Original_Amount_Caption; FieldCaption("Original Amount"))
                    {
                    }
                    column(Reminder_Line__Remaining_Amount_Caption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Reminder_Line__Due_Date_Caption; Reminder_Line__Due_Date_CaptionLbl)
                    {
                    }
                    column(Reminder_Line__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Reminder_Line__Document_Date_Caption; Reminder_Line__Document_Date_CaptionLbl)
                    {
                    }
                    column(Reminder_Line__Document_Type_Caption; FieldCaption("Document Type"))
                    {
                    }
                    column(Text009Caption; Text009CaptionLbl)
                    {
                    }
                    column(ReminderInterestAmount_VATInterest_100__1_Caption; ReminderInterestAmount_VATInterest_100__1_CaptionLbl)
                    {
                    }
                    column(VAT_AmountCaption; VAT_AmountCaptionLbl)
                    {
                    }
                    column(Interest; Interest)
                    {
                    }
                    column(Reminder_Line__Multiple_Interest_Rates_Entry; "Detailed Interest Rates Entry")
                    {
                    }
                    column(Reminder_Line__Type_Customer_Ledger_Entry; (Type = Type::"Customer Ledger Entry"))
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control97; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not "Detailed Interest Rates Entry" then begin
                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."VAT Amount" := "VAT Amount";
                            TempVATAmountLine."Amount Including VAT" := Amount + "VAT Amount";
                            TempVATAmountLine.InsertLine();

                            ReminderInterestAmount := 0;

                            case Type of
                                Type::"G/L Account":
                                    "Remaining Amount" := Amount;
                                Type::"Line Fee":
                                    "Remaining Amount" := Amount;
                                Type::"Customer Ledger Entry":
                                    ReminderInterestAmount := Amount;
                            end;

                            TotalVATAmount += "VAT Amount";

                            NNC_RemAmtTotal += "Remaining Amount";
                            NNC_VatAmtTotal += "VAT Amount";
                            NNC_ReminderInterestAmt += ReminderInterestAmount;

                            NNC_Interest :=
                              (NNC_ReminderInterestAmt + NNC_VatAmtTotal + "Reminder Header"."Additional Fee" - AddFeeInclVAT +
                               "Reminder Header"."Add. Fee per Line" - AddFeePerLineInclVAT) /
                              (VATInterest / 100 + 1);

                            NNC_TotalLCY := NNC_RemAmtTotal + NNC_ReminderInterestAmt;

                            NNC_VATAmount := NNC_VatAmtTotal;

                            NNC_TotalLCYVATAmount := NNC_RemAmtTotal + NNC_VatAmtTotal + NNC_ReminderInterestAmt;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalVATAmount := 0;

                        if Find('+') then
                            repeat
                                Continue := "No. of Reminders" = 0;
                            until ((Next(-1) = 0) or not Continue);

                        TempVATAmountLine.DeleteAll();
                        Clear(ReminderInterestAmount);
                    end;
                }
                dataitem("Not Due"; "Reminder Line")
                {
                    DataItemLink = "Reminder No." = field("No.");
                    DataItemLinkReference = "Reminder Header";
                    DataItemTableView = sorting("Reminder No.", "Line No.") where("Line Type" = const("Not Due"));
                    column(Not_Due__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(Not_Due__Document_Type_; "Document Type")
                    {
                    }
                    column(Not_Due__Document_No__; "Document No.")
                    {
                    }
                    column(Not_Due__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Not_Due__Original_Amount_; "Original Amount")
                    {
                    }
                    column(Not_Due__Remaining_Amount_; "Remaining Amount")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Not_Due__Type; Type)
                    {
                    }
                    column(Not_Due__Document_Type_Caption; FieldCaption("Document Type"))
                    {
                    }
                    column(Not_Due__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Not_Due__Due_Date_Caption; Not_Due__Due_Date_CaptionLbl)
                    {
                    }
                    column(Not_Due__Original_Amount_Caption; FieldCaption("Original Amount"))
                    {
                    }
                    column(Not_Due__Remaining_Amount_Caption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Not_Due__Document_Date_Caption; Not_Due__Document_Date_CaptionLbl)
                    {
                    }
                    column(Open_Entries_Not_DueCaption; Open_Entries_Not_DueCaptionLbl)
                    {
                    }
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VALVATAmount; VALVATAmount)
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                    {
                    }
                    column(VATAmountLine__Amount_Including_VAT_; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount__Control51; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Base__Control52; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__Amount_Including_VAT__Control78; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase_Control49; VALVATBase)
                    {
                        AutoFormatExpression = "Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT_Amount_Caption; VATAmountLine__VAT_Amount_CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT_Base_Caption; VATAmountLine__VAT_Base_CaptionLbl)
                    {
                    }
                    column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                    {
                    }
                    column(VATAmountLine__Amount_Including_VAT_Caption; VATAmountLine__Amount_Including_VAT_CaptionLbl)
                    {
                    }
                    column(VALVATBase_Control49Caption; VALVATBase_Control49CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                        VALVATBase := TempVATAmountLine."Amount Including VAT" / (1 + TempVATAmountLine."VAT %" / 100);
                        VALVATAmount := TempVATAmountLine."Amount Including VAT" - VALVATBase;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if TotalVATAmount = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, TempVATAmountLine.Count);
                        Clear(VALVATBase);
                        Clear(VALVATAmount);
                    end;
                }
                dataitem(VATCounterLCY; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VALExchRate; VALExchRate)
                    {
                    }
                    column(VALSpecLCYHeader; VALSpecLCYHeader)
                    {
                    }
                    column(VALVATAmountLCY; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATAmountLCY_Control114; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control115; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT____Control116; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VALVATAmountLCY_Control121; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control122; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATAmountLCY_Control114Caption; VALVATAmountLCY_Control114CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control115Caption; VALVATBaseLCY_Control115CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT____Control116Caption; VATAmountLine__VAT____Control116CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control122Caption; VALVATBaseLCY_Control122CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        VALVATBaseLCY := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                              "Reminder Header"."Posting Date", "Reminder Header"."Currency Code",
                              VALVATBase, CurrFactor));
                        VALVATAmountLCY := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                              "Reminder Header"."Posting Date", "Reminder Header"."Currency Code",
                              VALVATAmount, CurrFactor));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (not GLSetup."Print VAT specification in LCY") or
                           ("Reminder Header"."Currency Code" = '') or
                           (TempVATAmountLine.GetTotalVATAmount() = 0)
                        then
                            CurrReport.Break();

                        SetRange(Number, 1, TempVATAmountLine.Count);
                        Clear(VALVATBaseLCY);
                        Clear(VALVATAmountLCY);

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text011 + Text012
                        else
                            VALSpecLCYHeader := Text011 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Reminder Header"."Posting Date", "Reminder Header"."Currency Code", 1);
                        VALExchRate := StrSubstNo(Text013, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        CurrFactor := CurrExchRate.ExchangeRate("Reminder Header"."Posting Date",
                            "Reminder Header"."Currency Code");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                GLAcc: Record "G/L Account";
                CustPostingGroup: Record "Customer Posting Group";
                VATPostingSetup: Record "VAT Posting Setup";
                UserSetupManagement: Codeunit "User Setup Management";
                TempErrorText: Text[250];
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                CalcFields("Remaining Amount");
                if "Customer No." = '' then
                    AddError(StrSubstNo(Text000, FieldCaption("Customer No.")))
                else
                    if Cust.Get("Customer No.") then begin
                        if Cust."Privacy Blocked" then
                            AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                        if Cust.Blocked = Cust.Blocked::All then
                            AddError(
                              StrSubstNo(
                                Text010,
                                Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), "Customer No."));
                    end else
                        AddError(
                          StrSubstNo(
                            Text003,
                            Cust.TableCaption(), "Customer No."));

                GLSetup.Get();

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Posting Date")))
                else
                    if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                        AddError(TempErrorText);

                if "Document Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Document Date")));
                if "Due Date" = 0D then
                    AddError(StrSubstNo(Text000, FieldCaption("Due Date")));
                if "Customer Posting Group" = '' then
                    AddError(StrSubstNo(Text000, FieldCaption("Customer Posting Group")));
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text005, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text006, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text005, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text006, "Currency Code");
                end;
                FormatAddr.Reminder(CustAddr, "Reminder Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr());
                Cust.GetPrimaryContact("Customer No.", PrimaryContact);

                TableID[1] := DATABASE::Customer;
                No[1] := "Customer No.";
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());

                CalcFields("Additional Fee");
                CustPostingGroup.Get("Customer Posting Group");
                if GLAcc.Get(CustPostingGroup."Additional Fee Account") then begin
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    AddFeeInclVAT := "Additional Fee" * (1 + VATPostingSetup."VAT %" / 100);
                end else
                    AddFeeInclVAT := "Additional Fee";

                CalcFields("Add. Fee per Line");
                AddFeePerLineInclVAT := "Add. Fee per Line" + CalculateLineFeeVATAmount();

                CalcFields("Interest Amount", "VAT Amount");
                if ("Interest Amount" <> 0) and ("VAT Amount" <> 0) then begin
                    GLAcc.Get(CustPostingGroup."Interest Account");
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    VATInterest := VATPostingSetup."VAT %";
                    Interest :=
                      ("Interest Amount" +
                       "VAT Amount" + "Additional Fee" - AddFeeInclVAT + "Add. Fee per Line" - AddFeePerLineInclVAT) / (VATInterest / 100 + 1);
                end else begin
                    Interest := "Interest Amount";
                    VATInterest := 0;
                end;

                NNC_Interest := 0;
                NNC_TotalLCY := 0;
                NNC_VATAmount := 0;
                NNC_TotalLCYVATAmount := 0;
                NNC_RemAmtTotal := 0;
                NNC_VatAmtTotal := 0;
                NNC_ReminderInterestAmt := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
                    }
                    field(ShowMIR; ShowMIRLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show MIR Detail';
                        ToolTip = 'Specifies if you want multiple interest rate details for the journal lines to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ReminderHeaderFilter := "Reminder Header".GetFilters();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
        Text003: Label '%1 %2 does not exist.';
        Text005: Label 'Total %1';
        Text006: Label 'Total %1 Incl. VAT';
        Text008: Label 'Reminder: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PrimaryContact: Record Contact;
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        DimMgt: Codeunit DimensionManagement;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        ReminderHeaderFilter: Text;
        ReminderInterestAmount: Decimal;
        Continue: Boolean;
        VATNoText: Text[30];
        ReferenceText: Text[35];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label '%1 must not be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
#pragma warning disable AA0074
        Text011: Label 'VAT Amount Specification in ';
        Text012: Label 'Local Currency';
#pragma warning disable AA0470
        Text013: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrFactor: Decimal;
        TotalVATAmount: Decimal;
        AddFeeInclVAT: Decimal;
        AddFeePerLineInclVAT: Decimal;
        VATInterest: Decimal;
        Interest: Decimal;
        VALVATBase: Decimal;
        VALVATAmount: Decimal;
        NNC_Interest: Decimal;
        NNC_TotalLCY: Decimal;
        NNC_VATAmount: Decimal;
        NNC_TotalLCYVATAmount: Decimal;
        NNC_RemAmtTotal: Decimal;
        NNC_VatAmtTotal: Decimal;
        NNC_ReminderInterestAmt: Decimal;
        TextPageLbl: Label 'Page';
        Reminder___TestCaptionLbl: Label 'Reminder - Test';
        Reminder_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Reminder_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Reminder_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Text009Lbl: Label 'Interests must be positive or 0.';
        Reminder_Line__Due_Date_CaptionLbl: Label 'Due Date';
        Reminder_Line__Document_Date_CaptionLbl: Label 'Document Date';
        Text009CaptionLbl: Label 'Warning!';
        ReminderInterestAmount_VATInterest_100__1_CaptionLbl: Label 'Interest Amount';
        VAT_AmountCaptionLbl: Label 'VAT Amount';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        Not_Due__Due_Date_CaptionLbl: Label 'Due Date';
        Not_Due__Document_Date_CaptionLbl: Label 'Document Date';
        Open_Entries_Not_DueCaptionLbl: Label 'Open Entries Not Due';
        VATAmountLine__VAT_Amount_CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base_CaptionLbl: Label 'VAT Base';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__Amount_Including_VAT_CaptionLbl: Label 'Amount Including VAT';
        VALVATBase_Control49CaptionLbl: Label 'Total';
        VALVATAmountLCY_Control114CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control115CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control116CaptionLbl: Label 'VAT %';
        VALVATBaseLCY_Control122CaptionLbl: Label 'Total';
        ContactPhoneNoLbl: Label 'Contact Phone No.';
        ContactMobilePhoneNoLbl: Label 'Contact Mobile Phone No.';
        ContactEmailLbl: Label 'Contact E-Mail';
        ShowMIRLines: Boolean;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;
}

