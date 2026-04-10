codeunit 139141 "Update Parent Register Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempUpdateParentRegisterLine: Record "Update Parent Register Line" temporary;
        Assert: Codeunit Assert;
        Collecting: Boolean;
        CurrentLineNo: Integer;
        CurrEnumeratorDone: Boolean;
        RunSequence: Integer;
        RunID: Code[10];

    [Scope('OnPrem')]
    procedure Clear()
    var
        UpdateParentRegisterLineClear: Record "Update Parent Register Line";
    begin
        UpdateParentRegisterLineClear.DeleteAll();
        TempUpdateParentRegisterLine.DeleteAll();

        RunSequence := 1;
    end;

    [Scope('OnPrem')]
    procedure Start()
    begin
        Collecting := true;
    end;

    [Scope('OnPrem')]
    procedure Registrate(LinePageId: Integer; LineMethod: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord; LineOperation: Option LineOperation)
    begin
        if not Collecting then
            exit;

        TempUpdateParentRegisterLine.ID := RunID;
        TempUpdateParentRegisterLine.Sequence := RunSequence;
        TempUpdateParentRegisterLine."Page Id" := LinePageId;
        TempUpdateParentRegisterLine.Method := LineMethod;
        TempUpdateParentRegisterLine.Operation := LineOperation;
        TempUpdateParentRegisterLine.Insert();
        RunSequence := RunSequence + 1;
    end;

    [Scope('OnPrem')]
    procedure Stop()
    begin
        Collecting := false;
    end;

    [Scope('OnPrem')]
    procedure Init(ParmID: Code[10])
    begin
        RunID := ParmID;
        RunSequence := 1;
    end;

    [Scope('OnPrem')]
    procedure RegistrateVisit(LinePageId: Integer; LineMethod: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord)
    begin
        Registrate(LinePageId, LineMethod, 0)
    end;

    [Scope('OnPrem')]
    procedure RegistratePreUpdate(LinePageId: Integer; LineMethod: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord)
    begin
        Registrate(LinePageId, LineMethod, 1)
    end;

    [Scope('OnPrem')]
    procedure RegistratePostUpdate(LinePageId: Integer; LineMethod: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord)
    begin
        Registrate(LinePageId, LineMethod, 2)
    end;

    [Scope('OnPrem')]
    procedure EnumeratorReset()
    begin
        TempUpdateParentRegisterLine.Reset();
        TempUpdateParentRegisterLine.FindSet();
        CurrentLineNo := 0;
        CurrEnumeratorDone := false;
    end;

    [Scope('OnPrem')]
    procedure ExpectedLine(LinePageId: Integer; LineMethod: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord; LineOperation: Option Visit,PreUpdate,PostUpdate)
    begin
        CurrentLineNo := CurrentLineNo + 1;
        Assert.AreEqual(LinePageId, TempUpdateParentRegisterLine."Page Id", Format(CurrentLineNo) + ': The page Id is not correct');
        Assert.AreEqual(LineMethod, TempUpdateParentRegisterLine.Method, Format(CurrentLineNo) + ': The method is not correct');
        Assert.AreEqual(LineOperation, TempUpdateParentRegisterLine.Operation, Format(CurrentLineNo) + ': The operation is not correct');
        CurrEnumeratorDone := TempUpdateParentRegisterLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure EnumeratorDone(): Boolean
    begin
        exit(CurrEnumeratorDone);
    end;

    [Scope('OnPrem')]
    procedure EnumeratorCount(): Integer
    begin
        exit(TempUpdateParentRegisterLine.Count);
    end;
}

