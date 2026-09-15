codeunit 101342 "Create Dimension"
{

    trigger OnRun()
    var
        Language: Codeunit Language;
    begin
        DemoDataSetup.Get();
        InsertDimension(XDEPARTMENT, XDEPARTMENTlc, '');
        InsertDimensionValue(XDEPARTMENT, XADM, XAdministrationlc, 0, '', '');
        InsertDimensionValue(XDEPARTMENT, XSALES, XSaleslc, 0, '', '');
        InsertDimensionValue(XDEPARTMENT, XPROD, XProduction, 0, '', '');
        InsertDimension(XPROJECT, XPROJECTlc, '');
        InsertDimensionValue(XPROJECT, XMERCEDES, XMercedes300, 0, '', '');
        InsertDimensionValue(XPROJECT, XTOYOTA, XToyotaSupra30, 0, '', '');
        InsertDimensionValue(XPROJECT, XVW, XVWTransporter, 0, '', '');
        InsertDimension(XCUSTOMERGROUP, XCustomerGrp, '');
        InsertDimensionValue(XCUSTOMERGROUP, XPRIVATE, XPrivatelc, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XSMALL, XSmallBusiness, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XMEDIUM, XMediumBusiness, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XLARGE, XLargeBusiness, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XInstitution, XInstitutionlc, 0, '', '');
        InsertDimension(XBUSINESSGROUP, XBusinessGrp, '');
        InsertDimensionValue(XBUSINESSGROUP, XHOME, XHomelc, 0, '', '');
        InsertDimensionValue(XBUSINESSGROUP, XOFFICE, XOfficelc, 0, '', '');
        InsertDimensionValue(XBUSINESSGROUP, XINDUSTRIAL, XINDUSTRIALlc, 0, '', '');
        InsertDimension(XAREA, XAREAlc, '');
        InsertDimensionValue(XAREA, '10', XEurope, 3, '', '');
        InsertDimensionValue(XAREA, '20', XEuropeNorth, 3, '', '');
        InsertDimensionValue(XAREA, '30', XEuropeNorthEU, 0, '', '');
        InsertDimensionValue(XAREA, '40', XEuropeNorthNonEU, 0, '', '');
        InsertDimensionValue(XAREA, '45', XEuropeNorthTotal, 4, '', '');
        InsertDimensionValue(XAREA, '50', XEuropeSouth, 0, '', '');
        InsertDimensionValue(XAREA, '55', XEuropeTotal, 4, '10..55', '');
        InsertDimensionValue(XAREA, '60', XAmerica, 3, '', '');
        InsertDimensionValue(XAREA, '70', XAmericaNorth, 0, '', '');
        InsertDimensionValue(XAREA, '80', XAmericaSouth, 0, '', '');
        InsertDimensionValue(XAREA, '85', XAmericaTotal, 4, '60..85', '');
        InsertDimension(XSALESCAMPAIGN, XSALESCAMPAIGNlc, '');
        InsertDimensionValue(XSALESCAMPAIGN, XWINTER, XWinterlc, 0, '', '');
        InsertDimensionValue(XSALESCAMPAIGN, XSUMMER, XSummerlc, 0, '', '');
        InsertDimension(XSALESPERSON, XSALESPERSONlc, '');
        InsertDimensionValue(XSALESPERSON, XJO, XJimOlive, 0, '', '');
        InsertDimensionValue(XSALESPERSON, XOF, XOtisFalls, 0, '', '');
        InsertDimensionValue(XSALESPERSON, XLT, XLinaTownsend, 0, '', '');
        InsertDimension(XPURCHASER, XPURCHASERlc, '');
        InsertDimensionValue(XPURCHASER, XRB, XRobinBettencourt, 0, '', '');
        InsertDimensionValue(XPURCHASER, XTD, XTerryDodds, 0, '', '');
        InsertDimensionValue(XPURCHASER, XMH, XMartyHorst, 0, '', '');

        InsertDimensionTransl(XDEPARTMENT, Language.GetDefaultApplicationLanguageId(), 'Department', 'Department Code', 'Department Filter');
        InsertDimensionTransl(XPROJECT, Language.GetDefaultApplicationLanguageId(), 'Project', 'Project Code', 'Project Filter');
        InsertDimensionTransl(XCUSTOMERGROUP, Language.GetDefaultApplicationLanguageId(), 'Customer Group', 'Customergroup Code', 'Customergroup Filter');
        InsertDimensionTransl(XBUSINESSGROUP, Language.GetDefaultApplicationLanguageId(), 'Business Group', 'Businessgroup Code', 'Businessgroup Filter');
        InsertDimensionTransl(XAREA, Language.GetDefaultApplicationLanguageId(), 'Area', 'Area Code', 'Area Filter');
        InsertDimensionTransl(XSALESCAMPAIGN, Language.GetDefaultApplicationLanguageId(), 'Sales campaign', 'Salescampaign Code', 'Salescampaign Filter');
        InsertDimensionTransl(XSALESPERSON, Language.GetDefaultApplicationLanguageId(), 'Salesperson', 'Salesperson Code', 'Salesperson Filter');
        InsertDimensionTransl(XPURCHASER, Language.GetDefaultApplicationLanguageId(), 'Purchaser', 'Purchaser Code', 'Purchaser Filter');

        DimensionValueIndent.Indent();
    end;

    internal procedure GetDepartmentCode(): Code[20]
    begin
        exit(XDEPARTMENT);
    end;

    internal procedure GetDepartmentAMDCode(): Code[20]
    begin
        exit(XADM);
    end;

    internal procedure GetDepartmentSALESCode(): Code[20]
    begin
        exit(XSALES);
    end;

    internal procedure GetDepartmentPRODCode(): Code[20]
    begin
        exit(XPROD);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        DimensionValueIndent: Codeunit "Dimension Value-Indent";
        XDEPARTMENT: Label 'DEPARTMENT';
        XADM: Label 'ADM';
        XAdministrationlc: Label 'Administration';
        XSALES: Label 'SALES';
        XPROD: Label 'PROD';
        XProduction: Label 'Production';
        XPROJECT: Label 'PROJECT';
        XMERCEDES: Label 'MERCEDES';
        XMercedes300: Label 'Mercedes 300';
        XTOYOTA: Label 'TOYOTA';
        XToyotaSupra30: Label 'Toyota Supra 3.0';
        XVW: Label 'VW';
        XVWTransporter: Label 'VW Transporter';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XCustomerGrp: Label 'Customer Group';
        XPRIVATE: Label 'PRIVATE';
        XSMALL: Label 'SMALL';
        XSmallBusiness: Label 'Small Business';
        XMEDIUM: Label 'MEDIUM';
        XMediumBusiness: Label 'Medium Business';
        XLARGE: Label 'LARGE';
        XLargeBusiness: Label 'Large Business';
        XInstitution: Label 'INSTITUTION';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XBusinessGrp: Label 'Business Group';
        XHOME: Label 'HOME';
        XOFFICE: Label 'OFFICE';
        XINDUSTRIAL: Label 'INDUSTRIAL';
        XEurope: Label 'Europe';
        XEuropeNorth: Label 'Europe North';
        XEuropeNorthEU: Label 'Europe North (EU)';
        XAREA: Label 'AREA';
        XEuropeNorthNonEU: Label 'Europe North (Non EU)';
        XEuropeNorthTotal: Label 'Europe North, Total';
        XEuropeSouth: Label 'Europe South';
        XEuropeTotal: Label 'Europe, Total';
        XAmerica: Label 'America';
        XAmericaNorth: Label 'America North';
        XAmericaSouth: Label 'America South';
        XAmericaTotal: Label 'America, Total';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XWINTER: Label 'WINTER';
        XSUMMER: Label 'SUMMER';
        XSALESPERSON: Label 'SALESPERSON';
        XJO: Label 'JO';
        XJimOlive: Label 'Jim Olive';
        XOF: Label 'OF';
        XOtisFalls: Label 'Otis Falls';
        XPURCHASER: Label 'PURCHASER';
        XRB: Label 'RB';
        XRobinBettencourt: Label 'Robin Bettencourt';
        XTD: Label 'TD';
        XTerryDodds: Label 'Terry Dodds';
        XMH: Label 'MH';
        XMartyHorst: Label 'Marty Horst';
        XAREAlc: Label 'Area';
        XDEPARTMENTlc: Label 'Department';
        XPROJECTlc: Label 'Project';
        XSALESCAMPAIGNlc: Label 'Sales campaign';
        XPURCHASERlc: Label 'Purchaser';
        XSALESPERSONlc: Label 'Salesperson';
        XHomelc: Label 'Home';
        XPrivatelc: Label 'Private';
        XOfficelc: Label 'Office';
        XSaleslc: Label 'Sales';
        XInstitutionlc: Label 'Institution';
        XINDUSTRIALlc: Label 'Industrial';
        XWinterlc: Label 'Winter';
        XSummerlc: Label 'Summer';
        XLT: Label 'LT';
        XLinaTownsend: Label 'Lina Townsend';

    procedure InsertDimension("Code": Code[20]; Name: Text[30]; "Consolidation Code": Code[20])
    var
        Dimension: Record Dimension;
    begin
        Dimension.Init();
        Dimension.Validate(Code, Code);
        Dimension.Validate(Name, Name);
        Dimension.Validate("Consolidation Code", "Consolidation Code");
        Dimension.Insert();
    end;

    procedure InsertDimensionValue("Dimension Code": Code[20]; "Code": Code[20]; Name: Text[50]; "Dimension Value Type": Option; Totaling: Text[80]; "Consolidation Code": Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", "Dimension Code");
        DimensionValue.Validate(Code, Code);
        DimensionValue.Validate(Name, Name);
        DimensionValue.Validate("Dimension Value Type", "Dimension Value Type");
        DimensionValue.Validate(Totaling, Totaling);
        DimensionValue.Validate("Consolidation Code", "Consolidation Code");
        if DimensionValue."Dimension Code" = GetGlobalDimensionCode(1) then
            DimensionValue."Global Dimension No." := 1;
        if DimensionValue."Dimension Code" = GetGlobalDimensionCode(2) then
            DimensionValue."Global Dimension No." := 2;
        DimensionValue.Insert();
    end;

    procedure InsertDimensionTransl("Code": Code[20]; LanguageID: Integer; Name: Text[30]; CodeCaption: Text[30]; FilterCaption: Text[30])
    var
        DimensionTranslation: Record "Dimension Translation";
    begin
        DimensionTranslation.Init();
        DimensionTranslation.Code := Code;
        DimensionTranslation.Validate("Language ID", LanguageID);
        DimensionTranslation.Name := Name;
        DimensionTranslation."Code Caption" := CodeCaption;
        DimensionTranslation."Filter Caption" := FilterCaption;
        DimensionTranslation.Insert();
    end;

    procedure InsertEvaluationData()
    var
        Language: Codeunit Language;
    begin
        DemoDataSetup.Get();
        InsertDimension(XDEPARTMENT, XDEPARTMENTlc, '');
        InsertDimensionValue(XDEPARTMENT, XADM, XAdministrationlc, 0, '', '');
        InsertDimensionValue(XDEPARTMENT, XSALES, XSaleslc, 0, '', '');
        InsertDimensionValue(XDEPARTMENT, XPROD, XProduction, 0, '', '');
        InsertDimension(XCUSTOMERGROUP, XCustomerGrp, '');
        InsertDimensionValue(XCUSTOMERGROUP, XSMALL, XSmallBusiness, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XMEDIUM, XMediumBusiness, 0, '', '');
        InsertDimensionValue(XCUSTOMERGROUP, XLARGE, XLargeBusiness, 0, '', '');
        InsertDimension(XBUSINESSGROUP, XBusinessGrp, '');
        InsertDimensionValue(XBUSINESSGROUP, XHOME, XHomelc, 0, '', '');
        InsertDimensionValue(XBUSINESSGROUP, XOFFICE, XOfficelc, 0, '', '');
        InsertDimensionValue(XBUSINESSGROUP, XINDUSTRIAL, XINDUSTRIALlc, 0, '', '');
        InsertDimension(XAREA, XAREAlc, '');
        InsertDimensionValue(XAREA, '10', XEurope, 3, '', '');
        InsertDimensionValue(XAREA, '20', XEuropeNorth, 3, '', '');
        InsertDimensionValue(XAREA, '30', XEuropeNorthEU, 0, '', '');
        InsertDimensionValue(XAREA, '40', XEuropeNorthNonEU, 0, '', '');
        InsertDimensionValue(XAREA, '45', XEuropeNorthTotal, 4, '', '');
        InsertDimensionValue(XAREA, '50', XEuropeSouth, 0, '', '');
        InsertDimensionValue(XAREA, '55', XEuropeTotal, 4, '10..55', '');
        InsertDimensionValue(XAREA, '60', XAmerica, 3, '', '');
        InsertDimensionValue(XAREA, '70', XAmericaNorth, 0, '', '');
        InsertDimensionValue(XAREA, '80', XAmericaSouth, 0, '', '');
        InsertDimensionValue(XAREA, '85', XAmericaTotal, 4, '60..85', '');
        InsertDimension(XSALESCAMPAIGN, XSALESCAMPAIGNlc, '');
        InsertDimensionValue(XSALESCAMPAIGN, XWINTER, XWinterlc, 0, '', '');
        InsertDimensionValue(XSALESCAMPAIGN, XSUMMER, XSummerlc, 0, '', '');
        InsertDimension(XSALESPERSON, XSALESPERSONlc, '');
        InsertDimensionValue(XSALESPERSON, XJO, XJimOlive, 0, '', '');
        InsertDimensionValue(XSALESPERSON, XOF, XOtisFalls, 0, '', '');
        InsertDimensionValue(XSALESPERSON, XLT, XLinaTownsend, 0, '', '');
        InsertDimension(XPURCHASER, XPURCHASERlc, '');
        InsertDimensionValue(XPURCHASER, XRB, XRobinBettencourt, 0, '', '');
        InsertDimensionValue(XPURCHASER, XTD, XTerryDodds, 0, '', '');
        InsertDimensionValue(XPURCHASER, XMH, XMartyHorst, 0, '', '');

        InsertDimensionTransl(XDEPARTMENT, Language.GetDefaultApplicationLanguageId(), 'Department', 'Department Code', 'Department Filter');
        InsertDimensionTransl(XCUSTOMERGROUP, Language.GetDefaultApplicationLanguageId(), 'Customer Group', 'Customergroup Code', 'Customergroup Filter');
        InsertDimensionTransl(XBUSINESSGROUP, Language.GetDefaultApplicationLanguageId(), 'Business Group', 'Businessgroup Code', 'Businessgroup Filter');
        InsertDimensionTransl(XAREA, Language.GetDefaultApplicationLanguageId(), 'Area', 'Area Code', 'Area Filter');
        InsertDimensionTransl(XSALESCAMPAIGN, Language.GetDefaultApplicationLanguageId(), 'Sales campaign', 'Salescampaign Code', 'Salescampaign Filter');
        InsertDimensionTransl(XSALESPERSON, Language.GetDefaultApplicationLanguageId(), 'Salesperson', 'Salesperson Code', 'Salesperson Filter');
        InsertDimensionTransl(XPURCHASER, Language.GetDefaultApplicationLanguageId(), 'Purchaser', 'Purchaser Code', 'Purchaser Filter');

        DimensionValueIndent.Indent();
    end;

    procedure GetGlobalDimensionCode(Index: Integer): Code[20]
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Extended:
                begin
                    if Index = 1 then
                        exit(XDEPARTMENT);
                    if Index = 2 then
                        exit(XPROJECT);
                end;
            DemoDataSetup."Data Type"::Evaluation:
                begin
                    if Index = 1 then
                        exit(XDEPARTMENT);
                    if Index = 2 then
                        exit(XCUSTOMERGROUP);
                end;
        end;
        exit('');
    end;
}

