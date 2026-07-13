codeunit 117028 "Create Repair Status"
{

    trigger OnRun()
    begin
        InsertData(XFINISHED, XServiceisfinished, RepairStatus."Service Order Status"::Finished, RepairStatus.Priority::Low, false, false, false, true, false, false,
          false, false, false, true, true, true, true, true);
        InsertData(XINPROCESS, XServiceinprocess, RepairStatus."Service Order Status"::"In Process", RepairStatus.Priority::High, false, false, true, false, false,
          false, false, false, false, true, true, true, true, true);
        InsertData(XINITIAL, XInitialRepairStatus, RepairStatus."Service Order Status"::Pending, RepairStatus.Priority::"Medium High", true, false, false, false,
          false, false, false, false, false, true, true, true, true, true);
        InsertData(XPARTLYSERV, XPartlyServiced, RepairStatus."Service Order Status"::Pending, RepairStatus.Priority::"Medium High", false, true, false, false, false,
          false, false, false, false, true, true, true, true, true);
        InsertData(XQUOTEFIN, XQuotationFinished, RepairStatus."Service Order Status"::"On Hold", RepairStatus.Priority::"Medium Low", false, false, false, false,
          false, false, false, false, true, true, true, true, true, true);
        InsertData(XREFERRED, XReferredlc, RepairStatus."Service Order Status"::Pending, RepairStatus.Priority::"Medium High", false, false, false, false, true, false,
          false, false, false, true, true, true, true, true);
        InsertData(XSPORDERED, XSparePartordered, RepairStatus."Service Order Status"::"On Hold", RepairStatus.Priority::"Medium Low", false, false, false, false,
          false, true, false, false, false, false, false, false, false, true);
        InsertData(XSPRCVD, XSparepartreceived, RepairStatus."Service Order Status"::Pending, RepairStatus.Priority::"Medium High", false, false, false, false, false
          , false, true, false, false, true, true, true, true, true);
        InsertData(XWAITCUST, XWaitingforCustomer, RepairStatus."Service Order Status"::"On Hold", RepairStatus.Priority::"Medium Low", false, false, false, false,
          false, false, false, true, false, true, true, true, true, true);
    end;

    var
        RepairStatus: Record "Repair Status";
        XFINISHED: Label 'FINISHED';
        XServiceisfinished: Label 'Service is finished';
        XINPROCESS: Label 'IN PROCESS';
        XINITIAL: Label 'INITIAL';
        XPARTLYSERV: Label 'PARTLYSERV';
        XQUOTEFIN: Label 'QUOTEFIN';
        XREFERRED: Label 'REFERRED';
        XSPORDERED: Label 'SP ORDERED';
        XSPRCVD: Label 'SP RCVD';
        XWAITCUST: Label 'WAITCUST';
        XServiceinprocess: Label 'Service in process';
        XInitialRepairStatus: Label 'Initial Repair Status';
        XPartlyServiced: Label 'Partly Serviced';
        XQuotationFinished: Label 'Quotation Finished';
        XReferredlc: Label 'Referred';
        XSparePartordered: Label 'Spare Part ordered';
        XSparepartreceived: Label 'Spare part received';
        XWaitingforCustomer: Label 'Waiting for Customer';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Service Order Status": Enum "Service Document Status"; Priority: Option; Initial: Boolean; "Partly Serviced": Boolean; "In Process": Boolean; Finished: Boolean; Referred: Boolean; "Spare Part Ordered": Boolean; "Spare Part Received": Boolean; "Waiting for Customer": Boolean; "Quote Finished": Boolean; "Posting Allowed": Boolean; "Pending Status Allowed": Boolean; "In Process Status Allowed": Boolean; "Finished Status Allowed": Boolean; "On Hold Status Allowed": Boolean)
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.Init();
        RepairStatus.Validate(Code, Code);
        RepairStatus.Validate(Description, Description);
        RepairStatus.Validate("Service Order Status", "Service Order Status");
        RepairStatus.Validate(Priority, Priority);
        RepairStatus.Validate(Initial, Initial);
        RepairStatus.Validate("Partly Serviced", "Partly Serviced");
        RepairStatus.Validate("In Process", "In Process");
        RepairStatus.Validate(Finished, Finished);
        RepairStatus.Validate(Referred, Referred);
        RepairStatus.Validate("Spare Part Ordered", "Spare Part Ordered");
        RepairStatus.Validate("Spare Part Received", "Spare Part Received");
        RepairStatus.Validate("Waiting for Customer", "Waiting for Customer");
        RepairStatus.Validate("Quote Finished", "Quote Finished");
        RepairStatus.Validate("Posting Allowed", "Posting Allowed");
        RepairStatus.Validate("Pending Status Allowed", "Pending Status Allowed");
        RepairStatus.Validate("In Process Status Allowed", "In Process Status Allowed");
        RepairStatus.Validate("Finished Status Allowed", "Finished Status Allowed");
        RepairStatus.Validate("On Hold Status Allowed", "On Hold Status Allowed");
        RepairStatus.Insert(true);
    end;
}

