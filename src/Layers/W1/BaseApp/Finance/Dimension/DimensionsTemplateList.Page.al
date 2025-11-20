// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 1343 "Dimensions Template List"
{
    Caption = 'Dimension Templates';
    PageType = List;
    SourceTable = "Dimensions Template";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the default dimension.';
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
                }
                field("<Dimension Value Code>"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        TempDimensionsTemplate: Record "Dimensions Template" temporary;
        MasterRecordCodeFilter: Text;
        MasterRecordCodeWithRightLenght: Code[10];
        TableFilterId: Text;
        TableID: Integer;
    begin
        MasterRecordCodeFilter := Rec.GetFilter("Master Record Template Code");
        TableFilterId := Rec.GetFilter("Table Id");

        if (MasterRecordCodeFilter = '') or (TableFilterId = '') then
            Error(CannotRunPageDirectlyErr);

        MasterRecordCodeWithRightLenght := CopyStr(MasterRecordCodeFilter, 1, 10);
        Evaluate(TableID, TableFilterId);

        TempDimensionsTemplate.InitializeTemplatesFromMasterRecordTemplate(MasterRecordCodeWithRightLenght, Rec, TableID);
    end;

    var
        CannotRunPageDirectlyErr: Label 'This page cannot be run directly. You must open it with the action on the appropriate page.';
}

