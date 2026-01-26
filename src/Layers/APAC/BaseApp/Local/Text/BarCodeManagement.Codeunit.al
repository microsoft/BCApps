// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

codeunit 28001 "BarCode Management"
{

    trigger OnRun()
    begin
    end;

    var
        Bar3Table: array[64] of Text[3];
        Bar2Table: array[10] of Text[2];
        CTable: array[64] of Text[1];
        BarTablesGenerated: Boolean;
        mult: array[64, 64] of Integer;
        gen: array[5] of Integer;

    [Scope('OnPrem')]
    procedure BuildBarCode(AddressID: Text[10]; CustInfo: Text[15]; var BarCode: Text[67]): Integer
    var
        AddressIDBarCode: Text[16];
        FCCBarCode: Text[4];
        CustInfoBarCode: Text[31];
        FCC: Text[2];
        BarCodeLen: Integer;
        TestNumeric: BigInteger;
        CustInfoLenght: Integer;
        i: Integer;
        TempBarCode: Text[67];
    begin
        // ErrorCode := 1: Numerical Customer Information Too Long
        // ErrorCode := 2: Alphabetical Customer Information Too Long
        // ErrorCode := 3: Address ID does not contain 8 digits
        // ErrorCode := 4: Address ID contains letters
        // ErrorCode := 5: Reed Solomon not calculated
        // ErrorCode := 6: Address ID does not exist

        BarCode := '';
        if AddressID <> '' then begin
            GenerateBarTables();
            if Evaluate(TestNumeric, AddressID) then begin
                if StrLen(AddressID) = 8 then
                    AddressIDBarCode := EncodeInfo(0, AddressID)
                else
                    exit(3);
            end else
                exit(4);
        end else
            exit(6);

        CustInfoLenght := StrLen(CustInfo);
        case true of
            CustInfoLenght = 0:
                begin
                    FCC := '11';
                    BarCodeLen := 37;
                    CustInfoBarCode := '3';
                end;
            Evaluate(TestNumeric, CustInfo):
                case true of
                    CustInfoLenght <= 8:
                        begin
                            FCC := '59';
                            BarCodeLen := 52;
                            for i := 1 to (8 - CustInfoLenght) do
                                CustInfo := '0' + CustInfo;
                            CustInfoBarCode := EncodeInfo(0, CustInfo);
                        end;
                    (CustInfoLenght > 8) and (CustInfoLenght <= 15):
                        begin
                            FCC := '62';
                            BarCodeLen := 67;
                            for i := 1 to (15 - CustInfoLenght) do
                                CustInfo := '0' + CustInfo;
                            CustInfoBarCode := EncodeInfo(0, CustInfo) + '3';
                        end;
                    (CustInfoLenght > 15):
                        exit(1);
                end;
            else
                case true of
                    CustInfoLenght <= 5:
                        begin
                            FCC := '59';
                            BarCodeLen := 52;
                            for i := 1 to (5 - CustInfoLenght) do
                                CustInfo := ' ' + CustInfo;
                            CustInfoBarCode := EncodeInfo(1, CustInfo) + '3';
                        end;
                    (CustInfoLenght > 5) and (CustInfoLenght <= 10):
                        begin
                            FCC := '62';
                            BarCodeLen := 67;
                            for i := 1 to (10 - CustInfoLenght) do
                                CustInfo := ' ' + CustInfo;
                            CustInfoBarCode := EncodeInfo(1, CustInfo) + '3';
                        end;
                    (CustInfoLenght > 10):
                        exit(2);
                end;
        end;

        FCCBarCode := EncodeInfo(0, FCC);

        TempBarCode := FCCBarCode + AddressIDBarCode + CustInfoBarCode;

        if not AppendRSParity(TempBarCode) then
            exit(5);

        BarCode := '13' + TempBarCode + '13';
    end;

    local procedure EncodeInfo(TableToUse: Option NTable,CTable; InfoToCode: Text[250]) InfoBarCode: Text[31]
    var
        wCustInfo: Text[1];
        wCustInfoBarCodeN: Text[2];
        wCustInfoBarCodeC: Text[3];
        i: Integer;
    begin
        case TableToUse of
            TableToUse::NTable:
                for i := 1 to StrLen(InfoToCode) do begin
                    wCustInfoBarCodeN := '';
                    wCustInfo := Format(InfoToCode[i]);
                    NEncode(wCustInfo, wCustInfoBarCodeN);
                    InfoBarCode := InfoBarCode + wCustInfoBarCodeN;
                end;
            TableToUse::CTable:
                for i := 1 to StrLen(InfoToCode) do begin
                    wCustInfoBarCodeC := '';
                    wCustInfo := Format(InfoToCode[i]);
                    CEncode(wCustInfo, wCustInfoBarCodeC);
                    InfoBarCode := InfoBarCode + wCustInfoBarCodeC;
                end;
        end;
    end;

    local procedure BarToDec(var Dec: Integer; var Bar: Text[3])
    var
        i: Integer;
    begin
        if Bar = '' then
            Bar := Bar3Table[Dec + 1]
        else
            for i := 1 to 64 do
                if Bar = Bar3Table[i] then begin
                    Dec := i - 1;
                    exit;
                end;
    end;

    local procedure CEncode(var Character: Text[1]; var Bar: Text[3])
    var
        i: Integer;
    begin
        if Character <> '' then
            for i := 1 to 64 do
                if Character = CTable[i] then begin
                    Bar := Bar3Table[i];
                    exit;
                end
                else
                    for i := 1 to 64 do
                        if Bar = Bar3Table[i] then begin
                            Character := CTable[i];
                            exit;
                        end;
    end;

    local procedure NEncode(var Dec: Text[1]; var Bar: Text[2])
    var
        i: Integer;
    begin
        if Dec <> '' then begin
            if Evaluate(i, Dec) then
                Bar := Bar2Table[i + 1];
        end else
            for i := 1 to 10 do
                if Bar = Bar2Table[i] then begin
                    Dec := Format(i - 1);
                    exit;
                end;
    end;

    local procedure GenerateBarTables()
    begin
        if BarTablesGenerated = true then
            exit;
        Bar3Table[1] := '000';
        Bar3Table[2] := '001';
        Bar3Table[3] := '002';
        Bar3Table[4] := '003';
        Bar3Table[5] := '010';
        Bar3Table[6] := '011';
        Bar3Table[7] := '012';
        Bar3Table[8] := '013';
        Bar3Table[9] := '020';
        Bar3Table[10] := '021';
        Bar3Table[11] := '022';
        Bar3Table[12] := '023';
        Bar3Table[13] := '030';
        Bar3Table[14] := '031';
        Bar3Table[15] := '032';
        Bar3Table[16] := '033';
        Bar3Table[17] := '100';
        Bar3Table[18] := '101';
        Bar3Table[19] := '102';
        Bar3Table[20] := '103';
        Bar3Table[21] := '110';
        Bar3Table[22] := '111';
        Bar3Table[23] := '112';
        Bar3Table[24] := '113';
        Bar3Table[25] := '120';
        Bar3Table[26] := '121';
        Bar3Table[27] := '122';
        Bar3Table[28] := '123';
        Bar3Table[29] := '130';
        Bar3Table[30] := '131';
        Bar3Table[31] := '132';
        Bar3Table[32] := '133';
        Bar3Table[33] := '200';
        Bar3Table[34] := '201';
        Bar3Table[35] := '202';
        Bar3Table[36] := '203';
        Bar3Table[37] := '210';
        Bar3Table[38] := '211';
        Bar3Table[39] := '212';
        Bar3Table[40] := '213';
        Bar3Table[41] := '220';
        Bar3Table[42] := '221';
        Bar3Table[43] := '222';
        Bar3Table[44] := '223';
        Bar3Table[45] := '230';
        Bar3Table[46] := '231';
        Bar3Table[47] := '232';
        Bar3Table[48] := '233';
        Bar3Table[49] := '300';
        Bar3Table[50] := '301';
        Bar3Table[51] := '302';
        Bar3Table[52] := '303';
        Bar3Table[53] := '310';
        Bar3Table[54] := '311';
        Bar3Table[55] := '312';
        Bar3Table[56] := '313';
        Bar3Table[57] := '320';
        Bar3Table[58] := '321';
        Bar3Table[59] := '322';
        Bar3Table[60] := '323';
        Bar3Table[61] := '330';
        Bar3Table[62] := '331';
        Bar3Table[63] := '332';
        Bar3Table[64] := '333';
        Bar2Table[1] := '00';
        Bar2Table[2] := '01';
        Bar2Table[3] := '02';
        Bar2Table[4] := '10';
        Bar2Table[5] := '11';
        Bar2Table[6] := '12';
        Bar2Table[7] := '20';
        Bar2Table[8] := '21';
        Bar2Table[9] := '22';
        Bar2Table[10] := '30';
        CTable[1] := 'A';
        CTable[2] := 'B';
        CTable[3] := 'C';
        CTable[5] := 'D';
        CTable[6] := 'E';
        CTable[7] := 'F';
        CTable[9] := 'G';
        CTable[10] := 'H';
        CTable[11] := 'I';
        CTable[17] := 'J';
        CTable[18] := 'K';
        CTable[19] := 'L';
        CTable[21] := 'M';
        CTable[22] := 'N';
        CTable[23] := 'O';
        CTable[25] := 'P';
        CTable[26] := 'Q';
        CTable[27] := 'R';
        CTable[33] := 'S';
        CTable[34] := 'T';
        CTable[35] := 'U';
        CTable[37] := 'V';
        CTable[38] := 'W';
        CTable[39] := 'X';
        CTable[41] := 'Y';
        CTable[42] := 'Z';
        CTable[43] := '0';
        CTable[49] := '1';
        CTable[50] := '2';
        CTable[51] := '3';
        CTable[53] := '4';
        CTable[54] := '5';
        CTable[55] := '6';
        CTable[57] := '7';
        CTable[58] := '8';
        CTable[59] := '9';
        CTable[4] := ' ';
        CTable[8] := '#';
        CTable[12] := 'a';
        CTable[13] := 'b';
        CTable[14] := 'c';
        CTable[15] := 'd';
        CTable[16] := 'e';
        CTable[20] := 'f';
        CTable[24] := 'g';
        CTable[28] := 'h';
        CTable[29] := 'i';
        CTable[30] := 'j';
        CTable[31] := 'k';
        CTable[32] := 'l';
        CTable[36] := 'm';
        CTable[40] := 'n';
        CTable[44] := 'o';
        CTable[45] := 'p';
        CTable[46] := 'q';
        CTable[47] := 'r';
        CTable[48] := 's';
        CTable[52] := 't';
        CTable[56] := 'u';
        CTable[60] := 'v';
        CTable[61] := 'w';
        CTable[62] := 'x';
        CTable[63] := 'y';
        CTable[64] := 'z';
        BarTablesGenerated := true;
    end;

    local procedure AppendRSParity(var Barcode: Text[67]): Boolean
    var
        BarCodeLenght: Integer;
        iSymbols: Integer;
        iNumInfoSymbols: Integer;
        w_idx: Integer;
        wBarGroup: Text[3];
        i: Integer;
        j: Integer;
        ParitySymbols: array[4] of Integer;
        iTempCodeWord: array[21] of Integer;
        iCodeWord: array[21] of Integer;
    begin
        BarCodeLenght := StrLen(Barcode);
        if (BarCodeLenght <> 21) and (BarCodeLenght <> 36) and (BarCodeLenght <> 51) then
            exit(false);
        iNumInfoSymbols := BarCodeLenght / 3;
        iSymbols := iNumInfoSymbols + 4;
        for i := 1 to iNumInfoSymbols do begin
            w_idx := (i - 1) * 3;
            wBarGroup := CopyStr(Barcode, w_idx + 1, 3);
            BarToDec(iCodeWord[i], wBarGroup);
        end;

        j := iNumInfoSymbols;
        for i := 1 to iNumInfoSymbols do begin
            iTempCodeWord[i] := iCodeWord[j];
            j := j - 1;
        end;

        RSEncode(iNumInfoSymbols, iTempCodeWord, ParitySymbols);

        for i := 1 to 4 do
            iCodeWord[i + iNumInfoSymbols] := ParitySymbols[5 - i];

        for i := iNumInfoSymbols to iSymbols - 1 do begin
            wBarGroup := '';
            BarToDec(iCodeWord[i + 1], wBarGroup);
            Barcode := Barcode + wBarGroup;
        end;
        exit(true);
    end;

    local procedure RSInit()
    var
        primpoly: Integer;
        wtest: Integer;
        wprev: Integer;
        wnext: Integer;
        i: Integer;
        j: Integer;
    begin
        primpoly := 67;
        wtest := 64;

        for i := 0 to 63 do begin
            mult[0 + 1, i + 1] := 0;
            mult[1 + 1, i + 1] := i;
        end;

        wprev := 1;
        for i := 1 to 63 do begin
            wnext := wprev * 2;
            if wnext >= wtest then
                wnext := BitXor(wnext, primpoly);
            for j := 0 to 63 do begin
                mult[wnext + 1, j + 1] := mult[wprev + 1, j + 1] * 2;
                if mult[wnext + 1, j + 1] >= wtest then
                    mult[wnext + 1, j + 1] := BitXor(mult[wnext + 1, j + 1], primpoly);
            end;
            wprev := wnext;
        end;

        gen[1] := 48;
        gen[2] := 17;
        gen[3] := 29;
        gen[4] := 30;
        gen[5] := 1;
    end;

    local procedure RSEncode(k: Integer; SymbArray: array[21] of Integer; var RSArray: array[4] of Integer)
    var
        i: Integer;
        n: Integer;
        j: Integer;
        TempArray: array[21] of Integer;
    begin
        RSInit();
        n := k + 4;

        for i := 1 to 4 do
            TempArray[i] := 0;

        for i := 5 to n do
            TempArray[i] := SymbArray[i - 4];

        for i := k - 1 downto 0 do
            for j := 0 to 4 do
                TempArray[1 + i + j] := BitXor(TempArray[1 + i + j], mult[1 + gen[1 + j], 1 + TempArray[1 + 4 + i]]);

        for i := 1 to 4 do
            RSArray[i] := TempArray[i];
    end;

    local procedure BitXor(Num1: Integer; Num2: Integer) ReturnNum: Integer
    var
        Bit: Integer;
        Num1Bit: Integer;
        Num2Bit: Integer;
    begin
        ReturnNum := 0;
        Bit := 1;
        repeat
            if (Num1 <> 0) or (Num2 <> 0) then begin
                Num1Bit := Num1 mod 2;
                Num1 := Round(Num1 / 2, 1, '<');
                Num2Bit := Num2 mod 2;
                Num2 := Round(Num2 / 2, 1, '<');
                if Num1Bit <> Num2Bit then
                    ReturnNum := ReturnNum + Bit;
                Bit := Bit * 2;
            end;
        until (Num1 = 0) and (Num2 = 0);
    end;
}

