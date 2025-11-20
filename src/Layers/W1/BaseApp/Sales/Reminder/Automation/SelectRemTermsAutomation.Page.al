// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6754 "Select Rem. Terms Automation"
{
    PageType = StandardDialog;
    SourceTable = "Reminder Terms";
    Caption = 'Select reminder terms';
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Selected; Selected)
                {
                    ApplicationArea = All;
                    Caption = 'Selected';
                    ToolTip = 'Specifies whether the reminder term is included in the selection for the automation of the reminder terms job';

                    trigger OnValidate()
                    begin
                        if Selected then
                            if not TempSelectedReminderTerms.Get(Rec.Code) then begin
                                TempSelectedReminderTerms.TransferFields(Rec);
                                TempSelectedReminderTerms.Insert();
                            end;

                        if not Selected then
                            if TempSelectedReminderTerms.Get(Rec.Code) then begin
                                TempSelectedReminderTerms.Delete();
                                Selected := false;
                            end;
                    end;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    Editable = false;
                    ToolTip = 'Specifies the code of the reminder term';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the reminder term';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadIncludedRecords();
    end;

    local procedure LoadIncludedRecords()
    begin
        if not SearchReminderTerms.FindSet() then
            exit;

        repeat
            if not TempSelectedReminderTerms.Get(SearchReminderTerms.Code) then begin
                TempSelectedReminderTerms.TransferFields(SearchReminderTerms);
                TempSelectedReminderTerms.Insert();
            end;
        until SearchReminderTerms.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateIncluded();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateIncluded();
    end;

    local procedure UpdateIncluded()
    begin
        Selected := TempSelectedReminderTerms.Get(Rec.Code);
    end;

    internal procedure SetNewReminderTermsSelectionFilter(NewReminderTermsSelectionFilter: Text)
    begin
        if NewReminderTermsSelectionFilter <> '' then
            ReminderTermsSelectionFilter := NewReminderTermsSelectionFilter
        else
            ReminderTermsSelectionFilter := '<>*';

        SearchReminderTerms.FilterGroup(4);
        SearchReminderTerms.SetFilter(Code, ReminderTermsSelectionFilter);
        SearchReminderTerms.FilterGroup(0);
    end;

    internal procedure GetReminderTermsSelectionFilter(): Text
    var
        NewFilterText: Text;
    begin
        if not TempSelectedReminderTerms.FindFirst() then
            exit('');

        NewFilterText := TempSelectedReminderTerms.Code;
        if TempSelectedReminderTerms.Next() <> 0 then
            repeat
                NewFilterText += '|' + TempSelectedReminderTerms.Code;
            until TempSelectedReminderTerms.Next() = 0;

        exit(NewFilterText);
    end;

    var
        SearchReminderTerms: Record "Reminder Terms";
        TempSelectedReminderTerms: Record "Reminder Terms" temporary;
        ReminderTermsSelectionFilter: Text;
        Selected: Boolean;
}