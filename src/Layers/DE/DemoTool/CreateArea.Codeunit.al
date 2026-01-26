codeunit 161404 "Create Area"
{

    trigger OnRun()
    begin
        InsertData('01', 'Schleswig-Holstein');
        InsertData('02', 'Hamburg');
        InsertData('03', 'Niedersachsen');
        InsertData('04', 'Bremen');
        InsertData('05', 'Nordrhein-Westfalen');
        InsertData('06', 'Hessen');
        InsertData('07', 'Rheinland-Pfalz');
        InsertData('08', 'Baden-Württemberg');
        InsertData('09', 'Bayern');
        InsertData('10', 'Saarland');
        InsertData('11', 'Berlin');
        InsertData('12', 'Brandenburg');
        InsertData('13', 'Mecklenburg-Vorpommern');
        InsertData('14', 'Sachsen');
        InsertData('15', 'Sachsen-Anhalt');
        InsertData('16', 'Thüringen');
        // InsertData('25','Ausland');
        InsertData('25', 'Ausland (Eingang)');
        InsertData('99', 'Ausland (Versendung)');
    end;

    var
        "Area": Record "Area";

    procedure InsertData("Code": Code[10]; Text: Text[250])
    begin
        Area.Init();
        Area.Validate(Code, Code);
        Area.Validate(Text, Text);
        Area.Insert();
    end;
}

