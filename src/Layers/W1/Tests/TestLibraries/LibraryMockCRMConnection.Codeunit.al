codeunit 130610 "Library - Mock CRM Connection"
{
    // To be used for mocking of CRM connection/data by functions in TAB5330.

    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        GlobalSkipReading: Boolean;
        SetTestAsDefaultConnection: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"CRM Connection Setup", 'OnReadingCRMData', '', false, false)]
    local procedure OnReadingCRMData(var SkipReading: Boolean)
    begin
        SkipReading := GlobalSkipReading;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Connection Setup", 'OnGetDefaultCRMConnection', '', false, false)]
    local procedure OnGetDefaultCRMConnection(var ConnectionName: Text)
    begin
        if SetTestAsDefaultConnection then begin
            ConnectionName := 'TEST';
            if not HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName) then
                RegisterTestConnection();
        end;
        Assert.IsTrue(
          HasTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionName),
          StrSubstNo('COD130610.Connection "%1" should be registered.', ConnectionName));
        Assert.AreEqual(
          ConnectionName, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM),
          StrSubstNo('COD130610.Connection "%1" should be set as default.', ConnectionName));
    end;

    [Scope('OnPrem')]
    procedure RegisterTestConnection()
    begin
        RegisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST', '@@test@@');
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST');
    end;

    [Scope('OnPrem')]
    procedure EnableRead()
    begin
        GlobalSkipReading := false;
    end;

    [Scope('OnPrem')]
    procedure SkipRead()
    begin
        GlobalSkipReading := true;
    end;

    [Scope('OnPrem')]
    procedure MockConnection()
    begin
        SetTestAsDefaultConnection := true;
    end;
}

