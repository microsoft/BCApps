namespace Microsoft.Bc2Fabric;

codeunit 150004 "Fabric Platform Lookup State"
{
    SingleInstance = true;
    Access = Internal;

    var
        SelectedName: Text[250];
        SelectedValue: Text[250];
        RecordSelected: Boolean;
        CachedFabricApiToken: SecretText;
        FabricApiTokenExpiry: DateTime;

    procedure SetSelected(NewName: Text; NewValue: Text)
    begin
        SelectedName := CopyStr(NewName, 1, MaxStrLen(SelectedName));
        SelectedValue := CopyStr(NewValue, 1, MaxStrLen(SelectedValue));
        RecordSelected := true;
    end;

    procedure GetSelectedName(): Text
    begin
        exit(SelectedName);
    end;

    procedure GetSelectedValue(): Text
    begin
        exit(SelectedValue);
    end;

    procedure IsSelected(): Boolean
    begin
        exit(RecordSelected);
    end;

    procedure ClearSelection()
    begin
        SelectedName := '';
        SelectedValue := '';
        RecordSelected := false;
    end;

    [NonDebuggable]
    procedure SetFabricApiToken(Token: SecretText; ExpiresInSeconds: Integer)
    begin
        CachedFabricApiToken := Token;
        // Subtract 60 s safety margin so the token is refreshed before actual expiry.
        FabricApiTokenExpiry := CurrentDateTime() + (ExpiresInSeconds - 60) * 1000;
    end;

    [NonDebuggable]
    procedure GetFabricApiToken(): SecretText
    begin
        exit(CachedFabricApiToken);
    end;

    procedure HasFabricApiToken(): Boolean
    begin
        exit((FabricApiTokenExpiry <> 0DT) and (CurrentDateTime() < FabricApiTokenExpiry));
    end;

    procedure ClearFabricApiToken()
    var
        EmptySecret: SecretText;
    begin
        CachedFabricApiToken := EmptySecret;
        FabricApiTokenExpiry := 0DT;
    end;
}
