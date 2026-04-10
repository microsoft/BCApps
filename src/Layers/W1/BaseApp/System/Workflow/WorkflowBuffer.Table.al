namespace System.Automation;

table 1500 "Workflow Buffer"
{
    Caption = 'Workflow Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Category Code"; Code[20])
        {
            Caption = 'Category Code';
            DataClassification = SystemMetadata;
            TableRelation = "Workflow Category".Code;
        }
        field(2; "Workflow Code"; Code[20])
        {
            Caption = 'Workflow Code';
            DataClassification = SystemMetadata;
            TableRelation = Workflow.Code;
        }
        field(3; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; Template; Boolean)
        {
            CalcFormula = lookup(Workflow.Template where(Code = field("Workflow Code")));
            Caption = 'Template';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Enabled; Boolean)
        {
            CalcFormula = lookup(Workflow.Enabled where(Code = field("Workflow Code")));
            Caption = 'Enabled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "External Client ID"; Guid)
        {
            CalcFormula = lookup("Workflow Webhook Subscription"."Client Id" where("WF Definition Id" = field("Workflow Code"),
                                                                                    Enabled = const(true)));
            Caption = 'External Client ID';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "External Client Type"; Text[50])
        {
            CalcFormula = lookup("Workflow Webhook Subscription"."Client Type" where("WF Definition Id" = field("Workflow Code"),
                                                                                      Enabled = const(true)));
            Caption = 'External Client Type';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Category Code", "Workflow Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        if "Workflow Code" = '' then
            Error('');
        CalcFields(Template);
        if Template then
            Error('');
        Workflow.Get("Workflow Code");
        Workflow.Delete(true);

        TempWorkflowBuffer.Copy(Rec, true);
        TempWorkflowBuffer.SetRange("Category Code", "Category Code");
        TempWorkflowBuffer.SetFilter("Workflow Code", '<>%1&<>%2', '', "Workflow Code");
        if TempWorkflowBuffer.IsEmpty() then begin
            TempWorkflowBuffer.Get("Category Code", '');
            TempWorkflowBuffer.Delete(false);
        end;
    end;

    local procedure InitBuffer(var TempWorkflowBuffer: Record "Workflow Buffer" temporary; Template: Boolean)
    var
        Workflow: Record Workflow;
    begin
        DeleteAll();
        if TempWorkflowBuffer.IsTemporary() then
            TempWorkflowBuffer.DeleteAll();
        Workflow.SetRange(Template, Template);
        if Workflow.FindSet() then
            repeat
                if not TempWorkflowBuffer.Get(Workflow.Category, '') then
                    AddCategory(TempWorkflowBuffer, Workflow.Category);
                AddWorkflow(TempWorkflowBuffer, Workflow.Category, Workflow.Code);
            until Workflow.Next() = 0;
    end;

    procedure InitBufferForWorkflows(var TempWorkflowBuffer: Record "Workflow Buffer" temporary)
    begin
        InitBuffer(TempWorkflowBuffer, false);
    end;

    procedure InitBufferForTemplates(var TempWorkflowBuffer: Record "Workflow Buffer" temporary)
    begin
        InitBuffer(TempWorkflowBuffer, true);
    end;

    local procedure AddCategory(var TempWorkflowBuffer: Record "Workflow Buffer" temporary; CategoryCode: Code[20])
    begin
        InsertRec(TempWorkflowBuffer, CategoryCode, '', 0);
    end;

    local procedure AddWorkflow(var TempWorkflowBuffer: Record "Workflow Buffer" temporary; CategoryCode: Code[20]; WorkflowCode: Code[20])
    begin
        InsertRec(TempWorkflowBuffer, CategoryCode, WorkflowCode, 1);
    end;

    local procedure InsertRec(var TempWorkflowBuffer: Record "Workflow Buffer" temporary; CategoryCode: Code[20]; WorkflowCode: Code[20]; Indent: Integer)
    var
        Workflow: Record Workflow;
        WorkflowCategory: Record "Workflow Category";
    begin
        TempWorkflowBuffer.Init();
        TempWorkflowBuffer."Category Code" := CategoryCode;
        TempWorkflowBuffer."Workflow Code" := WorkflowCode;
        TempWorkflowBuffer.Indentation := Indent;
        if WorkflowCode = '' then begin
            if WorkflowCategory.Get(CategoryCode) then
                TempWorkflowBuffer.Description := WorkflowCategory.Description
        end else
            if Workflow.Get(WorkflowCode) then
                TempWorkflowBuffer.Description := Workflow.Description;

        if TempWorkflowBuffer.Insert() then;
    end;

    procedure CopyWorkflow(WorkflowBuffer: Record "Workflow Buffer")
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        CopyWorkflow: Report "Copy Workflow";
    begin
        if not FromWorkflow.Get(WorkflowBuffer."Workflow Code") then
            Error('');
        if FromWorkflow.Template or (IncStr(FromWorkflow.Code) = '') then
            ToWorkflow.Code := CopyStr(FromWorkflow.Code, 1, MaxStrLen(ToWorkflow.Code) - 3) + '-01'
        else
            ToWorkflow.Code := FromWorkflow.Code;
        while ToWorkflow.Get(ToWorkflow.Code) do
            ToWorkflow.Code := IncStr(ToWorkflow.Code);
        ToWorkflow.Init();
        ToWorkflow.Insert();
        CopyWorkflow.InitCopyWorkflow(FromWorkflow, ToWorkflow);
        CopyWorkflow.UseRequestPage(false);
        CopyWorkflow.Run();
        PAGE.Run(PAGE::Workflow, ToWorkflow);
    end;
}

