// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

codeunit 3677 "BOM Tree Nodes Bucket"
{
    Access = Internal;

    var
        NextBucket: Codeunit "BOM Tree Nodes Bucket";
        Instances: array[100] of Codeunit "BOM Tree Node";
        BucketId: Integer;
        Initialized: Boolean;

    procedure SizeOfBucket(): Integer
    begin
        exit(ArrayLen(Instances));
    end;

    procedure Init()
    begin
        BucketId := 0;
        Initialized := true;
    end;

    procedure Init(PreviousBucket: Codeunit "BOM Tree Nodes Bucket")
    begin
        BucketId := PreviousBucket.GetBucketId() + 1;
        Initialized := true;
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure SetNextBucket(NewNextBucket: Codeunit "BOM Tree Nodes Bucket")
    begin
        NextBucket := NewNextBucket;
    end;

    procedure GetBucketId(): Integer
    begin
        exit(BucketId);
    end;

    procedure GetNextBucket(var NextBucketResult: Codeunit "BOM Tree Nodes Bucket")
    begin
        Clear(NextBucketResult);
        NextBucketResult := NextBucket;
    end;

    procedure GetValue(AtIndex: Integer; var Instance: Codeunit "BOM Tree Node")
    begin
        Instance := Instances[AtIndex];
    end;

    procedure SetValue(AtIndex: Integer; Instance: Codeunit "BOM Tree Node")
    begin
        Instances[AtIndex] := Instance;
    end;
}