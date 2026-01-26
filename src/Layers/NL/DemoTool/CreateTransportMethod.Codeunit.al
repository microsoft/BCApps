codeunit 101259 "Create Transport Method"
{
    // // Descriptions from http://www.cbs.nl/en/service/respondents/codelist/codelist-2-2004.htm


    trigger OnRun()
    begin
        InsertData('1', XTransportBySea);
        InsertData('2', XTransportByRail);
        InsertData('3', XTransportByRoad);
        InsertData('4', XTransportByAeroplane);
        InsertData('5', XConsignmentsByPost);
        InsertData('7', XFixedTransportInstallations);
        InsertData('8', XTransportByInlandWaterway);
    end;

    var
        "Transport Method": Record "Transport Method";
        XTransportBySea: Label 'Transport by sea';
        XTransportByRail: Label 'Transport by rail';
        XTransportByRoad: Label 'Transport by road ';
        XTransportByAeroplane: Label 'Transport by aeroplane';
        XConsignmentsByPost: Label 'Consignments by post ';
        XFixedTransportInstallations: Label 'Fixed transport installations ';
        XTransportByInlandWaterway: Label 'Transport by inland waterway';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        "Transport Method".Init();
        "Transport Method".Validate(Code, Code);
        "Transport Method".Validate(Description, Description);
        "Transport Method".Insert();
    end;
}

