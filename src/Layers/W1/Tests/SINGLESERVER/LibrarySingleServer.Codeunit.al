codeunit 134613 "Library - Single Server"
{
    procedure GetAppIdGuid(): Guid
    var
        AppId: Guid;
    begin
        Evaluate(AppId, '{5B061701-DAE6-48CC-BC16-8C4761A2BAF5}');
        exit(AppId);
    end;

    procedure GetTestLibraryAppIdGuid(): Guid
    var
        AppId: Guid;
    begin
        Evaluate(AppId, '{5D86850B-0D76-4ECA-BD7B-951AD998E997}');
        exit(AppId);
    end;
}