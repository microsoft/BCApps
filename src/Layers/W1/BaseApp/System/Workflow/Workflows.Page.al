namespace System.Automation;

using System.Environment;
using System.IO;
using System.Utilities;

page 1500 Workflows
{
    ApplicationArea = Suite;
    Caption = 'Workflows';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Workflows';
    AboutText = 'Automate and manage business processes by designing workflows that connect tasks through triggers, conditions, and responses, enabling approvals, notifications, and system actions across your organization.';
    RefreshOnActivate = true;
    SourceTable = "Workflow Buffer";
    SourceTableTemporary = true;
    SourceTableView = where(Template = const(false));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;
                ShowAsTree = true;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specifies a description of the workflow.';
                }
                field(Source; Source)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the source of the workflow.';
                }
                field("Category Code"; Rec."Category Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow type, such as Administration or Finance.';
                    Visible = false;
                }
                field("Workflow Code"; Rec."Workflow Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow that the workflow step belongs to.';
                    Visible = false;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies if the workflow is enabled.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control7; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control8; Links)
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
            group(New)
            {
                Caption = 'New';
                action(NewAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'New';
                    Image = NewDocument;
                    ToolTip = 'Create a new workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        WorkflowPage: Page Workflow;
                    begin
                        if Rec.IsEmpty() then begin
                            Clear(Rec);
                            Rec.Insert();
                        end;
                        Workflow.SetRange(Template, false);
                        if Workflow.IsEmpty() then
                            Workflow.Insert();
                        Workflow.FilterGroup := 2;
                        WorkflowPage.SetOpenNew(true);
                        WorkflowPage.SetTableView(Workflow);
                        WorkflowPage.SetRecord(Workflow);
                        WorkflowPage.Run();
                    end;
                }
                action(CopyFromTemplate)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Workflow from Template';
                    Image = Copy;
                    ToolTip = 'Create a new workflow quickly using a template.';

                    trigger OnAction()
                    var
                        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
                    begin
                        if Rec.IsEmpty() then begin
                            Clear(Rec);
                            Rec.Insert();
                        end;
                        if PAGE.RunModal(PAGE::"Workflow Templates", TempWorkflowBuffer) = ACTION::LookupOK then begin
                            Rec.CopyWorkflow(TempWorkflowBuffer);

                            // If first workflow on an empty page
                            if Rec.Count = 1 then
                                Rec := TempWorkflowBuffer;

                            RefreshTempWorkflowBuffer();
                        end;
                    end;
                }
                action(CopyWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Workflow';
                    Enabled = Rec."Workflow Code" <> '';
                    Image = Copy;
                    ToolTip = 'Copy an existing workflow.';

                    trigger OnAction()
                    begin
                        Rec.CopyWorkflow(Rec);
                    end;
                }
            }
            group(Manage)
            {
                Caption = 'Manage';
                action(EditAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'Edit';
                    Enabled = Rec."Workflow Code" <> '';
                    Image = Edit;
                    ShortCutKey = 'Return';
                    ToolTip = 'Edit an existing workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                    begin
                        if Workflow.Get(Rec."Workflow Code") then
                            PAGE.Run(PAGE::Workflow, Workflow);
                    end;
                }
                action(ViewAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Enabled = Rec."Workflow Code" <> '';
                    Image = View;
                    ToolTip = 'View an existing workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        WorkflowPage: Page Workflow;
                    begin
                        Workflow.Get(Rec."Workflow Code");
                        WorkflowPage.SetRecord(Workflow);
                        WorkflowPage.SetOpenView(true);
                        WorkflowPage.Run();
                    end;
                }
                action(DeleteAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete';
                    Enabled = Rec."Workflow Code" <> '';
                    Image = Delete;
                    ToolTip = 'Delete the record.';

                    trigger OnAction()
                    begin
                        Rec.Delete(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Process)
            {
                Caption = 'Process';
                action(ImportWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Import from File';
                    Image = Import;
                    ToolTip = 'Import workflow from a file.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                    begin
                        if FileManagement.BLOBImport(TempBlob, '') <> '' then begin
                            Workflow.ImportFromBlob(TempBlob);
                            RefreshTempWorkflowBuffer();
                        end;
                    end;
                }
                action(ExportWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Export to File';
                    Enabled = ExportEnabled;
                    Image = Export;
                    ToolTip = 'Export the workflow to a file that can be imported in another Dynamics 365 database.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                        "Filter": Text;
                    begin
                        Filter := GetFilterFromSelection();
                        if Filter = '' then
                            exit;
                        Workflow.SetFilter(Code, Filter);
                        Workflow.ExportToBlob(TempBlob);
                        FileManagement.BLOBExport(TempBlob, '*.xml', true);
                    end;
                }
            }
            group(Flow)
            {
                Caption = 'Power Automate';
                action(WebhookClientLink)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Enabled = ExternalLinkEnabled;
                    Image = Flow;
                    Scope = Repeater;
                    ToolTip = 'View flow definition';
                    Visible = IsSaaS;

                    trigger OnAction()
                    var
                        WorkflowMgt: Codeunit "Workflow Management";
                    begin
                        Rec.CalcFields("External Client Type");
                        HyperLink(WorkflowMgt.GetWebhookClientLink(Rec."External Client ID", Rec."External Client Type"));
                    end;
                }
            }
        }
        area(navigation)
        {
            action(ViewTemplates)
            {
                ApplicationArea = Suite;
                Caption = 'View Templates';
                Ellipsis = true;
                Image = ViewPage;
                RunObject = Page "Workflow Templates";
                ToolTip = 'View the existing workflow templates.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
                ShowAs = SplitButton;

                actionref(CopyFromTemplate_Promoted; CopyFromTemplate)
                {
                }
                actionref(CopyWorkflow_Promoted; CopyWorkflow)
                {
                }
                actionref(NewAction_Promoted; NewAction)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ImportWorkflow_Promoted; ImportWorkflow)
                {
                }
                actionref(ExportWorkflow_Promoted; ExportWorkflow)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(EditAction_Promoted; EditAction)
                {
                }
                actionref(DeleteAction_Promoted; DeleteAction)
                {
                }
                actionref(ViewAction_Promoted; ViewAction)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Power Automate', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(WebhookClientLink_Promoted; WebhookClientLink)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RefreshTempWorkflowBufferRow();
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshTempWorkflowBuffer();
        ExportEnabled := not Rec.IsEmpty();

        if Rec."Workflow Code" = '' then begin
            DescriptionStyle := 'Strong';
            ExternalLinkEnabled := false;
            Source := '';
        end else begin
            DescriptionStyle := 'Standard';

            // Enable/disable external links
            Rec.CalcFields("External Client ID");
            ExternalLinkEnabled := not IsNullGuid(Rec."External Client ID");

            if ExternalLinkEnabled then
                Source := PowerAutomateTxt
            else
                Source := BusinessCentralSourceTxt;
        end
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        WorkflowSetup.InitWorkflow();
        if not WorkflowBufferInitialized then
            Rec.InitBufferForWorkflows(Rec);

        IsSaaS := EnvironmentInfo.IsSaaS();
    end;

    var
        WorkflowSetup: Codeunit "Workflow Setup";
        DescriptionStyle: Text;
        Refresh: Boolean;
        WorkflowBufferInitialized: Boolean;
        ExternalLinkEnabled: Boolean;
        IsSaaS: Boolean;
        Source: Text;
        BusinessCentralSourceTxt: Label 'Business Central';
        PowerAutomateTxt: Label 'Power Automate';

    protected var
        ExportEnabled: Boolean;

    procedure RefreshTempWorkflowBuffer()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
        WorkflowCode: Code[20];
        CurrentWorkflowChanged: Boolean;
        WorkflowCountChanged: Boolean;
    begin
        WorkflowCode := Rec."Workflow Code";
        if Workflow.Get(WorkflowCode) then
            CurrentWorkflowChanged := (Rec."Category Code" <> Workflow.Category) or (Rec.Description <> Workflow.Description)
        else
            CurrentWorkflowChanged := WorkflowCode <> '';

        Workflow.SetRange(Template, false);

        TempWorkflowBuffer.Copy(Rec, true);
        TempWorkflowBuffer.Reset();
        TempWorkflowBuffer.SetFilter("Workflow Code", '<>%1', '');
        TempWorkflowBuffer.SetRange(Template, false);

        WorkflowCountChanged := Workflow.Count <> TempWorkflowBuffer.Count();

        if CurrentWorkflowChanged or WorkflowCountChanged then begin
            Rec.InitBufferForWorkflows(Rec);
            Refresh := true;
        end;
    end;

    local procedure RefreshTempWorkflowBufferRow()
    var
        Workflow: Record Workflow;
    begin
        if Refresh then begin
            CurrPage.Update(false);
            Refresh := false;
            exit;
        end;

        if Rec."Workflow Code" = '' then
            exit;

        Workflow.Get(Rec."Workflow Code");
        Rec."Category Code" := Workflow.Category;
        Rec.Description := Workflow.Description;
        Rec.Modify();
    end;

    procedure GetFilterFromSelection() "Filter": Text
    var
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        TempWorkflowBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempWorkflowBuffer);

        if TempWorkflowBuffer.FindSet() then
            repeat
                if TempWorkflowBuffer."Workflow Code" <> '' then
                    if Filter = '' then
                        Filter := TempWorkflowBuffer."Workflow Code"
                    else
                        Filter := StrSubstNo('%1|%2', Filter, TempWorkflowBuffer."Workflow Code");
            until TempWorkflowBuffer.Next() = 0;
    end;

    procedure SetWorkflowBufferRec(var TempWorkflowBuffer: Record "Workflow Buffer" temporary)
    begin
        WorkflowBufferInitialized := true;
        Rec.InitBufferForWorkflows(Rec);
        Rec.CopyFilters(TempWorkflowBuffer);
        if StrLen(Rec.GetFilter("Workflow Code")) > 0 then
            Rec.SetFilter("Workflow Code", TempWorkflowBuffer.GetFilter("Workflow Code") + '|''''');
        if Rec.FindLast() then;
    end;
}

