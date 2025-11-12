codeunit 118852 "Create Bin Create Wksh.-Name"
{

    trigger OnRun()
    begin
        InsertData(XBIN, XWHITE);
        InsertData(XBINCONTEN, XWHITE);

        InsertData(XBIN, XSILVER);
        InsertData(XBINCONTEN, XSILVER);
    end;

    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
        Text000: Label 'DEFAULT';
        Text001: Label 'Default Worksheet';
        XBIN: Label 'BIN';
        XWHITE: Label 'WHITE';
        XBINCONTEN: Label 'BIN CONTEN';
        XSILVER: Label 'SILVER';

    procedure InsertData(WkshTemplateName: Code[10]; LocationCode: Code[10])
    begin
        BinCreateWkshName.Init();
        BinCreateWkshName.Validate("Worksheet Template Name", WkshTemplateName);
        BinCreateWkshName.Validate(Name, Text000);
        BinCreateWkshName.Validate("Location Code", LocationCode);
        BinCreateWkshName.Validate(Description, Text001);
        BinCreateWkshName.Insert(true);
    end;
}

