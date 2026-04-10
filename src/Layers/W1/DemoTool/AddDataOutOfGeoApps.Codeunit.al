codeunit 117570 "Add Data Out Of Geo. Apps"
{
    trigger OnRun()
    begin
    end;

#pragma warning disable AA0228
    // helper method used in localizations
    local procedure InsertDataOutOfGeoApp(AppID: Guid)
    var
        DataOutOfGeoApp: Codeunit "Data Out Of Geo. App";
    begin
        if not DataOutOfGeoApp.Contains(AppID) then
            DataOutOfGeoApp.Add(AppID);
    end;
#pragma warning restore AA0228
}