// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
#if not CLEAN28
using Microsoft.Finance.GeneralLedger.Account;
#endif
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
#if not CLEAN28
using Microsoft.Finance.VAT.Setup;
#endif
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Email;
using System.Globalization;
using System.Utilities;

report 118 "Finance Charge Memo"
{
    DefaultLayout = RDLC;
#if not CLEAN28
    RDLCLayout = './Sales/FinanceCharge/FinanceChargeMemoGB.rdlc';
#else
    RDLCLayout = './Sales/FinanceCharge/FinanceChargeMemo.rdlc';
#endif
    Caption = 'Finance Charge Memo';
    WordMergeDataItem = "Issued Fin. Charge Memo Header";

    dataset
    {
        dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';
#if not CLEAN28
            column(No_IssuedFinChrgMemoHeader; "No.")
            {
            }
#else
            column(No_IssuedFinChgMemo; "No.")
            {
            }
#endif
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(VATAmtCaption; VATAmtCaptionLbl)
            {
            }
            column(VATBaseCaption; VATBaseCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
#if CLEAN28
            column(DoctDateCaption; DoctDateCaptionLbl)
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EMailCaption; EMailCaptionLbl)
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
                column(CompanyInfoPicture; CompanyInfo3.Picture)
                {
                }
#else
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
#endif
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
#if not CLEAN28
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(PstDate_IssuedFinChrgMemoHeader; Format("Issued Fin. Charge Memo Header"."Posting Date"))
                {
                }
                column(DueDate_IssuedFinChrgMemoHeader; Format("Issued Fin. Charge Memo Header"."Due Date"))
                {
                }
                column(DocDate_IssuedFinChrgMemoHeader; Format("Issued Fin. Charge Memo Header"."Document Date"))
                {
                }
                column(YourRef_IssuedFinChrgMemoHeader; "Issued Fin. Charge Memo Header"."Your Reference")
                {
                }
#else
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
                column(PostDt_IssuFinChrgMemoHr; Format("Issued Fin. Charge Memo Header"."Posting Date"))
                {
                }
                column(DueDt_IssuFinChrgMemoHr; Format("Issued Fin. Charge Memo Header"."Due Date"))
                {
                }
                column(No1_IssuFinChrgMemoHr; "Issued Fin. Charge Memo Header"."No.")
                {
                }
                column(DocDt_IssuFinChrgMemoHr; Format("Issued Fin. Charge Memo Header"."Document Date"))
                {
                }
                column(YourRef_IssuFinChrgMemoHr; "Issued Fin. Charge Memo Header"."Your Reference")
                {
                }
#endif
                column(ReferenceText; ReferenceText)
                {
                }
#if not CLEAN28
                column(VATRegNo_IssuedFinChrgMemoHeader; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumber())
                {
                }
#else
                column(VatRNo_IssuFinChrgMemoHr; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumber())
                {
                }
#endif
                column(VATNoText; VATNoText)
                {
                }
#if not CLEAN28
                column(CompanyInfoBankAccountNo; CompanyBankAccount."Bank Account No.")
                {
                }
#else
                column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                {
                }
#endif
                column(CompanyInfoIBAN; CompanyBankAccount.IBAN)
                {
                }
#if not CLEAN28
                column(CustNo_IssuedFinChrgMemoHeader; "Issued Fin. Charge Memo Header"."Customer No.")
                {
                }
#else
                column(CustNo_IssuFinChrgMemoHr; "Issued Fin. Charge Memo Header"."Customer No.")
                {
                }
                column(CustNo_IssuFinChrgMemoHrCaption; "Issued Fin. Charge Memo Header".FieldCaption("Customer No."))
                {
                }
#endif
                column(CompanyInfoBankName; CompanyBankAccount.Name)
                {
                }
#if not CLEAN28
                column(CompanyInfoVATRegNo; CompanyInfo.GetVATRegistrationNumber())
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
#else
                column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                {
                }
                column(CompanyInfoVatRegNo; CompanyInfo.GetVATRegistrationNumber())
                {
                }
#endif
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
                {
                }
#if CLEAN28
                column(CompanyInfoEMail; CompanyInfo."E-Mail")
                {
                }
#endif
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                {
                }
                column(CustAddr7; CustAddr[7])
                {
                }
                column(CustAddr6; CustAddr[6])
                {
                }
#if not CLEAN28
                column(CompanyAddr8; CompanyAddr[8])
                {
                }
                column(CompanyAddr7; CompanyAddr[7])
                {
                }
#else
                column(CompanyAddr7; CompanyAddr[7])
                {
                }
                column(CompanyAddr8; CompanyAddr[8])
                {
                }
#endif
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
                column(PageCaption; StrSubstNo(Text002, ''))
                {
                }
#if not CLEAN28
                column(CompanyInfoBankBranchNo; CompanyInfo."Bank Branch No.")
                {
                }
#endif
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(FinChrgMemoNoCaption; FinChrgMemoNoCaptionLbl)
                {
                }
                column(BankAccNoCaption; BankAccNoCaptionLbl)
                {
                }
                column(IBANCaption; IBANCaptionLbl)
                {
                }
                column(BankNameCaption; BankNameCaptionLbl)
                {
                }
#if not CLEAN28
                column(VATRegNoCaption; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumberLbl())
                {
                }
                column(DocDateCaption; DocDateCaptionLbl)
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
                column(VATRegNoCaption; "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumberLbl())
                {
                }
#endif
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
#if not CLEAN28
                column(FinChrgMemoCaption; FinChrgMemoCaptionLbl)
                {
                }
                column(BankBranchNoCaption; BankBranchNoCaptionLbl)
                {
                }
                column(CustNo_IssuedFinChrgMemoHeaderCaption; "Issued Fin. Charge Memo Header".FieldCaption("Customer No."))
                {
                }
#else
                column(FinChgMemoCaption; FinChgMemoCaptionLbl)
                {
                }
#endif
                column(CompanyVATRegistrationNoCaption; CompanyInfo.GetVATRegistrationNumberLbl())
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
#if not CLEAN28
                    column(Number_IntegerLine; DimensionLoop.Number)
                    {
                    }
                    column(HdrDimsCaption; HdrDimsCaptionLbl)
                    {
                    }
#else
                    column(Number_DimLoop; Number)
                    {
                    }
                    column(HdrDimCaption; HdrDimCaptionLbl)
                    {
                    }
#endif

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
                dataitem("Issued Fin. Charge Memo Line"; "Issued Fin. Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = field("No.");
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = sorting("Finance Charge Memo No.", "Line No.");
                    column(LineNo_IssuFinChrgMemoLine; "Line No.")
                    {
                    }
                    column(StartLineNo; StartLineNo)
                    {
                    }
                    column(TypeInt; TypeInt)
                    {
                    }
                    column(ShowInternalInfo; ShowInternalInfo)
                    {
                    }
#if not CLEAN28
                    column(LineAmt_IssuedFinChrgMemoLine; Amount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Desc_IssuedFinChrgMemoLine; Description)
                    {
                    }
                    column(DocDate_IssuedFinChrgMemoLine; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuedFinChrgMemoLine; "Document No.")
                    {
                    }
                    column(FormatDueDate_IssuedFinChrgMemoLine; Format("Due Date"))
                    {
                    }
                    column(DocType_IssuedFinChrgMemoLine; "Document Type")
                    {
                    }
                    column(MultInterestRatesEntry_IssuedFinChrgMemoLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(DueDate_IssuedFinChrgMemoLine; "Due Date")
                    {
                    }
                    column(No_IssuedFinChrgMemoLine; "No.")
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(VatAmount_IssuedFinChrgMemoLine; "VAT Amount")
                    {
                    }
                    column(TotalRemainingAmount; TotalRemainingAmount)
                    {
                    }
                    column(AddFeeInclVAT; AddFeeInclVAT)
                    {
                    }
                    column(VATInterest; VATInterest)
                    {
                    }
                    column(AddFee_IssuedFinChrgMemoHeader; "Issued Fin. Charge Memo Header"."Additional Fee")
                    {
                    }
                    column(AmtVATAmt_IssuedFinChrgMemoHeader; Amount + "VAT Amount")
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Line".GetCurrencyCode();
                        AutoFormatType = 1;
                    }
#else
                    column(Amt_IssuFinChrgMemoLine; Amount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Desc_IssuFinChrgMemoLine; Description)
                    {
                    }
                    column(DocDt_IssuFinChrgMemoLine; Format("Document Date"))
                    {
                    }
                    column(DocNo_IssuFinChrgMemoLine; "Document No.")
                    {
                    }
                    column(DueDt_IssuFinChrgMemoLine; Format("Due Date"))
                    {
                    }
                    column(DcType_IssuFinChrgMemoLine; "Document Type")
                    {
                    }
                    column(DocNo_IssuFinChrgMemoLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(Desc_IssuFinChrgMemoLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Amt_IssuFinChrgMemoLineCaption; FieldCaption(Amount))
                    {
                    }
                    column(DcType_IssuFinChrgMemoLineCaption; FieldCaption("Document Type"))
                    {
                    }
                    column(No_IssuedFinChgMemoLine; "No.")
                    {
                    }
                    column(TotalText; TotalText)
                    {
                    }
#endif
                    column(TotalInclVATText; TotalInclVATText)
                    {
                    }
                    column(VatAmt_IssuFinChrgMemoLine; "VAT Amount")
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(DocDateCaption1; DocDateCaption1Lbl)
                    {
                    }
                    column(TotalVatAmount; TotalVatAmount)
                    {
                    }
                    column(TotalAmount; TotalAmount)
                    {
                    }
                    column(MultiIntRateEntry_IssuFinChrgMemoLine; "Detailed Interest Rates Entry")
                    {
                    }
                    column(ShowMIRLines; ShowMIRLines)
                    {
                    }
#if not CLEAN28
                    column(LineAmt_IssuedFinChrgMemoLineCaption; FieldCaption(Amount))
                    {
                    }
                    column(Desc_IssuedFinChrgMemoLineCaption; FieldCaption(Description))
                    {
                    }
                    column(DocNo_IssuedFinChrgMemoLineCaption; FieldCaption("Document No."))
                    {
                    }
                    column(DocType_IssuedFinChrgMemoLineCaption; FieldCaption("Document Type"))
                    {
                    }
#endif

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

                            TotalAmount += Amount;
                            TotalVatAmount += "VAT Amount";
                        end;

                        TypeInt := Type;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Find('-') then begin
                            StartLineNo := 0;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description = '') then
                                    StartLineNo := "Line No.";
                            until (Next() = 0) or not Continue;
                        end;
                        if Find('+') then begin
                            EndLineNo := "Line No." + 1;
                            repeat
                                Continue := Type = Type::" ";
                                if Continue and (Description = '') then
                                    EndLineNo := "Line No.";
                            until (Next(-1) = 0) or not Continue;
                        end;

                        TempVATAmountLine.DeleteAll();
                        SetFilter("Line No.", '<%1', EndLineNo);
                        if not ShowMIRLines then
                            SetRange("Detailed Interest Rates Entry", false);

                        TotalAmount := 0;
                        TotalVatAmount := 0;
                    end;
                }
                dataitem(IssuedFinChrgMemoLine2; "Issued Fin. Charge Memo Line")
                {
                    DataItemLink = "Finance Charge Memo No." = field("No.");
                    DataItemLinkReference = "Issued Fin. Charge Memo Header";
                    DataItemTableView = sorting("Finance Charge Memo No.", "Line No.");
#if not CLEAN28
                    column(Desc_IssuedFinChrgMemoLine2; Description)
                    {
                    }
                    column(LineNo_IssuedFinChrgMemoLine2; IssuedFinChrgMemoLine2."Line No.")
                    {
                    }
#else
                    column(Desc2_IssuFinChrgMemoLine; Description)
                    {
                    }
                    column(LnNo_IssuFinChrgMemoLine2; "Line No.")
                    {
                    }
#endif

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Line No.", '>=%1', EndLineNo);
                    end;
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
#if not CLEAN28
                    column(VALVATBaseVALVATAmount; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VALVATAmount; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
#else
                    column(ValVatBaseValVatAmt; VALVATBase + VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(ValvataAmt; VALVATAmount)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
#endif
                    column(VALVATBase; VALVATBase)
                    {
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
#if not CLEAN28
                    column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                    {
                    }
                    column(AmtIncludingVATCaption; AmtIncludingVATCaptionLbl)
                    {
                    }
#else
                    column(VatAmtLineVAT; TempVATAmountLine."VAT %")
                    {
                    }
                    column(AmtInclVATCaption; AmtInclVATCaptionLbl)
                    {
                    }
#endif
                    column(VATPercentCaption; VATPercentCaptionLbl)
                    {
                    }
                    column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
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
                        SetRange(Number, 1, TempVATAmountLine.Count);
                        Clear(VALVATBase);
                        Clear(VALVATAmount);
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
                        AutoFormatExpression = "Issued Fin. Charge Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATClausesCaption; VATClausesCap)
                    {
                    }
                    column(VATClauseVATIdentifierCaption; VATIdentifierLbl)
                    {
                    }
                    column(VATClauseVATAmtCaption; VATAmtCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                        if not VATClause.Get(TempVATAmountLine."VAT Clause Code") then
                            CurrReport.Skip();
                        VATClauseText := VATClause.GetDescriptionText("Issued Fin. Charge Memo Header");
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
#if not CLEAN28
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
                    column(VATAmountLineVATLCY; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
#else
                    column(ValExchRate; VALExchRate)
                    {
                    }
                    column(ValspecLCYHdr; VALSpecLCYHeader)
                    {
                    }
                    column(ValvatamountLCY; VALVATAmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(ValvataBaseLCY; VALVATBaseLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(VatAmtLnVat1; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
#endif
                    column(VATPercentCaption1; VATPercentCaption1Lbl)
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
                           ("Issued Fin. Charge Memo Header"."Currency Code" = '') or
                           (TempVATAmountLine.GetTotalVATAmount() = 0)
                        then
                            CurrReport.Break();

                        SetRange(Number, 1, TempVATAmountLine.Count);
                        Clear(VALVATBaseLCY);
                        Clear(VALVATAmountLCY);

                        if GLSetup."LCY Code" = '' then
                            VALSpecLCYHeader := Text007 + Text008
                        else
                            VALSpecLCYHeader := Text007 + Format(GLSetup."LCY Code");

                        CurrExchRate.FindCurrency("Issued Fin. Charge Memo Header"."Posting Date", "Issued Fin. Charge Memo Header"."Currency Code", 1);
#if not CLEAN28
                        CustEntry.SetRange("Customer No.", "Issued Fin. Charge Memo Header"."Customer No.");
                        CustEntry.SetRange("Document Type", CustEntry."Document Type"::"Finance Charge Memo");
                        CustEntry.SetRange("Document No.", "Issued Fin. Charge Memo Header"."No.");
                        if CustEntry.FindFirst() then begin
                            CustEntry.CalcFields("Amount (LCY)", Amount);
                            CurrFactor := 1 / (CustEntry."Amount (LCY)" / CustEntry.Amount);
#else
                        CustLedgerEntry.SetRange("Customer No.", "Issued Fin. Charge Memo Header"."Customer No.");
                        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Finance Charge Memo");
                        CustLedgerEntry.SetRange("Document No.", "Issued Fin. Charge Memo Header"."No.");
                        if CustLedgerEntry.FindFirst() then begin
                            CustLedgerEntry.CalcFields("Amount (LCY)", Amount);
                            CurrFactor := 1 / (CustLedgerEntry."Amount (LCY)" / CustLedgerEntry.Amount);
#endif
                            VALExchRate := StrSubstNo(Text009, Round(1 / CurrFactor * 100, 0.000001), CurrExchRate."Exchange Rate Amount");
                        end else begin
                            CurrFactor := CurrExchRate.ExchangeRate("Issued Fin. Charge Memo Header"."Posting Date",
                                "Issued Fin. Charge Memo Header"."Currency Code");
                            VALExchRate := StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
#if not CLEAN28
            var
                GLAcc: Record "G/L Account";
                CustPostingGroup: Record "Customer Posting Group";
                VATPostingSetup: Record "VAT Posting Setup";
#endif
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");
                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");

                if not CompanyBankAccount.Get("Issued Fin. Charge Memo Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                FormatAddr.IssuedFinanceChargeMemo(CustAddr, "Issued Fin. Charge Memo Header");
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumber() = '' then
                    VATNoText := ''
                else
                    VATNoText := "Issued Fin. Charge Memo Header".GetCustomerVATRegistrationNumberLbl();

                Customer.GetPrimaryContact("Customer No.", PrimaryContact);
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

#if not CLEAN28
                CalcFields("Additional Fee");
                CustPostingGroup.Get("Customer Posting Group");
                if GLAcc.Get(CustPostingGroup."Additional Fee Account") then begin
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    AddFeeInclVAT := "Additional Fee" * (1 + VATPostingSetup."VAT %" / 100);
                end else
                    AddFeeInclVAT := "Additional Fee";

                GLAcc.Get(CustPostingGroup."Interest Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                VATInterest := VATPostingSetup."VAT %";
#endif
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
                    field(ShowInternalInformation; ShowInternalInfo)
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
                        ToolTip = 'Specifies if you want the program to record the finance charge memos you print as interactions, and add them to the Interaction Log Entry table.';
                    }
                    field(ShowMIR; ShowMIRLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show MIR Detail';
                        ToolTip = 'Specifies if you want the printed report to show multiple interest rate detail.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
        end;
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
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Issued Fin. Charge Memo Header".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      19, "Issued Fin. Charge Memo Header"."No.", 0, 0, DATABASE::Customer,
                      "Issued Fin. Charge Memo Header"."Customer No.", '', '', "Issued Fin. Charge Memo Header"."Posting Description", '');

                until "Issued Fin. Charge Memo Header".Next() = 0;
    end;

    var
        PrimaryContact: Record Contact;
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        CompanyBankAccount: Record "Bank Account";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        DimSetEntry: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
#if not CLEAN28
        CustEntry: Record "Cust. Ledger Entry";
#else
        CustLedgerEntry: Record "Cust. Ledger Entry";
#endif
        SalesSetup: Record "Sales & Receivables Setup";
        LanguageMgt: Codeunit Language;
        SegManagement: Codeunit SegManagement;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        VATNoText: Text[30];
        ReferenceText: Text[35];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        StartLineNo: Integer;
        EndLineNo: Integer;
        TypeInt: Integer;
        Continue: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        CurrFactor: Decimal;
#if not CLEAN28
        AddFeeInclVAT: Decimal;
        VATInterest: Decimal;
#endif
        VALVATBase: Decimal;
        VALVATAmount: Decimal;
#if not CLEAN28
        TotalRemainingAmount: Decimal;
#endif
        VATClauseText: Text;
        LogInteractionEnable: Boolean;
        TotalAmount: Decimal;
        TotalVatAmount: Decimal;
        ShowMIRLines: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Total %1';
        Text001: Label 'Total %1 Incl. VAT';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
#pragma warning disable AA0470
        Text009: Label 'Exchange rate: %1/%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PostingDateCaptionLbl: Label 'Posting Date';
        FinChrgMemoNoCaptionLbl: Label 'Finance Charge Memo No.';
        BankAccNoCaptionLbl: Label 'Account No.';
        IBANCaptionLbl: Label 'IBAN';
        BankNameCaptionLbl: Label 'Bank';
#if CLEAN28
        GiroNoCaptionLbl: Label 'Giro No.';
#endif
        PhoneNoCaptionLbl: Label 'Phone No.';
#if not CLEAN28
        FinChrgMemoCaptionLbl: Label 'Finance Charge Memo';
        BankBranchNoCaptionLbl: Label 'Bank Branch No.';
        HdrDimsCaptionLbl: Label 'Header Dimensions';
#else
        FinChgMemoCaptionLbl: Label 'Finance Charge Memo';
        HdrDimCaptionLbl: Label 'Header Dimensions';
#endif
        DocDateCaption1Lbl: Label 'Document Date';
#if not CLEAN28
        AmtIncludingVATCaptionLbl: Label 'Amount Including VAT';
#else
        AmtInclVATCaptionLbl: Label 'Amount Including VAT';
#endif
        VATPercentCaptionLbl: Label 'VAT %';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATPercentCaption1Lbl: Label 'VAT %';
#pragma warning disable AA0074
        VATClausesCap: Label 'VAT Clause';
#pragma warning restore AA0074
        VATIdentifierLbl: Label 'VAT Identifier';
        DueDateCaptionLbl: Label 'Due Date';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATBaseCaptionLbl: Label 'VAT Base';
        TotalCaptionLbl: Label 'Total';
#if not CLEAN28
        DocDateCaptionLbl: Label 'Document Date';
        EmailCaptionLbl: Label 'E-Mail';
#else
        DoctDateCaptionLbl: Label 'Document Date';
#endif
        HomePageCaptionLbl: Label 'Home Page';
#if CLEAN28
        EMailCaptionLbl: Label 'Email';
#endif
        ContactPhoneNoLbl: Label 'Contact Phone No.';
        ContactMobilePhoneNoLbl: Label 'Contact Mobile Phone No.';
        ContactEmailLbl: Label 'Contact E-Mail';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        LogInteraction: Boolean;
        ShowInternalInfo: Boolean;

    protected procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Finance Charge Memo") <> '';
    end;

    procedure InitializeRequest(NewShowInternalInfo: Boolean; NewLogInteraction: Boolean)
    begin
        ShowInternalInfo := NewShowInternalInfo;
        LogInteraction := NewLogInteraction;
    end;
}

