codeunit 101816 "Create FA Maintenance"
{

    trigger OnRun()
    begin
        InsertData(XSERVICE, XServicelc);
        InsertData(XSPAREPARTS, XSparePartslc);
    end;

    var
        "Maintenance Code": Record Maintenance;
        XSERVICE: Label 'SERVICE';
        XServicelc: Label 'Service';
        XSPAREPARTS: Label 'SPAREPARTS';
        XSparePartslc: Label 'Spare Parts';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        "Maintenance Code".Init();
        "Maintenance Code".Validate(Code, Code);
        "Maintenance Code".Validate(Description, Description);
        "Maintenance Code".Insert();
    end;

    procedure GetMaintenanceCode(MaintenanceCode: Text): Code[10]
    begin
        case UpperCase(MaintenanceCode) of
            'XSERVICE':
                exit(XSERVICE);
            'XSPAREPARTS':
                exit(XSPAREPARTS);
            else
                Error('Unknown Maintenance Code %1.', MaintenanceCode);
        end;
    end;
}
