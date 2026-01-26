// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

report 11000008 "Export BBV"
{
    Caption = 'Export BBV';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment History"; "Payment History")
        {
            DataItemTableView = sorting("Our Bank", "Run No.");
            RequestFilterFields = "Our Bank", "Export Protocol", "Run No.", Status, Export;
            dataitem("Payment History Line"; "Payment History Line")
            {
                DataItemLink = "Run No." = field("Run No."), "Our Bank" = field("Our Bank");
                DataItemTableView = sorting("Our Bank", "Run No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    UseAmount: Decimal;
                begin
                    Paymenthistorylinecounter := Paymenthistorylinecounter + 1;
                    if "Currency Code" = '' then begin
                        AccountingSetup.TestField("LCY Code");
                        Currencycode := AccountingSetup."LCY Code";
                    end else
                        Currencycode := "Currency Code";
                    if ("Foreign Currency" = '') and
                       ("Foreign Amount" = 0)
                    then begin
                        AccountingSetup.TestField("LCY Code");
                        CurrencycodePayment := Currencycode;
                        Batchamount := Batchamount + Amount;
                        UseAmount := Amount;
                        AmountText := MakeAmountText(Amount, 10, 4, '0', ',');
                    end else begin
                        if "Foreign Currency" = '' then begin
                            AccountingSetup.TestField("LCY Code");
                            CurrencycodePayment := AccountingSetup."LCY Code";
                        end else
                            CurrencycodePayment := "Foreign Currency";
                        Batchamount := Batchamount + "Foreign Amount";
                        AmountText := MakeAmountText("Foreign Amount", 10, 4, '0', ',');
                        UseAmount := "Foreign Amount";
                    end;

                    Genpaymentorderinfo_32A(CurrencycodePayment, AmountText);
                    AccumulateCurrencycodeInfo(CurrencycodePayment, UseAmount);
                    NACPrincipal_50("Payment History"."Account Holder Name", "Payment History"."Account Holder Address", ("Payment History".
                                                                                                                        "Account Holder Post Code") +
                      ' ' + (
                             "Payment History"."Account Holder City"));

                    NACBank_57A("Bank Name", "Bank Address", "Bank City");

                    "NACAccountnumberben._59"("Bank Account No.", "Account Holder Name", "Account Holder Address", "Account Holder City");

                    Announcements_70("Description 1", '', '', '');

                    case "Transfer Cost Foreign" of
                        "Transfer Cost Foreign"::"Balancing Account Holder":
                            Costdivision_71A(Text1000005);
                        "Transfer Cost Foreign"::Principal:
                            Costdivision_71A(Text1000006)
                    end;

                    if ("Foreign Currency" = '') and ("Foreign Amount" = 0) then begin
                        if ("Currency Code" = '') and
                           (AccountingSetup."Local Currency" = 0)
                        then
                            Settlementmethod_01(Text1000007)
                        else
                            if ("Currency Code" = '') and
                               (AccountingSetup."Local Currency" = AccountingSetup."Local Currency"::Euro)
                            then
                                Settlementmethod_01(Text1000008)
                            else
                                if "Currency Code" <> '' then
                                    Settlementmethod_01(Text1000009);
                    end else
                        if (("Foreign Currency" = '') and ("Foreign Amount" <> 0)) and
                           (AccountingSetup."Local Currency" = 0)
                        then
                            Settlementmethod_01(Text1000007)
                        else
                            if (("Foreign Currency" = '') and ("Foreign Amount" <> 0)) and
                               (AccountingSetup."Local Currency" = AccountingSetup."Local Currency"::Euro)
                            then
                                Settlementmethod_01(Text1000008)
                            else
                                if "Foreign Currency" <> '' then
                                    Settlementmethod_01(Text1000009);

                    if "Acc. Hold. Country/Region Code" <> '' then
                        Landcodeben_03("Acc. Hold. Country/Region Code")
                    else
                        Landcodeben_03(Defaultlandcode);

                    if "Nature of the Payment" = "Nature of the Payment"::"Transfer to Own Account" then
                        "Principal=Ben._04"(Text1000010)
                    else
                        "Principal=Ben._04"(Text1000011);

                    if Urgent then
                        Paymentmethod_05(Text1000012)
                    else
                        Paymentmethod_05(Text1000011);

                    Accountinfo_08(TextFilter("Payment History"."Account No.", '0123456789'), CurrencycodePayment);

                    if "Bank Country/Region" <> '' then
                        LandcodeBankBen_10("Bank Country/Region")
                    else
                        LandcodeBankBen_10(Defaultlandcode);

                    LandcodePrincipal_11(Defaultlandcode);

                    case "Nature of the Payment" of
                        "Nature of the Payment"::Goods:
                            Sort := '10';
                        "Nature of the Payment"::"Transito Trade":
                            Sort := '20';
                        "Nature of the Payment"::"Invisible- and Capital Transactions":
                            Sort := '37';
                        "Nature of the Payment"::"Transfer to Own Account":
                            Sort := '40';
                        "Nature of the Payment"::"Other Registrated BFI":
                            Sort := '50';
                    end;
                    DNBInfo_13(Sort, "Registration No. DNB", "Item No.", "Traders No.", "Description Payment");

                    NationalBankcode_14("National Bank Code", "Abbrev. National Bank Code");

                    SWIFTAddress_15("SWIFT Code");

                    WillBeSent();
                end;

                trigger OnPostDataItem()
                begin
                    NextClose := false;
                    if TempfileAccumulatives.Find('-') then
                        repeat
                            CloseWriteField(Currfile, TempfileAccumulatives."Currency Code", TempfileAccumulatives."No. of Net Change",
                              TempfileAccumulatives.Amount, NextClose);
                            NextClose := true;
                        until TempfileAccumulatives.Next() = 0;
                    // WriteHex(Currfile, 3);
                    Closefile(Currfile);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Paymenthistorylinecounter := 0;

                if "File on Disk" = '' then
                    EmptyFileName := true;

                ClientFileName := GenerateExportfilename(NewFilenames);
                ExportProtocolCode := "Export Protocol";
                "File on Disk" := CopyStr(ClientFileName, 1, MaxStrLen("File on Disk"));
                Modify();

                Openfile(Currfile);

                Exported := true;

                HeaderRec(4, 3, Currfile);

                Export := false;
                if Status = Status::New then
                    Validate(Status, Status::Transmitted);
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                LockTable();
                Exported := false;
                TempfileAccumulatives.DeleteAll();
            end;
        }
    }

    requestpage
    {
        Caption = 'BBV-Export';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewFilenames; NewFilenames)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use New File Name';
                        ToolTip = 'Specifies if a new file name is created every time you export a SEPA payment file or if the previous file name is used. ';
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

    trigger OnPostReport()
    begin
        if Exported then
            Message(Text1000000 +
              Text1000001)
        else
            Message(Text1000002 +
              Text1000003 +
              Text1000004, "Payment History".FieldCaption(Export));
    end;

    trigger OnPreReport()
    begin
        AccountingSetup.Get();
    end;

    var
        Text1000000: Label 'BBV data has been exported to disk.\';
        Text1000001: Label 'File names can be found on payment history form';
        Text1000002: Label 'No BBV data has been exported to disk\';
        Text1000003: Label 'Check whether payment histories are present\';
        Text1000004: Label 'and/or %1 is activated';
        Text1000005: Label 'BEN';
        Text1000006: Label 'OUR';
        Text1000007: Label 'G';
        Text1000008: Label 'E';
        Text1000009: Label 'V';
        Text1000010: Label 'J';
        Text1000011: Label 'N';
        Text1000012: Label 'S';
        Text1000013: Label '32A';
        Text1000014: Label '<Year,2><Month,2><Day,2>', Locked = true;
        Text1000015: Label '57A';
        Text1000016: Label '71A';
        Text1000017: Label '<Integer>', Locked = true;
        Text1000018: Label 'Invalid sign used in Fillingcharacter';
        TempfileAccumulatives: Record "Payment History Export Buffer" temporary;
        Currencycode: Code[10];
        CurrencycodePayment: Code[10];
        AmountText: Text[30];
        Countlength: Integer;
        NewFilenames: Boolean;
        Paymenthistorylinecounter: Integer;
        Exported: Boolean;
        Currfile: File;
        AccountingSetup: Record "General Ledger Setup";
        Defaultlandcode: Label 'NL';
        Batchamount: Decimal;
        Sort: Text[30];
        MyChar: Char;
        EmptyFileName: Boolean;
        NextClose: Boolean;
        RBMgt: Codeunit "File Management";
        ClientFileName: Text;
        ExportProtocolCode: Code[20];

    [Scope('OnPrem')]
    procedure Genpaymentorderinfo_32A(Currency: Code[3]; Amount: Text[15])
    begin
        Writefield(Currfile, Text1000013, Format(Today, 0, Text1000014), 6, false, false, true);
        Currfile.TextMode(false);
        Currfile.Seek(Currfile.Pos - 10);
        MyChar := 5;
        Currfile.Write(MyChar);
        Currfile.Seek(Currfile.Pos + 9);
        Currfile.TextMode(true);
        Writefield(Currfile, Text1000013, Currency, 3, false, false, false);
        Writefield(Currfile, Text1000013, Amount, 15, true, true, false);
    end;

    [Scope('OnPrem')]
    procedure NACPrincipal_50(Name: Text[100]; Address: Text[100]; City: Text[35])
    begin
        Writefield(Currfile, '50 ', Name, 35, false, true, true);
        Writefield(Currfile, '50 ', '', 35, false, true, true);
        Writefield(Currfile, '50 ', Address, 35, false, true, true);
        Writefield(Currfile, '50 ', City, 35, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure NACBank_57A(Name: Text[100]; Address: Text[100]; City: Text[35])
    begin
        Writefield(Currfile, Text1000015, Name, 35, false, true, true);
        Writefield(Currfile, Text1000015, '', 35, false, true, true);
        Writefield(Currfile, Text1000015, Address, 35, false, true, true);
        Writefield(Currfile, Text1000015, City, 35, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure "NACAccountnumberben._59"(Accntnr: Text[34]; Nameben: Text[100]; Adressben: Text[100]; Cityben: Text[35])
    begin
        Writefield(Currfile, '59 ', Accntnr, 34, false, true, true);
        Writefield(Currfile, '59 ', Nameben, 35, false, true, true);
        Writefield(Currfile, '59 ', '', 35, false, true, true);
        Writefield(Currfile, '59 ', Adressben, 35, false, true, true);
        Writefield(Currfile, '59 ', Cityben, 35, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Announcements_70(Descr1: Text[35]; Description2: Text[35]; Descr3: Text[35]; Descr4: Text[35])
    begin
        Writefield(Currfile, '70 ', Descr1, 35, false, true, true);
        Writefield(Currfile, '70 ', Description2, 35, false, true, true);
        Writefield(Currfile, '70 ', Descr3, 35, false, true, true);
        Writefield(Currfile, '70 ', Descr4, 35, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Costdivision_71A(Costdivision: Text[3])
    begin
        Writefield(Currfile, Text1000016, StrSubstNo('%1', Costdivision), 3, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Settlementmethod_01(Currencyownacc: Code[1])
    begin
        Writefield(Currfile, '01 ', StrSubstNo('%1', Currencyownacc), 1, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Landcodeben_03(Landcode: Text[2])
    begin
        Writefield(Currfile, '03 ', Landcode, 2, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure "Principal=Ben._04"(Orderben: Text[1])
    begin
        Writefield(Currfile, '04 ', Orderben, 1, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Paymentmethod_05(Paymentmethod: Text[1])
    begin
        Writefield(Currfile, '05 ', StrSubstNo('%1', Paymentmethod), 1, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Accountinfo_08(Accnr: Text[9]; Currency: Code[3])
    begin
        FillOut(Accnr, 9, '>', '0');
        Writefield(Currfile, '08 ', Accnr, 9, false, false, true);
        Writefield(Currfile, '08 ', StrSubstNo('%1', Currency), 3, false, true, false);
    end;

    [Scope('OnPrem')]
    procedure Otherinstructions_09()
    begin
    end;

    [Scope('OnPrem')]
    procedure LandcodeBankBen_10(Landcode: Code[2])
    begin
        Writefield(Currfile, '10 ', StrSubstNo('%1', Landcode), 2, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure LandcodePrincipal_11(Landcode: Code[2])
    begin
        Writefield(Currfile, '11 ', StrSubstNo('%1', Landcode), 2, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure DNBInfo_13(Sortpay: Text[2]; RegistrationNr: Text[8]; ItemNr: Text[2]; TradersNo: Text[4]; Description: Text[60])
    begin
        FillOut(RegistrationNr, 8, '<', '');
        FillOut(ItemNr, 2, '<', '');
        FillOut(TradersNo, 4, '<', '');
        Writefield(Currfile, '13 ', Sortpay + RegistrationNr + ItemNr + TradersNo + Description, 77, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure NationalBankcode_14(Bankcode: Code[20]; AbbreviationBankCode: Text[3])
    begin
        FillOut(AbbreviationBankCode, 3, '<', '');
        Writefield(Currfile, '14 ', AbbreviationBankCode + StrSubstNo('%1', Bankcode), 20, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure SWIFTAddress_15(SWIFTaddress: Code[11])
    begin
        Writefield(Currfile, '15 ', StrSubstNo('%1', SWIFTaddress), 11, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure Openfile(var File: File)
    begin
        File.TextMode(true);
        File.WriteMode(true);
        File.Create(RBMgt.ServerTempFileName('.txt'));
    end;

    [Scope('OnPrem')]
    procedure Closefile(var CFile: File)
    var
        ReportChecksum: Codeunit "Report Checksum";
        ServerFileName: Text[1024];
    begin
        // Closes en opens to delete last 2 <ODOA> characters
        ServerFileName := CFile.Name;
        CFile.Close();
        CFile.Open(ServerFileName);
        CFile.Seek(CFile.Len - 2);
        CFile.Trunc();
        CFile.Close();
        ReportChecksum.GenerateChecksum("Payment History", ServerFileName, ExportProtocolCode);
        RBMgt.DownloadHandler(ServerFileName, '', '', '', RBMgt.GetFileName(ClientFileName));

        RBMgt.DeleteServerFile(ServerFileName);
    end;

    [Scope('OnPrem')]
    procedure GetFileName(Path: Text[1024]): Text[1024]
    var
        Pos: Integer;
    begin
        while StrPos(Path, '\') <> 0 do begin
            Pos := StrPos(Path, '\');
            Path := CopyStr(Path, Pos + 1);
        end;
        exit(Path);
    end;

    [Scope('OnPrem')]
    procedure Writefield(var CFile: File; Columncode: Text[3]; Text: Text[35]; Numberpos: Integer; Numeral: Boolean; Closingsign: Boolean; Columncoding: Boolean)
    var
        TextCounter: Integer;
        Filllength: Integer;
        Fillcharacter: Text[30];
    begin
        if StrLen(Text) > Numberpos then begin
            Text := CopyStr(Text, Numberpos);
            Filllength := 0
        end else
            Filllength := Numberpos - StrLen(Text);
        TextCounter := 0;
        if Numeral then
            Fillcharacter := '0'
        else
            Fillcharacter := ' ';
        if (Countlength + Numberpos + 4) > 128 then begin
            WriteHex(CFile, 3);
            Countlength := Countlength + 1;
            repeat
                Write(CFile, ' ');
                Countlength := Countlength + 1
            until Countlength = 128;
            CFile.Write('');
            WriteHex(CFile, 6);
            Countlength := 1;
        end;
        if Columncoding then begin
            Write(CFile, Columncode);
            Countlength := Countlength + 3;
        end;
        Write(CFile, Text);
        if Filllength > 0 then
            repeat
                Write(CFile, Fillcharacter);
                TextCounter := TextCounter + 1;
            until TextCounter = Filllength;
        if Closingsign then begin
            WriteHex(CFile, 3);
            Countlength := Countlength + 1;
        end;
        Countlength := Countlength + Numberpos;
    end;

    [Scope('OnPrem')]
    procedure CloseWriteField(var CFile: File; Currency: Code[10]; Numberoforders: Integer; TotAmount: Decimal; Next: Boolean)
    var
        Numberordertext: Text[30];
        AmountText: Text[30];
    begin
        if not Next then begin
            WriteHex(CFile, 3);
            Countlength := Countlength + 1;
            repeat
                Write(CFile, ' ');
                Countlength := Countlength + 1;
            until Countlength = 128;
            Countlength := 0;
            CFile.Write('');
        end;
        WriteHex(CFile, 7);
        Write(CFile, '999');
        Write(CFile, Format(Currency, 3));
        Numberordertext := StrSubstNo('%1', Numberoforders);
        if StrLen(Numberordertext) = 1 then
            Write(CFile, '00');
        if StrLen(Numberordertext) = 2 then
            Write(CFile, '0');
        Write(CFile, Format(Numberoforders, 0));
        AmountText := MakeAmountText(TotAmount, 10, 4, '0', ',');
        Write(CFile, AmountText);
        WriteHex(CFile, 3);
        WriteHex(CFile, 3);
        Countlength := Countlength + 26;
        repeat
            Write(CFile, ' ');
            Countlength := Countlength + 1;
        until Countlength = 126;
        Countlength := 0;
        CFile.Write(' ');
    end;

    [Scope('OnPrem')]
    procedure Write(var File: File; Text: Text[35])
    begin
        File.Write(Text);
        File.Seek(File.Pos - 2);
    end;

    [Scope('OnPrem')]
    procedure HeaderRec(Hexcode: Char; Closechar: Char; var Currfile: File)
    var
        Numerator: Integer;
    begin
        Numerator := 0;
        WriteHex(Currfile, 4);
        Write(Currfile, '000');
        "Payment History"."Account No." := TextFilter("Payment History"."Account No.", '0123456789');
        FillOut("Payment History"."Account No.", 9, '<', '0');
        Write(Currfile, "Payment History"."Account No.");
        WriteHex(Currfile, 3);
        WriteHex(Currfile, 3);
        repeat
            Write(Currfile, ' ');
            Numerator := Numerator + 1
        until Numerator = 112;
        Currfile.Write(' ');
        WriteHex(Currfile, 5);
        Countlength := 1;
    end;

    [Scope('OnPrem')]
    procedure MakeAmountText(Amount: Decimal; LengthBeforecomma: Integer; DecimalPlaces: Integer; FillingSign: Text[1]; DecimalSeperator: Text[1]) AmountText: Text[250]
    var
        hlpint: Integer;
        hlptxt: Text[250];
    begin
        AmountText := Format(Round(Amount, 1, '<'), 0, Text1000017);
        AmountText := PadStr('', LengthBeforecomma - StrLen(AmountText), FillingSign) +
          AmountText +
          DecimalSeperator;
        hlpint := (Amount * Power(10, DecimalPlaces)) mod Power(10, DecimalPlaces);
        hlptxt := Format(hlpint, 0, Text1000017);
        if StrLen(hlptxt) < DecimalPlaces then
            hlptxt := PadStr('', DecimalPlaces - StrLen(hlptxt), '0') + hlptxt;
        AmountText += hlptxt;
    end;

    [Scope('OnPrem')]
    procedure WriteHex(var CFile: File; Value: Char)
    begin
        CFile.Write(Value);
        CFile.Seek(CFile.Pos - 2);
    end;

    [Scope('OnPrem')]
    procedure FillOut(var Text: Text[250]; Numberpos: Integer; Align: Code[1]; "Filling character": Text[1])
    begin
        if Numberpos > StrLen(Text) then begin
            if "Filling character" = '' then
                "Filling character" := ' ';
            case Align of
                '', '<':
                    Text := PadStr(Text, Numberpos, "Filling character");
                '>':
                    Text := PadStr('', Numberpos - StrLen(Text), "Filling character") + Text;
                else
                    Error(Text1000018);
            end;
        end else
            if Numberpos < StrLen(Text) then
                case Align of
                    '', '<':
                        Text := CopyStr(Text, 1, Numberpos);
                    '>':
                        Text := DelStr(Text, 1, StrLen(Text) - Numberpos);
                    else
                        Error(Text1000018);
                end;
    end;

    [Scope('OnPrem')]
    procedure TextFilter(Text: Text[250]; "Filter": Text[30]) TextFilter: Text[250]
    begin
        TextFilter := DelChr(Text, '=', DelChr(Text, '=', Filter));
    end;

    local procedure AccumulateCurrencycodeInfo(Currencycode: Code[10]; Amount: Decimal)
    begin
        if TempfileAccumulatives.Get(Currencycode) then begin
            TempfileAccumulatives.Amount := TempfileAccumulatives.Amount + Amount;
            TempfileAccumulatives."No. of Net Change" := TempfileAccumulatives."No. of Net Change" + 1;
            TempfileAccumulatives.Modify();
        end else begin
            TempfileAccumulatives."Currency Code" := Currencycode;
            TempfileAccumulatives.Amount := Amount;
            TempfileAccumulatives."No. of Net Change" := 1;
            TempfileAccumulatives.Insert();
        end;
    end;
}

