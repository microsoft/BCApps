codeunit 119079 "Finalize Manufacturing Setup"
{

    trigger OnRun()
    begin
        ModifyManufacturingSetup.Finalize();
    end;

    var
        ModifyManufacturingSetup: Codeunit "Modify Manufacturing Setup";
}

