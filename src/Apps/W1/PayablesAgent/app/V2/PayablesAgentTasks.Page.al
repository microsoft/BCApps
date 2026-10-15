// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

/// <summary>
/// Lists Payables Agent v2 tasks with what they came from and what they produced.
/// In a Payables Agent session only the task bound to the session's agent task is listed.
/// </summary>
page 3333 "Payables Agent Tasks"
{
    Caption = 'Payables Agent Tasks';
    PageType = List;
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
    Permissions = tabledata "Agent Task" = r;

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field(Name; TaskName)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the task.';
                }
                field(Source; SourceDescription)
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies what the task came from, such as an email or a PDF file.';
                }
                field(Result; ResultDescription)
                {
                    Caption = 'Result';
                    ToolTip = 'Specifies the record that was registered as the outcome of the task.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the vendor of the purchase invoice that was registered as the outcome of the task.';
                }
                field("Agent Task Status"; Rec."Agent Task Status")
                {
                    HideValue = AgentTaskStatusHidden;
                    ToolTip = 'Specifies the status of the agent task that works on this task.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Email)
            {
                Caption = 'Email';
                Image = Email;

                action(OpenEmail)
                {
                    Caption = 'Open email';
                    ToolTip = 'Open the email that the task came from.';
                    Image = Email;
                    Enabled = IsEmailSourced;

                    trigger OnAction()
                    begin
                        Rec.OpenSourceEmail();
                    end;
                }
                action(OpenEmailExternally)
                {
                    Caption = 'Open externally';
                    ToolTip = 'Open the email that the task came from in Outlook on the web.';
                    Image = Web;
                    Enabled = HasEmailWebLink;

                    trigger OnAction()
                    begin
                        Hyperlink(EmailWebLink);
                    end;
                }
            }
            group(Pdf)
            {
                Caption = 'PDF';
                Image = Document;

                action(DownloadPdf)
                {
                    Caption = 'Download';
                    ToolTip = 'Download the PDF file of the task.';
                    Image = Download;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    begin
                        Rec.DownloadSourcePdf();
                    end;
                }
                action(ViewPdf)
                {
                    Caption = 'View';
                    ToolTip = 'View the PDF file of the task.';
                    Image = View;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    begin
                        Rec.OpenSourcePdf();
                    end;
                }
            }
            action(OpenSource)
            {
                Caption = 'Open source';
                ToolTip = 'Open what the task came from. A task that came from an email opens the email.';
                Image = Navigate;
                Enabled = HasSource;

                trigger OnAction()
                begin
                    Rec.OpenSource();
                end;
            }
            action(OpenOutcome)
            {
                Caption = 'Open outcome';
                ToolTip = 'Open the record that was registered as the outcome of the task.';
                Image = ViewDetails;
                Enabled = HasOutcome;

                trigger OnAction()
                begin
                    Rec.OpenOutcome();
                end;
            }
            action(RegisterOutcome)
            {
                Caption = 'Register outcome';
                ToolTip = 'Register the purchase document that is the outcome of the task.';
                Image = Approve;
                Visible = IsAgentSession;

                trigger OnAction()
                var
                    PATask: Codeunit "PA Task";
                    PARegisterOutcome: Page "PA Register Outcome";
                begin
                    Rec.GetTask(PATask);
                    PARegisterOutcome.SetTask(PATask);
                    if PARegisterOutcome.RunModal() <> Action::OK then
                        exit;
                    RefreshCurrentTask();
                end;
            }
        }
        area(Promoted)
        {
            group(Email_Promoted)
            {
                Caption = 'Email';

                actionref(OpenEmail_Promoted; OpenEmail)
                {
                }
                actionref(OpenEmailExternally_Promoted; OpenEmailExternally)
                {
                }
            }
            group(Pdf_Promoted)
            {
                Caption = 'PDF';

                actionref(DownloadPdf_Promoted; DownloadPdf)
                {
                }
                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
            }
            actionref(OpenSource_Promoted; OpenSource)
            {
            }
            actionref(OpenOutcome_Promoted; OpenOutcome)
            {
            }
            actionref(RegisterOutcome_Promoted; RegisterOutcome)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        PayablesAgent: Codeunit "Payables Agent";
        PATaskCollection: Codeunit "PA Task Collection";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := PayablesAgent.IsPayablesAgentSession(AgentTaskID);
        PATaskCollection.GetTasks(Rec);
        if Rec.FindSet() then
            repeat
                ResolveDetails();
            until Rec.Next() = 0;
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        if not TaskNames.Get(Rec."Entry No.", TaskName) then
            TaskName := '';
        if not SourceDescriptions.Get(Rec."Entry No.", SourceDescription) then
            SourceDescription := '';
        if not ResultDescriptions.Get(Rec."Entry No.", ResultDescription) then
            ResultDescription := '';
        AgentTaskStatusHidden := not EntriesWithAgentTask.Contains(Rec."Entry No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsEmailSourced := Rec."Source Type" = Rec."Source Type"::Email;
        IsPdfSourced := Rec."Has Pdf";
        HasSource := IsEmailSourced or IsPdfSourced;
        HasOutcome := Rec.Outcome.TableNo <> 0;
        EmailWebLink := '';
        if IsEmailSourced then
            EmailWebLink := Rec.GetSourceEmailWebLink();
        HasEmailWebLink := EmailWebLink <> '';
    end;

    local procedure RefreshCurrentTask()
    begin
        Rec.Refresh();
        Rec.Modify();
        ResolveDetails();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Resolves the displayed values of the current Rec that are not columns of the task record.
    /// </summary>
    local procedure ResolveDetails()
    var
        AgentTask: Record "Agent Task";
    begin
        if EntriesWithAgentTask.Contains(Rec."Entry No.") then
            EntriesWithAgentTask.Remove(Rec."Entry No.");
        if Rec."Agent Task ID" <> 0 then
            if AgentTask.Get(Rec."Agent Task ID") then
                EntriesWithAgentTask.Add(Rec."Entry No.");
        if AgentTask.Title <> '' then
            TaskNames.Set(Rec."Entry No.", AgentTask.Title)
        else
            TaskNames.Set(Rec."Entry No.", StrSubstNo(TaskNameTxt, Rec."Entry No."));
        SourceDescriptions.Set(Rec."Entry No.", Rec.DescribeSource());
        ResultDescriptions.Set(Rec."Entry No.", Rec.DescribeOutcome());
    end;

    var
        TaskNames: Dictionary of [BigInteger, Text];
        SourceDescriptions: Dictionary of [BigInteger, Text];
        ResultDescriptions: Dictionary of [BigInteger, Text];
        EntriesWithAgentTask: List of [BigInteger];
        TaskName: Text;
        SourceDescription: Text;
        ResultDescription: Text;
        EmailWebLink: Text;
        IsAgentSession: Boolean;
        IsEmailSourced: Boolean;
        IsPdfSourced: Boolean;
        HasSource: Boolean;
        HasOutcome: Boolean;
        HasEmailWebLink: Boolean;
        AgentTaskStatusHidden: Boolean;
        TaskNameTxt: Label 'Task %1', Comment = '%1 = task entry number';
}
