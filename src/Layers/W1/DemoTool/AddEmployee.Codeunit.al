codeunit 117566 "Add Employee"
{

    trigger OnRun()
    begin
        InsertRec(XKH, XKatherinelc, XHulllc, XKHULL, XServiceManager, XKHULL, X12SelsdonRoad, XLondon,
          'GB-N16 34Z', '020-2584-1095', '7223-4321-8744', Xlmcronusdemositecom,
          '1294370062', XUADMI, '4921826-897', '1', XADM, XMONTH);
        ModifyRec1(19021001D, 4, 19020519D, 35, XADM, XKatherine, '1095', XKH, 'Katherine Hull');
        UpdateResources();
    end;

    var
        NewRec: Record Employee;
        XKH: Label 'KH';
        XKatherinelc: Label 'Katherine';
        XHulllc: Label 'Hull';
        XKHULL: Label 'KHULL';
        XServiceManager: Label 'Service Manager';
        XKatherine: Label 'Katherine';
        X12SelsdonRoad: Label '12 Selsdon Road';
        XLondon: Label 'London';
        Xlmcronusdemositecom: Label 'lm@cronus-demosite.com';
        XUADMI: Label 'UADMI';
        XADM: Label 'ADM';
        XMONTH: Label 'MONTH';
        MakeAdjustments: Codeunit "Make Adjustments";
        Res: Record Resource;
        ResourceUpdate: Codeunit "Employee/Resource Update";

    procedure InsertRec(Fld1: Text[250]; Fld2: Text[250]; Fld4: Text[250]; Fld5: Text[250]; Fld6: Text[250]; Fld7: Text[250]; Fld8: Text[250]; Fld11: Text[250]; Fld13: Text[250]; Fld14: Text[250]; Fld15: Text[250]; Fld16: Text[250]; Fld21: Text[250]; Fld22: Text[250]; Fld23: Text[250]; Fld24: Text[250]; Fld27: Text[250]; Fld28: Text[250])
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        Clear(NewRec);
        NewRec.Init();
        Evaluate(NewRec."No.", Fld1);
        Evaluate(NewRec."First Name", Fld2);
        Evaluate(NewRec."Last Name", Fld4);
        Evaluate(NewRec.Initials, Fld5);
        Evaluate(NewRec."Job Title", Fld6);
        Evaluate(NewRec."Search Name", Fld7);
        Evaluate(NewRec.Address, Fld8);
        Evaluate(NewRec.City, Fld11);
        Evaluate(NewRec."Post Code", CreatePostCode.FindPostCode(Fld13));
        Evaluate(NewRec."Phone No.", Fld14);
        Evaluate(NewRec."Mobile Phone No.", Fld15);
        Evaluate(NewRec."E-Mail", CopyStr(Fld16, 1, MaxStrLen(NewRec."E-Mail")));
        Evaluate(NewRec."Social Security No.", Fld21);
        Evaluate(NewRec."Union Code", Fld22);
        Evaluate(NewRec."Union Membership No.", Fld23);
        Evaluate(NewRec.Gender, Fld24);
        Evaluate(NewRec."Emplymt. Contract Code", Fld27);
        Evaluate(NewRec."Statistics Group Code", Fld28);
        NewRec.Insert();
    end;

    procedure ModifyRec1(Fld29: Date; "Employment Years": Integer; Fld20: Date; Age: Integer; Fld36: Text[250]; Fld38: Text[250]; Fld46: Text[250]; Fld52: Text[250]; NameForImage: Text)
    var
        ImagePath: Text;
    begin
        Fld20 := MakeAdjustments.AdjustDate(Fld20);
        Fld20 := DMY2Date(Date2DMY(Fld20, 1), Date2DMY(Fld20, 2), (Date2DMY(Fld20, 3) - Age));
        NewRec."Birth Date" := Fld20;
        Fld29 := MakeAdjustments.AdjustDate(Fld29);
        Fld29 := DMY2Date(Date2DMY(Fld29, 1), Date2DMY(Fld29, 2), (Date2DMY(Fld29, 3) - "Employment Years"));
        NewRec."Employment Date" := Fld29;
        if Fld36 <> NewRec."Global Dimension 1 Code" then
            NewRec.Validate("Global Dimension 1 Code", Fld36);
        Evaluate(NewRec."Resource No.", Fld38);
        Evaluate(NewRec.Extension, Fld46);
        Evaluate(NewRec."Salespers./Purch. Code", Fld52);
        ImagePath :=
          StrSubstNo(
            'Images\Person\OnPrem\%1.jpg', NameForImage);
        if Exists(ImagePath) then
            NewRec.Image.ImportFile(ImagePath, NameForImage);
        NewRec.Modify();
    end;

    procedure UpdateResources()
    begin
        if (NewRec."Resource No." <> '') and Res.WritePermission then
            ResourceUpdate.ResUpdate(NewRec);
    end;
}

