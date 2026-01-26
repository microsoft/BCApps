// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.IO;

report 7000093 "Bill group - Export N32"
{
    Caption = 'Bill group - Export N32';
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
                DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Receivable));

                trigger OnAfterGetRecord()
                begin
                    DocNo := CopyStr("Document No.", 1, 10) + '/' + "No.";

                    DocType := DocMisc.DocType("Payment Method Code");

                    CustLedgEntry.Get("Entry No.");

                    Customer.Get(CustLedgEntry."Customer No.");
                    if not CustBankAcc.Get(CustLedgEntry."Customer No.", "Cust./Vendor Bank Acc. Code") then
                        Error(Text1100007);

                    Customer2 := CustBankAcc."CCC Bank No.";
                    CustCCCBankBranchNo := CustBankAcc."CCC Bank Branch No.";
                    CustCCCControlDigits := CustBankAcc."CCC Control Digits";
                    CustCCCAccNo := CustBankAcc."CCC Bank Account No.";

                    if (Customer2 = '') or (CustCCCBankBranchNo = '') or
                       (CustCCCControlDigits = '') or (CustCCCAccNo = '')
                    then
                        Error(Text1100008, CustBankAcc."Customer No.");

                    CustAddress[1] := Customer.Name;
                    CustAddress[2] := Customer.Address;
                    CustAddress[3] := Customer.City;
                    CustAddress[4] := Customer."Post Code";

                    AdditionalInfo := Text1100009 + "Document No." + '/' + "No.";

                    if Accepted = Accepted::Yes then
                        IsAccepted := '1'
                    else
                        IsAccepted := '2';

                    TotalDocs := TotalDocs + 1;
                    TotalPosted := TotalPosted + 3;

                    case true of
                        LCY = LCY::Euro:
                            if IsEuro then begin
                                DocAmount := DelStr(EuroAmount("Remaining Amt. (LCY)"), 1, 1);
                                TotalAmount := TotalAmount + "Remaining Amt. (LCY)";
                            end else begin
                                DocAmount := ConvertStr(Format("Remaining Amount", 9, Text1100010), ' ', '0');
                                TotalAmount := TotalAmount + "Remaining Amount";
                            end;
                        LCY = LCY::Other:
                            begin
                                if IsEuro then
                                    DocAmount := DelStr(EuroAmount("Remaining Amount"), 1, 1)
                                else
                                    DocAmount := ConvertStr(Format("Remaining Amount", 9, Text1100010), ' ', '0');
                                TotalAmount := TotalAmount + "Remaining Amount";
                            end;
                    end;

                    Clear(OutText);
                    OutText :=
                      '25' + RegisterString + '  ' + PadStr(DocNo, 15, ' ') + Format(WorkDate(), 6, 5) + PadStr(BillGrNo, 4, '0') +
                      PadStr(CopyStr(CompanyInfo."Post Code", 1, 2), 2, '0') + PadStr('', 9, ' ') + PadStr(CompanyInfo.City, 20, ' ') +
                      PadStr('', 25, ' ') + DocAmount +
                      PadStr('', 15, ' ') + Format("Due Date", 6, 5);
                    OutFile.Write(OutText);

                    Clear(OutText);
                    OutText :=
                      '26' + RegisterString + '  ' + PadStr(DocNo, 15, ' ') + PadStr('', 2, ' ') + DocType + Format("Bill Group"."Posting Date", 6, 5) +
                      IsAccepted + Expenses + Customer2 + CustCCCBankBranchNo + CustCCCControlDigits + CustCCCAccNo +
                      PadStr(CompanyInfo.Name, 34, ' ') + PadStr(CustAddress[1], 34, ' ') + PadStr(AdditionalInfo, 3, ' ');
                    OutFile.Write(OutText);

                    Clear(OutText);
                    OutText :=
                      '27' + RegisterString + '  ' + PadStr(DocNo, 15, ' ') + PadStr('', 2, ' ') + PadStr(CustAddress[2], 34, ' ') +
                      PadStr(CustAddress[4], 5, ' ') + PadStr(CustAddress[3], 20, ' ') + PadStr(CustAddress[4], 2, ' ');
                    OutFile.Write(OutText);
                end;

                trigger OnPostDataItem()
                begin
                    case true of
                        LCY = LCY::Euro:
                            if IsEuro then begin
                                "Bill Group".CalcFields("Amount (LCY)");
                                BillGrAmount := EuroAmount("Bill Group"."Amount (LCY)")
                            end else begin
                                "Bill Group".CalcFields(Amount);
                                BillGrAmount := ConvertStr(Format("Bill Group".Amount, 10, Text1100006), ' ', '0')
                            end;
                        LCY = LCY::Other:
                            if IsEuro then begin
                                "Bill Group".CalcFields(Amount);
                                BillGrAmount := EuroAmount("Bill Group".Amount)
                            end else begin
                                "Bill Group".CalcFields(Amount);
                                BillGrAmount := ConvertStr(Format("Bill Group".Amount, 10, Text1100006), ' ', '0')
                            end;
                    end;

                    TotalPosted := TotalPosted + 2;
                    Clear(OutText);
                    OutText :=
                      '71' + RegisterString + '  ' + Format(WorkDate(), 6, 5) + PadStr(BillGrNo, 4, '0') + PadStr('', 59, ' ') +
                      BillGrAmount + PadStr('', 46, ' ') +
                      ConvertStr(Format(TotalPosted, 7, Text1100006), ' ', '0') +
                      ConvertStr(Format(TotalDocs, 6, Text1100006), ' ', '0');
                    OutFile.Write(OutText);

                    DiskTotalPosted := DiskTotalPosted + TotalPosted;
                    DiskTotalDocs := DiskTotalDocs + TotalDocs;
                end;

                trigger OnPreDataItem()
                begin
                    TotalDocs := 0;
                    TotalPosted := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if StrLen("No.") <= 4 then
                    BillGrNo := PadStr("No.", 4, '0')
                else
                    BillGrNo := CopyStr("No.", StrLen("No.") - 3, 4);

                Clear(OutText);
                OutText :=
                  '11' + RegisterString + '  ' + Format(WorkDate(), 6, 5) + PadStr(ConvertStr(BillGrNo, ' ', '0'), 4, '0') +
                  PadStr('', 12, ' ') + PadStr(VATRegNo, 9, ' ') + PadStr(BankSuffix, 6, ' ') + PrintedDocs2 + PadStr('', 21, ' ') +
                  ConvertStr(CCCBankNo, ' ', '0') + ConvertStr(CCCBankBranchNo, ' ', '0') +
                  ConvertStr(CCCControlDigits, ' ', '0') + ConvertStr(CCCAccNo, ' ', '0') +
                  ConvertStr(CCCBankNo, ' ', '0') + ConvertStr(CCCBankBranchNo, ' ', '0') +
                  ConvertStr(CCCControlDigits, ' ', '0') + ConvertStr(CCCAccNo, ' ', '0') +
                  ConvertStr(CCCBankNo, ' ', '0') + ConvertStr(CCCBankBranchNo, ' ', '0') +
                  ConvertStr(CCCControlDigits, ' ', '0') + ConvertStr(CCCAccNo, ' ', '0');
                OutFile.Write(OutText);
            end;

            trigger OnPostDataItem()
            var
                FileMgt: Codeunit "File Management";
            begin
                "No. Printed" := "No. Printed" + 1;
                Clear(OutText);

                if IsEuro then
                    OutText :=
                      '98' + RegisterString + '  ' + PadStr('', 69, ' ') + EuroAmount(TotalAmount) +
                      PadStr('', 41, ' ') + ConvertStr(Format(TotalBillGr, 5, Text1100006), ' ', '0') +
                      ConvertStr(Format(DiskTotalPosted + 2, 7, Text1100006), ' ', '0') +
                      ConvertStr(Format(DiskTotalDocs, 6, Text1100006), ' ', '0')
                else
                    OutText :=
                      '98' + RegisterString + '  ' + PadStr('', 69, ' ') + ConvertStr(Format(TotalAmount, 10, Text1100006), ' ', '0') +
                      PadStr('', 41, ' ') + ConvertStr(Format(TotalBillGr, 5, Text1100006), ' ', '0') +
                      ConvertStr(Format(DiskTotalPosted + 2, 7, Text1100006), ' ', '0') +
                      ConvertStr(Format(DiskTotalDocs, 6, Text1100006), ' ', '0');

                OutFile.Write(OutText);
                OutFile.Close();

                if SilentMode then
                    FileMgt.CopyServerFile(ExternalFile, SilentModeFileName, true)
                else
                    Download(ExternalFile, '', 'C:', Text10701, ToFile);
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();

                Find('-');

                if BankSuffix = '' then
                    Error(Text1100000);

                if BankSuffixBankAcc = '' then begin
                    Suffix.SetRange(Suffix, BankSuffix);
                    if Suffix.FindFirst() then
                        BankSuffixBankAcc := Suffix."Bank Acc. Code";
                end;

                IsEuro := DocMisc.GetRegisterCode("Currency Code", TotalBillGr, RegisterString);

                if not DocMisc.CheckBankSuffix(BankSuffixBankAcc, "Bank Account No.") then
                    if not Confirm(Text1100002 +
                         Text1100003,
                         false,
                         FieldCaption("Bank Account No."),
                         TableCaption)
                    then
                        Error(Text1100004);

                TotalBillGr := Count;

                if StrLen("No.") <= 4 then
                    DiskNo := PadStr("No.", 4, '0')
                else
                    DiskNo := CopyStr("No.", StrLen("No.") - 3, 4);

                BankAcc.Get("Bank Account No.");
                CCCBankNo := BankAcc."CCC Bank No.";
                CCCBankBranchNo := BankAcc."CCC Bank Branch No.";
                CCCControlDigits := BankAcc."CCC Control Digits";
                CCCAccNo := BankAcc."CCC Bank Account No.";

                if (CCCBankNo = '') or (CCCBankBranchNo = '') or
                   (CCCControlDigits = '') or (CCCAccNo = '')
                then
                    Error(Text1100005, BankAcc."No.");

                Clear(OutText);
                OutText :=
                  '02' + RegisterString + '  ' + Format(WorkDate(), 6, 5) + PadStr(ConvertStr(DiskNo, ' ', '0'), 4, '0') +
                  PadStr('', 35, ' ') + PadStr(ConvertStr(CCCBankNo, ' ', '0'), 4, '0') +
                  PadStr(ConvertStr(CCCBankBranchNo, ' ', '0'), 4, '0');
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
                    field(WithExpenses; WithExpenses)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Expenses';
                        ToolTip = 'Specifies if you want the bills included in the bill group to show expenses. Deselect the check box (default option) when the bills included will be without expenses.';
                    }
                    field(PrintedDocs; PrintedDocs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Printed Bills Attached';
                        ToolTip = 'Specifies if the printed bill will be attached to the export.';
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
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        VATRegNo := CopyStr(DelChr(CompanyInfo."VAT Registration No.", '=', ' .-/'), 1, 9);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        if WithExpenses then
            Expenses := '1'
        else
            Expenses := '0';

        if PrintedDocs then
            PrintedDocs2 := '0'
        else
            PrintedDocs2 := '1';

        OutFile.TextMode := true;
        OutFile.WriteMode := true;
        ExternalFile := FileMgt.ServerTempFileName('');
        ToFile := Text10702;
        OutFile.Create(ExternalFile);

        TotalAmount := 0;
        DiskTotalPosted := 0;
        DiskTotalDocs := 0;
    end;

    var
        Text1100000: Label 'Bank Suffix cannot be blank.';
        Text1100002: Label 'The Bank Suffix selected belongs to a %1  different than the %2. \';
        Text1100003: Label 'Do you want to continue?.';
        Text1100004: Label 'Process cancelled by request of user.';
        Text1100005: Label 'Some data for Bank Account %1 are missing.';
        Text1100006: Label '<integer>', Locked = true;
        Text1100007: Label 'There is no bank account information for Customer %1.';
        Text1100008: Label 'Some data from the Bank Account of Customer %1 are missing.';
        Text1100009: Label 'Bill';
        Text1100010: Label '<Integer>', Locked = true;
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAcc: Record "Bank Account";
        CustBankAcc: Record "Customer Bank Account";
        DocMisc: Codeunit "Document-Misc";
        OutFile: File;
        ExternalFile: Text[1024];
        WithExpenses: Boolean;
        PrintedDocs: Boolean;
        VATRegNo: Text[9];
        CCCBankNo: Text[4];
        Customer2: Text[4];
        CCCBankBranchNo: Text[4];
        CustCCCBankBranchNo: Text[4];
        CCCControlDigits: Text[2];
        CustCCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        CustCCCAccNo: Text[10];
        DiskNo: Code[4];
        BillGrNo: Code[4];
        DocNo: Code[15];
        DocType: Code[1];
        AdditionalInfo: Text[30];
        CustAddress: array[4] of Text[100];
        TotalBillGr: Integer;
        TotalPosted: Integer;
        TotalDocs: Integer;
        DiskTotalPosted: Integer;
        DiskTotalDocs: Integer;
        TotalAmount: Decimal;
        DocAmount: Text[10];
        BillGrAmount: Text[10];
        Expenses: Code[1];
        IsAccepted: Code[1];
        PrintedDocs2: Code[1];
        OutText: Text[150];
        RegisterString: Text[2];
        IsEuro: Boolean;
        LCY: Option Euro,Other;
        BankSuffix: Code[3];
        BankSuffixBankAcc: Code[20];
        Suffix: Record Suffix;
        ToFile: Text[1024];
        Text10701: Label 'ASC Files (*.asc)|*.asc|All Files (*.*)|*.*';
        Text10702: Label 'EFECTOS.ASC';
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure EuroAmount(Amount: Decimal): Text[10]
    var
        TextAmount: Text[15];
    begin
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
    end;

    [Scope('OnPrem')]
    procedure EnableSilentMode(FileName: Text)
    begin
        SilentMode := true;
        SilentModeFileName := FileName;
    end;
}

