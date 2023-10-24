// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;
using System.Visualization;

page 1998 "Dup. Guided Experience Cleanup"
{
    ApplicationArea = All;
    Caption = 'Duplicated Guided Experience Item Cleanup';
    UsageCategory = Administration;
    SourceTableTemporary = true;
    SourceTable = "Guided Experience Item";
    Extensible = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            label(PageInformation)
            {
                Caption = 'This page provides an overview of duplicated guided experience items.';
            }
            repeater(DuplicatedGuidedExperienceItem)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code of the Guided Experience Item.';
                }
                field(Count; NumberOfRecords)
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
                Caption = 'Delete';
                ToolTip = 'Delete duplicated records for the selected Guided Experience Item.';
                Image = Delete;

                trigger OnAction()
                var
                    TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
                    GuidedExperienceImpl: Codeunit "Guided Experience Impl.";
                    SelectedGuidedExperienceItemCode: Code[300];
                begin
                    CurrPage.SetSelectionFilter(TempGuidedExperienceItem);

                    SelectedGuidedExperienceItemCode := CopyStr(TempGuidedExperienceItem.GetFilter(Code), 1, 300);
                    if SelectedGuidedExperienceItemCode = '' then
                        Error('Guided Experience Item can only by select once at a time.');

                    if Dialog.Confirm(LongRunningOperationQst, false) then
                        GuidedExperienceImpl.DeleteDuplicatedGuidedExperienceItems(SelectedGuidedExperienceItemCode);
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
            action(TestInsert1)
            {
                ApplicationArea = All;
                Caption = 'Test Insert 1';
                ToolTip = 'Test insert lots of Guided Experience Items.';
                Image = Insert;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    Limit, Counter : Integer;
                begin
                    Limit := 1000;
                    for Counter := 1 to Limit do
                        GuidedExperience.InsertManualSetup('Title', Format(Counter), '', 0, ObjectType::Page, Page::"Advanced Settings", Enum::"Manual Setup Category"::Uncategorized, '');
                end;
            }
            action(TestInsert2)
            {
                ApplicationArea = All;
                Caption = 'Test Insert 2';
                ToolTip = 'Test insert lots of Guided Experience Items.';
                Image = Insert;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    Limit, Counter : Integer;
                begin
                    Limit := 1000;
                    for Counter := 1 to Limit do
                        GuidedExperience.InsertManualSetup('Title', Format(Counter), '', 0, ObjectType::Page, Page::"Cue Setup Administrator", Enum::"Manual Setup Category"::Uncategorized, '');
                end;
            }
            action(TestInsert3)
            {
                ApplicationArea = All;
                Caption = 'Test Insert 3';
                ToolTip = 'Test insert lots of Guided Experience Items.';
                Image = Insert;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    Limit, Counter : Integer;
                begin
                    Limit := 1000;
                    for Counter := 1 to Limit do
                        GuidedExperience.InsertManualSetup('Title', Format(Counter), '', 0, ObjectType::Page, Page::"App Setup List", Enum::"Manual Setup Category"::Uncategorized, '');
                end;
            }
        }
    }

    var
        NumberOfRecords: Integer;
        LongRunningOperationQst: Label 'This operation may take a long time to execute, are you sure you want to proceed?';

    trigger OnAfterGetRecord()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        GuidedExperienceItem.SetRange(Code, Rec.Code);
        NumberOfRecords := GuidedExperienceItem.Count();
    end;

    local procedure LoadDuplicatedGuidedExperienceItems()
    var
        GuidedExperienceImpl: Codeunit "Guided Experience Impl.";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        GuidedExperienceImpl.GetDuplicatedGuidedExperienceItems(Rec, 100);
        if Rec.FindFirst() then; // set focus on the first row
    end;
}