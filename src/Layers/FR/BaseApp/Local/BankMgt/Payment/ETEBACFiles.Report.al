// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.IO;
using System.Reflection;

report 10880 "ETEBAC Files"
{
    Caption = 'ETEBAC Files';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment Header"; "Payment Header")
        {
            DataItemTableView = sorting("No.");
            MaxIteration = 1;
            dataitem("Payment Line"; "Payment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    Cust: Record Customer;
                    RecordCode: Text;
                    OperationCode: Text;
                    Numbering: Text;
                    BillReference: Text;
                    CustomerName: Text;
                    CustomerBankName: Text;
                    AcceptationCode: Text;
                    BankBranchNo: Text;
                    AgencyCode: Text;
                    BankAccountNo: Text;
                    PrintAmount: Text;
                    DueDate: Text;
                    CreationDate: Text;
                    ExportedText: Text;
                begin
                    if (CurrencyUsed = '') and ("Currency Code" <> '') then
                        Error(Text004, GLSetup."LCY Code");

                    TestField("Account No.");
                    Cust.Get("Account No.");

                    if StrLen("Bank Branch No.") > 5 then
                        Error(Text006, "Bank Account Code");

                    if StrLen("Agency Code") > 5 then
                        Error(Text006, "Bank Account Code");

                    if StrLen("Bank Account No.") > 11 then
                        Error(Text006, "Bank Account Code");

                    if not "RIB Checked" then
                        Error(Text007, "Bank Account Code", "Account No.");

                    LineNo := LineNo + 1;

                    RecordCode := '06';
                    OperationCode := '60';
                    Numbering := ConvertStr(Format(LineNo, 8), ' ', '0');

                    case "Drawee Reference" <> '' of
                        true:
                            BillReference := PADSTR2("Drawee Reference", 10, '0');
                        false:
                            BillReference := PADSTR2('', 10, ' ');
                    end;

                    CustomerName := PadStr(Cust.Name, 24);
                    CustomerBankName := PadStr("Bank Account Name", 24);

                    case "Acceptation Code" of
                        "Acceptation Code"::"LCR NA":
                            AcceptationCode := '0';
                        "Acceptation Code"::LCR:
                            AcceptationCode := '1';
                        "Acceptation Code"::BOR:
                            AcceptationCode := '2'
                    end;

                    BankBranchNo := PADSTR2("Bank Branch No.", 5, '0');
                    AgencyCode := PADSTR2("Agency Code", 5, '0');
                    BankAccountNo := PADSTR2("Bank Account No.", 11, '0');
                    PrintAmount := FormatAmount(Amount, 12);
                    DueDate := Format("Due Date", 6, '<Day,2><Month,2><Year,2>');
                    CreationDate := Format("Payment Header"."Posting Date", 6, '<Day,2><Month,2><Year,2>');
                    ExportedText :=
                      RecordCode +
                      OperationCode +
                      Numbering +
                      PadStr('', 8) +
                      BillReference +
                      CustomerName +
                      CustomerBankName +
                      AcceptationCode +
                      PadStr('', 2) +
                      BankBranchNo +
                      AgencyCode +
                      BankAccountNo +
                      PrintAmount +
                      PadStr('', 4) +
                      DueDate +
                      CreationDate;

                    ExportFile.Write(PadStr(ExportedText, 160));
                end;

                trigger OnPostDataItem()
                var
                    PaymentHeader: Record "Payment Header";
                    RecordCode: Text;
                    OperationCode: Text;
                    Numbering: Text;
                    PrintAmount: Text;
                    ExportedText: Text;
                begin
                    LineNo := LineNo + 1;
                    RecordCode := '08';
                    OperationCode := '60';
                    Numbering := ConvertStr(Format(LineNo, 8), ' ', '0');
                    PrintAmount := FormatAmount("Payment Header".Amount, 12);
                    ExportedText :=
                      RecordCode +
                      OperationCode +
                      Numbering +
                      PadStr('', 90) +
                      PrintAmount;

                    ExportFile.Write(PadStr(ExportedText, 160));

                    PaymentHeader := "Payment Header";
                    PaymentHeader."File Export Completed" := true;
                    PaymentHeader.Modify();
                end;
            }

            trigger OnAfterGetRecord()
            var
                RecordCode: Text;
                OperationCode: Text;
                Numbering: Text;
                FromPaymentNo: Text;
                DeliveryDate: Text;
                CompanyName: Text;
                CompanyBankName: Text;
                EntryCode: Text;
                CurrencyIdentifier: Code[1];
                BankBranchNo: Text;
                AgencyCode: Text;
                BankAccountNo: Text;
                ExportedText: Text;
            begin
                if StrLen("Bank Branch No.") > 5 then
                    Error(Text002, "Account No.");

                if StrLen("Agency Code") > 5 then
                    Error(Text002, "Account No.");

                if StrLen("Bank Account No.") > 11 then
                    Error(Text002, "Account No.");

                if not "RIB Checked" then
                    Error(Text003, "Account No.");

                case "Currency Code" = '' of
                    true:
                        CurrencyUsed := '';
                    false:
                        CurrencyUsed := 'FRF';
                end;

                case CurrencyUsed = '' of
                    true:
                        CurrencyIdentifier := 'E';
                    false:
                        CurrencyIdentifier := 'F';
                end;

                LineNo := 1;

                CalcFields(Amount);

                RecordCode := '03';
                OperationCode := '60';
                Numbering := ConvertStr(Format(LineNo, 8), ' ', '0');
                FromPaymentNo := PadStr("National Issuer No.", 6);
                DeliveryDate := Format("Posting Date", 6, '<Day,2><Month,2><Year,2>');
                CompanyName := PadStr(CompanyInfo.Name, 24);
                CompanyBankName := PadStr("Bank Name", 24);
                EntryCode := Format(PaymentType + 1);
                BankBranchNo := PADSTR2("Bank Branch No.", 5, '0');
                AgencyCode := PADSTR2("Agency Code", 5, '0');
                BankAccountNo := PADSTR2("Bank Account No.", 11, '0');
                ExportedText :=
                  RecordCode +
                  OperationCode +
                  Numbering +
                  FromPaymentNo +
                  PadStr('', 6) +
                  DeliveryDate +
                  CompanyName +
                  CompanyBankName +
                  EntryCode +
                  PadStr('', 1) +
                  CurrencyIdentifier +
                  BankBranchNo +
                  AgencyCode +
                  BankAccountNo;

                ExportFile.Write(PadStr(ExportedText, 160));
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PaymentType; PaymentType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Type';
                        OptionCaption = 'Discount,Discount in Value,Cash after Due Date,Cash after Unpaid Delay';
                        ToolTip = 'Specifies the payment type for the ETEBAC file.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PaymentType := PaymentType::"Cash after Due Date";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        FileMgt: Codeunit "File Management";
        ToFile: Text[260];
    begin
        ExportFile.Close();
        ToFile := Text009;
        FileMgt.DownloadHandler(ExportFileName, GetCaption(), '', Text008, ToFile);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);

        GLSetup.Get();

        ExportFileName := FileMgt.ServerTempFileName('');

        ExportFile.TextMode := true;
        ExportFile.WriteMode := true;
        ExportFile.Create(ExportFileName);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        ExportFile: File;
        ExportFileName: Text[260];
        CurrencyUsed: Code[10];
        PaymentType: Option Discount,"Discount in Value","Cash after Due Date","Cash after Unpaid Delay";
        Text002: Label 'Bank Account No. %1 is too long. Please verify before continuing.';
        Text003: Label 'The RIB of the company''s bank account %1 is incorrect. Please verify before continuing.';
        Text004: Label 'You can only use %1.', Comment = '%1 - currency code';
        Text006: Label 'Bank Account No. %1 is too long. Please verify before continuing.';
        Text007: Label 'The RIB of bank account %1 of customer %2 is incorrect. Please verify before continuing.';
        Text008: Label 'Text Files|*.txt|All Files|*.*';
        Text009: Label 'default.txt';
        LineNo: Integer;

    local procedure GetCaption() Result: Text[50]
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ID: Integer;
    begin
        Result := '';
        if not Evaluate(ID, DelChr(CurrReport.ObjectId(false), '=', DelChr(CurrReport.ObjectId(false), '=', '0123456789'))) then
            exit;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ID) then
            exit;

        exit(CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(Result)));
    end;

    local procedure PADSTR2(String: Text[1024]; Length: Integer; FillCharacter: Text[1]): Text[1024]
    var
        PaddingLength: Integer;
    begin
        PaddingLength := Length - StrLen(String);

        case true of
            PaddingLength <= 0:
                exit(PadStr(String, Length, FillCharacter));
            PaddingLength > 0:
                exit(PadStr('', PaddingLength, FillCharacter) + String);
        end;
    end;

    local procedure FormatAmount(Amount: Decimal; Width: Integer): Text
    var
        FormatAmount: Text[50];
    begin
        FormatAmount := ConvertStr(Format(Amount, Width, '<Precision,2:2><Integer><Decimal><Comma,,>'), ' ', '0');
        FormatAmount := '0' + CopyStr(FormatAmount, 1, Width - 3) + CopyStr(FormatAmount, Width - 1, 2);
        exit(FormatAmount);
    end;
}

