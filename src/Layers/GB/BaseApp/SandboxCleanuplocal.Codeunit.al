#if not CLEAN27
#pragma warning disable AA0247
codeunit 1883 "Sandbox Cleanup local"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to GovTalk app';
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        GovTalkSetup: Record "GovTalk Setup";
        nullGUID: Guid;
    begin
        if CompanyName() <> CompanyName then
            GovTalkSetup.ChangeCompany(CompanyName);

        GovTalkSetup.ModifyAll(Password, nullGUID);
    end;
}
#endif

