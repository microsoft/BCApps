namespace System.Threading;

codeunit 462 "Job Queue Activate Next"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        Rec.ActivateNextJobInCategory();
    end;


}