// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

page 1998 "Guided Experience Item Cleanup"
{
    ApplicationArea = All;
    Caption = 'Duplicated Guided Experience Item Cleanup';
    SourceTableTemporary = true;
    SourceTable = "Guided Experience Item";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            label(PageInformation)
            {
                Caption = 'This page provides an overview of duplicated guided experience items. You can either delete individual items or schedule a daily job queue to clean up all duplicated items.';
            }
            repeater(DuplicatedGuidedExperienceItem)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code of the Guided Experience Item.';
                }
                field(Count; GetNumberOfDuplicatedItems(Rec.Code))
                {
                    Caption = 'Number of Records';
                    ToolTip = 'Specifies the number of Guided Experience Items with the same code.';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(LoadDuplicatedItems_Promoted; LoadDuplicatedItems)
            {
            }
            actionref(Cleanup_Promoted; Delete)
            {
            }
        }
        area(Processing)
        {
            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete Duplicates';
                ToolTip = 'Delete duplicated records for the selected Guided Experience Item.';
                Image = Delete;

                trigger OnAction()
                var
                    TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
                    GuidedExperienceItemCleanup: Codeunit "Guided Experience Item Cleanup";
                    SelectedGuidedExperienceItemCode: Code[300];
                begin
                    CurrPage.SetSelectionFilter(TempGuidedExperienceItem);

                    SelectedGuidedExperienceItemCode := CopyStr(TempGuidedExperienceItem.GetFilter(Code), 1, 300);
                    if SelectedGuidedExperienceItemCode = '' then
                        Error(MoreThanOneSelectionErr);

                    if Dialog.Confirm(LongRunningOperationQst, false) then
                        GuidedExperienceItemCleanup.DeleteDuplicatedGuidedExperienceItems(SelectedGuidedExperienceItemCode);
                end;
            }
            action(LoadDuplicatedItems)
            {
                ApplicationArea = All;
                Caption = 'Load or Refresh Duplicated Items';
                ToolTip = 'Load or Refresh duplicated Guided Experience Items.';
                Image = Refresh;

                trigger OnAction()
                begin
                    LoadDuplicatedGuidedExperienceItems();
                end;
            }
        }
    }

    var
        LongRunningOperationQst: Label 'This operation may take a long time to execute, are you sure you want to proceed?';
        MoreThanOneSelectionErr: Label 'Only one Guided Experience Item can be selected at a time.';

    local procedure GetNumberOfDuplicatedItems(ItemCode: Code[300]): Integer
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        GuidedExperienceItem.SetLoadFields(Code, Version);
        GuidedExperienceItem.SetRange(Code, ItemCode);
        exit(GuidedExperienceItem.Count());
    end;

    local procedure LoadDuplicatedGuidedExperienceItems()
    var
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        GuidedExperienceImpl: Codeunit "Guided Experience Item Cleanup";
    begin
        Rec.DeleteAll();
        GuidedExperienceImpl.GetDuplicatedGuidedExperienceItems(TempGuidedExperienceItem, 100);

        if TempGuidedExperienceItem.IsEmpty() then
            exit;

        Rec.Copy(TempGuidedExperienceItem, true);
        if Rec.FindFirst() then; // set focus on the first row
        CurrPage.Update();
    end;
}