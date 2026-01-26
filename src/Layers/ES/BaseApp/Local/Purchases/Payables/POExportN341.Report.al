// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 7000060 "PO - Export N34.1"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Payables/POExportN341.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'PO - Export N34.1';
    Permissions = TableData "Cartera Doc." = rimd,
                  TableData "Payment Order" = m;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Payment Order"; "Payment Order")
        {
            DataItemTableView = sorting("No.") where("Elect. Pmts Exported" = const(false));
            RequestFilterFields = "No.";
            column(Payment_Order_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Cartera Doc."; "Cartera Doc.")
                {
                    DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                    DataItemLinkReference = "Payment Order";
                    DataItemTableView = sorting(Type, "Bill Gr./Pmt. Order No.", "Transfer Type", "Account No.") order(ascending) where(Type = const(Payable));
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
                    column(STRSUBSTNO_Text1100003_PayeeCCC_VendBankAccCode__ExportAmount_; StrSubstNo(Text1100003, PayeeCCC, VendBankAccCode, ExportAmount))
                    {
                    }
                    column(ExportAmount; ExportAmount)
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
                    column(DeliveryDate; Format(DeliveryDate))
                    {
                    }
                    column(OutputNo; OutputNo)
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
                    column(Cartera_Doc___Cartera_Doc___Description; Description)
                    {
                    }
                    column(Cartera_Doc___Cartera_Doc____Document_No__; "Document No.")
                    {
                    }
                    column(Cartera_Doc___Cartera_Doc____Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Cartera_Doc___Remaining_Amount_; "Remaining Amount")
                    {
                    }
                    column(ExportAmount_Control1100049; ExportAmount)
                    {
                        AutoFormatType = 1;
                    }
                    column(Cartera_Doc__Type; Type)
                    {
                    }
                    column(Cartera_Doc__Entry_No_; "Entry No.")
                    {
                    }
                    column(Cartera_Doc__Account_No_; "Account No.")
                    {
                    }
                    column(Cartera_Doc__Bill_Gr__Pmt__Order_No_; "Bill Gr./Pmt. Order No.")
                    {
                    }
                    column(To_Caption; To_CaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(Document_NumberCaption; Document_NumberCaptionLbl)
                    {
                    }
                    column(REMITTANCE_ADVICECaption; REMITTANCE_ADVICECaptionLbl)
                    {
                    }
                    column(Deposited_In_Caption; Deposited_In_CaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(Remittance_Advice_Number_Caption; Remittance_Advice_Number_CaptionLbl)
                    {
                    }
                    column(Settlement_Date_Caption; Settlement_Date_CaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(ExportAmountCaption; ExportAmountCaptionLbl)
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
                    column(Total_AmountCaption; Total_AmountCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        VendorBankAccount1: Record "Vendor Bank Account";
                    begin
                        if PreviousAccountNo <> "Account No." then begin
                            TestField("Account No.");
                            TestField("Payment Method Code");
                            DocType := DocMisc.DocType2("Payment Method Code");

                            ElectPmtMgmt.GetPayeeInfo("Account No.", VendorCCCBankNo, VendCCCBankBranchNo, VendCCCControlDigits, VendCCCAccNo,
                              PayeeAddress, PayeeCCC, IBAN, SwiftCode, "Transfer Type");

                            GetExportedAmount("Payment Order"."No.", "Account No.");

                            if (CopyTxt = '') and not CurrReport.Preview then begin
                                Vendor.Get("Account No.");
                                VATRegVend := Vendor."VAT Registration No.";
                                VATRegVend := VATRegVend + PadStr('', MaxStrLen(VATRegVend) - StrLen(VATRegVend), ' ');

                                if (ActualTransferType <> "Transfer Type") and
                                   ((TotalDoc10Vend <> 0) or (TotalDoc33Vend <> 0))
                                then
                                    case ActualTransferType of
                                        ActualTransferType::National:
                                            ElectPmtMgmt.InsertDomesticTrailer(TotalDoc10Vend, ElectPmtMgmt.EuroAmount(TotalAmountNAC));
                                        ActualTransferType::International:
                                            ElectPmtMgmt.InsertInterTransferTrailer(TotalDoc33Vend, ElectPmtMgmt.EuroAmount(TotalAmountInter));
                                    end;

                                case "Transfer Type" of
                                    "Transfer Type"::National:
                                        begin
                                            ActualTransferType := "Transfer Type"::National;
                                            ElectPmtMgmt.InsertDomesticTransferBlock(
                                              DocType, PmtOrderConcept, ExpensesCode, VATRegVend,
                                              ElectPmtMgmt.EuroAmount(ExportAmount), PayeeCCC, Vendor.Name);
                                            TotalDoc10Vend := TotalDoc10Vend + 1;
                                            TotalAmountNAC := TotalAmountNAC + ExportAmount;
                                        end;
                                    "Transfer Type"::International:
                                        begin
                                            ActualTransferType := "Transfer Type"::International;
                                            ElectPmtMgmt.InsertInterTransferBlock(
                                              PmtOrderConcept, ExpensesCode, ExpensesCodeValueInter, VATRegVend, IBAN,
                                              ElectPmtMgmt.EuroAmount(ExportAmount),
                                              Format(VendorBankAccount."Country/Region Code"), SwiftCode, Vendor.Name);
                                            TotalDoc33Vend := TotalDoc33Vend + 1;
                                            TotalAmountInter := TotalAmountInter + ExportAmount;
                                        end;
                                    else
                                        Error(Text1100002, "Entry No.", "Account No.", "Document No.", "Bill Gr./Pmt. Order No.");
                                end;
                                if "Document Type" = "Document Type"::Bill then
                                    DocumentType := DocumentType::Bill
                                else
                                    DocumentType := DocumentType::Invoice;
                                if DocType = '4' then
                                    ElectPmtMgmt.InsertIntoCheckLedger(BankAccount."No.", DeliveryDate, DocumentType, "Document No.",
                                      Description, "Payment Order"."Bank Account No.", ExportAmount, RecordId);
                            end;
                        end;
                        "Elect. Pmts Exported" := true;
                        "Export File Name" := EPayExportFilePath;
                        "Document No." := BankAccount."Last Remittance Advice No.";
                        Modify();
                        PreviousAccountNo := "Account No.";

                        VendorBankAccount1.Reset();
                        VendorBankAccount1.SetRange("Vendor No.", "Account No.");
                        VendorBankAccount1.SetRange("Use For Electronic Payments", true);
                        if VendorBankAccount1.FindFirst() then begin
                            TempVendCCCControlDigits := VendorBankAccount1."CCC Control Digits";
                            TempVendCCCAccNo := VendorBankAccount1."CCC Bank Account No.";
                            TempUserText :=
                              StrSubstNo(
                                Text1100003,
                                ConvertStr(PadStr(VendorBankAccount1."CCC Bank No.", 4, ' '), ' ', '0') +
                                ConvertStr(PadStr(VendorBankAccount1."CCC Bank Branch No.", 4, ' '), ' ', '0') +
                                PadStr(VendorBankAccount1."CCC Control Digits", 2, ' ') +
                                ConvertStr(PadStr(VendorBankAccount1."CCC Bank Account No.", 10, ' '), ' ', '0'),
                                VendBankAccCode,
                                Format(-ExportAmount));
                        end;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if (CopyTxt = '') and not CurrReport.Preview then begin
                            case ActualTransferType of
                                ActualTransferType::National:
                                    ElectPmtMgmt.InsertDomesticTrailer(TotalDoc10Vend, ElectPmtMgmt.EuroAmount(TotalAmountNAC));
                                ActualTransferType::International:
                                    ElectPmtMgmt.InsertInterTransferTrailer(TotalDoc33Vend, ElectPmtMgmt.EuroAmount(TotalAmountInter));
                            end;

                            ElectPmtMgmt.InsertGeneralTrailer(
                                TotalDoc10Vend + TotalDoc33Vend, TotalAmountNAC + TotalAmountInter, SilentMode, SilentModeFileName);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreviousAccountNo := '';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then // Original
                        Clear(CopyTxt)
                    else begin
                        CopyTxt := Text1100000;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoOfCopies + 1);

                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalAmount := 0;
                Amount := 0;
                TotalDoc10Vend := 0;
                TotalDoc33Vend := 0;
                TotalAmountInter := 0;
                AmountPaid := 0;
                TotalAmountPaid := 0;

                TestField("Currency Code", '');
                TestField("Export Electronic Payment");
                TestField("Bank Account No.");
                BankAccount.Get("Bank Account No.");
                BankAccount.CalcFields(Balance);
                if BankAccount.Balance < 0 then
                    if not Confirm(Text1100004, false, BankAccount."No.", BankAccount.Name, BankAccount.Balance) then
                        CurrReport.Quit();

                ElectPmtMgmt.GetCCCBankInfo("Bank Account No.",
                  CCCBankNo, CCCBankBranchNo, CCCControlDigits, CCCAccNo);

                if (CopyTxt = '') and not CurrReport.Preview then begin
                    if CheckErrors then
                        Relat := '1'
                    else
                        Relat := '0';

                    ElectPmtMgmt.GetLastEPayFileCreation(EPayExportFilePath, BankAccount);

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

                if not CurrReport.Preview then begin
                    ElectPmtMgmt.InsertHeaderRecType1(DeliveryDate, "Posting Date",
                      CCCBankNo + CCCBankBranchNo + CCCControlDigits + CCCAccNo, Relat);
                    ElectPmtMgmt.InsertHeaderRecType2();
                    ElectPmtMgmt.InsertHeaderRecType3();
                    ElectPmtMgmt.InsertHeaderRecType4();
                    "Elect. Pmts Exported" := true;
                    Modify();
                end;
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
                    field(DeliveryDate; DeliveryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delivery Date';
                        ToolTip = 'Specifies a number to identify the operations declaration.';
                    }
                    field(ExpensesCode; ExpensesCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Expenses Code';
                        OptionCaption = 'Payer,Payee';
                        ToolTip = 'Specifies who is responsible for the payment expenses, the payer or the payee.';
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
                    field(ExpensesCodeValueInter; ExpensesCodeValueInter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Shared (Only International Transf.)';
                        ToolTip = 'Specifies if you want to share the expenses between the payer and the payee. This is only applicable for international transfers.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DeliveryDate = 0D then
                DeliveryDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SilentMode := false;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        TotalDoc10Vend := 0;
        TotalDoc33Vend := 0;
    end;

    trigger OnPostReport()
    begin
        if not (CurrReport.Preview() or SilentMode) then
            ElectPmtMgmt.DownloadFile();
    end;

    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        DocMisc: Codeunit "Document-Misc";
        FormatAddr: Codeunit "Format Address";
        ElectPmtMgmt: Codeunit "Elect. Pmts Management";
        CheckErrors: Boolean;
        ExpensesCodeValueInter: Boolean;
        VendBankAccCode: Code[20];
        DocType: Code[10];
        CopyTxt: Code[10];
        DeliveryDate: Date;
        TotalAmount: Decimal;
        TotalDoc10Vend: Decimal;
        TotalDoc33Vend: Decimal;
        TotalAmountInter: Decimal;
        AmountPaid: Decimal;
        TotalAmountPaid: Decimal;
        ExportAmount: Decimal;
        NoOfCopies: Integer;
        ExpensesCode: Option Payer,Payee;
        PmtOrderConcept: Option Payroll,RetPayroll,Others;
        ActualTransferType: Option National,International,Special;
        DocumentType: Enum "Gen. Journal Document Type";
        VATRegVend: Text[12];
        CCCBankBranchNo: Text[4];
        CCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        CCCBankNo: Text[4];
        VendCCCBankBranchNo: Text[4];
        VendCCCControlDigits: Text[2];
        VendCCCAccNo: Text[10];
        VendorCCCBankNo: Text[4];
        PayeeCCC: Text[20];
        Relat: Text[1];
        IBAN: Text[34];
        SwiftCode: Text[11];
        Text1100000: Label 'COPY';
        Text1100001: Label 'REM001';
        Text1100002: Label 'Special Transfers are not allowed from Cartera. Please remove Entry No. %1, Account No. %2, Document No. %3 from Payment Order No. %4 and try again.';
        CompanyAddr: array[8] of Text[100];
        PayeeAddress: array[8] of Text[100];
        Text1100003: Label 'We would like to inform you that your Account Number %1, in %2 Bank was credited for the Amount of %3 to settle these transactions:';
        LastRemittanceAdvNo: Text[20];
        EPayExportFilePath: Text[250];
        Text1100004: Label 'Bank %1 - %2, has an overdue balance of %3. Do you still want to record the amount?';
        OutputNo: Integer;
        TempVendCCCAccNo: Text[30];
        TempVendCCCControlDigits: Text[30];
        TempUserText: Text[1024];
        PreviousAccountNo: Code[20];
        TotalAmountNAC: Decimal;
        To_CaptionLbl: Label 'To:';
        DescriptionCaptionLbl: Label 'Description';
        Document_NumberCaptionLbl: Label 'Document Number';
        REMITTANCE_ADVICECaptionLbl: Label 'REMITTANCE ADVICE';
        Deposited_In_CaptionLbl: Label 'Deposited In:';
        DateCaptionLbl: Label 'Date';
        Remittance_Advice_Number_CaptionLbl: Label 'Remittance Advice Number:';
        Settlement_Date_CaptionLbl: Label 'Settlement Date:';
        AmountCaptionLbl: Label 'Amount';
        ExportAmountCaptionLbl: Label 'Deposit Amount:';
        Vendor_CCC_Bank_No_CaptionLbl: Label 'Vendor CCC Bank No.';
        Vendor_CCC_Bank_Branch_No_CaptionLbl: Label 'Vendor CCC Bank Branch No.';
        Vendor_CCC_Control_DigitsCaptionLbl: Label 'Vendor CCC Control Digits';
        Vendor_CCC_Account_No_CaptionLbl: Label 'Vendor CCC Account No.';
        Total_AmountCaptionLbl: Label 'Total Amount';
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure GetExportedAmount(PmtOrderNo: Code[20]; CustVendAccNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code", Accepted, "Due Date");
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PmtOrderNo);
        CarteraDoc.SetRange("Account No.", CustVendAccNo);
        ExportAmount := 0;
        if CarteraDoc.Find('-') then
            repeat
                ExportAmount := ExportAmount + CarteraDoc."Remaining Amount";
            until CarteraDoc.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure EnableSilentMode(FileName: Text)
    begin
        SilentMode := true;
        SilentModeFileName := FileName;
    end;
}

