// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

table 11601 "BAS Calculation Sheet"
{
    Caption = 'BAS Calculation Sheet';
    LookupPageID = "BAS Calc. Schedule List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; A1; Code[11])
        {
            Caption = 'A1';
            Editable = false;
            NotBlank = true;

            trigger OnValidate()
            begin
                if A1 <> '' then
                    Error(CannotEditFieldErr);
                CheckModificationAllowed();
            end;
        }
        field(2; A2; Text[11])
        {
            Caption = 'A2';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(3; A3; Date)
        {
            Caption = 'A3';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(4; A4; Date)
        {
            Caption = 'A4';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(5; A5; Date)
        {
            Caption = 'A5';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(6; A6; Date)
        {
            Caption = 'A6';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(7; "1A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1A';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(8; "1C"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1C';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(9; "1E"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1E';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(10; "2A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '2A';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(11; "3"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '3';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(12; "4"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '4';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(13; "5A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '5A';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(14; "6A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '6A';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(15; "7"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '7';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(16; "8A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '8A';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(17; "9"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '9';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(18; "1B"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1B';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(19; "1D"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1D';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(20; "1F"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1F';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(21; "1G"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1G';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(22; "2B"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '2B';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(23; "5B"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '5B';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(24; "6B"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '6B';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(25; "8B"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '8B';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(26; G1; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G1';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(27; G2; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G2';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(28; G3; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G3';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(29; G4; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G4';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(30; G5; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G5';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(31; G6; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G6';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(32; G7; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G7';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(33; G8; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G8';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(34; G9; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G9';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(35; W1; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'W1';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(36; W2; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'W2';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(37; T1; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T1';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(38; T3; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T3';

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(39; F1; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'F1';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(40; F2; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'F2';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(41; G10; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G10';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(42; G11; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G11';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(43; G12; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G12';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(44; G13; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G13';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(45; G14; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G14';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(46; G15; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G15';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(47; G16; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G16';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(48; G17; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G17';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(49; G18; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G18';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(50; G19; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G19';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(51; G20; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G20';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(52; W3; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'W3';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(53; W4; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'W4';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(54; T2; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T2';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(55; T4; Code[2])
        {
            Caption = 'T4';
            Numeric = true;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(56; F3; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'F3';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(57; F4; Code[2])
        {
            Caption = 'F4';
            Numeric = true;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(58; "7A"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '7A';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(59; A2a; Text[3])
        {
            Caption = 'A2a';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(60; G21; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G21';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(61; G22; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G22';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(62; G23; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G23';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(63; G24; Code[2])
        {
            Caption = 'G24';
            Numeric = true;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(64; "1H"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '1H';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(65; W5; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'W5';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(66; T7; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T7';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(67; T8; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T8';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(68; T9; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T9';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(69; T11; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'T11';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(70; "PAYG Option 1"; Boolean)
        {
            Caption = 'PAYG Option 1';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(71; "PAYG Option 2"; Boolean)
        {
            Caption = 'PAYG Option 2';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(72; "7C"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '7C';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(73; "7D"; Decimal)
        {
            AutoFormatType = 0;
            Caption = '7D';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(100; "User Id"; Code[50])
        {
            Caption = 'User Id';
            Editable = false;
        }
        field(101; "Date of Export"; Date)
        {
            Caption = 'Date of Export';
            Editable = false;
        }
        field(102; "Time of Export"; Time)
        {
            Caption = 'Time of Export';
            Editable = false;
        }
        field(103; "File Name"; Text[250])
        {
            Caption = 'File Name';
            Editable = false;
        }
        field(104; Exported; Boolean)
        {
            Caption = 'Exported';
            Editable = false;
        }
        field(105; Consolidated; Boolean)
        {
            Caption = 'Consolidated';
            Editable = false;
        }
        field(107; "BAS Version"; Integer)
        {
            Caption = 'BAS Version';
            Editable = false;
        }
        field(108; Updated; Boolean)
        {
            Caption = 'Updated';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(109; "ATO Receipt No."; Text[50])
        {
            Caption = 'ATO Receipt No.';
        }
        field(110; "Group Consolidated"; Boolean)
        {
            Caption = 'Group Consolidated';
            Editable = false;
        }
        field(111; "BAS GST Division Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'BAS GST Division Factor';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(112; Comment; Boolean)
        {
            CalcFormula = exist("BAS Comment Line" where("No." = field(A1),
                                                          "Version No." = field("BAS Version")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(113; "BAS Setup Name"; Code[20])
        {
            Caption = 'BAS Setup Name';
            Editable = false;
            TableRelation = "BAS Setup Name";

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(114; Settled; Boolean)
        {
            Caption = 'Settled';
            Editable = false;

            trigger OnValidate()
            begin
                CheckModificationAllowed();
            end;
        }
        field(115; "BAS Template XML File"; BLOB)
        {
            Caption = 'BAS Template XML File';
        }
    }

    keys
    {
        key(Key1; A1, "BAS Version")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; A1, "BAS Version", A3, A4, A5, A6, Exported, Updated, "ATO Receipt No.", Settled)
        {
        }
    }

    var
        CannotEditFieldErr: Label 'You cannot edit this field. Use the import function.';

    [Scope('OnPrem')]
    procedure CheckModificationAllowed()
    begin
        TestField(A1);
        TestField("BAS Version");
        TestField(Exported, false);
        TestField(Consolidated, false);
    end;
}

