codeunit 101610 "Create Employee Stat. Group"
{

    trigger OnRun()
    begin
        InsertData(XMANAGER, XManagers);
        InsertData(XWORKER, XWorkers);
        InsertData(XSPECIALIST, XSpecialists);
        InsertData(XTECHPERS, XTechnicalPersonnel);
        InsertData(XSERVPERS, XServicePersonnel);
    end;

    var
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
        XMANAGER: Label 'MANAGER';
        XManagers: Label 'Managers';
        XWORKER: Label 'WORKER';
        XWorkers: Label 'Workers';
        XSPECIALIST: Label 'SPECIALIST';
        XSpecialists: Label 'Specialists';
        XTECHPERS: Label 'TECHPERS';
        XTechnicalPersonnel: Label 'Technical Personnel';
        XSERVPERS: Label 'SERVPERS';
        XServicePersonnel: Label 'Service Personnel';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        EmployeeStatisticsGroup.Code := Code;
        EmployeeStatisticsGroup.Description := Description;
        EmployeeStatisticsGroup.Insert();
    end;
}

