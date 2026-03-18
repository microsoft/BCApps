codeunit 101600 "Create Employee"
{

    trigger OnRun()
    begin
        InsertAllGeneral();
        InsertAllContact();
        InsertAllAdministration();
        InsertAllPersonal();
        InsertAllPostingGroups();
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
        XEmplExp: Label 'EMPLEXP', Locked = true;
        XAccountsPayableTok: Label 'Accounts Payable';
        XEmployeesPayable: Label 'Employees Payable';

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

    procedure InsertAdministration("No.": Code[20]; "Global Dimension 1 Code": Code[20]; "Global Dimension 2 Code": Code[20]; "Emplymt. Contract Code": Code[10]; "Statistics Group Code": Code[10]; "Employment Date": Date; SalespersonPurchaser: Code[10]; "Resource No.": Code[20])
    begin
        Employee.Get("No.");
        Employee."Global Dimension 1 Code" := "Global Dimension 1 Code";
        Employee."Global Dimension 2 Code" := "Global Dimension 2 Code";
        Employee."Emplymt. Contract Code" := "Emplymt. Contract Code";
        Employee."Statistics Group Code" := "Statistics Group Code";
        Employee."Employment Date" := "Employment Date";
        Employee."Salespers./Purch. Code" := SalespersonPurchaser;
        Employee."Resource No." := "Resource No.";
        Employee.Modify();
    end;

    procedure InsertPersonal("No.": Code[20]; "Birth Date": Date; "Social Security No.": Text[30]; "Union Code": Code[10]; "Union Membership No.": Text[30])
    begin
        Employee.Get("No.");
        Employee."Birth Date" := "Birth Date";
        Employee."Social Security No." := "Social Security No.";
        Employee."Union Code" := "Union Code";
        Employee."Union Membership No." := "Union Membership No.";
        Employee.Modify();
    end;

    procedure CreateEvaluationData()
    begin
        InsertAllGeneral();
        InsertAllContact();
        InsertAllDates();
        InsertAllPostingGroups();
    end;

    local procedure InsertAllGeneral()
    begin
        InsertGeneral(
          XEH, XEster, '', XHenderson, XEHENDERSON, X5RusselStreet, CreatePostCode.Convert('GB-PE17 4RN'),
          XManagingDirector, Employee.Gender::Female);
        InsertGeneral(
          XJO, XJim, '', XOlive, XJOLIVE, X47MainStreet, CreatePostCode.Convert('GB-W1 3AL'),
          XSalesManager, Employee.Gender::Male);
        InsertGeneral(
          XOF, XOtis, '', XFalls, XOFALLS, X327ElmwoodStreet, CreatePostCode.Convert('GB-W1 3AL'),
          XProductionManager, Employee.Gender::Male);
        InsertGeneral(
          XLT, XLina, '', XTownsend, XLTOWNSEND, X10HighStreet, CreatePostCode.Convert('GB-N16 34Z'),
          XDesigner, Employee.Gender::Female);
        InsertGeneral(
          XRB, XRobin, '', XBettencourt, XRBETTENCOURT, X7MaddistonRoad, CreatePostCode.Convert('GB-W1 3AL'),
          XSecretary, Employee.Gender::"Non-binary");
        InsertGeneral(
          XMH, XMarty, '', XHorst, XMHORST, X49GrahamsRoad, CreatePostCode.Convert('GB-N12 5XY'),
          XProductionAssistant, Employee.Gender::Male);
        InsertGeneral(
          XTD, XTerry, '', XDodds, XTDODDS, X66BJamesRoad, CreatePostCode.Convert('GB-N12 5XY'),
          XProductionAssistant, Employee.Gender::Male);
    end;

    local procedure InsertAllContact()
    begin
        InsertContact(XEH, '6743', '', '4564-4564-7831', '4465-4899-4643', '', 'Ester Henderson');
        InsertContact(XJO, '1415', '', '1234-5678-9012', '0678-9012-3456', '', 'Jim Olive');
        InsertContact(XOF, '4564', '', '1546-3124-4646', '6549-3216-7415', '', 'Otis Falls');
        InsertContact(XLT, '3545', '', '1234-6545-5649', '0678-1234-5466', '', 'Lina Townsend');
        InsertContact(XRB, '6571', '', '1234-1643-4384', '0678-2534-2013', '', 'Robin Bettencourt');
        InsertContact(XMH, '4456', '', '1234-5464-5446', '0678-2135-4649', '', 'Marty Horst');
        InsertContact(XTD, '4653', '', '1234-6545-8799', '0678-8712-5466', '', 'Terry Dodds');
    end;

    local procedure InsertAllAdministration()
    begin
        InsertAdministration(XEH, XSALES, '', XADM, XMONTH, 19960601D, XEH, '');
        InsertAdministration(XJO, XSALES, '', XADM, XMONTH, 20010101D, XJO, '');
        InsertAdministration(XOF, XADM, '', XADM, XMONTH, 19910101D, XOF, '');
        InsertAdministration(XLT, XPROD, '', XDEV, XHOUR, 19990101D, XLT, XLina);
        InsertAdministration(XRB, XPROD, '', XPROD, X14DAYS, 19960301D, XRB, '');
        InsertAdministration(XMH, XPROD, '', XPROD, X14DAYS, 19960301D, '', XMarty);
        InsertAdministration(XTD, XPROD, '', XPROD, X14DAYS, 19960301D, '', XTerry);
    end;

    local procedure InsertAllPersonal()
    begin
        InsertPersonal(XEH, 19631212D, '1212637665', XUADMI, '4151746513235-45646');
        InsertPersonal(XJO, 19690212D, '1202696486', XUADMI, '3462345-235');
        InsertPersonal(XOF, 19470705D, '0507473497', XUADMI, '346246546345-24535');
        InsertPersonal(XLT, 19560310D, '1003569468', XUDEVE, '541236-654');
        InsertPersonal(XRB, 19490507D, '0705491679', XUPROD, '234654-631');
        InsertPersonal(XMH, 19620807D, '0708624564', XUPROD, '234654-631');
        InsertPersonal(XTD, 19631207D, '0712635465', XUPROD, '234654-631');
    end;

    local procedure InsertAllDates()
    begin
        InsertDates(XEH, 19960601D, 19631212D);
        InsertDates(XJO, 20010101D, 19690212D);
        InsertDates(XOF, 19910101D, 19470705D);
        InsertDates(XLT, 19990101D, 19560310D);
        InsertDates(XRB, 19960301D, 19490507D);
        InsertDates(XMH, 19960301D, 19620807D);
        InsertDates(XTD, 19960301D, 19631207D);
    end;

    local procedure InsertDates("No.": Code[20]; "Employment Date": Date; "Birth Date": Date)
    begin
        Employee.Get("No.");
        Employee."Employment Date" := "Employment Date";
        Employee."Birth Date" := "Birth Date";
        Employee.Modify();
    end;

    local procedure InsertAllPostingGroups()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        GLAccount: Record "G/L Account";
        RoundingGLAccount: Record "G/L Account";
        CreateCustPostGroup: Codeunit "Create Cust. Posting Group";
    begin
        GLAccount.SetRange(Name, XEmployeesPayable);
        if not GLAccount.FindFirst() then begin
            GLAccount.SetRange(Name, XAccountsPayableTok);
            if not GLAccount.FindFirst() then
                exit;
        end;
        EmployeePostingGroup.Code := XEmplExp;
        RoundingGLAccount."No." := CreateCustPostGroup.GetRoundingAccount();
        EmployeePostingGroup."Payables Account" := GLAccount."No.";

        EmployeePostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", RoundingGLAccount."No.");
        EmployeePostingGroup.Validate("Credit Rounding Account", RoundingGLAccount."No.");
        EmployeePostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", RoundingGLAccount."No.");
        EmployeePostingGroup.Validate("Debit Rounding Account", RoundingGLAccount."No.");
        EmployeePostingGroup.Insert();

        InsertPostingGroup(XEH, EmployeePostingGroup.Code);
        InsertPostingGroup(XJO, EmployeePostingGroup.Code);
        InsertPostingGroup(XOF, EmployeePostingGroup.Code);
        InsertPostingGroup(XLT, EmployeePostingGroup.Code);
        InsertPostingGroup(XRB, EmployeePostingGroup.Code);
        InsertPostingGroup(XMH, EmployeePostingGroup.Code);
        InsertPostingGroup(XTD, EmployeePostingGroup.Code);
    end;

    procedure InsertPostingGroup("No.": Code[20]; PostingGroupCode: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.Get("No.");
        Employee."Employee Posting Group" := PostingGroupCode;
        Employee.Modify();
    end;

    procedure EmployeePostingGroupCode(): Code[20]
    begin
        exit(XEmplExp);
    end;
}

