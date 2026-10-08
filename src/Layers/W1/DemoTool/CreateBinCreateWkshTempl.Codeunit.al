codeunit 118851 "Create Bin Create Wksh.-Templ."
{

    trigger OnRun()
    begin
        InsertData(XBIN, XBinWorksheet, BinCreateWkshTemplate.Type::Bin);
        InsertData(XBINCONTEN, XBinContentWorksheet, BinCreateWkshTemplate.Type::"Bin Content");
    end;

    var
        BinCreateWkshTemplate: Record "Bin Creation Wksh. Template";
        XBIN: Label 'BIN';
        XBinWorksheet: Label 'Bin Worksheet';
        XBINCONTEN: Label 'BIN CONTEN';
        XBinContentWorksheet: Label 'Bin Content Worksheet';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Option)
    begin
        BinCreateWkshTemplate.Init();
        BinCreateWkshTemplate.Validate(Name, Name);
        BinCreateWkshTemplate.Validate(Description, Description);
        BinCreateWkshTemplate.Insert(true);
        BinCreateWkshTemplate.Validate(Type, Type);
        BinCreateWkshTemplate.Modify();
    end;
}

