// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.IO;

report 7000089 "Bill group - Export factoring"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bill group - Export factoring';
    Permissions = TableData "Bill Group" = m;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bill Group"; "Bill Group")
        {
            RequestFilterFields = "No.";
            dataitem("Cartera Doc."; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Bill Gr./Pmt. Order No.", "Collection Agent", "Due Date", "Global Dimension 1 Code", "Global Dimension 2 Code", "Category Code", "Posting Date", "Document No.", Accepted, "Currency Code", "Document Type");

                trigger OnAfterGetRecord()
                begin
                    TestField("Account No.");
                    Customer.Get("Account No.");
                    if "Document Type" = "Document Type"::Invoice then begin
                        TotalDocCust := TotalDocCust + 1;
                        if PaymentMethod.Get("Payment Method Code") then
                            DocType := ' '
                        else
                            case PaymentMethod."Bill Type" of
                                "ES Bill Type"::"Bill of Exchange":
                                    DocType := Text1100009;
                                "ES Bill Type"::Receipt:
                                    DocType := Text1100010;
                                "ES Bill Type"::IOU:
                                    DocType := Text1100011;
                                "ES Bill Type"::Check:
                                    DocType := Text1100012;
                                "ES Bill Type"::Transfer:
                                    DocType := Text1100013;
                                else
                                    DocType := ' ';
                            end;

                        RmgAmount := FormatNumber(Round("Remaining Amount" * 100, 1), 15);

                        TotalAmount := TotalAmount + "Remaining Amount";
                        CustPostCode := DelStr(Customer."Post Code", 1, StrPos(Customer."Post Code", '-'));

                        GetCurrencyCode("Cartera Doc.", CurrCode);

                        OutText := '09' + PadStr('', 5, '0') + PadStr(Customer.Name, 30, ' ') + PadStr(Customer."VAT Registration No.", 14, ' ')
                          + PadStr(Customer.Address, 30, ' ') + PadStr(Customer.City, 30, ' ') +
                          (PadStr('', 5 - StrLen(CustPostCode), '0') + CustPostCode) + Text1100014 + PadStr("Document No.", 10, ' ') + PadStr('', 10, ' ') +
                          Format("Posting Date", 0, Text1100007)
                          + Format("Due Date", 0, Text1100007) + RmgAmount + PadStr('', 2, '0') + PadStr('', 2, '0') + PadStr('', 2, '0')
                          + CCCBankNo + CCCBankBranchNo + CCCAccNo + DocType + PadStr("Account No.", 15, ' ') + CCCControlDigits
                          + Text1100015 + CurrCode + PadStr('', 21, ' ');
                        OutFile.Write(OutText);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Factoring = Factoring::" " then
                    Error(Text1100005, "No.");

                TestField("Bank Account No.");
                BankAcc.Get("Bank Account No.");

                CCCBankNo := BankAcc."CCC Bank No.";
                CCCBankBranchNo := BankAcc."CCC Bank Branch No.";
                CCCAccNo := BankAcc."CCC Bank Account No.";
                CCCControlDigits := BankAcc."CCC Control Digits";

                if (CCCBankNo = '') or (CCCBankBranchNo = '') or
                   (CCCControlDigits = '') or (CCCAccNo = '')
                then
                    Error(Text1100006, BankAcc."No.");

                CCCBankNo := PadStr('', MaxStrLen(CCCBankNo) - StrLen(CCCBankNo), '0') + CCCBankNo;
                CCCBankBranchNo := PadStr('', MaxStrLen(CCCBankBranchNo) - StrLen(CCCBankBranchNo), '0') + CCCBankBranchNo;
                CCCAccNo := PadStr('', MaxStrLen(CCCAccNo) - StrLen(CCCAccNo), '0') + CCCAccNo;
                if CCCControlDigits = '' then
                    CCCControlDigits := PadStr('', MaxStrLen(CCCControlDigits), ' ')
                else
                    CCCControlDigits := PadStr('', MaxStrLen(CCCControlDigits) - StrLen(CCCControlDigits), '0') + CCCControlDigits;

                NoBillGroup := NoBillGroup + 1;

                OutText := '06' + (PadStr('', 5 - StrLen(Format(NoBillGroup)), '0') + Format(NoBillGroup))
                  + Format("Posting Date", 0, Text1100007) + PadStr('', 219, ' ');
                OutFile.Write(OutText);
            end;

            trigger OnPostDataItem()
            var
                FileManagement: Codeunit "File Management";
            begin
                TotalRmgAmount := FormatNumber(Round(TotalAmount * 100, 1), 15);

                OutText := '66' + (PadStr('', 4 - StrLen(Format(TotalDocCust)), '0') + Format(TotalDocCust))
                  + PadStr('', 4, '0') + TotalRmgAmount + PadStr('', 15, '0') + PadStr('', 192, ' ');
                OutFile.Write(OutText);

                OutText := '99' + (PadStr('', 4 - StrLen(Format(NoBillGroup)), '0') + Format(NoBillGroup)) +
                  PadStr('', 226, ' ');
                OutFile.Write(OutText);

                OutFile.Close();

                if SilentMode then
                    FileManagement.CopyServerFile(ExternalFile, SilentModeFile, true)
                else
                    Download(ExternalFile, '', 'C:', Text10701, ToFile);
            end;

            trigger OnPreDataItem()
            begin
                if BankSuffix = '' then
                    Error(Text1100000);

                if not DocMisc.CheckBankSuffix(BankSuffixBankAcc, "Bank Account No.") then
                    if not Confirm(Text1100001 +
                         Text1100002,
                         false,
                         FieldCaption("Bank Account No."),
                         TableCaption)
                    then
                        Error(Text1100003);

                OutText := '03' + PadStr(BankSuffix, 5, '0') + NameCompany + Format(DeliveryDate, 0, Text1100004) + PadStr('', 189, ' ');
                OutFile.Write(OutText);
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
                        Caption = 'Delivery date';
                        ToolTip = 'Specifies a number to identify the operations declaration.';
                    }
                    field(BankSuffix; BankSuffix)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Suffix';
                        TableRelation = Suffix.Suffix;
                        ToolTip = 'Specifies the suffix assigned by the bank to manage bill groups. Usually, each bank assigns the company a different suffix for managing bill groups, depending on whether they are receivable or discount management operations.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Suffix: Record Suffix;
                            Suffixes: Page Suffixes;
                        begin
                            Suffixes.SetTableView(Suffix);
                            Suffixes.SetRecord(Suffix);
                            Suffixes.LookupMode(true);
                            Suffixes.Editable(false);
                            if Suffixes.RunModal() = ACTION::LookupOK then begin
                                Suffixes.GetRecord(Suffix);
                                BankSuffixBankAcc := Suffix."Bank Acc. Code";
                                BankSuffix := Suffix.Suffix;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if ExternalFile = '' then
                ExternalFile := 'C:\' + Text10702;
            if DeliveryDate = 0D then
                DeliveryDate := Today;
            "Bill Group".SetFilter(Factoring, '<>%1', "Bill Group".Factoring::" ");
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");
        NameCompany := CompanyInfo.Name;
        NameCompany := PadStr(NameCompany, 30, ' ');
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        OutFile.TextMode := true;
        OutFile.WriteMode := true;
        ExternalFile := FileMgt.ServerTempFileName('');
        ToFile := Text10702;
        OutFile.Create(ExternalFile);
    end;

    var
        Text1100000: Label 'Bank Suffix cannot be blank.';
        Text1100001: Label 'The Bank Suffix selected belongs to a %1  different than the %2. \';
        Text1100002: Label 'Do you want to continue?.';
        Text1100003: Label 'Process cancelled by request of user.';
        Text1100004: Label '<year><Month,2><Day,2>', Locked = true;
        Text1100005: Label 'Bill Group %1 cannot be sent to factoring';
        Text1100006: Label 'Some data for Bank Account %1 are missing.';
        Text1100007: Label '<Year><Month,2><Day,2>', Locked = true;
        Text1100009: Label 'B';
        Text1100010: Label 'R';
        Text1100011: Label 'I';
        Text1100012: Label 'C';
        Text1100013: Label 'T';
        Text1100014: Label 'F';
        Text1100015: Label 'ES';
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        BankAcc: Record "Bank Account";
        PaymentMethod: Record "Payment Method";
        GLSetup: Record "General Ledger Setup";
        DocMisc: Codeunit "Document-Misc";
        OutFile: File;
        ExternalFile: Text[1024];
        CCCBankNo: Text[4];
        CCCBankBranchNo: Text[4];
        CCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        TotalDocCust: Integer;
        TotalAmount: Decimal;
        OutText: Text[250];
        DeliveryDate: Date;
        DocType: Text[2];
        RmgAmount: Text[15];
        NameCompany: Text[100];
        NoBillGroup: Integer;
        TotalRmgAmount: Text[15];
        CustPostCode: Text[5];
        CurrCode: Text[3];
        BankSuffixBankAcc: Code[10];
        BankSuffix: Code[3];
        ToFile: Text[1024];
        Text10701: Label 'ASC Files (*.asc)|*.asc|All Files (*.*)|*.*';
        Text10702: Label 'FACTORING.ASC';
        SilentMode: Boolean;
        SilentModeFile: Text;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(Doc: Record "Cartera Doc."; var "Code": Text[3])
    begin
        GLSetup.Get();
        if Doc."Currency Code" = '' then
            Code := CopyStr(GLSetup."LCY Code", 1, 3)
        else
            if StrLen(Doc."Currency Code") > 3 then
                Code := CopyStr(Doc."Currency Code", 1, 3)
            else
                Code := PadStr(Doc."Currency Code", 3, ' ');
    end;

    [Scope('OnPrem')]
    procedure SetSilentMode(ServerFileName: Text)
    begin
        SilentMode := true;
        SilentModeFile := ServerFileName;
    end;

    local procedure FormatNumber(Number: Decimal; Length: Integer): Text[15]
    begin
        exit(ConvertStr(Format(Number, Length, '<Integer>'), ' ', '0'));
    end;
}

