// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.IO;

report 7000091 "Bill group - Export N58"
{
    Caption = 'Bill group - Export N58';
    Permissions = TableData "Bill Group" = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bill Group"; "Bill Group")
        {
            DataItemTableView = sorting("No.") where(Factoring = const(" "));
            RequestFilterFields = "No.";
            dataitem(Doc; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where(Type = const(Receivable));

                trigger OnAfterGetRecord()
                begin
                    DocMisc.DocType("Payment Method Code");

                    CustLedgEntry.Get("Entry No.");

                    Customer.Get(CustLedgEntry."Customer No.");
                    if not CustBankAcc.Get(CustLedgEntry."Customer No.", "Cust./Vendor Bank Acc. Code") then begin
                        CustCCCBankCode := '0000';
                        CustCCCBankBranchNo := '0000';
                        CustCCCControlDigits := '00';
                        CustCCCAccNo := '0000000000';
                        NotDom := true;
                    end else begin
                        CustCCCBankCode := CustBankAcc."CCC Bank No.";
                        CustCCCBankBranchNo := CustBankAcc."CCC Bank Branch No.";
                        CustCCCControlDigits := CustBankAcc."CCC Control Digits";
                        CustCCCAccNo := CustBankAcc."CCC Bank Account No.";
                        NotDom := false;
                        if CheckExportErrors then begin
                            DocMisc.CheckControlDigit(CustCCCControlDigits, CustCCCBankCode, CustCCCAccNo, CustCCCBankBranchNo);
                            if (CustBankAcc."CCC Control Digits" <> CustCCCControlDigits) and (CustCCCControlDigits <> '**') then begin
                                CustBankAcc."CCC Control Digits" := CustCCCControlDigits;
                                CustBankAcc.Modify();
                            end;
                        end;
                    end;

                    if (CustCCCBankCode = '') or (CustCCCBankBranchNo = '') or
                       (CustCCCControlDigits = '') or (CustCCCAccNo = '')
                    then begin
                        CustCCCBankCode := '0000';
                        CustCCCBankBranchNo := '0000';
                        CustCCCControlDigits := '00';
                        CustCCCAccNo := '0000000000';
                        NotDom := true;
                    end;

                    CustAddress[1] := Customer.Name;
                    CustAddress[2] := Customer.Address;
                    CustAddress[3] := Customer.City;
                    CustAddress[4] := Customer."Post Code";
                    CustNoNIF := Customer."VAT Registration No.";
#pragma warning disable AA0139
                    AdditionalInfo := Text1100008Lbl + "Document No." + '/' + "No.";
                    AdditionalInfo2 := "Document No." + '/' + "No.";
#pragma warning restore AA0139

                    TotalDoc := TotalDoc + 1;
                    TotalDocsCust := TotalDocsCust + 1;
                    TotalPrintedCust := TotalPrintedCust + 1;
                    TotalPosted := TotalPosted + 3;

                    case true of
                        LCY = LCY::Euro:
                            if IsEuro then
                                DocAmount := EuroAmount("Remaining Amt. (LCY)")
                            else
#pragma warning disable AA0139
                                DocAmount := ConvertStr(Format("Remaining Amount", 10, Text1100006Lbl), ' ', '0');
#pragma warning restore AA0139
                        LCY = LCY::Other:
                            if IsEuro then
                                DocAmount := EuroAmount("Remaining Amount")
                            else
#pragma warning disable AA0139
                                DocAmount := ConvertStr(Format("Remaining Amount", 10, Text1100006Lbl), ' ', '0');
#pragma warning restore AA0139
                    end;

                    RegisterCode2 := RegisterCode + 6;
                    DLDACurrency();

                    Clear(OutText);
                    OutText :=
                      RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                      PadStr(Format(CustNoNIF), 12, ' ') +
                      PadStr(Format(Customer.Name), 40, ' ') + ConvertStr(PadStr(CustCCCBankCode, 4, ' '), ' ', '0') +
                      ConvertStr(PadStr(CustCCCBankBranchNo, 4, ' '), ' ', '0') + PadStr(CustCCCControlDigits, 2, ' ') +
                      ConvertStr(PadStr(CustCCCAccNo, 10, ' '), ' ', '0') + DocAmount +
                      Text1100009Lbl + PadStr(AdditionalInfo2, 10, ' ') + PadStr(AdditionalInfo, 40, ' ') +
                      Format("Due Date", 6, 5) + PadStr('', 2, ' ');

                    OutFile.Write(OutText);
                    PostalCode.Get(CompanyInfo."Post Code", CompanyInfo.City);

                    if NotDom then begin
                        Clear(OutText);
                        OutText :=
                          RegisterString + '76' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                          PadStr(Format(CustNoNIF), 12, ' ') + PadStr(CustAddress[2], 40, ' ') +
                          PadStr(CustAddress[3], 35, ' ') + PadStr(CustAddress[4], 8, '0') +
                          PadStr(CompanyInfo.City, 35, ' ') + CopyStr(PostalCode."County Code", 1, 2) +
                          Format("Bill Group"."Posting Date", 6, 5) + PadStr('', 8, ' ');

                        OutFile.Write(OutText);
                        TotalPrintedCust := TotalPrintedCust + 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    Clear(OutText);
                    TotalPrintedCust := TotalPrintedCust + 1;

                    case true of
                        LCY = LCY::Euro:
                            if IsEuro then begin
                                "Bill Group".CalcFields("Amount (LCY)");
                                TotalAmount := "Bill Group"."Amount (LCY)" + TotalAmount;
                                BillGrAmount := EuroAmount("Bill Group"."Amount (LCY)")
                            end else begin
                                "Bill Group".CalcFields(Amount);
                                TotalAmount := "Bill Group".Amount + TotalAmount;
#pragma warning disable AA0139
                                BillGrAmount := ConvertStr(Format("Bill Group".Amount, 10, Text1100007Lbl), ' ', '0')
#pragma warning restore AA0139
                            end;
                        LCY = LCY::Other:
                            if IsEuro then begin
                                "Bill Group".CalcFields(Amount);
                                TotalAmount := "Bill Group".Amount + TotalAmount;
                                BillGrAmount := EuroAmount("Bill Group".Amount)
                            end else begin
                                "Bill Group".CalcFields(Amount);
                                TotalAmount := "Bill Group".Amount + TotalAmount;
#pragma warning disable AA0139
                                BillGrAmount := ConvertStr(Format("Bill Group".Amount, 10, Text1100007Lbl), ' ', '0')
#pragma warning restore AA0139
                            end;
                    end;

                    RegisterCode2 := RegisterCode + 8;
                    DLDACurrency();

                    OutText :=
                      RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                      PadStr('', 12, ' ') + PadStr('', 40, ' ') +
                      PadStr('', 20, ' ') + BillGrAmount + PadStr('', 6, ' ') + ConvertStr(Format(TotalDocsCust, 10, Text1100007Lbl), ' ', '0') +
                      ConvertStr(Format(TotalPrintedCust, 10, Text1100007Lbl), ' ', '0') + PadStr('', 20, ' ') + PadStr('', 18, ' ');
                    OutFile.Write(OutText);

                    TotalDocsCust := 0;
                    TotalPrinted := TotalPrinted + TotalPrintedCust;
                    TotalPrintedCust := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RegisterCode2 := RegisterCode + 3;
                DLDACurrency();

                Clear(OutText);
                OutText :=
                  RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                  Format(WorkDate(), 6, 5) + PadStr('', 6, ' ') +
                  PadStr(CompanyInfo.Name, 40, ' ') + ConvertStr(CCCBankNo, ' ', '0') +
                  ConvertStr(CCCBankBranchNo, ' ', '0') + ConvertStr(CCCControlDigits, ' ', '0') +
                  ConvertStr(CCCAccNo, ' ', '0') + PadStr('', 8, ' ') + '06' + PadStr('', 10, ' ') +
                  PadStr('', 40, ' ') + PadStr('', 2, ' ') + '000000000' + PadStr('', 3, ' ');
                OutFile.Write(OutText);

                TotalPrintedCust := TotalPrintedCust + 1;
            end;

            trigger OnPostDataItem()
            var
                FileMgt: Codeunit "File Management";
            begin
                "No. Printed" := "No. Printed" + 1;
                TotalPrinted := TotalPrinted + 2;

                RegisterCode2 := RegisterCode + 9;
                DLDACurrency();

                if IsEuro then
                    OutText :=
                      RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                      PadStr('', 12, ' ') + PadStr('', 40, ' ') +
                      '0001' + PadStr('', 16, ' ') + EuroAmount(TotalAmount) + PadStr('', 6, ' ') +
                      ConvertStr(Format(TotalDoc, 10, Text1100006Lbl), ' ', '0') + ConvertStr(Format(TotalPrinted, 10, Text1100006Lbl), ' ', '0') +
                      PadStr('', 20, ' ') + PadStr('', 18, ' ')
                else
                    OutText :=
                      RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                      PadStr('', 12, ' ') + PadStr('', 40, ' ') +
                      '0001' + PadStr('', 16, ' ') + ConvertStr(Format(TotalAmount, 10, Text1100007Lbl), ' ', '0') + PadStr('', 6, ' ') +
                      ConvertStr(Format(TotalDoc, 10, Text1100007Lbl), ' ', '0') + ConvertStr(Format(TotalPrinted, 10, Text1100007Lbl), ' ', '0') +
                      PadStr('', 20, ' ') + PadStr('', 18, ' ');

                OutFile.Write(OutText);
                OutFile.Close();

                if SilentMode then
                    FileMgt.CopyServerFile(ExternalFile, SilentModeFileName, true)
                else
#pragma warning disable AA0139
                    Download(ExternalFile, '', 'C:', FilterLbl, ToFile);
#pragma warning restore AA0139
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();

                Find('-');

                if ExportBankSuffix = '' then
                    Error(Text1100000Lbl);

                if BankSuffixBankAcc = '' then begin
                    Suffix.SetRange(Suffix, ExportBankSuffix);
                    if Suffix.FindFirst() then
                        BankSuffixBankAcc := Suffix."Bank Acc. Code";
                end;

                if not DocMisc.CheckBankSuffix(BankSuffixBankAcc, "Bank Account No.") then
                    if not Confirm(Text1100001Lbl +
                         Text1100002Lbl,
                         false,
                         FieldCaption("Bank Account No."),
                         TableCaption)
                    then
                        Error(Text1100003Lbl);

                BankAcc.Get("Bank Account No.");
                CCCBankNo := BankAcc."CCC Bank No.";
                CCCBankBranchNo := BankAcc."CCC Bank Branch No.";
                CCCControlDigits := BankAcc."CCC Control Digits";
                CCCAccNo := BankAcc."CCC Bank Account No.";

                if (CCCBankNo = '') or (CCCBankBranchNo = '') or
                   (CCCControlDigits = '') or (CCCAccNo = '')
                then
                    Error(Text1100004Lbl, BankAcc."No.");

                IsEuro := DocMisc.GetRegisterCode("Currency Code", RegisterCode, RegisterString);

                RegisterCode2 := RegisterCode + 1;
                DLDACurrency();

                Clear(OutText);
                OutText :=
                  RegisterString + '70' + Format(CompanyInfo."VAT Registration No.", 9) + PadStr(ExportBankSuffix, 3, ' ') +
                  Format(WorkDate(), 6, 5) + PadStr('', 6, ' ') +
                  PadStr(CompanyInfo.Name, 40, ' ') + PadStr('', 20, ' ') + ConvertStr(BankAcc."CCC Bank No.", ' ', '0') +
                  ConvertStr(BankAcc."CCC Bank Branch No.", ' ', '0') + PadStr('', 12, ' ') + PadStr('', 40, ' ') + PadStr('', 14, ' ');
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
                    field(CheckErrors; CheckExportErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Errors';
                        ToolTip = 'Specifies if you want error messages when sending the norms to magnetic media.';
                    }
                    field(BankSuffix; ExportBankSuffix)
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
                                ExportBankSuffix := Suffix.Suffix;
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
                ExternalFile := 'C:\' + Text10702Lbl;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        VATRegNo := CopyStr(DelChr(CompanyInfo."VAT Registration No.", '=', ' .-/'), 1, 9);
        SilentMode := false;
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        OutFile.TextMode := true;
        OutFile.WriteMode := true;
#pragma warning disable AA0139
        ExternalFile := FileMgt.ServerTempFileName('');
#pragma warning restore AA0139
        ToFile := Text10702Lbl;
        OutFile.Create(ExternalFile);
    end;

    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        CustBankAcc: Record "Customer Bank Account";
        PostalCode: Record "Post Code";
        Suffix: Record Suffix;
        DocMisc: Codeunit "Document-Misc";
        Text1100000Lbl: Label 'Bank Suffix cannot be blank.';
        Text1100001Lbl: Label 'The Bank Suffix selected belongs to a %1  different than the %2. \', Comment = '%1 = Bank Account No. field caption, %2 = Bill Group table caption';
        Text1100002Lbl: Label 'Do you want to continue?.';
        Text1100003Lbl: Label 'Process cancelled by request of user.';
        Text1100004Lbl: Label 'Some data for Bank Account %1 are missing.', Comment = '%1 = Bank account number';
        Text1100006Lbl: Label '<Integer>', Locked = true;
        Text1100007Lbl: Label '<integer>', Locked = true;
        Text1100008Lbl: Label 'Bill';
        Text1100009Lbl: Label 'DEVOL.';
        OutFile: File;
        ExternalFile: Text[1024];
        CheckExportErrors: Boolean;
        NotDom: Boolean;
        VATRegNo: Text[9];
        CCCBankNo: Text[4];
        CustCCCBankCode: Text[4];
        CCCBankBranchNo: Text[4];
        CustCCCBankBranchNo: Text[4];
        CCCControlDigits: Text[2];
        CustCCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        CustCCCAccNo: Text[10];
        AdditionalInfo: Text[30];
        AdditionalInfo2: Text[30];
        CustAddress: array[4] of Text[100];
        TotalPosted: Decimal;
        TotalDoc: Decimal;
        TotalDocsCust: Decimal;
        TotalPrintedCust: Decimal;
        TotalPrinted: Decimal;
        TotalAmount: Decimal;
        OutText: Text[162];
        RegisterCode: Integer;
        RegisterCode2: Integer;
        RegisterString: Text[2];
        DocAmount: Text[10];
        BillGrAmount: Text[10];
        CustNoNIF: Text[20];
        IsEuro: Boolean;
        LCY: Option Euro,Other;
        ExportBankSuffix: Code[3];
        BankSuffixBankAcc: Code[20];
        ToFile: Text[1024];
        FilterLbl: Label 'ASC Files (*.asc)|*.asc|All Files (*.*)|*.*';
        Text10702Lbl: Label 'EFECTOS.ASC';
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure DLDACurrency()
    begin
        if StrLen(Format(RegisterCode)) = 1 then
            RegisterString := '0' + Format(RegisterCode2)
        else
            RegisterString := Format(RegisterCode2);
    end;

    [Scope('OnPrem')]
    procedure EuroAmount(Amount: Decimal): Text[10]
    var
        TextAmount: Text[15];
    begin
#pragma warning disable AA0139
        TextAmount := ConvertStr(Format(Amount), ' ', '0');
        if StrPos(TextAmount, ',') = 0 then
            TextAmount := TextAmount + '00'
        else begin
            if StrLen(CopyStr(TextAmount, StrPos(TextAmount, ','), StrLen(TextAmount))) = 2 then
                TextAmount := TextAmount + '0';
            TextAmount := DelChr(TextAmount, '=', ',');
        end;
        if StrPos(TextAmount, '.') = 0 then
            TextAmount := TextAmount
        else
            TextAmount := DelChr(TextAmount, '=', '.');

        while StrLen(TextAmount) < 10 do
            TextAmount := '0' + TextAmount;

        exit(TextAmount);
#pragma warning restore AA0139
    end;

    [Scope('OnPrem')]
    procedure EnableSilentMode(FileName: Text)
    begin
        SilentMode := true;
        SilentModeFileName := FileName;
    end;
}

