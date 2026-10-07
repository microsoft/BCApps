// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.SyncEngine;

page 5386 "Integration Fields Lookup"
{
    Extensible = false;
    Editable = false;
    PageType = List;
    SourceTable = "Integration Field";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(TableNo; Rec."Table No.")
                {
                    ApplicationArea = All;
                    Caption = 'Table No.';
                    ToolTip = 'Specifies the number of the table this field belongs to.';
                    Visible = false;
                }
                field(FieldName; Rec."Field Name")
                {
                    ApplicationArea = All;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Field Caption';
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.';
                }
                field(IsRuntime; Rec.IsRuntime)
                {
                    ApplicationArea = All;
                    Caption = 'Is Runtime';
                    ToolTip = 'Specifies whether the field is a runtime field. Runtime fields are created on the fly and do not exist in the database schema.';
                }
            }
        }
    }

    procedure GetSelectedFields(var SelectedIntegrationField: Record "Integration Field")
    var
        IntegrationField: Record "Integration Field";
    begin
        if SelectedIntegrationField.IsTemporary() then begin
            SelectedIntegrationField.Reset();
            SelectedIntegrationField.DeleteAll();
            CurrPage.SetSelectionFilter(IntegrationField);
            if IntegrationField.FindSet() then
                repeat
                    SelectedIntegrationField.Copy(IntegrationField);
                    SelectedIntegrationField.Insert();
                until IntegrationField.Next() = 0;
        end else begin
            CurrPage.SetSelectionFilter(SelectedIntegrationField);
            SelectedIntegrationField.FindSet();
        end;
    end;
}