// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

page 3333 "Payables Agent Work Items"
{
    Caption = 'Payables Agent Work Items';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PA Work Item List Row";
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
            repeater(WorkItems)
            {
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the work item.';
                }
                field(Source; Rec."Source Description")
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies what the work item came from, such as an email or a PDF file.';
                }
                field(Result; Rec."Result Description")
                {
                    Caption = 'Result';
                    ToolTip = 'Specifies the record that was registered as the outcome of the work item.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the vendor of the purchase invoice that was registered as the outcome of the work item.';
                }
                field(AgentTaskId; Rec."Agent Task ID")
                {
                    Caption = 'Agent Task No.';
                    ToolTip = 'Specifies the number of the agent task associated with this work item.';
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
                    ToolTip = 'Specifies the status of the agent task associated with this work item.';
                }
                field("Admission Status"; Rec."Admission Status")
                {
                    ToolTip = 'Specifies whether the received source was accepted as an agent task or rejected during intake.';
                }
                field("Rejection Reason"; Rec."Rejection Reason")
                {
                    Visible = false;
                    ToolTip = 'Specifies why the received source was rejected during intake.';
                }
            }
        }
        area(FactBoxes)
        {
            part(PdfPreview; "PA Work Item Pdf Preview")
            {
                Caption = 'Preview';
                Visible = IsPdfSourced;
                ShowFilter = false;
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
                    ToolTip = 'Open the email that the work item came from.';
                    Image = Email;
                    Enabled = IsEmailSourced;

                    trigger OnAction()
                    begin
                        LoadCurrentWorkItem(WorkItem);
                        Presentation.OpenSourceEmail(WorkItem);
                    end;
                }
                action(OpenEmailExternally)
                {
                    Caption = 'Open externally';
                    ToolTip = 'Open the email that the work item came from in Outlook on the web.';
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
                    ToolTip = 'Upload a PDF invoice to create a new work item for the payables agent.';
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
                    ToolTip = 'Download the PDF file of the work item.';
                    Image = Download;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    begin
                        LoadCurrentWorkItem(WorkItem);
                        Presentation.DownloadSourcePdf(WorkItem);
                    end;
                }
                action(ViewPdf)
                {
                    Caption = 'View';
                    ToolTip = 'View the PDF file of the work item.';
                    Image = View;
                    Enabled = IsPdfSourced;

                    trigger OnAction()
                    begin
                        LoadCurrentWorkItem(WorkItem);
                        Presentation.OpenSourcePdf(WorkItem);
                    end;
                }
            }
            action(RefreshWorkItems)
            {
                Caption = 'Refresh';
                ToolTip = 'Reload the latest state of the payables agent work items.';
                Image = Refresh;

                trigger OnAction()
                begin
                    ReloadWorkItems();
                end;
            }
            action(OpenSource)
            {
                Caption = 'Open source';
                ToolTip = 'Open what the work item came from. A work item that came from an email opens the email.';
                Image = Navigate;
                Enabled = HasSource;

                trigger OnAction()
                begin
                    LoadCurrentWorkItem(WorkItem);
                    if UseAgentExperience and WorkItem.CanExtractText() then
                        AgentExperience.ShowSourceText(WorkItem)
                    else
                        Presentation.OpenSource(WorkItem);
                end;
            }
            action(OpenOutcome)
            {
                Caption = 'Open outcome';
                ToolTip = 'Open the record that was registered as the outcome of the work item.';
                Image = ViewDetails;
                Enabled = HasOutcome;

                trigger OnAction()
                begin
                    LoadCurrentWorkItem(WorkItem);
                    Presentation.OpenOutcome(WorkItem);
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
                        LoadCurrentWorkItem(WorkItem);
                        AgentExperience.ExtractSourceText(WorkItem);
                        RefreshCurrentWorkItem();
                    end;
                }
                action(RegisterOutcome)
                {
                    Caption = 'Register outcome';
                    ToolTip = 'Register the purchase document that is the outcome of the work item.';
                    Image = Approve;
                    Enabled = CanRegisterOutcome;

                    trigger OnAction()
                    var
                        PARegisterOutcome: Page "PA Register Outcome";
                    begin
                        LoadCurrentWorkItem(WorkItem);
                        PARegisterOutcome.SetWorkItem(WorkItem);
                        if PARegisterOutcome.RunModal() <> Action::OK then
                            exit;
                        RefreshCurrentWorkItem();
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
                ToolTip = 'Upload a PDF invoice to create a new work item for the payables agent.';
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
            actionref(RefreshWorkItems_Promoted; RefreshWorkItems)
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
        UseAgentExperience := PAAgentAccess.IsAgentView();
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
            LoadCurrentWorkItem(WorkItem);
            EmailWebLink := Presentation.GetEmailWebLink(WorkItem);
        end;
        HasEmailWebLink := EmailWebLink <> '';
        if IsPdfSourced then
            CurrPage.PdfPreview.Page.SetWorkItem(Rec."Work Item ID")
        else
            CurrPage.PdfPreview.Page.SetWorkItem(EmptyWorkItemId);
    end;

    var
        WorkItem: Codeunit "PA Work Item";
        Presentation: Codeunit "PA Work Item Presentation";
        AgentExperience: Codeunit "PA Agent Experience";
        PAAgentAccess: Codeunit "PA Agent Access";
        HasStateScope: Boolean;
        ScopeState: Enum "PA Work Item State";
        WorkItemNotFoundErr: Label 'The work item does not exist.';
        EmailWebLink: Text;
        EmptyWorkItemId: Guid;
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

    internal procedure OpenByState(State: Enum "PA Work Item State")
    begin
        HasStateScope := true;
        ScopeState := State;
    end;

    local procedure RebuildRows()
    var
        TempSavedView: Record "PA Work Item List Row" temporary;
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

    local procedure ReloadWorkItems()
    var
        CurrentWorkItemId: Guid;
    begin
        CurrentWorkItemId := Rec."Work Item ID";
        RebuildRows();
        if not SelectRow(CurrentWorkItemId) then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure SelectRow(WorkItemId: Guid): Boolean
    var
        TempVisibleRow: Record "PA Work Item List Row" temporary;
    begin
        TempVisibleRow.Copy(Rec, true);
        TempVisibleRow.SetRange("Work Item ID", WorkItemId);
        if not TempVisibleRow.FindFirst() then
            exit(false);
        Rec := TempVisibleRow;
        exit(true);
    end;

    local procedure RefreshCurrentWorkItem()
    begin
        ReloadWorkItems();
    end;

    local procedure UploadPdfForAgent()
    var
        Upload: Codeunit "PA Work Item Upload";
        UploadedWorkItem: Codeunit "PA Work Item";
        WorkItemId: Guid;
    begin
        if not Upload.UploadInvoiceWithAgent(WorkItemId) then
            exit;
        ReloadWorkItems();
        if SelectRow(WorkItemId) then
            CurrPage.Update(false)
        else
            if UploadedWorkItem.Load(WorkItemId) then
                if UploadedWorkItem.HasAgentTask() then
                    Presentation.OpenAgentTask(UploadedWorkItem.GetAgentTaskId());
    end;

    local procedure LoadCurrentWorkItem(var CurrentWorkItem: Codeunit "PA Work Item")
    begin
        if not CurrentWorkItem.Load(Rec."Work Item ID") then
            Error(WorkItemNotFoundErr);
    end;
}
