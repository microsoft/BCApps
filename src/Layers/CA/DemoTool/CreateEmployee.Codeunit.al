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
        X677FifthAvenue: Label '677 Fifth Avenue';
        XSecretary: Label 'Secretary';
        XUADMI: Label 'UADMI';
        XSALES: Label 'SALES';
        XADM: Label 'ADM';
        XMONTH: Label 'MONTH';
        XJO: Label 'JO';
        XJim: Label 'Jim';
        XOlive: Label 'Olive';
        XJOLIVE: Label 'JOLIVE';
        X125WestchesterAvenue: Label '125 Westchester Avenue';
        XSalesManager: Label 'Sales Manager';
        XOF: Label 'OF';
        XOtis: Label 'Otis';
        XFalls: Label 'Falls';
        XOFALLS: Label 'OFALLS';
        X160WaltWhitmanRoad: Label '160 Walt Whitman Road';
        XManagingDirector: Label 'Managing Director';
        XLT: Label 'LT';
        XLina: Label 'Lina';
        XTownsend: Label 'Townsend';
        XLTOWNSEND: Label 'LTOWNSEND';
        X10ColumbusCircle: Label '10 Columbus Circle';
        XDesigner: Label 'Designer';
        XPROD: Label 'PROD';
        XDEV: Label 'DEV';
        XHOUR: Label 'HOUR';
        XUDEVE: Label 'UDEVE';
        XRB: Label 'RB';
        XRobin: Label 'Robin';
        XBettencourt: Label 'Bettencourt';
        XRBETTENCOURT: Label 'RBETTENCOURT';
        X400CommonsWay: Label '400 Commons Way';
        XProductionManager: Label 'Production Manager';
        X14DAYS: Label '14DAYS';
        XUPROD: Label 'UPROD';
        XMH: Label 'MH';
        XMarty: Label 'Marty';
        XHorst: Label 'Horst';
        XMHORST: Label 'MHORST';
        X10344DestinyUSADrive: Label '10344 Destiny USA Drive';
        XProductionAssistant: Label 'Production Assistant';
        XTD: Label 'TD';
        XTerry: Label 'Terry';
        XDodds: Label 'Dodds';
        XTDODDS: Label 'TDODDS';
        XEmplExp: Label 'EMPLEXP', Locked = true;
        XAccountsPayableTok: Label 'Accounts Payable';
        XEmployeesPayable: Label 'Employees Payable';
        X3710Route9South: Label '3710 Route 9 South';

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
          XEH, XEster, '', XHenderson, XEHENDERSON, X677FifthAvenue, 'CA-AB T2H 0K8',
          XManagingDirector, Employee.Gender::Female);
        InsertGeneral(
          XJO, XJim, '', XOlive, XJOLIVE, X125WestchesterAvenue, 'CA-ON M5B 2H1',
          XSalesManager, Employee.Gender::Male);
        InsertGeneral(
          XOF, XOtis, '', XFalls, XOFALLS, X160WaltWhitmanRoad, 'CA-AB T5T 4J2',
          XProductionManager, Employee.Gender::Male);
        InsertGeneral(
          XLT, XLina, '', XTownsend, XLTOWNSEND, X10ColumbusCircle, 'CA-BC V7Y 1G5',
          XDesigner, Employee.Gender::Female);
        InsertGeneral(
          XRB, XRobin, '', xBETTENCOURT, XRBETTENCOURT, X400CommonsWay, 'CA-ON M6A 3A1',
          XSecretary, Employee.Gender::"Non-binary");
        InsertGeneral(
          XMH, XMarty, '', XHorst, XMHORST, X10344DestinyUSADrive, 'CA-ON L5B 2C9',
          XProductionAssistant, Employee.Gender::Male);
        InsertGeneral(
          XTD, XTerry, '', XDodds, XTDODDS, X3710Route9South, 'CA-BC V7Y 1L1',
          XProductionAssistant, Employee.Gender::Male);
    end;

    local procedure InsertAllContact()
    begin
        InsertContact(XEH, '6743', '', '4564-4564-7831', '4465-4899-4643', 'eh@cronus-demosite.com', 'Ester Henderson');
        InsertContact(XJO, '1415', '', '1234-5678-9012', '0678-9012-3456', 'jo@cronus-demosite.com', 'Jim Olive');
        InsertContact(XOF, '4564', '', '1546-3124-4646', '6549-3216-7415', 'of@cronus-demosite.com', 'Otis Falls');
        InsertContact(XLT, '3545', '', '1234-6545-5649', '0678-1234-5466', 'lt@cronus-demosite.com', 'Lina Townsend');
        InsertContact(XRB, '6571', '', '1234-1643-4384', '0678-2534-2013', 'rb@cronus-demosite.com', 'Robin Bettencourt');
        InsertContact(XMH, '4456', '', '1234-5464-5446', '0678-2135-4649', 'mh@cronus-demosite.com', 'Marty Horst');
        InsertContact(XTD, '4653', '', '1234-6545-8799', '0678-8712-5466', 'td@cronus-demosite.com', 'Terry Dodds');
    end;

    local procedure InsertAllAdministration()
    begin
        InsertAdministration(XEH, XSALES, '', XADM, XMONTH, 20010601D, XEH, '');
        InsertAdministration(XJO, XSALES, '', XADM, XMONTH, 20040301D, XJO, '');
        InsertAdministration(XOF, XADM, '', XADM, XMONTH, 20010601D, XOF, '');
        InsertAdministration(XLT, XPROD, '', XDEV, XHOUR, 20100801D, XLT, XLina);
        InsertAdministration(XRB, XPROD, '', XPROD, X14DAYS, 20010601D, XRB, '');
        InsertAdministration(XMH, XPROD, '', XPROD, X14DAYS, 20010601D, '', XMarty);
        InsertAdministration(XTD, XPROD, '', XPROD, X14DAYS, 20061201D, '', XTerry);
    end;

    local procedure InsertAllPersonal()
    begin
        InsertPersonal(XEH, 19731212D, '1212637665', XUADMI, '4151746513235-45646');
        InsertPersonal(XJO, 19790212D, '1202696486', XUADMI, '3462345-235');
        InsertPersonal(XOF, 19670705D, '0507473497', XUADMI, '346246546345-24535');
        InsertPersonal(XLT, 19760310D, '1003569468', XUDEVE, '541236-654');
        InsertPersonal(XRB, 19790507D, '0705491679', XUPROD, '234654-631');
        InsertPersonal(XMH, 19820807D, '0708624564', XUPROD, '234654-631');
        InsertPersonal(XTD, 19831207D, '0712635465', XUPROD, '234654-631');
    end;

    local procedure InsertAllDates()
    begin
        InsertDates(XEH, 20010601D, 19731212D);
        InsertDates(XJO, 20040301D, 19790212D);
        InsertDates(XOF, 20010601D, 19670705D);
        InsertDates(XLT, 20100801D, 19760310D);
        InsertDates(XRB, 20010601D, 19790507D);
        InsertDates(XMH, 20010601D, 19820807D);
        InsertDates(XTD, 20061201D, 19831207D);
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

