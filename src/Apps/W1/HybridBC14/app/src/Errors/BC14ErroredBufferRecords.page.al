// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Integration;
using System.IO;

page 46878 "BC14 Errored Buffer Records"
{
    PageType = Worksheet;
    Caption = 'Errored Buffer Records';
    DataCaptionExpression = BufferTableCaption;
    SourceTable = "Data Migration Error";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Trigger Options';

                field(RunValidateField; RunValidate)
                {
                    ApplicationArea = All;
                    Caption = 'Run Validate';
                    ToolTip = 'Specifies whether field validation triggers run when editing values.';
                }
                field(RunModifyField; RunModify)
                {
                    ApplicationArea = All;
                    Caption = 'Run Modify Trigger';
                    ToolTip = 'Specifies whether the OnModify trigger runs when saving changes.';
                }
            }
            repeater(Records)
            {
                ShowCaption = false;
                field(Field1; MatrixCellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field1Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(1);
                    end;
                }
                field(Field2; MatrixCellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field2Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(2);
                    end;
                }
                field(Field3; MatrixCellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field3Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(3);
                    end;
                }
                field(Field4; MatrixCellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field4Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(4);
                    end;
                }
                field(Field5; MatrixCellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field5Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(5);
                    end;
                }
                field(Field6; MatrixCellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field6Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(6);
                    end;
                }
                field(Field7; MatrixCellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field7Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(7);
                    end;
                }
                field(Field8; MatrixCellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field8Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(8);
                    end;
                }
                field(Field9; MatrixCellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field9Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(9);
                    end;
                }
                field(Field10; MatrixCellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field10Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(10);
                    end;
                }
                field(Field11; MatrixCellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field11Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(11);
                    end;
                }
                field(Field12; MatrixCellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field12Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(12);
                    end;
                }
                field(Field13; MatrixCellData[13])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field13Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(13);
                    end;
                }
                field(Field14; MatrixCellData[14])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field14Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(14);
                    end;
                }
                field(Field15; MatrixCellData[15])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field15Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(15);
                    end;
                }
                field(Field16; MatrixCellData[16])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field16Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(16);
                    end;
                }
                field(Field17; MatrixCellData[17])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field17Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(17);
                    end;
                }
                field(Field18; MatrixCellData[18])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field18Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(18);
                    end;
                }
                field(Field19; MatrixCellData[19])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field19Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(19);
                    end;
                }
                field(Field20; MatrixCellData[20])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field20Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(20);
                    end;
                }
                field(Field21; MatrixCellData[21])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field21Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(21);
                    end;
                }
                field(Field22; MatrixCellData[22])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field22Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(22);
                    end;
                }
                field(Field23; MatrixCellData[23])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field23Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(23);
                    end;
                }
                field(Field24; MatrixCellData[24])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field24Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(24);
                    end;
                }
                field(Field25; MatrixCellData[25])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field25Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(25);
                    end;
                }
                field(Field26; MatrixCellData[26])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field26Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(26);
                    end;
                }
                field(Field27; MatrixCellData[27])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field27Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(27);
                    end;
                }
                field(Field28; MatrixCellData[28])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field28Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(28);
                    end;
                }
                field(Field29; MatrixCellData[29])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field29Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(29);
                    end;
                }
                field(Field30; MatrixCellData[30])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field30Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(30);
                    end;
                }
                field(Field31; MatrixCellData[31])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field31Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(31);
                    end;
                }
                field(Field32; MatrixCellData[32])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field32Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(32);
                    end;
                }
                field(Field33; MatrixCellData[33])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[33];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field33Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(33);
                    end;
                }
                field(Field34; MatrixCellData[34])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[34];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field34Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(34);
                    end;
                }
                field(Field35; MatrixCellData[35])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[35];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field35Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(35);
                    end;
                }
                field(Field36; MatrixCellData[36])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[36];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field36Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(36);
                    end;
                }
                field(Field37; MatrixCellData[37])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[37];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field37Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(37);
                    end;
                }
                field(Field38; MatrixCellData[38])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[38];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field38Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(38);
                    end;
                }
                field(Field39; MatrixCellData[39])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[39];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field39Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(39);
                    end;
                }
                field(Field40; MatrixCellData[40])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[40];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field40Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(40);
                    end;
                }
                field(Field41; MatrixCellData[41])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[41];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field41Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(41);
                    end;
                }
                field(Field42; MatrixCellData[42])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[42];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field42Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(42);
                    end;
                }
                field(Field43; MatrixCellData[43])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[43];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field43Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(43);
                    end;
                }
                field(Field44; MatrixCellData[44])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[44];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field44Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(44);
                    end;
                }
                field(Field45; MatrixCellData[45])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[45];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field45Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(45);
                    end;
                }
                field(Field46; MatrixCellData[46])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[46];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field46Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(46);
                    end;
                }
                field(Field47; MatrixCellData[47])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[47];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field47Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(47);
                    end;
                }
                field(Field48; MatrixCellData[48])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[48];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field48Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(48);
                    end;
                }
                field(Field49; MatrixCellData[49])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[49];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field49Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(49);
                    end;
                }
                field(Field50; MatrixCellData[50])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MatrixColumnCaptions[50];
                    ToolTip = 'Specifies the field value.';
                    Visible = Field50Visible;

                    trigger OnValidate()
                    begin
                        ValidateFieldData(50);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshData)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Reload all records from the buffer table.';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RefreshData_Promoted; RefreshData) { }
        }
    }

    trigger OnOpenPage()
    var
        SourceTableFilter: Text;
        CompanyFilter: Text;
    begin
        SourceTableFilter := Rec.GetFilter("Source Table ID");
        CompanyFilter := Rec.GetFilter("Company Name");

        if (SourceTableFilter = '') or (CompanyFilter = '') then
            Error(MissingFiltersErr);
        if not Evaluate(SourceTableId, SourceTableFilter) then
            Error(MissingFiltersErr);
        SourceCompanyName := CopyStr(CompanyFilter, 1, MaxStrLen(SourceCompanyName));

        // Data Migration Error is DataPerCompany; when this page is opened from the cross-company
        // Migration Error Overview the caller may pass a Company Name other than the current
        // session's. Re-target Rec to that company so the repeater reads the right table.
        if SourceCompanyName <> CompanyName() then
            Rec.ChangeCompany(SourceCompanyName);

        // Constrain the repeater so it only shows rows for this source table + company.
        Rec.FilterGroup(2);
        Rec.SetRange("Source Table ID", SourceTableId);
        Rec.SetRange("Company Name", SourceCompanyName);
        Rec.FilterGroup(0);

        RunValidate := false;
        RunModify := false;

        InitializeFieldMetadata();
        BufferTableCaption := CopyStr(StrSubstNo(PageCaptionTxt, BufferTableCaption, SourceCompanyName), 1, MaxStrLen(BufferTableCaption));
    end;

    trigger OnAfterGetRecord()
    begin
        PopulateMatrixCells();
    end;

    trigger OnClosePage()
    begin
        if IsBufferOpen then begin
            BufferRecRef.Close();
            IsBufferOpen := false;
        end;
    end;

    var
        BufferRecRef: RecordRef;
        MatrixCellData: array[50] of Text;
        MatrixColumnCaptions: array[50] of Text[100];
        FieldNumbers: array[50] of Integer;
        BufferTableCaption: Text[250];
        SourceCompanyName: Text[30];
        MissingFiltersErr: Label 'This page must be opened with filters on Source Table ID and Company Name.';
        RecordNotFoundErr: Label 'The record could not be found. It may have been deleted.';
        PageCaptionTxt: Label 'Errored %1 records in company %2', Comment = '%1 = source buffer table caption, %2 = company name';
        SourceTableId: Integer;
        FieldCount: Integer;
        IsBufferOpen: Boolean;
        RunValidate: Boolean;
        RunModify: Boolean;
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

    local procedure InitializeFieldMetadata()
    var
        MetadataRecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        MetadataRecRef.Open(SourceTableId);
        FieldCount := 0;

        for i := 1 to MetadataRecRef.FieldCount do begin
            FldRef := MetadataRecRef.FieldIndex(i);
            if FldRef.Class = FieldClass::Normal then
                if not IsSystemField(FldRef) then begin
                    FieldCount += 1;
                    if FieldCount > 50 then begin
                        FieldCount := 50;
                        break;
                    end;
                    FieldNumbers[FieldCount] := FldRef.Number;
                    MatrixColumnCaptions[FieldCount] := CopyStr(FldRef.Caption, 1, MaxStrLen(MatrixColumnCaptions[FieldCount]));
                end;
        end;

        MetadataRecRef.Close();
        SetFieldsVisibility(FieldCount);

        BufferRecRef.Open(SourceTableId, false, SourceCompanyName);
        IsBufferOpen := true;
        BufferTableCaption := CopyStr(BufferRecRef.Caption, 1, MaxStrLen(BufferTableCaption));
    end;

    local procedure PopulateMatrixCells()
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        Clear(MatrixCellData);

        if not BufferRecRef.Get(Rec."Source Staging Table Record ID") then
            exit;

        for i := 1 to FieldCount do begin
            FldRef := BufferRecRef.Field(FieldNumbers[i]);
            MatrixCellData[i] := CopyStr(Format(FldRef.Value), 1, MaxStrLen(MatrixCellData[i]));
        end;
    end;

    local procedure ValidateFieldData(ColumnIndex: Integer)
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        FldRef: FieldRef;
        ErrorText: Text;
    begin
        if ColumnIndex > FieldCount then
            exit;

        if not BufferRecRef.Get(Rec."Source Staging Table Record ID") then
            Error(RecordNotFoundErr);

        FldRef := BufferRecRef.Field(FieldNumbers[ColumnIndex]);
        ErrorText := ConfigValidateMgt.EvaluateValue(FldRef, MatrixCellData[ColumnIndex], RunValidate);
        if ErrorText <> '' then
            Error(ErrorText);

        BufferRecRef.Modify(RunModify);

        // Re-read formatted value to reflect any type conversion
        MatrixCellData[ColumnIndex] := CopyStr(Format(FldRef.Value), 1, MaxStrLen(MatrixCellData[ColumnIndex]));
    end;

    local procedure IsSystemField(FldRef: FieldRef): Boolean
    begin
        exit(CopyStr(FldRef.Name, 1, 7).ToLower() = '$system');
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
    end;
}
