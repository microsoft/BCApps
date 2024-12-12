// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4313 "Agent Task Details"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Task Timeline Entry Step";
    Caption = 'Agent Task Timeline Entry Step';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(content)
        {
            repeater(Steps)
            {
                field(ClientContext; ClientContext)
                {
                    Caption = 'Client Context';
                    ToolTip = 'Specifies the client context.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

#pragma warning disable AW0005
            action(Confirm)
#pragma warning restore AW0005
            {
                Caption = 'Confirm';
                ToolTip = 'Confirms the timeline entry.';

                trigger OnAction()
                begin
                    AddUserInterventionTaskStep();
                end;
            }
#pragma warning disable AW0005
            action(DiscardStep)
#pragma warning restore AW0005
            {
                Caption = 'Discard step';
                ToolTip = 'Discard the timeline entry.';
                trigger OnAction()
                begin
                    SkipStep();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetClientContext();
    end;

    local procedure SetClientContext()
    var
        InStream: InStream;
    begin
        // Clear old value
        Clear(ClientContext);

        if Rec.CalcFields("Client Context") then
            if Rec."Client Context".HasValue() then begin
                Rec."Client Context".CreateInStream(InStream);
                ClientContext.Read(InStream);
            end;
    end;

    local procedure AddUserInterventionTaskStep()
    var
        UserInterventionRequestStep: Record "Agent Task Step";
        TaskTimelineEntry: Record "Agent Task Timeline Entry";
        UserInput: Text;
    begin
        TaskTimelineEntry.SetRange("Task ID", Rec."Task ID");
        TaskTimelineEntry.SetRange(ID, Rec."Timeline Entry ID");
        TaskTimelineEntry.SetRange("Last Step Type", TaskTimelineEntry."Last Step Type"::"User Intervention Request");
        if TaskTimelineEntry.FindLast() then begin
            case TaskTimelineEntry."User Intervention Request Type" of
                TaskTimelineEntry."User Intervention Request Type"::ReviewMessage:
                    UserInput := '';
                else
                    UserInput := UserMessage; //ToDo: Will be implemented when we have a message field.
            end;
            if UserInterventionRequestStep.Get(TaskTimelineEntry."Task ID", TaskTimelineEntry."Last Step Number") then
                AgentTaskImpl.CreateUserInterventionTaskStep(UserInterventionRequestStep, UserInput);
        end;
    end;

    local procedure SkipStep()
    var
        TaskTimelineEntry: Record "Agent Task Timeline Entry";
        AgentTaskMessage: Record "Agent Task Message";
    begin

        if not TaskTimelineEntry.Get(Rec."Task ID", Rec."Timeline Entry ID") then
            exit;

        case TaskTimelineEntry.Type of
            TaskTimelineEntry.Type::OutputMessage:
                if AgentTaskMessage.Get(TaskTimelineEntry."Primary Page Record ID") then begin
                    AgentTaskMessage.Status := AgentTaskMessage.Status::Discarded;
                    AgentTaskMessage.Modify(true);
                end;
        end;
    end;

    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        ClientContext: BigText;
        UserMessage: Text;
}


