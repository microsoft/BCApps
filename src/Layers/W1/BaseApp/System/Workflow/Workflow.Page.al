namespace System.Automation;

using System.Environment.Configuration;
using System.IO;
using System.Utilities;

page 1501 Workflow
{
    Caption = 'Workflow';
    PageType = Document;
    SourceTable = Workflow;

    layout
    {
        area(content)
        {
            field("Code"; Rec.Code)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the workflow.';

                trigger OnValidate()
                begin
                    if OpenNew then begin
                        if Rec.Insert() then;
                        CurrPage.Update(false);
                        Rec.Get(Rec.Code);
                        OpenNew := false;
                    end;
                end;
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the workflow.';
            }
            field(Category; Rec.Category)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the category that the workflow belongs to.';
            }
            field(Enabled; Rec.Enabled)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                Enabled = IsNotTemplate;
                ToolTip = 'Specifies that the workflow will start when the event in the first entry-point workflow step occurs.';

                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }
            part(WorkflowSubpage; "Workflow Subpage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Workflow Steps';
                SubPageLink = "Workflow Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(WorkflowResponses; "Workflow Response FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Workflow Responses';
                Provider = WorkflowSubpage;
                SubPageLink = "Parent Event Step ID" = field("Event Step ID"),
                              "Workflow Code" = field("Workflow Code");
            }
            systempart(Control11; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control10; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportWorkflow)
            {
                ApplicationArea = Suite;
                Caption = 'Import from File';
                Enabled = Rec.Code <> '';
                Image = Import;
                ToolTip = 'Import an existing workflow from an XML file.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    WorkflowImpExpMgt: Codeunit "Workflow Imp. / Exp. Mgt";
                    FileManagement: Codeunit "File Management";
                begin
                    if FileManagement.BLOBImport(TempBlob, '') = '' then
                        exit;

                    WorkflowImpExpMgt.ReplaceWorkflow(Rec, TempBlob);
                    CurrPage.WorkflowSubpage.PAGE.RefreshBuffer();
                end;
            }
            action(ExportWorkflow)
            {
                ApplicationArea = Suite;
                Caption = 'Export to File';
                Enabled = Rec.Code <> '';
                Image = Export;
                ToolTip = 'Export the workflow to a file that can be imported in another Dynamics 365 database.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    Workflow: Record Workflow;
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                begin
                    Workflow.Get(Rec.Code);
                    Workflow.SetRange(Code, Rec.Code);
                    Workflow.ExportToBlob(TempBlob);
                    FileManagement.BLOBExport(TempBlob, '*.xml', true);
                end;
            }
            group(Flow)
            {
                Caption = 'Power Automate';
                action(WebhookClientLink)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Image = Flow;
                    ToolTip = 'View flow definition';
                    Visible = HasWebhookClientLink;

                    trigger OnAction()
                    var
                        WorkflowMgt: Codeunit "Workflow Management";
                    begin
                        if not WorkflowWebhookSubscription.IsEmpty() then
                            HyperLink(WorkflowMgt.GetWebhookClientLink(WorkflowWebhookSubscription."Client Id", WorkflowWebhookSubscription."Client Type"));
                    end;
                }
            }
        }
        area(navigation)
        {
            action(WorkflowStepInstances)
            {
                ApplicationArea = Suite;
                Caption = 'Workflow Step Instances';
                Enabled = InstancesExist;
                Image = List;
                ToolTip = 'Show all instances of workflow steps in current workflows.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    WorkflowStepInstances: Page "Workflow Step Instances";
                begin
                    WorkflowStepInstances.SetWorkflow(Rec);
                    WorkflowStepInstances.RunModal();
                end;
            }
            action(ArchivedWorkflowStepInstances)
            {
                ApplicationArea = Suite;
                Caption = 'Archived Workflow Step Instances';
                Enabled = ArchiveExists;
                Image = ListPage;
                ToolTip = 'View all instances of workflow steps that are no longer used, either because they are completed or because they were manually archived.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    ArchivedWFStepInstances: Page "Archived WF Step Instances";
                begin
                    ArchivedWFStepInstances.SetWorkflowCode(Rec.Code);
                    ArchivedWFStepInstances.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ImportWorkflow_Promoted; ImportWorkflow)
                {
                }
                actionref(ExportWorkflow_Promoted; ExportWorkflow)
                {
                }
                actionref(WorkflowStepInstances_Promoted; WorkflowStepInstances)
                {
                }
                actionref(ArchivedWorkflowStepInstances_Promoted; ArchivedWorkflowStepInstances)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Power Automate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(WebhookClientLink_Promoted; WebhookClientLink)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if OpenNew then
            Clear(Rec);

        CurrPage.WorkflowResponses.PAGE.UpdateData();

        if not TemplateValueSet then begin
            TemplateValueSet := true;
            Rec.SetRange(Template, Rec.Template);
        end;
    end;

    trigger OnAfterGetRecord()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        IsNotTemplate := not Rec.Template;

        WorkflowStepInstance.SetRange("Workflow Code", Rec.Code);
        InstancesExist := not WorkflowStepInstance.IsEmpty();

        WorkflowStepInstanceArchive.SetRange("Workflow Code", Rec.Code);
        ArchiveExists := not WorkflowStepInstanceArchive.IsEmpty();
    end;

    trigger OnClosePage()
    var
        Workflow: Record Workflow;
    begin
        if Workflow.Get() then
            Workflow.Delete();
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsNotTemplate := not Rec.Template;
        InstancesExist := false;
        ArchiveExists := false;

        if OpenView or ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then
            CurrPage.Editable := false;

        // Load webhook subscription link when page opens
        WorkflowWebhookSubscription.SetRange(Enabled, true);
        WorkflowWebhookSubscription.SetRange("WF Definition Id", Rec.Code);
        HasWebhookClientLink := WorkflowWebhookSubscription.FindFirst();
    end;

    var
        WorkflowWebhookSubscription: Record "Workflow Webhook Subscription";
        IsNotTemplate: Boolean;
        InstancesExist: Boolean;
        ArchiveExists: Boolean;
        OpenNew: Boolean;
        OpenView: Boolean;
        HasWebhookClientLink: Boolean;
        TemplateValueSet: Boolean;

    procedure SetOpenNew(NewOpenNew: Boolean)
    begin
        OpenNew := NewOpenNew
    end;

    procedure SetOpenView(NewOpenView: Boolean)
    begin
        OpenView := NewOpenView
    end;
}

