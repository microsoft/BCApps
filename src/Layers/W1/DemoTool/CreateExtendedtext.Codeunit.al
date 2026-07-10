codeunit 101279 "Create Extended text"
{

    trigger OnRun()
    begin
        ItemModify('1920-S', false);
        ItemModify('766BC-A', true);

        CreateExtHeader(XITEM, '1920-S', '', 1, true);
        CreateExtLines(XITEM, '1920-S', '', 1, XTogowourconferencetable);
        CreateExtLines(XITEM, '1920-S', '', 1, Xwerecommendourguestchairs);
        CreateExtLines(XITEM, '1920-S', '', 1, Xwhichareavailableinblack);
        CreateExtLines(XITEM, '1920-S', '', 1, Xbluegreenandyellow);

        CreateExtHeader(XITEM, '766BC-A', '', 1, true);
        CreateExtLines(XITEM, '766BC-A', '', 1, XTheconferencepackagecontains);
        CreateExtLines(XITEM, '766BC-A', '', 1, Xonetabletwelveblackchairs);
        CreateExtLines(XITEM, '766BC-A', '', 1, Xandonewhiteboard);
    end;

    var
        ExtendedHeader: Record "Extended Text Header";
        ExtendedLines: Record "Extended Text Line";
        Item: Record Item;
        NextLineNo: Integer;
        XITEM: Label 'ITEM';
        XTogowourconferencetable: Label 'To go with our conference table,';
        Xwerecommendourguestchairs: Label 'we recommend our guest chairs,';
        Xwhichareavailableinblack: Label 'which are available in black,';
        Xbluegreenandyellow: Label 'blue, green and yellow.';
        XTheconferencepackagecontains: Label 'The conference package contains';
        Xonetabletwelveblackchairs: Label 'one table, twelve black chairs,';
        Xandonewhiteboard: Label 'and one whiteboard.';

    procedure CreateExtHeader("Table Name": Text[30]; No: Code[20]; "Language Code": Code[10]; "Text No.": Integer; "All Language Codes": Boolean)
    begin
        ExtendedHeader.Init();
        case "Table Name" of
            'Standard Text':
                ExtendedHeader."Table Name" := ExtendedHeader."Table Name"::"Standard Text";
            'G/L Account':
                ExtendedHeader."Table Name" := ExtendedHeader."Table Name"::"G/L Account";
            XITEM:
                ExtendedHeader."Table Name" := ExtendedHeader."Table Name"::Item;
            'Resource':
                ExtendedHeader."Table Name" := ExtendedHeader."Table Name"::Resource;
        end;
        ExtendedHeader."No." := No;
        ExtendedHeader."Language Code" := "Language Code";
        ExtendedHeader."Text No." := "Text No.";
        ExtendedHeader."All Language Codes" := "All Language Codes";
        ExtendedHeader.Insert();
        NextLineNo := 10000;
    end;

    procedure CreateExtLines("Table Name": Text[30]; "No.": Code[20]; "Language Code": Code[10]; "Text No.": Integer; LineText: Text[50])
    begin
        ExtendedLines.Init();
        case "Table Name" of
            'Standard Text':
                ExtendedLines."Table Name" := ExtendedLines."Table Name"::"Standard Text";
            'G/L Account':
                ExtendedLines."Table Name" := ExtendedLines."Table Name"::"G/L Account";
            XITEM:
                ExtendedLines."Table Name" := ExtendedLines."Table Name"::Item;
            'Resource':
                ExtendedLines."Table Name" := ExtendedLines."Table Name"::Resource;
        end;
        ExtendedLines."No." := "No.";
        ExtendedLines."Language Code" := "Language Code";
        ExtendedLines."Text No." := "Text No.";
        ExtendedLines."Line No." := NextLineNo;
        ExtendedLines.Text := LineText;
        ExtendedLines.Insert();
        NextLineNo := NextLineNo + 10000;
    end;

    procedure ItemModify("Item No.": Code[20]; "Automatic Ext. Texts": Boolean)
    begin
        Item.Get("Item No.");
        // Default value of "Automatic Ext. Texts" is yes
        Item."Automatic Ext. Texts" := "Automatic Ext. Texts";
        Item.Modify();
    end;
}

