// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

report 7000003 "Receivable Bill"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Receivables/ReceivableBill.rdlc';
    Caption = 'Receivable Bill';

    dataset
    {
        dataitem(CustLedgEntry; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.") where("Document Situation" = filter("Posted BG/PO" | "BG/PO" | Cartera));
            column(DocumentNo_CustLedgEntry; "Document No.")
            {
            }
            column(BillNo_CustLedgEntry; "Bill No.")
            {
            }
            column(DrawCity; DrawCity)
            {
            }
            column(PrintAmt; PrintAmt)
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(CurrencyCode; CurrencyCode)
            {
            }
            column(DrawDate; Format(DrawDate))
            {
            }
            column(DueDate_CustLedgEntry; Format("Due Date"))
            {
            }
            column(NumberText1; NumberText[1])
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(PostingDate_CustLedgEntry; Format("Posting Date"))
            {
            }
            column(PaymentMethod; PaymentMethod)
            {
            }
            column(CustBankAccName; CustBankAcc.Name)
            {
            }
            column(CustBankAccBankAccNoDetails; CustBankAcc."Bank Account No." + CustBankAcc."CCC Bank Account No.")
            {
            }
            column(CustVATRegNo; Customer."VAT Registration No.")
            {
            }
            column(CustAddr6; CustAddr[6])
            {
            }
            column(CustAddr7; CustAddr[7])
            {
            }
            column(CustAddr5; CustAddr[5])
            {
            }
            column(CustAddr4; CustAddr[4])
            {
            }
            column(CustAddr2; CustAddr[2])
            {
            }
            column(CustAddr3; CustAddr[3])
            {
            }
            column(CustAddr1; CustAddr[1])
            {
            }
            column(CurrencyTxt; CurrencyTxt)
            {
            }
            column(NumberText2; NumberText[2])
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(EntryNo_CustLedgEntry; "Entry No.")
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(StatedAddressCaption; YouarekindlyadvisedtopayinthestatedaddressCaptionLbl)
            {
            }
            column(WithTheFollowingDetailsCaption; WithTheFollowingDetailsCaptionLbl)
            {
            }
            column(RelatedtoCaption; RelatedtoCaptionLbl)
            {
            }
            column(InvoiceNoCaption; InvoiceNoCaptionLbl)
            {
            }
            column(IssuedDateCaption; IssuedDateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CustBankAcc.Init();

                GLSetup.Get();

                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if PrintAmountsInLCY then begin
                    FormatNoText(NumberText, "Remaining Amt. (LCY)");
                    CurrencyCode := GLSetup."LCY Code";
                end else begin
                    FormatNoText(NumberText, "Remaining Amount");
                    if "Currency Code" = '' then
                        CurrencyCode := GLSetup."LCY Code"
                    else
                        CurrencyCode := "Currency Code";
                end;

                CurrencyTxt := StrSubstNo(Text1100000, CurrencyCode);

                case "Document Situation" of
                    "Document Situation"::"BG/PO", "Document Situation"::Cartera:
                        begin
                            Doc.Get(Doc.Type::Receivable, CustLedgEntry."Entry No.");
                            CollectionAgent := Doc."Collection Agent";
                            AccountNo := Doc."Account No.";
                            if CustBankAcc.Get(AccountNo, Doc."Cust./Vendor Bank Acc. Code") then;
                            if PrintAmountsInLCY then
                                PrintAmt := CustLedgEntry."Remaining Amt. (LCY)"
                            else
                                PrintAmt := CustLedgEntry."Remaining Amount";
                            if Doc."Bill Gr./Pmt. Order No." <> '' then begin
                                BillGr.Get(Doc."Bill Gr./Pmt. Order No.");
                                GroupPostingDate := BillGr."Posting Date";
                            end;
                            PaymentMethod := Doc."Payment Method Code";
                        end;
                    "Document Situation"::"Posted BG/PO":
                        begin
                            PostedDoc.Get(PostedDoc.Type::Receivable, CustLedgEntry."Entry No.");
                            CollectionAgent := PostedDoc."Collection Agent";
                            AccountNo := PostedDoc."Account No.";
                            if CustBankAcc.Get(AccountNo, PostedDoc."Cust./Vendor Bank Acc. Code") then;
                            PostedBillGr.Get(PostedDoc."Bill Gr./Pmt. Order No.");
                            if PrintAmountsInLCY then
                                PrintAmt := PostedDoc."Amt. for Collection (LCY)"
                            else
                                PrintAmt := PostedDoc."Amount for Collection";
                            GroupPostingDate := PostedBillGr."Posting Date";
                            PaymentMethod := PostedDoc."Payment Method Code";
                        end;
                end;

                if DrawDate = 0D then
                    if GroupPostingDate <> 0D then
                        DrawDate := GroupPostingDate
                    else
                        DrawDate := WorkDate();

                Customer.Get(AccountNo);
                FormatAddress.Customer(CustAddr, Customer);
                if NumberText[1] = Text1100002 then
                    NumberText[1] := NumberText[1] + Text1100059;
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
                    field(DrawDate; DrawDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date of Drawing';
                        ToolTip = 'Specifies the creation date that will be printed on the bill. By default, the programs uses today''s date as the drawing date.';
                    }
                    field(DrawCity; DrawCity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City of Drawing';
                        ToolTip = 'Specifies the city where your company is located. By default, the city defined in the Company Information window is used.';
                    }
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CompanyInfo.Get();
            DrawCity := CompanyInfo.City;

            DrawDate := WorkDate();
        end;
    }

    labels
    {
    }

    var
        Text1100000: Label 'The total amount of %1';
        Text1100001: Label '%1 is too big to be text-formatted';
        Text1100002: Label 'CERO ';
        Text1100003: Label '<decimals>', Locked = true;
        Text1100004: Label 'CON ';
        Text1100005: Label 'MILLONES ';
        Text1100006: Label 'UN MILLÓN ';
        Text1100007: Label 'MIL ';
        Text1100008: Label 'CIEN ';
        Text1100009: Label 'CIENTO ';
        Text1100010: Label 'DOSCIENTOS ';
        Text1100011: Label 'TRESCIENTOS ';
        Text1100012: Label 'CUATROCIENTOS ';
        Text1100013: Label 'QUINIENTOS ';
        Text1100014: Label 'SEISCIENTOS ';
        Text1100015: Label 'SETECIENTOS ';
        Text1100016: Label 'OCHOCIENTOS ';
        Text1100017: Label 'NOVECIENTOS ';
        Text1100018: Label 'DOSCIENTOS ';
        Text1100019: Label 'TRESCIENTOS ';
        Text1100020: Label 'CUATROCIENTOS ';
        Text1100021: Label 'QUINIENTOS ';
        Text1100022: Label 'SEISCIENTOS ';
        Text1100023: Label 'SETECIENTOS ';
        Text1100024: Label 'OCHOCIENTOS ';
        Text1100025: Label 'NOVECIENTOS ';
        Text1100026: Label 'DIEZ ';
        Text1100027: Label 'ONCE ';
        Text1100028: Label 'DOCE ';
        Text1100029: Label 'TRECE ';
        Text1100030: Label 'CATORCE ';
        Text1100031: Label 'QUINCE ';
        Text1100032: Label 'DIECI';
        Text1100033: Label 'VEINTE ';
        Text1100034: Label 'VEINTI';
        Text1100035: Label 'TREINTA ';
        Text1100036: Label 'TREINTA Y ';
        Text1100037: Label 'CUARENTA ';
        Text1100038: Label 'CUARENTA Y ';
        Text1100039: Label 'CINCUENTA ';
        Text1100040: Label 'CINCUENTA Y ';
        Text1100041: Label 'SESENTA ';
        Text1100042: Label 'SESENTA Y ';
        Text1100043: Label 'SETENTA ';
        Text1100044: Label 'SETENTA Y ';
        Text1100045: Label 'OCHENTA ';
        Text1100046: Label 'OCHENTA Y ';
        Text1100047: Label 'NOVENTA ';
        Text1100048: Label 'NOVENTA Y ';
        Text1100049: Label 'UN ';
        Text1100050: Label 'UNO ';
        Text1100051: Label 'DOS ';
        Text1100052: Label 'TRES ';
        Text1100053: Label 'CUATRO ';
        Text1100054: Label 'CINCO ';
        Text1100055: Label 'SEIS ';
        Text1100056: Label 'SIETE ';
        Text1100057: Label 'OCHO ';
        Text1100058: Label 'NUEVE ';
        Text1100059: Label ' CÉNTIMOS';
        Text1100060: Label ' CÉNTIMOS';
        Text1100061: Label 'MILESIMAS';
        Text1100062: Label 'DIEZMILESIMAS';
        Text1100063: Label ' CÉNTIMO';
        Text1100064: Label ' CÉNTIMO';
        Text1100065: Label 'MILESIMA';
        Text1100066: Label 'DIEZMILESIMA';
        Text1100067: Label '%1 \results in a written number which is too long.';
        Doc: Record "Cartera Doc.";
        PostedDoc: Record "Posted Cartera Doc.";
        BillGr: Record "Bill Group";
        PostedBillGr: Record "Posted Bill Group";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustBankAcc: Record "Customer Bank Account";
        GLSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        PaymentMethod: Code[10];
        CustAddr: array[8] of Text[100];
        CollectionAgent: Option Direct,Bank;
        AccountNo: Code[20];
        GroupPostingDate: Date;
        CurrencyTxt: Text[250];
        DrawCity: Text[30];
        DrawDate: Date;
        PrintAmountsInLCY: Boolean;
        PrintAmt: Decimal;
        CurrencyCode: Code[10];
        NumberText: array[2] of Text[80];
        Remainder: Integer;
        HundMilion: Integer;
        TenMilion: Integer;
        UnitsMilion: Integer;
        HundThousands: Integer;
        TenThousands: Integer;
        UnitsThousands: Integer;
        Units: Integer;
        DecimalPlaces: Integer;
        DecimalText: array[2] of Text[80];
        DecimalString: Text[15];
        Decimals: Integer;
        EmptyStringCaptionLbl: Label '/', Locked = true;
        RelatedtoCaptionLbl: Label 'related to';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        IssuedDateCaptionLbl: Label 'issued date';
        YouarekindlyadvisedtopayinthestatedaddressCaptionLbl: Label 'You are kindly advised to pay in the stated address';
        WithTheFollowingDetailsCaptionLbl: Label 'with the following details';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if PrintAmountsInLCY then
            exit('');

        case CustLedgEntry."Document Situation" of
            CustLedgEntry."Document Situation"::"BG/PO", CustLedgEntry."Document Situation"::Cartera:
                exit(Doc."Currency Code");
            CustLedgEntry."Document Situation"::"Posted BG/PO":
                exit(PostedDoc."Currency Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatNoText(var NoText: array[2] of Text[80]; No: Decimal)
    var
        Tens: Integer;
        Hundreds: Integer;
        NoTextIndex: Integer;
    begin
        Clear(NoText);
        NoTextIndex := 1;

        if No > 999999999 then
            Error(Text1100001, No);

        if Round(No, 1, '<') = 0 then
            AddToNoText(NoText, NoTextIndex, Text1100002);

        HundMilion := Round(No, 1, '<') div 100000000;
        Remainder := Round(No, 1, '<') mod 100000000;
        TenMilion := Remainder div 10000000;
        Remainder := Remainder mod 10000000;
        UnitsMilion := Remainder div 1000000;
        Remainder := Remainder mod 1000000;
        HundThousands := Remainder div 100000;
        Remainder := Remainder mod 100000;
        TenThousands := Remainder div 10000;
        Remainder := Remainder mod 10000;
        UnitsThousands := Remainder div 1000;
        Remainder := Remainder mod 1000;
        Hundreds := Remainder div 100;
        Remainder := Remainder mod 100;
        Tens := Remainder div 10;
        Units := Remainder mod 10;
        DecimalPlaces := StrLen(Format(No, 0, Text1100003));
        if DecimalPlaces > 0 then begin
            DecimalPlaces := DecimalPlaces - 1;
            Decimals := (No - Round(No, 1, '<')) * Power(10, DecimalPlaces);
            if DecimalPlaces = 1 then
                Decimals := Decimals * 10;
            DecimalString := TextNoDecimals(DecimalPlaces);
        end;
        AddToNoText(NoText, NoTextIndex, TextHundMilion(HundMilion, TenMilion, UnitsMilion, true));
        AddToNoText(NoText, NoTextIndex, TextTenUnitsMilion(HundMilion, TenMilion, UnitsMilion, true));
        AddToNoText(NoText, NoTextIndex, TextHundThousands(HundThousands, TenThousands, UnitsThousands, false));
        AddToNoText(NoText, NoTextIndex, TextTenUnitsThousands(HundThousands, TenThousands, UnitsThousands, false));
        AddToNoText(NoText, NoTextIndex, TextHundreds(Hundreds, Tens, Units, false));
        AddToNoText(NoText, NoTextIndex, TextTensUnits(Tens, Units, false));
        if DecimalPlaces > 0 then begin
            FormatNoText(DecimalText, Decimals);
            AddToNoText(
              // NoText,NoTextIndex,Text1100004 + DecimalText[1] + TextNoDecimals(DecimalPlaces));
              NoText, NoTextIndex, Text1100004 + DecimalText[1] + DecimalString);
        end;
    end;

    [Scope('OnPrem')]
    procedure TextHundMilion(Hundreds: Integer; Ten: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        if Hundreds <> 0 then
            exit(TextHundreds(Hundreds, Ten, Units, true));
    end;

    [Scope('OnPrem')]
    procedure TextTenUnitsMilion(Hundreds: Integer; Ten: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        if (Hundreds <> 0) and (Ten = 0) and (Units = 0) then
            exit(Text1100005);
        if (Hundreds = 0) and (Ten = 0) and (Units = 1) then
            exit(Text1100006);
        if (Ten <> 0) or (Units <> 0) then
            exit(TextTensUnits(Ten, Units, Masc) + Text1100005);
    end;

    [Scope('OnPrem')]
    procedure TextHundThousands(Hundreds: Integer; Ten: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        if Hundreds <> 0 then
            exit(TextHundreds(Hundreds, Ten, Units, Masc))
    end;

    [Scope('OnPrem')]
    procedure TextTenUnitsThousands(Hundreds: Integer; Ten: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        if (Hundreds <> 0) and (Ten = 0) and (Units = 0) then
            exit(Text1100007);
        if (Hundreds = 0) and (Ten = 0) and (Units = 1) then
            exit(Text1100007);
        if (Ten <> 0) or (Units <> 0) then
            exit(TextTensUnits(Ten, Units, Masc) + Text1100007);
    end;

    [Scope('OnPrem')]
    procedure TextHundreds(Hundreds: Integer; Tens: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        if Hundreds = 0 then
            exit('');
        if Masc then
            case Hundreds of
                1:
                    if (Tens = 0) and (Units = 0) then
                        exit(Text1100008)
                    else
                        exit(Text1100009);
                2:
                    exit(Text1100010);
                3:
                    exit(Text1100011);
                4:
                    exit(Text1100012);
                5:
                    exit(Text1100013);
                6:
                    exit(Text1100014);
                7:
                    exit(Text1100015);
                8:
                    exit(Text1100016);
                9:
                    exit(Text1100017);
            end
        else
            case Hundreds of
                1:
                    if (Tens = 0) and (Units = 0) then
                        exit(Text1100008)
                    else
                        exit(Text1100009);
                2:
                    exit(Text1100018);
                3:
                    exit(Text1100019);
                4:
                    exit(Text1100020);
                5:
                    exit(Text1100021);
                6:
                    exit(Text1100022);
                7:
                    exit(Text1100023);
                8:
                    exit(Text1100024);
                9:
                    exit(Text1100025);
            end;
    end;

    [Scope('OnPrem')]
    procedure TextTensUnits(Tens: Integer; Units: Integer; Masc: Boolean): Text[250]
    begin
        case Tens of
            0:
                exit(TextUnits(Units, Masc));
            1:
                case Units of
                    0:
                        exit(Text1100026);
                    1:
                        exit(Text1100027);
                    2:
                        exit(Text1100028);
                    3:
                        exit(Text1100029);
                    4:
                        exit(Text1100030);
                    5:
                        exit(Text1100031);
                    else
                        exit(Text1100032 + TextUnits(Units, Masc));
                end;
            2:
                if Units = 0 then
                    exit(Text1100033)
                else
                    exit(Text1100034 + TextUnits(Units, Masc));
            3:
                if Units = 0 then
                    exit(Text1100035)
                else
                    exit(Text1100036 + TextUnits(Units, Masc));
            4:
                if Units = 0 then
                    exit(Text1100037)
                else
                    exit(Text1100038 + TextUnits(Units, Masc));
            5:
                if Units = 0 then
                    exit(Text1100039)
                else
                    exit(Text1100040 + TextUnits(Units, Masc));
            6:
                if Units = 0 then
                    exit(Text1100041)
                else
                    exit(Text1100042 + TextUnits(Units, Masc));
            7:
                if Units = 0 then
                    exit(Text1100043)
                else
                    exit(Text1100044 + TextUnits(Units, Masc));
            8:
                if Units = 0 then
                    exit(Text1100045)
                else
                    exit(Text1100046 + TextUnits(Units, Masc));
            9:
                if Units = 0 then
                    exit(Text1100047)
                else
                    exit(Text1100048 + TextUnits(Units, Masc));
        end;
    end;

    [Scope('OnPrem')]
    procedure TextUnits(Units: Integer; Masc: Boolean): Text[250]
    begin
        case Units of
            0:
                exit('');
            1:
                if Masc then
                    exit(Text1100049)
                else
                    exit(Text1100050);
            2:
                exit(Text1100051);
            3:
                exit(Text1100052);
            4:
                exit(Text1100053);
            5:
                exit(Text1100054);
            6:
                exit(Text1100055);
            7:
                exit(Text1100056);
            8:
                exit(Text1100057);
            9:
                exit(Text1100058);
        end;
    end;

    [Scope('OnPrem')]
    procedure TextNoDecimals(NoDecimals: Integer): Text[15]
    begin
        if Decimals > 1 then
            case NoDecimals of
                0:
                    exit('');
                1:
                    exit(Text1100059);
                2:
                    exit(Text1100060);
                3:
                    exit(Text1100061);
                4:
                    exit(Text1100062);
            end
        else
            case NoDecimals of
                0:
                    exit('');
                1:
                    exit(Text1100063);
                2:
                    exit(Text1100064);
                3:
                    exit(Text1100065);
                4:
                    exit(Text1100066);
            end;
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; AddText: Text[80])
    begin
        while StrLen(NoText[NoTextIndex] + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then
                Error(Text1100067, AddText);
        end;

        NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + AddText, '<');
    end;
}

