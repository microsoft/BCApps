namespace System.IO;

using Microsoft.Finance.Dimension;
using System.Utilities;

page 8626 "Config. Package Records"
{
    Caption = 'Config. Package Records';
    DataCaptionExpression = FormCaption;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Config. Package Record";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Invalid; Rec.Invalid)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether a configuration record has an error that prevents it from being imported into the table. You can see the error information in the Config. Package Errors window.';
                }
                field(Field1; MatrixCellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    Visible = Field1Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(1);
                    end;
                }
                field(Field2; MatrixCellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    Visible = Field2Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(2);
                    end;
                }
                field(Field3; MatrixCellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    Visible = Field3Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(3);
                    end;
                }
                field(Field4; MatrixCellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    Visible = Field4Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(4);
                    end;
                }
                field(Field5; MatrixCellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    Visible = Field5Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(5);
                    end;
                }
                field(Field6; MatrixCellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    Visible = Field6Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(6);
                    end;
                }
                field(Field7; MatrixCellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    Visible = Field7Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(7);
                    end;
                }
                field(Field8; MatrixCellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    Visible = Field8Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(8);
                    end;
                }
                field(Field9; MatrixCellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    Visible = Field9Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(9);
                    end;
                }
                field(Field10; MatrixCellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    Visible = Field10Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(10);
                    end;
                }
                field(Field11; MatrixCellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    Visible = Field11Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(11);
                    end;
                }
                field(Field12; MatrixCellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    Visible = Field12Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(12);
                    end;
                }
                field(Field13; MatrixCellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    Visible = Field13Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(13);
                    end;
                }
                field(Field14; MatrixCellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    Visible = Field14Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(14);
                    end;
                }
                field(Field15; MatrixCellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    Visible = Field15Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(15);
                    end;
                }
                field(Field16; MatrixCellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    Visible = Field16Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(16);
                    end;
                }
                field(Field17; MatrixCellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    Visible = Field17Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(17);
                    end;
                }
                field(Field18; MatrixCellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    Visible = Field18Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(18);
                    end;
                }
                field(Field19; MatrixCellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    Visible = Field19Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(19);
                    end;
                }
                field(Field20; MatrixCellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    Visible = Field20Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(20);
                    end;
                }
                field(Field21; MatrixCellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    Visible = Field21Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(21);
                    end;
                }
                field(Field22; MatrixCellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    Visible = Field22Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(22);
                    end;
                }
                field(Field23; MatrixCellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    Visible = Field23Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(23);
                    end;
                }
                field(Field24; MatrixCellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    Visible = Field24Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(24);
                    end;
                }
                field(Field25; MatrixCellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    Visible = Field25Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(25);
                    end;
                }
                field(Field26; MatrixCellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    Visible = Field26Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(26);
                    end;
                }
                field(Field27; MatrixCellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    Visible = Field27Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(27);
                    end;
                }
                field(Field28; MatrixCellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    Visible = Field28Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(28);
                    end;
                }
                field(Field29; MatrixCellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    Visible = Field29Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(29);
                    end;
                }
                field(Field30; MatrixCellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    Visible = Field30Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(30);
                    end;
                }
                field(Field31; MatrixCellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    Visible = Field31Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(31);
                    end;
                }
                field(Field32; MatrixCellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    Visible = Field32Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(32);
                    end;
                }
                field(Field33; MatrixCellData[33])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[33];
                    Visible = Field33Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(33);
                    end;
                }
                field(Field34; MatrixCellData[34])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[34];
                    Visible = Field34Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(34);
                    end;
                }
                field(Field35; MatrixCellData[35])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[35];
                    Visible = Field35Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(35);
                    end;
                }
                field(Field36; MatrixCellData[36])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[36];
                    Visible = Field36Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(36);
                    end;
                }
                field(Field37; MatrixCellData[37])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[37];
                    Visible = Field37Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(37);
                    end;
                }
                field(Field38; MatrixCellData[38])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[38];
                    Visible = Field38Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(38);
                    end;
                }
                field(Field39; MatrixCellData[39])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[39];
                    Visible = Field39Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(39);
                    end;
                }
                field(Field40; MatrixCellData[40])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[40];
                    Visible = Field40Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(40);
                    end;
                }
                field(Field41; MatrixCellData[41])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[41];
                    Visible = Field41Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(41);
                    end;
                }
                field(Field42; MatrixCellData[42])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[42];
                    Visible = Field42Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(42);
                    end;
                }
                field(Field43; MatrixCellData[43])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[43];
                    Visible = Field43Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(43);
                    end;
                }
                field(Field44; MatrixCellData[44])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[44];
                    Visible = Field44Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(44);
                    end;
                }
                field(Field45; MatrixCellData[45])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[45];
                    Visible = Field45Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(45);
                    end;
                }
                field(Field46; MatrixCellData[46])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[46];
                    Visible = Field46Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(46);
                    end;
                }
                field(Field47; MatrixCellData[47])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[47];
                    Visible = Field47Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(47);
                    end;
                }
                field(Field48; MatrixCellData[48])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[48];
                    Visible = Field48Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(48);
                    end;
                }
                field(Field49; MatrixCellData[49])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[49];
                    Visible = Field49Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(49);
                    end;
                }
                field(Field50; MatrixCellData[50])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[50];
                    Visible = Field50Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(50);
                    end;
                }
                field(Field51; MatrixCellData[51])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[51];
                    Visible = Field51Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(51);
                    end;
                }
                field(Field52; MatrixCellData[52])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[52];
                    Visible = Field52Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(52);
                    end;
                }
                field(Field53; MatrixCellData[53])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[53];
                    Visible = Field53Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(53);
                    end;
                }
                field(Field54; MatrixCellData[54])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[54];
                    Visible = Field54Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(54);
                    end;
                }
                field(Field55; MatrixCellData[55])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[55];
                    Visible = Field55Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(55);
                    end;
                }
                field(Field56; MatrixCellData[56])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[56];
                    Visible = Field56Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(56);
                    end;
                }
                field(Field57; MatrixCellData[57])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[57];
                    Visible = Field57Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(57);
                    end;
                }
                field(Field58; MatrixCellData[58])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[58];
                    Visible = Field58Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(58);
                    end;
                }
                field(Field59; MatrixCellData[59])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[59];
                    Visible = Field59Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(59);
                    end;
                }
                field(Field60; MatrixCellData[60])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[60];
                    Visible = Field60Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(60);
                    end;
                }
                field(Field61; MatrixCellData[61])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[61];
                    Visible = Field61Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(61);
                    end;
                }
                field(Field62; MatrixCellData[62])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[62];
                    Visible = Field62Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(62);
                    end;
                }
                field(Field63; MatrixCellData[63])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[63];
                    Visible = Field63Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(63);
                    end;
                }
                field(Field64; MatrixCellData[64])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[64];
                    Visible = Field64Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(64);
                    end;
                }
                field(Field65; MatrixCellData[65])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[65];
                    Visible = Field65Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(65);
                    end;
                }
                field(Field66; MatrixCellData[66])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[66];
                    Visible = Field66Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(66);
                    end;
                }
                field(Field67; MatrixCellData[67])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[67];
                    Visible = Field67Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(67);
                    end;
                }
                field(Field68; MatrixCellData[68])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[68];
                    Visible = Field68Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(68);
                    end;
                }
                field(Field69; MatrixCellData[69])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[69];
                    Visible = Field69Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(69);
                    end;
                }
                field(Field70; MatrixCellData[70])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[70];
                    Visible = Field70Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(70);
                    end;
                }
                field(Field71; MatrixCellData[71])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[71];
                    Visible = Field71Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(71);
                    end;
                }
                field(Field72; MatrixCellData[72])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[72];
                    Visible = Field72Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(72);
                    end;
                }
                field(Field73; MatrixCellData[73])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[73];
                    Visible = Field73Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(73);
                    end;
                }
                field(Field74; MatrixCellData[74])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[74];
                    Visible = Field74Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(74);
                    end;
                }
                field(Field75; MatrixCellData[75])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[75];
                    Visible = Field75Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(75);
                    end;
                }
                field(Field76; MatrixCellData[76])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[76];
                    Visible = Field76Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(76);
                    end;
                }
                field(Field77; MatrixCellData[77])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[77];
                    Visible = Field77Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(77);
                    end;
                }
                field(Field78; MatrixCellData[78])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[78];
                    Visible = Field78Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(78);
                    end;
                }
                field(Field79; MatrixCellData[79])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[79];
                    Visible = Field79Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(79);
                    end;
                }
                field(Field80; MatrixCellData[80])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[80];
                    Visible = Field80Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(80);
                    end;
                }
                field(Field81; MatrixCellData[81])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[81];
                    Visible = Field81Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(81);
                    end;
                }
                field(Field82; MatrixCellData[82])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[82];
                    Visible = Field82Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(82);
                    end;
                }
                field(Field83; MatrixCellData[83])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[83];
                    Visible = Field83Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(83);
                    end;
                }
                field(Field84; MatrixCellData[84])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[84];
                    Visible = Field84Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(84);
                    end;
                }
                field(Field85; MatrixCellData[85])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[85];
                    Visible = Field85Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(85);
                    end;
                }
                field(Field86; MatrixCellData[86])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[86];
                    Visible = Field86Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(86);
                    end;
                }
                field(Field87; MatrixCellData[87])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[87];
                    Visible = Field87Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(87);
                    end;
                }
                field(Field88; MatrixCellData[88])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[88];
                    Visible = Field88Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(88);
                    end;
                }
                field(Field89; MatrixCellData[89])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[89];
                    Visible = Field89Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(89);
                    end;
                }
                field(Field90; MatrixCellData[90])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[90];
                    Visible = Field90Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(90);
                    end;
                }
                field(Field91; MatrixCellData[91])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[91];
                    Visible = Field91Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(91);
                    end;
                }
                field(Field92; MatrixCellData[92])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[92];
                    Visible = Field92Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(92);
                    end;
                }
                field(Field93; MatrixCellData[93])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[93];
                    Visible = Field93Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(93);
                    end;
                }
                field(Field94; MatrixCellData[94])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[94];
                    Visible = Field94Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(94);
                    end;
                }
                field(Field95; MatrixCellData[95])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[95];
                    Visible = Field95Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(95);
                    end;
                }
                field(Field96; MatrixCellData[96])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[96];
                    Visible = Field96Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(96);
                    end;
                }
                field(Field97; MatrixCellData[97])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[97];
                    Visible = Field97Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(97);
                    end;
                }
                field(Field98; MatrixCellData[98])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[98];
                    Visible = Field98Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(98);
                    end;
                }
                field(Field99; MatrixCellData[99])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[99];
                    Visible = Field99Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(99);
                    end;
                }
                field(Field100; MatrixCellData[100])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[100];
                    Visible = Field100Visible;

                    trigger OnValidate()
                    begin
                        ValidatePackageData(100);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                Image = Setup;
                action("Show Error")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Error';
                    Image = Error;
                    ShortCutKey = 'F7';
                    ToolTip = 'Show the error message that has stopped the entry.';

                    trigger OnAction()
                    var
                        ConfigPackageError: Record "Config. Package Error";
                    begin
                        if Rec.Invalid then begin
                            ConfigPackageError.SetRange("Package Code", Rec."Package Code");
                            ConfigPackageError.SetRange("Table ID", Rec."Table ID");
                            ConfigPackageError.SetRange("Record No.", Rec."No.");
                            PAGE.RunModal(PAGE::"Config. Package Errors", ConfigPackageError);
                        end else
                            Message(NoMigrationErrorsMsg);
                    end;
                }
                action(ProcessData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Process Data';
                    Image = DataEntry;
                    ToolTip = 'Process data in the configuration package before you apply it to the database. For example, convert dates and decimals to the format required by the regional settings on a user''s computer and remove leading/trailing spaces or special characters.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                    begin
                        ConfigPackageTable.Get(Rec."Package Code", Rec."Table ID");
                        ConfigPackageTable.SetRange("Package Code", Rec."Package Code");
                        ConfigPackageTable.SetRange("Table ID", Rec."Table ID");

                        if ConfigPackageTable."Processing Report ID" > 0 then
                            REPORT.RunModal(ConfigPackageTable."Processing Report ID", false, false, ConfigPackageTable)
                        else
                            REPORT.RunModal(REPORT::"Config. Package - Process", false, false, ConfigPackageTable);
                        CurrPage.Update();
                    end;
                }
                action(ApplyData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Data';
                    Image = Apply;
                    ToolTip = 'Apply the data in the package to the database. After you apply data, you can only see it in the database.';

                    trigger OnAction()
                    var
                        ConfigPackageRecord: Record "Config. Package Record";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageRecord);
                        CleanSelectionErrors(ConfigPackageRecord);
                        Commit();

                        ConfigPackageMgt.ApplySelectedPackageRecords(ConfigPackageRecord, PackageCode, TableNo);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Show Error_Promoted"; "Show Error")
                {
                }
                actionref(ApplyData_Promoted; ApplyData)
                {
                }
                actionref(ProcessData_Promoted; ProcessData)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        InStream: InStream;
    begin
        MatrixColumnOrdinal := 0;
        Clear(MatrixCellData);
        if FindPackageFields(ConfigPackageField) then
            repeat
                MatrixColumnOrdinal := MatrixColumnOrdinal + 1;
                if ConfigPackageData.Get(Rec."Package Code", Rec."Table ID", Rec."No.", ConfigPackageField."Field ID") then begin
                    if ConfigPackageManagement.IsBLOBField(ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
                        ConfigPackageData.CalcFields("BLOB Value");
                        ConfigPackageData."BLOB Value".CreateInStream(InStream, TextEncoding::UTF8);
                        InStream.Read(MatrixCellData[MatrixColumnOrdinal]);
                    end else
                        MatrixCellData[MatrixColumnOrdinal] := ConfigPackageData.Value;
                    PackageColumnField[MatrixColumnOrdinal] := ConfigPackageData."Field ID";
                    MatrixDimension[MatrixColumnOrdinal] := ConfigPackageField.Dimension;
                end;
            until ConfigPackageField.Next() = 0;
    end;

    trigger OnClosePage()
    begin
        ClearAll();
    end;

    trigger OnInit()
    begin
        SetFieldsVisibility(100);
    end;

    trigger OnOpenPage()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        FindPackageFields(ConfigPackageField);
        SetFieldsVisibility(ConfigPackageField.Count);
    end;

    var
        ConfigPackageData: Record "Config. Package Data";
        MatrixCellData: array[1000] of Text;
        MatrixColumnCaptions: array[1000] of Text[100];
        MatrixDimension: array[1000] of Boolean;
        FormCaption: Text[1024];
        PackageCode: Code[20];
        PackageColumnField: array[1000] of Integer;
        MatrixColumnOrdinal: Integer;
        TableNo: Integer;
#pragma warning disable AA0470
        ValueNotExistErr: Label '%1 value ''%2'' does not exist.';
#pragma warning restore AA0470
        NoMigrationErrorsMsg: Label 'There are no data migration errors in this record.';
        ValueIsTooLongErr: Label 'Max length of %1 with value ''%2'' is %3.', Comment = '%1 - Table caption, %2 - Value, %3 - Max length';
        ErrorFieldNo: Integer;
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;
        Field33Visible: Boolean;
        Field34Visible: Boolean;
        Field35Visible: Boolean;
        Field36Visible: Boolean;
        Field37Visible: Boolean;
        Field38Visible: Boolean;
        Field39Visible: Boolean;
        Field40Visible: Boolean;
        Field41Visible: Boolean;
        Field42Visible: Boolean;
        Field43Visible: Boolean;
        Field44Visible: Boolean;
        Field45Visible: Boolean;
        Field46Visible: Boolean;
        Field47Visible: Boolean;
        Field48Visible: Boolean;
        Field49Visible: Boolean;
        Field50Visible: Boolean;
        Field51Visible: Boolean;
        Field52Visible: Boolean;
        Field53Visible: Boolean;
        Field54Visible: Boolean;
        Field55Visible: Boolean;
        Field56Visible: Boolean;
        Field57Visible: Boolean;
        Field58Visible: Boolean;
        Field59Visible: Boolean;
        Field60Visible: Boolean;
        Field61Visible: Boolean;
        Field62Visible: Boolean;
        Field63Visible: Boolean;
        Field64Visible: Boolean;
        Field65Visible: Boolean;
        Field66Visible: Boolean;
        Field67Visible: Boolean;
        Field68Visible: Boolean;
        Field69Visible: Boolean;
        Field70Visible: Boolean;
        Field71Visible: Boolean;
        Field72Visible: Boolean;
        Field73Visible: Boolean;
        Field74Visible: Boolean;
        Field75Visible: Boolean;
        Field76Visible: Boolean;
        Field77Visible: Boolean;
        Field78Visible: Boolean;
        Field79Visible: Boolean;
        Field80Visible: Boolean;
        Field81Visible: Boolean;
        Field82Visible: Boolean;
        Field83Visible: Boolean;
        Field84Visible: Boolean;
        Field85Visible: Boolean;
        Field86Visible: Boolean;
        Field87Visible: Boolean;
        Field88Visible: Boolean;
        Field89Visible: Boolean;
        Field90Visible: Boolean;
        Field91Visible: Boolean;
        Field92Visible: Boolean;
        Field93Visible: Boolean;
        Field94Visible: Boolean;
        Field95Visible: Boolean;
        Field96Visible: Boolean;
        Field97Visible: Boolean;
        Field98Visible: Boolean;
        Field99Visible: Boolean;
        Field100Visible: Boolean;
        ShowDim: Boolean;

    procedure Load(NewMatrixColumnCaptions: array[1000] of Text[100]; FormCaptionIn: Text[1024]; PackageCode1: Code[20]; TableNo1: Integer; ShowDim1: Boolean)
    begin
        CopyArray(MatrixColumnCaptions, NewMatrixColumnCaptions, 1);
        FormCaption := FormCaptionIn;
        PackageCode := PackageCode1;
        TableNo := TableNo1;
        ShowDim := ShowDim1;
    end;

    local procedure FindPackageFields(var ConfigPackageField: Record "Config. Package Field") Result: Boolean
    begin
        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Table ID", TableNo);
        if ErrorFieldNo = 0 then
            ConfigPackageField.SetRange("Include Field", true)
        else begin
            ConfigPackageField.FilterGroup(-1);
            ConfigPackageField.SetRange("Primary Key", true);
            ConfigPackageField.SetRange("Field ID", ErrorFieldNo);
            ConfigPackageField.FilterGroup(0);
        end;
        if not ShowDim then
            ConfigPackageField.SetRange(Dimension, false);
        Result := ConfigPackageField.FindSet();
        OnAfterFindPackageFields(ConfigPackageField, Result);
    end;

    procedure SetErrorFieldNo(FieldNo: Integer)
    begin
        ErrorFieldNo := FieldNo;
    end;

    local procedure SetFieldsVisibility(NoOfFields: Integer)
    begin
        Field1Visible := NoOfFields >= 1;
        Field2Visible := NoOfFields >= 2;
        Field3Visible := NoOfFields >= 3;
        Field4Visible := NoOfFields >= 4;
        Field5Visible := NoOfFields >= 5;
        Field6Visible := NoOfFields >= 6;
        Field7Visible := NoOfFields >= 7;
        Field8Visible := NoOfFields >= 8;
        Field9Visible := NoOfFields >= 9;
        Field10Visible := NoOfFields >= 10;
        Field11Visible := NoOfFields >= 11;
        Field12Visible := NoOfFields >= 12;
        Field13Visible := NoOfFields >= 13;
        Field14Visible := NoOfFields >= 14;
        Field15Visible := NoOfFields >= 15;
        Field16Visible := NoOfFields >= 16;
        Field17Visible := NoOfFields >= 17;
        Field18Visible := NoOfFields >= 18;
        Field19Visible := NoOfFields >= 19;
        Field20Visible := NoOfFields >= 20;
        Field21Visible := NoOfFields >= 21;
        Field22Visible := NoOfFields >= 22;
        Field23Visible := NoOfFields >= 23;
        Field24Visible := NoOfFields >= 24;
        Field25Visible := NoOfFields >= 25;
        Field26Visible := NoOfFields >= 26;
        Field27Visible := NoOfFields >= 27;
        Field28Visible := NoOfFields >= 28;
        Field29Visible := NoOfFields >= 29;
        Field30Visible := NoOfFields >= 30;
        Field31Visible := NoOfFields >= 31;
        Field32Visible := NoOfFields >= 32;
        Field33Visible := NoOfFields >= 33;
        Field34Visible := NoOfFields >= 34;
        Field35Visible := NoOfFields >= 35;
        Field36Visible := NoOfFields >= 36;
        Field37Visible := NoOfFields >= 37;
        Field38Visible := NoOfFields >= 38;
        Field39Visible := NoOfFields >= 39;
        Field40Visible := NoOfFields >= 40;
        Field41Visible := NoOfFields >= 41;
        Field42Visible := NoOfFields >= 42;
        Field43Visible := NoOfFields >= 43;
        Field44Visible := NoOfFields >= 44;
        Field45Visible := NoOfFields >= 45;
        Field46Visible := NoOfFields >= 46;
        Field47Visible := NoOfFields >= 47;
        Field48Visible := NoOfFields >= 48;
        Field49Visible := NoOfFields >= 49;
        Field50Visible := NoOfFields >= 50;
        Field51Visible := NoOfFields >= 51;
        Field52Visible := NoOfFields >= 52;
        Field53Visible := NoOfFields >= 53;
        Field54Visible := NoOfFields >= 54;
        Field55Visible := NoOfFields >= 55;
        Field56Visible := NoOfFields >= 56;
        Field57Visible := NoOfFields >= 57;
        Field58Visible := NoOfFields >= 58;
        Field59Visible := NoOfFields >= 59;
        Field60Visible := NoOfFields >= 60;
        Field61Visible := NoOfFields >= 61;
        Field62Visible := NoOfFields >= 62;
        Field63Visible := NoOfFields >= 63;
        Field64Visible := NoOfFields >= 64;
        Field65Visible := NoOfFields >= 65;
        Field66Visible := NoOfFields >= 66;
        Field67Visible := NoOfFields >= 67;
        Field68Visible := NoOfFields >= 68;
        Field69Visible := NoOfFields >= 69;
        Field70Visible := NoOfFields >= 70;
        Field71Visible := NoOfFields >= 71;
        Field72Visible := NoOfFields >= 72;
        Field73Visible := NoOfFields >= 73;
        Field74Visible := NoOfFields >= 74;
        Field75Visible := NoOfFields >= 75;
        Field76Visible := NoOfFields >= 76;
        Field77Visible := NoOfFields >= 77;
        Field78Visible := NoOfFields >= 78;
        Field79Visible := NoOfFields >= 79;
        Field80Visible := NoOfFields >= 80;
        Field81Visible := NoOfFields >= 81;
        Field82Visible := NoOfFields >= 82;
        Field83Visible := NoOfFields >= 83;
        Field84Visible := NoOfFields >= 84;
        Field85Visible := NoOfFields >= 85;
        Field86Visible := NoOfFields >= 86;
        Field87Visible := NoOfFields >= 87;
        Field88Visible := NoOfFields >= 88;
        Field89Visible := NoOfFields >= 89;
        Field90Visible := NoOfFields >= 90;
        Field91Visible := NoOfFields >= 91;
        Field92Visible := NoOfFields >= 92;
        Field93Visible := NoOfFields >= 93;
        Field94Visible := NoOfFields >= 94;
        Field95Visible := NoOfFields >= 95;
        Field96Visible := NoOfFields >= 96;
        Field97Visible := NoOfFields >= 97;
        Field98Visible := NoOfFields >= 98;
        Field99Visible := NoOfFields >= 99;
        Field100Visible := NoOfFields >= 100;
    end;

    local procedure ValidatePackageData(ColumnID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        InStream: InStream;
        ErrorText: Text;
        IsHandled, IsBlobField : Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePackageData(Rec, MatrixCellData, PackageColumnField, ColumnID, IsHandled);
        if IsHandled then
            exit;

        MatrixCellData[ColumnID] := DelChr(MatrixCellData[ColumnID], '<>', ' ');
        if MatrixDimension[ColumnID] then begin
            if MatrixCellData[ColumnID] <> '' then begin
                if StrLen(MatrixCellData[ColumnID]) > MaxStrLen(DimValue.Code) then
                    Error(ValueIsTooLongErr, Dimension.TableCaption(), MatrixCellData[ColumnID], MaxStrLen(DimValue.Code));
                if not DimValue.Get(MatrixColumnCaptions[ColumnID], MatrixCellData[ColumnID]) then
                    Error(ValueNotExistErr, Dimension.TableCaption(), MatrixCellData[ColumnID]);
            end;
            ConfigPackageData.Get(Rec."Package Code", Rec."Table ID", Rec."No.", PackageColumnField[ColumnID]);
            ConfigPackageData.Validate(Value, MatrixCellData[ColumnID]);
            ConfigPackageData.Modify();
        end else begin
            RecRef.Open(Rec."Table ID", true);
            FieldRef := RecRef.Field(PackageColumnField[ColumnID]);
            ConfigPackageField.Get(Rec."Package Code", Rec."Table ID", PackageColumnField[ColumnID]);
            ConfigPackageField.TestField(Dimension, false);

            IsBlobField := ConfigPackageMgt.IsBLOBField(ConfigPackageData."Table ID", ConfigPackageData."Field ID");
            if not IsBlobField then
                if StrLen(MatrixCellData[ColumnID]) > MaxStrLen(ConfigPackageData.Value) then
                    Error(ValueIsTooLongErr, ConfigPackageField."Field Caption", MatrixCellData[ColumnID], MaxStrLen(ConfigPackageData.Value));

            ConfigPackageData.Get(Rec."Package Code", Rec."Table ID", Rec."No.", PackageColumnField[ColumnID]);
            ConfigPackageMgt.CleanFieldError(ConfigPackageData);
            ErrorText := ConfigValidateMgt.EvaluateValue(FieldRef, MatrixCellData[ColumnID], false);
            if ErrorText <> '' then
                Error(ErrorText);

            if IsBlobField then begin
                TempBlob.FromFieldRef(FieldRef);
                TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
                InStream.Read(MatrixCellData[ColumnID]);
                ConfigPackageData."BLOB Value" := FieldRef.Value();
            end else begin
                MatrixCellData[ColumnID] := Format(FieldRef.Value);
                ConfigPackageData.Validate(Value, MatrixCellData[ColumnID]);
            end;

            if ConfigPackageField."Validate Field" and not ConfigPackageMgt.ValidateSinglePackageDataRelation(ConfigPackageData) then
                Error(ValueNotExistErr, FieldRef.Caption, FieldRef.Value);

            ConfigPackageData.Modify();
        end;
        CurrPage.Update();
    end;

    local procedure CleanSelectionErrors(var ConfigPackageRecord: Record "Config. Package Record")
    var
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        if ConfigPackageRecord.FindSet() then
            repeat
                ConfigPackageMgt.CleanRecordError(ConfigPackageRecord);
            until ConfigPackageRecord.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPackageFields(var ConfigPackageField: Record "Config. Package Field"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePackageData(var ConfigPackageRecord: record "Config. Package Record"; var MatrixCellData: array[1000] of Text; PackageColumnField: array[1000] of Integer; ColumnID: Integer; var IsHandled: Boolean)
    begin
    end;
}

