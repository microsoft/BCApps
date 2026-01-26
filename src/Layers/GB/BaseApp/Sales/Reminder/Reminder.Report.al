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
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
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
            column(No_IssuedReminderHeader; "No.")
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
#if not CLEAN28
            column(ShowMIRLines; ShowMIRLines)
            {
            }
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
            }
#else
            column(VATAmountCaption; VATAmountCaptionLbl)
            {
            }
            column(VATBaseCaption; VATBaseCaptionLbl)
            {
            }
            column(VATPercentCaption; VATPercentCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(DocDateCaption; DocDateCaptionLbl)
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EMailCaption; EMailCaptionLbl)
            {
            }
            column(ShowMIRLines; ShowMIRLines)
            {
            }
#endif
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
#if not CLEAN28
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
#else
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
#endif
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
#if not CLEAN28
                column(DueDate_IssuedReminderHeader; Format("Issued Reminder Header"."Due Date"))
                {
                }
                column(PostingDate_IssuedReminderHeader; Format("Issued Reminder Header"."Posting Date"))
                {
                }
                column(YourRef_IssuedReminderHeader; "Issued Reminder Header"."Your Reference")
                {
                }
#else
                column(DueDate_IssuedReminderHdr; Format("Issued Reminder Header"."Due Date"))
                {
                }
                column(PostDate_IssuedReminderHdr; Format("Issued Reminder Header"."Posting Date"))
                {
                }
                column(No1_IssuedReminderHdr; "Issued Reminder Header"."No.")
                {
                }
                column(YourRef_IssueReminderHdr; "Issued Reminder Header"."Your Reference")
                {
                }
#endif
                column(Contact_IssuedReminderHdr; "Issued Reminder Header".Contact)
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
#if not CLEAN28
                column(VATRegNo_IssuedReminderHeader; "Issued Reminder Header".GetCustomerVATRegistrationNumber())
                {
                }
#else
                column(VatRegNo_IssueReminderHdr; "Issued Reminder Header".GetCustomerVATRegistrationNumber())
                {
                }
#endif
                column(VATNoText; VATNoText)
                {
                }
#if not CLEAN28
                column(DocDate_IssuedReminderHeader; Format("Issued Reminder Header"."Document Date"))
                {
                }
                column(CustNo_IssuedReminderHeader; "Issued Reminder Header"."Customer No.")
                {
                }
                column(CompanyInfoBankAccountNo; CompanyBankAccount."Bank Account No.")
                {
                }
#else
                column(DocDate_IssueReminderHdr; Format("Issued Reminder Header"."Document Date"))
                {
                }
                column(CustNo_IssueReminderHdr; "Issued Reminder Header"."Customer No.")
                {
                }
                column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                {
                }
#endif
                column(CompanyInfoIBAN; CompanyBankAccount.IBAN)
                {
                }
                column(CompanyInfoBankName; CompanyBankAccount.Name)
                {
                }
#if CLEAN28
                column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                {
                }
#endif
                column(CompanyInfoVATRegNo; CompanyInfo.GetVATRegistrationNumber())
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
                {
                }
#if not CLEAN28
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
#else
                column(CompanyInfoEMail; CompanyInfo."E-Mail")
                {
                }
#endif
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CompanyAddr8; CompanyAddr[8])
                {
                }
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                {
                }
                column(CustAddr7; CustAddr[7])
                {
                }
                column(CompanyAddr7; CompanyAddr[7])
                {
                }
                column(CustAddr6; CustAddr[6])
                {
                }
                column(CompanyAddr6; CompanyAddr[6])
                {
                }
                column(CustAddr5; CustAddr[5])
                {
                }
                column(CompanyAddr5; CompanyAddr[5])
                {
                }
                column(CustAddr4; CustAddr[4])
                {
                }
                column(CompanyAddr4; CompanyAddr[4])
                {
                }
                column(CustAddr3; CustAddr[3])
                {
                }
                column(CompanyAddr3; CompanyAddr[3])
                {
                }
                column(CustAddr2; CustAddr[2])
                {
                }
                column(CompanyAddr2; CompanyAddr[2])
                {
                }
                column(CustAddr1; CustAddr[1])
                {
                }
                column(CompanyAddr1; CompanyAddr[1])
                {
                }
#if not CLEAN28
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(CompanyInfoBankBranchNo; CompanyInfo."Bank Branch No.")
                {
                }
#else
                column(TextPage; TextPageLbl)
                {
                }
#endif
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(ReminderNoCaption; ReminderNoCaptionLbl)
                {
                }
#if not CLEAN28
                column(BankAccountNoCaption; BankAccountNoCaptionLbl)
                {
                }
#else
                column(BankAccNoCaption; BankAccNoCaptionLbl)
                {
                }
#endif
                column(IBANCaption; IBANCaptionLbl)
                {
                }
                column(BankNameCaption; BankNameCaptionLbl)
                {
                }
#if not CLEAN28
                column(VATRegNoCaption; "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl())
                {
                }
                column(EmailCaption; EmailCaptionLbl)
                {
                }
                column(HomePageCaption; HomePageCaptionLbl)
                {
                }
#else
                column(GiroNoCaption; GiroNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl())
                {
                }
#endif
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
                column(ReminderCaption; ReminderCaptionLbl)
                {
                }
#if not CLEAN28
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl())
                {
                }
                column(BankBranchNoCaption; BankBranchNoCaptionLbl)
                {
                }
                column(CustNo_IssuedReminderHeaderCaption; "Issued Reminder Header".FieldCaption("Customer No."))
                {
                }
#else
                column(CustNo_IssueReminderHdrCaption; "Issued Reminder Header".FieldCaption("Customer No."))
                {
                }
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl())
                {
                }
#endif
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number_IntegerLine; Number)
                    {
                    }
                    column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
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
                    column(RemAmt_IssuedReminderLine; "Remaining Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(Desc_IssuedReminderLine; Description)
                    {
                    }
                    column(Type_IssuedReminderLine; Format(Type, 0, 2))
                    {
                    }
                    column(DocDate_IssuedReminderLine; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuedReminderLine; "Document No.")
                    {
                    }
                    column(DocNoCaption_IssuedReminderLine; FieldCaption("Document No."))
                    {
                    }
                    column(DueDate_IssuedReminderLine; Format("Due Date"))
                    {
                    }
#if not CLEAN28
                    column(OrgAmt_IssuedReminderLine; "Original Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
#else
                    column(OriginalAmt_IssuedReminderLine; "Original Amount")
                    {
                        AutoFormatExpression = GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
#endif
                    column(DocType_IssuedReminderLine; "Document Type")
                    {
                    }
#if not CLEAN28
                    column(No_IssuedReminderLine; "No.")
                    {
                    }
#else
                    column(LineNo_IssuedReminderLine; "No.")
                    {
                    }
#endif
                    column(ShowInternalInfo; ShowInternalInfo)
                    {
                    }
#if not CLEAN28
                    column(VATAmtIssRemHdrAddFeeInclVAT; (TotalRemIntAmount + "VAT Amount" + "Issued Reminder Header"."Additional Fee" - AddFeeInclVAT) / (VATInterest / 100 + 1))
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(NNCInterestAmount; NNC_InterestAmount)
                    {
                    }
                    column(TotalRemIntAmount; TotalRemIntAmount)
                    {
                    }
#else
                    column(NNCInterestAmt; NNC_InterestAmount)
                    {
                    }
#endif
                    column(TotalText; TotalText)
                    {
                    }
                    column(MIREntry_IssuedReminderLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(NNCTotal; NNC_Total)
                    {
                    }
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
#if not CLEAN28
                    column(NNCVATAmount; NNC_VATAmount)
                    {
                    }
#else
                    column(NNCVATAmt; NNC_VATAmount)
                    {
                    }
#endif
                    column(NNCTotalInclVAT; NNC_TotalInclVAT)
                    {
                    }
                    column(TotalVATAmt; TotalVATAmount)
                    {
                    }
#if not CLEAN28
                    column(Rem_IssuedReminderLine; "Reminder No.")
                    {
                    }
                    column(InterestAmountCaption; InterestAmountCaptionLbl)
                    {
                    }
                    column(VATAmountCaption; VATAmountCaptionLbl)
                    {
                    }
#else
                    column(RemNo_IssuedReminderLine; "Reminder No.")
                    {
                    }
                    column(DocumentDateCaption1; DocumentDateCaption1Lbl)
                    {
                    }
                    column(InterestAmountCaption; InterestAmountCaptionLbl)
                    {
                    }
#endif
                    column(RemAmt_IssuedReminderLineCaption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(DocNo_IssuedReminderLineCaption; FieldCaption("Document No."))
                    {
                    }
#if not CLEAN28
                    column(OrgAmt_IssuedReminderLineCaption; FieldCaption("Original Amount"))
                    {
                    }
#else
                    column(OriginalAmt_IssuedReminderLineCaption; FieldCaption("Original Amount"))
                    {
                    }
#endif
                    column(DocType_IssuedReminderLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(Interest; Interest)
                    {
                    }
                    column(RemainingAmountText; RemainingAmt)
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
                        Clear(CompanyInfo1.Picture);
                        Clear(CompanyInfo2.Picture);
                        Clear(CompanyInfo3.Picture);

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
#if not CLEAN28
                    column(Desc2_IssuedReminderLine; Description)
                    {
                    }
                    column(LineNo2_IssuedReminderLine; "Line No.")
                    {
                    }
#else
                    column(Desc1_IssuedReminderLine; Description)
                    {
                    }
                    column(LineNo1_IssuedReminderLine; "Line No.")
                    {
                    }
#endif

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
#if not CLEAN28
                    column(VATAmtLineAmtInclVAT; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
#else
                    column(VATAmtLineAmtIncludVAT; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
#endif
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
#if not CLEAN28
                    column(VALVATBaseVALVATAmount; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                    {
                    }
                    column(AmountIncludingVATCaption; AmountIncludingVATCaptionLbl)
                    {
                    }
                    column(VATAmountCaption1; VATAmountCaption1Lbl)
                    {
                    }
                    column(VATBaseCaption; VATBaseCaptionLbl)
                    {
                    }
                    column(VATPercentCaption; VATPercentCaptionLbl)
                    {
                    }
                    column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                    {
                    }
#else
                    column(VALVATBaseVALVATAmt; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                    {
                    }
                    column(AmountIncVATCaption; AmountIncVATCaptionLbl)
                    {
                    }
                    column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
                    {
                    }
#endif
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
#if not CLEAN28
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
#endif

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
                    column(VATClauseVATIdentifierCaption; VATIdentifierLbl)
                    {
                    }
                    column(VATClauseVATAmtCaption; VATAmountCaptionLbl)
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
#if not CLEAN28
                    column(VATAmtLineVAT1; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmountCaption2; VATAmountCaption2Lbl)
                    {
                    }
                    column(VATBase1Caption; VATBase1CaptionLbl)
                    {
                    }
                    column(VATPercentCaption1; VATPercentCaption1Lbl)
                    {
                    }
#else
                    column(VATAmtLineVATCtrl107; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
#endif
                    column(ContinuedCaption1; ContinuedCaption1Lbl)
                    {
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
                            VALExchRate := StrSubstNo(Text013, Round(1 / CurrFactor * 100, 0.000001), CurrExchRate."Exchange Rate Amount");
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
#if not CLEAN28
                    column(TotalCaption1; TotalCaption1Lbl)
                    {
                    }
#endif

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
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
#if not CLEAN28
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
#else
                SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
#endif
        end;

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
        SalesSetup: Record "Sales & Receivables Setup";
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
#if not CLEAN28
        TotalRemIntAmount: Decimal;
#endif
        LogInteractionEnable: Boolean;
#if not CLEAN28
        DueDateCaptionLbl: Label 'Due Date';
        DocumentDateCaptionLbl: Label 'Document Date';
        PageCaptionLbl: Label 'Page';
#else
        TextPageLbl: Label 'Page';
#endif
        PostingDateCaptionLbl: Label 'Posting Date';
        ReminderNoCaptionLbl: Label 'Reminder No.';
#if not CLEAN28
        BankAccountNoCaptionLbl: Label 'Account No.';
#else
        BankAccNoCaptionLbl: Label 'Account No.';
#endif
        IBANCaptionLbl: Label 'IBAN';
        BankNameCaptionLbl: Label 'Bank';
#if not CLEAN28
        EmailCaptionLbl: Label 'E-Mail';
        HomePageCaptionLbl: Label 'Home Page';
#else
        GiroNoCaptionLbl: Label 'Giro No.';
#endif
        PhoneNoCaptionLbl: Label 'Phone No.';
        ReminderCaptionLbl: Label 'Reminder';
#if not CLEAN28
        BankBranchNoCaptionLbl: Label 'Bank Branch No.';
#endif
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
#if CLEAN28
        DocumentDateCaption1Lbl: Label 'Document Date';
#endif
        InterestAmountCaptionLbl: Label 'Interest Amount';
#if not CLEAN28
        VATAmountCaptionLbl: Label 'VAT Amount';
        AmountIncludingVATCaptionLbl: Label 'Amount Including VAT';
        VATAmountCaption1Lbl: Label 'VAT Amount';
#else
        AmountIncVATCaptionLbl: Label 'Amount Including VAT';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
#endif
#pragma warning disable AA0074
        VATClausesCap: Label 'VAT Clause';
#pragma warning restore AA0074
        VATIdentifierLbl: Label 'VAT Identifier';
#if CLEAN28
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption1Lbl: Label 'Continued';
        DueDateCaptionLbl: Label 'Due Date';
        VATAmountCaptionLbl: Label 'VAT Amount';
#endif
        VATBaseCaptionLbl: Label 'VAT Base';
        VATPercentCaptionLbl: Label 'VAT %';
#if not CLEAN28
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        ContinuedCaptionLbl: Label 'Continued';
#endif
        TotalCaptionLbl: Label 'Total';
#if CLEAN28
        PageCaptionLbl: Label 'Page';
        DocDateCaptionLbl: Label 'Document Date';
        HomePageCaptionLbl: Label 'Home Page';
        EMailCaptionLbl: Label 'Email';
#endif
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
#if not CLEAN28
        VATAmountCaption2Lbl: Label 'VAT Amount';
        VATBase1CaptionLbl: Label 'VAT Base';
        VATPercentCaption1Lbl: Label 'VAT %';
        ContinuedCaption1Lbl: Label 'Continued';
        TotalCaption1Lbl: Label 'Total';
#endif

    protected var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
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

