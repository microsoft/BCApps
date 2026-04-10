namespace System.Environment.Configuration;

codeunit 8820 "AAD Application Interface"
{
    trigger OnRun()
    begin
    end;

    procedure CreateAADApplication(ClientId: Guid; ClientDescription: Text[50]; ContactInformation: Text[50])
    var
        AADApplication: Record "AAD Application";
    begin
        AADApplication."Client Id" := ClientId;
        AADApplication.Description := ClientDescription;
        AADApplication."Contact Information" := ContactInformation;
        AADApplication.State := AADApplication.State::Disabled;
        if AADApplication.Insert() then;
    end;

    procedure CreateAADApplication(ClientId: Guid; ClientDescription: Text[50]; ContactInformation: Text[50]; EnableAADApplication: Boolean)
    var
        AADApplication: Record "AAD Application";
    begin
        CreateAADApplication(ClientId, ClientDescription, ContactInformation);
        AADApplication.Get(ClientId);
        if EnableAADApplication then begin
            AADApplication.TestField(Description);
            AADApplication.Validate(State, AADApplication.State::Enabled);
            AADApplication.Modify();
        end;
    end;

    procedure ModifyAADApplicationDescription(ClientId: Guid; ClientDescription: Text[50])
    var
        AADApplication: Record "AAD Application";
    begin
        if not AADApplication.Get(ClientId) then
            exit;
        AADApplication.Description := ClientDescription;
        AADApplication.Modify();
    end;
}