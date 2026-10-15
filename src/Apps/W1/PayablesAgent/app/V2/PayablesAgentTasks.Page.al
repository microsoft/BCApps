// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
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
                    var
                        PATaskMgt: Codeunit "PA Task Mgt.";
                    begin
                        PATaskMgt.OpenSourceEmail(GetPayablesAgentTask());
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
                    var
                        PATaskMgt: Codeunit "PA Task Mgt.";
                    begin
                        PATaskMgt.DownloadSourcePdf(GetPayablesAgentTask());
                    end;
                }
                action(ViewPdf)
                {
                    Caption = 'View';
                    ToolTip = 'View the PDF file of the task.';
                    Image = View;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    var
                        PATaskMgt: Codeunit "PA Task Mgt.";
                    begin
                        PATaskMgt.OpenSourcePdf(GetPayablesAgentTask());
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
                var
                    PATaskMgt: Codeunit "PA Task Mgt.";
                begin
                    PATaskMgt.OpenSource(GetPayablesAgentTask());
                end;
            }
            action(OpenOutcome)
            {
                Caption = 'Open outcome';
                ToolTip = 'Open the record that was registered as the outcome of the task.';
                Image = ViewDetails;
                Enabled = HasOutcome;

                trigger OnAction()
                var
                    PATaskMgt: Codeunit "PA Task Mgt.";
                begin
                    PATaskMgt.OpenOutcome(GetPayablesAgentTask());
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
                    PARegisterOutcome: Page "PA Register Outcome";
                begin
                    PARegisterOutcome.SetTask(GetPayablesAgentTask());
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
        PayablesAgentTask: Record "Payables Agent Task";
        PayablesAgent: Codeunit "Payables Agent";
        PATaskMgt: Codeunit "PA Task Mgt.";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := PayablesAgent.IsPayablesAgentSession(AgentTaskID);
        if IsAgentSession then begin
            if PATaskMgt.GetCurrentSessionTask(PayablesAgentTask) then
                InsertDetailedTask(PayablesAgentTask);
        end else
            if PayablesAgentTask.FindSet() then
                repeat
                    InsertDetailedTask(PayablesAgentTask);
                until PayablesAgentTask.Next() = 0;
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
    var
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        IsEmailSourced := Rec."Source Data No." <> 0;
        IsPdfSourced := Rec."Task Data No." <> 0;
        HasSource := IsEmailSourced or IsPdfSourced;
        HasOutcome := Rec.Outcome.TableNo <> 0;
        EmailWebLink := '';
        if IsEmailSourced then
            EmailWebLink := PATaskMgt.GetSourceEmailWebLink(GetPayablesAgentTask());
        HasEmailWebLink := EmailWebLink <> '';
    end;

    local procedure InsertDetailedTask(PayablesAgentTask: Record "Payables Agent Task")
    begin
        Rec.Init();
        Rec.TransferFields(PayablesAgentTask);
        ResolveDetails(PayablesAgentTask);
        Rec.Insert();
    end;

    local procedure RefreshCurrentTask()
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        PayablesAgentTask := GetPayablesAgentTask();
        Rec.TransferFields(PayablesAgentTask);
        ResolveDetails(PayablesAgentTask);
        Rec.Modify();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Resolves the values of the current Rec that are read from the records the task points to.
    /// </summary>
    local procedure ResolveDetails(PayablesAgentTask: Record "Payables Agent Task")
    var
        AgentTask: Record "Agent Task";
        PATaskMgt: Codeunit "PA Task Mgt.";
    begin
        Rec."Vendor No." := '';
        Clear(Rec."Agent Task Status");
        if EntriesWithAgentTask.Contains(PayablesAgentTask."Entry No.") then
            EntriesWithAgentTask.Remove(PayablesAgentTask."Entry No.");
        if PayablesAgentTask."Agent Task ID" <> 0 then
            if AgentTask.Get(PayablesAgentTask."Agent Task ID") then begin
                Rec."Agent Task Status" := AgentTask.Status;
                EntriesWithAgentTask.Add(PayablesAgentTask."Entry No.");
            end;
        if AgentTask.Title <> '' then
            TaskNames.Set(PayablesAgentTask."Entry No.", AgentTask.Title)
        else
            TaskNames.Set(PayablesAgentTask."Entry No.", StrSubstNo(TaskNameTxt, PayablesAgentTask."Entry No."));
        SourceDescriptions.Set(PayablesAgentTask."Entry No.", PATaskMgt.DescribeSource(PayablesAgentTask));
        ResultDescriptions.Set(PayablesAgentTask."Entry No.", DescribeOutcome(PayablesAgentTask));
    end;

    /// <summary>
    /// Describes the outcome of the task and sets "Vendor No." on the current Rec when the outcome is a Purchase Invoice.
    /// </summary>
    local procedure DescribeOutcome(PayablesAgentTask: Record "Payables Agent Task"): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PayablesAgentTask.Outcome.TableNo = 0 then
            exit('');
        if PayablesAgentTask.Outcome.TableNo <> Database::"Purchase Header" then
            exit(Format(PayablesAgentTask.Outcome));

        PurchaseHeader.SetLoadFields("Document Type", "No.", "Buy-from Vendor No.");
        if not PurchaseHeader.Get(PayablesAgentTask.Outcome) then
            exit(Format(PayablesAgentTask.Outcome));
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            Rec."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        exit(StrSubstNo(PurchaseDocumentTxt, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    local procedure GetPayablesAgentTask() PayablesAgentTask: Record "Payables Agent Task"
    begin
        PayablesAgentTask.Get(Rec."Entry No.");
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
        PurchaseDocumentTxt: Label 'Purchase %1 %2', Comment = '%1 = purchase document type, such as Invoice, %2 = document number';
}
