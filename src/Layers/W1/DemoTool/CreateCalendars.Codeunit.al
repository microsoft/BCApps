codeunit 119022 "Create Calendars"
{

    trigger OnRun()
    begin
        CreateMachineCtrCalendar.InitializeRequest(CA.AdjustDate(19020101D), CA.AdjustDate(19031231D));
        CreateMachineCtrCalendar.UseRequestPage(false);
        CreateMachineCtrCalendar.RunModal();

        CreateWorkCtrCalendar.InitializeRequest(CA.AdjustDate(19020101D), CA.AdjustDate(19031231D));
        CreateWorkCtrCalendar.UseRequestPage(false);
        CreateWorkCtrCalendar.RunModal();
    end;

    var
        CreateWorkCtrCalendar: Report "Calculate Work Center Calendar";
        CreateMachineCtrCalendar: Report "Calc. Machine Center Calendar";
        CA: Codeunit "Make Adjustments";
}

