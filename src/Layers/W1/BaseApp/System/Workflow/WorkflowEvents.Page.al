namespace System.Automation;

page 1520 "Workflow Events"
{
    Caption = 'Workflow Events';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Workflow Event";
    SourceTableView = sorting(Independent, Description);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ShowCaption = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the workflow event.';
                    Width = 50;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        StyleTxt := GetStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := GetStyle();
    end;

    trigger OnOpenPage()
    var
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
    begin
        Rec.SetFilter("Function Name", '<>%1', WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode());
    end;

    var
        StyleTxt: Text;

    local procedure GetStyle(): Text
    begin
        if Rec.HasPredecessors() then
            exit('Strong');
        exit('');
    end;
}

