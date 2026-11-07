codeunit 101157 "Create Job Resources"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          XKATHERINE, "Resource Type"::Person, XKATHERINEHULL, X10DeerfieldRoad, XManager, 20050525D, XHour,
          428.1, 10, 856.2, CA.AdjustDate(20030501D), CreatePostCode.Convert('GB-N12 5XY'));
        InsertData(
          XLINA, "Resource Type"::Person, XLinaTownsend, X25WaterWay, XDesigner, 19990101D, XHour,
          513.7, 10, 1027.4, CA.AdjustDate(20030501D), CreatePostCode.Convert('GB-N16 34Z'));
        InsertData(
          XMARTY, "Resource Type"::Person, XMartyHorst, X49ALittleJohnStreet, XInstaller, 19960301D, XHour,
          385.3, 10, 770.6, CA.AdjustDate(20030501D), CreatePostCode.Convert('GB-N12 5XY'));
        InsertData(
          XTERRY, "Resource Type"::Person, XTerryDodds, X66BJamesRoad, XDesigner, 19960301D, XHour,
          428.1, 10, 856.2, CA.AdjustDate(20030501D), CreatePostCode.Convert('GB-N12 5XY'));
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Resource: Record Resource;
        CA: Codeunit "Make Adjustments";
        CreatePostCode: Codeunit "Create Post Code";
        XKatherine: Label 'Katherine';
        xKATHERINEHULL: Label 'KATHERINE HULL';
        XLINA: Label 'LINA';
        XLinaTownsend: Label 'Lina Townsend';
        X25WaterWay: Label '25 Water Way';
        XDesigner: Label 'Designer';
        XHour: Label 'Hour';
        XMarty: Label 'Marty';
        XMartyHorst: Label 'Marty Horst';
        X49ALittleJohnStreet: Label '49 A Little John Street';
        XInstaller: Label 'Installer';
        XTerry: Label 'Terry';
        XTerryDodds: Label 'Terry Dodds';
        X66BJamesRoad: Label '66 B James Road';
        XSERVICES: Label 'SERVICES';
        XLABOR: Label 'LABOR';
        X10DeerfieldRoad: Label '10 Deerfield Road';
        XManager: Label 'Manager';

    procedure InsertData("No.": Code[20]; Type: Enum "Resource Type"; Name: Text[30]; Address: Text[30]; "Job Title": Text[20]; "Employment Date": Date; "Unit of Measure Code": Text[10]; "Direct Unit Cost": Decimal; "Indirect Cost %": Decimal; "Unit Price": Decimal; "Last Date Modified": Date; "Post Code": Code[20])
    var
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        Resource.Init();
        Resource.Validate("No.", "No.");
        Resource.Validate(Type, Type);
        Resource.Validate(Name, Name);
        Resource.Validate(Address, Address);
        Resource.Validate("Job Title", "Job Title");
        Resource.Validate("Employment Date", "Employment Date");

        ResUnitOfMeasure.Init();
        ResUnitOfMeasure."Resource No." := Resource."No.";
        ResUnitOfMeasure.Code := "Unit of Measure Code";
        ResUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ResUnitOfMeasure."Related to Base Unit of Meas." := true;
        ResUnitOfMeasure.Insert();

        Resource.Validate("Base Unit of Measure", "Unit of Measure Code");
        Resource.Validate("Direct Unit Cost",
          Round("Direct Unit Cost" * DemoDataSetup."Local Currency Factor",
            10 * DemoDataSetup."Local Precision Factor"));
        Resource.Validate("Indirect Cost %", "Indirect Cost %");
        Resource.Validate("Unit Price",
          Round("Unit Price" * DemoDataSetup."Local Currency Factor",
            10 * DemoDataSetup."Local Precision Factor"));
        Resource.Validate("Last Date Modified", "Last Date Modified");
        Resource."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Resource.City := CreatePostCode.FindCity("Post Code");
        Resource.Validate("Gen. Prod. Posting Group", XSERVICES);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            Resource.Validate("Tax Group Code", XLABOR);
        Resource.Insert();
    end;

    procedure KatherineCode(): Code[20]
    begin
        exit(XKATHERINE);
    end;

    procedure LinaCode(): Code[20]
    begin
        exit(XLINA);
    end;

    procedure MartyCode(): Code[20]
    begin
        exit(XMARTY);
    end;

    procedure TerryCode(): Code[20]
    begin
        exit(XTERRY);
    end;
}

