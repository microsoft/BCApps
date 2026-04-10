namespace System.Integration;

using System;

codeunit 6711 "OData Action Management"
{

    trigger OnRun()
    begin
    end;

    var
        "Keys": DotNet GenericDictionary2;
        KeysInitialized: Boolean;

    procedure AddKey(FieldNo: Integer; Value: Variant)
    begin
        if not KeysInitialized then
            InitializeDictionary();

        Keys.Add(FieldNo, Value);
    end;

    [Scope('OnPrem')]
    procedure SetUpdatedPageResponse(var ActionContext: DotNet WebServiceActionContext; EntityObjectId: Integer)
    var
        ResponseCode: DotNet WebServiceActionContext_StatusCode;
    begin
        SetCommonContextValues(ActionContext, EntityObjectId);
        ActionContext.SetNavObjectType(OBJECTTYPE::Page);
        ActionContext.ResultCode := ResponseCode.Updated;
    end;

    [Scope('OnPrem')]
    procedure SetCreatedPageResponse(var ActionContext: DotNet WebServiceActionContext; EntityObjectId: Integer)
    var
        ResponseCode: DotNet WebServiceActionContext_StatusCode;
    begin
        SetCommonContextValues(ActionContext, EntityObjectId);
        ActionContext.SetNavObjectType(OBJECTTYPE::Page);
        ActionContext.ResultCode := ResponseCode.Created;
    end;

    [Scope('OnPrem')]
    procedure SetDeleteResponse(var ActionContext: DotNet WebServiceActionContext)
    var
        ResponseCode: DotNet WebServiceActionContext_StatusCode;
    begin
        ActionContext.ResultCode := ResponseCode.Deleted;
    end;

    [Scope('OnPrem')]
    procedure SetDeleteResponseLocation(var ActionContext: DotNet WebServiceActionContext; EntityObjectId: Integer)
    var
        ResponseCode: DotNet WebServiceActionContext_StatusCode;
    begin
        SetCommonContextValues(ActionContext, EntityObjectId);
        ActionContext.SetNavObjectType(OBJECTTYPE::Page);
        ActionContext.ResultCode := ResponseCode.Deleted;
    end;

    local procedure InitializeDictionary()
    var
        Type: DotNet Type;
        Activator: DotNet Activator;
        Arr: DotNet Array;
        "Object": DotNet Object;
        DummyInt: Integer;
    begin
        Arr := Arr.CreateInstance(GetDotNetType(Type), 2);
        Arr.SetValue(GetDotNetType(DummyInt), 0);
        Arr.SetValue(GetDotNetType(Object), 1);

        Type := GetDotNetType(Keys);
        Type := Type.MakeGenericType(Arr);

        Keys := Activator.CreateInstance(Type);
        KeysInitialized := true;
    end;

    local procedure SetCommonContextValues(var ActionContext: DotNet WebServiceActionContext; EntityObjectId: Integer)
    begin
        ActionContext.NavObjectId := EntityObjectId;
        if KeysInitialized then
            ActionContext.AddEntityKeys(Keys);
    end;
}

