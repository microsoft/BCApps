codeunit 117565 "Add Salesperson/Purchaser"
{

    trigger OnRun()
    begin
        InsertRec(XKH, XKATHERINEHULL);
        InsertDimensionValue(XSALESPERSON, XKH, XKATHERINEHULL, 0, '', '');
        InsertDefaultDimension(13, XKH, XSALESPERSON, XKH, 2);
    end;

    var
        XKH: Label 'KH';
        xKATHERINEHULL: Label 'KATHERINE HULL';
        XSALESPERSON: Label 'SALESPERSON';
        XDEPARTMENT: Label 'DEPARTMENT';
        XPROJECT: Label 'PROJECT';

    procedure InsertRec(Fld1: Text[250]; Fld2: Text[250])
    var
        NewRec: Record "Salesperson/Purchaser";
    begin
        NewRec.Init();
        Evaluate(NewRec.Code, Fld1);
        Evaluate(NewRec.Name, Fld2);
        NewRec.Insert();
    end;

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
        if DimensionValue."Dimension Code" = XDEPARTMENT then
            DimensionValue."Global Dimension No." := 1;
        if DimensionValue."Dimension Code" = XPROJECT then
            DimensionValue."Global Dimension No." := 2;
        DimensionValue.Insert();
    end;
}

