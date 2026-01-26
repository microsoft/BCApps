// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Globalization;

report 11000004 Docket
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/Docket.rdlc';
    Caption = 'Docket';

    dataset
    {
        dataitem("Payment History"; "Payment History")
        {
            RequestFilterFields = "Print Docket", "Run No.", Status, "Creation Date", "Sent On";
            column(OurBank_PaymentHistory; "Our Bank")
            {
            }
            column(RunNo_PaymentHistory; "Run No.")
            {
            }
            column(PageCaption; StrSubstNo(Text1000001, ' '))
            {
            }
            column(CompInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(CompInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompInfoGiroNo; CompanyInfo."Giro No.")
            {
            }
            column(CompInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(CompInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompInfoVATRegNoCaption; CompInfoVATRegNoCaptionLbl)
            {
            }
            column(CompInfoGiroNoCaption; CompInfoGiroNoCaptionLbl)
            {
            }
            column(CompInfoBankNameCaption; CompInfoBankNameCaptionLbl)
            {
            }
            column(CompInfoBankAccountNoCaption; CompInfoBankAccountNoCaptionLbl)
            {
            }
            column(CompInfoFaxNoCaption; CompInfoFaxNoCaptionLbl)
            {
            }
            column(CompInfoPhoneNoCaption; CompInfoPhoneNoCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            dataitem("Payment History Line"; "Payment History Line")
            {
                DataItemLink = "Our Bank" = field("Our Bank"), "Run No." = field("Run No.");
                DataItemTableView = sorting("Our Bank", Status, "Run No.", Order, Date);
                RequestFilterFields = Docket, "Run No.", "Account Type", "Account No.", Date;
                column(LineNo_PaymentHistoryLine; "Line No.")
                {
                }
                column(OurBank_PaymentHistoryLine; "Our Bank")
                {
                }
                column(RunNo_PaymentHistoryLine; "Run No.")
                {
                }
                column(AccNo_PaymentHistoryLine; "Account No.")
                {
                }
                column(DocketCaption; DocketCaptionLbl)
                {
                }
                dataitem(Customer; Customer)
                {
                    DataItemLink = "No." = field("Account No.");
                    DataItemTableView = sorting("No.");
                    column(CustAddr8; CustAddr[7])
                    {
                    }
                    column(CustAddr7; CustAddr[8])
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(No_Cust; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                        CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");

                        FormatAddr.Customer(CustAddr, Customer);
                        Cust.Get(Customer."No.", "Payment History Line".Bank);
                        YourBank := Cust.Name;
                        YourAccount := Cust."Bank Account No.";
                        YourIBAN := Cust.IBAN;
                        YourSWIFTCode := Cust."SWIFT Code";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if "Payment History Line"."Account Type" <> "Detail Line"."Account Type"::Customer then
                            CurrReport.Break();
                    end;
                }
                dataitem(Vendor; Vendor)
                {
                    DataItemLink = "No." = field("Account No.");
                    DataItemTableView = sorting("No.");
                    column(VendAddr7; VendAddr[7])
                    {
                    }
                    column(VendAddr8; VendAddr[8])
                    {
                    }
                    column(VendAddr6; VendAddr[6])
                    {
                    }
                    column(VendAddr5; VendAddr[5])
                    {
                    }
                    column(VendAddr4; VendAddr[4])
                    {
                    }
                    column(VendAddr3; VendAddr[3])
                    {
                    }
                    column(VendAddr2; VendAddr[2])
                    {
                    }
                    column(VendAddr1; VendAddr[1])
                    {
                    }
                    column(No_Vend; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                        CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");

                        FormatAddr.Vendor(VendAddr, Vendor);
                        VendBank.Get(Vendor."No.", "Payment History Line".Bank);
                        YourBank := VendBank.Name;
                        YourAccount := VendBank."Bank Account No.";
                        YourIBAN := VendBank.IBAN;
                        YourSWIFTCode := VendBank."SWIFT Code";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if "Payment History Line"."Account Type" <> "Detail Line"."Account Type"::Vendor then
                            CurrReport.Break();
                    end;
                }
                dataitem(Employee; Employee)
                {
                    DataItemLink = "No." = field("Account No.");
                    DataItemTableView = sorting("No.");
                    column(EmplAddr7; EmplAddr[7])
                    {
                    }
                    column(EmplAddr8; EmplAddr[8])
                    {
                    }
                    column(EmplAddr6; EmplAddr[6])
                    {
                    }
                    column(EmplAddr5; EmplAddr[5])
                    {
                    }
                    column(EmplAddr4; EmplAddr[4])
                    {
                    }
                    column(EmplAddr3; EmplAddr[3])
                    {
                    }
                    column(EmplAddr2; EmplAddr[2])
                    {
                    }
                    column(EmplAddr1; EmplAddr[1])
                    {
                    }
                    column(No_Empl; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        CountryRegionTranslation: Record "Country/Region Translation";
                    begin
                        if CountryRegionTranslation.Get("Country/Region Code") then
                            CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault(CountryRegionTranslation."Language Code")
                        else
                            CurrReport.Language := ReportLanguage;

                        FormatAddr.Employee(EmplAddr, Employee);
                        YourBank := "No.";
                        YourAccount := "Bank Account No.";
                        YourIBAN := IBAN;
                        YourSWIFTCode := "SWIFT Code";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if "Payment History Line"."Account Type" <> "Detail Line"."Account Type"::Employee then
                            CurrReport.Break();
                    end;
                }
                dataitem("Bank Account"; "Bank Account")
                {
                    DataItemLink = "No." = field("Our Bank");
                    DataItemTableView = sorting("No.");
                    column(BankAccNo_BankAcc; "Bank Account No.")
                    {
                    }
                    column(YourAccount; YourAccount)
                    {
                    }
                    column(PmtHistLineDate; Format("Payment History Line".Date))
                    {
                    }
                    column(PmtHistLineAmt; Abs("Payment History Line".Amount))
                    {
                        AutoFormatExpression = "Payment History Line"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PmtHistLineIdentification; "Payment History Line".Identification)
                    {
                    }
                    column(PmtHistLineDescription4; "Payment History Line"."Description 4")
                    {
                    }
                    column(PmtHistLineDescription3; "Payment History Line"."Description 3")
                    {
                    }
                    column(PmtHistLineDescription2; "Payment History Line"."Description 2")
                    {
                    }
                    column(PmtHistLineDescription1; "Payment History Line"."Description 1")
                    {
                    }
                    column(PmtHistLineCurrCode; "Payment History Line"."Currency Code")
                    {
                    }
                    column(No_BankAcc; "No.")
                    {
                    }
                    column(IBAN_BankAcc; IBAN)
                    {
                    }
                    column(SWIFTCode_BankAcc; "SWIFT Code")
                    {
                    }
                    column(YourIBAN; YourIBAN)
                    {
                    }
                    column(YourSWIFTCode; YourSWIFTCode)
                    {
                    }
                    column(WeHaveSentPmtOrdersCaption; WeHaveSentPmtOrdersCaptionLbl)
                    {
                    }
                    column(OurAccountCaption; OurAccountCaptionLbl)
                    {
                    }
                    column(You_AccountCaption; YourAccountCaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(IdentificationCaption; IdentificationCaptionLbl)
                    {
                    }
                    column(BankAccountIBANCaption; BankAccountIBANCaptionLbl)
                    {
                    }
                    column(BankAccountSWIFTCodeCaption; BankAccountSWIFTCodeCaptionLbl)
                    {
                    }
                    column(YourIBANCaption; YourIBANCaptionLbl)
                    {
                    }
                    column(YourSWIFTCodeCaption; YourSWIFTCodeCaptionLbl)
                    {
                    }
                }
                dataitem("Detail Line"; "Detail Line")
                {
                    DataItemLink = "Our Bank" = field("Our Bank"), "Connect Batches" = field("Run No."), "Connect Lines" = field("Line No.");
                    DataItemTableView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date) where(Status = filter("In process" | Posted));
                    column(CurrencyCode_DetailLine; "Currency Code")
                    {
                    }
                    column(ConnectBatches_DetailLine; "Connect Batches")
                    {
                    }
                    column(OurBank_DetailLine; "Our Bank")
                    {
                    }
                    column(ConnectLines_DetailLine; "Connect Lines")
                    {
                    }
                    column(ABSAccumAmount; Abs(AccumAmount))
                    {
                    }
                    column(ABSAmount; Abs(Amount))
                    {
                        AutoFormatExpression = "Payment History Line"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(PmtHistoryLineCurrCode; "Payment History Line"."Currency Code")
                    {
                    }
                    column(TransNo_DetailLine; "Transaction No.")
                    {
                    }
                    column(SerialNoEntry_DetailLine; "Serial No. (Entry)")
                    {
                    }
                    column(OurDocumentNoCaption; OurDocumentNoCaptionLbl)
                    {
                    }
                    column(OriginalAmountCaption; OriginalAmountCaptionLbl)
                    {
                    }
                    column(OutstandingAmountCaption; OutstandingAmountCaptionLbl)
                    {
                    }
                    column(CustLedgEntryDescCaption; "Cust. Ledger Entry".FieldCaption(Description))
                    {
                    }
                    column(YourDocumentNoCaption; YourDocumentNoCaptionLbl)
                    {
                    }
                    column(AmountPaidCaption; AmountPaidCaptionLbl)
                    {
                    }
                    column(CurrencyCaption; CurrencyCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(DocType_CustLedgEntry; "Document Type")
                        {
                        }
                        column(DocNo_CustLedgEntry; "Document No.")
                        {
                        }
                        column(DocDate_CustLedgEntry; Format("Document Date"))
                        {
                        }
                        column(Amt_CustLedgEntry; Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RemAmt_CustLedgEntry; "Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Desc_CustLedgEntry; Description)
                        {
                        }
                        column(ExtDocNo_CustLedgEntry; "External Document No.")
                        {
                        }
                        column(NegAmount_DetailLine; -"Detail Line".Amount)
                        {
                            AutoFormatExpression = "Payment History Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(CurrCode_CustLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_CustLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_CustLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Customerhist1; "Cust. Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(Desc_Customerhist1; Description)
                            {
                            }
                            column(RemAmt_Customerhist1; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Amt_Customerhist1; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocType_Customerhist1; "Document Type")
                            {
                            }
                            column(ExtDocNo_Customerhist1; "External Document No.")
                            {
                            }
                            column(DocNo_Customerhist1; "Document No.")
                            {
                            }
                            column(DocDate_Customerhist1; Format("Document Date"))
                            {
                            }
                            column(CurrCode_Customerhist1; "Currency Code")
                            {
                            }
                            column(EntryNo_Customerhist1; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNo_Customerhist1; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Customerhist2; "Cust. Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_Customerhist2; Description)
                            {
                            }
                            column(RemAmt_Customerhist2; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Amt_Customerhist2; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocType_Customerhist2; "Document Type")
                            {
                            }
                            column(ExtDocNo_Customerhist2; "External Document No.")
                            {
                            }
                            column(DocNo_Customerhist2; "Document No.")
                            {
                            }
                            column(DocDate_Customerhist2; Format("Document Date"))
                            {
                            }
                            column(CurrCode_Customerhist2; "Currency Code")
                            {
                            }
                            column(EntryNo_Customerhist2; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Customer then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(DocType_VendLedgEntry; "Document Type")
                        {
                        }
                        column(Desc_VendLedgEntry; Description)
                        {
                        }
                        column(NegRemAmt_VendLedgEntry; -"Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegAmount_VendLedgEntry; -Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(DetailLineAmt; "Detail Line".Amount)
                        {
                            AutoFormatExpression = "Payment History Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ExtDocNo_VendLedgEntry; "External Document No.")
                        {
                        }
                        column(DocNo_VendLedgEntry; "Document No.")
                        {
                        }
                        column(DocDate_VendLedgEntry; Format("Document Date"))
                        {
                        }
                        column(CurrCode_VendLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_VendLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_VendLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Venhist1; "Vendor Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(Desc_Venhist1; Description)
                            {
                            }
                            column(NegRemAmt_Venhist1; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmt_Venhist1; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocType_Venhist1; "Document Type")
                            {
                            }
                            column(ExtDocNo_Venhist1; "External Document No.")
                            {
                            }
                            column(DocNo_Venhist1; "Document No.")
                            {
                            }
                            column(DocDate_Venhist1; Format("Document Date"))
                            {
                            }
                            column(CurrCode_Venhist1; "Currency Code")
                            {
                            }
                            column(EntryNo_Venhist1; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNo_Venhist1; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Venhist2; "Vendor Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_Venhist2; Description)
                            {
                            }
                            column(NegRemAmt_Venhist2; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmt_Venhist2; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocType_Venhist2; "Document Type")
                            {
                            }
                            column(ExtDocNo_Venhist2; "External Document No.")
                            {
                            }
                            column(DocNo_Venhist2; "Document No.")
                            {
                            }
                            column(DocDate_Venhist2; Format("Document Date"))
                            {
                            }
                            column(CurrCode_Venhist2; "Currency Code")
                            {
                            }
                            column(EntryNo_Venhist2; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Vendor then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Employee Ledger Entry"; "Employee Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(Description_EmplLedgEntry; Description)
                        {
                        }
                        column(DetailLineAmt_EmplLedgEntry; "Detail Line".Amount)
                        {
                            AutoFormatExpression = "Detail Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegRemAmt_EmplLedgEntry; -"Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegAmt_EmplLedgEntry; -Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(DocNo_EmplLedgEntry; "Document No.")
                        {
                        }
                        column(DocType_EmplLedgEntry; "Document Type")
                        {
                        }
                        column(CurrCode_EmplLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_EmplLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_EmplLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Emphist1; "Employee Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(DescHist_EmplLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_EmplLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_EmplLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocNoHist_EmplLedgEntry; "Document No.")
                            {
                            }
                            column(DocTypeHist_EmplLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_EmplLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_EmplLedgEntry; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNoHist_EmplLedgEntry; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Emphist2; "Employee Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(DescHist_EmployeeLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_EmployeeLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_EmployeeLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocNoHist_EmployeeLedgEntry; "Document No.")
                            {
                            }
                            column(DocTypeHist_EmployeeLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_EmployeeLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_EmployeeLedgEntry; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Employee then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        AccumAmount := AccumAmount + Amount;
                    end;

                    trigger OnPreDataItem()
                    begin
                        AccumAmount := 0;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if not CurrReport.Preview then begin
                    PaymHist := "Payment History";
                    PaymHist."Print Docket" := false;
                    PaymHist.Modify();
                end;
            end;
        }
    }

    requestpage
    {
        Caption = 'Docket';

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        ReportLanguage := CurrReport.Language();
    end;

    var
        Text1000001: Label 'Page %1';
        PaymHist: Record "Payment History";
        CompanyInfo: Record "Company Information";
        GlobalLanguage: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        EmplAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Cust: Record "Customer Bank Account";
        VendBank: Record "Vendor Bank Account";
        YourBank: Text[100];
        YourAccount: Text[30];
        YourIBAN: Code[50];
        YourSWIFTCode: Code[20];
        AccumAmount: Decimal;
        ReportLanguage: Integer;
        DocketCaptionLbl: Label 'Docket';
        CompInfoVATRegNoCaptionLbl: Label 'VAT Registration No.';
        CompInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompInfoBankNameCaptionLbl: Label 'Bank';
        CompInfoBankAccountNoCaptionLbl: Label 'Account No.';
        CompInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompInfoPhoneNoCaptionLbl: Label 'Phone No.';
        WeHaveSentPmtOrdersCaptionLbl: Label 'We have sent a collection of payment orders to our bank. Below you will find a specification of the payment orders.';
        OurAccountCaptionLbl: Label 'Our Account';
        YourAccountCaptionLbl: Label 'Your Account';
        DateCaptionLbl: Label 'Date';
        AmountCaptionLbl: Label 'Amount';
        IdentificationCaptionLbl: Label 'Identification';
        BankAccountIBANCaptionLbl: Label 'Our IBAN';
        BankAccountSWIFTCodeCaptionLbl: Label 'Our SWIFT Code';
        YourIBANCaptionLbl: Label 'Your IBAN';
        YourSWIFTCodeCaptionLbl: Label 'Your SWIFT Code';
        OurDocumentNoCaptionLbl: Label 'Our Document No.';
        OriginalAmountCaptionLbl: Label 'Original Amount';
        OutstandingAmountCaptionLbl: Label 'Outstanding Amount';
        YourDocumentNoCaptionLbl: Label 'Your Document No.';
        AmountPaidCaptionLbl: Label 'Amount paid';
        CurrencyCaptionLbl: Label 'Currency';
        TotalCaptionLbl: Label 'Total';
}

