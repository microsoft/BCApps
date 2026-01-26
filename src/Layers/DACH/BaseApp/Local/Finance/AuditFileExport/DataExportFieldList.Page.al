// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

page 11009 "Data Export Field List"
{
    Caption = 'Data Export Field List';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Field";
    SourceTableView = sorting(TableNo, "No.");

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Field No.';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the number of field that holds the data to be exported.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the name of field that holds the data to be exported.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the type.';
                }
                field(Class; Rec.Class)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Class';
                    StyleExpr = ClassColumnStyle;
                    ToolTip = 'Specifies the class of the field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Class = Rec.Class::FlowField then
            ClassColumnStyle := 'StandardAccent'
        else
            ClassColumnStyle := 'Normal';
    end;

    var
        ClassColumnStyle: Text[30];

    local procedure GetCaption(): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Rec.TableNo) then
            exit(Format(Rec.TableNo) + ' ' + AllObjWithCaption."Object Caption");

        exit('');
    end;
}

