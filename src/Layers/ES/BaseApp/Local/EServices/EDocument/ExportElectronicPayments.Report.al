// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10721 "Export Electronic Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/EServices/EDocument/ExportElectronicPayments.rdlc';
    Caption = 'Export Electronic Payments';

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Bank Payment Type" = const("Electronic Payment"), "Exported to Payment File" = const(false), "Document Type" = const(Payment));
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
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Applies-to ID" = field("Applies-to ID");
                    DataItemLinkReference = "Gen. Journal Line";
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") order(descending) where(Open = const(true));
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
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
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
                    column(STRSUBSTNO_Text1100003_PayeeCCC_VendBankAccCode__ExportAmount_; StrSubstNo(Text1100003, PayeeCCC, VendBankAccCode, -ExportAmount))
                    {
                    }
                    column(VendorCCCBankNo; VendorCCCBankNo)
                    {
                    }
                    column(VendCCCBankBranchNo; VendCCCBankBranchNo)
                    {
                    }
                    column(VendCCCControlDigits; VendCCCControlDigits)
                    {
                    }
                    column(VendCCCAccNo; VendCCCAccNo)
                    {
                    }
                    column(LastRemittanceAdvNo; LastRemittanceAdvNo)
                    {
                    }
                    column(SettleDate; Format(SettleDate))
                    {
                    }
                    column(ExportAmount; -ExportAmount)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(Vendor_Ledger_Entry__Vendor_Ledger_Entry___Document_No__; "Vendor Ledger Entry"."Document No.")
                    {
                    }
                    column(Vendor_Ledger_Entry__Vendor_Ledger_Entry__Description; "Vendor Ledger Entry".Description)
                    {
                    }
                    column(Vendor_Ledger_Entry__Vendor_Ledger_Entry___Document_Date_; Format("Vendor Ledger Entry"."Document Date"))
                    {
                    }
                    column(AmountPaid; AmountPaid)
                    {
                    }
                    column(TempUserText; TempUserText)
                    {
                    }
                    column(TempVendCCCAccNo; TempVendCCCAccNo)
                    {
                    }
                    column(TempVendCCCControlDigits; TempVendCCCControlDigits)
                    {
                    }
                    column(ExportAmount_Control1101100048; -ExportAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Applies_to_ID; "Applies-to ID")
                    {
                    }
                    column(To_Caption; To_CaptionLbl)
                    {
                    }
                    column(REMITTANCE_ADVICECaption; REMITTANCE_ADVICECaptionLbl)
                    {
                    }
                    column(Deposited_In_Caption; Deposited_In_CaptionLbl)
                    {
                    }
                    column(Remittance_Advice_Number_Caption; Remittance_Advice_Number_CaptionLbl)
                    {
                    }
                    column(Settlement_Date_Caption; Settlement_Date_CaptionLbl)
                    {
                    }
                    column(Vendor_CCC_Bank_No_Caption; Vendor_CCC_Bank_No_CaptionLbl)
                    {
                    }
                    column(Vendor_CCC_Bank_Branch_No_Caption; Vendor_CCC_Bank_Branch_No_CaptionLbl)
                    {
                    }
                    column(Vendor_CCC_Control_DigitsCaption; Vendor_CCC_Control_DigitsCaptionLbl)
                    {
                    }
                    column(Vendor_CCC_Account_No_Caption; Vendor_CCC_Account_No_CaptionLbl)
                    {
                    }
                    column(Document_NumberCaption; Document_NumberCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(ExportAmountCaption; ExportAmountCaptionLbl)
                    {
                    }
                    column(Total_AmountCaption; Total_AmountCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        VendorBankAccount1: Record "Vendor Bank Account";
                    begin
                        if "Gen. Journal Line"."Applies-to ID" <> '' then begin
                            CalcFields("Remaining Amt. (LCY)");
                            if (-ExportAmount - TotalAmountPaid) > -"Remaining Amt. (LCY)" then
                                AmountPaid := -"Remaining Amt. (LCY)"
                            else
                                AmountPaid := -ExportAmount - TotalAmountPaid;
                            TotalAmountPaid := TotalAmountPaid + AmountPaid;
                        end else
                            if "Gen. Journal Line"."Applies-to Doc. No." <> '' then begin
                                Reset();
                                SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                                SetRange("Document Type", "Gen. Journal Line"."Applies-to Doc. Type");
                                SetRange("Document No.", "Gen. Journal Line"."Applies-to Doc. No.");
                                SetRange("Bill No.", "Gen. Journal Line"."Applies-to Bill No.");
                                SetRange("Vendor No.", Vendor."No.");
                                SetRange(Open, true);
                                Find('-');
                                CalcFields("Remaining Amt. (LCY)");
                                if -ExportAmount > -VendLedgEntry."Remaining Amt. (LCY)" then
                                    AmountPaid := -VendLedgEntry."Remaining Amt. (LCY)"
                                else
                                    AmountPaid := -ExportAmount;
                            end;

                        VendorBankAccount1.Reset();
                        VendorBankAccount1.SetRange("Vendor No.", "Gen. Journal Line"."Account No.");
                        VendorBankAccount1.SetRange("Use For Electronic Payments", true);
                        if VendorBankAccount1.FindFirst() then begin
                            TempVendCCCControlDigits := VendorBankAccount1."CCC Control Digits";
                            TempVendCCCAccNo := VendorBankAccount1."CCC Bank Account No.";
                            TempUserText :=
                              StrSubstNo(
                                Text1100003,
                                Format(VendorBankAccount1."CCC Bank No.") +
                                Format(VendorBankAccount1."CCC Bank Branch No.") +
                                Format(VendorBankAccount1."CCC Control Digits") +
                                Format(VendorBankAccount1."CCC Bank Account No."),
                                VendBankAccCode,
                                Format(-ExportAmount, 0, 0));
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if ("Gen. Journal Line"."Applies-to ID" = '') and ("Gen. Journal Line"."Applies-to Doc. No." = '') then
                            CurrReport.Break();

                        if "Gen. Journal Line"."Account Type" <> "Gen. Journal Line"."Account Type"::Vendor then
                            CurrReport.Break();
                        SetRange("Vendor No.", "Gen. Journal Line"."Account No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin// Original
                        Clear(CopyTxt);
                        CopyTxt := '';
                    end else begin
                        CopyTxt := Text1100000;
                        OutputNo += 1;
                    end;

                    AmountPaid := 0;
                    TotalAmountPaid := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoOfCopies + 1);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                DocMisc: Codeunit "Document-Misc";
                DocType: Code[10];
            begin
                TestField("Document No.");
                TestField("Account Type", "Account Type"::Vendor);
                TestField("Account No.");
                TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                TestField("Bal. Account No.");
                TestField("Currency Code", '');
                DocType := DocMisc.DocType2("Payment Method Code");
                if "Gen. Journal Line"."Document Type" <> "Gen. Journal Line"."Document Type"::Payment then
                    TestField("Payment Type", 0);

                if Amount < 0 then
                    FieldError(Amount, StrSubstNo(Text1100002, FieldCaption("Bank Payment Type"), Format("Bank Payment Type")));

                ElectPmtMgmt.GetPayeeInfo("Account No.", VendorCCCBankNo, VendCCCBankBranchNo, VendCCCControlDigits,
                  VendCCCAccNo, PayeeAddress, PayeeCCC, IBAN, SwiftCode, "Transfer Type");

                Vendor.Get("Account No.");
                CalcAmountPaid("Gen. Journal Line");

                if not CurrReport.Preview then begin
                    VATRegVend := Vendor."VAT Registration No.";
                    VATRegVend := VATRegVend + PadStr('', MaxStrLen(VATRegVend) - StrLen(VATRegVend), ' ');

                    if MatchSettleDate = MatchSettleDate::ChangeToMatch then
                        "Posting Date" := SettleDate;

                    if ActualTransferType <> "Gen. Journal Line"."Transfer Type" then
                        case ActualTransferType of
                            ActualTransferType::National:
                                ElectPmtMgmt.InsertDomesticTrailer(TotalDoc10Vend, ElectPmtMgmt.EuroAmount(TotalAmountNac));
                            ActualTransferType::International:
                                ElectPmtMgmt.InsertInterTransferTrailer(TotalDoc33Vend, ElectPmtMgmt.EuroAmount(TotalAmountInter));
                        end;

                    case "Transfer Type" of
                        "Transfer Type"::National:
                            begin
                                ActualTransferType := "Transfer Type"::National;
                                ElectPmtMgmt.InsertDomesticTransferBlock(DocType, PmtOrderConcept, ExpensesCode, VATRegVend,
                                  ElectPmtMgmt.EuroAmount(Amount), PayeeCCC, Vendor.Name);
                                TotalDoc10Vend := TotalDoc10Vend + 1;
                                TotalAmountNac := TotalAmountNac + Amount;
                            end;
                        "Transfer Type"::International:
                            begin
                                ActualTransferType := "Transfer Type"::International;
                                ElectPmtMgmt.InsertInterTransferBlock(PmtOrderConcept, ExpensesCode, ExpensesCodeValueInter, VATRegVend, IBAN,
                                  ElectPmtMgmt.EuroAmount(Amount), Format(VendorBankAccount."Country/Region Code"), SwiftCode, Vendor.Name);
                                TotalDoc33Vend := TotalDoc33Vend + 1;
                                TotalAmountInter := TotalAmountInter + Amount;
                            end;
                        "Transfer Type"::Special:
                            begin
                                TestField("Payment Type");
                                TestField("Statistical Code");
                                ActualTransferType := "Gen. Journal Line"."Transfer Type"::Special;
                                ElectPmtMgmt.InsertSpecialTransferBlock(PmtOrderConcept, ExpensesCode, VATRegVend, IBAN, ElectPmtMgmt.EuroAmount(Amount),
                                  Format(VendorBankAccount."Country/Region Code"), SwiftCode, Vendor.Name, Description,
                                  "Payment Type", "Statistical Code", PadStr(' ', 9, ' '), PadStr(' ', 8, ' '), PadStr(' ', 12, ' '));
                                TotalDoc43Vend := TotalDoc43Vend + 1;
                                TotalAmountSpecial := TotalAmountSpecial + Amount;
                            end;
                    end;

                    "Exported to Payment File" := true;
                    "Export File Name" := EPayExportFilePath;
                    "Document No." := BankAccount."Last Remittance Advice No.";
                    Modify();
                    if ("Payment Method Code" <> '') and (DocMisc.DocType2("Payment Method Code") = '4') then
                        ElectPmtMgmt.InsertIntoCheckLedger(BankAccount."No.", SettleDate, "Document Type", "Document No.",
                          Description, "Bal. Account No.", -ExportAmount, RecordId);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if not CurrReport.Preview then begin
                    case ActualTransferType of
                        ActualTransferType::National:
                            ElectPmtMgmt.InsertDomesticTrailer(TotalDoc10Vend, ElectPmtMgmt.EuroAmount(TotalAmountNac));
                        ActualTransferType::International:
                            ElectPmtMgmt.InsertInterTransferTrailer(TotalDoc33Vend, ElectPmtMgmt.EuroAmount(TotalAmountInter));
                        ActualTransferType::Special:
                            ElectPmtMgmt.InsertSpecialTransTrailer(TotalDoc43Vend, ElectPmtMgmt.EuroAmount(TotalAmountSpecial));
                    end;
                    ElectPmtMgmt.InsertGeneralTrailer(
                      TotalDoc10Vend + TotalDoc33Vend + TotalDoc43Vend, TotalAmountNac + TotalAmountInter + TotalAmountSpecial, false, '');
                end;
            end;

            trigger OnPreDataItem()
            begin
                TestField("Bal. Account No.");
                BankAccount.Get("Gen. Journal Line"."Bal. Account No.");

                ElectPmtMgmt.GetCCCBankInfo("Gen. Journal Line"."Bal. Account No.", CCCBankNo, CCCBankBranchNo,
                  CCCControlDigits, CCCAccNo);

                if not CurrReport.Preview then begin
                    BankAccount.CalcFields(Balance);
                    if not "Gen. Journal Line"."Exported to Payment File" then
                        if BankAccount.Balance < 0 then
                            if not Confirm(Text1100004, false, BankAccount."No.", BankAccount.Name, BankAccount.Balance) then
                                CurrReport.Quit();

                    if CheckErrors then
                        Relat := '1'
                    else
                        Relat := '0';

                    if MatchSettleDate = MatchSettleDate::SkipNotMatch then
                        SetRange("Posting Date", SettleDate);

                    ElectPmtMgmt.GetLastEPayFileCreation(EPayExportFilePath, BankAccount);

                    ElectPmtMgmt.InsertHeaderRecType1(SettleDate, SettleDate,
                      CCCBankNo + CCCBankBranchNo + CCCControlDigits + CCCAccNo, Relat);

                    ElectPmtMgmt.InsertHeaderRecType2();

                    ElectPmtMgmt.InsertHeaderRecType3();

                    ElectPmtMgmt.InsertHeaderRecType4();

                    if BankAccount."Last Remittance Advice No." <> '' then
                        BankAccount."Last Remittance Advice No." := IncStr(BankAccount."Last Remittance Advice No.")
                    else
                        BankAccount."Last Remittance Advice No." := Text1100001;
                    LastRemittanceAdvNo := BankAccount."Last Remittance Advice No.";
                    BankAccount.Modify();
                end else
                    if BankAccount."Last Remittance Advice No." <> '' then
                        LastRemittanceAdvNo := IncStr(BankAccount."Last Remittance Advice No.")
                    else
                        LastRemittanceAdvNo := Text1100001;

                SetCurrentKey("Journal Template Name", "Journal Batch Name", "Transfer Type");
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
                    field("""Gen. Journal Line"".""Bal. Account No."""; "Gen. Journal Line"."Bal. Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        LookupPageID = "Bank Account List";
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the number of the bank account.';
                    }
                    field(SettleDate; SettleDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settle Date';
                        ToolTip = 'Specifies the date that the export will be transmitted to the bank. This date will be the posting date for the payment journal entries that are exported.';
                    }
                    field(MatchSettleDate; MatchSettleDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If Posting Date does not match Delivery Date:';
                        OptionCaption = 'Change Posting Date To Match,Skip Lines Which Do Not Match';
                        ToolTip = 'Specifies if you want to match the settlement date, or if you want to skip any payment journal lines where the entered posting date does not match the settlement date.';
                    }
                    group(Control1100020)
                    {
                        ShowCaption = false;
                        field(ExpensesCode; ExpensesCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Expenses Code';
                            OptionCaption = 'Payer,Payee';
                            ToolTip = 'Specifies who is responsible for the payment expenses, the payer or the payee.';
                        }
                        field(ExpensesCodeValueInter; ExpensesCodeValueInter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Shared (Only International Transf.)';
                            ToolTip = 'Specifies if you want to share the expenses between the payer and the payee. This is only applicable for international transfers.';
                        }
                    }
                    field(PmtOrderConcept; PmtOrderConcept)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Order Concept';
                        OptionCaption = 'Payroll,Retirement Payroll,Others';
                        ToolTip = 'Specifies the payment order concept.';
                    }
                    field(CheckErrors; CheckErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Relation';
                        ToolTip = 'Specifies if you want the bank to send you a detailed list of all transfer charges. Deselect the check box if you want a simple total of charges for all the transfers made.';
                    }
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number Of Copies';
                        ToolTip = 'Specifies the number of additional copies of the remittance advice that will be printed by this process. One document is always printed so that it can be mailed to the payee.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if SettleDate = 0D then
                SettleDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        TotalDoc10Vend := 0;
        TotalDoc33Vend := 0;
        TotalDoc43Vend := 0;
    end;

    var
        BankAccount: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendLedgEntry: Record "Vendor Ledger Entry";
        FormatAddr: Codeunit "Format Address";
        ElectPmtMgmt: Codeunit "Elect. Pmts Management";
        CheckErrors: Boolean;
        ExpensesCodeValueInter: Boolean;
        VendBankAccCode: Code[20];
        CopyTxt: Code[10];
        SettleDate: Date;
        TotalDoc10Vend: Decimal;
        TotalDoc33Vend: Decimal;
        TotalDoc43Vend: Decimal;
        TotalAmountNac: Decimal;
        TotalAmountInter: Decimal;
        TotalAmountSpecial: Decimal;
        AmountPaid: Decimal;
        TotalAmountPaid: Decimal;
        ExportAmount: Decimal;
        NoOfCopies: Integer;
        MatchSettleDate: Option ChangeToMatch,SkipNotMatch;
        ActualTransferType: Option National,International,Special;
        ExpensesCode: Option Payer,Payee;
        PmtOrderConcept: Option Payroll,RetPayroll,Others;
        VATRegVend: Text[12];
        VendCCCBankBranchNo: Text[4];
        VendCCCControlDigits: Text[2];
        VendCCCAccNo: Text[10];
        VendorCCCBankNo: Text[4];
        PayeeCCC: Text[20];
        CCCBankBranchNo: Text[4];
        CCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        CCCBankNo: Text[4];
        Relat: Text[1];
        IBAN: Text[34];
        SwiftCode: Text[11];
        EPayExportFilePath: Text[150];
        PayeeAddress: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Text1100000: Label 'COPY';
        Text1100001: Label 'REM001';
        Text1100002: Label 'must be positive when %1 is %2';
        Text1100003: Label 'We would like to inform you that your Account Number %1, in %2 Bank was credited for the Amount of %3 to settle these transactions:';
        LastRemittanceAdvNo: Text[20];
        Text1100004: Label 'Bank %1 - %2, has an overdue balance of %3. Do you still want to record the amount?';
        TempVendCCCAccNo: Text[30];
        TempVendCCCControlDigits: Text[30];
        TempUserText: Text[1024];
        OutputNo: Integer;
        To_CaptionLbl: Label 'To:';
        REMITTANCE_ADVICECaptionLbl: Label 'REMITTANCE ADVICE';
        Deposited_In_CaptionLbl: Label 'Deposited In:';
        Remittance_Advice_Number_CaptionLbl: Label 'Remittance Advice Number:';
        Settlement_Date_CaptionLbl: Label 'Settlement Date:';
        Vendor_CCC_Bank_No_CaptionLbl: Label 'Vendor CCC Bank No.';
        Vendor_CCC_Bank_Branch_No_CaptionLbl: Label 'Vendor CCC Bank Branch No.';
        Vendor_CCC_Control_DigitsCaptionLbl: Label 'Vendor CCC Control Digits';
        Vendor_CCC_Account_No_CaptionLbl: Label 'Vendor CCC Account No.';
        Document_NumberCaptionLbl: Label 'Document Number';
        DescriptionCaptionLbl: Label 'Description';
        DateCaptionLbl: Label 'Date';
        AmountCaptionLbl: Label 'Amount';
        ExportAmountCaptionLbl: Label 'Deposit Amount:';
        Total_AmountCaptionLbl: Label 'Total Amount';

    [Scope('OnPrem')]
    procedure CalcAmountPaid(GenJnlLine: Record "Gen. Journal Line")
    begin
        ExportAmount := -GenJnlLine."Amount (LCY)";
        AmountPaid := 0;

        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.FindFirst();
            VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
            if -ExportAmount > -VendLedgEntry."Remaining Amt. (LCY)" then
                AmountPaid := -VendLedgEntry."Remaining Amt. (LCY)"
            else
                AmountPaid := -ExportAmount;
        end;
    end;

    internal procedure GetEPayFileContent(var TempBlob: Codeunit "Temp Blob")
    begin
        ElectPmtMgmt.GetFileContent(TempBlob);
    end;

    internal procedure GetEPayFileName(): Text[150]
    begin
        exit(EPayExportFilePath);
    end;
}

