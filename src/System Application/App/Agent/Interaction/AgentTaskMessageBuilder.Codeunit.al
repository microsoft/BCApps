procedure GetAttachments(var TempAttachments: Record "Agent Task File" temporary): Boolean
begin
    FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
    exit(AgentTaskMsgBuilderImpl.GetAttachments(TempAttachments));
end;