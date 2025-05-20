// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4313 "Agent Task Details"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Task Timeline Step Det.";
    Caption = 'Agent Task Timeline Step Details';
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
            repeater(Details)
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
                ToolTip = 'Confirms the timeline step.';

                trigger OnAction()
                begin
                    AddUserIntervention();
                end;
            }
#pragma warning disable AW0005
            action(DiscardStep)
#pragma warning restore AW0005
            {
                Caption = 'Discard step';
                ToolTip = 'Discard the timeline step.';
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

    local procedure AddUserIntervention()
    var
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        TaskTimelineStep: Record "Agent Task Timeline Step";
        UserInput: Text;
    begin
        TaskTimelineStep.SetRange("Task ID", Rec."Task ID");
        TaskTimelineStep.SetRange(ID, Rec."Timeline Step ID");
        TaskTimelineStep.SetRange("Last Log Entry Type", "Agent Task Log Entry Type"::"User Intervention Request");
        if TaskTimelineStep.FindLast() then begin
            case TaskTimelineStep."User Intervention Request Type" of
                TaskTimelineStep."User Intervention Request Type"::ReviewMessage:
                    UserInput := '';
                else
                    UserInput := UserMessage; //ToDo: Will be implemented when we have a message field.
            end;
            if UserInterventionRequestEntry.Get(TaskTimelineStep."Task ID", TaskTimelineStep."Last Log Entry ID") then
                AgentTaskImpl.CreateUserIntervention(UserInterventionRequestEntry, UserInput);
        end;
    end;

    local procedure SkipStep()
    var
        TaskTimelineStep: Record "Agent Task Timeline Step";
        AgentTaskMessage: Record "Agent Task Message";
    begin

        if not TaskTimelineStep.Get(Rec."Task ID", Rec."Timeline Step ID") then
            exit;

        case TaskTimelineStep.Type of
            "Agent Task Timeline Step Type"::InputMessage, "Agent Task Timeline Step Type"::OutputMessage:
                if AgentTaskMessage.Get(TaskTimelineStep."Primary Page Record ID") then begin
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


