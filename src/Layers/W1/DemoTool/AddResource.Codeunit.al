codeunit 117562 "Add Resource"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XKatherine, XKatherineHulllc, XKATHERINEHULL, X14SidneyBoulevard, XServiceManager,
          20010101D, XHOUR, 49, 10.0, 53.9, 49.62617, 107, 20000919D, XSERVICES, CreatePostCode.Convert('GB-N12 5XY'),
          DemoDataSetup.ServicesVATCode());
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CreatePostCode: Codeunit "Create Post Code";
        XKatherine: Label 'Katherine';
        XKatherineHulllc: Label 'Katherine Hull';
        xKATHERINEHULL: Label 'KATHERINE HULL';
        X14SidneyBoulevard: Label '14 Sidney Boulevard';
        XServiceManager: Label 'Service Manager';
        XHOUR: Label 'HOUR';
        XSERVICES: Label 'SERVICES';

    procedure InsertData(No: Code[20]; Name: Text[50]; SearchName: Text[50]; Address: Text[50]; JobTitle: Text[30]; EmploymentDate: Date; BaseUnitOfMeasure: Code[10]; DirectUnitCost: Decimal; IndirectCostPercent: Decimal; UnitCost: Decimal; ProfitPercent: Decimal; UnitPrice: Decimal; LastDateModified: Date; GenProdPostingGroup: Code[20]; PostCode: Code[20]; TaxProdPostingGroup: Code[20])
    var
        Resource: Record Resource;
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        Resource.Init();
        Resource."No." := No;
        Resource.Name := Name;
        Resource."Search Name" := SearchName;
        Resource.Address := Address;
        Resource."Post Code" := CreatePostCode.FindPostCode(PostCode);
        Resource.City := CreatePostCode.FindCity(PostCode);
        Resource."Job Title" := JobTitle;
        Resource."Employment Date" := EmploymentDate;

        ResUnitOfMeasure.Init();
        ResUnitOfMeasure."Resource No." := No;
        ResUnitOfMeasure.Code := BaseUnitOfMeasure;
        ResUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ResUnitOfMeasure."Related to Base Unit of Meas." := true;
        ResUnitOfMeasure.Insert();

        Resource."Base Unit of Measure" := BaseUnitOfMeasure;
        Resource."Direct Unit Cost" := DirectUnitCost;
        Resource.Validate("Direct Unit Cost", RoundAmount(DirectUnitCost));
        Resource."Indirect Cost %" := IndirectCostPercent;
        Resource.Validate("Unit Cost", RoundAmount(UnitCost));
        Resource."Profit %" := ProfitPercent;
        Resource.Validate("Unit Price", RoundAmount(UnitPrice));
        Resource."Last Date Modified" := LastDateModified;
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            Resource.Validate("VAT Prod. Posting Group", TaxProdPostingGroup)
        else
            Resource.Validate("Tax Group Code", TaxProdPostingGroup);
        Resource.Insert();
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    begin
        exit(
          Round(
            Amount * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));
    end;
}

