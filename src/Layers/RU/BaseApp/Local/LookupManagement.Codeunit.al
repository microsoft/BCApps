#pragma warning disable AA0247
codeunit 17209 "Lookup Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text1001: Label ' - Option List';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1003: Label 'Description';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1004: Label 'Name';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1010: Label 'Illegal using of symbol `point`.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1011: Label 'Illegal Value\%1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure BuildLookupBuffer(var TempLookupBuffer: Record "Lookup Buffer" temporary; TableID: Integer; FieldID: Integer)
    var
        xRecordRef: RecordRef;
        xFieldRef: FieldRef;
        xOptionString: Text[1024];
        xPosition: Integer;
    begin
        TempLookupBuffer.Reset();
        TempLookupBuffer.DeleteAll();

        xRecordRef.Open(TableID, true);
        xFieldRef := xRecordRef.Field(FieldID);
        if xFieldRef.Type = FieldType::Option then
            xOptionString := xFieldRef.OptionCaption;
        xRecordRef.Close();

        while xOptionString <> '' do begin
            xPosition := StrPos(xOptionString, ',');
            TempLookupBuffer.Init();
            if xPosition = 0 then begin
                TempLookupBuffer.Text := CopyStr(xOptionString, 1, MaxStrLen(TempLookupBuffer.Text));
                xOptionString := '';
            end else
                if xPosition = 1 then begin
                    TempLookupBuffer.Text := '';
                    xOptionString := CopyStr(xOptionString, xPosition + 1);
                end else begin
                    TempLookupBuffer.Text := CopyStr(xOptionString, 1, xPosition - 1);
                    xOptionString := CopyStr(xOptionString, xPosition + 1)
                end;
            if TempLookupBuffer.Text <> '' then
                TempLookupBuffer.Insert();
            TempLookupBuffer.Integer += 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatOptionTotaling(TableID: Integer; FieldID: Integer; TotalingString: Text[250]) ResultText: Text[250]
    var
        TempLookupBuffer: Record "Lookup Buffer" temporary;
        RestText: Text[250];
        NextPart: Text[250];
        NextString: Text[250];
        NextCount: Integer;
        PointPosition: Integer;
        ORPosition: Integer;
        FindPoint: Boolean;
    begin
        if TotalingString = '' then
            exit;

        BuildLookupBuffer(TempLookupBuffer, TableID, FieldID);

        TempLookupBuffer.Reset();
        RestText := TotalingString;
        while StrLen(RestText) <> 0 do begin
            PointPosition := StrPos(RestText, '.');
            if PointPosition <> StrPos(RestText, '..') then
                Error(Text1010);
            ORPosition := StrPos(RestText, '|');
            if (PointPosition <> 0) or (ORPosition <> 0) then begin
                FindPoint :=
                  ((PointPosition <> 0) and ((ORPosition = 0) or ((ORPosition <> 0) and (PointPosition < ORPosition))));
                if FindPoint then
                    NextPart := CopyStr(RestText, 1, PointPosition - 1)
                else
                    NextPart := CopyStr(RestText, 1, ORPosition - 1);
                if (NextPart <> '') or (RestText <> TotalingString) then begin
                    if not Evaluate(NextCount, NextPart) then
                        Error(Text1011, ResultText + RestText);
                    TempLookupBuffer.SetRange(Integer, NextCount);
                    if TempLookupBuffer.Find('-') then
                        NextString := TempLookupBuffer.Text
                    else
                        NextString := NextPart;
                    ResultText := ResultText + NextString;
                end;
                if FindPoint then begin
                    RestText := CopyStr(RestText, PointPosition + 2);
                    ResultText := ResultText + '..';
                end else begin
                    RestText := CopyStr(RestText, ORPosition + 1);
                    ResultText := ResultText + '|';
                    if RestText = '' then
                        Error(Text1011, ResultText);
                end;
            end else begin
                if not Evaluate(NextCount, RestText) then
                    Error(Text1011, ResultText + RestText);
                TempLookupBuffer.SetRange(Integer, NextCount);
                if TempLookupBuffer.Find('-') then
                    NextString := TempLookupBuffer.Text
                else
                    NextString := RestText;
                ResultText := ResultText + NextString;
                RestText := '';
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupOptionList(TableID: Integer; FieldID: Integer; var Text: Text[250]): Boolean
    var
        TempLookupBuffer: Record "Lookup Buffer" temporary;
        ChoiceOptionValues: Page "Option Values";
        xRecordRef: RecordRef;
        xFieldRef: FieldRef;
    begin
        Clear(ChoiceOptionValues);
        ChoiceOptionValues.CreateLookupBuffer(TableID, FieldID);
        ChoiceOptionValues.LookupMode := true;
        xRecordRef.Open(TableID, true);
        xFieldRef := xRecordRef.Field(FieldID);
        ChoiceOptionValues.SetFormTitle(xFieldRef.Caption);
        xRecordRef.Close();
        if ACTION::LookupOK = ChoiceOptionValues.RunModal() then begin
            ChoiceOptionValues.GetRecord(TempLookupBuffer);
            Text := Format(TempLookupBuffer.Integer);
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDownOptionList(TableID: Integer; FieldID: Integer; Totaling: Text[250])
    var
        TempLookupBuffer: Record "Lookup Buffer" temporary;
        ChoiceOptionValues: Page "Option Values";
        xRecordRef: RecordRef;
        xFieldRef: FieldRef;
    begin
        Clear(ChoiceOptionValues);
        ChoiceOptionValues.CreateLookupBuffer(TableID, FieldID);
        TempLookupBuffer.SetFilter(Integer, Totaling);
        ChoiceOptionValues.SetTableView(TempLookupBuffer);
        xRecordRef.Open(TableID, true);
        xFieldRef := xRecordRef.Field(FieldID);
        ChoiceOptionValues.SetFormTitle(xFieldRef.Caption + Text1001);
        xRecordRef.Close();
        ChoiceOptionValues.Run();
    end;

    [Scope('OnPrem')]
    procedure MergeOptionLists(TableID: Integer; FieldID: Integer; Totaling1: Text[250]; Totaling2: Text[250]; var Totaling: Text[250]): Boolean
    var
        TempLookupBuffer: Record "Lookup Buffer" temporary;
        Node1: Text[30];
        Node2: Text[30];
    begin
        Totaling := '';
        case true of
            Totaling1 = Totaling2,
          Totaling1 = '':
                Totaling := Totaling2;
            Totaling2 = '':
                Totaling := Totaling1;
        end;
        if Totaling <> '' then
            exit(true);

        BuildLookupBuffer(TempLookupBuffer, TableID, FieldID);
        TempLookupBuffer.Reset();
        TempLookupBuffer.SetFilter(Integer, Totaling1);
        if TempLookupBuffer.Find('-') then begin
            repeat
                TempLookupBuffer.Mark := true;
            until TempLookupBuffer.Next(1) = 0;
            TempLookupBuffer.MarkedOnly := true;
            if not TempLookupBuffer.Find('-') then
                exit(false);
            repeat
                TempLookupBuffer.SetFilter(Integer, Totaling2);
                if not TempLookupBuffer.Find() then
                    TempLookupBuffer.Mark := false;
                TempLookupBuffer.SetRange(Integer);
            until TempLookupBuffer.Next(1) = 0;
            if not TempLookupBuffer.Find('-') then
                exit(false);
            Node1 := Format(TempLookupBuffer.Integer);
            Node2 := Node1;
            TempLookupBuffer.MarkedOnly := false;
            repeat
                if TempLookupBuffer.Mark() then
                    Node2 := Format(TempLookupBuffer.Integer)
                else begin
                    AddNextFragment(Totaling, Node1, Node2);
                    Node1 := '';
                    Node2 := Node1;
                    TempLookupBuffer.MarkedOnly := true;
                    if TempLookupBuffer.Next(1) <> 0 then begin
                        Node1 := Format(TempLookupBuffer.Integer);
                        Node2 := Node1;
                        TempLookupBuffer.MarkedOnly := false;
                    end;
                end;
            until TempLookupBuffer.Next(1) = 0;
            AddNextFragment(Totaling, Node1, Node2);
            exit(true);
        end;
    end;

    local procedure AddNextFragment(var Total: Text[250]; Node1: Text[30]; Node2: Text[30])
    begin
        if Node1 <> '' then
            if Node1 = Node2 then
                if Total = '' then
                    Total := Node1
                else
                    Total := StrSubstNo('%1|%2', Total, Node1)
            else
                if Total = '' then
                    Total := StrSubstNo('%1..%2', Node1, Node2)
                else
                    Total := StrSubstNo('%1|%2..%3', Total, Node1, Node2);
    end;

    [Scope('OnPrem')]
    procedure BuildKeyList(var TmpKeyList: Record "Lookup Buffer" temporary; TableID: Integer)
    var
        xRecordRef: RecordRef;
        xFieldRef: FieldRef;
        xKeyRef: KeyRef;
        xCountKey: Integer;
        xCountNo: Integer;
    begin
        TmpKeyList.Reset();
        TmpKeyList.DeleteAll();
        Clear(TmpKeyList);

        xRecordRef.Open(TableID, true);
        for xCountKey := 1 to xRecordRef.KeyCount do begin
            xKeyRef := xRecordRef.KeyIndex(xCountKey);
            if xKeyRef.Active then begin
                for xCountNo := 1 to xKeyRef.FieldCount do begin
                    xFieldRef := xKeyRef.FieldIndex(xCountNo);
                    if TmpKeyList.Text = '' then
                        TmpKeyList.Text := xFieldRef.Caption
                    else
                        TmpKeyList.Text :=
                          CopyStr(StrSubstNo('%1,%2', TmpKeyList.Text, xFieldRef.Caption), 1, MaxStrLen(TmpKeyList.Text));
                end;
                TmpKeyList.Integer := xCountKey;
                TmpKeyList.Insert();
                TmpKeyList.Text := '';
            end;
        end;
        xRecordRef.Close();
    end;

    [Scope('OnPrem')]
    procedure PrepeareLookupCode(TableID: Integer; FieldID: Integer; var IDRecordRef: Integer; var IDFieldRefCode: Integer; var IDFieldRefText: Integer; TableRelationID: Integer; FieldRelationNo: Integer): Boolean
    var
        "Field": Record "Field";
        xRecordRef: RecordRef;
        xFieldRef: FieldRef;
        xKeyRef: KeyRef;
    begin
        if Field.Get(TableID, FieldID) then
            if (Field.Type = Field.Type::Code) and
               ((TableRelationID <> 0) or (Field.RelationTableNo <> 0))
            then begin
                if Field.RelationTableNo <> 0 then begin
                    xRecordRef.Open(Field.RelationTableNo, true);
                    if Field.RelationFieldNo = 0 then begin
                        xKeyRef := xRecordRef.KeyIndex(1);
                        xFieldRef := xKeyRef.FieldIndex(1);
                    end else
                        xFieldRef := xRecordRef.Field(Field.RelationFieldNo);
                    IDRecordRef := Field.RelationTableNo;
                end else begin
                    xRecordRef.Open(TableRelationID, true);
                    if FieldRelationNo = 0 then begin
                        xKeyRef := xRecordRef.KeyIndex(1);
                        xFieldRef := xKeyRef.FieldIndex(1);
                    end else
                        xFieldRef := xRecordRef.Field(FieldRelationNo);
                    IDRecordRef := TableRelationID;
                end;
                if Format(xFieldRef.Type) = Format(Field.Type) then begin
                    Field.SetRange(TableNo, IDRecordRef);
                    Field.SetRange(Type, Field.Type::Text);
                    Field.SetRange(Enabled, true);
                    Field.SetRange(FieldName, Text1003);   // 'Description'
                    Field."No." := 0;
                    if not Field.FindFirst() then begin
                        Field.SetRange(FieldName, Text1004); // 'Name'
                        if not Field.FindFirst() then begin
                            Field.SetRange(FieldName);
                            if not Field.FindFirst() then
                                Field."No." := xFieldRef.Number;
                        end;
                    end;
                    if Field."No." <> 0 then begin
                        IDFieldRefCode := xFieldRef.Number;
                        IDFieldRefText := Field."No.";
                        xRecordRef.Close();
                        exit(true);
                    end;
                end;
                xRecordRef.Close();
            end;
    end;
}

