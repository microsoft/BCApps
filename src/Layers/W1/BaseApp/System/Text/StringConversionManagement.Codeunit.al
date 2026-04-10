namespace System.Text;

using System.Utilities;

codeunit 47 StringConversionManagement
{

    trigger OnRun()
    begin
    end;

    procedure WindowsToASCII(InText: Text): Text
    var
        OutText: Text;
        i: Integer;
        Len: Integer;
    begin
        OutText := InText;
        Len := StrLen(InText);
        for i := 1 to Len do
            OutText[i] := WindowsToASCIIChar(InText[i]);
        exit(OutText);
    end;

    local procedure WindowsToASCIIChar(c: Integer): Char
    begin
        // EPC217-08 conversion rules
        case c of
            1 .. 127:
                exit(WindowsToASCIICharEPC(c));
            128 .. 255:
                exit(WindowsToASCIIChar8Bit(c));
            8364: // Euro sign
                exit('E');
            else
                exit(WindowsToASCIIChar16Bit(c));
        end;
    end;

    local procedure WindowsToASCIIChar8Bit(c: Integer): Char
    begin
        case c of
            191:
                exit('?');
            192 .. 198:
                exit('A');
            199:
                exit('C');
            200 .. 203:
                exit('E');
            204 .. 207:
                exit('I');
            208:
                exit('D');
            209:
                exit('N');
            210 .. 214, 216:
                exit('O');
            217 .. 220:
                exit('U');
            221:
                exit('Y');
            222:
                exit('T');
            223:
                exit('s');
            224 .. 230:
                exit('a');
            231:
                exit('c');
            232 .. 235:
                exit('e');
            236 .. 239:
                exit('i');
            240:
                exit('d');
            241:
                exit('n');
            242 .. 246, 248:
                exit('o');
            249 .. 252:
                exit('u');
            253, 255:
                exit('y');
            254:
                exit('t');
        end;
        exit('.');
    end;

    local procedure WindowsToASCIIChar16Bit(c: Integer): Char
    begin
        case c of
            256, 258, 260, 902, 913, 1040, 1066:
                exit('A');
            257, 259, 261, 940, 945, 1072, 1098:
                exit('a');
            1041:
                exit('B');
            1073:
                exit('b');
            262, 264, 266, 268, 935, 1063:
                exit('C');
            263, 265, 267, 269, 967, 1095:
                exit('c');
            270, 272, 916, 1044:
                exit('D');
            271, 273, 948, 1076:
                exit('d');
            274, 276, 278, 280, 282, 904, 917, 1045:
                exit('E');
            275, 277, 279, 281, 283, 941, 949, 1077:
                exit('e');
            934, 1060:
                exit('F');
            966, 1092:
                exit('f');
            284, 286, 288, 290, 915, 1043:
                exit('G');
            285, 287, 289, 291, 947, 1075:
                exit('g');
            292, 294, 1061:
                exit('H');
            293, 295, 1093:
                exit('h');
            296, 298, 300, 302, 304, 306, 905, 906, 919, 921, 938, 1048:
                exit('I');
            297, 299, 301, 303, 305, 307, 912, 942, 943, 951, 953, 970, 1080:
                exit('i');
            308:
                exit('J');
            309:
                exit('j');
            310, 922, 1050:
                exit('K');
            311, 954, 1082:
                exit('k');
            313, 315, 317, 319, 321, 923, 1051:
                exit('L');
            314, 316, 318, 320, 322, 955, 1083:
                exit('l');
            924, 1052:
                exit('M');
            956, 1084:
                exit('m');
            323, 325, 327, 925, 1053:
                exit('N');
            324, 326, 328, 957, 1085:
                exit('n');
            336, 338, 908, 911, 927, 937, 1054:
                exit('O');
            337, 339, 959, 969, 972, 974, 1086:
                exit('o');
            928, 936, 1055:
                exit('P');
            960, 968, 1087:
                exit('p');
            340, 342, 344, 929, 1056:
                exit('R');
            341, 343, 345, 961, 1088:
                exit('r');
            346, 348, 350, 352, 536, 931, 1057, 1064, 1065:
                exit('S');
            347, 349, 351, 353, 537, 962, 963, 1089, 1096, 1097:
                exit('s');
            354, 356, 358, 538, 920, 932, 1058, 1062:
                exit('T');
            355, 357, 359, 539, 952, 964, 1090, 1094:
                exit('t');
            360, 362, 364, 366, 368, 370, 1059:
                exit('U');
            361, 363, 365, 367, 369, 371, 1091:
                exit('u');
            914, 1042:
                exit('V');
            946, 1074:
                exit('v');
            372:
                exit('W');
            373:
                exit('w');
            926:
                exit('X');
            958:
                exit('x');
            374, 376, 910, 933, 939, 1049, 1068, 1070, 1071:
                exit('Y');
            375, 944, 965, 971, 973, 1081, 1100, 1102, 1103:
                exit('y');
            377, 379, 381, 918, 1046, 1047:
                exit('Z');
            378, 380, 382, 950, 1078, 1079:
                exit('z');
        end;
        exit('.');
    end;

    local procedure WindowsToASCIICharEPC(c: Integer): Char
    begin
        case c of
            33, 35 .. 37, 42, 61, 64, 94, 127: // !,#,$,%,&,*,=,@,delete
                exit('.');
            34, 39, 60, 62, 96: // ",',<,>,`
                exit(' ');
            38: // AMPERSAND
                exit('+');
            59: // ;
                exit(',');
            91, 123: // [,{
                exit('(');
            92, 124: // \,|
                exit('/');
            93, 125: // ],}
                exit(')');
            95, 126: // _,~
                exit('-');
        end;
        exit(c);
    end;

    procedure GetPaddedString(StringToModify: Text[250]; PadLength: Integer; PadCharacter: Text[1]; Justification: Option Right,Left): Text[250]
    begin
        if PadLength < StrLen(StringToModify) then
            exit(StringToModify);
        if Justification = Justification::Right then
            exit(PadStr('', PadLength - StrLen(StringToModify), PadCharacter) + StringToModify);
        if Justification = Justification::Left then
            exit(StringToModify + PadStr('', PadLength - StrLen(StringToModify), PadCharacter));
    end;

    procedure RemoveDecimalFromString(StringToModify: Text[250]; PadLength: Integer; PadCharacter: Text[1]; Justification: Option Right,Left) FinalString: Text[250]
    var
        TempDecimal: Decimal;
        StringToRemove: Text;
    begin
        if PadLength < StrLen(StringToModify) - 1 then
            exit(StringToModify);
        if not Evaluate(TempDecimal, StringToModify) then
            exit(StringToModify);
        StringToRemove := DelChr(StringToModify, '=', '0123456789');
        FinalString := GetPaddedString(DelChr(StringToModify, '=', StringToRemove), PadLength, PadCharacter, Justification);
        exit(FinalString);
    end;

    procedure RemoveNonAlphaNumericCharacters(InputString: Text): Text
    var
        Regex: Codeunit Regex;
        OutputString: Text;
    begin
        OutputString := Regex.Replace(InputString, '\W|_', '');
        exit(OutputString);
    end;
}

