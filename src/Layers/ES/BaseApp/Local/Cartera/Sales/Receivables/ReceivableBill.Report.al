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
    RDLCLayout = './Local/Cartera/Sales/Receivables/ReceivableBill.rdlc';
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
            column(DrawCity; BillDrawCity)
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
            column(DrawDate; Format(BillDrawDate))
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
                if ShowAmountsInLCY then begin
                    FormatNoText(NumberText, "Remaining Amt. (LCY)");
                    CurrencyCode := GLSetup."LCY Code";
                end else begin
                    FormatNoText(NumberText, "Remaining Amount");
                    if "Currency Code" = '' then
                        CurrencyCode := GLSetup."LCY Code"
                    else
                        CurrencyCode := "Currency Code";
                end;

                CurrencyTxt := StrSubstNo(Text1100000Lbl, CurrencyCode);

                case "Document Situation" of
                    "Document Situation"::"BG/PO", "Document Situation"::Cartera:
                        begin
                            Doc.Get(Doc.Type::Receivable, CustLedgEntry."Entry No.");
                            CollectionAgent := Doc."Collection Agent";
                            AccountNo := Doc."Account No.";
                            if CustBankAcc.Get(AccountNo, Doc."Cust./Vendor Bank Acc. Code") then;
                            if ShowAmountsInLCY then
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
                            if ShowAmountsInLCY then
                                PrintAmt := PostedDoc."Amt. for Collection (LCY)"
                            else
                                PrintAmt := PostedDoc."Amount for Collection";
                            GroupPostingDate := PostedBillGr."Posting Date";
                            PaymentMethod := PostedDoc."Payment Method Code";
                        end;
                end;

                if BillDrawDate = 0D then
                    if GroupPostingDate <> 0D then
                        BillDrawDate := GroupPostingDate
                    else
                        BillDrawDate := WorkDate();

                Customer.Get(AccountNo);
                FormatAddress.Customer(CustAddr, Customer);
                if NumberText[1] = Text1100002Lbl then
                    NumberText[1] := NumberText[1] + Text1100059Lbl;
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
                    field(DrawDate; BillDrawDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date of Drawing';
                        ToolTip = 'Specifies the creation date that will be printed on the bill. By default, the programs uses today''s date as the drawing date.';
                    }
                    field(DrawCity; BillDrawCity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City of Drawing';
                        ToolTip = 'Specifies the city where your company is located. By default, the city defined in the Company Information window is used.';
                    }
                    field(PrintAmountsInLCY; ShowAmountsInLCY)
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
            BillDrawCity := CompanyInfo.City;

            BillDrawDate := WorkDate();
        end;
    }

    labels
    {
    }

    var
        Doc: Record "Cartera Doc.";
        PostedDoc: Record "Posted Cartera Doc.";
        BillGr: Record "Bill Group";
        PostedBillGr: Record "Posted Bill Group";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustBankAcc: Record "Customer Bank Account";
        GLSetup: Record "General Ledger Setup";
        FormatAddress: Codeunit "Format Address";
        Text1100000Lbl: Label 'The total amount of %1', Comment = '%1 = Currency code';
        Text1100001Lbl: Label '%1 is too big to be text-formatted', Comment = '%1 = Amount to format in words';
        Text1100002Lbl: Label 'CERO ';
        Text1100003Lbl: Label '<decimals>', Locked = true;
        Text1100004Lbl: Label 'CON ';
        Text1100005Lbl: Label 'MILLONES ';
        Text1100006Lbl: Label 'UN MILLÓN ';
        Text1100007Lbl: Label 'MIL ';
        Text1100008Lbl: Label 'CIEN ';
        Text1100009Lbl: Label 'CIENTO ';
        Text1100010Lbl: Label 'DOSCIENTOS ';
        Text1100011Lbl: Label 'TRESCIENTOS ';
        Text1100012Lbl: Label 'CUATROCIENTOS ';
        Text1100013Lbl: Label 'QUINIENTOS ';
        Text1100014Lbl: Label 'SEISCIENTOS ';
        Text1100015Lbl: Label 'SETECIENTOS ';
        Text1100016Lbl: Label 'OCHOCIENTOS ';
        Text1100017Lbl: Label 'NOVECIENTOS ';
        Text1100018Lbl: Label 'DOSCIENTOS ';
        Text1100019Lbl: Label 'TRESCIENTOS ';
        Text1100020Lbl: Label 'CUATROCIENTOS ';
        Text1100021Lbl: Label 'QUINIENTOS ';
        Text1100022Lbl: Label 'SEISCIENTOS ';
        Text1100023Lbl: Label 'SETECIENTOS ';
        Text1100024Lbl: Label 'OCHOCIENTOS ';
        Text1100025Lbl: Label 'NOVECIENTOS ';
        Text1100026Lbl: Label 'DIEZ ';
        Text1100027Lbl: Label 'ONCE ';
        Text1100028Lbl: Label 'DOCE ';
        Text1100029Lbl: Label 'TRECE ';
        Text1100030Lbl: Label 'CATORCE ';
        Text1100031Lbl: Label 'QUINCE ';
        Text1100032Lbl: Label 'DIECI';
        Text1100033Lbl: Label 'VEINTE ';
        Text1100034Lbl: Label 'VEINTI';
        Text1100035Lbl: Label 'TREINTA ';
        Text1100036Lbl: Label 'TREINTA Y ';
        Text1100037Lbl: Label 'CUARENTA ';
        Text1100038Lbl: Label 'CUARENTA Y ';
        Text1100039Lbl: Label 'CINCUENTA ';
        Text1100040Lbl: Label 'CINCUENTA Y ';
        Text1100041Lbl: Label 'SESENTA ';
        Text1100042Lbl: Label 'SESENTA Y ';
        Text1100043Lbl: Label 'SETENTA ';
        Text1100044Lbl: Label 'SETENTA Y ';
        Text1100045Lbl: Label 'OCHENTA ';
        Text1100046Lbl: Label 'OCHENTA Y ';
        Text1100047Lbl: Label 'NOVENTA ';
        Text1100048Lbl: Label 'NOVENTA Y ';
        Text1100049Lbl: Label 'UN ';
        Text1100050Lbl: Label 'UNO ';
        Text1100051Lbl: Label 'DOS ';
        Text1100052Lbl: Label 'TRES ';
        Text1100053Lbl: Label 'CUATRO ';
        Text1100054Lbl: Label 'CINCO ';
        Text1100055Lbl: Label 'SEIS ';
        Text1100056Lbl: Label 'SIETE ';
        Text1100057Lbl: Label 'OCHO ';
        Text1100058Lbl: Label 'NUEVE ';
        Text1100059Lbl: Label ' CÉNTIMOS';
        Text1100060Lbl: Label ' CÉNTIMOS';
        Text1100061Lbl: Label 'MILESIMAS';
        Text1100062Lbl: Label 'DIEZMILESIMAS';
        Text1100063Lbl: Label ' CÉNTIMO';
        Text1100064Lbl: Label ' CÉNTIMO';
        Text1100065Lbl: Label 'MILESIMA';
        Text1100066Lbl: Label 'DIEZMILESIMA';
        Text1100067Lbl: Label '%1 \results in a written number which is too long.', Comment = '%1 = Text to add to the amount in words';
        PaymentMethod: Code[10];
        CustAddr: array[8] of Text[100];
        CollectionAgent: Option Direct,Bank;
        AccountNo: Code[20];
        GroupPostingDate: Date;
        CurrencyTxt: Text[250];
        BillDrawCity: Text[30];
        BillDrawDate: Date;
        ShowAmountsInLCY: Boolean;
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
        UnitsDigit: Integer;
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
        if ShowAmountsInLCY then
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
            Error(Text1100001Lbl, No);

        if Round(No, 1, '<') = 0 then
            AddToNoText(NoText, NoTextIndex, Text1100002Lbl);

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
        UnitsDigit := Remainder mod 10;
        DecimalPlaces := StrLen(Format(No, 0, Text1100003Lbl));
        if DecimalPlaces > 0 then begin
            DecimalPlaces := DecimalPlaces - 1;
            Decimals := (No - Round(No, 1, '<')) * Power(10, DecimalPlaces);
            if DecimalPlaces = 1 then
                Decimals := Decimals * 10;
            DecimalString := TextNoDecimals(DecimalPlaces);
        end;
#pragma warning disable AA0139
        AddToNoText(NoText, NoTextIndex, TextHundMilion(HundMilion, TenMilion, UnitsMilion, true));
        AddToNoText(NoText, NoTextIndex, TextTenUnitsMilion(HundMilion, TenMilion, UnitsMilion, true));
        AddToNoText(NoText, NoTextIndex, TextHundThousands(HundThousands, TenThousands, UnitsThousands, false));
        AddToNoText(NoText, NoTextIndex, TextTenUnitsThousands(HundThousands, TenThousands, UnitsThousands, false));
        AddToNoText(NoText, NoTextIndex, TextHundreds(Hundreds, Tens, UnitsDigit, false));
        AddToNoText(NoText, NoTextIndex, TextTensUnits(Tens, UnitsDigit, false));
#pragma warning restore AA0139
        if DecimalPlaces > 0 then begin
            FormatNoText(DecimalText, Decimals);
            AddToNoText(
              // NoText,NoTextIndex,Text1100004 + DecimalText[1] + TextNoDecimals(DecimalPlaces));
              NoText, NoTextIndex, Text1100004Lbl + DecimalText[1] + DecimalString);
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
            exit(Text1100005Lbl);
        if (Hundreds = 0) and (Ten = 0) and (Units = 1) then
            exit(Text1100006Lbl);
        if (Ten <> 0) or (Units <> 0) then
#pragma warning disable AA0139
            exit(TextTensUnits(Ten, Units, Masc) + Text1100005Lbl);
#pragma warning restore AA0139
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
            exit(Text1100007Lbl);
        if (Hundreds = 0) and (Ten = 0) and (Units = 1) then
            exit(Text1100007Lbl);
        if (Ten <> 0) or (Units <> 0) then
#pragma warning disable AA0139
            exit(TextTensUnits(Ten, Units, Masc) + Text1100007Lbl);
#pragma warning restore AA0139
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
                        exit(Text1100008Lbl)
                    else
                        exit(Text1100009Lbl);
                2:
                    exit(Text1100010Lbl);
                3:
                    exit(Text1100011Lbl);
                4:
                    exit(Text1100012Lbl);
                5:
                    exit(Text1100013Lbl);
                6:
                    exit(Text1100014Lbl);
                7:
                    exit(Text1100015Lbl);
                8:
                    exit(Text1100016Lbl);
                9:
                    exit(Text1100017Lbl);
            end
        else
            case Hundreds of
                1:
                    if (Tens = 0) and (Units = 0) then
                        exit(Text1100008Lbl)
                    else
                        exit(Text1100009Lbl);
                2:
                    exit(Text1100018Lbl);
                3:
                    exit(Text1100019Lbl);
                4:
                    exit(Text1100020Lbl);
                5:
                    exit(Text1100021Lbl);
                6:
                    exit(Text1100022Lbl);
                7:
                    exit(Text1100023Lbl);
                8:
                    exit(Text1100024Lbl);
                9:
                    exit(Text1100025Lbl);
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
                        exit(Text1100026Lbl);
                    1:
                        exit(Text1100027Lbl);
                    2:
                        exit(Text1100028Lbl);
                    3:
                        exit(Text1100029Lbl);
                    4:
                        exit(Text1100030Lbl);
                    5:
                        exit(Text1100031Lbl);
                    else
#pragma warning disable AA0139
                        exit(Text1100032Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
                end;
            2:
                if Units = 0 then
                    exit(Text1100033Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100034Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            3:
                if Units = 0 then
                    exit(Text1100035Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100036Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            4:
                if Units = 0 then
                    exit(Text1100037Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100038Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            5:
                if Units = 0 then
                    exit(Text1100039Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100040Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            6:
                if Units = 0 then
                    exit(Text1100041Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100042Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            7:
                if Units = 0 then
                    exit(Text1100043Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100044Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            8:
                if Units = 0 then
                    exit(Text1100045Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100046Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
            9:
                if Units = 0 then
                    exit(Text1100047Lbl)
                else
#pragma warning disable AA0139
                    exit(Text1100048Lbl + TextUnits(Units, Masc));
#pragma warning restore AA0139
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
                    exit(Text1100049Lbl)
                else
                    exit(Text1100050Lbl);
            2:
                exit(Text1100051Lbl);
            3:
                exit(Text1100052Lbl);
            4:
                exit(Text1100053Lbl);
            5:
                exit(Text1100054Lbl);
            6:
                exit(Text1100055Lbl);
            7:
                exit(Text1100056Lbl);
            8:
                exit(Text1100057Lbl);
            9:
                exit(Text1100058Lbl);
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
                    exit(Text1100059Lbl);
                2:
                    exit(Text1100060Lbl);
                3:
                    exit(Text1100061Lbl);
                4:
                    exit(Text1100062Lbl);
            end
        else
            case NoDecimals of
                0:
                    exit('');
                1:
                    exit(Text1100063Lbl);
                2:
                    exit(Text1100064Lbl);
                3:
                    exit(Text1100065Lbl);
                4:
                    exit(Text1100066Lbl);
            end;
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; AddText: Text[80])
    begin
        while StrLen(NoText[NoTextIndex] + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then
                Error(Text1100067Lbl, AddText);
        end;

#pragma warning disable AA0139
        NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + AddText, '<');
#pragma warning restore AA0139
    end;
}

