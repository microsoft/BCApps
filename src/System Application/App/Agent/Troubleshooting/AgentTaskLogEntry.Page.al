// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Security.AccessControl;

page 4312 "Agent Task Log Entry"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Agent Task Log Entry";
    Caption = 'Agent Task Log Entry (Preview)';
    DataCaptionExpression = StrSubstNo(PageCaptionLbl, rec.ID, Rec.Description);
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AboutTitle = 'About agent task log entry';
    AboutText = 'Use this detailed log of what the AI agent found on the page and how it acted autonomously to troubleshoot agent issues. AI-generated content may be incorrect.';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'What the agent decided';
                AboutTitle = 'General information';
                AboutText = 'General information about the log entry. Click show more to see advanced details about the execution.';
                Editable = false;
                Visible = IsAgentAction;

                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the log entry.';
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Description);
                    end;
                }
                field(Reason; Rec.Reason)
                {
                    Caption = 'Reason';
                    ToolTip = 'Specifies the reason, provided by the agent, for the log entry.';
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Reason);
                    end;
                }
                field(Details; LogEntryDetailsTxt)
                {
                    Caption = 'Details';
                    ToolTip = 'Specifies the details of the log entry.';
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        Message(LogEntryDetailsTxt);
                    end;
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the log entry.';
                    Importance = Additional;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Timestamp';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
                    Importance = Additional;
                }
                field(UserFullName; Rec."User Full Name")
                {
                    Caption = 'User full name';
                    Tooltip = 'Specifies the full name of the user that was involved';
                    Importance = Additional;
                }
                field(TaskID; Rec."Task ID")
                {
                    Caption = 'Task ID';
                    ToolTip = 'Specifies the ID of the task that was executed.';
                    Importance = Additional;
                }
                field(AgentName; AgentName)
                {
                    Caption = 'Agent name';
                    ToolTip = 'Specifies the name of the agent that performed the tasks.';
                    Importance = Additional;
                }
                field(IsDecision; IsDecisionTxt)
                {
                    Caption = 'Decision Point';
                    ToolTip = 'Specifies if the agent made a decision at this point, or whether this was executed as part of a previous decision.';
                    Importance = Additional;
                }
                field(IsSuccess; IsSuccess)
                {
                    Caption = 'Success';
                    ToolTip = 'Specifies if the operation was successful.';
                    Importance = Additional;
                }
            }
            group(GeneralOther)
            {
                Caption = 'What happened';
                AboutTitle = 'General information';
                AboutText = 'General information about the log entry. Click show more to see advanced details about the execution.';
                Editable = false;
                Visible = not IsAgentAction;

                field(DescriptionOther; Rec.Description)
                {
                    Caption = 'Description';
                    Importance = Promoted;
                }
                field(DetailsOther; LogEntryDetailsTxt)
                {
                    Caption = 'Details';
                    ToolTip = 'Specifies the details of the log entry.';
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        Message(LogEntryDetailsTxt);
                    end;
                }
                field(TypeOther; Rec.Type)
                {
                    Caption = 'Type';
                    Importance = Additional;
                }
                field(TimestampOther; Rec.SystemCreatedAt)
                {
                    Caption = 'Timestamp';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
                    Importance = Additional;
                }
                field(NameOther; Rec."User Full Name")
                {
                    Caption = 'User full name';
                    Tooltip = 'Specifies the full name of the user that took the decision.';
                    Importance = Promoted;
                }
            }
            part(InputMessagePart; "Agent Task Message ListPart")
            {
                Caption = 'What the agent received';
                SubPageLink = "Task ID" = field("Task ID");
                AboutTitle = 'What the agent received';
                AboutText = 'Shows the message the agent received as part of this task.';
                Enabled = false;
                Visible = Rec.Type = Rec.Type::"Input Message";
            }
            part(OutputMessagePart; "Agent Task Message ListPart")
            {
                Caption = 'What the agent wrote';
                SubPageLink = "Task ID" = field("Task ID");
                AboutTitle = 'What the agent wrote';
                AboutText = 'Shows the message the agent wrote as part of this task.';
                Enabled = false;
                Visible = (Rec.Type = Rec.Type::"Output Message Draft") or (Rec.Type = Rec.Type::"Output Message");
            }
            part(LogsPart; "Agent Task Log Entry ListPart")
            {
                Caption = 'What other actions were decided at the same time';
                Visible = IsLogPageVisible;
                SubPageLink = "Task ID" = field("Task ID");
                AboutTitle = 'What other actions were decided at the same time';
                AboutText = 'The agent can take multiple actions from the same decision. This lists the log entries related to the actions taken by the agent for this particular entry.';
            }
            group(PageContentGroup)
            {
                Caption = 'What the agent saw';
                Visible = IsSerializedPageVisible;
                AboutTitle = 'What the agent saw';
                AboutText = 'The view of the page the agent saw before taking a decision. The data format is subject to change, therefore do not reference it too specifically in instructions.';

                field(PageContent; SerializedPageJson)
                {
                    Caption = 'Page content';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Message(SerializedPageJson);
                    end;
                }
            }
            part("Agent Available Tools"; "Agent Available Tools Part")
            {
                Caption = 'What tools the agent had access to';
                Enabled = false;
                AboutTitle = 'What tools the agent had available for the current page and context';
                AboutText = 'Lists the tools that were available to the agent at this point. The set of available tools may change over time; do not rely on this list being exhaustive or permanent in instructions.';
                Visible = IsAvailableToolsVisible and IsAgentAction;
            }
            part("Agent Memorized Data"; "Agent Memorized Data Part")
            {
                Caption = 'What data the agent memorized';
                AboutTitle = 'What data the agent memorized';
                AboutText = 'Lists the key-value data that the agent had memorized as part of the current task at this point.';
                Visible = IsMemorizedDataVisible and IsAgentAction;
            }
            part(EarlierMessagesPart; "Agent Task Message ListPart")
            {
                Caption = 'What messages the agent had access to';
                SubPageLink = "Task ID" = field("Task ID");
                AboutTitle = 'What messages the agent had access to';
                AboutText = 'Lists the messages related to the task the agent had access to before taking a decision.';
                Enabled = false;
                Visible = IsEarlierMessagesPartVisible;
            }
        }

        area(FactBoxes)
        {
            part(TaskContext; "Agent Task Context Part")
            {
                ApplicationArea = All;
                Caption = 'Task context';
                AboutTitle = 'Context information about the task and agent';
                AboutText = 'Shows context information such as the agent name, task ID, and company name.';
                SubPageLink = ID = field("Task ID");
            }
            part(PageStack; "Agent PageStack Part")
            {
                Caption = 'Page stack';
                AboutTitle = 'What pages were open below';
                AboutText = 'Shows the pages that were opened at the time of the log entry.';
                Visible = IsCurrentPageStackVisible;
            }
            part(TaskPageSettings; "Agent Task Page Settings Part")
            {
                Caption = 'Task and page settings';
                AboutTitle = 'Task and page settings';
                AboutText = 'Shows the settings of the page at the time of the log entry.';
                Visible = IsTaskPageSettingsVisible;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        AgentTaskLogEntryRecord: Record "Agent Task Log Entry";
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        ContentInStream: InStream;
    begin
        LogEntryDetailsTxt := AgentTaskImpl.GetDetailsForAgentTaskLogEntry(Rec);
        SetIsAgentAction();

        if not MemoryEntry.Get(Rec."Task ID", Rec."Memory Entry ID") then begin
            MemoryEntryDetailsTxt := '';
            ClearPartsAndVariables();
            exit;
        end;

        MemoryEntry.CalcFields(Details);
        MemoryEntry.Details.CreateInStream(ContentInStream, AgentTaskLogEntry.GetDefaultEncoding());
        ContentInStream.Read(MemoryEntryDetailsTxt);

        SetAgentName();
        ParseDetails();
        GetPageContext();

        if Rec.Id <> GlobalCurrentID then begin
            CurrPage.InputMessagePart.Page.DisplayInputMessageFor(MemoryEntry.ID);
            CurrPage.OutputMessagePart.Page.DisplayOutputMessageFor(MemoryEntry.ID);
            IsEarlierMessagesPartVisible := CurrPage.EarlierMessagesPart.Page.DisplayMessagesEarlierThan(MemoryEntry.ID);
            CurrPage.LogsPart.Page.SetEntryFilter(MemoryEntry.ID);
            GlobalCurrentID := Rec.Id;
            CurrPage.Update(false);
        end;

        AgentTaskLogEntryRecord.SetRange("Task ID", Rec."Task ID");
        AgentTaskLogEntryRecord.SetRange("Memory Entry ID", MemoryEntry.ID);
        IsLogPageVisible := AgentTaskLogEntryRecord.Count() > 1;
    end;

    local procedure ParseDetails()
    var
        RootObj: JsonObject;
    begin
        if not RootObj.ReadFrom(MemoryEntryDetailsTxt) then
            exit;

        IsSuccess := RootObj.Contains(SuccessLbl)
            ? Format(RootObj.GetBoolean(SuccessLbl, true))
            : '';
    end;

    local procedure SetAgentName()
    var
        Agent: Record Agent;
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        if not AgentTaskImpl.TryGetAgentRecordFromTaskId(Rec."Task ID", Agent) then begin
            AgentName := '';
            exit;
        end;

        AgentName := Agent."Display Name";
    end;

    local procedure SetIsAgentAction()
    var
        User: Record User;
        Default: Boolean;
    begin
        Default := false;

        case Rec.Type of
            // Operations always performed by a user.
            Rec.Type::"Input Message",
            Rec.Type::Resume,
            Rec.Type::"User Intervention":
                IsAgentAction := false;
            // Operations always performed by the agent.
            Rec.Type::"Page Operation",
            Rec.Type::"Output Message",
            Rec.Type::"Output Message Draft",
            Rec.Type::"User Intervention Request":
                IsAgentAction := true;
            // Operations performed by a user or the agent.
            Rec.Type::Stop:
                IsAgentAction := User.Get(Rec."User Security ID")
                    ? User."License Type" = User."License Type"::Agent
                    : Default;
            // By default, consider it was a user action.
            else
                IsAgentAction := Default;
        end;
    end;

    local procedure GetPageContext()
    var
        TempAvailableToolsRecords: Record "Agent JSON Buffer" temporary;
        TempPageStacksRecords: Record "Agent JSON Buffer" temporary;
        TempMemorizedDataRecords: Record "Agent JSON Buffer" temporary;
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        AgentSystemPermissionsImpl: Codeunit "Agent System Permissions Impl.";
        Root: JsonObject;
        TaskPageContextObj: JsonObject;
        RawSerializedPageJson: Text;
    begin
        ContextTxt := AgentTaskLogEntry.ReadContext(Rec);
        if ContextTxt = '' then
            // Fallback to memory entry context.
            ContextTxt := AgentTaskLogEntry.ReadContext(MemoryEntry);

        IsSerializedPageVisible := ContextTxt <> '';

        if not Root.ReadFrom(ContextTxt) then begin
            ClearPartsAndVariables();
            exit;
        end;

        RawSerializedPageJson := Root.GetText(SerializedPageLbl, true);
        if RawSerializedPageJson <> '' then
            SerializedPageJson := AgentSystemPermissionsImpl.CurrentUserHasTroubleshootAllAgents()
                ? AgentTaskLogEntry.FormatJsonTextForRichContent(RawSerializedPageJson)
                : AgentTroubleshooterMissingPermissionTxt
        else
            IsSerializedPageVisible := false;

        IsDecisionTxt := Root.Contains(IsDecisionPointLbl)
            ? Format(Root.GetBoolean(IsDecisionPointLbl, true))
            : Format(false);

        AgentTaskLogEntry.ExtractPageStack(TempPageStacksRecords, Root);
        IsCurrentPageStackVisible := TempPageStacksRecords.Count() > 0;
        CurrPage.PageStack.Page.SetData(TempPageStacksRecords);
        CurrPage.PageStack.Page.Update();

        AgentTaskLogEntry.ExtractAvailableTools(TempAvailableToolsRecords, Root);
        IsAvailableToolsVisible := TempAvailableToolsRecords.Count() > 0;
        CurrPage."Agent Available Tools".Page.SetData(TempAvailableToolsRecords);
        CurrPage."Agent Available Tools".Page.Update();

        AgentTaskLogEntry.ExtractMemorizedData(TempMemorizedDataRecords, Root);
        IsMemorizedDataVisible := TempMemorizedDataRecords.Count() > 0;
        CurrPage."Agent Memorized Data".Page.SetData(TempMemorizedDataRecords);
        CurrPage."Agent Memorized Data".Page.Update();

        if (not Root.Contains(TaskPageContextLbl)) then
            IsTaskPageSettingsVisible := false
        else begin
            IsTaskPageSettingsVisible := true;
            TaskPageContextObj := Root.GetObject(TaskPageContextLbl, true);
            CurrPage.TaskPageSettings.Page.SetData(TaskPageContextObj);
            CurrPage.TaskPageSettings.Page.Update();
        end;
    end;

    local procedure ClearPartsAndVariables()
    begin
        IsDecisionTxt := Format(false);
        IsLogPageVisible := false;
        IsSerializedPageVisible := false;
        IsEarlierMessagesPartVisible := false;

        CurrPage.PageStack.Page.ClearData();
        CurrPage.PageStack.Page.Update();
        IsCurrentPageStackVisible := false;

        CurrPage."Agent Available Tools".Page.ClearData();
        CurrPage."Agent Available Tools".Page.Update();
        IsAvailableToolsVisible := false;

        CurrPage."Agent Memorized Data".Page.ClearData();
        CurrPage."Agent Memorized Data".Page.Update();
        IsMemorizedDataVisible := false;

        CurrPage.TaskPageSettings.Page.ClearData();
        CurrPage.TaskPageSettings.Page.Update();
        IsTaskPageSettingsVisible := false;
    end;

    var
        MemoryEntry: Record "Agent Task Memory Entry";
        AgentTroubleshooterMissingPermissionTxt: Label 'Only users who are assigned the ''Troubleshoot All Agents'' permission can view page snapshot data.';
        ContextTxt: Text;
        MemoryEntryDetailsTxt: Text;
        LogEntryDetailsTxt: Text;
        AgentName: text;
        SerializedPageJson: text;
        IsDecisionTxt: Text;
        IsSuccess: Text;
        IsAgentAction: Boolean;
        IsAvailableToolsVisible: Boolean;
        IsEarlierMessagesPartVisible: Boolean;
        IsSerializedPageVisible: Boolean;
        IsTaskPageSettingsVisible: Boolean;
        IsCurrentPageStackVisible: Boolean;
        IsMemorizedDataVisible: Boolean;
        IsLogPageVisible: Boolean;
        GlobalCurrentID: Integer;
        SerializedPageLbl: Label 'serializedPage', Locked = true;
        IsDecisionPointLbl: Label 'isDecisionPoint', Locked = true;
        TaskPageContextLbl: Label 'taskPageContext', Locked = true;
        SuccessLbl: Label 'success', Locked = true;
        PageCaptionLbl: Label 'Log %1 - %2', Comment = '%1 is the id, and %2 is the description of it.';
}