// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;

page 5361 "Integration Field Mapping List"
{
    Caption = 'Integration Field Mapping List';
    DataCaptionExpression = Rec."Integration Table Mapping Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Integration Field Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                }
                field(FieldName; NAVFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in Business Central.';
                }
                field("Integration Table Field No."; Rec."Integration Table Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the field number of the integration field to map to the Business Central field.';
                }
                field(IntegrationFieldName; CRMFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the integration field to map to the Business Central field.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Suite;
                }
                field("Constant Value"; Rec."Constant Value")
                {
                    ApplicationArea = Suite;
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Transformation Direction"; Rec."Transformation Direction")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec."Direction" = Rec."Direction"::Bidirectional;
                }
                field("Validate Field"; Rec."Validate Field")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the field should be validated during assignment in Business Central. ';
                }
                field("Validate Integration Table Fld"; Rec."Validate Integration Table Fld")
                {
                    ApplicationArea = Suite;
                }
                field("Clear Value on Failed Sync"; Rec."Clear Value on Failed Sync")
                {
                    ApplicationArea = Suite;
                }
                field("Not Null"; Rec."Not Null")
                {
                    ApplicationArea = Suite;
                }
                field("User Defined"; Rec."User Defined")
                {
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetTransformationRules)
            {
                ApplicationArea = Suite;
                Caption = 'Reset Transformation Rules';
                Image = ResetStatus;
                ToolTip = 'Resets the transformation rules for the integration table mapping.';

                trigger OnAction()
                var
                    IntegrationFieldMapping: Record "Integration Field Mapping";
                begin
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Rec."Integration Table Mapping Name");
                    IntegrationFieldMapping.ModifyAll("Transformation Rule", '');
                end;
            }
            action(ManualIntTableMapping)
            {
                ApplicationArea = Suite;
                Caption = 'New Field Mapping';
                Image = New;
                ToolTip = 'Create a new integration field mapping.';
                trigger OnAction()
                var
                    IntegrationTableMapping: Record "Integration Table Mapping";
                    CDSNewManIntTableWizard: Page "CDS New Man. Int. Table Wizard";
                begin
                    IntegrationTableMapping.Get(Rec."Integration Table Mapping Name");
                    CDSNewManIntTableWizard.SetValues(IntegrationTableMapping.Name, IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID");
                    CDSNewManIntTableWizard.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ManualIntTableMapping_Promoted; ManualIntTableMapping)
                {
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
        NAVFieldName: Text;
        CRMFieldName: Text;

    local procedure GetFieldCaptions()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(Rec."Integration Table Mapping Name");
        NAVFieldName := GetFieldCaption(IntegrationTableMapping."Table ID", Rec."Field No.");
        CRMFieldName := GetFieldCaption(IntegrationTableMapping."Integration Table ID", Rec."Integration Table Field No.");
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

