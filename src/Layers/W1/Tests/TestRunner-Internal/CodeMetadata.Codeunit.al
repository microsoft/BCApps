codeunit 130005 "Code Metadata"
{

    trigger OnRun()
    begin
    end;

    var
        ObjectCode: Text;
        LastObjectType: Option;
        LastObjectId: Integer;
        FunctionTypeNotFount: Label 'Function Type not found for function %1.';
        NoCodeInObject: Label 'No code in the object.';
        NotFoundInSourceCode: Label '%1 not found in the source code.';
        ExpectedNavHandler: Label 'Expected NavHandler in the Properties: %1.';
        ObjectIdIdentifier: Label 'ObjectId =';
        HandlerStart: Label 'Handlers=@"';
        HandlerEnd: Label '", TestMethod';

    [Scope('OnPrem')]
    procedure GetFunctionType(ObjectType: Option; ObjectId: Integer; FunctionName: Text): Text
    var
        "Code": Text;
        Properties: Text;
    begin
        Code := ReadCode(ObjectType, ObjectId);
        Properties := GetProperties(Code, FunctionName);

        if Properties = '' then
            exit('Normal');

        if StrPos(Properties, 'NavTest') = 1 then
            exit('Test');

        if StrPos(Properties, 'NavHandler') = 1 then
            exit(GetHandlerType(Properties));

        Error(FunctionTypeNotFount, FunctionName);
    end;

    [Scope('OnPrem')]
    procedure GetFunctionHandlers(ObjectType: Option; ObjectId: Integer; FunctionName: Text): Text
    var
        "Code": Text;
        Properties: Text;
    begin
        Code := ReadCode(ObjectType, ObjectId);
        Properties := GetProperties(Code, FunctionName);

        if StrPos(Properties, 'NavTest') = 1 then
            exit(GetHandlers(Properties));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetObjectIdFromHandler(ObjectType: Option; ObjectId: Integer; FunctionName: Text): Integer
    var
        "Code": Text;
        FunctionDefinition: Text;
        Id: Integer;
        ObjectIdStart: Integer;
        ObjectIdLength: Integer;
        IdString: Text;
    begin
        Code := ReadCode(ObjectType, ObjectId);
        FunctionDefinition := GetFunctionDefinition(Code, FunctionName);

        if StrPos(FunctionDefinition, '[NavObjectId(') > 0 then begin
            // Find ObjectId =
            ObjectIdStart := StrPos(FunctionDefinition, ObjectIdIdentifier) + StrLen(ObjectIdIdentifier) + 1;
            // Find Next )
            ObjectIdLength := StrPos(CopyStr(FunctionDefinition, ObjectIdStart), ')');
            IdString := CopyStr(FunctionDefinition, ObjectIdStart, ObjectIdLength - 1);
            Evaluate(Id, IdString);
        end;

        exit(Id);
    end;

    [Scope('OnPrem')]
    procedure ReadCode(ObjectType: Option; ObjectId: Integer): Text
    var
        AppObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        InStream: InStream;
        "Code": Text;
    begin
        if (LastObjectType = ObjectType) and (LastObjectId = ObjectId) then
            exit(ObjectCode);

        ObjectCode := '';

        AllObj.Get(ObjectType, ObjectId);
        AppObjectMetadata.Get(AllObj."App Runtime Package ID", ObjectType, ObjectId);
        AppObjectMetadata.CalcFields("User Code");
        AppObjectMetadata."User Code".CreateInStream(InStream);

        while (not InStream.EOS) and (StrPos(Code, 'SourceSpans') = 0) do begin
            InStream.ReadText(Code);
            ObjectCode := ObjectCode + Code;
        end;

        if StrLen(ObjectCode) = 0 then
            Error(NoCodeInObject);

        LastObjectType := ObjectType;
        LastObjectId := ObjectId;

        exit(ObjectCode);
    end;

    [Scope('OnPrem')]
    procedure FunctionExists("Code": Text; FunctionName: Text): Boolean
    begin
        exit(StrPos(Code, StrSubstNo(' new %1_Scope(', FunctionName)) > 0);
    end;

    local procedure GetProperties("Code": Text; FunctionName: Text): Text
    var
        IndexFunction: Integer;
        IndexPublic: Integer;
        IndexBracketStart: Integer;
        IndexBracketEnd: Integer;
        Prop: Text;
        IndexCurlyBracketEnd: Integer;
    begin
        if not FunctionExists(Code, FunctionName) then
            Error(NotFoundInSourceCode, FunctionName);

        // Find public statement
        IndexFunction := StrPos(Code, StrSubstNo(' new %1_Scope(', FunctionName));
        IndexPublic := FindFirstBefore(Code, 'public ', IndexFunction);
        IndexCurlyBracketEnd := FindFirstBefore(Code, '}', IndexPublic);

        // Find ]
        IndexBracketEnd := FindFirstBefore(Code, ']', IndexPublic);

        // Find [
        IndexBracketStart := FindFirstBefore(Code, '[', IndexBracketEnd);

        // return empty if no properties
        if (IndexCurlyBracketEnd > IndexBracketEnd) or (IndexBracketEnd < IndexBracketStart) or (IndexPublic < IndexBracketEnd) then
            exit('');

        Prop := CopyStr(Code, IndexBracketStart, IndexBracketEnd - IndexBracketStart - 1);

        // return Property string if found.
        exit(Prop);
    end;

    local procedure GetFunctionDefinition("Code": Text; FunctionName: Text): Text
    var
        IndexFunction: Integer;
        IndexFunctionDefStart: Integer;
    begin
        IndexFunction := StrPos(Code, StrSubstNo(' new %1_Scope(', FunctionName));
        IndexFunctionDefStart := FindFirstBefore(Code, FunctionName + '(', IndexFunction);
        exit(CopyStr(Code, IndexFunctionDefStart, IndexFunction - IndexFunctionDefStart));
    end;

    local procedure FindFirstBefore("Code": Text; SubString: Text; Index: Integer): Integer
    var
        LastIndex: Integer;
        NextIndex: Integer;
    begin
        NextIndex := StrPos(Code, SubString);

        while (NextIndex > 0) and ((LastIndex + NextIndex + StrLen(SubString)) < Index) do begin
            LastIndex := LastIndex + NextIndex + StrLen(SubString);
            Code := DelStr(Code, 1, NextIndex + StrLen(SubString));
            NextIndex := StrPos(Code, SubString);
        end;

        exit(LastIndex);
    end;

    local procedure GetHandlerType(Properties: Text): Text
    var
        IndexType: Integer;
        IndexTypeEnd: Integer;
    begin
        if StrPos(Properties, 'NavHandler') <> 1 then
            Error(ExpectedNavHandler, Properties);

        IndexType := StrPos(Properties, '.') + 1;
        IndexTypeEnd := StrPos(Properties, ')');

        exit(CopyStr(Properties, IndexType, IndexTypeEnd - IndexType) + 'Handler');
    end;

    local procedure GetHandlers(Properties: Text): Text
    var
        IndexHandlerStart: Integer;
        IndexHandlerEnd: Integer;
    begin
        if StrPos(Properties, HandlerStart) = 0 then
            exit('');

        IndexHandlerStart := StrPos(Properties, HandlerStart) + StrLen(HandlerStart);
        IndexHandlerEnd := StrPos(Properties, HandlerEnd);

        exit(CopyStr(Properties, IndexHandlerStart, IndexHandlerEnd - IndexHandlerStart));
    end;
}

