codeunit 161510 "Create CH Acc. Schedule"
{

    trigger OnRun()
    begin
        InsertSchemaName(xSchemaAbsatz, Text50001);
        InsertSchemaName(xSchemaKFR, Text50003);
        InsertSchemaName(xSchemaKam, Text50005);

        KtoSchemaZeile.Init();
        KtoSchemaZeile.Show := KtoSchemaZeile.Show::Yes;

        KtoSchemaZeile.Validate("Schedule Name", xSchemaAbsatz);
        InsertSchemaZeile(10000, '', Text50001, '', 0);
        InsertSchemaZeile(20000, '', '', '', 0);
        InsertSchemaZeile(30000, '3000', Text50006, '3999', 1);
        InsertSchemaZeile(40000, '4000', Text50007, '4999', 1);
        InsertSchemaZeile(50000, '4999', Text50008, '3000..4000', 2);
        InsertSchemaZeile(60000, '', '', '', 0);
        InsertSchemaZeile(70000, '5000', Text50009, '5999', 1);
        InsertSchemaZeile(80000, '6000', Text50010, '6799', 1);
        InsertSchemaZeile(90000, '', Text50011, '4999..6000', 2);

        KtoSchemaZeile.Validate("Schedule Name", xSchemaKFR);
        InsertSchemaZeile(10000, '', Text50012, '', 0);
        InsertSchemaZeile(20000, '', '', '', 0);
        InsertSchemaZeile(30000, '', Text50013, '', 0);
        InsertSchemaZeile(40000, '', '', '', 0);
        InsertSchemaZeile(50000, '1', Text50014, '1099', 1);
        InsertSchemaZeile(60000, '2', Text50015, '1199', 1);
        InsertSchemaZeile(70000, '4', Text50016, '1299', 1);
        InsertSchemaZeile(80000, '5', Text50017, '1300..1399', 0);
        InsertSchemaZeile(90000, '6', Text50018, '1..5', 2);
        InsertSchemaZeile(100000, '', '', '', 0);
        InsertSchemaZeile(110000, '', Text50019, '', 0);
        InsertSchemaZeile(120000, '', '', '', 0);
        InsertSchemaZeile(130000, '11', Text50020, '2000..2002', 0);
        InsertSchemaZeile(140000, '12', Text50021, '2100', 0);
        InsertSchemaZeile(150000, '13', Text50022, '2160..2340', 0);
        InsertSchemaZeile(160000, '15', Text50023, '11..13', 2);
        InsertSchemaZeile(170000, '', '', '', 0);
        InsertSchemaZeile(180000, '', Text50024, '5|15', 2);

        KtoSchemaZeile.Validate("Schedule Name", xSchemaKam);
        InsertSchemaZeile(10000, '', Text50025, '', 0);
        InsertSchemaZeile(20000, '', '', '', 0);
        InsertSchemaZeile(30000, '11', Text50026, '3200', 0);
        InsertSchemaZeile(40000, '12', Text50027, '4200', 0);
        InsertSchemaZeile(50000, '1', Text50028, '-12-11', 2);
        InsertSchemaZeile(60000, '', '', '', 0);
        InsertSchemaZeile(70000, '21', Text50029, '3202', 0);
        InsertSchemaZeile(80000, '22', Text50030, '4202', 0);
        InsertSchemaZeile(90000, '2', Text50031, '-22-21', 2);
        InsertSchemaZeile(100000, '', '', '', 0);
        InsertSchemaZeile(110000, '31', Text50032, '3204', 0);
        InsertSchemaZeile(120000, '32', Text50033, '4204', 0);
        InsertSchemaZeile(130000, '3', Text50034, '-32-31', 2);
        InsertSchemaZeile(140000, '', '', '', 0);
        InsertSchemaZeile(150000, '', Text50035, '1+2+3', 2);
    end;

    var
        xSchemaAbsatz: Label 'SALES IS';
        xSchemaKFR: Label 'ST LIQUID';
        xSchemaKam: Label 'CAMPAIGN';
        Text50001: Label 'Sales Income Statement';
        Text50003: Label 'Liquidity, Current Assets / Short-term Liabilities';
        Text50005: Label 'Campaign Analysis';
        Text50006: Label 'Goods Income';
        Text50007: Label 'Goods Expense';
        Text50008: Label 'Gross Profit';
        Text50009: Label 'Personnel Costs';
        Text50010: Label 'Other Op. Expenses';
        Text50011: Label 'Operating Result';
        Text50012: Label 'LIQUIDITY ANALYSIS';
        Text50013: Label 'Current Assets';
        Text50014: Label 'Means of Payment';
        Text50015: Label 'Accts Receivable';
        Text50016: Label 'Inventories';
        Text50017: Label 'Deferments';
        Text50018: Label 'Total Current Assets';
        Text50019: Label 'Short-term Liabilities';
        Text50020: Label 'Vendors';
        Text50021: Label 'Bank';
        Text50022: Label 'Other';
        Text50023: Label 'Total Short-term Liabilities';
        Text50024: Label 'Balance';
        Text50025: Label 'CAMPAIGN ANALYSIS';
        Text50026: Label 'Sales, Trade - Domestic';
        Text50027: Label 'Purchases, Trade - Domestic';
        Text50028: Label 'Trade Margin, Domestic';
        Text50029: Label 'Sales, Trade - EU';
        Text50030: Label 'Purchases, Trade - EU';
        Text50031: Label 'Trade Margin, EU';
        Text50032: Label 'Sales, Trade - Export';
        Text50033: Label 'Purchases, Trade - Export';
        Text50034: Label 'Trade Margin, Export';
        Text50035: Label 'Campaign Result';
        KtoSchemaName: Record "Acc. Schedule Name";
        KtoSchemaZeile: Record "Acc. Schedule Line";

    procedure InsertSchemaName(_Name: Code[10]; _Beschreibung: Text[80])
    begin
        KtoSchemaName.Init();
        KtoSchemaName.Name := _Name;
        KtoSchemaName.Description := _Beschreibung;
        KtoSchemaName.Insert();
    end;

    procedure InsertSchemaZeile(_ZeiNr: Integer; _Rubrik: Code[10]; _Bezeichnung: Text[80]; _Zusammenz: Text[80]; _TotalArt: Integer)
    begin
        KtoSchemaZeile."Line No." := _ZeiNr;
        KtoSchemaZeile.Validate("Row No.", _Rubrik);
        KtoSchemaZeile.Validate(Description, _Bezeichnung);
        KtoSchemaZeile.Validate(Totaling, _Zusammenz);
        KtoSchemaZeile.Validate("Totaling Type", _TotalArt);
        KtoSchemaZeile.Insert();
    end;
}

