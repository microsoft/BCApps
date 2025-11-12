// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using System.Utilities;

report 7310 "Calculate Bins"
{
    Caption = 'Calculate Bins';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rack2; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(Section2; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(Level2; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    begin
                        if IncStr(Level) = Level then
                            CurrReport.Break();
                        if Level > ToLevel then
                            CurrReport.Break();
                        if StrLen(Level) > StrLen(ToLevel) then
                            CurrReport.Break();

                        OnLevel2OnAfterGetRecordOnBeforeBinCreateWksh(Level);
                        BinCreateWksh();

                        Level := IncStr(Level);
                    end;

                    trigger OnPostDataItem()
                    begin
                        Section := IncStr(Section);
                    end;

                    trigger OnPreDataItem()
                    begin
                        Level := FromLevel;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if IncStr(Section) = Section then
                        CurrReport.Break();
                    if Section > ToSection then
                        CurrReport.Break();
                    if StrLen(Section) > StrLen(ToSection) then
                        CurrReport.Break();

                    if (FromLevel = '') and (ToLevel = '') then
                        BinCreateWksh();
                end;

                trigger OnPostDataItem()
                begin
                    Rack := IncStr(Rack);
                end;

                trigger OnPreDataItem()
                begin
                    Section := FromSection;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if IncStr(Rack) = Rack then
                    CurrReport.Break();
                if Rack > ToRack then
                    CurrReport.Break();
                if StrLen(Rack) > StrLen(ToRack) then
                    CurrReport.Break();

                if (FromSection = '') and (ToSection = '') then
                    BinCreateWksh();
            end;

            trigger OnPreDataItem()
            begin
                Rack := FromRack;
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
                    field(BinTemplateCode; BinTemplateFilter.Code)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Template Code';
                        ToolTip = 'Specifies the code for the bin. ';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            BinTemplates: Page "Bin Templates";
                        begin
                            if CurrLocationCode <> '' then begin
                                BinTemplateFilter.FilterGroup := 2;
                                BinTemplateFilter.SetRange("Location Code", CurrLocationCode);
                                BinTemplateFilter.FilterGroup := 0;
                            end;
                            Clear(BinTemplates);
                            BinTemplates.SetTableView(BinTemplateFilter);
                            BinTemplates.Editable(false);
                            BinTemplates.LookupMode(true);
                            if BinTemplates.RunModal() = ACTION::LookupOK then begin
                                BinTemplates.GetRecord(BinTemplateFilter);
                                BinTemplateFilter.Validate(Code);
                                BinTemplateFilter.TestField("Location Code");
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if BinTemplateFilter.Code <> '' then begin
                                BinTemplateFilter.Get(BinTemplateFilter.Code);
                                BinTemplateFilter.TestField("Location Code");
                            end else begin
                                BinTemplateFilter.Code := '';
                                BinTemplateFilter.Description := '';
                                BinTemplateFilter."Location Code" := '';
                                BinTemplateFilter."Zone Code" := '';
                            end;
                        end;
                    }
                    field("BinTemplateFilter.Description"; BinTemplateFilter.Description)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description of the bin.';
                    }
#pragma warning disable AA0100
                    field("BinTemplateFilter.""Location Code"""; BinTemplateFilter."Location Code")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Location Code';
                        Editable = false;
                        ToolTip = 'Specifies the location where the warehouse activity takes place. ';
                    }
#pragma warning disable AA0100
                    field("BinTemplateFilter.""Zone Code"""; BinTemplateFilter."Zone Code")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Zone Code';
                        Editable = false;
                        ToolTip = 'Specifies the zone code where the bin on this line is located.';
                    }
                    group(Rack)
                    {
                        Caption = 'Rack';
                        field(RackFromNo; FromRack)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'From No.';
                            ToolTip = 'Specifies the lowest number from which you will calculate the bin.';

                            trigger OnValidate()
                            begin
                                if (FromRack <> '') and
                                   (ToRack <> '') and
                                   (StrLen(FromRack) <> StrLen(ToRack))
                                then
                                    Error(Text004);
                            end;
                        }
                        field(RackToNo; ToRack)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'To No.';

                            trigger OnValidate()
                            begin
                                if (FromRack <> '') and
                                   (ToRack <> '') and
                                   (StrLen(FromRack) <> StrLen(ToRack))
                                then
                                    Error(Text004);
                            end;
                        }
                    }
                    group(Section)
                    {
                        Caption = 'Section';
                        field(SelectionFromNo; FromSection)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'From No.';
                            ToolTip = 'Specifies the lowest number from which you will calculate the bin.';

                            trigger OnValidate()
                            begin
                                if (FromSection <> '') and
                                   (ToSection <> '') and
                                   (StrLen(FromSection) <> StrLen(ToSection))
                                then
                                    Error(Text004);
                            end;
                        }
                        field(SelectionToNo; ToSection)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'To No.';

                            trigger OnValidate()
                            begin
                                if (FromSection <> '') and
                                   (ToSection <> '') and
                                   (StrLen(FromSection) <> StrLen(ToSection))
                                then
                                    Error(Text004);
                            end;
                        }
                    }
                    group(Level)
                    {
                        Caption = 'Level';
                        field(LevelFromNo; FromLevel)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'From No.';
                            ToolTip = 'Specifies the lowest number from which you will calculate the bin.';

                            trigger OnValidate()
                            begin
                                if (FromLevel <> '') and
                                   (ToLevel <> '') and
                                   (StrLen(FromLevel) <> StrLen(ToLevel))
                                then
                                    Error(Text004);
                            end;
                        }
                        field(LevelToNo; ToLevel)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'To No.';

                            trigger OnValidate()
                            begin
                                if (FromLevel <> '') and
                                   (ToLevel <> '') and
                                   (StrLen(FromLevel) <> StrLen(ToLevel))
                                then
                                    Error(Text004);
                            end;
                        }
                    }
                    field(FieldSeparator; FieldSeparator)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Field Separator';
                        ToolTip = 'Specifies if you want a character, such as a hyphen, to separate the category fields you have defined as part of the bin code. If so, fill in the Field Separator field with this character.';
                    }
                    field(CheckOnBin; CheckOnBin)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Check on Existing Bin';
                        ToolTip = 'Specifies whether or not to check on an existing bin.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        BinTemplateFilter.TestField(Code);
        if BinTemplateFilter.Get(BinTemplateFilter.Code) then;
        BinCreationWkshLine.SetRange("Worksheet Template Name", CurrTemplateName);
        BinCreationWkshLine.SetRange(Name, CurrWorksheetName);
        BinCreationWkshLine.SetRange("Location Code", CurrLocationCode);
        if BinCreationWkshLine.FindLast() then
            LineNo := BinCreationWkshLine."Line No." + 10000
        else
            LineNo := 10000;
        BinCreationWkshLine.Init();
        BinCreationWkshLine."Worksheet Template Name" := CurrTemplateName;
        BinCreationWkshLine.Name := CurrWorksheetName;
        BinCreationWkshLine."Location Code" := CurrLocationCode;
        BinCreationWkshLine.Dedicated := BinTemplateFilter.Dedicated;
        BinCreationWkshLine."Zone Code" := BinTemplateFilter."Zone Code";
        BinCreationWkshLine.Description := BinTemplateFilter."Bin Description";
        BinCreationWkshLine."Bin Type Code" := BinTemplateFilter."Bin Type Code";
        BinCreationWkshLine."Warehouse Class Code" := BinTemplateFilter."Warehouse Class Code";
        BinCreationWkshLine."Block Movement" := BinTemplateFilter."Block Movement";
        BinCreationWkshLine."Special Equipment Code" := BinTemplateFilter."Special Equipment Code";
        BinCreationWkshLine."Bin Ranking" := BinTemplateFilter."Bin Ranking";
        BinCreationWkshLine."Maximum Cubage" := BinTemplateFilter."Maximum Cubage";
        BinCreationWkshLine."Maximum Weight" := BinTemplateFilter."Maximum Weight";
    end;

    var
        Bin: Record Bin;
        BinTemplateFilter: Record "Bin Template";
        BinCreationWkshLine: Record "Bin Creation Worksheet Line";
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        CurrLocationCode: Code[10];
        FromRack: Code[20];
        FromSection: Code[20];
        FromLevel: Code[20];
        ToRack: Code[20];
        ToSection: Code[20];
        ToLevel: Code[20];
        FieldSeparator: Code[1];
        Rack: Code[20];
        Section: Code[20];
        Level: Code[20];
        CheckOnBin: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The length of From Rack+From Section+From Level is greater than the maximum length of Bin Code (%1).';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LenFieldSeparator: Integer;
        LineNo: Integer;
#pragma warning disable AA0074
        Text004: Label 'The length of the strings inserted in From No. and To No. must be identical.';
#pragma warning restore AA0074

    local procedure BinCreateWksh()
    begin
        OnBeforeBinCreateWksh(BinCreationWkshLine, BinTemplateFilter);

        LenFieldSeparator := 0;
        if FieldSeparator <> '' then
            LenFieldSeparator := 2;

        if (StrLen(Rack + Section + Level) + LenFieldSeparator) > MaxStrLen(BinCreationWkshLine."Bin Code") then
            Error(Text000, MaxStrLen(BinCreationWkshLine."Bin Code"));

        BinCreationWkshLine."Line No." := LineNo;
        BinCreationWkshLine."Bin Code" :=
          CopyStr(Rack + FieldSeparator + Section + FieldSeparator + Level, 1, MaxStrLen(BinCreationWkshLine."Bin Code"));
        if not CheckOnBin then
            BinCreationWkshLine.Insert(true)
        else begin
            if Bin.Get(BinCreationWkshLine."Location Code", BinCreationWkshLine."Bin Code") then
                exit;
            BinCreationWkshLine.Insert(true);
        end;
        LineNo := LineNo + 10000;
    end;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10]; LocationCode: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
        CurrLocationCode := LocationCode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinCreateWksh(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line"; BinTemplate: Record "Bin Template")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLevel2OnAfterGetRecordOnBeforeBinCreateWksh(var Level: Code[20])
    begin
    end;
}

