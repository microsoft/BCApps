codeunit 143017 "ERM Dimension Subscriber - RU"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetLocalTablesWithDimSetIDValidationIgnored', '', false, false)]
    local procedure GetCountOfLocalTablesWithDimSetIDValidationIgnored(var CountOfTablesIgnored: Integer)
    begin
        // Specifies how many tables with "Dimension Set ID" field related to "Dimension Set Entry" table should not have OnValidate trigger which updates shortcut dimensions

        CountOfTablesIgnored += 18;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetTableNosWithGlobalDimensionCode', '', false, false)]
    local procedure AddingLocalTable(var TableBuffer: Record "Integer" temporary)
    begin
        AddTable(TableBuffer, DATABASE::"Vendor Agreement");
        AddTable(TableBuffer, DATABASE::"Customer Agreement");
        AddTable(TableBuffer, DATABASE::"FA Charge");
    end;

    local procedure AddTable(var TableBuffer: Record "Integer" temporary; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;
}

