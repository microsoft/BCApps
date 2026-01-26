// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

report 15000002 "Remittance Test Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Payables/RemittanceTestReport.rdlc';
    Caption = 'Remittance Test Report';

    dataset
    {
        dataitem(Transaction; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Remittance Agreement Code", "Remittance Type");
            RequestFilterFields = "Account Type", "Account No.";
            column(JnlTempName_Transaction; "Journal Template Name")
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(JnlBatchName_Transaction; "Journal Batch Name")
            {
            }
            column(RemAccountCode; RemAccount.Code)
            {
            }
            column(RemAccountDescription; RemAccount.Description)
            {
            }
            column(RemAccountBankAccNo; RemAccount."Bank Account No.")
            {
            }
            column(RemContractDescription; RemContract.Description)
            {
            }
            column(RemContractCode; RemContract.Code)
            {
            }
            column(AccountNo; "Account No.")
            {
            }
            column(RemittanceType; "Remittance Type")
            {
            }
            column(RemittanceTypeIntValue; RemittanceTypeIntValue)
            {
            }
            column(PostingDate; Format("Posting Date"))
            {
            }
            column(ShowPaymentInfo; ShowPaymentInfo)
            {
            }
            column(Amount_Transaction; Amount)
            {
            }
            column(CurrencyCode; "Currency Code")
            {
            }
            column(AmountLCY_Transaction; "Amount (LCY)")
            {
            }
            column(NumberNo; NumberNo)
            {
            }
            column(JnlTempNameCaption_Transaction; FieldCaption("Journal Template Name"))
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(RemTestReportCaption; RemTestReportCaptionLbl)
            {
            }
            column(JnlBatchNameCaption_Transaction; FieldCaption("Journal Batch Name"))
            {
            }
            column(RemAccCodeCaption; RemAccCodeCaptionLbl)
            {
            }
            column(BankAccNoCaption; BankAccNoCaptionLbl)
            {
            }
            column(RemContractCodeCaption; RemContractCodeCaptionLbl)
            {
            }
            column(AmountCaption_Transaction; "Gen. Journal Line".FieldCaption(Amount))
            {
            }
            column(AccountNameCaption; AccountNameCaptionLbl)
            {
            }
            column(AccNoCaption_Transaction; FieldCaption("Account No."))
            {
            }
            column(DocNoCaption_Transaction; "Gen. Journal Line".FieldCaption("Document No."))
            {
            }
            column(DocTypeCaption; DocTypeCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(AmountLCYCaption_Transaction; "Gen. Journal Line".FieldCaption("Amount (LCY)"))
            {
            }
            column(DescriptionCaption_Transaction; "Gen. Journal Line".FieldCaption(Description))
            {
            }
            column(RemittanceAgreementCode_Transaction; "Remittance Agreement Code")
            {
            }
            dataitem("Gen. Journal Line"; "Gen. Journal Line")
            {
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Remittance Agreement Code", "Remittance Type");
                column(TransactionNo; TransactionNo)
                {
                }
                column(PostingDate_GenJnlLine; Format("Posting Date"))
                {
                }
                column(AccountNo_GenJnlLine; "Account No.")
                {
                }
                column(RemTypeDomestic; "Remittance Type" = "Remittance Type"::Domestic)
                {
                }
                column(VendRecipientBankAccNo; Vendor."Recipient Bank Account No.")
                {
                }
                column(NOTUnstructuredPaym; not UnstructuredPaym)
                {
                }
                column(AgreedWith_GenJnlLine; "Agreed With")
                {
                }
                column(Urgent_GenJnlLine; Urgent)
                {
                }
                column(CurrencyCodeShow; CurrencyCodeShow)
                {
                }
                column(AgreedExchRate_GenJnlLine; "Agreed Exch. Rate")
                {
                }
                column(FuturesContractNo_GenJnlLine; "Futures Contract No.")
                {
                }
                column(FuturesContractExchRate_GenJnlLine; "Futures Contract Exch. Rate")
                {
                }
                column(CurrExchrateShow; CurrExchrateShow)
                {
                    DecimalPlaces = 5 : 5;
                }
                column(CurrExchRateText; CurrExchRateText)
                {
                }
                column(CurrencyCode_GenJnlLine; "Currency Code")
                {
                }
                column(Amount_GenJnlLine; Amount)
                {
                }
                column(Description_GenJnlLine; Description)
                {
                }
                column(AccountName; AccountName)
                {
                }
                column(DocumentNo_GenJnlLine; "Document No.")
                {
                }
                column(DocumentType_GenJnlLine; "Document Type")
                {
                }
                column(AmountLCY_GenJnlLine; "Amount (LCY)")
                {
                }
                column(RemittanceAccCode_GenJnlLine; "Remittance Account Code")
                {
                }
                column(BOLSTextCode_GenJnlLine; "BOLS Text Code")
                {
                }
                column(PaymentTypeCodeDomestic_GenJnlLine; "Payment Type Code Domestic")
                {
                }
                column(KID_GenJnlLine; KID)
                {
                }
                column(RecipientRef1_GenJnlLine; "Recipient Ref. 1")
                {
                }
                column(RecipientRef2_GenJnlLine; "Recipient Ref. 2")
                {
                }
                column(RecipientRef3_GenJnlLine; "Recipient Ref. 3")
                {
                }
                column(ExternalDocNo_GenJnlLine; "External Document No.")
                {
                }
                column(OurAccNo_GenJnlLine; "Our Account No.")
                {
                }
                column(Check_GenJnlLine; Check)
                {
                }
                column(RecipientRefAbroad_GenJnlLine; "Recipient Ref. Abroad")
                {
                }
                column(PaymentTypeCodeAbroad_GenJnlLine; "Payment Type Code Abroad")
                {
                }
                column(SpecificationNorgesBank_GenJnlLine; "Specification (Norges Bank)")
                {
                }
                column(TransactionNoCaption; TransactionNoCaptionLbl)
                {
                }
                column(VendorNoCaption; VendorNoCaptionLbl)
                {
                }
                column(DomesticPaymentsCaption; DomesticPaymentsCaptionLbl)
                {
                }
                column(VendRecipientBankAccNoCaption; VendRecipientBankAccNoCaptionLbl)
                {
                }
                column(NOTUnstructuredPaymCaption; NOTUnstructuredPaymCaptionLbl)
                {
                }
                column(AgreedWithCaption_GenJnlLine; FieldCaption("Agreed With"))
                {
                }
                column(UrgentCaption_GenJnlLine; FieldCaption(Urgent))
                {
                }
                column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                {
                }
                column(AgreedExchRateCaption_GenJnlLine; FieldCaption("Agreed Exch. Rate"))
                {
                }
                column(FuturesContractNoCaption_GenJnlLine; FieldCaption("Futures Contract No."))
                {
                }
                column(ContractExchRateCaption_GenJnlLine; FieldCaption("Futures Contract Exch. Rate"))
                {
                }
                column(BOLSTextCodeCaption_GenJnlLine; FieldCaption("BOLS Text Code"))
                {
                }
                column(PaymentTypeCodeDomCaption_GenJnlLine; FieldCaption("Payment Type Code Domestic"))
                {
                }
                column(KIDCaption; FieldCaption(KID))
                {
                }
                column(RecipientRef1Caption_GenJnlLine; FieldCaption("Recipient Ref. 1"))
                {
                }
                column(RecipientRef2Caption_GenJnlLine; FieldCaption("Recipient Ref. 2"))
                {
                }
                column(RecipientRef3Caption_GenJnlLine; FieldCaption("Recipient Ref. 3"))
                {
                }
                column(RemittanceAccCodeCaption_GenJnlLine; FieldCaption("Remittance Account Code"))
                {
                }
                column(AgreementCodeCaption; AgreementCodeCaptionLbl)
                {
                }
                column(ExternalDocNoCaption_GenJnlLine; FieldCaption("External Document No."))
                {
                }
                column(OurAccNoCaption_GenJnlLine; FieldCaption("Our Account No."))
                {
                }
                column(CheckCaption; FieldCaption(Check))
                {
                }
                column(RecipientRefAbroadCaption_GenJnlLine; FieldCaption("Recipient Ref. Abroad"))
                {
                }
                column(PaymentTypeCodeAbroadCaption_GenJnlLine; FieldCaption("Payment Type Code Abroad"))
                {
                }
                column(SpecificationNorgesBankCaption_GenJnlLine; FieldCaption("Specification (Norges Bank)"))
                {
                }
                column(JnlTempName_GenJnlLine; "Journal Template Name")
                {
                }
                column(JnlBatchName_GenJnlLine; "Journal Batch Name")
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionsCaption; DimensionsCaptionLbl)
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

                        DimText := GetDimText(Number);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();

                        DimSetEntry.SetRange("Dimension Set ID", "Gen. Journal Line"."Dimension Set ID");
                    end;
                }
                dataitem(ErrorLoopPayment; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorTextNumber_ErrorLoopPayment; ErrorText[Number])
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
                    RemittanceTypeIntValue := "Remittance Type";
                    TransLineCounter := TransLineCounter + 1;
                    TransTotal := TransTotal + "Gen. Journal Line".Amount;
                    TotalAmountLCY := TotalAmountLCY + "Gen. Journal Line"."Amount (LCY)";
                    ErrorCounter := ErrorCounter + 1;
                    ErrorText[ErrorCounter] := '1';

                    AccountName := '';
                    case "Gen. Journal Line"."Account Type" of
                        "Gen. Journal Line"."Account Type"::"G/L Account":
                            if GenLedgAccount.Get("Account No.") then
                                AccountName := GenLedgAccount.Name;
                        "Gen. Journal Line"."Account Type"::Customer:
                            if Customer.Get("Account No.") then
                                AccountName := Customer.Name;
                        "Gen. Journal Line"."Account Type"::Vendor:
                            if Vendor.Get("Account No.") then
                                AccountName := Vendor.Name;
                        "Gen. Journal Line"."Account Type"::"Bank Account":
                            if BankAccount.Get("Account No.") then
                                AccountName := BankAccount.Name;
                    end;

                    LineCheck("Gen. Journal Line");
                    SettleAccount(
                      RemAccount."Bank Account No.", "Gen. Journal Line"."Currency Code", "Gen. Journal Line".Amount,
                      "Gen. Journal Line"."Amount (LCY)");
                end;

                trigger OnPostDataItem()
                begin
                    if TransTotal <= 0 then
                        AdditionError(Text018, true);
                end;

                trigger OnPreDataItem()
                begin
                    ErrorCounter := 0;
                    TransLineCounter := 0;
                    UnstructuredPaym := false;

                    // Group together all payments within the transaction
                    // If the payments are not structured, then the max. no. of payments within transaction is 8.
                    // In case of structured payments, max. no. of payments within transaction is 999.
                    "Gen. Journal Line".SetRange("Journal Template Name", Transaction."Journal Template Name");
                    "Gen. Journal Line".SetRange("Journal Batch Name", Transaction."Journal Batch Name");
                    "Gen. Journal Line".SetRange("Remittance Type", Transaction."Remittance Type");
                    "Gen. Journal Line".SetRange("Remittance Account Code", Transaction."Remittance Account Code");
                    "Gen. Journal Line".SetRange("Posting Date", Transaction."Posting Date");
                    "Gen. Journal Line".SetRange("Account No.", Transaction."Account No.");
                    "Gen. Journal Line".SetRange(Urgent, Transaction.Urgent);
                    "Gen. Journal Line".SetRange("Futures Contract No.", Transaction."Futures Contract No.");
                    "Gen. Journal Line".SetRange("Futures Contract Exch. Rate", Transaction."Futures Contract Exch. Rate");
                    "Gen. Journal Line".SetRange("Currency Code", Transaction."Currency Code");
                    "Gen. Journal Line".SetRange("Currency Factor", Transaction."Currency Factor");
                    "Gen. Journal Line".SetRange("Agreed Exch. Rate", Transaction."Agreed Exch. Rate");
                    "Gen. Journal Line".SetRange("Agreed With", Transaction."Agreed With");
                    if not Transaction."Structured Payment" then
                        UnstructuredPaym := true;
                    "Gen. Journal Line".SetRange("Structured Payment", Transaction."Structured Payment");

                    NumberOfPayments := "Gen. Journal Line".Count();
                end;
            }
            dataitem(ErrorLoopTransaction; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ErrorTextNumber_ErrorLoopTransaction; ErrorText[Number])
                {
                }
                column(TransactionNoumber; TransactionNo)
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
                TransactionNo := TransactionNo + 1;
                TransTotal := 0;
                TestField("Remittance Account Code");
                RemAccount.Get("Remittance Account Code");
                RemContract.Get("Remittance Agreement Code");

                // Data Item Transaction is processing only one record per Transaction,
                // and moves to the last line of the current transaction:
                SetRange("Remittance Agreement Code", "Remittance Agreement Code");
                SetRange("Remittance Type", "Remittance Type");
                SetRange("Remittance Account Code", "Remittance Account Code");
                SetRange("Posting Date", "Posting Date");
                SetRange("Account No.", "Account No.");
                SetRange(Urgent, Urgent);
                SetRange("Futures Contract No.", "Futures Contract No.");
                SetRange("Futures Contract Exch. Rate", "Futures Contract Exch. Rate");
                SetRange("Currency Code", "Currency Code");
                SetRange("Currency Factor", "Currency Factor");
                SetRange("Agreed Exch. Rate", "Agreed Exch. Rate");
                SetRange("Agreed With", "Agreed With");
                // Split into structured (kid or ext. doc. no <> '') and
                // structured (recipient ref. 1-3 <> '') payments
                SetRange("Structured Payment", "Structured Payment");
                FindLast();

                // Reestablish/delete filters on the transaction fields
                StoreJnlFilters.CopyFilter("Remittance Agreement Code", "Remittance Agreement Code");
                StoreJnlFilters.CopyFilter("Remittance Type", "Remittance Type");
                StoreJnlFilters.CopyFilter("Remittance Account Code", "Remittance Account Code");
                StoreJnlFilters.CopyFilter("Posting Date", "Posting Date");
                StoreJnlFilters.CopyFilter("Account No.", "Account No.");
                StoreJnlFilters.CopyFilter(Urgent, Urgent);
                StoreJnlFilters.CopyFilter("Futures Contract No.", "Futures Contract No.");
                StoreJnlFilters.CopyFilter("Futures Contract Exch. Rate", "Futures Contract Exch. Rate");
                StoreJnlFilters.CopyFilter("Currency Code", "Currency Code");
                StoreJnlFilters.CopyFilter("Currency Factor", "Currency Factor");
                StoreJnlFilters.CopyFilter("Agreed Exch. Rate", "Agreed Exch. Rate");
                StoreJnlFilters.CopyFilter("Agreed With", "Agreed With");
                StoreJnlFilters.CopyFilter("Recipient Ref. 1", "Recipient Ref. 1");
                StoreJnlFilters.CopyFilter("Structured Payment", "Structured Payment");

                // Locate currency info.
                if "Currency Code" <> '' then begin
                    Currency.Get("Currency Code");
                    if Currency."EMU Currency" then
                        CurrExchRateText := Text000
                    else
                        CurrExchRateText := Text001;
                    CurrencyCodeShow := "Currency Code";
                    CurrExchrateShow := Round("Amount (LCY)" / Amount * 100, 0.00001);
                end else begin
                    // Show currency code as specified in General ledger setup
                    CurrencyCodeShow := GenLedgSetup."LCY Code";
                    CurrExchRateText := '';
                end;

                StoreAgreementCode := RemAccount.Code;
            end;

            trigger OnPreDataItem()
            begin
                // Select lines from the journal:
                SetRange("Journal Template Name", CurrentJnlLine."Journal Template Name");
                SetRange("Journal Batch Name", CurrentJnlLine."Journal Batch Name");

                GenLedgSetup.Get();
                StoreJnlFilters.Copy(Transaction); // Store user-set filters
                TransactionNo := 0;
                StoreAgreementCode := '';

                PurchaseSetup.Get();
            end;
        }
        dataitem(ReportTotal; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(TotalAmountLCY; TotalAmountLCY)
            {
            }
            column(TotalAmountLCYCaption; TotalAmountLCYCaptionLbl)
            {
            }
        }
        dataitem(Settlementloop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(SettleNetChangeNumber; SettleNetChange[Number])
            {
            }
            column(SettleBankAccountNoNumber; SettleBankAccountNo[Number])
            {
            }
            column(SettleCurrencyCodeNumber; SettleCurrencyCode[Number])
            {
            }
            column(SettleNetChangeLCYNumber; SettleNetChangeLCY[Number])
            {
            }
            column(SettlementCaption; SettlementCaptionLbl)
            {
            }
            column(SettleNetChangeLCYNumberCaption; SettleNetChangeLCYNumberCaptionLbl)
            {
            }
            column(SettleNetChangeNumberCaption; SettleNetChangeNumberCaptionLbl)
            {
            }
            column(BankAccNoCaption_Settlementloop; BankAccNoCaptionLbl)
            {
            }

            trigger OnPostDataItem()
            begin
                SettleCounter := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, SettleCounter);
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
                    field(ShowPaymentInfo; ShowPaymentInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show payment info';
                        ToolTip = 'Specifies if you want to print the payment details on the report.';
                    }
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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

    var
        Text000: Label 'Currency exch. rate (to LCY) ';
        Text001: Label 'Currency exchange rate';
        Text002: Label 'Both Recipient ref. and KID/External Document No. are filled in. They cannot be used both at the same time.';
        Text003: Label 'There are no messages for beneficiary. You have to fill in Recipient ref., External Document No., or KID.';
        Text004: Label 'Currency payments are not used for domestic payments. Use Amount (LCY) for payments.';
        Text005: Label 'Field %1 is filled in, but can not be used for domestic payments.';
        Text006: Label 'LCY';
        Text007: Label 'Curency code LCY is specified. This is the local currency code, specified with <blank>.';
        Text009: Label 'Field %1 is filled in, but can not be used for payments abroad.';
        Text018: Label 'Transaction amount can not be negative.';
        Text026: Label 'Warning!';
        Text027: Label 'Note:';
        Text028: Label '<other accounts>';
        RemContract: Record "Remittance Agreement";
        RemAccount: Record "Remittance Account";
        GenLedgAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CurrentJnlLine: Record "Gen. Journal Line";
        StoreJnlFilters: Record "Gen. Journal Line";
        Currency: Record Currency;
        GenLedgSetup: Record "General Ledger Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        DimSetEntry: Record "Dimension Set Entry";
        RemittJournalCheckLine: Codeunit "Remitt. journal - Check line";
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        AccountName: Text[100];
        TransactionNo: Integer;
        StoreAgreementCode: Code[10];
        TransLineCounter: Integer;
        NumberOfPayments: Integer;
        TotalAmountLCY: Decimal;
        TransTotal: Decimal;
        SettleCounter: Integer;
        SettleNetChange: array[20] of Decimal;
        SettleNetChangeLCY: array[20] of Decimal;
        SettleBankAccountNo: array[20] of Code[20];
        SettleCurrencyCode: array[20] of Code[10];
        CurrExchRateText: Text[50];
        CurrExchrateShow: Decimal;
        CurrencyCodeShow: Code[10];
        ShowPaymentInfo: Boolean;
        ShowDim: Boolean;
        DimText: Text[120];
        Continue: Boolean;
        Text029: Label 'Bank name and adr. should be blank if the swift adr. is filled out. Filling out these fileds might be charged with the fee.';
        Text030: Label 'Swift address should always be filled out and must be filled out for payments within EU.';
        Text031: Label 'Recipients bank country/region code is mandatory if the swift address is not used.';
        Text032: Label 'Bank Code is used only if IBAN is not used, and recipient country/region is one of the following countries/regions: ''AU'',''CA'',''IE'',''GB'',''CH'',''ZA'',''DE'',''US'',''AT''';
        Text033: Label 'Field %1 is mandatory for payments abroad.';
        UnstructuredPaym: Boolean;
        Text037: Label 'It is not required to fill in %1 when the amount is below NOK %2, but recommended.';
        Text038: Label '%1 is missing. This field is required because %2 on line %3 is higher then %4.';
        NumberNo: Integer;
        PageNoCaptionLbl: Label 'Page';
        RemTestReportCaptionLbl: Label 'Remittance Test Report';
        RemAccCodeCaptionLbl: Label 'Remittance account';
        BankAccNoCaptionLbl: Label 'Bank account no.';
        RemContractCodeCaptionLbl: Label 'Remittance agreement';
        AccountNameCaptionLbl: Label 'Name';
        DocTypeCaptionLbl: Label 'D ty';
        PostingDateCaptionLbl: Label 'Posting date';
        TransactionNoCaptionLbl: Label 'TransactionNo';
        VendorNoCaptionLbl: Label 'Vendor no.';
        DomesticPaymentsCaptionLbl: Label 'Domestic payments';
        VendRecipientBankAccNoCaptionLbl: Label 'Recipient bank account no.';
        NOTUnstructuredPaymCaptionLbl: Label 'Structured payments';
        CurrencyCodeCaptionLbl: Label 'Currency code';
        AgreementCodeCaptionLbl: Label 'Agreement code';
        DimensionsCaptionLbl: Label 'Dimensions';
        TotalAmountLCYCaptionLbl: Label 'Total amount (LCY)';
        SettlementCaptionLbl: Label 'Settlement';
        SettleNetChangeLCYNumberCaptionLbl: Label 'Net change (LCY)';
        SettleNetChangeNumberCaptionLbl: Label 'Net change';
        RemittanceTypeIntValue: Integer;

    [Scope('OnPrem')]
    procedure SetJournal(GenJnlLine: Record "Gen. Journal Line")
    begin
        CurrentJnlLine := GenJnlLine;
    end;

    local procedure LineCheck(GenJnlLine: Record "Gen. Journal Line")
    var
        CheckError: array[50] of Text[250];
        CheckFatal: array[50] of Boolean;
        i: Integer;
    begin
        RemAccount.Get(GenJnlLine."Remittance Account Code");

        // Make sure the user doesn't confuse inland and abroad, + misc. control:
        if RemAccount.Type = RemAccount.Type::Domestic then begin
            // If KID or External Doc. No. is in use, the recipient ref. should be left empty:
            if (GenJnlLine.KID <> '') and
               ((GenJnlLine."Recipient Ref. 1" <> '') or
                (GenJnlLine."Recipient Ref. 2" <> '') or
                (GenJnlLine."Recipient Ref. 3" <> ''))
            then
                AdditionError(Text002, true);
            // Both KID and recipient ref. are empty, and there is no message for vendor:
            if (GenJnlLine.KID = '') and
               (GenJnlLine."External Document No." = '') and
               (GenJnlLine."Recipient Ref. 1" = '') and
               (GenJnlLine."Recipient Ref. 2" = '') and
               (GenJnlLine."Recipient Ref. 3" = '')
            then
                AdditionError(Text003, true);
            if GenJnlLine."Currency Code" <> '' then
                AdditionError(
                  StrSubstNo(Text004),
                  false);
            if GenJnlLine.Urgent then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption(Urgent)), false);
            if GenJnlLine."Agreed Exch. Rate" <> 0 then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Agreed Exch. Rate")), false);
            if GenJnlLine."Agreed With" <> '' then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Agreed With")), false);
            if GenJnlLine."Futures Contract No." <> '' then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Futures Contract No.")), false);
            if GenJnlLine."Futures Contract Exch. Rate" <> 0 then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Futures Contract Exch. Rate")), false);
            if GenJnlLine.Check <> 0 then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption(Check)), false);
            if GenJnlLine."Recipient Ref. Abroad" <> '' then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Recipient Ref. Abroad")), false);
            if GenJnlLine."Payment Type Code Abroad" <> '' then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Payment Type Code Abroad")), false);
            if GenJnlLine."Specification (Norges Bank)" <> '' then
                AdditionError(
                  StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Specification (Norges Bank)")), false);
        end else begin
            if GenJnlLine."Currency Code" = Text006 then
                AdditionError(Text007, true);
            if GenJnlLine."BOLS Text Code" <> 0 then
                AdditionError(
                  StrSubstNo(Text009,
                    GenJnlLine.FieldCaption("BOLS Text Code")), false);
            if GenJnlLine."Payment Type Code Domestic" <> '' then
                AdditionError(
                  StrSubstNo(Text009,
                    GenJnlLine.FieldCaption("Payment Type Code Domestic")), false);
            if GenJnlLine."Recipient Ref. 1" <> '' then
                AdditionError(
                  StrSubstNo(Text009,
                    GenJnlLine.FieldCaption("Recipient Ref. 1")), false);
            if GenJnlLine."Recipient Ref. 2" <> '' then
                AdditionError(
                  StrSubstNo(Text009,
                    GenJnlLine.FieldCaption("Recipient Ref. 2")), false);
            if GenJnlLine."Recipient Ref. 3" <> '' then
                AdditionError(
                  StrSubstNo(Text009,
                    GenJnlLine.FieldCaption("Recipient Ref. 3")), false);
            if Vendor.Get(GenJnlLine."Account No.") then;
            if (Vendor."Bank Name" <> '') and (Vendor."Bank Address 1" <> '') and
               (Vendor.SWIFT <> '')
            then
                AdditionError(Text029, false);

            if GenJnlLine."Currency Code" <> '' then begin
                Currency.Get(GenJnlLine."Currency Code");
                if Currency."EMU Currency" and (Vendor.SWIFT = '') then
                    AdditionError(Text030, false);
            end else
                if GenLedgSetup."EMU Currency" and (Vendor.SWIFT = '') then
                    AdditionError(Text030, false);

            if Vendor."Country/Region Code" = '' then
                AdditionError(
                  StrSubstNo(Text033,
                    Vendor.FieldCaption("Country/Region Code")), false);
            if (Vendor."Rcpt. Bank Country/Region Code" = '') and (Vendor.SWIFT = '') then
                AdditionError(Text031, false);
            if (Vendor."Recipient Bank Account No." <> '') and
               (CopyStr(Vendor."Recipient Bank Account No.", 1, 2) <> CopyStr(Vendor."Rcpt. Bank Country/Region Code", 1, 2))
            then
                if not (Vendor."Rcpt. Bank Country/Region Code" in ['AU', 'CA', 'IE', 'GB', 'CH', 'ZA', 'DE', 'US', 'AT']) then
                    AdditionError(Text032, false);
            if GenJnlLine."Payment Type Code Abroad" = '' then
                AdditionError(
                  StrSubstNo(Text033,
                    GenJnlLine.FieldCaption("Payment Type Code Abroad")), false);

            if (GenJnlLine."Specification (Norges Bank)" = '') and (PurchaseSetup."Amt. Spec limit to Norges Bank" > 0) then
                if GenJnlLine."Amount (LCY)" >= PurchaseSetup."Amt. Spec limit to Norges Bank" then
                    AdditionError(StrSubstNo(Text038, GenJnlLine.FieldCaption("Specification (Norges Bank)"),
                        GenJnlLine.FieldCaption("Amount (LCY)"),
                        Format(GenJnlLine."Line No."),
                        PurchaseSetup."Amt. Spec limit to Norges Bank"),
                      true)
                else
                    AdditionError(StrSubstNo(Text037, GenJnlLine.FieldCaption("Specification (Norges Bank)")
                        , PurchaseSetup."Amt. Spec limit to Norges Bank"), false)
        end;

        if RemittJournalCheckLine.Check(GenJnlLine, RemAccount, CheckError, CheckFatal) then
            for i := 1 to ArrayLen(CheckError) do
                if CheckError[i] <> '' then
                    AdditionError(CheckError[i], CheckFatal[i]);
    end;

    local procedure AdditionError(Text: Text[250]; Fatal: Boolean)
    begin
        ErrorCounter := ErrorCounter + 1;
        if Fatal then
            ErrorText[ErrorCounter] := CopyStr(Text026 + Text, 1, MaxStrLen(ErrorText[ErrorCounter]))
        else
            ErrorText[ErrorCounter] := CopyStr(Text027 + Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    local procedure SettleAccount(BankAccountNo: Code[20]; CurrencyCode: Code[10]; SettleAmount: Decimal; SettleAmountLCY: Decimal)
    var
        i: Integer;
    begin
        if BankAccountNo <> '' then begin
            i := 1;
            while
                  (i < SettleCounter) and
                  ((SettleBankAccountNo[i] <> BankAccountNo) or (SettleCurrencyCode[i] <> CurrencyCode))
            do
                i := i + 1;
            if (SettleBankAccountNo[i] = BankAccountNo) and (SettleCurrencyCode[i] = CurrencyCode) then begin
                SettleNetChange[i] := SettleNetChange[i] + SettleAmount;
                SettleNetChangeLCY[SettleCounter] := SettleNetChangeLCY[SettleCounter] + SettleAmountLCY;
            end else
                if SettleCounter < ArrayLen(SettleBankAccountNo) then begin
                    SettleCounter := SettleCounter + 1;
                    SettleBankAccountNo[SettleCounter] := BankAccountNo;
                    SettleCurrencyCode[SettleCounter] := CurrencyCode;
                    SettleNetChange[SettleCounter] := SettleNetChange[SettleCounter] + SettleAmount;
                    SettleNetChangeLCY[SettleCounter] := SettleNetChangeLCY[SettleCounter] + SettleAmountLCY;
                end else begin
                    SettleBankAccountNo[SettleCounter] := Text028;
                    SettleCurrencyCode[SettleCounter] := Text006;
                    SettleNetChange[SettleCounter] := SettleNetChange[SettleCounter] + SettleAmountLCY;
                    SettleNetChangeLCY[SettleCounter] := SettleNetChangeLCY[SettleCounter] + SettleAmountLCY;
                end;
        end;
    end;

    local procedure GetDimText(Number: Integer) DimText: Text[120]
    var
        OldDimText: Text[75];
    begin
        Clear(DimText);
        Continue := false;
        repeat
            OldDimText := DimText;
            if DimText = '' then
                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
            else
                DimText :=
                  StrSubstNo(
                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
            NumberNo := Number;
            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                DimText := OldDimText;
                NumberNo := Number;
                Continue := true;
                exit;
            end;
        until DimSetEntry.Next() = 0;
        exit(DimText);
    end;
}

