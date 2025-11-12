// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Text;

/// <summary>
/// Table 1226 "Payment Export Data" contains data for exporting payments to bank files.
/// This table stores all the necessary information for payment file generation including sender bank details,
/// recipient information, payment amounts, SEPA parameters, and various formatting options.
/// </summary>
table 1226 "Payment Export Data"
{
    Caption = 'Payment Export Data';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the payment export data entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Reference to the data exchange entry associated with this payment export.
        /// </summary>
        field(2; "Data Exch Entry No."; Integer)
        {
            Caption = 'Data Exch Entry No.';
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Line number within the data exchange for this payment export data.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Code defining the line definition in the data exchange.
        /// </summary>
        field(4; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
        }
        /// <summary>
        /// General journal template associated with this payment export.
        /// </summary>
        field(5; "General Journal Template"; Code[10])
        {
            Caption = 'General Journal Template';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// General journal batch name associated with this payment export.
        /// </summary>
        field(6; "General Journal Batch Name"; Code[10])
        {
            Caption = 'General Journal Batch Name';
            TableRelation = "Gen. Journal Batch";
        }
        /// <summary>
        /// General journal line number associated with this payment export.
        /// </summary>
        field(7; "General Journal Line No."; Integer)
        {
            Caption = 'General Journal Line No.';
        }
        /// <summary>
        /// Sender bank name for data conversion purposes (limited to 50 characters).
        /// </summary>
        field(28; "Sender Bank Name - Data Conv."; Text[50])
        {
            Caption = 'Sender Bank Name - Data Conv.';
        }
        /// <summary>
        /// Full name of the sender bank.
        /// </summary>
        field(29; "Sender Bank Name"; Text[100])
        {
            Caption = 'Sender Bank Name';
        }
        /// <summary>
        /// Code of the sender bank account.
        /// </summary>
        field(30; "Sender Bank Account Code"; Code[20])
        {
            Caption = 'Sender Bank Account Code';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Account number of the sender bank.
        /// </summary>
        field(31; "Sender Bank Account No."; Text[50])
        {
            Caption = 'Sender Bank Account No.';
        }
        /// <summary>
        /// Currency code of the sender bank account.
        /// </summary>
        field(32; "Sender Bank Account Currency"; Code[10])
        {
            Caption = 'Sender Bank Account Currency';
            TableRelation = Currency;
        }
        /// <summary>
        /// Country/region code of the sender bank.
        /// </summary>
        field(33; "Sender Bank Country/Region"; Code[10])
        {
            Caption = 'Sender Bank Country/Region';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Bank Identifier Code (BIC) of the sender bank.
        /// </summary>
        field(34; "Sender Bank BIC"; Code[35])
        {
            Caption = 'Sender Bank BIC';
        }
        /// <summary>
        /// Clearing standard used by the sender bank.
        /// </summary>
        field(35; "Sender Bank Clearing Std."; Text[50])
        {
            Caption = 'Sender Bank Clearing Std.';
            TableRelation = "Bank Clearing Standard";
        }
        /// <summary>
        /// Clearing code used by the sender bank.
        /// </summary>
        field(36; "Sender Bank Clearing Code"; Text[50])
        {
            Caption = 'Sender Bank Clearing Code';
        }
        /// <summary>
        /// Address of the sender bank.
        /// </summary>
        field(37; "Sender Bank Address"; Text[100])
        {
            Caption = 'Sender Bank Address';
        }
        /// <summary>
        /// City of the sender bank.
        /// </summary>
        field(38; "Sender Bank City"; Text[50])
        {
            Caption = 'Sender Bank City';
        }
        /// <summary>
        /// Postal code of the sender bank.
        /// </summary>
        field(39; "Sender Bank Post Code"; Code[20])
        {
            Caption = 'Sender Bank Post Code';
        }
        /// <summary>
        /// Name of the payment recipient.
        /// </summary>
        field(40; "Recipient Name"; Text[100])
        {
            Caption = 'Recipient Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Address of the payment recipient.
        /// </summary>
        field(41; "Recipient Address"; Text[100])
        {
            Caption = 'Recipient Address';
        }
        /// <summary>
        /// City of the payment recipient.
        /// </summary>
        field(42; "Recipient City"; Text[50])
        {
            Caption = 'Recipient City';
        }
        /// <summary>
        /// Postal code of the payment recipient.
        /// </summary>
        field(43; "Recipient Post Code"; Code[20])
        {
            Caption = 'Recipient Post Code';
        }
        field(44; "Recipient Country/Region Code"; Code[10])
        {
            Caption = 'Recipient Country/Region Code';
        }
        field(45; "Recipient Email Address"; Text[80])
        {
            Caption = 'Recipient Email Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(46; "Recipient ID"; Code[20])
        {
            Caption = 'Recipient ID';
        }
        field(48; "Recipient Bank Clearing Std."; Text[50])
        {
            Caption = 'Recipient Bank Clearing Std.';
            TableRelation = "Bank Clearing Standard";
        }
        field(49; "Recipient Bank Clearing Code"; Text[50])
        {
            Caption = 'Recipient Bank Clearing Code';
        }
        field(50; "Recipient Reg. No."; Code[20])
        {
            Caption = 'Recipient Reg. No.';
        }
        field(51; "Recipient Acc. No."; Code[30])
        {
            Caption = 'Recipient Acc. No.';
        }
        field(52; "Recipient Bank Acc. No."; Text[50])
        {
            Caption = 'Recipient Bank Acc. No.';
        }
        field(53; "Recipient Bank BIC"; Code[35])
        {
            Caption = 'Recipient Bank BIC';
        }
        field(54; "Recipient Bank Name"; Text[100])
        {
            Caption = 'Recipient Bank Name';
        }
        field(55; "Recipient Bank Address"; Text[100])
        {
            Caption = 'Recipient Bank Address';
        }
        field(56; "Recipient Bank City"; Text[50])
        {
            Caption = 'Recipient Bank City';
        }
        field(57; "Recipient Bank Country/Region"; Code[10])
        {
            Caption = 'Recipient Bank Country/Region';
            TableRelation = "Country/Region";
        }
        field(58; "Recipient Creditor No."; Code[20])
        {
            Caption = 'Recipient Creditor No.';
        }
        field(59; "Recipient Bank Post Code"; Code[20])
        {
            Caption = 'Recipient Bank Post Code';
        }
        field(60; "Message Type"; Code[1])
        {
            Caption = 'Message Type';
        }
        field(61; "Letter to Sender"; Code[1])
        {
            Caption = 'Letter to Sender';
        }
        field(63; "Recipient Acknowledgement"; Code[1])
        {
            Caption = 'Recipient Acknowledgement';
        }
        field(64; "Short Advice"; Text[35])
        {
            Caption = 'Short Advice';
        }
        field(65; "Message to Recipient 1"; Text[140])
        {
            Caption = 'Message to Recipient 1';
        }
        field(66; "Message to Recipient 2"; Text[140])
        {
            Caption = 'Message to Recipient 2';
        }
        field(80; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DecimalPlaces = 2 : 2;
        }
        field(81; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(82; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        field(83; "Transfer Type"; Code[1])
        {
            Caption = 'Transfer Type';
        }
        field(84; "Payment Type"; Text[50])
        {
            Caption = 'Payment Type';
        }
        field(85; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(87; "Recipient Reference"; Code[35])
        {
            Caption = 'Recipient Reference';
        }
        field(88; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(89; "Invoice Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Invoice Amount';
        }
        field(90; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
        }
        field(91; "Recipient County"; Text[30])
        {
            CaptionClass = '5,11,' + "Recipient Country/Region Code";
            Caption = 'Recipient County';
        }
        field(92; "Recipient Bank County"; Text[30])
        {
            CaptionClass = '5,10,' + "Recipient Bank Country/Region";
            Caption = 'Recipient Bank County';
        }
        field(93; "Sender Bank County"; Text[30])
        {
            CaptionClass = '5,9,' + "Sender Bank Country/Region";
            Caption = 'Sender Bank County';
        }
        field(94; "Sender Reg. No."; Text[50])
        {
            Caption = 'Sender Registration No.';
            DataClassification = CustomerContent;
        }
        field(100; "Payment Information ID"; Text[50])
        {
            Caption = 'Payment Information ID';
        }
        field(101; "End-to-End ID"; Text[50])
        {
            Caption = 'End-to-End ID';
        }
        field(102; "Message ID"; Text[35])
        {
            Caption = 'Message ID';
        }
        field(103; "SEPA Instruction Priority"; Option)
        {
            Caption = 'SEPA Instruction Priority';
            OptionCaption = 'NORMAL,HIGH';
            OptionMembers = NORMAL,HIGH;

            trigger OnValidate()
            begin
                case "SEPA Instruction Priority" of
                    "SEPA Instruction Priority"::NORMAL:
                        "SEPA Instruction Priority Text" := 'NORM';
                    "SEPA Instruction Priority"::HIGH:
                        "SEPA Instruction Priority Text" := 'HIGH';
                end;
            end;
        }
        field(104; "SEPA Instruction Priority Text"; Code[4])
        {
            Caption = 'SEPA Instruction Priority Text';
            Editable = false;
        }
        field(105; "SEPA Payment Method"; Option)
        {
            Caption = 'SEPA Payment Method';
            InitValue = TRF;
            OptionCaption = 'CHK,TRF,TRA';
            OptionMembers = CHK,TRF,TRA;

            trigger OnValidate()
            begin
                case "SEPA Payment Method" of
                    "SEPA Payment Method"::CHK:
                        "SEPA Payment Method Text" := 'CHK';
                    "SEPA Payment Method"::TRF:
                        "SEPA Payment Method Text" := 'TRF';
                    "SEPA Payment Method"::TRA:
                        "SEPA Payment Method Text" := 'TRA';
                end;
            end;
        }
        field(106; "SEPA Payment Method Text"; Code[3])
        {
            Caption = 'SEPA Payment Method Text';
        }
        field(107; "SEPA Batch Booking"; Boolean)
        {
            Caption = 'SEPA Batch Booking';
        }
        field(108; "SEPA Charge Bearer"; Option)
        {
            Caption = 'SEPA Charge Bearer';
            InitValue = SLEV;
            OptionCaption = 'DEBT,CRED,SHAR,SLEV';
            OptionMembers = DEBT,CRED,SHAR,SLEV;

            trigger OnValidate()
            begin
                case "SEPA Charge Bearer" of
                    "SEPA Charge Bearer"::DEBT:
                        "SEPA Charge Bearer Text" := 'DEBT';
                    "SEPA Charge Bearer"::CRED:
                        "SEPA Charge Bearer Text" := 'CRED';
                    "SEPA Charge Bearer"::SHAR:
                        "SEPA Charge Bearer Text" := 'SHAR';
                    "SEPA Charge Bearer"::SLEV:
                        "SEPA Charge Bearer Text" := 'SLEV';
                end;
            end;
        }
        field(109; "SEPA Charge Bearer Text"; Code[4])
        {
            Caption = 'SEPA Charge Bearer Text';
        }
        field(120; "SEPA Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'SEPA Direct Debit Mandate ID';
        }
        field(121; "SEPA Direct Debit Seq. Type"; Option)
        {
            Caption = 'SEPA Direct Debit Seq. Type';
            OptionCaption = 'One Off,First,Recurring,Last';
            OptionMembers = "One Off",First,Recurring,Last;

            trigger OnValidate()
            begin
                case "SEPA Direct Debit Seq. Type" of
                    "SEPA Direct Debit Seq. Type"::"One Off":
                        "SEPA Direct Debit Seq. Text" := 'OOFF';
                    "SEPA Direct Debit Seq. Type"::First:
                        "SEPA Direct Debit Seq. Text" := 'FRST';
                    "SEPA Direct Debit Seq. Type"::Recurring:
                        "SEPA Direct Debit Seq. Text" := 'RCUR';
                    "SEPA Direct Debit Seq. Type"::Last:
                        "SEPA Direct Debit Seq. Text" := 'FNAL';
                end;
            end;
        }
        field(122; "SEPA Direct Debit Seq. Text"; Code[4])
        {
            Caption = 'SEPA Direct Debit Seq. Text';
        }
        field(123; "SEPA DD Mandate Signed Date"; Date)
        {
            Caption = 'SEPA DD Mandate Signed Date';
        }
        field(124; "SEPA Partner Type"; Enum "Partner Type")
        {
            Caption = 'SEPA Partner Type';

            trigger OnValidate()
            begin
                case "SEPA Partner Type" of
                    "SEPA Partner Type"::" ":
                        "SEPA Partner Type Text" := '';
                    "SEPA Partner Type"::Company:
                        "SEPA Partner Type Text" := 'B2B';
                    "SEPA Partner Type"::Person:
                        "SEPA Partner Type Text" := 'CORE';
                end;
            end;
        }
        field(125; "SEPA Partner Type Text"; Code[4])
        {
            Caption = 'SEPA Partner Type Text';
        }
        field(130; "Importing Code"; Code[10])
        {
            Caption = 'Importing Code';
        }
        field(131; "Importing Date"; Date)
        {
            Caption = 'Importing Date';
        }
        field(132; "Importing Description"; Text[250])
        {
            Caption = 'Importing Description';
        }
        field(133; "Costs Distribution"; Text[30])
        {
            Caption = 'Costs Distribution';
        }
        field(134; "Message Structure"; Text[30])
        {
            Caption = 'Message Structure';
        }
        field(135; "Own Address Info."; Text[30])
        {
            Caption = 'Own Address Info.';
        }
        field(170; "Creditor No."; Code[35])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Transit No."; Code[35])
        {
            Caption = 'Transit No.';
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(200; "Format Command"; Code[4])
        {
            Caption = 'Format Command';
        }
        field(201; "Format Remittance Info Type"; Code[1])
        {
            Caption = 'Format Remittance Info Type';
        }
        field(220; "Format Payment Type"; Code[2])
        {
            Caption = 'Format Payment Type';
        }
        field(221; "Format Expense Code"; Code[1])
        {
            Caption = 'Format Expense Code';
        }
        field(222; "Format Text Code"; Code[3])
        {
            Caption = 'Format Text Code';
        }
        field(283; "Format Form Type"; Code[2])
        {
            Caption = 'Format Form Type';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not PreserveNonLatinCharacters then
            PaymentExportConvertToLatin();
    end;

    var
        TempPaymentExportRemittanceText: Record "Payment Export Remittance Text" temporary;
        PreserveNonLatinCharacters: Boolean;
        BankMustHaveBankAccountNoErr: Label 'You must specify either Bank Account No. or IBAN for Bank Account %1.', Comment = '%1 = Bank Account Name';
        EmployeeMustHaveBankAccountNoErr: Label 'You must specify either Bank Account No. or IBAN for employee %1.', Comment = '%1 - Employee name';

    procedure InitData(var GenJnlLine: Record "Gen. Journal Line")
    begin
        Reset();
        Clear(TempPaymentExportRemittanceText);
        Init();
        Amount := GenJnlLine.Amount;
        "Currency Code" := GenJnlLine."Currency Code";
    end;

    procedure AddRemittanceText(NewText: Text[140])
    begin
        if NewText = '' then
            exit;
        if TempPaymentExportRemittanceText.FindLast() then;
        TempPaymentExportRemittanceText."Pmt. Export Data Entry No." := "Entry No.";
        TempPaymentExportRemittanceText."Line No." += 1;
        if PreserveNonLatinCharacters then
            TempPaymentExportRemittanceText.Text := NewText
        else
            TempPaymentExportRemittanceText.Text := CopyStr(ConvertToASCII(NewText), 1, MaxStrLen(TempPaymentExportRemittanceText.Text));
        TempPaymentExportRemittanceText.Insert();
    end;

    procedure GetRemittanceTexts(var PaymentExportRemittanceText: Record "Payment Export Remittance Text")
    begin
        if TempPaymentExportRemittanceText.FindSet() then
            repeat
                PaymentExportRemittanceText := TempPaymentExportRemittanceText;
                PaymentExportRemittanceText.Insert();
            until TempPaymentExportRemittanceText.Next() = 0;
    end;

    procedure GetOrganizationID(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."VAT Registration No.");
    end;

    procedure GetSenderCreditorNo(): Text
    var
        BankAccount: Record "Bank Account";
        CreditorNo: Text;
    begin
        BankAccount.Get("Sender Bank Account Code");
        CreditorNo := BankAccount."Creditor No.";
        OnAfterGetSenderCreditorNo(Rec, CreditorNo);
        exit(CreditorNo);
    end;

    procedure AddGenJnlLineErrorText(GenJnlLine: Record "Gen. Journal Line"; NewText: Text)
    begin
        GenJnlLine.InsertPaymentFileError(NewText);
    end;

    local procedure ConvertToASCII(Text: Text): Text
    var
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        exit(StringConversionManagement.WindowsToASCII(Text));
    end;

    procedure SetPreserveNonLatinCharacters(NewPreserveNonLatinCharacters: Boolean)
    begin
        PreserveNonLatinCharacters := NewPreserveNonLatinCharacters;
    end;

    procedure GetPreserveNonLatinCharacters(): Boolean
    begin
        exit(PreserveNonLatinCharacters);
    end;

    local procedure PaymentExportConvertToLatin()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        ConvertFieldsToLatinCharacters(RecRef);
        RecRef.SetTable(Rec);
    end;

    procedure CompanyInformationConvertToLatin(var CompanyInformation: Record "Company Information")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CompanyInformation);
        ConvertFieldsToLatinCharacters(RecRef);
        RecRef.SetTable(CompanyInformation);
    end;

    local procedure ConvertFieldsToLatinCharacters(var RecRef: RecordRef)
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        FieldRef: FieldRef;
        i: Integer;
    begin
        PreserveNonLatinCharacters := false;
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if (FieldRef.Class = FieldClass::Normal) and (FieldRef.Type in [FieldType::Text, FieldType::Code]) then
                FieldRef.Value := CopyStr(StringConversionManagement.WindowsToASCII(Format(FieldRef.Value)), 1, FieldRef.Length);
        end;
    end;

    procedure SetCustomerAsRecipient(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account")
    begin
        "Recipient Name" := Customer.Name;
        "Recipient Address" := CopyStr(Customer.Address, 1, 70);
        "Recipient City" := CopyStr(Customer.City, 1, 35);
        "Recipient County" := Customer.County;
        "Recipient Post Code" := Customer."Post Code";
        "Recipient Country/Region Code" := Customer."Country/Region Code";
        "Recipient Email Address" := Customer."E-Mail";
        "Recipient Bank Name" := CustomerBankAccount.Name;
        "Recipient Bank Address" := CopyStr(CustomerBankAccount.Address, 1, 70);
        "Recipient Bank City" := CopyStr(CustomerBankAccount.City, 1, 35);
        "Recipient Bank County" := CustomerBankAccount.County;
        "Recipient Bank Post Code" := CustomerBankAccount."Post Code";
        "Recipient Bank Country/Region" := CustomerBankAccount."Country/Region Code";
        "Recipient Bank BIC" := CustomerBankAccount."SWIFT Code";
        "Recipient Bank Acc. No." := CopyStr(CustomerBankAccount.GetBankAccountNo(), 1, MaxStrLen("Recipient Bank Acc. No."));
        "Recipient Bank Clearing Std." := CustomerBankAccount."Bank Clearing Standard";
        "Recipient Bank Clearing Code" := CustomerBankAccount."Bank Clearing Code";

        OnAfterSetCustomerAsRecipient(Rec, Customer, CustomerBankAccount);
    end;

    procedure SetVendorAsRecipient(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account")
    begin
        "Recipient Name" := Vendor.Name;
        "Recipient Address" := CopyStr(Vendor.Address, 1, 70);
        "Recipient City" := CopyStr(Vendor.City, 1, 35);
        "Recipient County" := Vendor.County;
        "Recipient Post Code" := Vendor."Post Code";
        "Recipient Country/Region Code" := Vendor."Country/Region Code";
        "Recipient Email Address" := Vendor."E-Mail";
        "Recipient Bank Name" := VendorBankAccount.Name;
        "Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 70);
        "Recipient Bank City" := CopyStr(VendorBankAccount.City, 1, 35);
        "Recipient Bank County" := VendorBankAccount.County;
        "Recipient Bank Post Code" := VendorBankAccount."Post Code";
        "Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
        "Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
        "Recipient Bank Acc. No." := CopyStr(VendorBankAccount.GetBankAccountNo(), 1, MaxStrLen("Recipient Bank Acc. No."));
        "Recipient Bank Clearing Std." := VendorBankAccount."Bank Clearing Standard";
        "Recipient Bank Clearing Code" := VendorBankAccount."Bank Clearing Code";

        OnAfterSetVendorAsRecipient(Rec, Vendor, VendorBankAccount);
    end;

    procedure SetEmployeeAsRecipient(var Employee: Record Employee)
    begin
        "Recipient Name" := CopyStr(Employee.FullName(), 1, MaxStrLen("Recipient Name"));
        "Recipient Address" := CopyStr(Employee.Address, 1, 70);
        "Recipient City" := CopyStr(Employee.City, 1, 35);
        "Recipient County" := Employee.County;
        "Recipient Post Code" := Employee."Post Code";
        "Recipient Country/Region Code" := Employee."Country/Region Code";
        "Recipient Email Address" := Employee."E-Mail";
        if Employee.GetBankAccountNo() = '' then
            Error(EmployeeMustHaveBankAccountNoErr, Employee.FullName());
        "Recipient Bank Acc. No." := CopyStr(Employee.GetBankAccountNo(), 1, MaxStrLen("Recipient Bank Acc. No."));
        "Recipient Bank BIC" := Employee."SWIFT Code";
        OnAfterSetEmployeeAsRecipient(Employee);
    end;

    procedure SetBankAsRecipient(var BankAccount: Record "Bank Account")
    begin
        "Recipient Name" := BankAccount.Name;
        "Recipient Address" := BankAccount.Address;
        "Recipient City" := BankAccount.City;
        "Recipient County" := BankAccount.County;
        "Recipient Post Code" := BankAccount."Post Code";
        "Recipient Country/Region Code" := BankAccount."Country/Region Code";
        "Recipient Email Address" := BankAccount."E-Mail";
        if BankAccount.GetBankAccountNo() = '' then
            Error(BankMustHaveBankAccountNoErr, BankAccount.Name);
        "Recipient Bank Acc. No." := CopyStr(BankAccount.GetBankAccountNo(), 1, MaxStrLen(Rec."Recipient Bank Acc. No."));
        "Recipient Bank BIC" := BankAccount."SWIFT Code";
        OnAfterSetBankAsRecipient(Rec, BankAccount);
    end;

    procedure SetBankAsSenderBank(BankAccount: Record "Bank Account")
    begin
        "Sender Bank Name" := BankAccount.Name;
        "Sender Bank Address" := BankAccount.Address;
        "Sender Bank City" := BankAccount.City;
        "Sender Bank County" := BankAccount.County;
        "Sender Bank Post Code" := BankAccount."Post Code";
        "Sender Bank Account Code" := BankAccount."No.";
        "Sender Bank Account No." := CopyStr(BankAccount.GetBankAccountNo(), 1, MaxStrLen("Sender Bank Account No."));
        "Sender Bank BIC" := BankAccount."SWIFT Code";
        "Sender Bank Clearing Std." := BankAccount."Bank Clearing Standard";
        "Sender Bank Clearing Code" := BankAccount."Bank Clearing Code";
        OnAfterSetBankAsSenderBank(BankAccount);
    end;

    procedure SetCreditorIdentifier(BankAccount: Record "Bank Account")
    begin
        BankAccount.TestField("Creditor No.");
        "Creditor No." := BankAccount."Creditor No.";
        "Transit No." := BankAccount."Transit No.";
    end;

    procedure SetCreditTransferIDs(MessageID: Code[20])
    begin
        "Message ID" := MessageID;
        "Payment Information ID" := MessageID + '/' + Format("Entry No.");
        "End-to-End ID" := "Payment Information ID";
    end;

    procedure IsFieldBlank(FieldID: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        BlankValue: Text;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(FieldID);
        case FieldRef.Type of
            FieldType::Text, FieldType::Code, FieldType::Date:
                BlankValue := '';
            FieldType::Decimal, FieldType::Integer:
                BlankValue := '0';
        end;
        exit(Format(FieldRef.Value) = BlankValue);
    end;

    /// <summary>
    /// Integration event raised after determining the sender creditor number for payment export.
    /// Enables custom logic to modify or override the creditor number used in payment files.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data record being processed</param>
    /// <param name="CreditorNo">Creditor number to be used in payment export</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterGetSenderCreditorNo(PaymentExportData: Record "Payment Export Data"; var CreditorNo: Text)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting the bank account as sender bank for payment export.
    /// Enables custom processing after sender bank configuration.
    /// </summary>
    /// <param name="BankAccount">Bank account configured as sender</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterSetBankAsSenderBank(BankAccount: Record "Bank Account")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting a customer as the payment recipient.
    /// Enables custom modifications to customer recipient data for payment export.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data being updated</param>
    /// <param name="Customer">Customer record configured as recipient</param>
    /// <param name="CustomerBankAccount">Customer bank account for payment</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustomerAsRecipient(var PaymentExportData: Record "Payment Export Data"; var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account");
    begin
    end;

    /// <summary>
    /// Integration event raised after setting an employee as the payment recipient.
    /// Enables custom processing after employee recipient configuration.
    /// </summary>
    /// <param name="Employee">Employee record configured as recipient</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterSetEmployeeAsRecipient(Employee: Record Employee)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting a vendor as the payment recipient.
    /// Enables custom modifications to vendor recipient data for payment export.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data being updated</param>
    /// <param name="Vendor">Vendor record configured as recipient</param>
    /// <param name="VendorBankAccount">Vendor bank account for payment</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVendorAsRecipient(var PaymentExportData: Record "Payment Export Data"; var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account");
    begin
    end;

    /// <summary>
    /// Integration event raised after setting a bank account as the payment recipient.
    /// Enables custom modifications to bank recipient data for payment export.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data being updated</param>
    /// <param name="BankAccount">Bank account configured as recipient</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterSetBankAsRecipient(var PaymentExportData: Record "Payment Export Data"; var BankAccount: Record "Bank Account")
    begin
    end;
}
