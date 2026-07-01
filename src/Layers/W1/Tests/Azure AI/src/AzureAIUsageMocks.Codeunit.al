/// <summary>
/// Provides mocks for Azure AI Usage tests.
/// </summary>
codeunit 135211 "Azure AI Usage Mocks"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CurrentDateTimeMock: DateTime;

    procedure SetCurrentDateTime(NewDateTime: DateTime)
    begin
        CurrentDateTimeMock := NewDateTime;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AI Usage Impl.", 'OnAfterGetCurrentDateTime', '', false, false)]
    local procedure ChangeCurrentDateTime(var CurrentDateTime: DateTime)
    begin
        CurrentDateTime := CurrentDateTimeMock;
    end;
}