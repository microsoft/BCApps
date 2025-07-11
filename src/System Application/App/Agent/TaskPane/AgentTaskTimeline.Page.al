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
    SourceTable = "Agent Task Timeline Step";
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
            field(UserMessage; UserMessage)
            {
                Editable = true;
                Caption = 'Additional Instructions';
                ToolTip = 'Specifies additional instructions for the user intervention request.';
            }
            repeater(TaskTimeline)
            {
                Editable = false;
                field(Header; Rec.Title)
                {
                    Caption = 'Header';
                    ToolTip = 'Specifies the header of the timeline step.';
                }
                field(Summary; GlobalPageSummary)
                {
                    Caption = 'Summary';
                    ToolTip = 'Specifies the summary of the timeline step.';
                }
                field(PrimaryPageQuery; GlobalPageQuery)
                {
                    Caption = 'Primary Page Query';
                    ToolTip = 'Specifies the primary page query of the timeline step.';
                }
                field(Description; GlobalDescription)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the timeline step.';
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
                    ToolTip = 'Specifies the confirmation status of the timeline step.';
                    OptionCaption = ' ,ConfirmationNotRequired,ReviewConfirmationRequired,ReviewConfirmed,StopConfirmationRequired,StopConfirmed,Discarded';
                }
                field(ConfirmedBy; GlobalConfirmedBy)
                {
                    Caption = 'Confirmed By';
                    ToolTip = 'Specifies the user who confirmed the timeline step.';
                }
                field(ConfirmedAt; GlobalConfirmedAt)
                {
                    Caption = 'Confirmed At';
                    ToolTip = 'Specifies the date and time when the timeline step was confirmed.';
                }
                field(NowAuthorizedBy; GlobalNowAuthorizedBy)
                {
                    Caption = 'Now Authorized By';
                    ToolTip = 'Specifies the task authorization changes from previous steps.';
                }
                field(Annotations; GlobalAnnotations)
                {
                    Caption = 'Annotations';
                    Tooltip = 'Specifies the annotations for the timeline step, such as additional messages to surface to the user.';
                }
                field(Importance; Rec.Importance)
                {
                }
                field(UserInterventionRequestType; Rec."User Intervention Request Type")
                {
                    Caption = 'User Intervention Request Type';
                    ToolTip = 'Specifies the type of user intervention request when this step is an intervention request.';
                }
                field(Suggestions; GlobalSuggestions)
                {
                    Caption = 'Suggestions';
                    ToolTip = 'Specifies the suggestions for the user intervention request.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'First Step Created At';
                    ToolTip = 'Specifies the date and time when the timeline step was created.';
                }
                field(LastUserInterventionDetails; GlobalUserInterventionDetails)
                {
                    Caption = 'Last User Intervention Details';
                    ToolTip = 'Specifies the details of the last user intervention in the timeline step.';
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
                    UserInterventionRequestEntry: Record "Agent Task Log Entry";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    if UserInterventionRequestEntry.Get(Rec."Task ID", Rec."Last Log Entry ID") then
                        if UserInterventionRequestEntry.Type = "Agent Task Log Entry Type"::"User Intervention Request" then
                            AgentTaskImpl.CreateUserIntervention(UserInterventionRequestEntry, UserMessage, SelectedSuggestionId);
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
                    UserInterventionRequestEntry: Record "Agent Task Log Entry";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    if UserInterventionRequestEntry.Get(Rec."Task ID", Rec."Last Log Entry ID") then
                        if UserInterventionRequestEntry.Type = "Agent Task Log Entry Type"::"User Intervention Request" then
                            AgentTaskImpl.CreateUserIntervention(UserInterventionRequestEntry);
                end;

            }
        }
    }

    trigger OnOpenPage()
    begin
        Clear(SelectedSuggestionId);
        Clear(UserMessage);
        Rec.SetRange(Importance, Rec.Importance::Primary);
    end;

    trigger OnAfterGetRecord()
    begin
        SetTaskTimelineDetails();
    end;

    local procedure SetTaskTimelineDetails()
    var
        AgentTaskMessage: Record "Agent Task Message";
        InStream: InStream;
        ConfirmationLogEntryType: Enum "Agent Task Log Entry Type";
        LogEntryId: Integer;
        ConfirmedById: Guid;
        PrevConfirmedById: Guid;
        ShouldRefreshConfirmationDetails: Boolean;
    begin
        // Clear old values
        GlobalNowAuthorizedBy := '';
        GlobalConfirmedBy := '';
        GlobalConfirmedAt := 0DT;
        Clear(GlobalPageSummary);
        Clear(GlobalPageQuery);
        Clear(GlobalAnnotations);
        Clear(GlobalSuggestions);
        Clear(GlobalUserInterventionDetails);

        GlobalDescription := Rec.Description;

        if Rec.CalcFields("Primary Page Summary", "Primary Page Query", "Annotations", "Last User Intervention Details") then begin
            if Rec."Primary Page Summary".HasValue() then begin
                Rec."Primary Page Summary".CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
                GlobalPageSummary.Read(InStream);
                Clear(InStream);
            end;
            if Rec."Primary Page Query".HasValue() then begin
                Rec."Primary Page Query".CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
                GlobalPageQuery.Read(InStream);
                Clear(InStream);
            end;
            if Rec."Annotations".HasValue() then begin
                Rec."Annotations".CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
                GlobalAnnotations.Read(InStream);
                Clear(InStream);
            end;
            if Rec."Last User Intervention Details".HasValue() then begin
                Rec."Last User Intervention Details".CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
                GlobalUserInterventionDetails.Read(InStream);
                Clear(InStream);
            end;
        end;

        if Rec.Type = Rec.Type::UserInterventionRequest then begin
            Rec.CalcFields("Suggestions");
            if Rec.Suggestions.HasValue then begin
                Rec.Suggestions.CreateInStream(InStream, AgentTaskImpl.GetDefaultEncoding());
                GlobalSuggestions.Read(InStream);
                Clear(InStream);
            end;
        end;

        ConfirmationStatusOption := ConfirmationStatusOption::ConfirmationNotRequired;
        LogEntryId := Rec."Last Log Entry ID";

        ShouldRefreshConfirmationDetails := true;

        if (Rec."Last Log Entry Type" <> "Agent Task Log Entry Type"::Stop) and (Rec."Last User Intervention ID" > 0) then
            LogEntryId := Rec."Last User Intervention ID"
        else
            if Rec."Last Log Entry Type" <> "Agent Task Log Entry Type"::Stop then
                // We know that there is no user intervention entry for this timeline entry, and the last entry is not a stop.
                ShouldRefreshConfirmationDetails := false;

        PrevConfirmedById := GetPreviousTimelineStepDetailConfirmedById(LogEntryId);

        if IsNullGuid(PrevConfirmedById) then
            // There were no user interventions before the current step. Default to the user who created the task.
            PrevConfirmedById := GetTaskCreatedBy();

        if not ShouldRefreshConfirmationDetails then
            exit;

        if not TryGetConfirmationDetails(LogEntryId, ConfirmedById, GlobalConfirmedAt, ConfirmationLogEntryType) then
            exit;

        GlobalConfirmedBy := ResolveUserDisplayName(ConfirmedById);
        if (not IsNullGuid(ConfirmedById)) and (ConfirmedById <> PrevConfirmedById) then
            GlobalNowAuthorizedBy := GlobalConfirmedBy;

        case
            ConfirmationLogEntryType of
            "Agent Task Log Entry Type"::"User Intervention Request":
                ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmationRequired;
            "Agent Task Log Entry Type"::"User Intervention":
                if (Rec.Type = Rec.Type::InputMessage) or (Rec.Type = Rec.Type::OutputMessage) then begin
                    ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmed;
                    if AgentTaskMessage.Get(Rec."Primary Page Record ID") then
                        if AgentTaskMessage.Status = AgentTaskMessage.Status::Discarded then begin
                            // Discards should not change authorized by.
                            GlobalNowAuthorizedBy := '';
                            ConfirmationStatusOption := ConfirmationStatusOption::Discarded;
                        end;
                end else
                    ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmed;
            "Agent Task Log Entry Type"::Stop:
                ConfirmationStatusOption := ConfirmationStatusOption::StopConfirmed;
            else
                ConfirmationStatusOption := ConfirmationStatusOption::ConfirmationNotRequired;
        end;
    end;

    local procedure TryGetConfirmationDetails(LogEntryId: Integer; var ById: Guid; var At: DateTime; var ConfirmationLogEntryType: Enum "Agent Task Log Entry Type"): Boolean
    var
        TaskTimelineStepDetail: Record "Agent Task Timeline Step Det.";
    begin
        if LogEntryId <= 0 then
            exit(false);

        TaskTimelineStepDetail.SetRange("Task ID", Rec."Task ID");
        TaskTimelineStepDetail.SetRange("Timeline Step ID", Rec.ID);
        TaskTimelineStepDetail.SetRange("ID", LogEntryId);
        if not TaskTimelineStepDetail.FindLast() then
            exit(false);

        ConfirmationLogEntryType := TaskTimelineStepDetail.Type;
        if TaskTimelineStepDetail.Type = "Agent Task Log Entry Type"::"User Intervention Request" then
            exit(true);

        if ((TaskTimelineStepDetail.Type <> "Agent Task Log Entry Type"::"User Intervention") and
            (TaskTimelineStepDetail.Type <> "Agent Task Log Entry Type"::Stop)) then
            exit(false);

        ById := TaskTimelineStepDetail."User Security ID";
        At := Rec.SystemModifiedAt;

        exit(true);
    end;

    local procedure GetTaskCreatedBy(): Guid
    var
        AgentTaskRec: Record "Agent Task";
        EmptyGuid: Guid;
    begin
        if not AgentTaskRec.Get(Rec."Task ID") then
            exit(EmptyGuid);

        exit(AgentTaskRec."Created By");
    end;

    local procedure GetPreviousTimelineStepDetailConfirmedById(LogEntryId: Integer): Guid
    var
        TaskTimelineStepDetail: Record "Agent Task Timeline Step Det.";
        EmptyGuid: Guid;
    begin
        TaskTimelineStepDetail.SetRange("Task ID", Rec."Task ID");
        TaskTimelineStepDetail.SetFilter("Timeline Step ID", '<%1', Rec.ID);
        TaskTimelineStepDetail.SetFilter("ID", '<%1', LogEntryId);
        TaskTimelineStepDetail.SetFilter("Type", '%1|%2', "Agent Task Log Entry Type"::"User Intervention", "Agent Task Log Entry Type"::Stop);
        if TaskTimelineStepDetail.FindLast() then
            exit(TaskTimelineStepDetail."User Security ID");

        exit(EmptyGuid);
    end;

    local procedure ResolveUserDisplayName(UserSecurityId: Guid): Text[250]
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');

        if User.Get(UserSecurityId) then
            if User."Full Name" <> '' then
                exit(User."Full Name")
            else
                exit(User."User Name");

        exit('');
    end;

    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        GlobalPageSummary: BigText;
        GlobalPageQuery: BigText;
        GlobalAnnotations: BigText;
        GlobalSuggestions: BigText;
        GlobalUserInterventionDetails: BigText;
        GlobalDescription: Text[2048];
        GlobalConfirmedBy: Text[250];
        GlobalNowAuthorizedBy: Text[250];
        GlobalConfirmedAt: DateTime;
        ConfirmationStatusOption: Option " ",ConfirmationNotRequired,ReviewConfirmationRequired,ReviewConfirmed,StopConfirmationRequired,StopConfirmed,Discarded;
        UserMessage: Text[250];
        SelectedSuggestionId: Text[3];
}

