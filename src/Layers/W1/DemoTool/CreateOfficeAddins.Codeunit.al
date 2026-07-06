codeunit 118600 "Create Office Add-ins"
{

    trigger OnRun()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
    end;
}

