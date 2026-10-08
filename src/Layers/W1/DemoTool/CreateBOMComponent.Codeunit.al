codeunit 101090 "Create BOM Component"
{

    trigger OnRun()
    begin
        InsertData('1924-W', 10000, '70000', 2);
        InsertData('1924-W', 20000, '70001', 1);
        InsertData('1924-W', 30000, '70002', 1);
        InsertData('1924-W', 40000, '70003', 1);
        InsertData('1928-W', 20000, '70000', 2);
        InsertData('1928-W', 30000, '70001', 1);
        InsertData('1928-W', 40000, '70002', 1);
        InsertData('1928-W', 50000, '70003', 1);
        InsertData('1928-W', 60000, '70040', 2);
        InsertData('1952-W', 20000, '70000', 2);
        InsertData('1952-W', 30000, '70001', 1);
        InsertData('1952-W', 40000, '70002', 1);
        InsertData('1952-W', 50000, '70003', 1);
        InsertData('1952-W', 60000, '70041', 1);
        InsertData('1964-W', 20000, '70000', 2);
        InsertData('1964-W', 30000, '70001', 1);
        InsertData('1964-W', 40000, '70002', 1);
        InsertData('1964-W', 50000, '70003', 1);
        InsertData('1964-W', 60000, '70041', 1);
        InsertData('1964-W', 70000, '70011', 2);
        InsertData('1964-W', 80000, '70200', 4);
        InsertData('1964-W', 90000, '70201', 2);
        InsertData('1968-W', 20000, '1996-S', 1);
        InsertData('1968-W', 30000, '70103', 1);
        InsertData('1972-W', 10000, '1996-S', 1);
        InsertData('1972-W', 20000, '70100', 1);
        InsertData('1976-W', 20000, '70000', 2);
        InsertData('1976-W', 30000, '70001', 1);
        InsertData('1976-W', 40000, '70002', 1);
        InsertData('1976-W', 50000, '70003', 1);
        InsertData('1976-W', 60000, '70041', 1);
        InsertData('1976-W', 70000, '70010', 2);
        InsertData('1976-W', 80000, '70200', 4);
        InsertData('1976-W', 90000, '70201', 2);
        InsertData('1984-W', 20000, '1996-S', 1);
        InsertData('1984-W', 30000, '70102', 1);
        InsertData('1988-W', 20000, '1996-S', 1);
        InsertData('1988-W', 30000, '70101', 1);
        InsertData('1992-W', 20000, '1996-S', 1);
        InsertData('1992-W', 30000, '70104', 1);
        InsertData('766BC-A', 10000, '1920-S', 5);
        InsertData('766BC-A', 20000, '1900-S', 12);
        InsertData('766BC-A', 30000, '1996-S', 1);
        InsertData('766BC-A', 40000, '70102', 1);
        InsertData('766BC-B', 20000, '1952-W', 1);
        InsertData('766BC-B', 30000, '1928-W', 1);
        InsertData('766BC-B', 40000, '1976-W', 1);
        InsertData('766BC-B', 50000, '1964-W', 1);
        InsertData('766BC-B', 60000, '70060', 1);
        InsertData('766BC-B', 70000, '1896-S', 1);
        InsertData('766BC-B', 80000, '1908-S', 1);
        InsertData('766BC-B', 90000, '1928-S', 1);
        InsertData('766BC-B', 100000, '70102', 1);
        InsertData('766BC-C', 10000, '1952-W', 1);
        InsertData('766BC-C', 20000, '1928-W', 1);
        InsertData('766BC-C', 30000, '1976-W', 1);
        InsertData('766BC-C', 40000, '1964-W', 1);
        InsertData('766BC-C', 50000, '70060', 1);
    end;

    var
        "BOM Component": Record "BOM Component";
        XPCS: Label 'PCS';
        XHOUR: Label 'HOUR', Comment = 'Number of hours.';
        XKatherine: Label 'Katherine', Comment = 'BOM component number - should be used with translation LISE.';
        BOMDescription: Label 'Installation';

    procedure InsertData("Parent Item No.": Code[20]; "Line No.": Integer; "No.": Code[20]; "Quantity per": Decimal)
    begin
        "BOM Component".Init();
        "BOM Component".Validate("Parent Item No.", "Parent Item No.");
        "BOM Component".Validate("Line No.", "Line No.");
        "BOM Component".Validate(Type, "BOM Component".Type::Item);
        "BOM Component".Validate("No.", "No.");
        "BOM Component".Validate("Quantity per", "Quantity per");
        "BOM Component".Insert(true);
    end;

    local procedure InsertEvaluationData("Parent Item No.": Code[20]; "Line No.": Integer; "No.": Code[20]; Description: Text[50]; "Quantity per": Decimal; "Unit of Measure": Code[10]; "Component Type": Enum "BOM Component Type")
    begin
        "BOM Component".Init();
        "BOM Component".Validate("Parent Item No.", "Parent Item No.");
        "BOM Component".Validate("Line No.", "Line No.");
        "BOM Component".Validate(Type, "Component Type");
        "BOM Component".Validate("No.", "No.");
        if Description <> '' then
            "BOM Component".Validate(Description, Description);
        "BOM Component".Validate("Quantity per", "Quantity per");
        "BOM Component".Validate("Unit of Measure Code", "Unit of Measure");
        "BOM Component".Insert(true);
    end;

    [Scope('Cloud')]
    procedure CreateEvaluationData()
    begin
        InsertEvaluationData('1925-W', 10000, '1920-S', '', 1, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1925-W', 20000, '1968-S', '', 6, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1925-W', 30000, XKatherine, BOMDescription, 1, XHOUR, "BOM Component".Type::Resource);

        InsertEvaluationData('1929-W', 10000, '1920-S', '', 1, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1929-W', 20000, '1968-S', '', 8, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1929-W', 30000, XKatherine, BOMDescription, 1, XHOUR, "BOM Component".Type::Resource);

        InsertEvaluationData('1953-W', 10000, '1960-S', '', 4, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1953-W', 20000, '1906-S', '', 1, XPCS, "BOM Component".Type::Item);

        InsertEvaluationData('1965-W', 10000, '1920-S', '', 1, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1965-W', 20000, '2000-S', '', 8, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1965-W', 30000, XKatherine, BOMDescription, 1, XHOUR, "BOM Component".Type::Resource);

        InsertEvaluationData('1969-W', 10000, '1965-W', '', 1, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1969-W', 20000, '1953-W', '', 1, XPCS, "BOM Component".Type::Item);
        InsertEvaluationData('1969-W', 30000, XKatherine, BOMDescription, 1, XHOUR, "BOM Component".Type::Resource);
    end;
}

