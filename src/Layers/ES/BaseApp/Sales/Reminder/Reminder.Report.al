// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using System.Email;
using System.Globalization;
using System.Text;
using System.Utilities;

report 117 Reminder
{
    Caption = 'Reminder';
    DefaultRenderingLayout = "Reminder.rdlc";
    WordMergeDataItem = "Issued Reminder Header";

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';
            column(Issued_Reminder_Header_No_; "No.")
            {
            }
            column(DueDateCaption; Issued_Reminder_Header___Due_Date_CaptionLbl)
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
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Issued_Reminder_Header___Due_Date_; Format("Issued Reminder Header"."Due Date"))
                {
                }
                column(Issued_Reminder_Header___Posting_Date_; Format("Issued Reminder Header"."Posting Date"))
                {
                }
                column(Issued_Reminder_Header___No__; "Issued Reminder Header"."No.")
                {
                }
                column(Issued_Reminder_Header___Your_Reference_; "Issued Reminder Header"."Your Reference")
                {
                }
                column(Contact_IssuedReminderHdr; "Issued Reminder Header".Contact)
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VatRegNo_IssueReminderHdr; "Issued Reminder Header".GetCustomerVATRegistrationNumber())
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(Issued_Reminder_Header___Document_Date_; Format("Issued Reminder Header"."Document Date"))
                {
                }
                column(Issued_Reminder_Header___Customer_No__; "Issued Reminder Header"."Customer No.")
                {
                }
                column(CompanyInfo__Bank_Account_No__; CompanyBankAccount."Bank Account No.")
                {
                }
                column(CompanyInfoIBAN; CompanyBankAccount.IBAN)
                {
                }
                column(CompanyInfo__Bank_Name_; CompanyBankAccount.Name)
                {
                }
                column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfoVATRegNo; CompanyInfo.GetVATRegistrationNumber())
                {
                }
                column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                {
                }
                column(CustAddr_8_; CustAddr[8])
                {
                }
                column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                {
                }
                column(CustAddr_7_; CustAddr[7])
                {
                }
                column(CustAddr_6_; CustAddr[6])
                {
                }
                column(CompanyAddr6; CompanyAddr[6])
                {
                }
                column(CustAddr_5_; CustAddr[5])
                {
                }
                column(CompanyAddr5; CompanyAddr[5])
                {
                }
                column(CustAddr_4_; CustAddr[4])
                {
                }
                column(CompanyAddr4; CompanyAddr[4])
                {
                }
                column(CustAddr_3_; CustAddr[3])
                {
                }
                column(CompanyAddr3; CompanyAddr[3])
                {
                }
                column(CustAddr_2_; CustAddr[2])
                {
                }
                column(CompanyAddr2; CompanyAddr[2])
                {
                }
                column(CustAddr_1_; CustAddr[1])
                {
                }
                column(CompanyAddr1; CompanyAddr[1])
                {
                }
                column(TextPage; TextPageLbl)
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(Issued_Reminder_Header___Due_Date_Caption; Issued_Reminder_Header___Due_Date_CaptionLbl)
                {
                }
                column(Issued_Reminder_Header___Posting_Date_Caption; Issued_Reminder_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Issued_Reminder_Header___No__Caption; Issued_Reminder_Header___No__CaptionLbl)
                {
                }
                column(Issued_Reminder_Header___Customer_No__Caption; "Issued Reminder Header".FieldCaption("Customer No."))
                {
                }
                column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                {
                }
                column(IBANCaption; IBANCaptionLbl)
                {
                }
                column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                {
                }
                column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                {
                }
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl())
                {
                }
                column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                {
                }
                column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                {
                }
                column(ReminderCaption; ReminderCaptionLbl)
                {
                }
                column(CACCaption; CACCaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; Number)
                    {
                    }
                    column(DimText_Control93; DimText)
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
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText,
                                    DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowInternalInfo then
                            CurrReport.Break();
                    end;
                }
                dataitem("Issued Reminder Line"; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = field("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = sorting("Reminder No.", "Line No.");
                    column(Issued_Reminder_Line__Remaining_Amount_; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Desc_IssuedReminderLine; Description)
                    {
                    }
                    column(Type_IssuedReminderLine; Format("Issued Reminder Line".Type, 0, 2))
                    {
                    }
                    column(Issued_Reminder_Line__Document_Date_; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuedReminderLine; "Document No.")
                    {
                    }
                    column(DueDate_IssuedReminderLine; Format("Due Date"))
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount__Control40; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Issued_Reminder_Line__Original_Amount_; "Original Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(DocType_IssuedReminderLine; "Document Type")
                    {
                    }
                    column(Issued_Reminder_Line_Description_Control31; Description)
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount__Control38; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Issued_Reminder_Line__No__; "No.")
                    {
                    }
                    column(ShowInternalInfo; ShowInternalInfo)
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount__Control95; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Issued_Reminder_Line_Description_Control96; Description)
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount__Control42; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(ReminderInterestAmount____VAT_Amount____Issued_Reminder_Header___Additional_Fee____AddFeeInclVAT___VATInterest_100__1_; (ReminderInterestAmount + "VAT Amount" + "Issued Reminder Header"."Additional Fee" - AddFeeInclVAT) / (VATInterest / 100 + 1))
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(NNC_InterestAmount; NNC_InterestAmount)
                    {
                    }
                    column(DataItem44; "Remaining Amount" + ReminderInterestAmount)
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(MIREntry_IssuedReminderLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(NNC_Total; NNC_Total)
                    {
                    }
                    column(Remaining_Amount____ReminderInterestAmount____VAT_Amount_; "Remaining Amount" + ReminderInterestAmount + "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(DataItem121; "VAT Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(NNC_VATAmount; NNC_VATAmount)
                    {
                    }
                    column(NNC_TotalInclVAT; NNC_TotalInclVAT)
                    {
                    }
                    column(TotalVATAmt; TotalVATAmount)
                    {
                    }
                    column(Issued_Reminder_Line_Reminder_No_; "Reminder No.")
                    {
                    }
                    column(Issued_Reminder_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Issued_Reminder_Line__Document_Date_Caption; Issued_Reminder_Line__Document_Date_CaptionLbl)
                    {
                    }
                    column(DocNo_IssuedReminderLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(Issued_Reminder_Line__Due_Date_Caption; Issued_Reminder_Line__Due_Date_CaptionLbl)
                    {
                    }
                    column(RemAmt_IssuedReminderLineCaption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Issued_Reminder_Line__Original_Amount_Caption; FieldCaption("Original Amount"))
                    {
                    }
                    column(DocType_IssuedReminderLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(Interest; Interest)
                    {
                    }
                    column(RemainingAmountText; RemainingAmt)
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount_Caption; Issued_Reminder_Line__Remaining_Amount_CaptionLbl)
                    {
                    }
                    column(Issued_Reminder_Line__Remaining_Amount__Control42Caption; Issued_Reminder_Line__Remaining_Amount__Control42CaptionLbl)
                    {
                    }
                    column(DataItem47; ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_CaptionLbl)
                    {
                    }
                    column(DataItem123; ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_VATInLbl)
                    {
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
                            TempVATAmountLine."VAT Clause Code" := "VAT Clause Code";
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

                            NNC_InterestAmountTotal += ReminderInterestAmount;
                            NNC_RemainingAmountTotal += "Remaining Amount";
                            NNC_VATAmountTotal += "VAT Amount";

                            NNC_InterestAmount := (NNC_InterestAmountTotal + NNC_VATAmountTotal + "Issued Reminder Header"."Additional Fee" -
                                                   AddFeeInclVAT + "Issued Reminder Header"."Add. Fee per Line" - AddFeePerLineInclVAT) /
                              (VATInterest / 100 + 1);
                            NNC_Total := NNC_RemainingAmountTotal + NNC_InterestAmountTotal;
                            NNC_VATAmount := NNC_VATAmountTotal;
                            NNC_TotalInclVAT := NNC_RemainingAmountTotal + NNC_InterestAmountTotal + NNC_VATAmountTotal;

                            TotalRemAmt += "Remaining Amount";
                        end;

                        RemainingAmt := '';

                        if ("Remaining Amount" = 0) and ("Due Date" = 0D) then
                            RemainingAmt := ''
                        else
                            RemainingAmt := Format("Remaining Amount");
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(CompanyInfo.Picture);

                        if FindLast() then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue :=
                                  not ShowNotDueAmounts and
                                  ("No. of Reminders" = 0) and
                                  (((Type = Type::"Customer Ledger Entry") or (Type = Type::"Line Fee")) or (Type = Type::" ")) or
                                  "Detailed Interest Rates Entry" and not ShowMIRLines;
                                if Continue then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;

                        TempVATAmountLine.DeleteAll();
                        SetFilter("Line No.", '<%1', EndLineNo);
                    end;
                }
                dataitem(IssuedReminderLine2; "Issued Reminder Line")
                {
                    DataItemLink = "Reminder No." = field("No.");
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = sorting("Reminder No.", "Line No.");
                    column(IssuedReminderLine2_Description; Description)
                    {
                    }
                    column(IssuedReminderLine2_Reminder_No_; "Reminder No.")
                    {
                    }
                    column(IssuedReminderLine2_Line_No_; "Line No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                        if not ShowNotDueAmounts then begin
                            SetFilter(Type, '<>%1', Type::" ");
                            if FindFirst() then
                                if "Line No." > EndLineNo then begin
                                    SetRange(Type);
                                    SetRange("Line No.", EndLineNo, "Line No." - 1); // find "Open Entries Not Due" line
                                    if FindLast() then
                                        SetRange("Line No.", EndLineNo, "Line No." - 1);
                                end;
                            SetRange(Type);
                        end;
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATAmountLine__Amount_Including_VAT_; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATAmount; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase___VALVATAmount; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATAmount_Control71; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase_Control72; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT___; TempVATAmountLine."VAT %")
                    {
                    }
                    column(VALVATBase___VALVATAmount_Control78; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATAmount_Control79; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase_Control80; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATAmount_Control82; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase_Control83; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase___VALVATAmount_Control85; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATCounter_Number; Number)
                    {
                    }
                    column(VALVATBase___VALVATAmountCaption; VALVATBase___VALVATAmountCaptionLbl)
                    {
                    }
                    column(VALVATAmount_Control71Caption; VALVATAmount_Control71CaptionLbl)
                    {
                    }
                    column(VALVATBase_Control72Caption; VALVATBase_Control72CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                    {
                    }
                    column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                    {
                    }
                    column(VALVATBaseCaption; VALVATBaseCaptionLbl)
                    {
                    }
                    column(VALVATBase_Control80Caption; VALVATBase_Control80CaptionLbl)
                    {
                    }
                    column(VALVATBase_Control83Caption; VALVATBase_Control83CaptionLbl)
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
                        if TempVATAmountLine.GetTotalVATAmount() = 0 then
                            CurrReport.Break();

                        SetRange(Number, 1, TempVATAmountLine.Count);

                        VALVATBase := 0;
                        VALVATAmount := 0;
                    end;
                }
                dataitem(VATClauseEntryCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VATClauseVATIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATClauseCode; TempVATAmountLine."VAT Clause Code")
                    {
                    }
                    column(VATClauseDescription; VATClauseText)
                    {
                    }
                    column(VATClauseDescription2; VATClause."Description 2")
                    {
                    }
                    column(VATClauseAmount; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Issued Reminder Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATClausesCaption; VATClausesCap)
                    {
                    }
                    column(VATClauseVATIdentifierCaption; VATIdentifierCaptionLbl)
                    {
                    }
                    column(VATClauseVATAmtCaption; VALVATBase___VALVATAmountCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                        if not VATClause.Get(TempVATAmountLine."VAT Clause Code") then
                            CurrReport.Skip();
                        VATClauseText := VATClause.GetDescriptionText("Issued Reminder Header");
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(VATClause);
                        SetRange(Number, 1, TempVATAmountLine.Count);
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
                    column(VALVATAmountLCY_Control105; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control106; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATAmountLine__VAT____Control107; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VALVATAmountLCY_Control108; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        VALVATBaseLCY := Round(TempVATAmountLine."Amount Including VAT" / (1 + TempVATAmountLine."VAT %" / 100) / CurrFactor);
                        VALVATAmountLCY := Round(TempVATAmountLine."Amount Including VAT" / CurrFactor - VALVATBaseLCY);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (not GLSetup."Print VAT specification in LCY") or
                           ("Issued Reminder Header"."Currency Code" = '') or
                           (TempVATAmountLine.GetTotalVATAmount() = 0)
                        then
                            CurrReport.Break();

                        SetRange(Number, 1, TempVATAmountLine.Count);

                        VALVATBaseLCY := 0;
                        VALVATAmountLCY := 0;

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text011 + Text012
                        else
                            VALSpecLCYHeader := Text011 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Issued Reminder Header"."Posting Date", "Issued Reminder Header"."Currency Code", 1);
                        CustEntry.SetRange("Customer No.", "Issued Reminder Header"."Customer No.");
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::Reminder);
                        CustEntry.SetRange("Document No.", "Issued Reminder Header"."No.");
                        if CustEntry.FindFirst() then begin
                            CustEntry.CalcFields("Amount (LCY)", Amount);
                            CurrFactor := 1 / (CustEntry."Amount (LCY)" / CustEntry.Amount);
                            VALExchRate := StrSubstNo(Text013, Round(1 / CurrFactor * 100, 0.00001), CurrExchRate."Exchange Rate Amount");
                        end else begin
                            CurrFactor := CurrExchRate.ExchangeRate("Issued Reminder Header"."Posting Date", "Issued Reminder Header"."Currency Code");
                            VALExchRate := StrSubstNo(Text013, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    end;
                }
                dataitem(LetterText; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(GreetingText; GreetingTxt)
                    {
                    }
                    column(AmtDueText; AmtDueTxt)
                    {
                    }
                    column(BodyText; BodyTxt)
                    {
                    }
                    column(ClosingText; ClosingTxt)
                    {
                    }
                    column(DescriptionText; DescriptionTxt)
                    {
                    }
                    column(TotalRemAmt_IssuedReminderLine; TotalRemAmt)
                    {
                    }
                    column(FinalTotalInclVAT; NNC_TotalInclVAT)
                    {
                    }
                    column(VALVATBaseLCY_Control109; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATAmountLCY_Control111; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY_Control112; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATCounterLCY_Number; Number)
                    {
                    }
                    column(VALVATAmountLCY_Control105Caption; VALVATAmountLCY_Control105CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control106Caption; VALVATBaseLCY_Control106CaptionLbl)
                    {
                    }
                    column(VATAmountLine__VAT____Control107Caption; VATAmountLine__VAT____Control107CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCYCaption; VALVATBaseLCYCaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control109Caption; VALVATBaseLCY_Control109CaptionLbl)
                    {
                    }
                    column(VALVATBaseLCY_Control112Caption; VALVATBaseLCY_Control112CaptionLbl)
                    {
                    }

                    trigger OnPreDataItem()
                    var
                        FinanceChargeTerms: Record "Finance Charge Terms";
                        ReminderEmailText: Record "Reminder Email Text";
                        AutoFormat: Codeunit "Auto Format";
                        ReminderCommunication: Codeunit "Reminder Communication";
                        AutoFormatType: Enum "Auto Format";
                        EmailTextInStream: InStream;
                        EmailTextLine: Text;
                    begin
                        if ReminderCommunication.NewReminderCommunicationEnabled() then
                            ReminderCommunication.PopulateEmailText("Issued Reminder Header", CompanyInfo, GreetingTxt, AmtDueTxt, BodyTxt, ClosingTxt, DescriptionTxt, NNC_TotalInclVAT)
                        else begin
                            AmtDueTxt := '';
                            BodyTxt := '';
                            GreetingTxt := ReminderEmailText.GetDefaultGreetingLbl();
                            ClosingTxt := ReminderEmailText.GetDefaultClosingLbl();
                            DescriptionTxt := ReminderEmailText.GetDescriptionLbl();
                            if Format("Issued Reminder Header"."Due Date") <> '' then
                                AmtDueTxt := StrSubstNo(ReminderEmailText.GetAmtDueLbl(), "Issued Reminder Header"."Due Date");

                            if GetEmailTextInStream(EmailTextInStream, "Issued Reminder Header") then begin
                                AmtDueTxt := '';
                                BodyTxt := '';
                                if "Issued Reminder Header"."Fin. Charge Terms Code" <> '' then
                                    FinanceChargeTerms.Get("Issued Reminder Header"."Fin. Charge Terms Code");

                                while EmailTextInStream.ReadText(EmailTextLine) > 0 do
                                    BodyTxt += EmailTextLine;

                                BodyTxt := StrSubstNo(
                                    BodyTxt,
                                    "Issued Reminder Header"."Document Date",
                                    "Issued Reminder Header"."Due Date",
                                    FinanceChargeTerms."Interest Rate",
                                    Format("Issued Reminder Header"."Remaining Amount", 0,
                                        AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, "Issued Reminder Header"."Currency Code")),
                                    "Issued Reminder Header"."Interest Amount",
                                    "Issued Reminder Header"."Additional Fee",
                                    Format(NNC_TotalInclVAT, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, "Issued Reminder Header"."Currency Code")),
                                    "Issued Reminder Header"."Reminder Level",
                                    "Issued Reminder Header"."Currency Code",
                                    "Issued Reminder Header"."Posting Date",
                                    CompanyInfo.Name,
                                    "Issued Reminder Header"."Add. Fee per Line");
                            end else
                                BodyTxt := ReminderEmailText.GetBodyLbl();
                        end;
                        OnLetterTextOnPreDataItemOnAfterSetAmtDueTxt("Issued Reminder Header", AmtDueTxt, GreetingTxt, BodyTxt, ClosingTxt, DescriptionTxt);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                GLAcc: Record "G/L Account";
                CustPostingGroup: Record "Customer Posting Group";
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");

                if not CompanyBankAccount.Get("Issued Reminder Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                FormatAddr.IssuedReminder(CustAddr, "Issued Reminder Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "Issued Reminder Header".GetCustomerVATRegistrationNumber() = '' then
                    VATNoText := ''
                else
                    VATNoText := "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl();
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text000, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text001, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text000, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text001, "Currency Code");
                end;
                if not IsReportInPreviewMode() then
                    IncrNoPrinted();

                Customer.GetPrimaryContact("Customer No.", PrimaryContact);
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

                TotalVATAmount := "VAT Amount";

                ShowCashAccountingCriteria("Issued Reminder Header");

                NNC_InterestAmountTotal := 0;
                NNC_RemainingAmountTotal := 0;
                NNC_VATAmountTotal := 0;
                NNC_InterestAmount := 0;
                NNC_Total := 0;
                NNC_VATAmount := 0;
                NNC_TotalInclVAT := 0;
                TotalRemAmt := 0;

                OnAfterResetAmounts(VATInterest, AddFeeInclVAT, AddFeePerLineInclVAT);
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
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
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the reminder that you print to be recorded as interaction, and to be added to the Interaction Log Entry table.';
                    }
                    field(ShowNotDueAmounts; ShowNotDueAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Not Due Amounts';
                        ToolTip = 'Specifies if you want to show amounts that are not due from customers.';
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

        trigger OnInit()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Rmdr.") <> '';
            LogInteractionEnable := LogInteraction;
            if ReportParametersInitialized then
                LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if ReportParametersInitialized then
                exit;
        end;
    }

    rendering
    {
        layout("Reminder.rdlc")
        {
            Type = RDLC;
            LayoutFile = './Sales/Reminder/Reminder.rdlc';
            Caption = 'Reminder (RDLC)';
            Summary = 'The Reminder (RDLC) provides a detailed layout.';
        }
        layout("DefaultReminderEmail.docx")
        {
            Type = Word;
            LayoutFile = './Sales/Reminder/DefaultReminderEmail.docx';
            Caption = 'Default Reminder Email (Word)';
            Summary = 'The Default Reminder Email (Word) provides an email body for the reminder.';
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        "Issued Reminder Header".OnGetReportParameters(LogInteraction, ShowNotDueAmounts, ShowMIRLines, Report::Reminder, ReportParametersInitialized);
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Issued Reminder Header".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      8, "Issued Reminder Header"."No.", 0, 0, DATABASE::Customer, "Issued Reminder Header"."Customer No.",
                      '', '', "Issued Reminder Header"."Posting Description", '');
                until "Issued Reminder Header".Next() = 0;
    end;

    local procedure GetEmailTextInStream(var EmailTextInStream: InStream; var IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        ReminderText: Record "Reminder Text";
        ReminderTextPosition: Enum "Reminder Text Position";
    begin
        IssuedReminderHeader.CalcFields("Email Text");
        ReminderText.SetAutoCalcFields("Email Text");

        // if there is email text on the reminder, prepare to read it                       
        if IssuedReminderHeader."Email Text".HasValue() then begin
            IssuedReminderHeader."Email Text".CreateInStream(EmailTextInStream);
            exit(true);
        end;

        // otherwise, if there is email text on the reminder level, prepare to read it                       
        if ReminderText.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level", ReminderTextPosition::"Email Body", 0) then
            if ReminderText."Email Text".HasValue() then begin
                ReminderText."Email Text".CreateInStream(EmailTextInstream);
                exit(true);
            end;

        // otherwise, if there is email text on the reminder terms, prepare to read it                       
        if ReminderText.Get(IssuedReminderHeader."Reminder Terms Code", 0, ReminderTextPosition::"Email Body", 0) then
            if ReminderText."Email Text".HasValue() then begin
                ReminderText."Email Text".CreateInStream(EmailTextInstream);
                exit(true)
            end;

        exit(false)
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Total %1';
        Text001: Label 'Total %1 Incl. VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PrimaryContact: Record Contact;
        Customer: Record Customer;
        CustEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        CompanyBankAccount: Record "Bank Account";
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ReminderInterestAmount: Decimal;
        Continue: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        CurrFactor: Decimal;
#pragma warning disable AA0074
        Text011: Label 'VAT Amount Specification in ';
        Text012: Label 'Local Currency';
#pragma warning disable AA0470
        Text013: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AddFeeInclVAT: Decimal;
        AddFeePerLineInclVAT: Decimal;
        TotalVATAmount: Decimal;
        VATInterest: Decimal;
        VALVATBase: Decimal;
        VALVATAmount: Decimal;
        VATClauseText: Text;
        LogInteractionEnable: Boolean;
        TextPageLbl: Label 'Page';
        Issued_Reminder_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Issued_Reminder_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Issued_Reminder_Header___No__CaptionLbl: Label 'Reminder No.';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        IBANCaptionLbl: Label 'IBAN';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        ReminderCaptionLbl: Label 'Reminder';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Issued_Reminder_Line__Document_Date_CaptionLbl: Label 'Document Date';
        Issued_Reminder_Line__Due_Date_CaptionLbl: Label 'Due Date';
        Issued_Reminder_Line__Remaining_Amount_CaptionLbl: Label 'Continued';
        Issued_Reminder_Line__Remaining_Amount__Control42CaptionLbl: Label 'Continued';
        ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_CaptionLbl: Label 'Interest Amount';
        ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_VATInLbl: Label 'VAT Amount';
        VALVATBase___VALVATAmountCaptionLbl: Label 'Amount Including VAT';
        VALVATAmount_Control71CaptionLbl: Label 'VAT Amount';
        VALVATBase_Control72CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VALVATBaseCaptionLbl: Label 'Continued';
#pragma warning disable AA0074
        VATClausesCap: Label 'VAT Clause';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        VALVATBase_Control80CaptionLbl: Label 'Continued';
        VALVATBase_Control83CaptionLbl: Label 'Total';
        VALVATAmountLCY_Control105CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control106CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control107CaptionLbl: Label 'VAT %';
        VALVATBaseLCYCaptionLbl: Label 'Continued';
        VALVATBaseLCY_Control109CaptionLbl: Label 'Continued';
        VALVATBaseLCY_Control112CaptionLbl: Label 'Total';
        CACCaptionLbl: Text;
        CACTxt: Label 'Régimen especial del criterio de caja', Locked = true;
#pragma warning restore AA0074
        ContactPhoneNoLbl: Label 'Contact Phone No.';
        ContactMobilePhoneNoLbl: Label 'Contact Mobile Phone No.';
        ContactEmailLbl: Label 'Contact E-Mail';
        AmtDueTxt: Text;
        GreetingTxt: Text;
        BodyTxt: Text;
        ClosingTxt: Text;
        DescriptionTxt: Text;
        RemainingAmt: Text;
        ReportParametersInitialized: Boolean;

    protected var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        CompanyInfo: Record "Company Information";
        ReferenceText: Text[35];
        VATNoText: Text[30];
        EndLineNo: Integer;
        LogInteraction: Boolean;
        ShowInternalInfo: Boolean;
        ShowNotDueAmounts: Boolean;
        ShowMIRLines: Boolean;
        Interest: Decimal;
        NNC_InterestAmount: Decimal;
        NNC_InterestAmountTotal: Decimal;
        NNC_RemainingAmountTotal: Decimal;
        NNC_Total: Decimal;
        NNC_TotalInclVAT: Decimal;
        NNC_VATAmount: Decimal;
        NNC_VATAmountTotal: Decimal;
        TotalRemAmt: Decimal;
        TotalText: Text[50];
        TotalInclVATText: Text[50];

    [Scope('OnPrem')]
    procedure ShowCashAccountingCriteria(IssuedReminderHeader: Record "Issued Reminder Header"): Text
    var
        VATEntry: Record "VAT Entry";
    begin
        GLSetup.Get();
        if not GLSetup."Unrealized VAT" then
            exit;
        CACCaptionLbl := '';
        VATEntry.SetRange("Document No.", IssuedReminderHeader."No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Reminder);
        if VATEntry.FindSet() then
            repeat
                if VATEntry."VAT Cash Regime" then
                    CACCaptionLbl := CACTxt;
            until (VATEntry.Next() = 0) or (CACCaptionLbl <> '');
        exit(CACCaptionLbl);
    end;

    protected procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLetterTextOnPreDataItemOnAfterSetAmtDueTxt(var IssuedReminderHeader: Record "Issued Reminder Header"; var AmtDueTxt: Text; var GreetingTxt: Text; var BodyTxt: Text; var ClosingTxt: Text; var DescriptionTxt: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterResetAmounts(var VATInterest: Decimal; var AddFeeInclVAT: Decimal; var AddFeePerLineInclVAT: Decimal)
    begin
    end;
}

