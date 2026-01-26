codeunit 117570 "Add Data Out Of Geo. Apps"
{
    trigger OnRun()
    begin
        InsertDataOutOfGeoApp('d09fa965-9a2a-424d-b704-69f3b54ed0ce'); // Paypal
        InsertDataOutOfGeoApp('bae453ed-0fd8-4416-afdc-4b09db6c12c3'); // World Pay
        InsertDataOutOfGeoApp('16319982-4995-4fb1-8fb2-2b1e13773e3b'); // AMC
        InsertDataOutOfGeoApp('e868ad92-21b8-4e08-af2b-8975a8b06e04'); // Image Analysis
        InsertDataOutOfGeoApp('3d5b2137-efeb-4014-8489-41d37f8fd4c3'); // Late Payment Predictor
        InsertDataOutOfGeoApp('c526b3e9-b8ca-4683-81ba-fcd5f6b1472a'); // Sales and Inventory Forecast
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