codeunit 117029 "Create Service Status Priority"
{

    trigger OnRun()
    begin
        InsertData(ServiceStatusPrioritySetup."Service Order Status"::Pending, ServiceStatusPrioritySetup.Priority::"Medium High");
        InsertData(ServiceStatusPrioritySetup."Service Order Status"::"In Process", ServiceStatusPrioritySetup.Priority::High);
        InsertData(ServiceStatusPrioritySetup."Service Order Status"::Finished, ServiceStatusPrioritySetup.Priority::Low);
        InsertData(ServiceStatusPrioritySetup."Service Order Status"::"On Hold", ServiceStatusPrioritySetup.Priority::"Medium Low");
    end;

    var
        ServiceStatusPrioritySetup: Record "Service Status Priority Setup";

    procedure InsertData("Service Order Status": Enum "Service Document Type"; Priority: Option)
    var
        ServiceStatusPrioritySetup: Record "Service Status Priority Setup";
    begin
        ServiceStatusPrioritySetup.Init();
        ServiceStatusPrioritySetup.Validate("Service Order Status", "Service Order Status");
        ServiceStatusPrioritySetup.Validate(Priority, Priority);
        ServiceStatusPrioritySetup.Insert(true);
    end;
}

