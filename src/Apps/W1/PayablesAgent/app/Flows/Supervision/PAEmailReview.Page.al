// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

page 3338 "PA Email Review"
{
    Caption = 'Email Review';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "PA Detailed Task";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                Caption = 'Header';
                field(EmailFrom; EmailFrom)
                {
                    Caption = 'From';
                    ToolTip = 'Specifies the sender of the email.';
                }
                field(EmailSubject; DisplaySubject)
                {
                    Caption = 'Subject';
                    ToolTip = 'Specifies the subject of the email.';
                }
                field(EmailReceivedAt; Rec."Email Received At")
                {
                    Caption = 'Received';
                    ToolTip = 'Specifies when the email was received.';
                }
            }
            group(Body)
            {
                Caption = 'Body';
                field(EmailBody; EmailBody)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ToolTip = 'Specifies the body of the email.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EmailFrom := Rec."Email From";
        if Rec."Sender Name" <> '' then
            EmailFrom := StrSubstNo(EmailFromTxt, Rec."Sender Name", Rec."Email From");
        EmailBody := Task.GetSourceEmailBody();
        DisplaySubject := Rec."Email Subject";
        if (EmailFrom = '') and (DisplaySubject = '') and (EmailBody = '') then
            DisplaySubject := EmailNotAvailableTxt;
    end;

    var
        Task: Codeunit "Payables Agent Task";
        TaskNotFoundErr: Label 'The task does not exist.';
        EmailFrom: Text;
        EmailBody: Text;
        DisplaySubject: Text;
        EmailNotAvailableTxt: Label 'This email is no longer available.';
        EmailFromTxt: Label '%1 <%2>', Comment = '%1 = sender name, %2 = sender address';

    internal procedure SetTask(NewTask: Codeunit "Payables Agent Task")
    var
        Presentation: Codeunit "PA Task Presentation";
    begin
        // Pin this page to its own task handle rather than retain the caller's mutable wrapper.
        if not Task.Load(NewTask.GetAgentTaskId()) then
            Error(TaskNotFoundErr);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Presentation.PopulateListRow(Rec, Task);
        Rec.Insert();
    end;
}
