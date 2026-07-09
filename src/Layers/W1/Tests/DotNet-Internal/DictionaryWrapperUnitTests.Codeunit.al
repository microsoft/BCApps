codeunit 132597 "Dictionary Wrapper Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [Dictionary]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryCount()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
    begin
        // [SCENARIO] DictionaryWrapper.Count returns correct value

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.Count
        // [THEN] The function gives us the correct result
        Assert.AreEqual(3, DictionaryWrapper.Count(), 'Count returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryClear()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
    begin
        // [SCENARIO] DictionaryWrapper.Clear clears the dictionary

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.Clear
        DictionaryWrapper.Clear();

        // [THEN] The function clears the dictionary
        Assert.AreEqual(0, DictionaryWrapper.Count(), 'Count returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionarySetExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.Set(Key,Value) changes value for existing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We change a value
        DictionaryWrapper.Set(1, 'ONE');

        // [THEN] The function works correctly for existing key
        Assert.AreEqual(3, DictionaryWrapper.Count(), 'Count returns wrong result');
        Assert.AreEqual(true, DictionaryWrapper.ContainsKey(1), 'ContainsKey returns wrong result');
        Assert.AreEqual(true, DictionaryWrapper.TryGetValue(1, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual('ONE', Value, 'TryGetValue returns wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionarySetMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.Set(Key,Value) adds value for missing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We add a new item
        DictionaryWrapper.Set(4, 'four');

        // [THEN] The function works correctly for missing key
        Assert.AreEqual(4, DictionaryWrapper.Count(), 'Count is wrong');
        Assert.AreEqual(true, DictionaryWrapper.ContainsKey(4), 'ContainsKey returns wrong result');
        Assert.AreEqual(true, DictionaryWrapper.TryGetValue(4, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual('four', Value, 'TryGetValue returns wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryContainsKeyExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
    begin
        // [SCENARIO] DictionaryWrapper.ContainsKey(Key) returns true for existing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.ContainsKey
        // [THEN] The function works correctly for existing key
        Assert.AreEqual(true, DictionaryWrapper.ContainsKey(1), 'ContainsKey returns wrong result');
        Assert.AreEqual(true, DictionaryWrapper.ContainsKey(2), 'ContainsKey returns wrong result');
        Assert.AreEqual(true, DictionaryWrapper.ContainsKey(3), 'ContainsKey returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryContainsKeyMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
    begin
        // [SCENARIO] DictionaryWrapper.ContainsKey(Key) returns false for missing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.ContainsKey
        // [THEN] The function works correctly for missing key
        Assert.AreEqual(false, DictionaryWrapper.ContainsKey(4), 'ContainsKey returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetValueExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetValue(Key,Value) returns correct value for existing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetValue
        // [THEN] The function works correctly for existing key
        Assert.AreEqual(true, DictionaryWrapper.TryGetValue(1, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual('one', Value, 'TryGetValue returns wrong value');
        Assert.AreEqual(true, DictionaryWrapper.TryGetValue(2, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual('two', Value, 'TryGetValue returns wrong value');
        Assert.AreEqual(true, DictionaryWrapper.TryGetValue(3, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual('three', Value, 'TryGetValue returns wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetValueMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetValue(Key,Value) does not return value for missing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetValue
        // [THEN] The function works correctly for missing key
        Assert.AreEqual(false, DictionaryWrapper.TryGetValue(4, Value), 'TryGetValue returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetKeyExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        "Key": Variant;
        I: Integer;
        "Count": Integer;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetKey(Index,Key) returns correct key for existing index

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetKey
        // [THEN] The function works correctly for existing index
        Count := DictionaryWrapper.Count();
        for I := 1 to Count do begin
            Assert.AreEqual(true, DictionaryWrapper.TryGetKey(I - 1, Key), 'TryGetKey returns wrong result');
            Assert.AreEqual(I, Key, 'TryGetKey returns wrong key');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetKeyMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        "Key": Variant;
        "Count": Integer;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetKey(Index,Key) returns key for missing index

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetKey
        // [THEN] The function works correctly for missing index
        Count := DictionaryWrapper.Count();
        Assert.AreEqual(false, DictionaryWrapper.TryGetKey(Count, Key), 'TryGetKey returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetKeyValueExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        "Key": Variant;
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetKeyValue(Index,Key,Value) returns correct value for existing index

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetKeyValue
        // [THEN] The function works correctly for existing index
        Assert.AreEqual(true, DictionaryWrapper.TryGetKeyValue(0, Key, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual(1, Key, 'TryGetKeyValue returns wrong key');
        Assert.AreEqual('one', Value, 'TryGetKeyValue returns wrong value');
        Assert.AreEqual(true, DictionaryWrapper.TryGetKeyValue(1, Key, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual(2, Key, 'TryGetKeyValue returns wrong key');
        Assert.AreEqual('two', Value, 'TryGetKeyValue returns wrong value');
        Assert.AreEqual(true, DictionaryWrapper.TryGetKeyValue(2, Key, Value), 'TryGetValue returns wrong result');
        Assert.AreEqual(3, Key, 'TryGetKeyValue returns wrong key');
        Assert.AreEqual('three', Value, 'TryGetKeyValue returns wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryTryGetKeyValueMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        "Key": Variant;
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.TryGetKeyValue(Index,Key,Value) does not return value for missing index

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test DictionaryWrapper.TryGetKeyValue
        // [THEN] The function works correctly for missing index
        Assert.AreEqual(false, DictionaryWrapper.TryGetKeyValue(-1, Key, Value), 'TryGetKeyValue returns wrong result');
        Assert.AreEqual(false, DictionaryWrapper.TryGetKeyValue(3, Key, Value), 'TryGetKeyValue returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryRemoveExisting()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
        Value: Variant;
    begin
        // [SCENARIO] DictionaryWrapper.Remove(Key) removes value for existing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test them
        // [THEN] The function works correctly for existing key
        DictionaryWrapper.Remove(1);

        Assert.AreEqual(2, DictionaryWrapper.Count(), 'Count returns wrong result');
        Assert.AreEqual(false, DictionaryWrapper.ContainsKey(1), 'ContainsKey returns wrong result');
        Assert.AreEqual(false, DictionaryWrapper.TryGetValue(1, Value), 'ContainsKey returns wrong result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDictionaryRemoveMissing()
    var
        DictionaryWrapper: Codeunit "Dictionary Wrapper";
    begin
        // [SCENARIO] DictionaryWrapper.Remove(Key) does nothing for missing key

        // [GIVEN] DictionaryWrapper
        Initilize(DictionaryWrapper);

        // [WHEN] We test them
        // [THEN] The function works correctly for missing key
        DictionaryWrapper.Remove(4);

        Assert.AreEqual(3, DictionaryWrapper.Count(), 'Count returns wrong result');
    end;

    local procedure Initilize(var DictionaryWrapper: Codeunit "Dictionary Wrapper")
    begin
        DictionaryWrapper.Set(1, 'one');
        DictionaryWrapper.Set(2, 'two');
        DictionaryWrapper.Set(3, 'three');
    end;
}

