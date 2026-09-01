codeunit 101600 "Create Employee"
{

    trigger OnRun()
    begin
        InsertGeneral(
          XEH, XEster, '', XHenderson, XEHENDERSON, X5RusselStreet, CreatePostCode.Convert('GB-PE17 4RN'),
          XManagingDirector, Employee.Gender::Female);
        InsertContact(XEH, '6743', '', '4564-4564-7831', '4465-4899-4643', '', 'Ester Henderson');
        InsertAdministration(XEH, XSALES, '', XADM, XMONTH, 19960601D, XEH, '', XUADMI, '4151746513235-45646');

        InsertGeneral(
          XJO, XJim, '', XOlive, XJOLIVE, X47MainStreet, CreatePostCode.Convert('GB-W1 3AL'),
          XSalesManager, Employee.Gender::Male);
        InsertContact(XJO, '1415', '', '1234-5678-9012', '0678-9012-3456', '', 'Jim Olive');
        InsertAdministration(XJO, XSALES, '', XADM, XMONTH, 20010101D, XJO, '', XUADMI, '3462345-235');

        InsertGeneral(
          XOF, XOtis, '', XFalls, XOFALLS, X327ElmwoodStreet, CreatePostCode.Convert('GB-W1 3AL'),
          XProductionManager, Employee.Gender::Male);
        InsertContact(XOF, '4564', '', '1546-3124-4646', '6549-3216-7415', '', 'Otis Falls');
        InsertAdministration(XOF, XADM, '', XADM, XMONTH, 19910101D, XOF, '', XUADMI, '346246546345-24535');

        InsertGeneral(
          XLT, XLina, '', XTownsend, XLTOWNSEND, X10HighStreet, CreatePostCode.Convert('GB-N16 34Z'),
          XDesigner, Employee.Gender::Female);
        InsertContact(XLT, '3545', '', '1234-6545-5649', '0678-1234-5466', '', 'Lina Townsend');
        InsertAdministration(XLT, XPROD, '', XDEV, XHOUR, 19990101D, XLT, XLina, XUDEVE, '541236-654');

        InsertGeneral(
          XRB, XRobin, '', XBettencourt, XRBETTENCOURT, X7MaddistonRoad, CreatePostCode.Convert('GB-W1 3AL'),
          XSecretary, Employee.Gender::"Non-binary");
        InsertContact(XRB, '6571', '', '1234-1643-4384', '0678-2534-2013', '', 'Robin Bettencourt');
        InsertAdministration(XRB, XPROD, '', XPROD, X14DAYS, 19960301D, XRB, '', XUDEVE, '541236-654');

        InsertGeneral(
          XMH, XMarty, '', XHorst, XMHORST, X49GrahamsRoad, CreatePostCode.Convert('GB-N12 5XY'),
          XProductionAssistant, Employee.Gender::Male);
        InsertContact(XMH, '4456', '', '1234-5464-5446', '0678-2135-4649', '', 'Marty Horst');
        InsertAdministration(XMH, XPROD, '', XPROD, X14DAYS, 19960301D, '', XMarty, XUPROD, '234654-631');

        InsertGeneral(
          XTD, XTerry, '', XDodds, XTDODDS, X66BJamesRoad, CreatePostCode.Convert('GB-N12 5XY'),
          XProductionAssistant, Employee.Gender::Male);
        InsertContact(XTD, '4653', '', '1234-6545-8799', '0678-8712-5466', '', 'Terry Dodds');
        InsertAdministration(XTD, XPROD, '', XPROD, X14DAYS, 19960301D, '', XTerry, XUPROD, '234654-631');
    end;

    var
        Employee: Record Employee;
        CreatePostCode: Codeunit "Create Post Code";
        XEH: Label 'EH';
        XEster: Label 'Ester';
        XHenderson: Label 'Henderson';
        XEHENDERSON: Label 'EHENDERSON';
        X5RusselStreet: Label '5 Russel Street';
        XSecretary: Label 'Secretary';
        XUADMI: Label 'UADMI';
        XSALES: Label 'SALES';
        XADM: Label 'ADM';
        XMONTH: Label 'MONTH';
        XJO: Label 'JO';
        XJim: Label 'Jim';
        XOlive: Label 'Olive';
        XJOLIVE: Label 'JOLIVE';
        X47MainStreet: Label '47 Main Street';
        XSalesManager: Label 'Sales Manager';
        XOF: Label 'OF';
        XOtis: Label 'Otis';
        XFalls: Label 'Falls';
        XOFALLS: Label 'OFALLS';
        X327ElmwoodStreet: Label '327 Elmwood Street';
        XManagingDirector: Label 'Managing Director';
        XLT: Label 'LT';
        XLina: Label 'Lina';
        XTownsend: Label 'Townsend';
        XLTOWNSEND: Label 'LTOWNSEND';
        X10HighStreet: Label '10 High Street';
        XDesigner: Label 'Designer';
        XPROD: Label 'PROD';
        XDEV: Label 'DEV';
        XHOUR: Label 'HOUR';
        XUDEVE: Label 'UDEVE';
        XRB: Label 'RB';
        XRobin: Label 'Robin';
        XBettencourt: Label 'Bettencourt';
        XRBETTENCOURT: Label 'RBETTENCOURT';
        X7MaddistonRoad: Label '7 Maddiston Road';
        XProductionManager: Label 'Production Manager';
        X14DAYS: Label '14DAYS';
        XUPROD: Label 'UPROD';
        XMH: Label 'MH';
        XMarty: Label 'Marty';
        XHorst: Label 'Horst';
        XMHORST: Label 'MHORST';
        X49GrahamsRoad: Label '49 Grahams Road';
        XProductionAssistant: Label 'Production Assistant';
        XTD: Label 'TD';
        XTerry: Label 'Terry';
        XDodds: Label 'Dodds';
        XTDODDS: Label 'TDODDS';
        X66BJamesRoad: Label '66B James Road';
        XPERSONAL: Label 'PERSONAL';
        XPERSEXP: Label 'PERSEXP';

    procedure InsertGeneral("No.": Code[20]; "First Name": Text[30]; "Middle Name": Text[30]; "Last Name": Text[30]; Initials: Text[30]; Address: Text[30]; "Post Code": Code[20]; Title: Text[30]; Sex: Enum "Employee Gender")
    begin
        Employee.Init();
        Employee."No." := "No.";
        Employee."First Name" := "First Name";
        Employee."Middle Name" := "Middle Name";
        Employee."Last Name" := "Last Name";
        Employee.Validate(Initials, Initials);
        Employee.Address := Address;
        Employee."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Employee.City := CreatePostCode.FindCity("Post Code");
        Employee."Job Title" := Title;
        Employee.Gender := Sex;
        Employee.Insert();
    end;

    procedure InsertContact("No.": Code[20]; "Internal Phone No.": Text[30]; Pager: Text[30]; "Mobile Phone No.": Text[30]; "Phone No.": Text[30]; Email: Text[80]; NameForImage: Text)
    var
        DemoDataSetup: Record "Demo Data Setup";
        ImagePath: Text;
    begin
        Employee.Get("No.");
        Employee.Extension := "Internal Phone No.";
        Employee.Pager := Pager;
        Employee."Mobile Phone No." := "Mobile Phone No.";
        Employee."Phone No." := "Phone No.";
        if Email <> '' then
            Employee."E-Mail" := Email
        else
            Employee."E-Mail" := StrSubstNo('%1@cronus-demosite.com', LowerCase(Employee."No."));
        if DemoDataSetup.Get() then;
        ImagePath := DemoDataSetup."Path to Picture Folder" + StrSubstNo('Images\Person\OnPrem\%1.jpg', NameForImage);
        if Exists(ImagePath) then
            Employee.Image.ImportFile(ImagePath, NameForImage);
        Employee.Modify();
    end;

    procedure InsertAdministration("No.": Code[20]; "Global Dimension 1 Code": Code[20]; "Global Dimension 2 Code": Code[20]; "Emplymt. Contract Code": Code[10]; "Statistics Group Code": Code[10]; "Employment Date": Date; SalespersonPurchaser: Code[10]; "Resource No.": Code[20]; "Union Code": Code[10]; "Union Membership No.": Text[30])
    begin
        Employee.Get("No.");
        Employee."Global Dimension 1 Code" := "Global Dimension 1 Code";
        Employee."Global Dimension 2 Code" := "Global Dimension 2 Code";
        Employee."Emplymt. Contract Code" := "Emplymt. Contract Code";
        Employee."Statistics Group Code" := "Statistics Group Code";
        Employee."Employment Date" := "Employment Date";
        Employee."Salespers./Purch. Code" := SalespersonPurchaser;
        Employee."Union Code" := "Union Code";
        Employee."Union Membership No." := "Union Membership No.";
        Employee."Resource No." := "Resource No.";
        Employee.Modify();
    end;

    procedure InsertVendor("No.": Code[20])
    var
        Vend: Record Vendor;
        EmpVendUpdate: Codeunit "EmployeeVendor-Update";
    begin
        Employee.Get("No.");
        EmpVendUpdate.OnInsert(Employee);
        Vend.Get("No.");
        Vend.Validate("Vendor Posting Group", XPERSEXP);
        Vend.Validate("Gen. Bus. Posting Group", XPERSONAL);
        Vend.Modify();
    end;
}

