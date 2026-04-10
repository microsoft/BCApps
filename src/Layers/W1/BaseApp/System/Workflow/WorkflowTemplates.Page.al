namespace System.Automation;

page 1505 "Workflow Templates"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Templates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Workflow Buffer";
    SourceTableTemporary = true;
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
                    ApplicationArea = Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specifies a description of the workflow template.';
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
            action(ViewAction)
            {
                ApplicationArea = Suite;
                Caption = 'View';
                Image = View;
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'View an existing workflow template.';

                trigger OnAction()
                var
                    Workflow: Record Workflow;
                begin
                    Workflow.Get(Rec."Workflow Code");
                    PAGE.Run(PAGE::Workflow, Workflow);
                end;
            }
            action("New Workflow from Template")
            {
                ApplicationArea = Suite;
                Caption = 'New Workflow from Template';
                Enabled = not IsLookupMode;
                Image = NewDocument;
                ToolTip = 'Create a new workflow template using an existing workflow template.';

                trigger OnAction()
                begin
                    Rec.CopyWorkflow(Rec)
                end;
            }
            action("Reset Templates")
            {
                ApplicationArea = Suite;
                Caption = 'Reset Microsoft Templates';
                Visible = not IsLookupMode;
                Image = ResetStatus;
                ToolTip = 'Recreate all Microsoft templates';

                trigger OnAction()
                var
                    WorkflowSetup: Codeunit "Workflow Setup";
                begin
                    WorkflowSetup.ResetWorkflowTemplates();
                    Initialize();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref("New Workflow from Template_Promoted"; "New Workflow from Template")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ViewAction_Promoted; ViewAction)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Workflow Code" = '' then
            DescriptionStyle := 'Strong'
        else
            DescriptionStyle := 'Standard';
    end;

    trigger OnOpenPage()
    begin
        Initialize();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CurrPage.LookupMode and (CloseAction = ACTION::LookupOK) and (Rec."Workflow Code" = '') then
            Error(QueryClosePageLookupErr);
    end;

    protected procedure Initialize()
    begin
        WorkflowSetup.InitWorkflow();
        Rec.InitBufferForTemplates(Rec);
        IsLookupMode := CurrPage.LookupMode;
        if Rec.FindFirst() then;
    end;

    var
        WorkflowSetup: Codeunit "Workflow Setup";
        QueryClosePageLookupErr: Label 'Select a workflow template to continue, or choose Cancel to close the page.';
        DescriptionStyle: Text;

    protected var
        IsLookupMode: Boolean;
}

