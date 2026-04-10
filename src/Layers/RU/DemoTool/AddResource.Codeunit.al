codeunit 117562 "Add Resource"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertRec(XKatherine, XKatherineHulllc, XKATHERINEHULL, X14SidneyBoulevard, XServiceManager,
          20010101D, XHOUR, 49, 10.0, 53.9, 49.62617, 107, 20000919D, XSERV20, CreatePostCode.Convert('GB-N12 5XY'), XSERV20);
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
        XSERV20: Label 'SERV20', Comment = 'SERV20';

    procedure InsertRec(Fld1: Text[250]; Fld3: Text[250]; Fld4: Text[250]; Fld6: Text[250]; Fld10: Text[250]; Fld13: Date; Fld18: Text[250]; Fld19: Decimal; Fld20: Decimal; Fld21: Decimal; Fld22: Decimal; Fld24: Decimal; Fld26: Date; Fld51: Text[250]; Fld53: Text[250]; Fld58: Text[250])
    var
        Resource: Record Resource;
        ResUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        Resource.Init();
        Evaluate(Resource."No.", Fld1);
        Evaluate(Resource.Name, Fld3);
        Evaluate(Resource."Search Name", Fld4);
        Evaluate(Resource.Address, Fld6);
        Evaluate(Resource."Post Code", CreatePostCode.FindPostCode(Fld53));
        Evaluate(Resource.City, CreatePostCode.FindCity(Fld53));
        Evaluate(Resource."Job Title", Fld10);
        Resource."Employment Date" := Fld13;

        ResUnitOfMeasure.Init();
        Evaluate(ResUnitOfMeasure."Resource No.", Fld1);
        Evaluate(ResUnitOfMeasure.Code, Fld18);
        ResUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ResUnitOfMeasure."Related to Base Unit of Meas." := true;
        ResUnitOfMeasure.Insert();

        Evaluate(Resource."Base Unit of Measure", Fld18);

        Resource."Direct Unit Cost" := Fld19;
        Resource.Validate(
          "Direct Unit Cost",
          Round(
            Resource."Direct Unit Cost" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));

        Resource."Indirect Cost %" := Fld20;

        Resource."Unit Cost" := Fld21;
        Resource.Validate(
          "Unit Cost",
          Round(
            Resource."Unit Cost" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));

        Resource."Profit %" := Fld22;

        Resource."Unit Price" := Fld24;
        Resource.Validate(
          "Unit Price",
          Round(
            Resource."Unit Price" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));

        Resource."Last Date Modified" := Fld26;
        Evaluate(Resource."Gen. Prod. Posting Group", Fld51);
        Evaluate(Resource."VAT Prod. Posting Group", Fld58);
        Resource.Insert();
    end;
}

