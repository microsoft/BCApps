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
            repeater(TaskTimeline)
            {
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
                    SelectedSuggestionIdInt: Integer;
                begin
                    if UserInterventionRequestEntry.Get(Rec."Task ID", Rec."Last Log Entry ID") then
                        if UserInterventionRequestEntry.Type = "Agent Task Log Entry Type"::"User Intervention Request" then
                            if Evaluate(SelectedSuggestionIdInt, SelectedSuggestionId) then
                                AgentTaskImpl.CreateUserIntervention(UserInterventionRequestEntry, SelectedSuggestionIdInt);
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
        ConfirmationLogEntryType: Enum "Agent Task Log Entry Type";
        LogEntryId: Integer;
        PrevConfirmedBy: Text[250];
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
        LogEntryId := Rec."Last Log Entry ID";

        ShouldRefreshConfirmationDetails := true;

        if (Rec."Last Log Entry Type" <> "Agent Task Log Entry Type"::Stop) and (Rec."Last User Intervention ID" > 0) then
            LogEntryId := Rec."Last User Intervention ID"
        else
            if Rec."Last Log Entry Type" <> "Agent Task Log Entry Type"::Stop then
                // We know that there is no user intervention entry for this timeline entry, and the last entry is not a stop.
                ShouldRefreshConfirmationDetails := false;

        PrevConfirmedBy := GetPreviousTimelineStepDetailConfirmedBy(LogEntryId);

        if (PrevConfirmedBy = '') then
            GlobalNowAuthorizedBy := GetTaskCreatedBy();

        if not ShouldRefreshConfirmationDetails then
            exit;

        if not TryGetConfirmationDetails(LogEntryId, GlobalConfirmedBy, GlobalConfirmedAt, ConfirmationLogEntryType) then
            exit;

        if (PrevConfirmedBy = '') and (GlobalConfirmedBy <> '') then
            GlobalNowAuthorizedBy := GlobalConfirmedBy
        else
            if (PrevConfirmedBy <> '') and (GlobalConfirmedBy <> '') and (PrevConfirmedBy <> GlobalConfirmedBy) then
                GlobalNowAuthorizedBy := GlobalConfirmedBy;

        case
            ConfirmationLogEntryType of
            "Agent Task Log Entry Type"::"User Intervention Request":
                ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmationRequired;
            "Agent Task Log Entry Type"::"User Intervention":
                ConfirmationStatusOption := ConfirmationStatusOption::ReviewConfirmed;
            "Agent Task Log Entry Type"::Stop:
                ConfirmationStatusOption := ConfirmationStatusOption::StopConfirmed;
            else
                ConfirmationStatusOption := ConfirmationStatusOption::ConfirmationNotRequired;
        end;
    end;

    local procedure TryGetConfirmationDetails(LogEntryId: Integer; var By: Text[250]; var At: DateTime; var ConfirmationLogEntryType: Enum "Agent Task Log Entry Type"): Boolean
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

        By := ResolveUserDisplayName(TaskTimelineStepDetail."User Security ID");
        At := Rec.SystemModifiedAt;

        exit(true);
    end;

    local procedure GetTaskCreatedBy(): Text[250]
    var
        AgentTaskTimelineRec: Record "Agent Task Timeline";
    begin
        AgentTaskTimelineRec.SetRange("Task ID", Rec."Task ID");
        if not AgentTaskTimelineRec.FindFirst() then
            exit('');

        exit(ResolveUserDisplayName(AgentTaskTimelineRec."Created By"));
    end;

    local procedure GetPreviousTimelineStepDetailConfirmedBy(LogEntryId: Integer): Text[250]
    var
        TaskTimelineStepDetail: Record "Agent Task Timeline Step Det.";
        ConfirmedByUserId: Guid;
    begin
        TaskTimelineStepDetail.SetRange("Task ID", Rec."Task ID");
        TaskTimelineStepDetail.SetFilter("Timeline Step ID", '<%1', Rec.ID);
        TaskTimelineStepDetail.SetFilter("ID", '<%1', LogEntryId);
        TaskTimelineStepDetail.SetFilter("Type", '%1|%2', "Agent Task Log Entry Type"::"User Intervention", "Agent Task Log Entry Type"::Stop);
        if TaskTimelineStepDetail.FindLast() then
            ConfirmedByUserId := TaskTimelineStepDetail."User Security ID";

        if (IsNullGuid(ConfirmedByUserId)) then
            exit('');

        exit(ResolveUserDisplayName(TaskTimelineStepDetail."User Security ID"))
    end;

    local procedure ResolveUserDisplayName(UserSecurityId: Guid): Text[250]
    var
        User: Record User;
    begin
        User.SetRange("User Security ID", UserSecurityId);
        if User.FindFirst() then
            if User."Full Name" <> '' then
                exit(User."Full Name")
            else
                exit(User."User Name");

        exit('');
    end;

    var
        GlobalPageSummary: BigText;
        GlobalPageQuery: BigText;
        GlobalAnnotations: BigText;
        GlobalSuggestions: BigText;
        GlobalDescription: Text[2048];
        GlobalConfirmedBy: Text[250];
        GlobalNowAuthorizedBy: Text[250];
        GlobalConfirmedAt: DateTime;
        ConfirmationStatusOption: Option " ",ConfirmationNotRequired,ReviewConfirmationRequired,ReviewConfirmed,StopConfirmationRequired,StopConfirmed,Discarded;
        SelectedSuggestionId: Text[3];
}


