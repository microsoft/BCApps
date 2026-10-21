// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

page 3333 "Payables Agent Tasks"
{
    Caption = 'Payables Agent Tasks';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
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
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the task.';
                }
                field(Source; Rec."Source Description")
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies what the task came from, such as an email or a PDF file.';
                }
                field(Result; Rec."Result Description")
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
                        LoadCurrentTask(PATask);
                        Presentation.OpenSourceEmail(PATask);
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
                        LoadCurrentTask(PATask);
                        Presentation.DownloadSourcePdf(PATask);
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
                        LoadCurrentTask(PATask);
                        Presentation.OpenSourcePdf(PATask);
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
                    LoadCurrentTask(PATask);
                    Presentation.OpenSource(PATask);
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
                    LoadCurrentTask(PATask);
                    Presentation.OpenOutcome(PATask);
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
                    PATask: Codeunit "Payables Agent Task";
                    PARegisterOutcome: Page "PA Register Outcome";
                begin
                    LoadCurrentTask(PATask);
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
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := PayablesAgent.IsPayablesAgentSession(AgentTaskID);
        // TODOPAV1V2
        IsAgentSession := true;
        if not TasksSupplied then
            Presentation.GetTasks(Rec);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        AgentTaskStatusHidden := not Rec."Has Agent Task";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsEmailSourced := Rec."Source Type" = Rec."Source Type"::Email;
        IsPdfSourced := Rec."Has Pdf";
        HasSource := IsEmailSourced or IsPdfSourced;
        HasOutcome := Rec.Outcome.TableNo <> 0;
        EmailWebLink := '';
        if IsEmailSourced then begin
            LoadCurrentTask(PATask);
            EmailWebLink := Presentation.GetEmailWebLink(PATask);
        end;
        HasEmailWebLink := EmailWebLink <> '';
    end;

    internal procedure SetTasks(var TempTasks: Record "PA Detailed Task" temporary)
    begin
        Rec.Copy(TempTasks, true);
        TasksSupplied := true;
    end;

    local procedure RefreshCurrentTask()
    begin
        LoadCurrentTask(PATask);
        PATask.Refresh();
        Presentation.PopulateListRow(Rec, PATask);
        Rec.Modify();
        CurrPage.Update(false);
    end;

    local procedure LoadCurrentTask(var Task: Codeunit "Payables Agent Task")
    begin
        if not Task.Load(Rec."Task Id") then
            Error(TaskNotFoundErr);
    end;

    var
        PATask: Codeunit "Payables Agent Task";
        Presentation: Codeunit "PA Task Presentation";
        TasksSupplied: Boolean;
        TaskNotFoundErr: Label 'The task does not exist.';
        EmailWebLink: Text;
        IsAgentSession: Boolean;
        IsEmailSourced: Boolean;
        IsPdfSourced: Boolean;
        HasSource: Boolean;
        HasOutcome: Boolean;
        HasEmailWebLink: Boolean;
        AgentTaskStatusHidden: Boolean;
}
