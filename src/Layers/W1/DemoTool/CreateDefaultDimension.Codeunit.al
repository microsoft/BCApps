codeunit 101344 "Create Default Dimension"
{

    trigger OnRun()
    begin
        InsertDefaultDimension(13, XJO, XSALESPERSON, XJO, 2);
        InsertDefaultDimension(13, XOF, XSALESPERSON, XOF, 2);
        InsertDefaultDimension(13, XLT, XSALESPERSON, XLT, 2);
        InsertDefaultDimension(13, XRB, XPURCHASER, XRB, 2);
        InsertDefaultDimension(18, '10000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '10000', XAREA, '30', 1);
        InsertDefaultDimension(18, '20000', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimension(18, '20000', XAREA, '30', 1);
        InsertDefaultDimension(18, '30000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '30000', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimension(18, '30000', XAREA, '30', 1);
        InsertDefaultDimension(18, '40000', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '40000', XAREA, '30', 1);
        InsertDefaultDimension(18, '50000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '50000', XBUSINESSGROUP, XOFFICE, 2);
        InsertDefaultDimension(18, '50000', XAREA, '30', 1);
        InsertDefaultDimension(18, '01121212', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '01121212', XAREA, '70', 1);
        InsertDefaultDimension(18, '01121212', XBUSINESSGROUP, XINDUSTRIAL, 0);
        InsertDefaultDimension(18, '01445544', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimension(18, '01445544', XAREA, '70', 1);
        InsertDefaultDimension(18, '01445544', XSALESCAMPAIGN, XWINTER, 0);
        InsertDefaultDimension(18, '01454545', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '01454545', XAREA, '70', 1);
        InsertDefaultDimension(18, '01454545', XBUSINESSGROUP, XOFFICE, 0);
        InsertDefaultDimension(18, '31505050', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '31505050', XAREA, '30', 1);
        InsertDefaultDimension(18, '31669966', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '31669966', XAREA, '30', 1);
        InsertDefaultDimension(18, '31669966', XBUSINESSGROUP, XINDUSTRIAL, 2);
        InsertDefaultDimension(18, '31987987', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '31987987', XAREA, '30', 1);
        InsertDefaultDimension(18, '31987987', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(18, '32124578', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimension(18, '32124578', XAREA, '30', 1);
        InsertDefaultDimension(18, '32124578', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(18, '32656565', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '32656565', XAREA, '30', 1);
        InsertDefaultDimension(18, '32789456', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '32789456', XAREA, '30', 1);
        InsertDefaultDimension(18, '34010199', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '34010199', XAREA, '50', 1);
        InsertDefaultDimension(18, '34010100', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '34010100', XAREA, '50', 1);
        InsertDefaultDimension(18, '34010100', XBUSINESSGROUP, XHOME, 0);
        InsertDefaultDimension(18, '34010100', XSALESCAMPAIGN, XWINTER, 0);
        InsertDefaultDimension(18, '34010602', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '34010602', XAREA, '50', 1);
        InsertDefaultDimension(18, '35122112', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '35122112', XAREA, '40', 1);
        InsertDefaultDimension(18, '35451236', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '35451236', XAREA, '40', 1);
        InsertDefaultDimension(18, '35963852', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '35963852', XAREA, '40', 1);
        InsertDefaultDimension(18, '35963852', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(18, '38128456', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '38128456', XAREA, '40', 1);
        InsertDefaultDimension(18, '38546552', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '38546552', XAREA, '40', 1);
        InsertDefaultDimension(18, '38632147', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '38632147', XAREA, '40', 1);
        InsertDefaultDimension(18, '38632147', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimension(18, '42147258', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '42147258', XAREA, '40', 1);
        InsertDefaultDimension(18, '42258258', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '42258258', XAREA, '40', 1);
        InsertDefaultDimension(18, '42369147', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '42369147', XAREA, '40', 1);
        InsertDefaultDimension(18, '43687129', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '43687129', XAREA, '30', 1);
        InsertDefaultDimension(18, '43687129', XBUSINESSGROUP, XOFFICE, 2);
        InsertDefaultDimension(18, '43852147', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '43852147', XAREA, '30', 1);
        InsertDefaultDimension(18, '43871144', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '43871144', XAREA, '30', 1);
        InsertDefaultDimension(18, '45282828', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '45282828', XAREA, '30', 1);
        InsertDefaultDimension(18, '45779977', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '45779977', XAREA, '30', 1);
        InsertDefaultDimension(18, '45979797', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '45979797', XAREA, '30', 1);
        InsertDefaultDimension(18, '46251425', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimension(18, '46251425', XAREA, '30', 1);
        InsertDefaultDimension(18, '46525241', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '46525241', XAREA, '30', 1);
        InsertDefaultDimension(18, '46897889', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '46897889', XAREA, '30', 1);
        InsertDefaultDimension(18, '46897889', XBUSINESSGROUP, XINDUSTRIAL, 0);
        InsertDefaultDimension(18, '46897889', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(18, '47523687', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '47523687', XAREA, '40', 1);
        InsertDefaultDimension(18, '47523687', XBUSINESSGROUP, XOFFICE, 2);
        InsertDefaultDimension(18, '47563218', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '47563218', XAREA, '40', 1);
        InsertDefaultDimension(18, '47586954', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '47586954', XAREA, '40', 1);
        InsertDefaultDimension(18, '49525252', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '49525252', XAREA, '30', 1);
        InsertDefaultDimension(18, '49525252', XSALESCAMPAIGN, XWINTER, 0);
        InsertDefaultDimension(18, '49858585', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '49858585', XAREA, '30', 1);
        InsertDefaultDimension(18, '49858585', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimension(18, '44180220', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '44180220', XAREA, '30', 1);
        InsertDefaultDimension(18, '44171511', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimension(18, '44171511', XAREA, '30', 1);
        InsertDefaultDimension(18, '44171511', XBUSINESSGROUP, XINDUSTRIAL, 2);
        InsertDefaultDimension(18, '44756404', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '44756404', XAREA, '30', 1);
        InsertDefaultDimension(18, '44756404', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(18, '41597832', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '41597832', XAREA, '40', 1);
        InsertDefaultDimension(18, '41497647', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '41497647', XAREA, '40', 1);
        InsertDefaultDimension(18, '41231215', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimension(18, '41231215', XAREA, '40', 1);
        InsertDefaultDimension(23, '10000', XAREA, '30', 1);
        InsertDefaultDimension(23, '10000', XBUSINESSGROUP, XINDUSTRIAL, 0);
        InsertDefaultDimension(23, '20000', XAREA, '30', 1);
        InsertDefaultDimension(23, '30000', XAREA, '30', 1);
        InsertDefaultDimension(23, '40000', XAREA, '30', 1);
        InsertDefaultDimension(23, '40000', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimension(23, '50000', XAREA, '30', 1);
        InsertDefaultDimension(23, '10000', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(23, '01254796', XAREA, '70', 1);
        InsertDefaultDimension(23, '01587796', XAREA, '70', 1);
        InsertDefaultDimension(23, '01863656', XAREA, '70', 1);
        InsertDefaultDimension(23, '01863656', XBUSINESSGROUP, XHOME, 0);
        InsertDefaultDimension(23, '01863656', XSALESCAMPAIGN, XWINTER, 0);
        InsertDefaultDimension(23, '31147896', XAREA, '30', 1);
        InsertDefaultDimension(23, '31568974', XAREA, '30', 1);
        InsertDefaultDimension(23, '31580305', XAREA, '30', 1);
        InsertDefaultDimension(23, '32456123', XAREA, '30', 1);
        InsertDefaultDimension(23, '32456123', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimension(23, '32554455', XAREA, '30', 1);
        InsertDefaultDimension(23, '32665544', XAREA, '30', 1);
        InsertDefaultDimension(23, '34151086', XAREA, '50', 1);
        InsertDefaultDimension(23, '34280789', XAREA, '50', 1);
        InsertDefaultDimension(23, '34110257', XAREA, '50', 1);
        InsertDefaultDimension(23, '35225588', XAREA, '30', 1);
        InsertDefaultDimension(23, '35336699', XAREA, '30', 1);
        InsertDefaultDimension(23, '35336699', XBUSINESSGROUP, XINDUSTRIAL, 2);
        InsertDefaultDimension(23, '35741852', XAREA, '30', 1);
        InsertDefaultDimension(23, '38458653', XAREA, '40', 1);
        InsertDefaultDimension(23, '38521479', XAREA, '40', 1);
        InsertDefaultDimension(23, '38654478', XAREA, '40', 1);
        InsertDefaultDimension(23, '38654478', XBUSINESSGROUP, XOFFICE, 0);
        InsertDefaultDimension(23, '38654478', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(23, '42125678', XAREA, '40', 1);
        InsertDefaultDimension(23, '42784512', XAREA, '40', 1);
        InsertDefaultDimension(23, '42895623', XAREA, '40', 1);
        InsertDefaultDimension(23, '43258545', XAREA, '30', 1);
        InsertDefaultDimension(23, '43589632', XAREA, '30', 1);
        InsertDefaultDimension(23, '43698547', XAREA, '30', 1);
        InsertDefaultDimension(23, '43698547', XBUSINESSGROUP, XHOME, 0);
        InsertDefaultDimension(23, '43698547', XSALESCAMPAIGN, XWINTER, 0);
        InsertDefaultDimension(23, '45774477', XAREA, '30', 1);
        InsertDefaultDimension(23, '45858585', XAREA, '30', 1);
        InsertDefaultDimension(23, '45868686', XAREA, '30', 1);
        InsertDefaultDimension(23, '45868686', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(23, '46558855', XAREA, '30', 1);
        InsertDefaultDimension(23, '46635241', XAREA, '30', 1);
        InsertDefaultDimension(23, '46895623', XAREA, '30', 1);
        InsertDefaultDimension(23, '47521478', XAREA, '40', 1);
        InsertDefaultDimension(23, '47562214', XAREA, '40', 1);
        InsertDefaultDimension(23, '47586622', XAREA, '40', 1);
        InsertDefaultDimension(23, '47586622', XBUSINESSGROUP, XINDUSTRIAL, 2);
        InsertDefaultDimension(23, '47586622', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimension(23, '49454647', XAREA, '30', 1);
        InsertDefaultDimension(23, '49494949', XAREA, '30', 1);
        InsertDefaultDimension(23, '49989898', XAREA, '30', 1);
        InsertDefaultDimension(23, '44756404', XAREA, '30', 1);
        InsertDefaultDimension(23, '44729910', XAREA, '30', 1);
        InsertDefaultDimension(23, '44127904', XAREA, '30', 1);
        InsertDefaultDimension(23, '41568934', XAREA, '40', 1);
        InsertDefaultDimension(23, '41568934', XBUSINESSGROUP, XOFFICE, 0);
        InsertDefaultDimension(23, '41483124', XAREA, '40', 1);
        InsertDefaultDimension(23, '41124089', XAREA, '40', 1);
        InsertDefaultDimension(23, '44127914', XAREA, '30', 1);

        SourceCodeSetup.Get();
        InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 18, 1);
        InsertDefaultDimensionPriority(SourceCodeSetup.Sales, 27, 2);
        InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 18, 1);
        InsertDefaultDimensionPriority(SourceCodeSetup."Sales Journal", 27, 2);
        InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 23, 1);
        InsertDefaultDimensionPriority(SourceCodeSetup.Purchases, 27, 2);
        InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 23, 1);
        InsertDefaultDimensionPriority(SourceCodeSetup."Purchase Journal", 27, 2);

        SetAllowedValuesFilter(18, '01121212', XAREA, '70|80');
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        XJO: Label 'JO';
        XSALESPERSON: Label 'SALESPERSON';
        XOF: Label 'OF';
        XLT: Label 'LT';
        XRB: Label 'RB';
        XPURCHASER: Label 'PURCHASER';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XMEDIUM: Label 'MEDIUM';
        XAREA: Label 'AREA';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XHOME: Label 'HOME';
        XSMALL: Label 'SMALL';
        XINDUSTRIAL: Label 'INDUSTRIAL';
        XLARGE: Label 'LARGE';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XOFFICE: Label 'OFFICE';
        XSUMMER: Label 'SUMMER';
        XWINTER: Label 'WINTER';

    procedure InsertDefaultDimension("Table ID": Integer; "No.": Code[20]; "Dimension Code": Code[20]; "Dimension Value Code": Code[20]; "Value Posting": Option)
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Init();
        DefaultDimension.Validate("Table ID", "Table ID");
        DefaultDimension.Validate("No.", "No.");
        DefaultDimension.Validate("Dimension Code", "Dimension Code");
        DefaultDimension.Validate("Dimension Value Code", "Dimension Value Code");
        DefaultDimension.Validate("Value Posting", "Value Posting");
        DefaultDimension.Insert(true);
    end;

    local procedure SetAllowedValuesFilter(TableID: Integer; No: Code[20]; DimensionCode: Code[20]; AllowedValuesFilter: Text[250])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(TableID, No, DimensionCode);
        DefaultDimension.Validate("Allowed Values Filter", AllowedValuesFilter);
        DefaultDimension.Modify(true);
    end;

    procedure InsertDefaultDimensionPriority("Source Code": Code[20]; "Table ID": Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.Init();
        DefaultDimensionPriority.Validate("Source Code", "Source Code");
        DefaultDimensionPriority.Validate("Table ID", "Table ID");
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Insert(true);
    end;

    procedure CreateEvaluationData()
    begin
        InsertDefaultDimension(13, XJO, XSALESPERSON, XJO, 2);
        InsertDefaultDimension(13, XOF, XSALESPERSON, XOF, 2);
        InsertDefaultDimension(13, XLT, XSALESPERSON, XLT, 2);
        InsertDefaultDimension(13, XRB, XPURCHASER, XRB, 2);

        InsertDefaultDimension(18, '10000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimensionAreaEvaluation(18, '10000');
        InsertDefaultDimension(18, '20000', XCUSTOMERGROUP, XLARGE, 2);
        InsertDefaultDimensionAreaEvaluation(18, '20000');
        InsertDefaultDimension(18, '30000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '30000', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimensionAreaEvaluation(18, '30000');
        InsertDefaultDimension(18, '40000', XCUSTOMERGROUP, XSMALL, 2);
        InsertDefaultDimensionAreaEvaluation(18, '40000');
        InsertDefaultDimension(18, '50000', XCUSTOMERGROUP, XMEDIUM, 2);
        InsertDefaultDimension(18, '50000', XBUSINESSGROUP, XOFFICE, 2);
        InsertDefaultDimensionAreaEvaluation(18, '50000');

        InsertDefaultDimensionAreaEvaluation(23, '10000');
        InsertDefaultDimension(23, '10000', XBUSINESSGROUP, XINDUSTRIAL, 0);
        InsertDefaultDimension(23, '10000', XSALESCAMPAIGN, XSUMMER, 0);
        InsertDefaultDimensionAreaEvaluation(23, '20000');
        InsertDefaultDimensionAreaEvaluation(23, '30000');
        InsertDefaultDimensionAreaEvaluation(23, '40000');
        InsertDefaultDimension(23, '40000', XBUSINESSGROUP, XHOME, 2);
        InsertDefaultDimensionAreaEvaluation(23, '50000');

        SetAllowedValuesFilter(18, '30000', XAREA, '70|80');
    end;

    local procedure InsertDefaultDimensionAreaEvaluation(TableID: Integer; No: Code[20])
    var
        CreateCustomer: Codeunit "Create Customer";
        CreateVendor: Codeunit "Create Vendor";
    begin
        case TableID of
            Database::Customer:
                InsertDefaultDimension(TableID, No, XAREA, CreateCustomer.GetDefaultAreaDimensionValueEvaluation(No), 1);
            Database::Vendor:
                InsertDefaultDimension(TableID, No, XAREA, CreateVendor.GetDefaultAreaDimensionValueEvaluation(No), 1);
        end;
    end;
}

