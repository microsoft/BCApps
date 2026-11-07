codeunit 101412 "Create IC Dimension Value"
{
    // Create IC Dimension Value


    trigger OnRun()
    var
        CreateDimensionValue: Codeunit "Create Dimension";
    begin
        CreateDimensionValue.InsertDimensionValue(XCUSTOMERGROUP, XINTERCOMPANY, XIntercompanyCustomers, 0, '', '');
        CreateDimensionValue.InsertDimensionValue(XBUSINESSGROUP, XINTERCOMPANY, XIntercompanylc, 0, '', '');

        InsertData(XAREA, '10', XEurope, 3, false, XAREA, '10');
        InsertData(XAREA, '20', XEuropeNorth, 3, false, XAREA, '20');
        InsertData(XAREA, '30', XEuropeNorthEU, 0, false, XAREA, '30');
        InsertData(XAREA, '40', XEuropeNorthNonEU, 0, false, XAREA, '40');
        InsertData(XAREA, '45', XEuropeNorthTotal, 4, false, XAREA, '45');
        InsertData(XAREA, '50', XEuropeSouth, 0, false, XAREA, '50');
        InsertData(XAREA, '55', XEurope, 4, false, XAREA, '55');
        InsertData(XAREA, '60', XAmerica, 3, false, XAREA, '60');
        InsertData(XAREA, '70', XAmericaNorth, 0, false, XAREA, '70');
        InsertData(XAREA, '80', XAmericaSouth, 0, false, XAREA, '80');
        InsertData(XAREA, '85', XAmericaTotal, 4, false, XAREA, '85');

        InsertData(XBUSINESSGROUP, XHOME, XHOME, 0, false, XBUSINESSGROUP, XHOME);
        InsertData(XBUSINESSGROUP, XINDUSTRIAL, XINDUSTRIAL, 0, false, XBUSINESSGROUP, XINDUSTRIAL);
        InsertData(XBUSINESSGROUP, XINTERCOMPANY, XIntercompanylc, 0, false, XBUSINESSGROUP, XINTERCOMPANY);
        InsertData(XBUSINESSGROUP, XOFFICE, XOFFICE, 0, false, XBUSINESSGROUP, XOFFICE);

        InsertData(XCUSTOMERGROUP, XINSTITUTION, XPublicInstitutions, 0, false, XCUSTOMERGROUP, XINSTITUTION);
        InsertData(XCUSTOMERGROUP, XLARGE, XLargeBusiness, 0, false, XCUSTOMERGROUP, XLARGE);
        InsertData(XCUSTOMERGROUP, XMEDIUM, XMediumBusiness, 0, false, XCUSTOMERGROUP, XMEDIUM);
        InsertData(XCUSTOMERGROUP, XINTERCOMPANY, XIntercompanyCustomers, 0, false, XCUSTOMERGROUP, XINTERCOMPANY);
        InsertData(XCUSTOMERGROUP, XPRIVATE, XPrivateRetail, 0, false, XCUSTOMERGROUP, XPRIVATE);
        InsertData(XCUSTOMERGROUP, XSMALL, XSmallBusiness, 0, false, XCUSTOMERGROUP, XSMALL);
    end;

    var
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XINTERCOMPANY: Label 'INTERCOMPANY';
        XIntercompanyCustomers: Label 'Intercompany Customers';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XAREA: Label 'AREA';
        XEurope: Label 'Europe';
        XEuropeNorth: Label 'Europe North';
        XEuropeNorthEU: Label 'Europe North (EU)';
        XEuropeNorthNonEU: Label 'Europe North (Non EU)';
        XEuropeNorthTotal: Label 'Europe North, Total';
        XEuropeSouth: Label 'Europe South';
        XAmerica: Label 'America';
        XAmericaNorth: Label 'America North';
        XAmericaSouth: Label 'America South';
        XAmericaTotal: Label 'America, Total';
        XHOME: Label 'HOME';
        XINDUSTRIAL: Label 'INDUSTRIAL';
        XOFFICE: Label 'OFFICE';
        XINSTITUTION: Label 'INSTITUTION';
        XPublicInstitutions: Label 'Public Institutions';
        XLARGE: Label 'LARGE';
        XLargeBusiness: Label 'Large Business';
        XMEDIUM: Label 'MEDIUM';
        XMediumBusiness: Label 'Medium Business';
        XPRIVATE: Label 'PRIVATE';
        XPrivateRetail: Label 'Private, Retail';
        XSMALL: Label 'SMALL';
        XSmallBusiness: Label 'Small Business';
        XIntercompanylc: Label 'Intercompany';

    procedure InsertData("Dimension Code": Code[20]; "Code": Code[20]; Name: Text[30]; "Dimension Value Type": Option Standard,Heading,Total,"Begin-Total","End-Total"; Blocked: Boolean; "Map-to Dimension Code": Code[20]; "Map-to Dimension Value Code": Code[20])
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        ICDimensionValue.Init();
        ICDimensionValue.Validate("Dimension Code", "Dimension Code");
        ICDimensionValue.Code := Code;
        ICDimensionValue.Name := Name;
        ICDimensionValue.Validate("Dimension Value Type", "Dimension Value Type");
        ICDimensionValue.Blocked := Blocked;
        ICDimensionValue.Validate("Map-to Dimension Code", "Map-to Dimension Code");
        ICDimensionValue.Validate("Map-to Dimension Value Code", "Map-to Dimension Value Code");
        ICDimensionValue.Insert();
    end;
}

