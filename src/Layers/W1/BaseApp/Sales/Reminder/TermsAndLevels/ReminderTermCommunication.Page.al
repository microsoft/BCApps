// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

page 1897 "Reminder Term Communication"
{
    PageType = Card;
    UsageCategory = None;
    Caption = 'Reminder Term Communication';
    SourceTable = "Reminder Terms";

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(ReminderTermCode; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Reminder Term Code';
                    ToolTip = 'Specifies the code of the reminder term for the current communications.';
                    Enabled = false;
                    Editable = false;
                }
                field("Language Code"; CurrentLanguage.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Language Code';
                    ToolTip = 'Specifies the language code of the text fields below to use when generating the reminder document and email for the customer.';

                    trigger OnDrillDown()
                    var
                        LocalLanguage: Record "Language";
                        ReminderCommunication: Codeunit "Reminder Communication";
                        Languages: Page "Languages";
                        FilterText: Text;
                    begin
                        FilterText := ReminderCommunication.GetListOfAttachmentLanguagesFromIdWithSeparator(Rec."Reminder Attachment Text", OrOperatorTok);
                        if FilterText <> '' then
                            LocalLanguage.SetFilter(Code, FilterText)
                        else
                            Error(NoLanguageTextErr);

                        Languages.SetTableView(LocalLanguage);
                        Languages.Editable := false;
                        Languages.LookupMode(true);
                        if Languages.RunModal() <> ACTION::LookupOK then
                            exit;

                        LocalLanguage.Reset();
                        Languages.SetSelectionFilter(LocalLanguage);
                        LocalLanguage.FindFirst();
                        SelectedNewLanguage := true;
                        SelectLanguageAndText(LocalLanguage.Code, false);
                    end;

                    trigger OnValidate()
                    begin
                        SelectLanguageAndText(CurrentLanguage.Code, false);
                    end;
                }
            }
            part(ReminderAttachmentTextPart; "Reminder Attachment Text")
            {
                Caption = 'Attachment Texts';
                ApplicationArea = All;
                SubPageLink = Id = field("Reminder Attachment Text");
            }
            part(ReminderEmailTextPart; "Reminder Email Text")
            {
                Caption = 'Email Texts';
                ApplicationArea = All;
                SubPageLink = Id = field("Reminder Email Text");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("View All Communications")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Overview communications';
                ToolTip = 'View all communication texts for every language for this reminder term.';
                Image = View;
                RunObject = Page "Reminder View Communication";
                RunPageLink = Id = field("Reminder Attachment Text");
            }
            action("Add New Language")
            {
                ApplicationArea = Basic, Suite;
                Image = Add;
                Caption = 'Add text for language ...';
                ToolTip = 'Choose the language to use for new communication texts with customers.';

                trigger OnAction()
                var
                    LocalLanguage: Record "Language";
                    ReminderCommunication: Codeunit "Reminder Communication";
                    Languages: Page "Languages";
                    FilterText: Text;
                begin
                    FilterText := ReminderCommunication.GetListOfAttachmentLanguagesFromIdWithSeparator(Rec."Reminder Attachment Text", DifferentOperatorTok);
                    if FilterText <> '' then
                        LocalLanguage.SetFilter(Code, StrSubstNo('<>%1', FilterText));

                    Languages.SetTableView(LocalLanguage);
                    Languages.Editable := false;
                    Languages.LookupMode(true);
                    if Languages.RunModal() <> ACTION::LookupOK then
                        exit;

                    LocalLanguage.Reset();
                    Languages.SetSelectionFilter(LocalLanguage);
                    LocalLanguage.FindFirst();

                    // Necessary when the user has deleted all languages or has not created any language yet
                    if IsNullGuid(Rec."Reminder Attachment Text") then
                        ReminderCommunication.SetDefaultContentForNewLanguage(CreateGuid(), LocalLanguage.Code, Enum::"Reminder Text Source Type"::"Reminder Term", Rec.SystemId);

                    SelectedNewLanguage := true;
                    SelectLanguageAndText(LocalLanguage.Code, true);
                end;
            }
            action("Remove Language")
            {
                ApplicationArea = Basic, Suite;
                Image = CancelLine;
                Enabled = RemoveEnabled;
                Caption = 'Remove current language';
                ToolTip = 'Remove the communications texts created for the current language.';

                trigger OnAction()
                var
                    ReminderAttachmentText: Record "Reminder Attachment Text";
                    ReminderEmailText: Record "Reminder Email Text";
                begin
                    if not Confirm(StrSubstNo(RemoveLanguageQst, CurrentLanguage.Code)) then
                        exit;

                    if ReminderAttachmentText.Get(Rec."Reminder Attachment Text", CurrentLanguage.Code) then begin
                        ReminderAttachmentText.Delete(true);
                        SelectedNewLanguage := false;
                    end;

                    if ReminderEmailText.Get(Rec."Reminder Email Text", CurrentLanguage.Code) then begin
                        ReminderEmailText.Delete(true);
                        SelectedNewLanguage := false;
                    end;

                    ReminderAttachmentText.Reset();
                    ReminderAttachmentText.SetRange(Id, Rec."Reminder Attachment Text");
                    if ReminderAttachmentText.IsEmpty() then begin
                        Clear(rec);
                        CurrPage.Close()
                    end else
                        CurrPage.Update();
                end;
            }
            action("Remove All Languages")
            {
                ApplicationArea = Basic, Suite;
                Image = CancelAllLines;
                Enabled = RemoveEnabled;
                Caption = 'Remove all languages';
                ToolTip = 'Remove all communication texts for every language for this reminder term.';

                trigger OnAction()
                var
                    ReminderAttachmentText: Record "Reminder Attachment Text";
                    ReminderEmailText: Record "Reminder Email Text";
                begin
                    if not Confirm(RemoveAllLanguagesQst) then
                        exit;

                    ReminderAttachmentText.SetRange(Id, Rec."Reminder Attachment Text");
                    if not ReminderAttachmentText.IsEmpty() then
                        ReminderAttachmentText.DeleteAll(true);

                    ReminderEmailText.SetRange(Id, Rec."Reminder Email Text");
                    if not ReminderEmailText.IsEmpty() then
                        ReminderEmailText.DeleteAll(true);

                    Clear(rec);
                    CurrPage.Close();
                end;
            }
            action("Select Report Layout")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select report layout';
                Image = PrintChecklistReport;
                RunObject = Page "Report Selection - Reminder";
                RunPageMode = View;
                Tooltip = 'Select a report layout for the reminder communications.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("View All Communications_Promoted"; "View All Communications")
                {
                }
                actionref("Add New Language_Promoted"; "Add New Language")
                {
                }
                actionref("Remove Language_Promoted"; "Remove Language")
                {
                }
                actionref("Remove All Languages_Promoted"; "Remove All Languages")
                {
                }
                actionref("Select Report Layout_Promoted"; "Select Report Layout")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
        LocalGuid: Guid;
    begin
        if IsNullGuid(Rec."Reminder Attachment Text") then
            RemoveEnabled := false
        else
            RemoveEnabled := true;

        // Check if it exist an ID to either Reminder Attachment Text or Reminder Email Text. If not, create a new one.
        if not IsNullGuid(Rec."Reminder Attachment Text") then
            LocalGuid := Rec."Reminder Attachment Text";

        if not IsNullGuid(Rec."Reminder Email Text") then
            LocalGuid := Rec."Reminder Email Text";

        if IsNullGuid(LocalGuid) then
            LocalGuid := CreateGuid();

        // Check if the Reminder Attachment Text and Reminder Email Text has a value. If not, ask the customer to create a new one with the default content.
        if IsNullGuid(Rec."Reminder Attachment Text") and IsNullGuid(Rec."Reminder Email Text") then
            if Confirm(ConfirmDefaultCreationofCommunicationTextMsg) then begin
                ReminderAttachmentText.SetDefaultContentForNewLanguage(LocalGuid, Enum::"Reminder Text Source Type"::"Reminder Term");
                ReminderEmailText.SetDefaultContentForNewLanguage(LocalGuid, Enum::"Reminder Text Source Type"::"Reminder Term");
                Rec."Reminder Attachment Text" := LocalGuid;
                Rec."Reminder Email Text" := LocalGuid;
                Rec.Modify(true);
            end;

        if SelectedNewLanguage then
            exit;

        ReminderAttachmentText.SetRange(Id, Rec."Reminder Attachment Text");
        if ReminderAttachmentText.FindFirst() then
            SelectLanguageForSubpages(ReminderAttachmentText.Id);
    end;

    var
        CurrentLanguage: Record "Language";
        SelectedNewLanguage, RemoveEnabled : Boolean;
        OrOperatorTok: Label '%1|%2', Locked = true;
        DifferentOperatorTok: Label '%1&<>%2', Locked = true;
        NoLanguageTextErr: Label 'There are no communication texts for this reminder term for any language. Add a new entry if you want to personalize the communication with the customer.';
        NoTextForSelectedLanguageErr: Label 'There are no communication texts for the selected language %1. Add a new entry if you want to personalize the communication with the customer.', Comment = '%1 = Language Code';
        RemoveLanguageQst: Label 'Do you want to remove the communication texts for the selected language? This would remove the attachment texts and the email texts for language %1.', Comment = '%1 = Language Code';
        RemoveAllLanguagesQst: Label 'Do you want to remove all communication texts for all languages?';
        ConfirmDefaultCreationofCommunicationTextMsg: Label 'There are no communication texts for this reminder term. Do you want to create a new communication text for your current language?';


    internal procedure SelectLanguageForSubpages(Id: Guid)
    var
        ReminderCommunication: Codeunit "Reminder Communication";
        FilterText: Text;
    begin
        FilterText := ReminderCommunication.GetListOfAttachmentLanguagesFromIdWithSeparator(Id, OrOperatorTok);
        if FilterText <> '' then
            CurrentLanguage.SetFilter(Code, FilterText)
        else
            Error(NoLanguageTextErr);

        if not CurrentLanguage.IsEmpty() then begin
            CurrentLanguage.FindFirst();
            SelectLanguageAndText(CurrentLanguage.Code, false);
        end;
    end;

    internal procedure SelectLanguageAndText(LanguageCode: Code[10]; CreateNewEntry: Boolean)
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderEmailText: Record "Reminder Email Text";
    begin
        if LanguageCode = '' then
            exit;

        CurrentLanguage.SetRange(Code, LanguageCode);
        CurrentLanguage.FindFirst();

        if not ReminderAttachmentText.Get(Rec."Reminder Attachment Text", CurrentLanguage.Code) then
            if CreateNewEntry then begin
                ReminderAttachmentText.SetDefaultContentForNewLanguage(Rec."Reminder Attachment Text", CurrentLanguage.Code, Enum::"Reminder Text Source Type"::"Reminder Term");
                ReminderEmailText.SetDefaultContentForNewLanguage(Rec."Reminder Email Text", CurrentLanguage.Code, Enum::"Reminder Text Source Type"::"Reminder Term");
            end
            else
                Error(NoTextForSelectedLanguageErr, CurrentLanguage.Code);

        CurrPage.Update(false);
        CurrPage.ReminderAttachmentTextPart.Page.SetSourceDataAsTerm(CurrentLanguage.Code);
        CurrPage.ReminderEmailTextPart.Page.SetSourceData(CurrentLanguage.Code);
    end;
}