codeunit 130001 "Delta Assert"
{
    // Created by: simej
    // 
    // Delta Assertion code unit.


    trigger OnRun()
    begin
        Initialized := false;
        Tolerance := 0.0;
    end;

    var
        Watches: Record "Delta watch";
        LibAssert: Codeunit Assert;
        Initialized: Boolean;
        Tolerance: Decimal;

    local procedure GetValue(Watch: Record "Delta watch"): Decimal
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Computes the current value of the surveyed field
        RecRef.Open(Watch.TableNo, false, CompanyName);
        RecRef.SetPosition(Watch.PositionNo);
        FieldRef := RecRef.Field(Watch.FieldNo);

        if FieldRef.Class = FieldClass::FlowField then
            FieldRef.CalcField();

        exit(FieldRef.Value);
    end;

    [Scope('OnPrem')]
    procedure GetTableName(Watch: Record "Delta watch"): Text[30]
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Watch.TableNo, false, CompanyName);
        exit(RecRef.Name);
    end;

    [Scope('OnPrem')]
    procedure Init()
    begin
        LibAssert.IsFalse(Initialized, 'Delta Assert library already initialized.');

        // Initializes the delta assertion by setting table, view and field information
        Initialized := true;
        ClearWatches();
    end;

    [Scope('OnPrem')]
    procedure Reset()
    begin
        Initialized := false;
    end;

    [Scope('OnPrem')]
    procedure ClearWatches()
    begin
        Watches.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure AddWatch("Table": Integer; Position: Text[250]; "Field": Integer; Delta: Decimal)
    begin
        LibAssert.IsTrue(Initialized, 'Delta Assert library not initialized correctly.');
        if Watches.FindLast() then
            Watches."No." := Watches."No." + 1;

        Watches.Init();
        Watches.Insert(true);
        Watches.Validate(TableNo, Table);
        Watches.Validate(FieldNo, Field);
        Watches.Validate(PositionNo, Position);
        Watches.Validate(Delta, Delta);
        Watches.Modify(true);

        Update(Watches);
    end;

    [Scope('OnPrem')]
    procedure SetTolerance(Tol: Decimal)
    begin
        Tolerance := Tol;
    end;

    local procedure Update(var Watch: Record "Delta watch")
    begin
        // Update the base for comparison to the current value
        Watch.OriginalValue := GetValue(Watch);
        Watch.Modify(true);
    end;

    local procedure AssertWatch(Watch: Record "Delta watch")
    begin
        LibAssert.AreNearlyEqual(Watch.OriginalValue + Watch.Delta, GetValue(Watch), Tolerance,
              StrSubstNo('Delta Assertion <Table: %1, Key: %2, Delta: %3>', GetTableName(Watch), Watch.PositionNo, Watch.Delta));
    end;

    [Scope('OnPrem')]
    procedure Assert()
    begin
        // Checks the delta assertion holds
        LibAssert.IsTrue(Initialized, 'Delta Assert library not initialized correctly.');
        LibAssert.IsFalse(Watches.IsEmpty, 'No watches added.');

        // Check all watches
        Watches.Reset();
        Watches.FindSet();
        repeat
            AssertWatch(Watches);
        until Watches.Next() = 0;

        // Go back to uninitialized state so the class can be reused
        Initialized := false;
    end;
}

