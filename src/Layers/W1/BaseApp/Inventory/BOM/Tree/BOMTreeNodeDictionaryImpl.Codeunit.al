// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

codeunit 3676 "BOM Tree Node Dictionary Impl."
{
    Access = Internal;

    var
        FirstBucket: Codeunit "BOM Tree Nodes Bucket";
        EmptyValuesIndices: List of [Integer];
        LastIndex: Integer;
        KeyIndexMap: Dictionary of [Text, Integer];
        Initialized: Boolean;
        EnumeratorIndex: Integer;
        EnumerationInProgress: Boolean;
        NotFoundErr: Label 'The element with unique key %1 was not found.', Comment = '%1 is the unique identifying text for an instance.';
        KeyAlreadyExistsErr: Label 'Cannot add instance as another with key %1 has already been added.', Comment = '%1 is the unique identifying text for an instance.';
        EnumerationInProgressErr: Label 'The collection cannot be modified as an enumeration is in progress. Please call ResetEnumerator() before modifying.';
        BucketOutOfRangeErr: Label 'Bucket Id %1 is out of range.', Comment = '%1 is the index of bucket';

    local procedure Init()
    begin
        if Initialized then
            exit;
        LastIndex := 0;
        Initialized := true;
        FirstBucket.Init();
    end;

    procedure Get(InstanceKey: Text; var Found: Codeunit "BOM Tree Node")
    var
        FoundAtIndex: Integer;
    begin
        FoundAtIndex := IndexOf(InstanceKey);
        if FoundAtIndex = 0 then
            Error(NotFoundErr, InstanceKey);

        Get(FoundAtIndex, Found);
    end;

    procedure Add(Instance: Codeunit "BOM Tree Node") AtIndex: Integer
    var
        InstanceKey: Text;
    begin
        Init();

        if EnumerationInProgress then
            Error(EnumerationInProgressErr);

        // check instance with same key already exists
        InstanceKey := Instance.GetKey();
        if KeyIndexMap.ContainsKey(InstanceKey) then
            Error(KeyAlreadyExistsErr, InstanceKey);

        // try to add the instance to an index pointing to a gap
        if EmptyValuesIndices.Count() > 0 then begin
            AtIndex := EmptyValuesIndices.Get(1); // first element
            Set(AtIndex, Instance);
            KeyIndexMap.Add(InstanceKey, AtIndex);

            EmptyValuesIndices.RemoveAt(1);
            exit;
        end;

        // add to the end
        LastIndex += 1;
        AtIndex := LastIndex;
        Set(LastIndex, Instance);
        KeyIndexMap.Add(InstanceKey, AtIndex);
    end;

    procedure Remove(InstanceKey: Text)
    var
        FoundAtIndex: Integer;
    begin
        if EnumerationInProgress then
            Error(EnumerationInProgressErr);

        FoundAtIndex := IndexOf(InstanceKey);
        if FoundAtIndex = 0 then
            Error(NotFoundErr, InstanceKey);

        KeyIndexMap.Remove(InstanceKey);
        EmptyValuesIndices.Add(FoundAtIndex);
    end;

    procedure ResetEnumerator()
    begin
        EnumeratorIndex := 0;
        EnumerationInProgress := false;
    end;

    procedure MoveNext(): Boolean
    begin
        EnumerationInProgress := true;
        EnumeratorIndex += 1;

        while EnumeratorIndex <= LastIndex do begin
            if not EmptyValuesIndices.Contains(EnumeratorIndex) then
                exit(true);
            EnumeratorIndex += 1;
        end;

        // cannot move further
        exit(false);
    end;

    procedure GetCurrent(var Instance: Codeunit "BOM Tree Node")
    begin
        Get(EnumeratorIndex, Instance);
    end;

    procedure Count(): Integer
    begin
        exit(LastIndex - EmptyValuesIndices.Count());
    end;

    local procedure GetBucketId(FromIndex: Integer) RequiredBucketId: Integer
    var
        Bucket: Codeunit "BOM Tree Nodes Bucket";
        BucketSize: Integer;
    begin
        BucketSize := Bucket.SizeOfBucket();
        RequiredBucketId := Round((FromIndex - 1) / BucketSize, 1, '<');
    end;

    local procedure GetBucket(RequestedBucketId: Integer; var Bucket: Codeunit "BOM Tree Nodes Bucket"; CreateBuckets: Boolean)
    var
        CurrentBucket: Codeunit "BOM Tree Nodes Bucket";
    begin
        Bucket := FirstBucket;
        CurrentBucket := Bucket;
        while CurrentBucket.GetBucketId() < RequestedBucketId do begin
            CurrentBucket.GetNextBucket(Bucket);
            if not Bucket.IsInitialized() then
                if CreateBuckets then begin
                    Bucket.Init(CurrentBucket);
                    CurrentBucket.SetNextBucket(Bucket);
                end else
                    Error(BucketOutOfRangeErr, RequestedBucketId);
            CurrentBucket := Bucket;
        end;
    end;

    local procedure Get(AtIndex: Integer; var Instance: Codeunit "BOM Tree Node")
    var
        Bucket: Codeunit "BOM Tree Nodes Bucket";
        RequiredBucketId: Integer;
        LocalIndex: Integer;
    begin
        RequiredBucketId := GetBucketId(AtIndex);
        GetBucket(RequiredBucketId, Bucket, false);
        LocalIndex := AtIndex - (Bucket.SizeOfBucket() * RequiredBucketId);
        Bucket.GetValue(LocalIndex, Instance);
    end;

    local procedure Set(AtIndex: Integer; Instance: Codeunit "BOM Tree Node")
    var
        Bucket: Codeunit "BOM Tree Nodes Bucket";
        RequiredBucketId: Integer;
        LocalIndex: Integer;
    begin
        RequiredBucketId := GetBucketId(AtIndex);
        GetBucket(RequiredBucketId, Bucket, true);
        LocalIndex := AtIndex - (Bucket.SizeOfBucket() * RequiredBucketId);
        Bucket.SetValue(LocalIndex, Instance);
    end;

    local procedure IndexOf(UniqueKey: Text): Integer
    begin
        if LastIndex = 0 then
            exit(0);

        if not KeyIndexMap.ContainsKey(UniqueKey) then
            exit(0);

        exit(KeyIndexMap.Get(UniqueKey));
    end;
}