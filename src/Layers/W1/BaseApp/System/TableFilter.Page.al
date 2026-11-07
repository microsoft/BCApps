namespace System.Text;

using System.Reflection;
using System.Security.AccessControl;

page 9805 "Table Filter"
{
    AutoSplitKey = true;
    Caption = 'Table Filter';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Table Filter";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Field Number"; Rec."Field Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the field on which a security filter is set.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, Rec."Table Number");
                        if FieldSelection.Open(Field) then begin
                            if Field."No." = Rec."Field Number" then
                                exit;
                            Rec.CheckDuplicateField(Field);
                            FillSourceRecord(Field);
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field on which a security filter is set.';
                }
                field("Field Filter"; Rec."Field Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the field for a security filter.';

                    trigger OnValidate()
                    var
                        Permission: Record Permission;
                    begin
                        CheckFieldFilter();
                        Evaluate(Permission."Security Filter", CreateTextTableFilter(true));
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        InitSourceTable();
    end;

    trigger OnOpenPage()
    begin
        SetCaption();
    end;

    var
        FilterTooLargeErr: Label 'The filters are too large to be copied to the type "TableFilter".';

    protected var
        SourceTableNumber: Integer;
        SourceTableName: Text;
        SourceTableCaption: Text;

    local procedure FillSourceRecord("Field": Record "Field")
    begin
        Rec.SetRange("Field Number");
        Rec.Init();

        Rec."Table Number" := Field.TableNo;
        Rec."Table Name" := Field.TableName;
        Rec."Field Number" := Field."No.";
        Rec."Field Name" := Field.FieldName;
        Rec."Field Caption" := Field."Field Caption";
    end;

    procedure SetSourceTable(TableFilterText: Text; NewTableNumber: Integer; NewTableCaption: Text)
    var
        AllObj: Record AllObj;
    begin
        SourceTableNumber := NewTableNumber;
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", NewTableNumber);
        if AllObj.FindFirst() then
            SourceTableName := AllObj."Object Name";
        SourceTableCaption := NewTableCaption;
        InitSourceTable();
        if StrLen(TableFilterText) > 0 then
            ParseTableFilter(TableFilterText);
    end;

    local procedure InitSourceTable()
    begin
        Rec.Init();
        Rec."Table Number" := SourceTableNumber;
        Rec."Table Name" := SourceTableName;
        Rec."Line No." := 0;
    end;

    local procedure ParseTableFilter(TableFilterText: Text)
    begin
        // Parsing a TableFilter text representation into the TableName and Field filters.
        // TableFilter text format:
        // <table name>: <field name>=<field filter>,<field name 2>=<field filter 2>...
        // Table name can be wrapped into double quotes if it contains a colon;
        // field names can be wrapped into double quotes if they contain the equal sign;
        // field filters can be wrapped into double quotes if they contain a comma.
        // If a value is wrapped into the double quotes,the double quote characters possibly contained in the value are escaped by another double quote.

        if not TableNameMatches(TableFilterText) then
            exit;

        // Read field names and field filters:
        while StrLen(TableFilterText) > 0 do begin
            ExtractFieldName(TableFilterText);
            ExtractFieldFilter(TableFilterText);
        end;
    end;

    local procedure GetValue(var TextString: Text; Delimiter: Text) PartOfText: Text
    var
        DelimiterPosition: Integer;
    begin
        DelimiterPosition := StrPos(TextString, Delimiter);
        if DelimiterPosition = 0 then begin
            // If delimiter wasn't found read everything until the end of the string:
            PartOfText := CopyStr(TextString, 1, StrLen(TextString));
            TextString := '';
        end else begin
            PartOfText := CopyStr(TextString, 1, DelimiterPosition - 1);
            TextString := CopyStr(TextString, DelimiterPosition + 1, StrLen(TextString) - DelimiterPosition);
        end;

        exit(PartOfText);
    end;

    local procedure GetQuotedValue(var TextString: Text; Delimiter: Text) PartOfText: Text
    var
        Position: Integer;
        Length: Integer;
        OneCharString: Text;
        IsQuote: Boolean;
        IsDelimiter: Boolean;
        EvenQuote: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQuotedValue(Rec, TextString, Delimiter, PartOfText, IsHandled);
        if IsHandled then
            exit(PartOfText);

        // Remove the first quote:
        TextString := CopyStr(TextString, 2, StrLen(TextString) - 1);
        Length := StrLen(TextString);

        EvenQuote := false;
        Position := 1;
        while Position <= Length do begin
            OneCharString := CopyStr(TextString, Position, 1);

            IsDelimiter := OneCharString = Delimiter;
            if IsDelimiter and EvenQuote then begin
                PartOfText := CopyStr(TextString, 1, Position - 2);
                PartOfText := UnescapeQuotedValue(PartOfText);
                TextString := CopyStr(TextString, Position + 1, StrLen(TextString) - Position);
                exit(PartOfText);
            end;

            IsQuote := StrPos(OneCharString, '"') = 1;
            if IsQuote then
                EvenQuote := not EvenQuote;

            Position += 1;
        end;

        // If delimiter wasn't found read everything until the end of the string,excluding the closing quote:
        PartOfText := CopyStr(TextString, 1, Position - 2);
        PartOfText := UnescapeQuotedValue(PartOfText);
        TextString := '';
        exit(PartOfText);
    end;

    local procedure UnescapeQuotedValue(TextValue: Text): Text
    var
        InnerQuotePosition: Integer;
        TextValue2: Text;
    begin
        InnerQuotePosition := StrPos(TextValue, '""');
        if InnerQuotePosition = 0 then
            exit(TextValue);

        while InnerQuotePosition > 0 do begin
            TextValue2 += CopyStr(TextValue, 1, InnerQuotePosition);
            TextValue := CopyStr(TextValue, InnerQuotePosition + 2, StrLen(TextValue) - InnerQuotePosition - 1);
            InnerQuotePosition := StrPos(TextValue, '""')
        end;

        TextValue2 += TextValue;
        exit(TextValue2);
    end;

    procedure CreateTextTableFilter(CurrentLineOnly: Boolean): Text
    var
        TextTableFilter: Text;
        TextFieldFilter: Text;
    begin
        TextFieldFilter := CreateTextTableFilterWithoutTableName(CurrentLineOnly);
        if StrLen(TextFieldFilter) > 0 then
            TextTableFilter := QuoteValue(Rec."Table Name", ':') + ': ' + TextFieldFilter;
        exit(TextTableFilter);
    end;

    procedure CreateTextTableFilterWithoutTableName(CurrentLineOnly: Boolean): Text
    var
        TextTableFilter: Text;
        TextFieldFilter: Text;
        FirstField: Boolean;
    begin
        FirstField := true;
        if CurrentLineOnly then
            AppendFieldFilter(TextTableFilter, CreateTextFieldFilter())
        else
            if Rec.Find('-') then
                repeat
                    TextFieldFilter := CreateTextFieldFilter();
                    if StrLen(TextFieldFilter) > 0 then begin
                        if not FirstField then
                            TextTableFilter += ',';
                        FirstField := false;
                        AppendFieldFilter(TextTableFilter, TextFieldFilter);
                    end;
                until Rec.Next() = 0;

        exit(TextTableFilter);
    end;

    local procedure CreateTextFieldFilter(): Text
    begin
        if (Rec."Field Number" > 0) and (StrLen(Rec."Field Filter") > 0) then
            exit(QuoteValue(Rec."Field Caption", '=') + '=' + QuoteValue(Rec."Field Filter", ','));

        exit('');
    end;

    local procedure AppendFieldFilter(var TextTableFilter: Text; TextFieldFilter: Text)
    begin
        if (StrLen(TextTableFilter) + StrLen(TextFieldFilter)) > 200 then
            Error(FilterTooLargeErr);

        TextTableFilter += TextFieldFilter;
    end;

    local procedure QuoteValue(TextValue: Text[250]; TextCausingQuotes: Text): Text
    var
        InnerQuotePosition: Integer;
        TextValue2: Text;
    begin
        // If quotes are not needed return initial value:
        if StrPos(TextValue, TextCausingQuotes) <= 0 then
            exit(TextValue);

        // Escape possible double quote characters:
        InnerQuotePosition := StrPos(TextValue, '"');
        while InnerQuotePosition > 0 do begin
            TextValue2 += CopyStr(TextValue, 1, InnerQuotePosition) + '"';
            TextValue := CopyStr(TextValue, InnerQuotePosition + 1, StrLen(TextValue));
            InnerQuotePosition := StrPos(TextValue, '"');
        end;

        // Surround by double quotes:
        TextValue2 += TextValue;
        TextValue2 := '"' + TextValue2 + '"';

        exit(TextValue2);
    end;

    local procedure TableNameMatches(var TableFilterText: Text): Boolean
    var
        TableName2: Text;
        TableNamesEqual: Boolean;
    begin
        // Extract TableName from TableFilterText.
        // If the first character in TableFilterText is a double quote,get the table name from the quotes,
        // otherwise read it from TableFilterText until the colon:
        if StrPos(CopyStr(TableFilterText, 1, 1), '"') = 1 then
            TableName2 := GetQuotedValue(TableFilterText, ':')
        else
            TableName2 := GetValue(TableFilterText, ':');

        TableNamesEqual := TableName2 = Rec."Table Name";

        if TableNamesEqual then
            // Remove the first blank space:
            TableFilterText := CopyStr(TableFilterText, 2, StrLen(TableFilterText) - 1);

        exit(TableNamesEqual);
    end;

    local procedure ExtractFieldName(var TableFilterText: Text)
    var
        FieldTable: Record "Field";
        FieldName2: Text;
    begin
        // If the first character s a double quote, extract the field name from the quotes,
        // otherwise read it from the string until the equal sign:
        if StrPos(CopyStr(TableFilterText, 1, 1), '"') = 1 then
            FieldName2 := GetQuotedValue(TableFilterText, '=')
        else
            FieldName2 := GetValue(TableFilterText, '=');

        FieldTable.Reset();
        FieldTable.SetRange(TableNo, Rec."Table Number");
        FieldTable.SetRange("Field Caption", FieldName2);
        FieldTable.FindFirst();
        FillSourceRecord(FieldTable);
        Rec."Line No." := 0;
    end;

    local procedure ExtractFieldFilter(var TableFilterText: Text)
    var
        FieldFilter2: Text;
    begin
        // If the first character is a double quote, extract the field filter from the quotes,
        // otherwise read it from the string until the comma:
        if StrPos(CopyStr(TableFilterText, 1, 1), '"') = 1 then
            FieldFilter2 := GetQuotedValue(TableFilterText, ',')
        else
            FieldFilter2 := GetValue(TableFilterText, ',');

        Rec."Field Filter" := FieldFilter2;
        CurrPage.Update(true);
    end;

    local procedure CheckFieldFilter()
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(Rec."Table Number");
        FieldRef := RecordRef.Field(Rec."Field Number");
        FieldRef.SetFilter(Rec."Field Filter");
        Rec."Field Filter" := FieldRef.GetFilter;
        RecordRef.Close();
    end;

    local procedure SetCaption()
    begin
        CurrPage.Caption := CurrPage.Caption + ' - ' + SourceTableCaption;
    end;

    procedure GetViewFilter(): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Rec."Table Number");
        if Rec.FindSet() then
            repeat
                FldRef := RecRef.Field(Rec."Field Number");
                FldRef.SetFilter(Rec."Field Filter");
            until Rec.Next() = 0;
        exit(RecRef.GetView());
    end;

    procedure GetFilterFieldsList(var TempTableFilter: Record "Table Filter")
    begin
        TempTableFilter.Reset();
        TempTableFilter.DeleteAll();
        if Rec.FindSet() then
            repeat
                TempTableFilter.Init();
                TempTableFilter.TransferFields(Rec);
                TempTableFilter.Insert();
            until Rec.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQuotedValue(var TableFilter: Record "Table Filter"; var TextString: Text; Delimiter: Text; var PartOfText: Text; var IsHandled: Boolean)
    begin
    end;
}

