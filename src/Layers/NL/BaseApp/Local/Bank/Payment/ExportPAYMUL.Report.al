// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using System.IO;

report 11000009 "Export PAYMUL"
{
    // PAYMUL export.
    // Beta version.

    Caption = 'Export PAYMUL';
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
                begin
                    if Paymenthistorylinecounter < 9999 then
                        Paymenthistorylinecounter := Paymenthistorylinecounter + 1
                    else
                        Error(Text1000007);

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

                    Concerns := Format("Nature of the Payment", 0, '<standard format,0>');

                    case "Transfer Cost Domestic" of
                        "Transfer Cost Domestic"::Principal:
                            if Currencycode = AccountingSetup."Currency Euro" then
                                CostDomestic := 1
                            else
                                CostDomestic := 2;
                        "Transfer Cost Domestic"::"Balancing Account Holder":
                            CostDomestic := 3;
                    end;
                    case "Transfer Cost Foreign" of
                        "Transfer Cost Foreign"::Principal:
                            if Currencycode = AccountingSetup."Currency Euro" then
                                CostForeign := 1
                            else
                                CostForeign := 2;
                        "Transfer Cost Foreign"::"Balancing Account Holder":
                            CostForeign := 3;
                    end;

                    SequenceDetails();
                    MonetaryAmount(Amount, false);
                    Reference();
                    if (IBAN <> '') and
                       ("Acc. Hold. Country/Region Code" <> "Bank Country/Region")
                    then
                        FinInstInfoBeneficiary(IBAN, "Bank Name", "Bank City", "Bank Country/Region")
                    else
                        FinInstInfoBeneficiary(CharacterFilter("Bank Account No.", '0123456789'), "Bank Name", "Bank City", "Bank Country/Region");

                    NameAddressBeneficiary();
                    GeneralIndicator();
                    FreeTextGeneral();
                    PRCIdentifier();
                    FreeText();
                    if "Acc. Hold. Country/Region Code" <> '' then
                        Country.Get("Acc. Hold. Country/Region Code")
                    else
                        Clear(Country);

                    if "Bank Country/Region" <> '' then
                        Country.Get("Bank Country/Region")
                    else
                        Clear(Country);
                    WillBeSent();
                end;

                trigger OnPostDataItem()
                begin
                    MessageTrailer();
                    InterchangeTrailer();
                    CurrentSequenceNo := IncStr(CurrentSequenceNo);
                    Closefile();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Paymenthistorylinecounter := 0;
                TotAmount := 0;
                TotalNumberOfMessages := TotalNumberOfMessages + 1;

                ClientFileName := GenerateExportfilename(NewFilenames);
                ExportProtocolCode := "Export Protocol";
                Openfile();
                Exported := true;

                if "Acc. Hold. Country/Region Code" <> '' then
                    Country.Get("Acc. Hold. Country/Region Code")
                else
                    Clear(Country);
                CurrentSequenceNo := '1';
                InterchangeHeader();
                MessageHeader();
                BeginningOfMessage();
                DateTimePeriod(true, WorkDate());
                LineItem();
                DateTimePeriod(false, WorkDate());
                FinancialChargesAllocation();
                CalcFields("Remaining Amount");
                MonetaryAmount("Remaining Amount", true);
                FinancialInstitutionInfo("Account No.", "Account Holder Name", "Account Holder City", "Acc. Hold. Country/Region Code");

                Export := false;
                if Status = Status::New then
                    Validate(Status, Status::Transmitted);
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                LockTable();
                LINCounter := 0;
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
                        Caption = 'Testmode';
                        ToolTip = 'Specifies if the next run shows a test report instead of executing the export.';
                    }
                    field(NewFilenames; NewFilenames)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Always create new file';
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
        AccountingSetup.Get();
        TotalNumberOfMessages := 0;
        MessageIdentifier := '1';
        ReservedChars := '''+:?';
    end;

    var
        Text1000002: Label 'PAYMUL data has been exported to disk.\';
        Text1000003: Label 'File names can be found on payment history form';
        Text1000004: Label 'No PAYMUL data has been exported to disk.\';
        Text1000005: Label 'Check whether payment histories are present\';
        Text1000006: Label 'and/or %1 is activated';
        Text1000007: Label 'The maximum transaction number of 9999 is reached';
        AccountingSetup: Record "General Ledger Setup";
        Country: Record "Country/Region";
        Curfile: File;
        TotAmount: Decimal;
        UseAmount: Decimal;
        Currencycode: Code[10];
        CurrencycodePayment: Code[10];
        Exported: Boolean;
        NewFilenames: Boolean;
        "Test Order": Boolean;
        Concerns: Text[30];
        strData: Text[250];
        CurrentSequenceNo: Text[10];
        ReservedChars: Text[30];
        MessageIdentifier: Code[10];
        Paymenthistorylinecounter: Integer;
        CostDomestic: Integer;
        CostForeign: Integer;
        SegmentCounter: Integer;
        TotalNumberOfMessages: Integer;
        LINCounter: Integer;
        RBMgt: Codeunit "File Management";
        ClientFileName: Text;
        ExportProtocolCode: Code[20];

    [Scope('OnPrem')]
    procedure InterchangeHeader()
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := StrSubstNo('UNB+UNOA:2+%1:ZZ+%2:55+', GetSenderID(), 'INGBNL2A') +
          GetYYMMDD(WorkDate(), false) + ':' + GetTimeString() + '+' + GetSequenceNo();
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure MessageHeader()
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := StrSubstNo('UNH+%1+PAYMUL:D:96A:UN:171001', MessageIdentifier);
        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure BeginningOfMessage()
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := StrSubstNo('BGM+452+%1+9', "Payment History"."Run No.");
        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure DateTimePeriod(IsCreationDate: Boolean; DateToUse: Date)
    begin
        SegmentCounter := SegmentCounter + 1;
        if IsCreationDate then
            strData := 'DTM+137:' + GetYYMMDD(DateToUse, true) + GetTimeString() + ':203'
        else
            strData := 'DTM+203:' + GetYYMMDD(DateToUse, true) + ':102';
        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure NameAddress()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('NAD+HQ+++%1+%2+%3+++%4',
            CnvStr("Payment History"."Account Holder Name"),
            CnvStr("Payment History"."Account Holder Address"),
            CnvStr("Payment History"."Account Holder City"),
            CnvStr("Payment History"."Acc. Hold. Country/Region Code"));
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure LineItem()
    begin
        SegmentCounter := SegmentCounter + 1;
        LINCounter := LINCounter + 1;

        strData := 'LIN+1';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure Reference()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('RFF+AFO:%1', "Payment History Line"."Description 1");
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure BusinessFunction()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'BUS+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure FinancialChargesAllocation()
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := 'FCA+14';
        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure MonetaryAmount(Amount: Decimal; IsTotal: Boolean)
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := 'MOA+9:' + MakeAmountText(Amount);
        strData := strData + ':' + GetCurrencyCode();

        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure FinancialInstitutionInfo(AccountNo: Text[250]; Name: Text[250]; Place: Text[250]; Country: Text[250])
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := 'FII+OR+';
        strData := strData + StrSubstNo('%1:%2:%3++%4',
            CharacterFilter(AccountNo, '0123456789'),
            CnvStr(Name),
            CnvStr(Place),
            CnvStr(Country));
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure FinInstInfoBeneficiary(AccountNo: Text[250]; Name: Text[250]; Place: Text[250]; Country: Text[250])
    begin
        SegmentCounter := SegmentCounter + 1;
        strData := 'FII+BF+';
        strData := strData + StrSubstNo('%1:%2:%3:%4+%5:%6:%7+%8',
            AccountNo,
            CnvStr(Name),
            CnvStr(Place),
            CnvStr('EUR'),
            CnvStr("Payment History Line"."SWIFT Code"),
            25,// Code List Qualifier
            17,// SWIFT indicator
            CnvStr(Country));
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure NameAddressBeneficiary()
    begin
        if "Payment History Line"."Account Holder Name" <> '' then begin
            SegmentCounter := SegmentCounter + 1;
            strData := StrSubstNo('NAD+BE+++%1+%2+%3+++%4',
                CnvStr("Payment History Line"."Account Holder Name"),
                CnvStr("Payment History Line"."Account Holder Address"),
                CnvStr("Payment History Line"."Account Holder City"),
                CnvStr("Payment History Line"."Acc. Hold. Country/Region Code"));
            Write(strData, false);

            EndOfLine();
        end;
    end;

    [Scope('OnPrem')]
    procedure GeneralIndicator()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'GIS+61';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure PRCIdentifier()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'PRC+11';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure FreeTextGeneral()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('FTX+REG+++%1', Concerns);
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure FreeText()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('FTX+PMD+++%1:%2:%3:%4', CnvStr("Payment History Line"."Description 1"),
            CnvStr("Payment History Line"."Description 2"),
            CnvStr("Payment History Line"."Description 3"),
            CnvStr("Payment History Line"."Description 4"));
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure ProcessIdentification()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'PRC+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure SequenceDetails()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('SEQ++%1', Paymenthistorylinecounter);
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure DocumentMessageDetails()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'DOC+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure Currencies()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'CUX+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure AdjustmentDetails()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'AJT+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure DocumentLineIdentification()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'DLI+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure AdditionalProductID()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := 'PIA+';
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure ControlTotal()
    begin
        SegmentCounter := SegmentCounter + 1;

        strData := StrSubstNo('CNT+%1:%2', TotalNumberOfMessages, LINCounter);
        Write(strData, false);

        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure MessageTrailer()
    begin
        // This one must NOT be counted!
        strData := StrSubstNo('UNT+%1+%2', SegmentCounter, MessageIdentifier);
        Write(strData, false);
        EndOfLine();
    end;

    [Scope('OnPrem')]
    procedure InterchangeTrailer()
    begin
        // This one must NOT be counted!
        strData := StrSubstNo('UNZ+1+%1', GetSequenceNo());
        Write(strData, false);
        EndOfLine();
    end;

    local procedure Write(Text: Text[250]; LineTransition: Boolean)
    begin
        Text := UpperCase(Text);
        Curfile.Write(Text);
        if not LineTransition then
            Curfile.Seek(Curfile.Pos - 2);
    end;

    local procedure Openfile()
    begin
        Curfile.TextMode(true);
        Curfile.WriteMode(true);
        Curfile.Create(RBMgt.ServerTempFileName('.txt'));
    end;

    local procedure Closefile()
    var
        ReportChecksum: Codeunit "Report Checksum";
        ServerFileName: Text[1024];
    begin
        ServerFileName := Curfile.Name;
        Curfile.Trunc();
        Curfile.Close();
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

    local procedure MakeAmountText(Amount: Decimal) AmountText: Text[250]
    begin
        AmountText := Format(Amount, 0, '<integer><decimals,3><comma,,>');
    end;

    local procedure EndOfLine()
    begin
        Clear(strData);
        strData[1] := '''';
        Curfile.Write(strData);
    end;

    [Scope('OnPrem')]
    procedure GetYYMMDD(DateToUse: Date; AppendCentury: Boolean) DateStr: Code[10]
    var
        strYear: Text[4];
        strMonth: Text[2];
        strDay: Text[2];
    begin
        if AppendCentury then
            strYear := Format(DateToUse, 4, '<Year4>')
        else
            strYear := Format(DateToUse, 2, '<Year>');
        strMonth := Format(DateToUse, 2, '<Month>');
        if strMonth[1] = ' ' then
            strMonth[1] := '0';
        strDay := Format(DateToUse, 2, '<Day>');
        if strDay[1] = ' ' then
            strDay[1] := '0';
        exit(strYear + strMonth + strDay);
    end;

    local procedure GetTimeString(): Code[10]
    begin
        exit(CharacterFilter(Format(Time, 5), '0123456789'));
    end;

    local procedure GetSenderID(): Code[35]
    begin
        exit('CLIENTIDENTIFICATION');
    end;

    local procedure GetCurrencyCode() CurrCode: Code[10]
    var
        PaymLine: Record "Payment History Line";
    begin
        PaymLine.SetRange("Our Bank", "Payment History"."Our Bank");
        PaymLine.SetRange("Run No.", "Payment History"."Run No.");
        if PaymLine.FindFirst() then
            if PaymLine."Currency Code" = '' then
                CurrCode := AccountingSetup."LCY Code"
            else
                CurrCode := PaymLine."Currency Code";
    end;

    local procedure GetSequenceNo(): Text[10]
    begin
        exit("Payment History"."Run No.");
    end;

    local procedure CnvStr(text: Text[250]) ResultStr: Text[250]
    var
        i: Integer;
        j: Integer;
    begin
        j := 1;
        for i := 1 to StrLen(text) do begin
            if StrPos(ReservedChars, Format(text[i])) > 0 then begin
                ResultStr[j] := '?';
                j := j + 1;
            end;
            ResultStr[j] := text[i];
            j := j + 1;
        end;
    end;

    local procedure CharacterFilter(Text: Text[250]; "Filter": Text[250]): Text[250]
    begin
        exit(DelChr(Text, '=', DelChr(Text, '=', Filter)));
    end;
}

