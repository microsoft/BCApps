The modules exposes functionality to define default role center.

Example

```
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Default Role Center", 'OnBeforeGetDefaultRoleCenter', '', false, false)]
local procedure SetRoleCenter(var RoleCenterId: Integer; var Handled: Boolean)
begin
    // Do not overwrite already defined default role center
    if Handled then
        exit;
        
    RoleCenterId := Page::MyAwesomeRoleCenterPage;

    // Set Handled to true so that other subscribers know that a default role center has been defined
    Handled := true;
end;
```

