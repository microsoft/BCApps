namespace System.Automation;

page 1521 "Workflow Responses"
{
    Caption = 'Workflow Responses';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Workflow Response";
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
                    ToolTip = 'Specifies the workflow response.';
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
        WorkflowWebhookResponses: Codeunit "Workflow Webhook Responses";
    begin
        Rec.SetFilter("Function Name", '<>%1', WorkflowWebhookResponses.SendNotificationToWebhookCode());
        if Rec.FindFirst() then;
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

