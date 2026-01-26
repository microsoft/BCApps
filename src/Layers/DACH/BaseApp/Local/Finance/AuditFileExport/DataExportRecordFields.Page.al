// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

page 11027 "Data Export Record Fields"
{
    Caption = 'Data Export Record Fields';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Data Export Record Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the field that you have added to the record source.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = FlowFieldStyle;
                    ToolTip = 'Specifies the name of the field that is specified in the Field No. field.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type of the selected field.';
                }
                field("Field Class"; Rec."Field Class")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = FlowFieldStyle;
                    ToolTip = 'Specifies the class of the specified field.';
                }
                field("Date Filter Handling"; Rec."Date Filter Handling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the field Starting Date and Ending Date in the Export Business Data batch job, influence the calculation.';
                }
                field("Export Field Name"; Rec."Export Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for the data from this field that can be accepted by the auditor''s tools.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Add ")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Add';
                Image = Add;
                ToolTip = 'Add the selected fields to the source table for data export.';

                trigger OnAction()
                var
                    "Field": Record "Field";
                    DataExportFieldList: Page "Data Export Field List";
                    DataExportCode: Code[10];
                    DataExportRecTypeCode: Code[10];
                    CurrGroup: Integer;
                    TableNo: Integer;
                    SelectedLineNo: Integer;
                    SourceLineNo: Integer;
                begin
                    CurrGroup := Rec.FilterGroup;
                    Rec.FilterGroup(4);
                    Evaluate(TableNo, Rec.GetFilter("Table No."));
                    Evaluate(SourceLineNo, Rec.GetFilter("Source Line No."));
                    DataExportCode := Rec.GetRangeMin("Data Export Code");
                    DataExportRecTypeCode := Rec.GetRangeMin("Data Exp. Rec. Type Code");
                    Rec.FilterGroup(CurrGroup);
                    Field.FilterGroup(4);
                    Field.SetRange(TableNo, TableNo);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    Field.SetFilter(Type, '%1|%2|%3|%4|%5|%6|%7|%8',
                      Field.Type::Option, Field.Type::Text, Field.Type::Code, Field.Type::Integer, Field.Type::Decimal,
                      Field.Type::Date, Field.Type::Boolean, Field.Type::DateTime);
                    Field.FilterGroup(0);

                    Clear(DataExportFieldList);
                    DataExportFieldList.SetTableView(Field);
                    DataExportFieldList.LookupMode := true;
                    if DataExportFieldList.RunModal() = ACTION::LookupOK then begin
                        DataExportFieldList.SetSelectionFilter(Field);
                        SelectedLineNo := GetSelectedFieldsLineNo(DataExportCode, DataExportRecTypeCode, SourceLineNo);
                        Rec.InsertSelectedFields(Field, DataExportCode, DataExportRecTypeCode, SourceLineNo, SelectedLineNo);
                    end;
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Remove the selected fields from the data export.';

                trigger OnAction()
                var
                    DataExportRecordField: Record "Data Export Record Field";
                begin
                    CurrPage.SetSelectionFilter(DataExportRecordField);
                    DataExportRecordField.DeleteAll();
                end;
            }
            action(MoveUp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Image = MoveUp;
                ToolTip = 'Change the order of the selected field.';

                trigger OnAction()
                begin
                    Rec.MoveRecordUp(Rec);
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Image = MoveDown;
                ToolTip = 'Change the order of the selected field.';

                trigger OnAction()
                begin
                    Rec.MoveRecordDown(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Field Class" = Rec."Field Class"::FlowField then
            FlowFieldStyle := 'StandardAccent'
        else
            FlowFieldStyle := 'Normal';
    end;

    var
        FlowFieldStyle: Text[30];

    [Scope('OnPrem')]
    procedure GetSelectedFieldsLineNo(DataExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer) SelectedLineNo: Integer
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.SetRange("Data Export Code", DataExportCode);
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordField.SetRange("Source Line No.", SourceLineNo);
        if DataExportRecordField.IsEmpty() then
            SelectedLineNo := 0
        else
            SelectedLineNo := Rec."Line No.";
    end;
}

