// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.IO;

report 7000090 "Payment order - Export N34"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment order - Export N34';
    Permissions = TableData "Payment Order" = m;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Payment Order"; "Payment Order")
        {
            RequestFilterFields = "No.";
            dataitem("Cartera Doc."; "Cartera Doc.")
            {
                DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                DataItemTableView = sorting(Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code", Accepted, "Due Date") order(ascending) where(Type = const(Payable));

                trigger OnAfterGetRecord()
                begin
                    TestField("Payment Method Code");
                    DocType2 := DocMisc.DocType2("Payment Method Code");

                    TestField("Account No.");
                    Vendor.Get("Account No.");

                    VATRegVend := Vendor."VAT Registration No.";
                    VATRegVend := PadStr('', MaxStrLen(VATRegVend) - StrLen(VATRegVend), ' ') + VATRegVend;
                    RmgAmount := PadStr('', MaxStrLen(RmgAmount) - StrLen(RmgAmount), '0') + RmgAmount;

                    case true of
                        LCY = LCY::Euro:
                            if IsEuro then begin
                                TotalAmount := TotalAmount + "Remaining Amount";
                                RmgAmount := EuroAmount("Remaining Amount");
                            end else begin
                                RmgAmount := Format("Remaining Amount" * 100, 12, Text1100000);
                                TotalAmount := TotalAmount + "Remaining Amount";
                            end;
                        LCY = LCY::Other:
                            if IsEuro then begin
                                TotalAmount := TotalAmount + "Remaining Amount";
                                RmgAmount := EuroAmount("Remaining Amount");
                            end else begin
                                RmgAmount := Format("Remaining Amount" * 100, 12, Text1100000);
                                TotalAmount := TotalAmount + "Remaining Amount" * 100;
                            end;
                    end;

                    if DocType2 = '4' then begin
                        VendBankAccCode := "Cust./Vendor Bank Acc. Code";
                        if VendBankAcc.Get("Account No.", VendBankAccCode) then begin
                            VendCCCAccNo := VendBankAcc."CCC Bank Account No.";
                            VendCCCControlDigits := VendBankAcc."CCC Control Digits";
                            Vendor2 := VendBankAcc."CCC Bank No.";
                            VendCCCBankBranchNo := VendBankAcc."CCC Bank Branch No.";
                        end else begin
                            VendCCCAccNo := '';
                            VendCCCControlDigits := '';
                            Vendor2 := '';
                            VendCCCBankBranchNo := '';
                        end;
                    end else begin
                        TestField("Cust./Vendor Bank Acc. Code");
                        VendBankAccCode := "Cust./Vendor Bank Acc. Code";
                        VendBankAcc.Get("Account No.", VendBankAccCode);
                        VendCCCAccNo := VendBankAcc."CCC Bank Account No.";
                        VendCCCControlDigits := VendBankAcc."CCC Control Digits";
                        Vendor2 := VendBankAcc."CCC Bank No.";
                        VendCCCBankBranchNo := VendBankAcc."CCC Bank Branch No.";
                        if (Vendor2 = '') or (VendCCCBankBranchNo = '') or
                           (VendCCCControlDigits = '') or (VendCCCAccNo = '')
                        then
                            Error(Text1100003, VendBankAcc."Vendor No.");
                    end;

                    VendCCCAccNo := PadStr('', MaxStrLen(VendCCCAccNo) - StrLen(VendCCCAccNo), '0') + VendCCCAccNo;
                    VendCCCControlDigits := PadStr('', MaxStrLen(VendCCCControlDigits) - StrLen(VendCCCControlDigits), '0')
                      + VendCCCControlDigits;

                    if IsEuro then
                        if DocType2 = '4' then
                            DocType := '57'
                        else begin
                            DocType := '56';
                            VendBankAcc.TestField("CCC Bank Account No.");
                        end
                    else
                        if DocType2 = '4' then
                            DocType := '07'
                        else begin
                            DocType := '06';
                            VendBankAcc.TestField("CCC Bank Account No.");
                        end;

                    OutText := '06' + DocType + VATRegNo + VATRegVend + '010' + ConvertStr(RmgAmount, ' ', '0') +
                      ConvertStr(PadStr(Vendor2, 4, ' '), ' ', '0') + ConvertStr(PadStr(VendCCCBankBranchNo, 4, ' '), ' ', '0') +
                      ConvertStr(PadStr(VendCCCAccNo, 10, ' '), ' ', '0') +
                      '1' + '9' + PadStr('', 2, ' ') + PadStr(VendCCCControlDigits, 2, ' ') + PadStr('', 7, ' ');
                    OutFile.Write(OutText);

                    TotalReg := TotalReg + 1;
                    TotalDocVend := TotalDocVend + 1;

                    OutText := '06' + DocType + VATRegNo + VATRegVend + '011' + PadStr(Vendor.Name, 36, ' ')
                      + PadStr('', 7, ' ');
                    OutFile.Write(OutText);
                    TotalReg := TotalReg + 1;
                    if (DocType = '06') or (DocType = '56') then begin
                        OutText := '06' + DocType + VATRegNo + VATRegVend + '012' + PadStr(Vendor.Address, 36, ' ')
                          + PadStr('', 7, ' ');
                        OutFile.Write(OutText);

                        TotalReg := TotalReg + 1;

                        if Vendor."Address 2" <> '' then begin
                            OutText := '06' + DocType + VATRegNo + VATRegVend + '013' + PadStr(Vendor."Address 2", 36, ' ')
                              + PadStr('', 7, ' ');
                            OutFile.Write(OutText);

                            TotalReg := TotalReg + 1;
                        end;

                        OutText := '06' + DocType + VATRegNo + VATRegVend + '014' + PadStr(Vendor."Post Code" + ' ' + Vendor.City, 36, ' ')
                          + PadStr('', 7, ' ');
                        OutFile.Write(OutText);

                        TotalReg := TotalReg + 1;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField("Bank Account No.");
                BankAcc.Get("Bank Account No.");

                CCCBankNo := BankAcc."CCC Bank No.";
                CCCBankNo := PadStr('', MaxStrLen(CCCBankNo) - StrLen(CCCBankNo), '0') + CCCBankNo;

                CCCBankBranchNo := BankAcc."CCC Bank Branch No.";
                CCCBankBranchNo := PadStr('', MaxStrLen(CCCBankBranchNo) - StrLen(CCCBankBranchNo), '0') + CCCBankBranchNo;

                CCCAccNo := BankAcc."CCC Bank Account No.";
                CCCAccNo := PadStr('', MaxStrLen(CCCAccNo) - StrLen(CCCAccNo), '0') + CCCAccNo;

                CCCControlDigits := BankAcc."CCC Control Digits";
                CCCControlDigits := PadStr('', MaxStrLen(CCCControlDigits) - StrLen(CCCControlDigits), '0') + CCCControlDigits;

                if "Posting Date" = 0D then
                    PostDate := PadStr('', 6, '0')
                else
                    PostDate := Format("Posting Date", 0, Text1100002);

                OutText := '03' + RegisterString + VATRegNo + PadStr('', 12, ' ') + '001' +
                  Format(DeliveryDate, 0, Text1100002) + PostDate +
                  CCCBankNo + CCCBankBranchNo + CCCAccNo + Relat + PadStr('', 3, ' ') + CCCControlDigits + PadStr('', 7, ' ');
                OutFile.Write(OutText);

                TotalReg := TotalReg + 1;

                OutText := '03' + RegisterString + VATRegNo + PadStr('', 12, ' ') + '002' +
                  PadStr(CompanyInfo.Name, 36, ' ') + PadStr('', 7, ' ');
                OutFile.Write(OutText);

                TotalReg := TotalReg + 1;

                OutText := '03' + RegisterString + VATRegNo + PadStr('', 12, ' ') + '003' +
                  PadStr(CompanyInfo.Address, 36, ' ') + PadStr('', 7, ' ');
                OutFile.Write(OutText);

                TotalReg := TotalReg + 1;

                OutText := '03' + RegisterString + VATRegNo + PadStr('', 12, ' ') + '004' +
                  PadStr(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, 36, ' ') + PadStr('', 7, ' ');
                OutFile.Write(OutText);

                TotalReg := TotalReg + 1;
                "Elect. Pmts Exported" := true;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                if CheckErrors then
                    Relat := '1'
                else
                    Relat := '0';

                Find('-');
                IsEuro := DocMisc.GetRegisterCode("Currency Code", RegisterCode, RegisterString);
                if RegisterCode <> 0 then
                    RegisterString := '56'
                else
                    RegisterString := '06';
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
                    field(crelation; CheckErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Relation';
                        ToolTip = 'Specifies if you want the bank to send you a detailed list of all transfer charges. Deselect the check box if you want a simple total of charges for all the transfers made.';
                    }
                    field(DeliveryDate; DeliveryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delivery Date';
                        ToolTip = 'Specifies a number to identify the operations declaration.';
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
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");
        VATRegNo := InsStr(PadStr('', MaxStrLen(VATRegNo) - StrLen(CompanyInfo."VAT Registration No."), ' '),
            CompanyInfo."VAT Registration No.", 1 + MaxStrLen(VATRegNo) - StrLen(CompanyInfo."VAT Registration No."));
        SilentMode := false;
    end;

    trigger OnPostReport()
    begin
        TotalReg := TotalReg + 1;
        case true of
            LCY = LCY::Euro:
                if IsEuro then
                    DocAmount := EuroAmount(TotalAmount)
                else
                    DocAmount := ConvertStr(Format(TotalAmount, 12, Text1100000), ' ', '0');
            LCY = LCY::Other:
                if IsEuro then
                    DocAmount := EuroAmount(TotalAmount)
                else
                    DocAmount := ConvertStr(Format(TotalAmount, 12, Text1100000), ' ', '0');
        end;

        OutText := '08' + RegisterString + VATRegNo + PadStr('', 15, ' ') +
          DocAmount +
          (PadStr('', 8 - StrLen(Format(TotalDocVend)), '0') + Format(TotalDocVend, 0, 1)) +
          (PadStr('', 10 - StrLen(Format(TotalReg)), '0') + Format(TotalReg, 0, 1)) +
          PadStr('', 13, ' ');
        OutFile.Write(OutText);

        OutFile.Close();

        if SilentMode then
            FileMgt.CopyServerFile(ExternalFile, SilentModeFileName, true)
        else
            Download(ExternalFile, '', 'C:', Text10701, ToFile);
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
        Text1100000: Label '<Integer>', Locked = true;
        Text1100002: Label '<Day,2><month,2><year>', Locked = true;
        Text1100003: Label 'Some data from the Bank Account of Vendor %1 are missing.';
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        BankAcc: Record "Bank Account";
        VendBankAcc: Record "Vendor Bank Account";
        GLSetup: Record "General Ledger Setup";
        DocMisc: Codeunit "Document-Misc";
        FileMgt: Codeunit "File Management";
        OutFile: File;
        ExternalFile: Text[1024];
        CheckErrors: Boolean;
        VATRegNo: Text[10];
        CCCBankNo: Text[4];
        VATRegVend: Text[12];
        VendCCCBankBranchNo: Text[4];
        CCCBankBranchNo: Text[4];
        VendCCCControlDigits: Text[2];
        CCCControlDigits: Text[2];
        CCCAccNo: Text[10];
        VendCCCAccNo: Text[10];
        Vendor2: Text[4];
        TotalReg: Decimal;
        TotalDocVend: Decimal;
        TotalAmount: Decimal;
        OutText: Text[85];
        DeliveryDate: Date;
        Relat: Text[1];
        DocType2: Code[10];
        DocType: Text[2];
        RmgAmount: Text[12];
        VendBankAccCode: Code[20];
        PostDate: Text[6];
        LCY: Option Euro,Other;
        IsEuro: Boolean;
        RegisterCode: Integer;
        RegisterString: Text[2];
        DocAmount: Text[12];
        ToFile: Text[1024];
        Text10701: Label 'ASC Files (*.asc)|*.asc|All Files (*.*)|*.*';
        Text10702: Label 'ORDENPAGO.ASC';
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure EuroAmount(Amount: Decimal): Text[12]
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

        while StrLen(TextAmount) < 12 do
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

