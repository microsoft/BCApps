codeunit 101156 "Create Resource"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          XLIFT, "Resource Type"::Machine, XLiftforFurniture, '', '', 0D, XHour, 0, 0, 2500, CA.AdjustDate(19030126D), CreatePostCode.Convert(''));
        InsertData(
          XLINA, "Resource Type"::Person, XLinaTownsend, X10HighStreet, XDesigner, 19990101D, XHour,
          420, 10, 920, CA.AdjustDate(19030125D), CreatePostCode.Convert('GB-N16 34Z'));
        InsertData(
          XMARTY, "Resource Type"::Person, XMartyHorst, X49ALittleJohnStreet, XCabinetmaker, 19960301D, XHour,
          250, 10, 460, CA.AdjustDate(19030125D), CreatePostCode.Convert('GB-N12 5XY'));
        InsertData(
          XTERRY, "Resource Type"::Person, XTerryDodds, X66BJamesRoad, XCabinetmaker, 19960301D, XHour,
          250, 10, 460, CA.AdjustDate(19030125D), CreatePostCode.Convert('GB-N12 5XY'));
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Resource: Record Resource;
        CA: Codeunit "Make Adjustments";
        CreatePostCode: Codeunit "Create Post Code";
        XLIFT: Label 'LIFT';
        XLiftforFurniture: Label 'Lift for Furniture';
        XLINA: Label 'LINA';
        XLinaTownsend: Label 'Lina Townsend';
        X10HighStreet: Label '10 High Street';
        XDesigner: Label 'Designer';
        XHour: Label 'Hour';
        XMarty: Label 'Marty';
        XMartyHorst: Label 'Marty Horst';
        X49ALittleJohnStreet: Label '49 A Little John Street';
        XCabinetmaker: Label 'Cabinetmaker';
        XTerry: Label 'Terry';
        XTerryDodds: Label 'Terry Dodds';
        X66BJamesRoad: Label '66 B James Road';
        XSERVICES: Label 'SERVICES';
        XLABOR: Label 'LABOR';

    procedure InsertData("No.": Code[20]; Type: Enum "Resource Type"; Name: Text[30]; Address: Text[30]; "Job Title": Text[20]; "Employment Date": Date; "Unit of Measure Code": Text[10]; "Direct Unit Cost": Decimal; "Indirect Cost %": Decimal; "Unit Price": Decimal; "Last Date Modified": Date; "Post Code": Code[20])
    var
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        ImagePath: Text;
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
        if Resource.Type = Resource.Type::Person then begin
            ImagePath := DemoDataSetup."Path to Picture Folder" + StrSubstNo('Images\Person\OnPrem\%1.jpg', Name);
            if Exists(ImagePath) then
                Resource.Image.ImportFile(ImagePath, Name);
        end;
        Resource.Insert();
    end;
}

