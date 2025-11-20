// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Globalization;
using System.Reflection;

page 5382 "Man. Int. Table Mapping List"
{
    PageType = List;
    ApplicationArea = Suite;
    SourceTable = "Man. Integration Table Mapping";
    InsertAllowed = false;
    DeleteAllowed = true;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                Editable = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the integration table.';
                }
                field(TableCaptionValue; TableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table Caption';
                    Enabled = false;
                    ToolTip = 'Specifies the name of the table to map to the integration table.';
                }
                field(IntegrationTableCaptionValue; IntegrationTableCaptionValue)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table Caption';
                    Enabled = false;
                    ToolTip = 'Specifies the caption of the integration table.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Fields)
            {
                Caption = 'Fields';
                Image = SelectField;
                RunObject = page "Man. Int. Field Mapping List";
                RunPageLink = "Name" = field(Name);
                ToolTip = 'View fields in integration tables that are mapped to fields in Business Central.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IntegrationTableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Integration Table ID");
        TableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Table ID");
        IntegrationTableUIDCaptionValue := GetFieldCaption(Rec."Integration Table ID", Rec."Integration Table UID");
        ModifiedFieldCaptionValue := GetFieldCaption(Rec."Integration Table ID", Rec."Int. Tbl. Modified On Id");
    end;

    var
        ObjectTranslation: Record "Object Translation";
        IntegrationTableCaptionValue: text;
        TableCaptionValue: text;
        IntegrationTableUIDCaptionValue: text;
        ModifiedFieldCaptionValue: text;

    local procedure GetFieldCaption(tableId: Integer; FieldNo: Integer): Text
    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        if TypeHelper.GetField(tableId, FieldNo, Field) then
            exit(Field."Field Caption");
    end;
}