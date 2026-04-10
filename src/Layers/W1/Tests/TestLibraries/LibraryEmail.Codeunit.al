codeunit 132223 "Library - Email"
{
    procedure SetUpEmailAccount()
    var
        TempAccount: Record "Email Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
    begin
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailScenarioMock.DeleteAllMappings();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, TempAccount."Account Id", TempAccount.Connector);
    end;
}