codeunit 135250 "Isolated Storage Mgt. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Isolated Storage] [Read Isolation]
    end;

    var
        Assert: Codeunit Assert;
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ValueMismatchErr: Label 'The retrieved value does not match the stored value.';
        GetShouldSucceedErr: Label 'Get should have returned true for an existing key.';
        GetShouldFailErr: Label 'Get should have returned false for a missing key.';

    [Test]
    [Scope('OnPrem')]
    procedure GetTextForEachIsolationLevelReturnsStoredValue()
    begin
        // [SCENARIO] The IsolationLevel Get overload returns the stored Text value for every supported isolation level.
        VerifyTextRoundTrip(IsolationLevel::Default);
        VerifyTextRoundTrip(IsolationLevel::ReadUncommitted);
        VerifyTextRoundTrip(IsolationLevel::ReadCommitted);
        VerifyTextRoundTrip(IsolationLevel::UpdLock);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetTextWithIsolationLevelMissingKeyReturnsFalse()
    var
        MissingKey: Text;
        RetrievedValue: Text;
    begin
        // [SCENARIO] The IsolationLevel Get overload returns false and clears the value when the key does not exist.
        // [GIVEN] A key that is not present in Isolated Storage.
        MissingKey := Format(CreateGuid());

        // [WHEN] Getting the value with an explicit IsolationLevel.
        // [THEN] Get returns false and the value is empty.
        Assert.IsFalse(IsolatedStorageManagement.Get(MissingKey, DataScope::Company, IsolationLevel::ReadCommitted, RetrievedValue), GetShouldFailErr);
        Assert.AreEqual('', RetrievedValue, ValueMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSecretTextWithIsolationLevelReturnsStoredValue()
    var
        StorageKey: Text;
        StoredValue: Text;
        RetrievedValue: SecretText;
    begin
        // [SCENARIO] The IsolationLevel SecretText Get overload returns the stored value.
        // [GIVEN] A value stored in Isolated Storage.
        StorageKey := Format(CreateGuid());
        StoredValue := Format(CreateGuid());
        Assert.IsTrue(IsolatedStorageManagement.Set(StorageKey, StoredValue, DataScope::Company), 'Set should succeed.');

        // [WHEN] Getting the value as SecretText with an explicit IsolationLevel.
        // [THEN] Get returns true and the unwrapped value round-trips.
        Assert.IsTrue(IsolatedStorageManagement.Get(StorageKey, DataScope::Company, IsolationLevel::UpdLock, RetrievedValue), GetShouldSucceedErr);
        Assert.AreEqual(StoredValue, UnwrapSecretText(RetrievedValue), ValueMismatchErr);

        IsolatedStorageManagement.Delete(StorageKey, DataScope::Company);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSecretTextWithIsolationLevelMissingKeyReturnsFalse()
    var
        MissingKey: Text;
        RetrievedValue: SecretText;
    begin
        // [SCENARIO] The IsolationLevel SecretText Get overload returns false when the key does not exist.
        // [GIVEN] A key that is not present in Isolated Storage.
        MissingKey := Format(CreateGuid());

        // [WHEN] Getting the value as SecretText with an explicit IsolationLevel.
        // [THEN] Get returns false and the value is empty.
        Assert.IsFalse(IsolatedStorageManagement.Get(MissingKey, DataScope::Company, IsolationLevel::ReadUncommitted, RetrievedValue), GetShouldFailErr);
        Assert.AreEqual('', UnwrapSecretText(RetrievedValue), ValueMismatchErr);
    end;

    local procedure VerifyTextRoundTrip(TheIsolationLevel: IsolationLevel)
    var
        StorageKey: Text;
        StoredValue: Text;
        RetrievedValue: Text;
    begin
        StorageKey := Format(CreateGuid());
        StoredValue := Format(CreateGuid());

        Assert.IsTrue(IsolatedStorageManagement.Set(StorageKey, StoredValue, DataScope::Company), 'Set should succeed.');
        Assert.IsTrue(IsolatedStorageManagement.Get(StorageKey, DataScope::Company, TheIsolationLevel, RetrievedValue), GetShouldSucceedErr);
        Assert.AreEqual(StoredValue, RetrievedValue, ValueMismatchErr);

        IsolatedStorageManagement.Delete(StorageKey, DataScope::Company);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure UnwrapSecretText(SecretTextToUnwrap: SecretText): Text
    begin
        exit(SecretTextToUnwrap.Unwrap());
    end;
}
