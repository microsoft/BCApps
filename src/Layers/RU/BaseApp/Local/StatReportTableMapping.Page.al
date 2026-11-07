#pragma warning disable AA0247
page 26592 "Stat. Report Table Mapping"
{
    Caption = 'Stat. Report Table Mapping';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Stat. Report Table Row";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with the statutory report table row.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Visible = Field1Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(1);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Visible = Field2Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(2);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Visible = Field3Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(3);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Visible = Field4Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(4);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Visible = Field5Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(5);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Visible = Field6Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(6);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Visible = Field7Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(7);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Visible = Field8Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(8);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Visible = Field9Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(9);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Visible = Field10Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(10);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Visible = Field11Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(11);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Visible = Field12Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(12);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    Visible = Field13Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(13);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    Visible = Field14Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(14);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    Visible = Field15Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(15);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    Visible = Field16Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(16);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    Visible = Field17Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(17);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    Visible = Field18Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(18);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    Visible = Field19Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(19);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    Visible = Field20Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(20);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    Visible = Field21Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(21);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    Visible = Field22Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(22);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    Visible = Field23Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(23);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    Visible = Field24Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(24);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    Visible = Field25Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(25);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    Visible = Field26Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(26);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    Visible = Field27Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(27);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    Visible = Field28Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(28);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    Visible = Field29Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(29);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    Visible = Field30Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(30);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(3);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    Visible = Field31Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(31);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    Visible = Field32Visible;

                    trigger OnAssistEdit()
                    begin
                        MATRIX_OnAssistEdit(32);
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_OnValidate(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnOpenPage()
    begin
        Load(Rec."Report Code", Rec."Table Code");
    end;

    var
        StatReportTableColumn: Record "Stat. Report Table Column";
        MatrixRecords: array[32] of Record "Stat. Report Table Column";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        MATRIX_CaptionSet: array[32] of Text[1024];
        MATRIX_CellData: array[32] of Text[1024];
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        ColumnValue: Text[1024];
        ReportCode: Code[20];
        TableCode: Code[20];
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

    [Scope('OnPrem')]
    procedure Load(NewReportCode: Code[20]; NewTableCode: Code[20])
    var
        i: Integer;
    begin
        ReportCode := NewReportCode;
        TableCode := NewTableCode;

        i := 0;
        StatReportTableColumn.SetRange("Report Code", ReportCode);
        StatReportTableColumn.SetRange("Table Code", TableCode);
        if StatReportTableColumn.FindSet() then
            repeat
                i := i + 1;
                MatrixRecords[i] := StatReportTableColumn;
                MATRIX_CaptionSet[i] := StatReportTableColumn."Column Header";
            until StatReportTableColumn.Next() = 0;
        MATRIX_CurrentNoOfMatrixColumn := StatReportTableColumn.Count();

        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
        Field5Visible := MATRIX_CaptionSet[5] <> '';
        Field6Visible := MATRIX_CaptionSet[6] <> '';
        Field7Visible := MATRIX_CaptionSet[7] <> '';
        Field8Visible := MATRIX_CaptionSet[8] <> '';
        Field9Visible := MATRIX_CaptionSet[9] <> '';
        Field10Visible := MATRIX_CaptionSet[10] <> '';
        Field11Visible := MATRIX_CaptionSet[11] <> '';
        Field12Visible := MATRIX_CaptionSet[12] <> '';
        Field13Visible := MATRIX_CaptionSet[13] <> '';
        Field14Visible := MATRIX_CaptionSet[14] <> '';
        Field15Visible := MATRIX_CaptionSet[15] <> '';
        Field16Visible := MATRIX_CaptionSet[16] <> '';
        Field17Visible := MATRIX_CaptionSet[17] <> '';
        Field18Visible := MATRIX_CaptionSet[18] <> '';
        Field19Visible := MATRIX_CaptionSet[19] <> '';
        Field20Visible := MATRIX_CaptionSet[20] <> '';
        Field21Visible := MATRIX_CaptionSet[21] <> '';
        Field22Visible := MATRIX_CaptionSet[22] <> '';
        Field23Visible := MATRIX_CaptionSet[23] <> '';
        Field24Visible := MATRIX_CaptionSet[24] <> '';
        Field25Visible := MATRIX_CaptionSet[25] <> '';
        Field26Visible := MATRIX_CaptionSet[26] <> '';
        Field27Visible := MATRIX_CaptionSet[27] <> '';
        Field28Visible := MATRIX_CaptionSet[28] <> '';
        Field29Visible := MATRIX_CaptionSet[29] <> '';
        Field30Visible := MATRIX_CaptionSet[30] <> '';
        Field31Visible := MATRIX_CaptionSet[31] <> '';
        Field32Visible := MATRIX_CaptionSet[32] <> '';
    end;

    [Scope('OnPrem')]
    procedure MATRIX_OnAssistEdit(MATRIX_ColumnOrdinal: Integer)
    begin
        StatReportTableMapping.ShowMappingCard(
          ReportCode,
          TableCode,
          Rec."Line No.",
          MatrixRecords[MATRIX_ColumnOrdinal]."Line No.",
          ColumnValue);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        ColumnValue := '';
        if StatReportTableMapping.Get(
             ReportCode,
             TableCode,
             Rec."Line No.",
             MatrixRecords[MATRIX_ColumnOrdinal]."Line No.")
        then
            ColumnValue := StatReportTableMapping.GetRecDescription();
        MATRIX_CellData[MATRIX_ColumnOrdinal] := ColumnValue;
    end;

    local procedure MATRIX_OnValidate(MATRIX_ColumnOrdinal: Integer)
    begin
        if MATRIX_CellData[MATRIX_ColumnOrdinal] = '' then;
        if StatReportTableMapping.Get(
             ReportCode,
             TableCode,
             Rec."Line No.",
             MatrixRecords[MATRIX_ColumnOrdinal]."Line No.")
        then
            StatReportTableMapping.Delete();
    end;
}

