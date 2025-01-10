// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4307 "Agent Task Timeline"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Task Timeline Entry";
    Caption = 'Agent Task Timeline';
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(content)
        {
            field(SelectedSuggestionId; SelectedSuggestionId)
            {
                Editable = true;
                Caption = 'Selected Suggestion ID';
                ToolTip = 'Specifies the selected suggestion ID for the user intervention request.';
            }
            repeater(TaskTimeline)
            {
                field(Header; Rec.Title)
                {
                    Caption = 'Header';
                    ToolTip = 'Specifies the header of the timeline entry.';
                }
                field(Summary; GlobalPageSummary)
                {
                    Caption = 'Summary';
                    ToolTip = 'Specifies the summary of the timeline entry.';
                }
                field(PrimaryPageQuery; GlobalPageQuery)
                {
                    Caption = 'Primary Page Query';
                    ToolTip = 'Specifies the primary page query of the timeline entry.';
                }
                field(Description; GlobalDescription)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the timeline entry.';
                }
                field(Category; Rec.Category)
                {
                }
                field(Type; Rec.Type)
                {
                }
                field(ConfirmationStatus; ConfirmationStatusOption)
                {
                    Caption = 'Confirmation Status';
                    ToolTip = 'Specifies the confirmation status of the timeline entry.';
                    OptionCaption = ' ,ConfirmationNotRequired,ReviewConfirmationRequired,ReviewConfirmed,StopConfirmationRequired,StopConfirmed,Discarded';
                }
                field(ConfirmedBy; GlobalConfirmedBy)
                {
                    Caption = 'Confirmed By';
                    ToolTip = 'Specifies the user who confirmed the timeline entry.';
                }
                field(ConfirmedAt; GlobalConfirmedAt)
                {
                    Caption = 'Confirmed At';
                    ToolTip = 'Specifies the date and time when the timeline entry was confirmed.';
                }
                field(Annotations; GlobalAnnotations)
                {
                    Caption = 'Annotations';
                    Tooltip = 'Specifies the annotations for the timeline entry, such as additional messages to surface to the user.';
                }
                field(Importance; Rec.Importance)
                {
                }
                field(UserInterventionRequestType; Rec."User Intervention Request Type")
                {
                    Caption = 'User Intervention Request Type';
                    ToolTip = 'Specifies the type of user intervention request when this entry is an intervention request.';
                }
                field(Suggestions; GlobalSuggestions)
                {
                    Caption = 'Suggestions';
                    ToolTip = 'Specifies the suggestions for the user intervention request.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'First Step Created At';
                    ToolTip = 'Specifies the date and time when the timeline entry was created.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
#pragma warning disable AW0005
            action(Send)
#pragma warning restore AW0005
            {
                Caption = 'Send';
                ToolTip = 'Sends the selected instructions to the agent.';
                Scope = Repeater;
                trigger OnAction()
                var
                    UserInterventionRequestStep: Record "Agent Task Step";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                    SelectedSuggestionIdInt: Integer;
                begin
                    if UserInterventionRequestStep.Get(Rec."Task ID", Rec."Last Step Number") then
                        if UserInterventionRequestStep.Type = "Agent Task Step Type"::"User Intervention Request" then
                            if Evaluate(SelectedSuggestionIdInt, SelectedSuggestionId) then
                                AgentTaskImpl.CreateUserInterventionTaskStep(UserInterventionRequestStep, SelectedSuggestionIdInt);
                end;
            }

#pragma warning disable AW0005
            action(Retry)
#pragma warning restore AW0005
            {
                Caption = 'Retry';
                ToolTip = 'Retries the task.';
                Scope = Repeater;
                trigger OnAction()
                var
                    UserInterventionRequestStep: Record "Agent Task Step";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    if UserInterventionRequestStep.Get(Rec."Task ID", Rec."Last Step Number") then
                        if UserInterventionRequestStep.Type = "Agent Task Step Type"::"User Intervention Request" then
                            AgentTaskImpl.CreateUserInterventionTaskStep(UserInterventionRequestStep);
                end;

            }
        }
    }

    trigger OnOpenPage()
    begin
        SelectedSuggestionId := '';
        Rec.SetRange(Importance, Rec.Importance::Primary);
    end;

    trigger OnAfterGetRecord()
    begin
        SetTaskTimelineDetails();
    end;

    local procedure SetTaskTimelineDetails()
    var
        InStream: InStream;
        ConfirmationStepType: Enum "Agent Task Step Type";
        StepNumber: Integer;
    begin
        // Clear old values
        GlobalConfirmedBy := '';
        GlobalConfirmedAt := 0DT;
        Clear(GlobalPageSummary);
        Clear(GlobalPageQuery);
        Clear(GlobalAnnotations);
        Clear(GlobalSuggestions);

        GlobalDescription := Rec.Description;

        if Rec.CalcFields("Primary Page Summary", "Primary Page Query", "Annotations") then begin
            if Rec."Primary Page Summary".HasValue then begin
                Rec."Primary Page Summary".CreateInStream(InStream, TextEncoding::UTF8);
                GlobalPageSummary.Read(InStream);
                Clear(InStream);
            end;
            if Rec."Primary Page Query".HasValue then begin
                Rec."Primary Page Query".CreateInStream(InStream, TextEncoding::UTF8);
                GlobalPageQuery.Read(InStream);
                Clear(InStream);
            end;
            if Rec."Annotations".HasValue then begin
                Rec."Annotations".CreateInStream(InStream, TextEncoding::UTF8);
                GlobalAnnotations.Read(InStream);
                Clear(InStream);
            end;
        end;

        if Rec.Type = Rec.Type::UserInterventionRequest then begin
            Rec.CalcFields("Suggestions");
            if Rec.Suggestions.HasValue then begin
                Rec.Suggestions.CreateInStream(InStream, TextEncoding::UTF8);
                GlobalSuggestions.Read(InStream);
                Clear(InStream);
            end;
        end;

        ConfirmationStatusOption := ConfirmationStatusOption::ConfirmationNotRequired;
        StepNumber := Rec."Last Step Number";
        if (Rec."Last Step Type" <> "Agent Task Step Type"::Stop) and (Rec."Last User Intervention Step" > 0) then
            StepNumber := Rec."Last User Intervention Step"
        else
            if Rec."Last Step Type" <> "Agent Task Step Type"::Stop then
                // We know that there is no user intervention step for this timeline entry, and the last step is not a stop step.
                exit;
        if not TryGetConfirmationDetails(StepNumber, GlobalConfirmedBy, GlobalConfirmedAt, ConfirmationStepType) then
            exit;

        case
            ConfirmationStepType of
            "Agent Task Step Type"::"User Intervention Request":
                ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmationRequired;
            "Agent Task Step Type"::"User Intervention":
                ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmed;
            "Agent Task Step Type"::Stop:
                ConfirmationStatusOption := ConfirmationStatusOption::StopConfirmed;
            else
                ConfirmationStatusOption := ConfirmationStatusOption::ConfirmationNotRequired;
        end;
    end;

    local procedure TryGetConfirmationDetails(StepNumber: Integer; var By: Text[250]; var At: DateTime; var ConfirmationStepType: Enum "Agent Task Step Type"): Boolean
    var
        TaskTimelineEntryStep: Record "Agent Task Timeline Entry Step";
        User: Record User;
    begin
        if StepNumber <= 0 then
            exit(false);

        TaskTimelineEntryStep.SetRange("Task ID", Rec."Task ID");
        TaskTimelineEntryStep.SetRange("Timeline Entry ID", Rec.ID);
        TaskTimelineEntryStep.SetRange("Step Number", StepNumber);
        if not TaskTimelineEntryStep.FindLast() then
            exit(false);

        ConfirmationStepType := TaskTimelineEntryStep.Type;
        if TaskTimelineEntryStep.Type = "Agent Task Step Type"::"User Intervention Request" then
            exit(true);

        if ((TaskTimelineEntryStep.Type <> "Agent Task Step Type"::"User Intervention") and
            (TaskTimelineEntryStep.Type <> "Agent Task Step Type"::Stop)) then
            exit(false);

        User.SetRange("User Security ID", TaskTimelineEntryStep."User Security ID");
        if User.FindFirst() then
            if User."Full Name" <> '' then
                By := User."Full Name"
            else
                By := User."User Name";

        At := Rec.SystemModifiedAt;
        exit(true);
    end;

    var
        GlobalPageSummary: BigText;
        GlobalPageQuery: BigText;
        GlobalAnnotations: BigText;
        GlobalSuggestions: BigText;
        GlobalDescription: Text[2048];
        GlobalConfirmedBy: Text[250];
        GlobalConfirmedAt: DateTime;
        ConfirmationStatusOption: Option " ",ConfirmationNotRequired,ReviewConfirmationRequired,ReviewConfirmed,StopConfirmationRequired,StopConfirmed,Discarded;
        SelectedSuggestionId: Text[3];
}


