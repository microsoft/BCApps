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
            column(RemLineDocumentDateCaption; RemLineDocumentDateCaptionLbl)
            {
            }
            column(VatAmtCaption; VatAmtCaptionLbl)
            {
            }
            column(VatBaseCaption; VatBaseCaptionLbl)
            {
            }
            column(Vatpercentcaption; VatpercentcaptionLbl)
            {
            }
            column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
            {
            }
            column(CompanyInfoEmailIdCaption; CompanyInfoEmailIdCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
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
                column(DueDate_IssuedRemHdr; Format("Issued Reminder Header"."Due Date"))
                {
                }
                column(PostingDate_IssuedRemHdr; Format("Issued Reminder Header"."Posting Date"))
                {
                }
                column(No1_IssuedReminderHeader; "Issued Reminder Header"."No.")
                {
                }
                column(YourRef_IssuedRemHdr; "Issued Reminder Header"."Your Reference")
                {
                }
                column(Contact_IssuedReminderHdr; "Issued Reminder Header".Contact)
                {
                }
                column(ReferenceText; ReferenceText)
                {
                }
                column(VATRegsNo_IssuedRemHdr; "Issued Reminder Header".GetCustomerVATRegistrationNumber())
                {
                }
                column(VATNoText; VATNoText)
                {
                }
                column(DocumentDate_IssuedRemHrd; Format("Issued Reminder Header"."Document Date"))
                {
                }
                column(CustomerNo_IssuedRemHrd; "Issued Reminder Header"."Customer No.")
                {
                }
                column(CustomerNo_IssuedRemHrdCaption; "Issued Reminder Header".FieldCaption("Customer No."))
                {
                }
                column(CompanyInfoAccountNo; CompanyBankAccount."Bank Account No.")
                {
                }
                column(CompanyInfoIBAN; CompanyBankAccount.IBAN)
                {
                }
                column(CompanyInfoBankName; CompanyBankAccount.Name)
                {
                }
                column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
                {
                }
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
                column(CompanyInfoVATRegsNo; CompanyInfo.GetVATRegistrationNumber())
                {
                }
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
                column(TextPage; TextPageLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(ReminderNoCaption; ReminderNoCaptionLbl)
                {
                }
                column(BankAccountNoCaption; BankAccountNoCaptionLbl)
                {
                }
                column(IBANCaption; IBANCaptionLbl)
                {
                }
                column(BankNameCaption; BankNameCaptionLbl)
                {
                }
                column(GiroNoCaption; GiroNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; "Issued Reminder Header".GetCustomerVATRegistrationNumberLbl())
                {
                }
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
                column(ReminderCaption; ReminderCaptionLbl)
                {
                }
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl())
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Reminder Header";
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; DimensionLoop.Number)
                    {
                    }
                    column(HeaderDimCaption; HeaderDimCaptionLbl)
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
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(RemAmt_IssuedReminderLineCaption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Desc_IssuedReminderLine; Description)
                    {
                    }
                    column(Type_IssuedReminderLine; Format(Type, 0, 2))
                    {
                    }
                    column(DocDate_IssuedRemLine; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuedReminderLine; "Document No.")
                    {
                    }
                    column(DocNo_IssuedReminderLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(DueDate_IssuedReminderLine; Format("Due Date"))
                    {
                    }
                    column(OriginalAmt_IssuedRemLine; "Original Amount")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(OriginalAmt_IssuedRemLineCaption; FieldCaption("Original Amount"))
                    {
                    }
                    column(DocType_IssuedReminderLine; "Document Type")
                    {
                    }
                    column(DocType_IssuedReminderLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(No_IssuedReminderLine; "No.")
                    {
                    }
                    column(ShowInterInfo_IssuRemLine; ShowInternalInfo)
                    {
                    }
                    column(InterestAmt_IssuRemLine; NNC_InterestAmount)
                    {
                    }
                    column(TotText_IssuedRemLine; TotalText)
                    {
                    }
                    column(MIREntry_IssuedReminderLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(NNCTotal_IssuedRemLine; NNC_Total)
                    {
                    }
                    column(InclVATText_IssuedRemLine; TotalInclVATText)
                    {
                    }
                    column(VATAmt_IssuedRemLine; NNC_VATAmount)
                    {
                    }
                    column(TotInclVAT_IssuedRemLine; NNC_TotalInclVAT)
                    {
                    }
                    column(TotalVATAmt; TotalVATAmount)
                    {
                    }
                    column(RemNo_IssuedReminderLine; "Reminder No.")
                    {
                    }
                    column(ContinuedCaption; ContinuedCaptionLbl)
                    {
                    }
                    column(InterestAmountcaption; InterestAmountcaptionLbl)
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
                    column(Desc2_IssuedReminderLine; Description)
                    {
                    }
                    column(LineNo_IssuedReminderLine; "Line No.")
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
                    column(AmtIncludVAT_VATAmtLine; TempVATAmountLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATAmt; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseVALVATAmt; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Reminder Line".GetCurrencyCodeFromHeader();
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                    {
                    }
                    column(AmountInclVATCaption; AmountInclVATCaptionLbl)
                    {
                    }
                    column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
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
                dataitem(VATCounterLCY; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(VALExchRate; VALExchRate)
                    {
                    }
                    column(VALSpecLCYHdr; VALSpecLCYHeader)
                    {
                    }
                    column(VALVATAmtLCY; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VALVATBaseLCY; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATCounter; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
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
        CompanyInfo.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
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
        LogInteractionEnable: Boolean;
        DueDateCaptionLbl: Label 'Due Date';
        RemLineDocumentDateCaptionLbl: Label 'Document Date';
        TextPageLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        ReminderNoCaptionLbl: Label 'Reminder No.';
        BankAccountNoCaptionLbl: Label 'Account No.';
        IBANCaptionLbl: Label 'IBAN';
        BankNameCaptionLbl: Label 'Bank';
        GiroNoCaptionLbl: Label 'Giro No.';
        PhoneNoCaptionLbl: Label 'Phone No.';
        ReminderCaptionLbl: Label 'Reminder';
        HeaderDimCaptionLbl: Label 'Header Dimensions';
        ContinuedCaptionLbl: Label 'Continued';
        InterestAmountcaptionLbl: Label 'Interest Amount';
        AmountInclVATCaptionLbl: Label 'Amount Including VAT';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        TotalCaptionLbl: Label 'Total';
        VatAmtCaptionLbl: Label 'VAT Amount';
        VatBaseCaptionLbl: Label 'VAT Base';
        VatpercentcaptionLbl: Label 'VAT %';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoEmailIdCaptionLbl: Label 'E-Mail';
        PageCaptionLbl: Label 'Page';
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

