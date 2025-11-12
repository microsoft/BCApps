// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;

page 5385 "Man. Int. Field Mapping List"
{
    ApplicationArea = All;
    Caption = 'User Defined Field Mappings';
    PageType = List;
    SourceTable = "Man. Int. Field Mapping";
    InsertAllowed = false;
    DeleteAllowed = true;
    layout
    {
        area(Content)
        {
            repeater(repeaterName)
            {
                editable = false;
                field(TableFieldCaptionValue; TableFieldCaption)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field in Business Central.';
                }
                field(IntegrationTableFieldCaptionValue; IntTableFieldCaption)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Caption = 'Integration Field Name';
                    ToolTip = 'Specifies the name of the integration field to map to the Business Central field.';

                }
                field(Direction; Rec."Direction")
                {
                    ToolTip = 'Specifies the synchronization direction.';
                }
                field(ConstValue; Rec."Const Value")
                {
                    ToolTip = 'Specifies the constant value that the mapped field will be set to.';
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ToolTip = 'Specifies a rule for transforming imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365.';
                }
                field(ValidateField; Rec."Validate Field")
                {
                    ToolTip = 'Specifies if the field should be validated during assignment.';
                }
                field(ValidateIntegrTableField; Rec."Validate Integr. Table Field")
                {
                    ToolTip = 'Specifies if the field should be validated during assignment in the integration table.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetFieldCaptions();
    end;

    var
        TypeHelper: Codeunit "Type Helper";
        TableFieldCaption: Text;
        IntTableFieldCaption: Text;

    local procedure GetFieldCaptions()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(Rec.Name);
        TableFieldCaption := GetFieldCaption(IntegrationTableMapping."Table ID", Rec."Table Field No.");
        IntTableFieldCaption := GetFieldCaption(IntegrationTableMapping."Integration Table ID", Rec."Integration Table Field No.");
    end;

    local procedure GetFieldCaption(TableID: Integer; FieldID: Integer): Text
    var
        "Field": Record "Field";
    begin
        if (TableID <> 0) and (FieldID <> 0) then
            if TypeHelper.GetField(TableID, FieldID, Field) then
                exit(Field."Field Caption");
        exit('');
    end;
}