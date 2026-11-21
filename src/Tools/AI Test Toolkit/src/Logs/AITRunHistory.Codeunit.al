// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;

codeunit 149036 "AIT Run History"
{
    Access = Internal;

    procedure GetHistory(Code: Code[100]; LineNo: Integer; AITViewBy: Enum "AIT Run History - View By"; var TempAITRunHistory: Record "AIT Run History" temporary)
    var
        AITRunHistory: Record "AIT Run History";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        Quota: Codeunit "Copilot Quota";
        SeenTags: List of [Text[20]];
        TaskIDs: Text;
    begin
        TempAITRunHistory.DeleteAll();
        AITRunHistory.SetRange("Test Suite Code", Code);

        if AITViewBy = AITViewBy::Version then
            if AITRunHistory.FindSet() then
                repeat
                    TempAITRunHistory.TransferFields(AITRunHistory);
                    TaskIDs := AgentTestContextImpl.GetAgentTaskIDs(AITRunHistory."Test Suite Code", AITRunHistory.Version, '', LineNo);
                    TempAITRunHistory."Agent Task IDs" := CopyStr(TaskIDs, 1, MaxStrLen(TempAITRunHistory."Agent Task IDs"));
                    if Quota.IsNewMonetizationEnabled() then begin
                        if TaskIDs <> '' then begin
                            TempAITRunHistory."AI Credits" := AgentTestContextImpl.GetCopilotCredits(AITRunHistory."Test Suite Code", AITRunHistory.Version, '', LineNo);
                            TempAITRunHistory."AI Pricing Pending" := AgentTestContextImpl.IsPricingPendingForTasks(TaskIDs);
                        end;
                    end else
                        TempAITRunHistory."Copilot Credits" := AgentTestContextImpl.GetCopilotCredits(AITRunHistory."Test Suite Code", AITRunHistory.Version, '', LineNo);
                    TempAITRunHistory.Insert();
                until AITRunHistory.Next() = 0;

        if AITViewBy = AITViewBy::Tag then
            if AITRunHistory.FindSet() then
                repeat
                    if not SeenTags.Contains(AITRunHistory.Tag) then begin
                        TempAITRunHistory.TransferFields(AITRunHistory);
                        TaskIDs := AgentTestContextImpl.GetAgentTaskIDs(AITRunHistory."Test Suite Code", '', AITRunHistory.Tag, LineNo);
                        TempAITRunHistory."Agent Task IDs - By Tag" := CopyStr(TaskIDs, 1, MaxStrLen(TempAITRunHistory."Agent Task IDs - By Tag"));
                        if Quota.IsNewMonetizationEnabled() then begin
                            if TaskIDs <> '' then begin
                                TempAITRunHistory."AI Credits - By Tag" := AgentTestContextImpl.GetCopilotCredits(AITRunHistory."Test Suite Code", '', AITRunHistory.Tag, LineNo);
                                TempAITRunHistory."AI Pricing Pending - By Tag" := AgentTestContextImpl.IsPricingPendingForTasks(TaskIDs);
                            end;
                        end else
                            TempAITRunHistory."Copilot Credits - By Tag" := AgentTestContextImpl.GetCopilotCredits(AITRunHistory."Test Suite Code", '', AITRunHistory.Tag, LineNo);
                        TempAITRunHistory.Insert();
                    end;
                    SeenTags.Add(AITRunHistory.Tag);
                until AITRunHistory.Next() = 0;

        if (LineNo <> 0) then
            TempAITRunHistory.SetRange("Line No. Filter", LineNo)
        else
            TempAITRunHistory.SetRange("Line No. Filter");
    end;
}