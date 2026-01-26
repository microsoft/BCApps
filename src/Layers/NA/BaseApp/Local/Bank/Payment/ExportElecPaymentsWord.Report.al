// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11383 "ExportElecPayments - Word"
{
    Caption = 'Export Electronic Payments';
    DefaultRenderingLayout = "ExportElecPaymentsWord.docx";

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Bank Payment Type" = filter("Electronic Payment" | "Electronic Payment-IAT"), "Document Type" = filter(Payment | Refund));
            RequestFilterFields = "Journal Template Name", "Journal Batch Name";
            column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(Gen__Journal_Line_Line_No_; "Line No.")
            {
            }
            column(Gen__Journal_Line_Applies_to_ID; "Applies-to ID")
            {
            }
            dataitem(LetterText; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GreetingText; GreetingLbl)
                {
                }
                column(ClosingText; ClosingLbl)
                {
                }
                column(BodyText; BodyLbl)
                {
                }
                column(CompanyAddress_1; CompanyAddress[1])
                {
                }
                column(CompanyAddress_2; CompanyAddress[2])
                {
                }
                column(CompanyAddress_3; CompanyAddress[3])
                {
                }
                column(CompanyAddress_4; CompanyAddress[4])
                {
                }
                column(CompanyAddress_5; CompanyAddress[5])
                {
                }
                column(CompanyAddress_6; CompanyAddress[6])
                {
                }
                column(CompanyAddress_7; CompanyAddress[7])
                {
                }
                column(CompanyAddress_8; CompanyAddress[8])
                {
                }
                column(CompanyLegalOffice; '')
                {
                }
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(PayeeAddress_1_; PayeeAddress[1])
                    {
                    }
                    column(PayeeAddress_2_; PayeeAddress[2])
                    {
                    }
                    column(PayeeAddress_3_; PayeeAddress[3])
                    {
                    }
                    column(PayeeAddress_4_; PayeeAddress[4])
                    {
                    }
                    column(PayeeAddress_5_; PayeeAddress[5])
                    {
                    }
                    column(PayeeAddress_6_; PayeeAddress[6])
                    {
                    }
                    column(PayeeAddress_7_; PayeeAddress[7])
                    {
                    }
                    column(PayeeAddress_8_; PayeeAddress[8])
                    {
                    }
                    column(PayeeType; Format(PayeeType))
                    {
                    }
                    column(PayeeNo; PayeeNo)
                    {
                    }
                    column(Gen__Journal_Line___Document_No__; "Gen. Journal Line"."Document No.")
                    {
                    }
                    column(SettleDate; Format("Gen. Journal Line"."Document Date", 0, 4))
                    {
                    }
                    column(ExportAmount; -ExportAmount)
                    {
                    }
                    column(PayeeBankTransitNo; PayeeBankTransitNo)
                    {
                    }
                    column(PayeeBankAccountNo; PayeeBankAccountNo)
                    {
                    }
                    column(myNumber; CopyLoop.Number)
                    {
                    }
                    column(myBal; "Gen. Journal Line"."Bal. Account No.")
                    {
                    }
                    column(mypostingdate; "Gen. Journal Line"."Posting Date")
                    {
                    }
                    column(Gen__Journal_Line___Applies_to_Doc__No__; "Gen. Journal Line"."Applies-to Doc. No.")
                    {
                    }
                    column(myType; myType)
                    {
                    }
                    column(AmountPaid; AmountPaid)
                    {
                    }
                    column(DiscountTaken; DiscountTaken)
                    {
                    }
                    column(VendLedgEntry__Remaining_Amt___LCY__; -VendLedgEntry."Remaining Amt. (LCY)")
                    {
                    }
                    column(VendLedgEntry__Document_Date_; Format(VendLedgEntry."Document Date", 0, 4))
                    {
                    }
                    column(VendLedgEntry__External_Document_No__; VendLedgEntry."External Document No.")
                    {
                    }
                    column(VendLedgEntry__Document_Type_; VendLedgEntry."Document Type")
                    {
                    }
                    column(AmountPaid_Control57; AmountPaid)
                    {
                    }
                    column(DiscountTaken_Control58; DiscountTaken)
                    {
                    }
                    column(CustLedgEntry__Remaining_Amt___LCY__; -CustLedgEntry."Remaining Amt. (LCY)")
                    {
                    }
                    column(CustLedgEntry__Document_Date_; CustLedgEntry."Document Date")
                    {
                    }
                    column(CustLedgEntry__Document_No__; CustLedgEntry."Document No.")
                    {
                    }
                    column(CustLedgEntry__Document_Type_; CustLedgEntry."Document Type")
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(REMITTANCE_ADVICECaption; REMITTANCE_ADVICECaptionLbl)
                    {
                    }
                    column(To_Caption; To_CaptionLbl)
                    {
                    }
                    column(Remittance_Advice_Number_Caption; Remittance_Advice_Number_CaptionLbl)
                    {
                    }
                    column(Settlement_Date_Caption; Settlement_Date_CaptionLbl)
                    {
                    }
                    column(Page_Caption; Page_CaptionLbl)
                    {
                    }
                    column(ExportAmountCaption; ExportAmountCaptionLbl)
                    {
                    }
                    column(PayeeBankTransitNoCaption; PayeeBankTransitNoCaptionLbl)
                    {
                    }
                    column(Deposited_In_Caption; Deposited_In_CaptionLbl)
                    {
                    }
                    column(PayeeBankAccountNoCaption; PayeeBankAccountNoCaptionLbl)
                    {
                    }
                    column(Vendor_Ledger_Entry__Document_Type_Caption; "Vendor Ledger Entry".FieldCaption("Document Type"))
                    {
                    }
                    column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
                    {
                    }
                    column(Vendor_Ledger_Entry__Document_Date_Caption; "Vendor Ledger Entry".FieldCaption("Document Date"))
                    {
                    }
                    column(Remaining_Amt___LCY___Control36Caption; Remaining_Amt___LCY___Control36CaptionLbl)
                    {
                    }
                    column(DiscountTaken_Control38Caption; DiscountTaken_Control38CaptionLbl)
                    {
                    }
                    column(AmountPaid_Control43Caption; AmountPaid_Control43CaptionLbl)
                    {
                    }
                    dataitem(PrintCompanyAddress; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(CompanyPicture; CompanyInfo.Picture)
                        {
                        }
                        column(CompanyAddress_1_; CompanyAddress[1])
                        {
                        }
                        column(CompanyAddress_2_; CompanyAddress[2])
                        {
                        }
                        column(CompanyAddress_3_; CompanyAddress[3])
                        {
                        }
                        column(CompanyAddress_4_; CompanyAddress[4])
                        {
                        }
                        column(CompanyAddress_5_; CompanyAddress[5])
                        {
                        }
                        column(CompanyAddress_6_; CompanyAddress[6])
                        {
                        }
                        column(CompanyAddress_7_; CompanyAddress[7])
                        {
                        }
                        column(CompanyAddress_8_; CompanyAddress[8])
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            CompanyInfo.Get();
                            if PrintCompanyPicture then
                                CompanyInfo.CalcFields(Picture);
                            if PrintCompanyAdd then begin
                                FormatAddress.Company(CompanyAddress, CompanyInfo);
                                if CompanyAddress[5] <> '' then
                                    CompanyAddress[5] := StrSubstNo(', %1', CompanyAddress[5]);
                            end;
                        end;
                    }
                    dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                    {
                        DataItemLink = "Applies-to ID" = field("Applies-to ID");
                        DataItemLinkReference = "Gen. Journal Line";
                        DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date", "Currency Code") order(descending) where(Open = const(true));
                        column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Cust__Ledger_Entry__Document_No__; "Document No.")
                        {
                        }
                        column(Cust__Ledger_Entry__Document_Date_; Format("Document Date", 0, 4))
                        {
                        }
                        column(Remaining_Amt___LCY__; -"Remaining Amt. (LCY)")
                        {
                        }
                        column(DiscountTaken_Control49; DiscountTaken)
                        {
                        }
                        column(AmountPaid_Control50; AmountPaid)
                        {
                        }
                        column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                        {
                        }
                        column(Cust__Ledger_Entry_Applies_to_ID; "Applies-to ID")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            CalcFields("Remaining Amt. (LCY)");
                            if ("Pmt. Discount Date" >= "Gen. Journal Line"."Document Date") and
                               ("Remaining Pmt. Disc. Possible" <> 0) and
                               ((-ExportAmount - TotalAmountPaid) - "Remaining Pmt. Disc. Possible" >= -"Amount to Apply")
                            then begin
                                DiscountTaken := -"Remaining Pmt. Disc. Possible";
                                AmountPaid := -("Amount to Apply" - "Remaining Pmt. Disc. Possible");
                            end else begin
                                DiscountTaken := 0;
                                if (-ExportAmount - TotalAmountPaid) > -"Amount to Apply" then
                                    AmountPaid := -"Amount to Apply"
                                else
                                    AmountPaid := -ExportAmount - TotalAmountPaid;
                            end;

                            TotalAmountPaid := TotalAmountPaid + AmountPaid;

                            IsSummary := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if "Gen. Journal Line"."Applies-to ID" = '' then
                                CurrReport.Break();

                            if BankAccountIs = BankAccountIs::Acnt then begin
                                if "Gen. Journal Line"."Bal. Account Type" <> "Gen. Journal Line"."Bal. Account Type"::Customer then
                                    CurrReport.Break();
                                SetRange("Customer No.", "Gen. Journal Line"."Bal. Account No.");
                            end else begin
                                if "Gen. Journal Line"."Account Type" <> "Gen. Journal Line"."Account Type"::Customer then
                                    CurrReport.Break();
                                SetRange("Customer No.", "Gen. Journal Line"."Account No.");
                            end;
                        end;
                    }
                    dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                    {
                        DataItemLink = "Applies-to ID" = field("Applies-to ID");
                        DataItemLinkReference = "Gen. Journal Line";
                        DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") order(descending) where(Open = const(true));
                        column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Vendor_Ledger_Entry__External_Document_No__; "External Document No.")
                        {
                        }
                        column(Vendor_Ledger_Entry__Document_Date_; Format("Document Date", 0, 4))
                        {
                        }
                        column(Remaining_Amt___LCY___Control36; -"Remaining Amt. (LCY)")
                        {
                        }
                        column(DiscountTaken_Control38; DiscountTaken)
                        {
                        }
                        column(AmountPaid_Control43; AmountPaid)
                        {
                        }
                        column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                        {
                        }
                        column(Vendor_Ledger_Entry_Applies_to_ID; "Applies-to ID")
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            Currency: Record Currency;
                            CurrExchRate: Record "Currency Exchange Rate";
                            ValidExchRate: Boolean;
                        begin
                            CalcFields("Remaining Amt. (LCY)");
                            if ("Pmt. Discount Date" >= "Gen. Journal Line"."Document Date") and
                               ("Remaining Pmt. Disc. Possible" <> 0) and
                               ((-ExportAmount - TotalAmountPaid) - "Remaining Pmt. Disc. Possible" >= -"Amount to Apply")
                            then begin
                                DiscountTaken := -"Remaining Pmt. Disc. Possible";
                                AmountPaid := -("Amount to Apply" - "Remaining Pmt. Disc. Possible");
                            end else begin
                                DiscountTaken := 0;
                                if (-ExportAmount - TotalAmountPaid) > -"Amount to Apply" then
                                    AmountPaid := -"Amount to Apply"
                                else
                                    AmountPaid := -ExportAmount - TotalAmountPaid;
                            end;

                            if "Gen. Journal Line"."Currency Code" = '' then begin
                                Currency.Reset();
                                Currency.SetRange(Code, "Currency Code");
                                if Currency.FindFirst() then
                                    TotalAmountPaid := TotalAmountPaid + Round(CurrExchRate.ApplnExchangeAmtFCYToFCY(
                                             "Posting Date", "Currency Code", "Gen. Journal Line"."Currency Code", AmountPaid, ValidExchRate), Currency."Amount Rounding Precision")
                                else
                                    TotalAmountPaid := TotalAmountPaid + AmountPaid;
                            end else
                                TotalAmountPaid := TotalAmountPaid + AmountPaid;
                            IsSummary := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if "Gen. Journal Line"."Applies-to ID" = '' then
                                CurrReport.Break();

                            if BankAccountIs = BankAccountIs::Acnt then begin
                                if "Gen. Journal Line"."Bal. Account Type" <> "Gen. Journal Line"."Bal. Account Type"::Vendor then
                                    CurrReport.Break();
                                SetRange("Vendor No.", "Gen. Journal Line"."Bal. Account No.");
                            end else begin
                                if "Gen. Journal Line"."Account Type" <> "Gen. Journal Line"."Account Type"::Vendor then
                                    CurrReport.Break();
                                SetRange("Vendor No.", "Gen. Journal Line"."Account No.");
                            end;
                        end;
                    }
                    dataitem(CustomerInfo; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                        column(AmountPaid_Customer; AmountPaid)
                        {
                        }
                        column(DiscountTaken_Customer; DiscountTaken)
                        {
                        }
                        column(Cust_Remaining_Amt_LCY; -CustLedgEntry."Remaining Amt. (LCY)")
                        {
                        }
                        column(Cust_Document_Date; Format(CustLedgEntry."Document Date", 0, 4))
                        {
                        }
                        column(Cust_Document_No; CustLedgEntry."Document No.")
                        {
                        }
                        column(Cust_Document_Type; CustLedgEntry."Document Type")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if (PayeeType <> PayeeType::Customer) or IsSummary then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(VendorInfo; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                        column(Vend_Remaining_Amt_LCY; -VendLedgEntry."Remaining Amt. (LCY)")
                        {
                        }
                        column(Vend_Document_Date; Format(VendLedgEntry."Document Date", 0, 4))
                        {
                        }
                        column(Vend_External_Document_No; VendLedgEntry."External Document No.")
                        {
                        }
                        column(Vend_Document_Type; VendLedgEntry."Document Type")
                        {
                        }
                        column(AmountPaid_Vendor; AmountPaid)
                        {
                        }
                        column(DiscountTaken_Vendor; DiscountTaken)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if (PayeeType <> PayeeType::Vendor) or IsSummary then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Unapplied; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Text004; Text004Lbl)
                        {
                        }
                        column(AmountPaid_Control65; AmountPaid)
                        {
                        }
                        column(Unapplied_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            AmountPaid := -ExportAmount - TotalAmountPaid;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if TotalAmountPaid >= -ExportAmount then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        myType := PayeeType;// an Integer variable refer to  option type
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    AmountPaid := SaveAmountPaid;

                    if Number = 1 then // Original
                        Clear(CopyTxt)
                    else
                        CopyTxt := CopyLoopLbl;

                    if "Gen. Journal Line"."Applies-to Doc. No." = '' then
                        Clear(TotalAmountPaid);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoCopies + 1);
                    SaveAmountPaid := AmountPaid;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Account Type" = "Account Type"::"Bank Account" then begin
                    BankAccountIs := BankAccountIs::Acnt;
                    if "Account No." <> BankAccount."No." then
                        CurrReport.Skip();
                end else
                    if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then begin
                        BankAccountIs := BankAccountIs::BalAcnt;
                        if "Bal. Account No." <> BankAccount."No." then
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();
                if BankAccountIs = BankAccountIs::Acnt then begin
                    ExportAmount := "Amount (LCY)";
                    PayeeNo := "Bal. Account No.";
                    if "Bal. Account Type" = "Bal. Account Type"::Vendor then begin
                        PayeeType := PayeeType::Vendor;
                        Vendor.Get("Bal. Account No.");
                    end else
                        if "Bal. Account Type" = "Bal. Account Type"::Customer then begin
                            PayeeType := PayeeType::Customer;
                            Customer.Get("Bal. Account No.");
                        end else
                            Error(AccountTypeErr,
                              FieldCaption("Bal. Account Type"), Customer.TableCaption(), Vendor.TableCaption());
                end else begin
                    ExportAmount := -"Amount (LCY)";
                    PayeeNo := "Account No.";
                    if "Account Type" = "Account Type"::Vendor then begin
                        PayeeType := PayeeType::Vendor;
                        Vendor.Get("Account No.");
                    end else
                        if "Account Type" = "Account Type"::Customer then begin
                            PayeeType := PayeeType::Customer;
                            Customer.Get("Account No.");
                        end else
                            Error(AccountTypeErr,
                              FieldCaption("Account Type"), Customer.TableCaption(), Vendor.TableCaption());
                end;

                DiscountTaken := 0;
                AmountPaid := 0;
                TotalAmountPaid := 0;
                if PayeeType = PayeeType::Vendor then
                    ProcessVendor("Gen. Journal Line")
                else
                    ProcessCustomer("Gen. Journal Line");

                TotalAmountPaid := AmountPaid;

                if PayeeAddress[5] <> '' then
                    PayeeAddress[5] := StrSubstNo(', %1', PayeeAddress[5]);
            end;

            trigger OnPreDataItem()
            begin
            end;
        }
    }

    requestpage
    {
        Caption = 'Export Electronic Payments';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(BankAccountNo; BankAccount."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the payment is transmitted to.';
                    }
                    field(NumberOfCopies; NoCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        MaxValue = 9;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompanyAddress; PrintCompanyAdd)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(PrintCompanyLogo; PrintCompanyPicture)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Logo';
                        ToolTip = 'Specifies if your company logo is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s logo.';
                    }
                    group(OutputOptions)
                    {
                        Caption = 'Output Options';
                        field(OutputMethod; SupportedOutputMethod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Output Method';
                            OptionCaption = 'Print,Preview,PDF,Email,Word,XML - RDLC layouts only', Comment = 'Verbs - to print, to preview, to export to PDF, to email, to export to word, to export to XML (with note that it''s for RDLC layouts only)';
                            ToolTip = 'Specifies how the electronic payment is exported.';

                            trigger OnValidate()
                            begin
                                MapOutputMethod();
                            end;
                        }
                        field(ChosenOutputMethod; ChosenOutputMethod)
                        {
                            Visible = false;
                        }
                    }
                    group(EmailOptions)
                    {
                        Caption = 'Email Options';
                        Visible = ShowPrintIfEmailIsMissing;
                        field(PrintMissingAddresses; PrintIfEmailIsMissing)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print remaining statements';
                            ToolTip = 'Specifies that amounts remaining to be paid will be included.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            MapOutputMethod();
        end;
    }

    rendering
    {
        layout("ExportElecPaymentsWord.rdlc")
        {
            Type = RDLC;
            Caption = 'RDLC layout for the Export Electronic Payments';
            LayoutFile = './Local/Bank/Payment/ExportElecPaymentsWord.rdlc';
        }
        layout("ExportElecPaymentsWord.docx")
        {
            Type = Word;
            Caption = 'Word layout for the Export Electronic Payments';
            LayoutFile = './Local/Bank/Payment/ExportElecPaymentsWord.docx';
        }
        layout("ExportElecPaymentsWordEmail.docx")
        {
            Type = Word;
            Caption = 'Email body for the Export Electronic Payments';
            LayoutFile = './Local/Bank/Payment/ExportElecPaymentsWordEmail.docx';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CompanyInformation.Get();

        GenJournalLine.Copy("Gen. Journal Line");
        if GenJournalLine.FindFirst() then begin
            GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
            if not GenJournalTemplate."Force Doc. Balance" then
                if not Confirm(CannotVoidQst, true) then
                    Error(UserCancelledErr);

            if not UseRequestPage() then
                if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
                    GenJournalBatch.TestField("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
                    GenJournalBatch.TestField(GenJournalBatch."Bal. Account No.");
                    BankAccount."No." := GenJournalBatch."Bal. Account No.";
                end;

            BankAccount.Get(BankAccount."No.");
            BankAccount.TestField(Blocked, false);
            BankAccount.TestField("Export Format");
            BankAccount.TestField("Last Remittance Advice No.");
        end;

        if PrintCompanyAdd then
            FormatAddress.Company(CompanyAddress, CompanyInformation);
    end;

    var
        AccountTypeErr: Label 'For Electronic Payments, the %1 must be %2 or %3.', Comment = '%1=Balance account type,%2=Customer table caption,%3=Vendor table caption';
        CopyLoopLbl: Label '- COPY';
        CannotVoidQst: Label 'Warning:  Transactions cannot be financially voided when Force Doc. Balance is set to No in the Journal Template.  Do you want to continue anyway?';
        UserCancelledErr: Label 'Process cancelled at user request.';
        REMITTANCE_ADVICECaptionLbl: Label 'REMITTANCE ADVICE';
        To_CaptionLbl: Label 'To:';
        Remittance_Advice_Number_CaptionLbl: Label 'Remittance Advice Number:';
        Settlement_Date_CaptionLbl: Label 'Settlement Date:';
        Page_CaptionLbl: Label 'Page:';
        ExportAmountCaptionLbl: Label 'Deposit Amount:';
        PayeeBankTransitNoCaptionLbl: Label 'Bank Transit No:';
        Deposited_In_CaptionLbl: Label 'Deposited In:';
        PayeeBankAccountNoCaptionLbl: Label 'Bank Account No:';
        Remaining_Amt___LCY___Control36CaptionLbl: Label 'Amount Due';
        DiscountTaken_Control38CaptionLbl: Label 'Discount Taken';
        AmountPaid_Control43CaptionLbl: Label 'Amount Paid';
        Text004Lbl: Label 'Unapplied Amount';
        CompanyInformation: Record "Company Information";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustBankAccount: Record "Customer Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendBankAccount: Record "Vendor Bank Account";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FormatAddress: Codeunit "Format Address";
        ExportAmount: Decimal;
        BankAccountIs: Option Acnt,BalAcnt;
        NoCopies: Integer;
        CopyTxt: Code[10];
        PrintCompanyAdd: Boolean;
        PrintCompanyPicture: Boolean;
        CompanyAddress: array[8] of Text[100];
        PayeeAddress: array[8] of Text[100];
        PayeeType: Option Vendor,Customer;
        PayeeNo: Text;
        PayeeBankTransitNo: Text[30];
        PayeeBankAccountNo: Text[30];
        DiscountTaken: Decimal;
        AmountPaid: Decimal;
        TotalAmountPaid: Decimal;
        myType: Integer;
        SaveAmountPaid: Decimal;
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Word,XML;
        ChosenOutputMethod: Integer;
        PrintIfEmailIsMissing: Boolean;
        ShowPrintIfEmailIsMissing: Boolean;
        IsSummary: Boolean;
        GreetingLbl: Label 'Hello';
        ClosingLbl: Label 'Sincerely';
        BodyLbl: Label 'Thank you for your business. Your remittance is attached to this message.';

    protected var
        CompanyInfo: Record "Company Information";

    local procedure MapOutputMethod()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        ShowPrintIfEmailIsMissing := (SupportedOutputMethod = SupportedOutputMethod::Email);
        // Map the supported option (shown on the page) to the list of supported output methods
        case SupportedOutputMethod of
            SupportedOutputMethod::Print:
                ChosenOutputMethod := CustomLayoutReporting.GetPrintOption();
            SupportedOutputMethod::Preview:
                ChosenOutputMethod := CustomLayoutReporting.GetPreviewOption();
            SupportedOutputMethod::PDF:
                ChosenOutputMethod := CustomLayoutReporting.GetPDFOption();
            SupportedOutputMethod::Email:
                ChosenOutputMethod := CustomLayoutReporting.GetEmailOption();
            SupportedOutputMethod::Word:
                ChosenOutputMethod := CustomLayoutReporting.GetWordOption();
            SupportedOutputMethod::XML:
                ChosenOutputMethod := CustomLayoutReporting.GetXMLOption();
        end;
    end;

    local procedure ProcessVendor(var GenJnlLine: Record "Gen. Journal Line")
    var
        EFTRecipientBankAccountMgt: codeunit "EFT Recipient Bank Account Mgt";
    begin
        FormatAddress.Vendor(PayeeAddress, Vendor);

        EFTRecipientBankAccountMgt.GetRecipientVendorBankAccount(VendBankAccount, GenJnlLine, Vendor."No.");

        PayeeBankTransitNo := VendBankAccount."Transit No.";
        PayeeBankAccountNo := VendBankAccount."Bank Account No.";
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.FindFirst();
            VendLedgEntry.CalcFields("Remaining Amt. (LCY)", Amount);
            if (VendLedgEntry."Pmt. Discount Date" >= GenJnlLine."Document Date") and
               (VendLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
               (-(ExportAmount + VendLedgEntry."Remaining Pmt. Disc. Possible") >= -VendLedgEntry.Amount)
            then begin
                DiscountTaken := -VendLedgEntry."Remaining Pmt. Disc. Possible";
                AmountPaid := -(VendLedgEntry.Amount - VendLedgEntry."Remaining Pmt. Disc. Possible");
            end else
                if -ExportAmount > -VendLedgEntry.Amount then
                    AmountPaid := -VendLedgEntry.Amount
                else
                    AmountPaid := -ExportAmount;
        end;
    end;

    local procedure ProcessCustomer(var GenJnlLine: Record "Gen. Journal Line")
    var
        EFTRecipientBankAccountMgt: codeunit "EFT Recipient Bank Account Mgt";
    begin
        FormatAddress.Customer(PayeeAddress, Customer);

        EFTRecipientBankAccountMgt.GetRecipientCustomerBankAccount(CustBankAccount, GenJnlLine, Customer."No.");

        PayeeBankTransitNo := CustBankAccount."Transit No.";
        PayeeBankAccountNo := CustBankAccount."Bank Account No.";
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            CustLedgEntry.SetRange("Customer No.", Customer."No.");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.FindFirst();
            CustLedgEntry.CalcFields("Remaining Amt. (LCY)", Amount);
            if (CustLedgEntry."Pmt. Discount Date" >= GenJnlLine."Document Date") and
               (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
               (-(ExportAmount - CustLedgEntry."Remaining Pmt. Disc. Possible") >= -CustLedgEntry.Amount)
            then begin
                DiscountTaken := -CustLedgEntry."Remaining Pmt. Disc. Possible";
                AmountPaid := -(CustLedgEntry.Amount - CustLedgEntry."Remaining Pmt. Disc. Possible");
            end else
                if -ExportAmount > -CustLedgEntry.Amount then
                    AmountPaid := -CustLedgEntry.Amount
                else
                    AmountPaid := -ExportAmount;
        end;
    end;
}

