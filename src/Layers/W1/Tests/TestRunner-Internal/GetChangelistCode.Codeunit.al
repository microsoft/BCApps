codeunit 130026 "Get Changelist Code"
{
    var
        TempChangelistCode: Record "Changelist Code" temporary;

    [Scope('OnPrem')]
    procedure ProcessGitChanges(ChangesPath: Text)
    var
        ChangelistCode: Record "Changelist Code";
    begin
        ChangelistCode.DeleteAll();
        ProcessChangeList(ChangesPath);
        Cleanup();
    end;

    [Scope('OnPrem')]
    procedure ProcessChangeList(ChangesPath: Text)
    var
        SReader: DotNet StreamReader;
    begin
        OpenReadFile(ChangesPath, SReader);
        Process(SReader);
        SReader.Close();
    end;

    local procedure Process(var SReader: DotNet StreamReader)
    begin
        ProcessInputFile(SReader);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure Cleanup()
    var
        ChangelistCode: Record "Changelist Code";
        TriggerChangelistCode: Record "Changelist Code";
        ObjectChangelistCode: Record "Changelist Code";
        CheckObjectHasCode: Boolean;
        CheckTriggerHasCode: Boolean;
    begin
        if ChangelistCode.FindSet() then
            repeat
                case ChangelistCode."Line Type" of
                    ChangelistCode."Line Type"::Object:
                        begin
                            if CheckTriggerHasCode then
                                RemoveTrigger(TriggerChangelistCode);
                            if CheckObjectHasCode then
                                RemoveObject(ObjectChangelistCode);
                            ObjectChangelistCode := ChangelistCode;
                            CheckTriggerHasCode := false;
                            CheckObjectHasCode := true;
                        end;
                    ChangelistCode."Line Type"::"Trigger/Function":
                        begin
                            if CheckTriggerHasCode then
                                RemoveTrigger(TriggerChangelistCode);
                            TriggerChangelistCode := ChangelistCode;
                            CheckTriggerHasCode := true;
                        end;
                    ChangelistCode."Line Type"::Empty:
                        ;
                    else
                        CheckTriggerHasCode := false;
                        CheckObjectHasCode := false;
                end;
            until ChangelistCode.Next() = 0;

        if CheckTriggerHasCode then
            RemoveTrigger(TriggerChangelistCode);
        if CheckObjectHasCode then
            RemoveObject(ObjectChangelistCode);
    end;

    local procedure ProcessInputFile(var SReader: DotNet StreamReader)
    var
        TokenLine: Text;
        TrimmedToken: Text;
        LowerCaseTrimmedToken: Text;
        FilePath: Text;
        ObjectNo: Integer;
        ObjectType: Option;
        ObjectName: Text[1000];
        ElementName: Text[250];
        TriggerName: Text[1000];
        ChangeChar: Char;
        InCode: Boolean;
        i: Integer;
        TokenLen: Integer;
        Indent: Integer;
        TriggerIndent: Integer;
        NextIsEmpty: Boolean;
        CurrIsEmpty: Boolean;
        ObjectLineNo: Integer;
    begin
        i := 0;
        while SReader.Peek() <> -1 do begin
            i += 1;

            TokenLine := SReader.ReadLine();
            TokenLen := StrLen(TokenLine);
            if TokenLen > 0 then begin
                ChangeChar := TokenLine[1];
                if ChangeChar in ['+', '-'] then
                    TokenLine[1] := ' ';
            end else
                ChangeChar := ' ';
            TrimmedToken := TokenLine.Trim();
            Indent := StrLen(TokenLine) - StrLen(TrimmedToken);
            LowerCaseTrimmedToken := LowerCase(TrimmedToken);

            if ObjectNo > 0 then
                if ChangeChar <> '-' then
                    ObjectLineNo += 1;

            case true of
                (ChangeChar = 'd') and TokenLine.StartsWith(' iff --git a/'):
                    begin
                        InCode := false;
                        ObjectType := 0;
                        ObjectNo := 0;
                        ObjectName := '';
                        TriggerName := '';
                        ElementName := '';
                        ChangeChar := ' ';
                        ObjectLineNo := 0;
                    end;
                IsFileStart(ChangeChar, TokenLine, FilePath):
                    ;
                IsObjectStart(TrimmedToken, ObjectType, ObjectNo, ObjectName):
                    begin
                        InCode := false;
                        ObjectLineNo := 1;
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::Object, ObjectLineNo, ObjectName, true, ChangeChar);
                    end;
                IsProcedureStart(TrimmedToken, LowerCaseTrimmedToken, TriggerName):
                    begin
                        InCode := false;
                        TriggerIndent := Indent;
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::"Trigger/Function", ObjectLineNo, TrimmedToken, true, ChangeChar);
                    end;
                IsTriggerStart(TrimmedToken, LowerCaseTrimmedToken, TriggerName):
                    begin
                        InCode := false;
                        TriggerIndent := Indent;
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::"Trigger/Function", ObjectLineNo, StrSubstNo('%1 - %2', ElementName, TrimmedToken), true, ChangeChar);
                    end;
                IsElementStart(InCode, TrimmedToken, LowerCaseTrimmedToken, ElementName):
                    ;
                IsCodeStart(LowerCaseTrimmedToken, TriggerName, Indent, TriggerIndent, ChangeChar, InCode):
                    begin
                        InCode := true;
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::Code, ObjectLineNo, TrimmedToken, true, ChangeChar);
                    end;
                IsCodeEnd(LowerCaseTrimmedToken, TriggerName, Indent, TriggerIndent, ChangeChar, InCode):
                    begin
                        InCode := false;
                        TriggerName := '';
                        TriggerIndent := 0;
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::Code, ObjectLineNo, TrimmedToken, true, ChangeChar);
                    end;
                InCode and (ChangeChar <> '-'):
                    begin
                        CurrIsEmpty := NextIsEmpty;
                        NextIsEmpty := NextIsEmptyLine(LowerCaseTrimmedToken);
                        InsertCodeChange(ObjectType, ObjectNo, TempChangelistCode."Line Type"::Code, ObjectLineNo, TrimmedToken, CurrIsEmpty, ChangeChar);
                    end;
            end;
        end;
    end;

    local procedure IsFileStart(ChangeChar: Char; TokenLine: Text; var FilePath: Text): Boolean
    begin
        if ChangeChar <> '+' then
            exit(false);

        if not TokenLine.StartsWith(' ++ b/') then
            exit(false);

        FilePath := CopyStr(TokenLine, StrLen(' ++ b/') + 1);
        exit(true);
    end;

    local procedure IsObjectStart(TrimmedToken: Text; var ObjectType: Option; var ObjectNo: Integer; var ObjectName: Text): Boolean
    var
        EndPos: Integer;
        ObjectTypeText: Text;
        ObjectNoText: Text;
    begin
        EndPos := StrPos(TrimmedToken, ' ');
        if EndPos = 0 then
            exit(false);
        ObjectTypeText := CopyStr(TrimmedToken, 1, EndPos - 1);
        if not GetObjectType(ObjectTypeText, ObjectType) then
            exit(false);

        TrimmedToken := CopyStr(TrimmedToken, EndPos).TrimStart();
        EndPos := StrPos(TrimmedToken, ' ');
        if EndPos = 0 then
            exit(false);
        ObjectNoText := CopyStr(TrimmedToken, 1, EndPos - 1);
        if not Evaluate(ObjectNo, ObjectNoText) then
            exit(false);

        TrimmedToken := CopyStr(TrimmedToken, EndPos).TrimStart();
        if TrimmedToken[1] = '"' then begin
            TrimmedToken := CopyStr(TrimmedToken, 2);
            EndPos := StrPos(TrimmedToken, '"');
            if EndPos = 0 then
                exit(false);
        end else
            EndPos := StrPos(TrimmedToken, ' ');
        if EndPos > 0 then
            ObjectName := CopyStr(TrimmedToken, 1, EndPos - 1)
        else
            ObjectName := CopyStr(TrimmedToken, 1).TrimEnd();

        ObjectName := StrSubstNo('%1 %2 (%3)', LowerCase(ObjectTypeText), ObjectName, ObjectNo);
        exit(true);
    end;

    local procedure GetObjectType(TrimmedToken: Text; var ObjectType: Option): Boolean
    begin
        case LowerCase(TrimmedToken) of
            'table':
                ObjectType := TempChangelistCode."Object Type"::Table;
            'codeunit':
                ObjectType := TempChangelistCode."Object Type"::Codeunit;
            'report':
                ObjectType := TempChangelistCode."Object Type"::Report;
            'xmlport':
                ObjectType := TempChangelistCode."Object Type"::XMLPort;
            'page':
                ObjectType := TempChangelistCode."Object Type"::Page;
            'form':
                ObjectType := TempChangelistCode."Object Type"::Form;
            'dataport':
                ObjectType := TempChangelistCode."Object Type"::Dataport;
            'menusuite':
                ObjectType := TempChangelistCode."Object Type"::Menusuite;
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsElementStart(InCode: Boolean; TrimmedToken: Text; LowerCaseTrimmedToken: Text; var ElementName: Text): Boolean
    begin
        if InCode then
            exit(false);

        case true of
            LowerCaseTrimmedToken.StartsWith('field'):
                if GetFieldName(TrimmedToken, ElementName) then
                    exit(true);
            LowerCaseTrimmedToken.StartsWith('usercontrol'):
                if GetUserControlName(TrimmedToken, ElementName) then
                    exit(true);
            LowerCaseTrimmedToken.StartsWith('action'):
                if GetActionName(TrimmedToken, ElementName) then
                    exit(true);
            else
                exit(false);
        end;
    end;

    local procedure GetFieldName(TrimmedToken: Text; var FieldName: Text): Boolean
    var
        StartPos: Integer;
        EndPos: Integer;
        RestToken: Text;
    begin
        StartPos := StrPos(TrimmedToken, ';');
        if StartPos = 0 then
            exit(false);
        RestToken := CopyStr(RestToken, StartPos + 1);

        EndPos := StrPos(RestToken, ';');
        if EndPos = 0 then
            exit(false);
        RestToken := CopyStr(RestToken, 1, EndPos - 1);

        FieldName := RestToken.Trim();
        exit(true);
    end;

    local procedure GetUserControlName(TrimmedToken: Text; var UserControlName: Text): Boolean
    var
        StartPos: Integer;
        EndPos: Integer;
        RestToken: Text;
    begin
        StartPos := StrPos(TrimmedToken, '(');
        if StartPos = 0 then
            exit(false);
        RestToken := CopyStr(TrimmedToken, StartPos + 1);

        EndPos := StrPos(RestToken, ';');
        if EndPos = 0 then
            exit(false);
        RestToken := CopyStr(RestToken, 1, EndPos - 1);

        UserControlName := RestToken.Trim();
        exit(true);
    end;

    local procedure GetActionName(TrimmedToken: Text; var ActionName: Text): Boolean
    var
        StartPos: Integer;
        EndPos: Integer;
        RestToken: Text;
    begin
        StartPos := StrPos(TrimmedToken, '(');
        if StartPos = 0 then
            exit(false);
        RestToken := CopyStr(TrimmedToken, StartPos + 1);

        EndPos := StrPos(RestToken, ')');
        if EndPos = 0 then
            exit(false);
        RestToken := CopyStr(RestToken, 1, EndPos - 1);

        ActionName := RestToken.Trim();
        exit(true);
    end;


    local procedure IsProcedureStart(TrimmedToken: Text; LowerCaseTrimmedToken: Text; var ProcedureName: Text): Boolean
    begin
        if LowerCaseTrimmedToken.StartsWith('procedure ') then
            exit(GetProcedureName(CopyStr(TrimmedToken, StrLen('procedure ')), ProcedureName));
        if LowerCaseTrimmedToken.StartsWith('local procedure ') then
            exit(GetProcedureName(CopyStr(TrimmedToken, StrLen('local procedure ')), ProcedureName));
        exit(false);
    end;

    local procedure IsTriggerStart(TrimmedToken: Text; LowerCaseTrimmedToken: Text; var TriggerName: Text): Boolean
    begin
        if LowerCaseTrimmedToken.StartsWith('trigger ') then
            exit(GetTriggerName(CopyStr(TrimmedToken, StrLen('trigger ')), TriggerName));
        exit(false);
    end;

    local procedure IsCodeStart(LowerCaseTrimmedToken: Text; TriggerName: Text; TokenIndent: Integer; TriggerIndent: Integer; ChangeChar: Char; InCode: Boolean): Boolean
    begin
        if InCode then
            exit(false);
        if ChangeChar = '-' then
            exit(false);
        if TriggerName = '' then
            exit(false);
        if TokenIndent <> TriggerIndent then
            exit(false);
        exit(LowerCaseTrimmedToken = 'begin');
    end;

    local procedure IsCodeEnd(LowerCaseTrimmedToken: Text; TriggerName: Text; TokenIndent: Integer; TriggerIndent: Integer; ChangeChar: Char; InCode: Boolean): Boolean
    begin
        if not InCode then
            exit(false);
        if ChangeChar = '-' then
            exit(false);
        if TriggerName = '' then
            exit(false);
        if TokenIndent <> TriggerIndent then
            exit(false);
        exit(LowerCaseTrimmedToken = 'end;');
    end;

    local procedure GetProcedureName(Token: Text; var ProcedureName: Text): Boolean
    begin
        exit(GetTriggerName(Token, ProcedureName));
    end;

    local procedure GetTriggerName(Token: Text; var TriggerName: Text): Boolean
    var
        TrimmedToken: Text;
        EndPos: Integer;
    begin
        TrimmedToken := Token.TrimStart();
        EndPos := StrPos(TrimmedToken, '(');
        if EndPos = 0 then
            exit(false);
        TriggerName := CopyStr(TrimmedToken, 1, EndPos - 1).TrimEnd();
        if TriggerName = '' then
            exit(false);
        exit(true);
    end;

    local procedure InsertCodeChange(ObjectType: Option; ObjectNo: Integer; LineType: Option; ObjectLineNo: Integer; CodeLine: Text; IsEmpty: Boolean; ChangeChar: Char)
    var
        ChangelistCode: Record "Changelist Code";
    begin
        if ObjectType in [ChangelistCode."Object Type"::Form,
                          ChangelistCode."Object Type"::Dataport,
                          ChangelistCode."Object Type"::Menusuite]
        then
            exit;

        ChangelistCode.Init();
        ChangelistCode."Object Type" := ObjectType;
        ChangelistCode."Object No." := ObjectNo;
        ChangelistCode.Change[1] := ChangeChar;
        ChangelistCode."Line Type" := LineType;
        ChangelistCode."Line No." := ObjectLineNo;
        ChangelistCode."Code Coverage Line No." := ObjectLineNo;
        ChangelistCode.Line := CopyStr(CodeLine, 1, 250);
        ChangelistCode."No. of Checkins" := 1;
        ChangelistCode."Is Modification" := false;

        case LineType of
            ChangelistCode."Line Type"::Object:
                begin
                    ChangelistCode.Indentation := 0;
                    if not ChangelistCode.Insert() then;
                end;
            ChangelistCode."Line Type"::"Trigger/Function":
                begin
                    ChangelistCode.Indentation := 1;
                    if not ChangelistCode.Insert() then;
                end;
            ChangelistCode."Line Type"::Code:
                begin
                    ChangelistCode.Indentation := 2;
                    if true in [IsEmpty, ChangeChar = '-', IsEmptyLine(CodeLine)] then
                        ChangelistCode."Line Type" := ChangelistCode."Line Type"::Empty;
                    if not ChangelistCode.Insert() then;
                end;
        end;
    end;

    local procedure IsEmptyLine(LowerCaseTrimmedToken: Text): Boolean
    begin
        LowerCaseTrimmedToken := TrimCodeLine(LowerCaseTrimmedToken);
        if LowerCaseTrimmedToken in ['',
                                'repeat',
                                'if',
                                'while',
                                'until',
                                'then',
                                'begin',
                                'end',
                                'end;',
                                'else',
                                'end else',
                                'end else begin',
                                'else begin',
                                'case',
                                'with',
                                'do']
        then
            exit(true);

        if true in [LowerCaseTrimmedToken.StartsWith(','),
                    LowerCaseTrimmedToken.StartsWith('='),
                    LowerCaseTrimmedToken.StartsWith('('),
                    LowerCaseTrimmedToken.StartsWith('+'),
                    LowerCaseTrimmedToken.StartsWith('-'),
                    LowerCaseTrimmedToken.StartsWith('*'),
                    LowerCaseTrimmedToken.StartsWith('/'),
                    LowerCaseTrimmedToken.StartsWith('['),
                    LowerCaseTrimmedToken.StartsWith(':='),
                    LowerCaseTrimmedToken.StartsWith('in '),
                    LowerCaseTrimmedToken.StartsWith('and '),
                    LowerCaseTrimmedToken.StartsWith('or '),
                    LowerCaseTrimmedToken.StartsWith('xor '),
                    LowerCaseTrimmedToken.StartsWith('not '),
                    LowerCaseTrimmedToken.StartsWith('//')]
        then
            exit(true);
        exit(false);
    end;

    local procedure NextIsEmptyLine(LowerCaseTrimmedToken: Text): Boolean
    begin
        LowerCaseTrimmedToken := TrimCodeLine(LowerCaseTrimmedToken);

        if true in [LowerCaseTrimmedToken.EndsWith(','),
                    LowerCaseTrimmedToken.EndsWith('='),
                    LowerCaseTrimmedToken.EndsWith('('),
                    LowerCaseTrimmedToken.EndsWith('+'),
                    LowerCaseTrimmedToken.EndsWith('-'),
                    LowerCaseTrimmedToken.EndsWith('*'),
                    LowerCaseTrimmedToken.EndsWith('/'),
                    LowerCaseTrimmedToken.EndsWith('['),
                    LowerCaseTrimmedToken.EndsWith(' in'),
                    LowerCaseTrimmedToken.EndsWith(' and'),
                    LowerCaseTrimmedToken.EndsWith(' or'),
                    LowerCaseTrimmedToken.EndsWith(' xor'),
                    LowerCaseTrimmedToken.EndsWith(' not')]
        then
            exit(true);
        exit(false);
    end;

    local procedure RemoveTrigger(TriggerChangelistCode: Record "Changelist Code")
    var
        ChangelistCode: Record "Changelist Code";
    begin
        ChangelistCode := TriggerChangelistCode;
        ChangelistCode.SetRange("Object Type", ChangelistCode."Object Type");
        ChangelistCode.SetRange("Object No.", ChangelistCode."Object No.");
        repeat
            ChangelistCode.Delete();
        until ((ChangelistCode.Next() = 0) or (ChangelistCode."Line Type" = ChangelistCode."Line Type"::"Trigger/Function"))
    end;

    local procedure RemoveObject(ChangelistCode: Record "Changelist Code")
    begin
        ChangelistCode.Reset();
        ChangelistCode.SetRange("Object Type", ChangelistCode."Object Type");
        ChangelistCode.SetRange("Object No.", ChangelistCode."Object No.");
        ChangelistCode.DeleteAll();
    end;

    local procedure OpenReadFile(FilePath: Text; var SReader: DotNet StreamReader): Boolean
    var
        NewFile: DotNet File;
    begin
        if NewFile.Exists(FilePath) then begin
            SReader := SReader.StreamReader(FilePath);
            exit(true);
        end;

        exit(false);
    end;

    local procedure TrimCodeLine(CodeLine: Text) TrimmedCodeLine: Text
    begin
        TrimmedCodeLine := CodeLine.Trim();
        if StrPos(TrimmedCodeLine, '//') > 0 then
            TrimmedCodeLine := DelStr(TrimmedCodeLine, StrPos(TrimmedCodeLine, '//')).Trim();
    end;

    [Scope('OnPrem')]
    procedure ExpandEnvVariables(Path: Text): Text
    var
        [RunOnClient]
        Environment: DotNet Environment;
    begin
        exit(Environment.ExpandEnvironmentVariables(Path));
    end;

    [Scope('OnPrem')]
    procedure GetSDRootPath(): Text
    begin
        exit(ExpandEnvVariables('//depot/releases/%CoreXtBranch%/'));
    end;

    [Scope('OnPrem')]
    procedure GetSdPath(): Text
    begin
        exit(GetSDRootPath() + 'App');
    end;

    [Scope('OnPrem')]
    procedure GetSdClientPath(): Text
    begin
        exit(ExpandEnvVariables('%INETROOT%\'));
    end;

}
