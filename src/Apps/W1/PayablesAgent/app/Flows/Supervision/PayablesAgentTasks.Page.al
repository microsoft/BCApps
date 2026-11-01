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
                field(AgentTaskId; Rec."Agent Task ID")
                {
                    Caption = 'Agent Task No.';
                    ToolTip = 'Specifies the number of the agent task that works on this task.';
                    Editable = false;
                    ExtendedDatatype = Task;
                    BlankNumbers = BlankZero;

                    trigger OnDrillDown()
                    begin
                        Presentation.OpenAgentTask(Rec."Agent Task ID");
                    end;
                }
                field("Agent Task Status"; Rec."Agent Task Status")
                {
                    HideValue = AgentTaskStatusHidden;
                    ToolTip = 'Specifies the status of the agent task that works on this task.';
                }
                field("Intake Status"; Rec."Intake Status")
                {
                    ToolTip = 'Specifies whether the received source was accepted as an agent task or rejected during intake.';
                }
                field("Rejection Reason"; Rec."Rejection Reason")
                {
                    ToolTip = 'Specifies why the received source was rejected during intake.';
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

                action(UploadPdf)
                {
                    Caption = 'Upload';
                    ToolTip = 'Upload a PDF invoice to create a new task for the payables agent.';
                    Image = Import;
                    Visible = CanUploadPdf;

                    trigger OnAction()
                    begin
                        UploadPdfForAgent();
                    end;
                }
                action(DownloadPdf)
                {
                    Caption = 'Download';
                    ToolTip = 'Download the PDF file of the task.';
                    Image = Download;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    begin
                        LoadCurrentTask(PATask);
                        PATask.GetSource(TaskSource);
                        Presentation.DownloadSourcePdf(TaskSource);
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
                        PATask.GetSource(TaskSource);
                        Presentation.OpenSourcePdf(TaskSource);
                    end;
                }
            }
            action(RefreshTasks)
            {
                Caption = 'Refresh';
                ToolTip = 'Reload the latest state of the payables agent tasks.';
                Image = Refresh;

                trigger OnAction()
                begin
                    ReloadTasks();
                end;
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
                    if AgentExperience.IsActive() and PATask.CanExtractText() then
                        AgentExperience.ShowSourceText(PATask)
                    else
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
            group(Agent)
            {
                Caption = 'Agent';
                Image = Sparkle;
                Visible = UseAgentExperience;

                action(ExtractSourceText)
                {
                    Caption = 'Retrigger extraction';
                    ToolTip = 'Extract the source PDF text again, replacing existing extracted text after confirmation.';
                    Image = SparkleFilled;
                    Enabled = CanExtractSourceText;

                    trigger OnAction()
                    begin
                        LoadCurrentTask(PATask);
                        AgentExperience.ExtractSourceText(PATask);
                        RefreshCurrentTask();
                    end;
                }
                action(RegisterOutcome)
                {
                    Caption = 'Register outcome';
                    ToolTip = 'Register the purchase document that is the outcome of the task.';
                    Image = Approve;
                    Enabled = CanRegisterOutcome;

                    trigger OnAction()
                    var
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
        }
        area(Prompting)
        {
            action(UploadPdfPrompting)
            {
                ApplicationArea = All;
                Caption = 'New from PDF';
                ToolTip = 'Upload a PDF invoice to create a new task for the payables agent.';
                Image = Sparkle;
                Visible = CanUploadPdf;

                trigger OnAction()
                begin
                    UploadPdfForAgent();
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

                actionref(UploadPdf_Promoted; UploadPdf)
                {
                }
                actionref(DownloadPdf_Promoted; DownloadPdf)
                {
                }
                actionref(ViewPdf_Promoted; ViewPdf)
                {
                }
            }
            actionref(RefreshTasks_Promoted; RefreshTasks)
            {
            }
            actionref(OpenSource_Promoted; OpenSource)
            {
            }
            actionref(OpenOutcome_Promoted; OpenOutcome)
            {
            }
            group(Agent_Promoted)
            {
                Caption = 'Agent';
                Visible = UseAgentExperience;

                actionref(ExtractSourceText_Promoted; ExtractSourceText)
                {
                }
                actionref(RegisterOutcome_Promoted; RegisterOutcome)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UseAgentExperience := AgentExperience.IsActive();
        CanUploadPdf := PAAgentAccess.CanShowAgentActions();
        RebuildRows();
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        AgentTaskStatusHidden := not Rec."Has Agent Task";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsEmailSourced := Rec."Has Agent Task" and (Rec."Source Type" = Rec."Source Type"::Email);
        IsPdfSourced := Rec."Has Agent Task" and Rec."Has Pdf";
        HasSource := IsEmailSourced or IsPdfSourced;
        HasOutcome := Rec."Has Agent Task" and (Rec.Outcome.TableNo <> 0);
        CanExtractSourceText := Rec."Has Agent Task" and Rec."Can Extract Text";
        CanRegisterOutcome := Rec."Has Agent Task" and Rec."Can Register Outcome";
        EmailWebLink := '';
        if IsEmailSourced then begin
            LoadCurrentTask(PATask);
            PATask.GetSource(TaskSource);
            EmailWebLink := Presentation.GetEmailWebLink(TaskSource);
        end;
        HasEmailWebLink := EmailWebLink <> '';
    end;

    var
        PATask: Codeunit "Payables Agent Task";
        Presentation: Codeunit "PA Task Presentation";
        AgentExperience: Codeunit "PA Agent Experience";
        PAAgentAccess: Codeunit "PA Agent Access";
        TaskSource: Codeunit "PA Task Source";
        HasStateScope: Boolean;
        ScopeState: Enum "PA Task State";
        TaskNotFoundErr: Label 'The task does not exist.';
        EmailWebLink: Text;
        UseAgentExperience: Boolean;
        IsEmailSourced: Boolean;
        IsPdfSourced: Boolean;
        HasSource: Boolean;
        HasOutcome: Boolean;
        HasEmailWebLink: Boolean;
        CanUploadPdf: Boolean;
        CanExtractSourceText: Boolean;
        CanRegisterOutcome: Boolean;
        AgentTaskStatusHidden: Boolean;

    internal procedure OpenByState(State: Enum "PA Task State")
    begin
        HasStateScope := true;
        ScopeState := State;
    end;

    local procedure RebuildRows()
    var
        TempSavedView: Record "PA Detailed Task" temporary;
    begin
        TempSavedView.Copy(Rec);
        if HasStateScope then
            Presentation.LoadRowsByState(ScopeState, Rec)
        else
            Presentation.LoadAllRows(Rec);
        Rec.Copy(TempSavedView);
        Rec.Init();
        Rec."Entry No." := 0;
    end;

    local procedure ReloadTasks()
    var
        CurrentAgentTaskId: BigInteger;
        CurrentSourceId: Guid;
    begin
        if Rec."Has Agent Task" then
            CurrentAgentTaskId := Rec."Agent Task ID";
        CurrentSourceId := Rec."Source Id";
        RebuildRows();
        if not SelectRow(CurrentAgentTaskId, CurrentSourceId) then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure SelectRow(SelectedAgentTaskId: BigInteger; SourceId: Guid): Boolean
    var
        TempVisibleRow: Record "PA Detailed Task" temporary;
    begin
        TempVisibleRow.Copy(Rec, true);
        if TempVisibleRow.FindSet() then
            repeat
                if ((SelectedAgentTaskId <> 0) and TempVisibleRow."Has Agent Task" and (TempVisibleRow."Agent Task ID" = SelectedAgentTaskId)) or
                   ((SelectedAgentTaskId = 0) and (TempVisibleRow."Source Id" = SourceId)) then begin
                    Rec := TempVisibleRow;
                    exit(true);
                end;
            until TempVisibleRow.Next() = 0;
        exit(false);
    end;

    local procedure RefreshCurrentTask()
    begin
        ReloadTasks();
    end;

    local procedure UploadPdfForAgent()
    var
        TaskUpload: Codeunit "PA Task Upload";
        UploadedSource: Codeunit "PA Task Source";
        SourceId: Guid;
    begin
        if not TaskUpload.UploadInvoiceWithAgent(SourceId) then
            exit;
        ReloadTasks();
        if SelectRow(0, SourceId) then
            CurrPage.Update(false)
        else
            if UploadedSource.Load(SourceId) then
                if UploadedSource.GetAgentTaskId() <> 0 then
                    Presentation.OpenAgentTask(UploadedSource.GetAgentTaskId());
    end;

    local procedure LoadCurrentTask(var Task: Codeunit "Payables Agent Task")
    begin
        if not Task.Load(Rec."Agent Task ID") then
            Error(TaskNotFoundErr);
    end;
}
