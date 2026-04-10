namespace System.Automation;

page 1515 "Workflow Step Responses"
{
    AutoSplitKey = true;
    Caption = 'Workflow Responses';
    DataCaptionExpression = DataCaptionString;
    DelayedInsert = true;
    PageType = StandardDialog;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = "Workflow Step Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = ShowResponseList;
                field(ResponseDescriptionTableControl; Rec."Response Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Response';
                    ToolTip = 'Specifies the workflow response.';
                    Width = 100;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkflowResponse: Record "Workflow Response";
                    begin
                        Rec.ResponseDescriptionLookup('', WorkflowResponse);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Control4)
            {
                ShowCaption = false;
                Visible = not ShowResponseList;
                field(ResponseDescriptionCardControl; Rec."Response Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Select Response';
                    ToolTip = 'Specifies that you want to select a workflow response.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkflowResponse: Record "Workflow Response";
                    begin
                        Rec.ResponseDescriptionLookup('', WorkflowResponse);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            field(AddMoreResponsesLabel; AddMoreResponsesLabel)
            {
                ApplicationArea = Suite;
                Caption = 'AddMoreResponsesLabel';
                Editable = false;
                Enabled = CanAddMoreResponses;
                ShowCaption = false;
                Visible = CanAddMoreResponses;

                trigger OnDrillDown()
                begin
                    AddMoreResponsesLabel := '';
                    ShowResponseList := true;
                    UpdatePageData();
                end;
            }
            field(NextStepDescription; Rec."Next Step Description")
            {
                ApplicationArea = Suite;
                Caption = 'Next Step';
                Editable = false;
                Enabled = ShowNextStep;
                ShowCaption = false;
                ToolTip = 'Specifies another workflow step than the next one in the sequence that you want to start, for example, because the event on the workflow step failed to meet a condition.';
                Visible = ShowNextStep;

                trigger OnDrillDown()
                begin
                    if Rec.NextStepLookup() then
                        CurrPage.Update(false);
                end;
            }
            part("Workflow Response Options"; "Workflow Response Options")
            {
                ApplicationArea = Suite;
                Caption = 'Options for the Selected Response';
                SubPageLink = ID = field(Argument);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        if TempWorkflowStepBuffer.FindLast() then;
        if (Rec."Next Step Description" = '') and (Rec.Order = TempWorkflowStepBuffer.Order) then
            Rec."Next Step Description" := NextStepTxt;

        ShowNextStep := Rec."Next Step Description" <> '';

        Rec.UpdateRecFromWorkflowStep();
    end;

    trigger OnAfterGetRecord()
    begin
        WorkflowStep.Get(Rec."Workflow Code", Rec."Response Step ID");
        Rec."Response Description" := WorkflowStep.GetDescription();
        Rec.Modify();

        Rec.UpdateNextStepDescription();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Rec.SetCurrentKey(Order);
        Rec.Ascending(true);

        if Rec.IsEmpty() then
            Rec.PopulateTableFromEvent(Rec.GetRangeMax("Workflow Code"), Rec.GetRangeMax("Parent Event Step ID"));

        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        xRecWorkflowStep: Record "Workflow Step";
    begin
        if not BelowxRec then
            Rec."Previous Workflow Step ID" := xRec."Previous Workflow Step ID"
        else
            if not xRecWorkflowStep.Get(Rec."Workflow Code", xRec."Response Step ID") then
                Rec."Previous Workflow Step ID" := Rec."Parent Event Step ID"
            else
                Rec."Previous Workflow Step ID" := xRec."Response Step ID";

        Rec.CalculateNewKey(BelowxRec);

        WorkflowStep.Init();
        Rec.UpdateNextStepDescription();
    end;

    trigger OnOpenPage()
    begin
        Rec.CalcFields(Template);
        ShowResponseList := Rec.Count > 1;
        CanAddMoreResponses := not (ShowResponseList or Rec.Template);
        AddMoreResponsesLabel := AddMoreResponsesLbl;
        UpdatePageCaption();
        ShowNextStep := true;
    end;

    var
        WorkflowStep: Record "Workflow Step";
        ShowResponseList: Boolean;
        CanAddMoreResponses: Boolean;
        DataCaptionString: Text;
        AddMoreResponsesLabel: Text;
        AddMoreResponsesLbl: Label 'Add More Responses';
        NextStepTxt: Label '<(Optional) Select Next Step>';
        ShowNextStep: Boolean;

    local procedure UpdatePageCaption()
    var
        WorkflowStep2: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowStep2.Get(Rec.GetRangeMax("Workflow Code"), Rec.GetRangeMax("Parent Event Step ID"));
        WorkflowEvent.Get(WorkflowStep2."Function Name");
        DataCaptionString := WorkflowEvent.Description;
    end;

    local procedure UpdatePageData()
    begin
        Rec.ClearBuffer();
        Rec.PopulateTableFromEvent(Rec.GetRangeMax("Workflow Code"), Rec.GetRangeMax("Parent Event Step ID"));
        CurrPage.Update(false);
    end;
}

