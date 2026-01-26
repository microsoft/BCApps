codeunit 160801 "Ansi - Ascii Conversion"
{

    trigger OnRun()
    begin
    end;

    var
        AsciiTegn: Text[250];
        AnsiTegn: Text[250];
        Opprettet: Boolean;

    procedure Ansi2Ascii(AnsiTekst: Text[250]): Text[250]
    begin
        if not Opprettet then
            OppretteKonverteringstabell();
        exit(ConvertStr(AnsiTekst, AnsiTegn, AsciiTegn));
    end;

    procedure Ascii2Ansi(AsciiTekst: Text[250]): Text[250]
    begin
        if not Opprettet then
            OppretteKonverteringstabell();
        exit(ConvertStr(AsciiTekst, AsciiTegn, AnsiTegn));
    end;

    local procedure OppretteKonverteringstabell()
    begin
        AsciiTegn[1] := 128;  // Ç
        AnsiTegn[1] := 199;
        AsciiTegn[2] := 129;  // ü
        AnsiTegn[2] := 252;
        AsciiTegn[3] := 130;  // é
        AnsiTegn[3] := 233;
        AsciiTegn[4] := 131;  // â
        AnsiTegn[4] := 226;
        AsciiTegn[5] := 132;  // ä
        AnsiTegn[5] := 228;
        AsciiTegn[6] := 133;  // à
        AnsiTegn[6] := 224;
        AsciiTegn[7] := 134;  // å
        AnsiTegn[7] := 229;
        AsciiTegn[8] := 135;  // ç
        AnsiTegn[8] := 231;
        AsciiTegn[9] := 136;  // ê
        AnsiTegn[9] := 234;
        AsciiTegn[10] := 137; // ë
        AnsiTegn[10] := 235;
        AsciiTegn[11] := 138; // è
        AnsiTegn[11] := 232;
        AsciiTegn[12] := 139; // ï
        AnsiTegn[12] := 239;
        AsciiTegn[13] := 140; // î
        AnsiTegn[13] := 238;
        AsciiTegn[14] := 141; // ì
        AnsiTegn[14] := 236;
        AsciiTegn[15] := 142; // Ä
        AnsiTegn[15] := 196;
        AsciiTegn[16] := 143; // Å
        AnsiTegn[16] := 197;
        AsciiTegn[17] := 144; // É
        AnsiTegn[17] := 201;
        AsciiTegn[18] := 145; // æ
        AnsiTegn[18] := 230;
        AsciiTegn[19] := 146; // Æ
        AnsiTegn[19] := 198;
        AsciiTegn[20] := 147; // ô
        AnsiTegn[20] := 244;
        AsciiTegn[21] := 148; // ö
        AnsiTegn[21] := 246;
        AsciiTegn[22] := 149; // ò
        AnsiTegn[22] := 242;
        AsciiTegn[23] := 150; // û
        AnsiTegn[23] := 251;
        AsciiTegn[24] := 151; // ù
        AnsiTegn[24] := 249;
        AsciiTegn[25] := 152; // ÿ
        AnsiTegn[25] := 255;
        AsciiTegn[26] := 153; // Ö
        AnsiTegn[26] := 214;
        AsciiTegn[27] := 154; // Ü
        AnsiTegn[27] := 220;
        AsciiTegn[28] := 155; // ø
        AnsiTegn[28] := 248;
        AsciiTegn[29] := 156; // £
        AnsiTegn[29] := 163;
        AsciiTegn[30] := 157; // Ø
        AnsiTegn[30] := 216;
        AsciiTegn[31] := 158; // ×
        AnsiTegn[31] := 215;
        AsciiTegn[32] := 159; // krølle f
        AnsiTegn[32] := 131;
        AsciiTegn[33] := 160; // á
        AnsiTegn[33] := 225;
        AsciiTegn[34] := 161; // í
        AnsiTegn[34] := 237;
        AsciiTegn[35] := 162; // ó
        AnsiTegn[35] := 243;
        AsciiTegn[36] := 163; // ú
        AnsiTegn[36] := 250;
        AsciiTegn[37] := 164; // ñ
        AnsiTegn[37] := 241;
        AsciiTegn[38] := 165; // Ñ
        AnsiTegn[38] := 209;
        AsciiTegn[39] := 166; // ª
        AnsiTegn[39] := 170;
        AsciiTegn[40] := 167; // º
        AnsiTegn[40] := 186;
        AsciiTegn[41] := 168; // ¿
        AnsiTegn[41] := 191;
        AsciiTegn[42] := 169; // ®
        AnsiTegn[42] := 174;
        AsciiTegn[43] := 170; // ¬
        AnsiTegn[43] := 172;
        AsciiTegn[44] := 171; // ½
        AnsiTegn[44] := 189;
        AsciiTegn[45] := 172; // ¼
        AnsiTegn[45] := 188;
        AsciiTegn[46] := 173; // ¡
        AnsiTegn[46] := 161;
        AsciiTegn[47] := 174; // «
        AnsiTegn[47] := 171;
        AsciiTegn[48] := 175; // »
        AnsiTegn[48] := 187;
        AsciiTegn[49] := 176; // Euro tegn
        AnsiTegn[49] := 128;
        AsciiTegn[50] := 181; // Á
        AnsiTegn[50] := 193;
        AsciiTegn[51] := 182; // Â
        AnsiTegn[51] := 194;
        AsciiTegn[52] := 183; // À
        AnsiTegn[52] := 192;
        AsciiTegn[53] := 184; // ©
        AnsiTegn[53] := 169;
        AsciiTegn[54] := 189; // ¢
        AnsiTegn[54] := 162;
        AsciiTegn[55] := 190; // ¥
        AnsiTegn[55] := 165;
        AsciiTegn[56] := 198; // ã
        AnsiTegn[56] := 227;
        AsciiTegn[57] := 199; // Ã
        AnsiTegn[57] := 195;
        AsciiTegn[58] := 207; // ¤
        AnsiTegn[58] := 164;
        AsciiTegn[59] := 208; // ð
        AnsiTegn[59] := 240;
        AsciiTegn[60] := 209; // Ð
        AnsiTegn[60] := 208;
        AsciiTegn[61] := 210; // Ê
        AnsiTegn[61] := 202;
        AsciiTegn[62] := 211; // Ë
        AnsiTegn[62] := 203;
        AsciiTegn[63] := 212; // È
        AnsiTegn[63] := 200;
        AsciiTegn[64] := 214; // Í
        AnsiTegn[64] := 205;
        AsciiTegn[65] := 215; // Î
        AnsiTegn[65] := 206;
        AsciiTegn[66] := 216; // Ï
        AnsiTegn[66] := 207;
        AsciiTegn[67] := 221; // ¦
        AnsiTegn[67] := 166;
        AsciiTegn[68] := 222; // Ì
        AnsiTegn[68] := 204;
        AsciiTegn[69] := 224; // Ó
        AnsiTegn[69] := 211;
        AsciiTegn[70] := 225; // ß
        AnsiTegn[70] := 223;
        AsciiTegn[71] := 226; // Ô
        AnsiTegn[71] := 212;
        AsciiTegn[72] := 227; // Ò
        AnsiTegn[72] := 210;
        AsciiTegn[73] := 228; // õ
        AnsiTegn[73] := 245;
        AsciiTegn[74] := 229; // Õ
        AnsiTegn[74] := 213;
        AsciiTegn[75] := 230; // µ
        AnsiTegn[75] := 181;
        AsciiTegn[76] := 231; // þ
        AnsiTegn[76] := 254;
        AsciiTegn[77] := 232; // Þ
        AnsiTegn[77] := 222;
        AsciiTegn[78] := 233; // Ú
        AnsiTegn[78] := 218;
        AsciiTegn[79] := 234; // Û
        AnsiTegn[79] := 219;
        AsciiTegn[80] := 235; // Ù
        AnsiTegn[80] := 217;
        AsciiTegn[81] := 236; // ý
        AnsiTegn[81] := 253;
        AsciiTegn[82] := 237; // Ý
        AnsiTegn[82] := 221;
        AsciiTegn[83] := 238; // ¯
        AnsiTegn[83] := 175;
        AsciiTegn[84] := 239; // ´
        AnsiTegn[84] := 180;
        AsciiTegn[85] := 240; // ­
        AnsiTegn[85] := 173;
        AsciiTegn[86] := 241; // ±
        AnsiTegn[86] := 177;
        AsciiTegn[87] := 243; // ¾
        AnsiTegn[87] := 190;
        AsciiTegn[88] := 244; // ¶
        AnsiTegn[88] := 182;
        AsciiTegn[89] := 245; // §
        AnsiTegn[89] := 167;
        AsciiTegn[90] := 246; // ÷
        AnsiTegn[90] := 247;
        AsciiTegn[91] := 247; // ¸
        AnsiTegn[91] := 184;
        AsciiTegn[92] := 248; // °
        AnsiTegn[92] := 176;
        AsciiTegn[93] := 249; // ¨
        AnsiTegn[93] := 168;
        AsciiTegn[94] := 250; // ·
        AnsiTegn[94] := 183;
        AsciiTegn[95] := 251; // ¹
        AnsiTegn[95] := 185;
        AsciiTegn[96] := 252; // ³
        AnsiTegn[96] := 179;
        AsciiTegn[97] := 253; // ²
        AnsiTegn[97] := 178;
        AsciiTegn[98] := 255; // hårdt space
        AnsiTegn[98] := 160;
        Opprettet := true;
    end;
}

