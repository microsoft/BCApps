codeunit 132470 "Bank Acc. Linking Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TestServiceFriendlyNameTxt: Label 'Test Statement Provider Service';
        TestServiceKeyTxt: Label 'TestProvider';
        Assert: Codeunit Assert;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnGetStatementProvidersEvent', '', false, false)]
    local procedure OnGetStatementProviders(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        LastId: Integer;
    begin
        LastId := 0;
        if TempNameValueBuffer.FindLast() then
            LastId := TempNameValueBuffer.ID;

        LastId += 1;

        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := LastId;
        TempNameValueBuffer.Name := TestServiceKeyTxt;
        TempNameValueBuffer.Value := TestServiceFriendlyNameTxt;
        TempNameValueBuffer.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnLinkStatementProviderEvent', '', false, false)]
    local procedure OnLinkStatementProvider(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        Assert.AreEqual(TestServiceKeyTxt, StatementProvider, 'wrong provider');
    end;
}

