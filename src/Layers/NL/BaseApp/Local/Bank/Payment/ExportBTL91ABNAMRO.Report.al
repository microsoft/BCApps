// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using System.IO;

report 11000007 "Export BTL91-ABN AMRO"
{
    Caption = 'Export BTL91-ABN AMRO';
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
                DataItemTableView = sorting("Our Bank", "Run No.", "Line No.") where(Status = filter(New | Transmitted | "Request for Cancellation"));

                trigger OnAfterGetRecord()
                var
                    Sortofexportation: Integer;
                begin
                    if Paymenthistorylinecounter < 9999 then
                        Paymenthistorylinecounter := Paymenthistorylinecounter + 1
                    else
                        Error(Text1000007);

                    if Urgent then
                        Sortofexportation := 2
                    else
                        Sortofexportation := 0;
                    if "Currency Code" = '' then begin
                        AccountingSetup.TestField("LCY Code");
                        Currencycode := AccountingSetup."LCY Code"
                    end else
                        Currencycode := "Currency Code";

                    if ("Foreign Currency" = '') and
                       ("Foreign Amount" = 0)
                    then
                        UseAmount := Amount
                    else
                        UseAmount := "Foreign Amount";

                    if ("Foreign Currency" = '') and
                       ("Foreign Amount" = 0)
                    then begin
                        AccountingSetup.TestField("LCY Code");
                        CurrencycodePayment := Currencycode;
                    end else
                        if "Foreign Currency" = '' then begin
                            AccountingSetup.TestField("LCY Code");
                            CurrencycodePayment := AccountingSetup."LCY Code";
                        end else
                            CurrencycodePayment := "Foreign Currency";
                    TotAmount := TotAmount + UseAmount;

                    Concerns := Format("Nature of the Payment", 0, Text1000008);

                    case "Transfer Cost Domestic" of
                        "Transfer Cost Domestic"::Principal:
                            case AccountingSetup."Local Currency" of
                                AccountingSetup."Local Currency"::Euro:
                                    if Currencycode = AccountingSetup."LCY Code" then
                                        CostDomestic := 1
                                    else
                                        CostDomestic := 2;
                                AccountingSetup."Local Currency"::Other:
                                    if Currencycode = AccountingSetup."Currency Euro" then
                                        CostDomestic := 1
                                    else
                                        CostDomestic := 2;
                            end;
                        "Transfer Cost Domestic"::"Balancing Account Holder":
                            CostDomestic := 3;
                    end;
                    case "Transfer Cost Foreign" of
                        "Transfer Cost Foreign"::Principal:
                            case AccountingSetup."Local Currency" of
                                AccountingSetup."Local Currency"::Euro:
                                    if Currencycode = AccountingSetup."LCY Code" then
                                        CostForeign := 1
                                    else
                                        CostForeign := 2;
                                AccountingSetup."Local Currency"::Other:
                                    if Currencycode = AccountingSetup."Currency Euro" then
                                        CostForeign := 1
                                    else
                                        CostForeign := 2;
                            end;
                        "Transfer Cost Foreign"::"Balancing Account Holder":
                            CostForeign := 3;
                    end;
                    Paymentrecord1Info(TextFilter("Payment History"."Account No.", '0123456789'),
                      UseAmount, Paymenthistorylinecounter, Currencycode, Date,
                      CostDomestic,
                      CostForeign,
                      Concerns, "Description Payment", "Registration No. DNB",
                      "Item No.", "Traders No.", Sortofexportation, CurrencycodePayment);
                    AccumulateCurrencycodeInfo(CurrencycodePayment, UseAmount);
                    if "Acc. Hold. Country/Region Code" <> '' then
                        Country.Get("Acc. Hold. Country/Region Code")
                    else
                        Clear(Country);
                    if (IBAN <> '') and
                       ("Payment History"."Acc. Hold. Country/Region Code" <> "Acc. Hold. Country/Region Code")
                    then
                        Paymentrecord2Info(IBAN,
                          "Account Holder Name", "Account Holder Address", "Account Holder City", "Acc. Hold. Country/Region Code",
                          Paymenthistorylinecounter, Country.Name)
                    else
                        Paymentrecord2Info("National Bank Code" + "Bank Account No.",
                          "Account Holder Name", "Account Holder Address", "Account Holder City", "Acc. Hold. Country/Region Code",
                          Paymenthistorylinecounter, Country.Name);

                    if "Bank Country/Region" <> '' then
                        Country.Get("Bank Country/Region")
                    else
                        Clear(Country);
                    Paymentrecord3Info(Paymenthistorylinecounter, "Bank Name", "Bank Address", "Bank City", "Bank Country/Region",
                      Country.Name, "SWIFT Code");

                    Paymentrecord4Info("Description 1", "Description 2", "Description 3", "Description 4", Paymenthistorylinecounter);

                    WillBeSent();
                end;

                trigger OnPostDataItem()
                begin
                    CurrencyCounter := 0;
                    if TempfileAccumulatives.Find('-') then
                        repeat
                            TotalrecordInfo(
                              TempfileAccumulatives."Currency Code", TempfileAccumulatives.Amount, TempfileAccumulatives."No. of Net Change");
                            CurrencyCounter := CurrencyCounter + 1;
                        until TempfileAccumulatives.Next() = 0;
                    ClosingrecordInfo((Paymenthistorylinecounter * 4) + 2 + CurrencyCounter, Paymenthistorylinecounter);
                    Closefile(Currfile);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Paymenthistorylinecounter := 0;
                TotAmount := 0;

                ClientFileName := GenerateExportfilename(NewFilenames);
                ExportProtocolCode := "Export Protocol";
                Openfile(Currfile, true);
                Exported := true;

                if "Acc. Hold. Country/Region Code" <> '' then
                    Country.Get("Acc. Hold. Country/Region Code")
                else
                    Clear(Country);
                PostCodeAndCity := "Account Holder Post Code" + ' ' + "Account Holder City";
                HeaderInfo(
                  "Account Holder Name", "Account Holder Address",
                  PostCodeAndCity, Country.Name, "Exchange bank");

                Export := false;
                if Status = Status::New then
                    Validate(Status, Status::Transmitted);
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                LockTable();
                TempfileAccumulatives.DeleteAll();
            end;
        }
    }

    requestpage
    {
        Caption = 'BTL91-Export';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Test Order"; "Test Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Mode';
                        ToolTip = 'Specifies if the next run shows a test report instead of executing the export.';
                    }
                    field(NewFilenames; NewFilenames)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Always Create New File';
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
            Message(Text1000002 +
              Text1000003)
        else
            Message(Text1000004 +
              Text1000005 +
              Text1000006, "Payment History".FieldCaption(Export));
    end;

    trigger OnPreReport()
    begin
        if not "Test Order" then
            "Exchange bank" := 'ABNA'
        else
            "Exchange bank" := 'ABNT';
        AccountingSetup.Get();
    end;

    var
        Text1000002: Label 'BTL91 data has been exported.\';
        Text1000003: Label 'File names can be found on payment history form';
        Text1000004: Label 'No BTL91 data has been exported.\';
        Text1000005: Label 'Check whether payment histories are present\';
        Text1000006: Label 'and/or %1 is activated';
        Text1000007: Label 'The maximum transaction number of 9999 is reached';
        Text1000008: Label '<standard format,2>', Locked = true;
        Text1000009: Label 'X';
        Text1000010: Label '<Year,2><Month,2><Day,2>', Locked = true;
        Text1000013: Label '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./- ';
        Text1000014: Label 'Invalid sign used in Fillingcharacter';
        Text1000015: Label '<Integer>', Locked = true;
        TempfileAccumulatives: Record "Payment History Export Buffer" temporary;
        TotAmount: Decimal;
        UseAmount: Decimal;
        Exported: Boolean;
        AccountingSetup: Record "General Ledger Setup";
        Currfile: File;
        ClientFileName: Text[250];
        Currencycode: Code[10];
        CurrencycodePayment: Code[10];
        Country: Record "Country/Region";
        Paymenthistorylinecounter: Integer;
        NewFilenames: Boolean;
        "Test Order": Boolean;
        "Exchange bank": Text[30];
        Concerns: Text[30];
        DefaultLandcode: Label 'NL';
        DefaultLandDescription: Label 'Nederland';
        CostDomestic: Integer;
        CostForeign: Integer;
        CurrencyCounter: Integer;
        RBMgt: Codeunit "File Management";
        PostCodeAndCity: Text[70];
        ExportProtocolCode: Code[20];

    [Scope('OnPrem')]
    procedure HeaderInfo(AcctHolder: Text[100]; Address: Text[100]; City: Text[70]; "Country Code": Code[50]; "Exchange bank": Text[30])
    begin
        Write(Currfile, '11', 2, '>', '0', false); // 11-1
        Write(Currfile, "Exchange bank", 4, '', '', false); // 11-2
        Write(Currfile, Text1000009, 1, '', '', false); // 11-3
        Write(Currfile, '01', 2, '>', '0', false); // 11-4
        Write(Currfile, '20' + Format(Today, 0, Text1000010), 8, '', '', false); // 11-5
        Write(Currfile, '001', 3, '>', '0', false); // 11-6
        Write(Currfile, AcctHolder, 35, '', '', false); // 11-7
        Write(Currfile, Address, 35, '', '', false); // 11-8
        Write(Currfile, City, 35, '', '', false); // 11-9
        if "Country Code" = '' then
            "Country Code" := DefaultLandDescription;
        Write(Currfile, "Country Code", 35, '', '', false); // 11-10
        Write(Currfile, '', 4, '>', '0', false); // 11-11
        Write(Currfile, '', 8, '>', '0', false); // 11-12
        Write(Currfile, '', 20, '', '', true); // 11-13
    end;

    [Scope('OnPrem')]
    procedure Paymentrecord1Info(AccnoPrincipal: Text[30]; Amount: Decimal; Orderno: Integer; Ordercurrencycode: Code[10]; ExpecdateOrder: Date; BNL: Integer; KORR: Integer; Concerns: Text[30]; DescrSort: Text[30]; RegNr: Text[8]; ItemNo: Text[2]; HandNr: Text[4]; Execution: Option; PaymentCurrencyCode: Code[10])
    var
        Amountstr: Text[30];
    begin
        Write(Currfile, '21', 2, '>', '0', false); // 21-1
        Write(Currfile, StrSubstNo('%1', Orderno), 4, '>', '0', false); // 21-2
        Write(Currfile, Ordercurrencycode, 3, '', '', false); // 21-3
        Write(Currfile, AccnoPrincipal, 10, '>', '0', false); // 21-4
        Write(Currfile, PaymentCurrencyCode, 3, '', '', false); // 21-5
        Amountstr := MakeAmountText(Amount, 12, 3, '0', ''); // 21-6
        Write(Currfile, Amountstr, 15, '>', '0', false);
        Write(Currfile, '20' + Format(ExpecdateOrder, 0, Text1000010), 8, '', '', false); // 21-7
        Write(Currfile, StrSubstNo('%1', BNL), 1, '>', '0', false); // 21-8
        Write(Currfile, StrSubstNo('%1', KORR), 1, '>', '0', false); // 21-9
        Write(Currfile, '', 1, '>', '0', false); // 21-10
        Write(Currfile, StrSubstNo('%1', Execution), 1, '>', '0', false); // 21-11
        Write(Currfile, '', 1, '', '', false); // 21-12
        Write(Currfile, '', 1, '', '', false); // 21-13
        Write(Currfile, '', 2, '', '', false); // 21-14
        Write(Currfile, '', 2, '', '', false); // 21-15
        Write(Currfile, '', 2, '', '', false); // 21-16
        Write(Currfile, '', 2, '', '', false); // 21-17
        Write(Currfile, Concerns, 1, '', '', false); // 21-18
        Write(Currfile, Format("Payment History Line"."Nature of the Payment", 0, '<standard format,0>'), 40, '', '', false); // 21-19
        Write(Currfile, '', 40, '', '', false); // 21-20
        Write(Currfile, RegNr, 8, '', '', false); // 21-21
        Write(Currfile, '', 2, '', '', false); // 21-22
        Write(Currfile, ItemNo, 2, '', '', false); // 21-23
        Write(Currfile, HandNr, 4, '', '', false); // 21-24
        Write(Currfile, '', 36, '', '', true); // 21-25
    end;

    [Scope('OnPrem')]
    procedure Paymentrecord2Info(AccNrBeneficiary: Text[50]; NameBeneficiary: Text[100]; AddressBeneficiary: Text[100]; CityBeneficiary: Text[30]; Landcodebeneficiary: Code[10]; Orderno: Integer; "Country Name": Text[50])
    begin
        Write(Currfile, '22', 2, '>', '0', false); // 22-1
        Write(Currfile, StrSubstNo('%1', Orderno), 4, '>', '0', false); // 22-2
        Write(Currfile, AccNrBeneficiary, 34, '', '', false); // 22-3
        Write(Currfile, NameBeneficiary, 35, '', '', false); // 22-4
        Write(Currfile, AddressBeneficiary, 35, '', '', false); // 22-5
        Write(Currfile, CityBeneficiary, 35, '', '', false); // 22-6
        if Landcodebeneficiary = '' then
            Landcodebeneficiary := DefaultLandcode;
        Write(Currfile, Landcodebeneficiary, 2, '', '', false); // 22-7
        if "Country Name" = '' then
            "Country Name" := DefaultLandDescription;
        Write(Currfile, "Country Name", 35, '', '', false); // 22-8
        Write(Currfile, '', 10, '', '', true); // 22-9
    end;

    [Scope('OnPrem')]
    procedure Paymentrecord3Info(Orderno: Integer; Banknameben: Text[100]; Bankaddressben: Text[100]; Bankcityben: Text[30]; Banklandcode: Code[10]; Banklandnameben: Text[50]; SWIFTaddress: Text[20])
    begin
        Write(Currfile, '23', 2, '>', '0', false); // 23-1
        Write(Currfile, StrSubstNo('%1', Orderno), 4, '>', '0', false); // 23-2
        Write(Currfile, SWIFTaddress, 11, '', '', false); // 23-3
        Write(Currfile, Banknameben, 35, '', '', false); // 23-4
        Write(Currfile, Bankaddressben, 35, '', '', false); // 23-5
        Write(Currfile, Bankcityben, 35, '', '', false); // 23-6
        if Banklandcode = '' then
            Banklandcode := DefaultLandcode;
        Write(Currfile, Banklandcode, 2, '', '', false); // 23-7
        if Banklandnameben = '' then
            Banklandnameben := DefaultLandDescription;
        Write(Currfile, Banklandnameben, 35, '', '', false); // 23-8
        Write(Currfile, '', 33, '', '', true); // 23-9
    end;

    [Scope('OnPrem')]
    procedure Paymentrecord4Info(Descr1: Text[32]; Description2: Text[32]; Descr3: Text[32]; Descr4: Text[32]; Orderno: Integer)
    begin
        Write(Currfile, '24', 2, '>', '0', false); // 24-1
        Write(Currfile, StrSubstNo('%1', Orderno), 4, '>', '0', false); // 24-2
        Write(Currfile, Descr1, 35, '', '', false); // 24-3
        Write(Currfile, Description2, 35, '', '', false); // 24-4
        Write(Currfile, Descr3, 35, '', '', false); // 24-5
        Write(Currfile, Descr4, 35, '', '', false); // 24-6
        Write(Currfile, '', 46, '', '', true); // 24-7
    end;

    [Scope('OnPrem')]
    procedure TotalrecordInfo(Currencycode: Code[10]; TotAmount: Decimal; NumberOfOrders: Integer)
    var
        Amountstr: Text[30];
    begin
        Write(Currfile, '31', 2, '>', '0', false); // 31-1
        Write(Currfile, Currencycode, 3, '', '', false); // 31-2
        Amountstr := MakeAmountText(TotAmount, 12, 3, '0', '');
        Write(Currfile, Amountstr, 15, '>', '0', false); // 31-3
        Write(Currfile, StrSubstNo('%1', NumberOfOrders), 4, '>', '0', false); // 31-4
        Write(Currfile, '', 168, '', '', true); // 31-5
    end;

    [Scope('OnPrem')]
    procedure ClosingrecordInfo(TotnumberRec: Integer; TotnumberOrd: Integer)
    begin
        Write(Currfile, '41', 2, '>', '0', false); // 41-1
        Write(Currfile, StrSubstNo('%1', TotnumberRec), 6, '>', '0', false); // 41-2
        Write(Currfile, StrSubstNo('%1', TotnumberOrd), 4, '>', '0', false); // 41-3
        Write(Currfile, '', 24, '>', '0', false); // 41-4
        Write(Currfile, '', 156, '', '', true); // 41-5
    end;

    [Scope('OnPrem')]
    procedure Write(var CFile: File; Text: Text[250]; Numberpos: Integer; Align: Code[1]; "Filling character": Text[1]; LineTransition: Boolean)
    begin
        Text := ConvertStr(Text,
            'ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜøØáíóúñÁÂÀ¢¥ãÃðÐÊËÈiÍÎÏËÈÌÓßÔÒõÕµÚÛÙýÝ',
            'CueaaaaceeeiiiAAEaAooouuyOUoOaiounAAAcyaAoDEEEiIIIEEIOBOOoOuUUUyY');
        Text := UpperCase(Text);
        Text := DelChr(Text, '=', DelChr(Text, '=', Text1000013));

        FillOut(Text, Numberpos, Align, "Filling character");
        CFile.Write(Text);
        if not LineTransition then
            CFile.Seek(CFile.Pos - 2);
    end;

    [Scope('OnPrem')]
    procedure Openfile(var File: File; New: Boolean)
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
        ServerFileName := CFile.Name;
        CFile.Trunc();
        CFile.Close();
        ReportChecksum.GenerateChecksum("Payment History", ServerFileName, ExportProtocolCode);
        RBMgt.DownloadHandler(ServerFileName, '', '', '', RBMgt.GetFileName(ClientFileName));

        RBMgt.DeleteServerFile(ServerFileName);
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
                    Error(Text1000014);
            end;
        end else
            if Numberpos < StrLen(Text) then
                case Align of
                    '', '<':
                        Text := CopyStr(Text, 1, Numberpos);
                    '>':
                        Text := DelStr(Text, 1, StrLen(Text) - Numberpos);
                    else
                        Error(Text1000014);
                end;
    end;

    [Scope('OnPrem')]
    procedure MakeAmountText(Amount: Decimal; LengthBeforecomma: Integer; DecimalPlaces: Integer; FillingSign: Text[1]; DecimalSeperator: Text[1]) AmountText: Text[250]
    var
        hlpint: Integer;
        hlptxt: Text[30];
    begin
        AmountText := Format(Round(Amount, 1, '<'), 0, Text1000015);
        AmountText := PadStr('', LengthBeforecomma - StrLen(AmountText), FillingSign) +
          AmountText +
          DecimalSeperator;
        hlpint := (Amount * Power(10, DecimalPlaces)) mod Power(10, DecimalPlaces);
        hlptxt := Format(hlpint, 0, Text1000015);
        if StrLen(hlptxt) < DecimalPlaces then
            hlptxt := PadStr('', DecimalPlaces - StrLen(hlptxt), '0') + hlptxt;
        AmountText := AmountText + hlptxt;
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

