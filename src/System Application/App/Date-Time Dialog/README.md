The modules consists of a page to enter date or date-time values.

Usage example:

```
procedure LookupDateTime(InitialValue: DateTime): DateTime
var
    DateTimeDialog: Page "Date-Time Dialog";
    NewValue: DateTime;
begin
    DateTimeDialog.SetDateTime(InitialValue);

    if DateTimeDialog.RunModal() = Action::OK then
        NewValue := DateTimeDialog.GetDateTime();

    exit(NewValue);
end;

procedure LookupDate(InitialValue: Date): Date
var
    DateDialog: Page "Date-Time Dialog";
    NewValue: Date;
begin
    DateDialog.UseDateOnly()
    DateDialog.SetDate(InitialValue);

    if DateDialog.RunModal() = Action::OK then
        NewValue := DateDialog.GetDate();

    exit(NewValue);
end;
```


