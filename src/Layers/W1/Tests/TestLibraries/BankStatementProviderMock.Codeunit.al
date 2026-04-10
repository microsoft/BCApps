codeunit 139350 "Bank Statement Provider Mock"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        BankStatementProviderExist: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnGetStatementProvidersEvent', '', false, false)]
    [Normal]
    local procedure OnOnlineBankStatementExist(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        TempNameValueBuffer.DeleteAll();
        if BankStatementProviderExist then begin
            TempNameValueBuffer.Init();
            TempNameValueBuffer.Name := 'TestStatementFeed';
            TempNameValueBuffer.Value := 'TestValue';
            TempNameValueBuffer.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnSimpleLinkStatementProviderEvent', '', false, false)]
    [Normal]
    local procedure OnSimpleLinkOnlineProvider(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var StatementProvider: Text)
    begin
        OnlineBankAccLink.DeleteAll();
        if BankStatementProviderExist then begin
            OnlineBankAccLink.Init();
            OnlineBankAccLink.Name := 'Test Account Name';
            OnlineBankAccLink."Bank Account No." := '123-5456';
            OnlineBankAccLink.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBankStatementExist(StatementExist: Boolean)
    begin
        BankStatementProviderExist := StatementExist;
    end;
}

