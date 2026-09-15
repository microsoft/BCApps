// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 2121 "O365 Brand Color"
{
    Caption = 'O365 Brand Color';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(6; "Color Value"; Code[10])
        {
            Caption = 'Color Value';
        }
        field(15; "Sample Picture"; Media)
        {
            Caption = 'Sample Picture';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Name, "Sample Picture")
        {
        }
    }

    var
        CustomColorCodeTxt: Label 'Custom', Locked = true;
        CustomColorNameTxt: Label 'Custom';
        BlueCodeTok: Label 'BLUE', Comment = 'Blue';
        BlueGrayCodeTok: Label 'BLUE_GRAY', Comment = 'Blue gray';
        DarkBlueCodeTok: Label 'DARK_BLUE', Comment = 'dark blue';
        GreenCodeTok: Label 'GREEN', Comment = 'Green';
        DarkGreenCodeTok: Label 'DARK_GREEN', Comment = 'dark green';
        OrangeCodeTok: Label 'ORANGE', Comment = 'Orange';
        DarkOrangeTok: Label 'DARK_ORANGE', Comment = 'dark orange';
        RedCodeTok: Label 'RED', Comment = 'Red';
        PurpleCodeTok: Label 'PURPLE', Comment = 'Purple';
        DarkPurpleCodeTok: Label 'DARK_PURPLE', Comment = 'dark purple';
        YellowCodeTok: Label 'YELLOW', Comment = 'yellow';
        TealCodeTok: Label 'TEAL', Comment = 'teal';
        BlueTxt: Label 'Blue';
        BlueGrayTxt: Label 'Blue gray';
        DarkBlueTxt: Label 'Dark blue';
        GreenTxt: Label 'Green';
        DarkGreenTxt: Label 'Dark green';
        OrangeTxt: Label 'Orange';
        DarkOrangeTxt: Label 'Dark orange';
        RedTxt: Label 'Red';
        PurpleTxt: Label 'Purple';
        DarkPurpleTxt: Label 'Dark purple';
        YellowTxt: Label 'Yellow';
        TealTxt: Label 'Teal';

    [Scope('OnPrem')]
    procedure CreateOrUpdateCustomColor(var O365BrandColor: Record "O365 Brand Color"; ColorValue: Code[10])
    begin
        if not O365BrandColor.Get(CustomColorCodeTxt) then begin
            O365BrandColor.Init();
            O365BrandColor.Code := CustomColorCodeTxt;
            O365BrandColor.Name := CustomColorNameTxt;
            O365BrandColor.Insert();
        end;

        O365BrandColor."Color Value" := ColorValue;
        O365BrandColor.MakePicture();
        O365BrandColor.Modify();
    end;

    [Scope('OnPrem')]
    procedure FindColor(var O365BrandColor: Record "O365 Brand Color"; ColorValue: Code[10])
    begin
        O365BrandColor.SetRange("Color Value", ColorValue);
        if O365BrandColor.FindFirst() then
            exit;

        if ColorValue = '' then
            if O365BrandColor.Get(BlueCodeTok) then
                exit;

        // ARGB color format has additional alpha channel and has to be converted to RGB
        if StrLen(ColorValue) = 9 then
            ColorValue := ConvertARGBToRGB(ColorValue);

        O365BrandColor.SetRange("Color Value", ColorValue);
        if O365BrandColor.FindFirst() then
            exit;

        CreateOrUpdateCustomColor(O365BrandColor, ColorValue);
    end;

    [Scope('OnPrem')]
    procedure MakePicture()
    var
        TempBlob: Codeunit "Temp Blob";
        Bitmap: DotNet Bitmap;
        Graphics: DotNet Graphics;
        Color: DotNet Color;
        ColorTranslator: DotNet ColorTranslator;
        SolidColorBrush: DotNet SolidBrush;
        ImageFormat: DotNet ImageFormat;
        InStr: InStream;
    begin
        Bitmap := Bitmap.Bitmap(100, 100);
        Graphics := Graphics.FromImage(Bitmap);

        Color := ColorTranslator.FromHtml("Color Value");
        SolidColorBrush := SolidColorBrush.SolidBrush(Color);
        Graphics.FillEllipse(SolidColorBrush, 0, 0, 100, 100);
        Graphics.Dispose();

        TempBlob.CreateInStream(InStr);
        Bitmap.Save(InStr, ImageFormat.Png);

        "Sample Picture".ImportStream(InStr, '');
        Bitmap.Dispose();
    end;

    local procedure BlendColorWithWhite(Value: Integer; Alpha: Integer): Integer
    begin
        exit(Round(Value * Alpha / 255 + (1 - Alpha / 255) * 255, 1));
    end;

    local procedure ConvertARGBToRGB(ARGBValue: Text): Code[10]
    var
        Convert: DotNet Convert;
        R: Integer;
        G: Integer;
        B: Integer;
        A: Integer;
    begin
        A := Convert.ToInt32(CopyStr(ARGBValue, 2, 2), 16);
        R := Convert.ToInt32(CopyStr(ARGBValue, 4, 2), 16);
        G := Convert.ToInt32(CopyStr(ARGBValue, 6, 2), 16);
        B := Convert.ToInt32(CopyStr(ARGBValue, 8, 2), 16);

        exit(
          StrSubstNo(
            '#%1%2%3',
            IntToHex(BlendColorWithWhite(R, A)),
            IntToHex(BlendColorWithWhite(G, A)),
            IntToHex(BlendColorWithWhite(B, A))));
    end;

    local procedure IntToHex(IntValue: Integer) HexValue: Code[10]
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        HexValue := CopyStr(TypeHelper.IntToHex(IntValue), 1, MaxStrLen(HexValue));
        if StrLen(HexValue) = 1 then
            HexValue := '0' + HexValue;
    end;

    [Scope('OnPrem')]
    procedure CreateDefaultBrandColors()
    begin
        CreateBrandColor(RedCodeTok, RedTxt, '#B51725');
        CreateBrandColor(DarkOrangeTok, DarkOrangeTxt, '#DE371C');
        CreateBrandColor(OrangeCodeTok, OrangeTxt, '#FF5709');
        CreateBrandColor(YellowCodeTok, YellowTxt, '#E29D00');
        CreateBrandColor(GreenCodeTok, GreenTxt, '#25892F');
        CreateBrandColor(DarkGreenCodeTok, DarkGreenTxt, '#005C4D');
        CreateBrandColor(TealCodeTok, TealTxt, '#00A199');
        CreateBrandColor(BlueCodeTok, BlueTxt, '#008DD3');
        CreateBrandColor(DarkBlueCodeTok, DarkBlueTxt, '#003A6C');
        CreateBrandColor(BlueGrayCodeTok, BlueGrayTxt, '#536076');
        CreateBrandColor(DarkPurpleCodeTok, DarkPurpleTxt, '#3A327D');
        CreateBrandColor(PurpleCodeTok, PurpleTxt, '#8F65B6');
    end;

    local procedure CreateBrandColor(BrandColorCode: Code[20]; BrandColorName: Text[30]; ColorValue: Code[10])
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if O365BrandColor.Get(Code) then
            exit;
        O365BrandColor.Code := BrandColorCode;
        O365BrandColor.Name := BrandColorName;
        O365BrandColor."Color Value" := ColorValue;
        O365BrandColor.MakePicture();
        O365BrandColor.Insert();
    end;
}

