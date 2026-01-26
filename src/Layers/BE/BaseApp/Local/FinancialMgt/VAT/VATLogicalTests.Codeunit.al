// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

codeunit 11300 VATLogicalTests
{

    trigger OnRun()
    begin
    end;

    var
        Text11300: Label '1. Row [01] and/or Row [02] and/or Row [03] \';
        Text11301: Label '    => Row [54]';
        Text11302: Label '2. Row [54] => Row [01] and/or Row [02] and/or \';
        Text11303: Label '    Row [03]';
        Text11304: Label '3. Row [86] and/or Row [88] => Row [55]';
        Text11305: Label '4. Row [87] => Row [56] and/or Row [57]';
        Text11306: Label '5. There is an amount in Row [65] \';
        Text11307: Label '    and/or Row [66]';
        Text11308: Label '6. There is a wrong amount in Row [91]';
        Text11309: Label '7. Row [01] x 6% + Row [02] x 12% + \';
        Text11310: Label '    Row [03] x 21% = Row [54]';
        Text11311: Label '8. Row [55] =< (Row [84] + Row [86] + Row [88]) * 21%';
        Text11312: Label '9. (Row [56] + Row [57]) =< \';
        Text11313: Label '    (Row [85] + Row [87]) * 21%';
        Text11314: Label '10. Row [59] =< (Row [81] + Row [82] + \';
        Text11315: Label '     Row [83] + Row [84] + Row [85]) * 50%';
        Text11316: Label '11. Row [63] =< Row [85] * 21%';
        Text11317: Label '12. Row [64] =< Row [49] * 21%';
        Text11318: Label 'Error';
        Text11319: Label 'OK';
        Text11320: Label '13. There is/are row(s) with negative amounts';

    procedure CheckNo(No: Text[20]): Boolean
    var
        Vatno: Text[20];
        WorkVatNo: Decimal;
        Ctrl: Decimal;
    begin
        Vatno := DelChr(No, '=', DelChr(No, '=', '0123456789'));
        if StrLen(Vatno) <> 9 then
            exit(false);
        Evaluate(WorkVatNo, CopyStr(Vatno, 1, 7));
        Evaluate(Ctrl, CopyStr(Vatno, 8, 2));
        WorkVatNo := 97 - (WorkVatNo mod 97);
        exit(WorkVatNo = Ctrl);
    end;

    procedure CheckForErrors(NoOfPeriods: Integer; Row: array[99, 12] of Decimal; Errormargin: Decimal; December: Integer; var Control: array[14] of Text[250]; var CheckList: array[14, 12] of Text[30])
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to NoOfPeriods do begin
            Control[1] := Text11300 + Text11301; // "Code A"
            Test(1,
              ((Row[1, i] <> 0) or (Row[2, i] <> 0) or (Row[3, i] <> 0)) and
              (Row[54, i] = 0), i, CheckList);

            Control[2] := Text11302 + Text11303; // "Code B"
            Test(2,
              (Row[54, i] <> 0) and
              (Row[1, i] = 0) and (Row[2, i] = 0) and (Row[3, i] = 0), i, CheckList);

            Control[3] := Text11304; // "Code C"
            Test(3, ((Row[86, i] <> 0) or (Row[88, i] <> 0)) and (Row[55, i] = 0), i, CheckList);

            Control[4] := Text11305; // "Code D"
            Test(4, (Row[87, i] <> 0) and (Row[56, i] = 0) and (Row[57, i] = 0), i, CheckList);

            Control[5] := Text11306 + Text11307;
            Test(5, (Row[65, i] <> 0) or (Row[66, i] <> 0), i, CheckList);

            Control[6] := Text11308; // "Code 5"
            Test(6, (Row[91, i] <> 0) and (December <> 12), i, CheckList);

            Control[7] := Text11309 + Text11310; // "Code O"
            Test(7,
              Abs(Row[1, i] * 0.06 + Row[2, i] * 0.12 + Row[3, i] * 0.21 - Row[54, i]) >
              Errormargin, i, CheckList);

            Control[8] := Text11311; // "Code P"
            Test(8, Row[55, i] > ((Row[84, i] + Row[86, i] + Row[88, i]) * 0.21 + Errormargin), i, CheckList);

            Control[9] := Text11312 + Text11313; // "Code Q"
            Test(9, (Row[56, i] + Row[57, i]) > ((Row[85, i] + Row[87, i]) * 0.21 + Errormargin), i, CheckList);

            Control[10] := Text11314 + Text11315; // "Code S"
            Test(10, Row[59, i] > (Row[81, i] + Row[82, i] + Row[83, i] + Row[84, i] + Row[85, i]) * 0.5, i, CheckList);

            Control[11] := Text11316; // "Code T"
            Test(11, Row[63, i] > Row[85, i] * 0.21 + Errormargin, i, CheckList);

            Control[12] := Text11317; // "Code U"
            Test(12, Row[64, i] > Row[49, i] * 0.21 + Errormargin, i, CheckList);

            // check for negative amounts on one of the rows
            Control[13] := Text11320;
            Test(13, false, i, CheckList);  // initial value is OK
            for j := 1 to 99 do
                if Row[j, i] < 0 then
                    Test(13, true, i, CheckList);
        end;
    end;

    procedure CheckEnterpriseNoFormat(EnterpriseNo: Text[50]): Boolean
    begin
        EnterpriseNo := UpperCase(DelChr(EnterpriseNo, '=', '0123456789,?;.:/-_ '));
        if (StrPos(EnterpriseNo, 'BTW') = 0) and (StrPos(EnterpriseNo, 'TVA') = 0) then
            exit(false);
        exit(true);
    end;

    procedure Test(TestNo: Integer; LogicalTest: Boolean; Period: Integer; var MyCheckList: array[14, 12] of Text[30])
    begin
        if LogicalTest then
            MyCheckList[TestNo, Period] := Text11318
        else
            MyCheckList[TestNo, Period] := Text11319;
    end;

    procedure MOD97Check(Number: Text[50]): Boolean
    var
        No: Text[20];
        WorkNo: Decimal;
        Ctrl: Decimal;
    begin
        No := DelChr(Number, '=', DelChr(Number, '=', '0123456789'));
        if StrLen(No) <> 10 then
            exit(false);
        Evaluate(WorkNo, CopyStr(No, 1, 8));
        Evaluate(Ctrl, CopyStr(No, 9, 2));
        WorkNo := 97 - (WorkNo mod 97);
        exit(WorkNo = Ctrl);
    end;
}

