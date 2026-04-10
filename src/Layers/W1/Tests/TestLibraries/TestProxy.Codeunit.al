codeunit 130220 "Test Proxy"
{

    trigger OnRun()
    begin
    end;

    var
        TestProxyNotificationMgt: Codeunit "Test Proxy Notification Mgt.";

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        BindSubscription(TestProxyNotificationMgt);
    end;

    [Scope('OnPrem')]
    procedure InvokeOnBeforeTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    begin
        if SkipFunction(FunctionName) then
            exit;

        OnBeforeTestFunctionRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions);
    end;

    [Scope('OnPrem')]
    procedure InvokeOnAfterTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var IsSuccess: Boolean)
    begin
        if SkipFunction(FunctionName) then
            exit;

        OnAfterTestFunctionRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions, IsSuccess);
    end;

    local procedure SkipFunction(FunctionName: Text[128]): Boolean
    begin
        exit((FunctionName = '') or (FunctionName = 'OnRun'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var IsSuccess: Boolean)
    begin
    end;
}

