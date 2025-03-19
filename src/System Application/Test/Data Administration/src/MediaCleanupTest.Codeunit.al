// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.DataAdministration;

using System.DataAdministration;
using System.Environment;
using System.Utilities;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 135018 "Media Cleanup Test"
{
    Subtype = Test;
    Permissions = tabledata "Tenant Media" = r,
                  tabledata "Tenant Media Set" = r;

    var
        LibraryAssert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        MediaCleanupImpl: Codeunit "Media Cleanup Impl.";
        Any: Codeunit Any;

    [Test]
    procedure EnsureNoDetachedMediaByDefault()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
    begin
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Tenant media contains unreferenced media by default.');
    end;

    [Test]
    procedure EnsureDetachedMediaIsDetected()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMedia(1000, 100 * 1024); // 1000 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(1000, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMedia(TempTenantMedia);
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureLargeDetachedMediaIsDetected()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMedia(10, 100 * 1024 * 1024); // 10 media of 100 MB
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(10, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMedia(TempTenantMedia);
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureManyDetachedMediaIsDetected()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMedia(10000, 100); // 10000 media of 100 bytes
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(10000, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMedia(TempTenantMedia);
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaThroughMediaSetIsDetected()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(1000, 100 * 1024); // 1000 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(1000, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMedia(TempTenantMedia);
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUp()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(100, 100 * 1024); // 100 media of 100 kb
        CreateDetachedMedia(100, 100 * 1024); // 100 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(200, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUpSingleFullSubListPortion()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(10, 100 * 1024); // 10 media of 100 kb
        CreateDetachedMedia(10, 100 * 1024); // 10 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(20, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUpNotDivisibleSubListBigger()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(101, 100 * 1024); // 101 media of 100 kb
        CreateDetachedMedia(101, 100 * 1024); // 101 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(202, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUpNotDivisibleSubListLess()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(99, 100 * 1024); // 99 media of 100 kb
        CreateDetachedMedia(99, 100 * 1024); // 99 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(198, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUpLessThanBatch()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(7, 100 * 1024); // 7 media of 100 kb
        CreateDetachedMedia(7, 100 * 1024); // 7 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(14, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreSuccessWithEmptyData()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureDetachedMediaAndMediaSetAreCleanedUpThroughCodeunit()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(100, 100 * 1024); // 100 media of 100 kb
        CreateDetachedMedia(100, 100 * 1024); // 100 media of 100 kb
        PermissionsMock.Set('Data Cleanup - Admin');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(200, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');

        Codeunit.Run(Codeunit::"Media Cleanup Runner");
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureViewPermissionsCannotCleanupMedia()
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        PermissionsMock.ClearAssignments();
        CreateDetachedMediaThroughMediaSet(100, 100 * 1024); // 100 media of 100 kb
        CreateDetachedMedia(100, 100 * 1024); // 100 media of 100 kb
        PermissionsMock.Set('Data Cleanup - View');
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(200, TempTenantMedia.Count(), 'Tenant media does not contain all detached media initially.');

        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(200, TempTenantMedia.Count(), 'Tenant media does not contain all detached media after view deletion attempt.');

        PermissionsMock.Set('Data Cleanup - Admin');
        MediaCleanup.DeleteDetachedTenantMediaSet();
        MediaCleanup.DeleteDetachedTenantMedia();
        GetDetachedTenantMedia(TempTenantMedia);
        LibraryAssert.AreEqual(0, TempTenantMedia.Count(), 'Tenant media does not contain all detached media.');
        LibraryAssert.IsTrue(TempTenantMedia.IsEmpty(), 'Detached Tenant media was not cleaned up properly.');
    end;

    [Test]
    procedure EnsureNormalMediaArePersisted()
    var
        TenantMedia: Record "Tenant Media";
        TenantMediaSetup: Record "Tenant Media Set";
        TestMediaClean: Record "Test Media Cleanup";
        TempBlob: Codeunit "Temp Blob";
        MediaOutStream: OutStream;
        i: Integer;
    begin
        PermissionsMock.Set('Data Cleanup - Admin');

        TestMediaClean.Insert();

        TempBlob.CreateOutStream(MediaOutStream);
        MediaOutStream.WriteText('123');
        TestMediaClean."Test Media".ImportStream(TempBlob.CreateInStream(), '');
        TestMediaClean.Modify();

        clear(TempBlob);
        TempBlob.CreateOutStream(MediaOutStream);
        for i := 0 to 99 do
            MediaOutStream.WriteText('123');
        TestMediaClean."Test Media Set".ImportStream(TempBlob.CreateInStream(), '');
        TestMediaClean.Modify();

        LibraryAssert.IsTrue(TestMediaClean."Test Media".HasValue(), 'Tenant Media is not correctly inserted.');
        LibraryAssert.IsTrue(TestMediaClean."Test Media Set".Count() > 0, 'Tenant Media Set is not correctly inserted.');
        LibraryAssert.IsFalse(TenantMedia.IsEmpty(), 'Tenant Media is not correctly inserted.');
        LibraryAssert.IsFalse(TenantMediaSetup.IsEmpty(), 'Tenant Media Set is not correctly inserted.');

        Codeunit.Run(Codeunit::"Media Cleanup Runner");

        LibraryAssert.IsFalse(TenantMedia.IsEmpty(), 'Normal tenant media is also affected.');
        LibraryAssert.IsFalse(TenantMediaSetup.IsEmpty(), 'Normal tenant media set is also affected.');
    end;

    [Test]
    procedure SplitListIntoSubLists322Into100CountSublists()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
        i: Integer;
    begin
        // Basic Test: 322 items with SubListCount = 100
        // Expected outcome: 4 sublists (100, 100, 100, and 22 items respectively)
        for i := 1 to 322 do
            InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 100, ResultSublists);

        // Verify the total number of sublists is 4
        LibraryAssert.AreEqual(4, ResultSublists.Count(), '322 items with batch size 100 should produce 4 sublists.');

        // Verify the size of each sublist
        LibraryAssert.AreEqual(100, ResultSublists.Get(1).Count(), 'First sublist should contain 100 items.');
        LibraryAssert.AreEqual(100, ResultSublists.Get(2).Count(), 'Second sublist should contain 100 items.');
        LibraryAssert.AreEqual(100, ResultSublists.Get(3).Count(), 'Third sublist should contain 100 items.');
        LibraryAssert.AreEqual(22, ResultSublists.Get(4).Count(), 'Fourth sublist (remainder) should contain 22 items.');
    end;

    [Test]
    procedure SplitListIntoSubLists350Into100CountSublists()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
        i: Integer;
    begin
        // Basic Test: 350 items with SubListCount = 100
        // Expected outcome: 4 sublists (100, 100, 100, and 50 items respectively)
        for i := 1 to 350 do
            InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 100, ResultSublists);

        // Verify the total number of sublists is 4
        LibraryAssert.AreEqual(4, ResultSublists.Count(), '350 items with batch size 100 should produce 4 sublists.');

        // Verify the size of each sublist
        LibraryAssert.AreEqual(100, ResultSublists.Get(1).Count(), 'First sublist should contain 100 items.');
        LibraryAssert.AreEqual(100, ResultSublists.Get(2).Count(), 'Second sublist should contain 100 items.');
        LibraryAssert.AreEqual(100, ResultSublists.Get(3).Count(), 'Third sublist should contain 100 items.');
        LibraryAssert.AreEqual(50, ResultSublists.Get(4).Count(), 'Fourth sublist (remainder) should contain 50 items.');
    end;

    [Test]
    procedure SplitListIntoSubListsReturnsEmptyResult()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
    begin
        // Edge Case: Empty input list, SubListCount = 100
        // Expected outcome: result is an empty list of sublists (no sublists)
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 100, ResultSublists);

        // Verify that result is empty (no sublists)
        LibraryAssert.AreEqual(0, ResultSublists.Count(), 'Empty input list should produce an empty result (0 sublists).');
    end;

    [Test]
    procedure SplitListIntoSubListsFewerItemsThanBatchReturnsSingleSublist()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
        i: Integer;
    begin
        // Edge Case: Input list has fewer items than SubListCount
        // Example: 50 items, SubListCount = 100
        // Expected outcome: a single sublist containing all 50 items (since no split needed)
        for i := 1 to 50 do
            InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 100, ResultSublists);

        // Verify that there is exactly 1 sublist
        LibraryAssert.AreEqual(1, ResultSublists.Count(), '50 items with batch size 100 should produce 1 sublist (all items in one batch).');

        // Verify that the single sublist contains all 50 items
        LibraryAssert.AreEqual(50, ResultSublists.Get(1).Count(), 'The single sublist should contain all 50 items.');
    end;

    [Test]
    procedure SplitListIntoSubListsCreatesIndividualItemSublists()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
        i: Integer;
        idx: Integer;
    begin
        // Edge Case: SubListCount = 1 (each item should be its own sublist)
        // Example: 5 items, SubListCount = 1 -> expect 5 sublists, each with 1 item
        for i := 1 to 5 do
            InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 1, ResultSublists);

        // Verify that the number of sublists equals the number of items (5 sublists for 5 items)
        LibraryAssert.AreEqual(5, ResultSublists.Count(), '5 items with batch size 1 should produce 5 sublists.');

        // Verify each sublist contains exactly one item
        for idx := 1 to ResultSublists.Count() do
            LibraryAssert.AreEqual(1, ResultSublists.Get(idx).Count(), 'Sublist should contain exactly 1 item.');
    end;

    [Test]
    procedure SplitListIntoSubListsReturnsSingleFullSublist()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
        i: Integer;
    begin
        // Edge Case: SubListCount equals the input list count
        // Example: 8 items, SubListCount = 8 -> expect a single sublist with all 8 items
        for i := 1 to 8 do
            InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 8, ResultSublists);

        // Verify that there is exactly 1 sublist
        LibraryAssert.AreEqual(1, ResultSublists.Count(), '8 items with batch size 8 should produce 1 sublist.');

        // Verify that the single sublist contains all 8 items
        LibraryAssert.AreEqual(8, ResultSublists.Get(1).Count(), 'The single sublist should contain all 8 items.');
    end;

    [Test]
    procedure SplitListIntoSubListsOneItemBatchOfOne()
    var
        InputList: List of [Guid];
        ResultSublists: List of [List of [Guid]];
    begin
        // Boundary Case: Minimum input values (1 item, SubListCount = 1)
        // Expected outcome: 1 sublist containing the single item
        InputList.Add(Any.GuidValue());
        MediaCleanupImpl.SplitListIntoSubLists(InputList, 1, ResultSublists);

        // Verify one sublist is created
        LibraryAssert.AreEqual(1, ResultSublists.Count(), '1 item with batch size 1 should result in 1 sublist.');

        // Verify the sublist contains that one item
        LibraryAssert.AreEqual(1, ResultSublists.Get(1).Count(), 'The single sublist should contain the one item.');
    end;

    local procedure GetDetachedTenantMedia(var TempTenantMedia: Record "Tenant Media" temporary)
    var
        MediaCleanup: Codeunit "Media Cleanup";
    begin
        TempTenantMedia.Reset();
        TempTenantMedia.DeleteAll();
        MediaCleanup.GetDetachedTenantMedia(TempTenantMedia, false);
        MediaCleanup.GetTenantMediaFromDetachedMediaSet(TempTenantMedia, false);
    end;

    procedure CreateDetachedMedia(OrphanCount: Integer; Size: Integer)
    var
        TenantMedia: Record "Tenant Media";
        MediaOutStream: OutStream;
        OrphanNo: Integer;
        i: Integer;
    begin
        for OrphanNo := 1 to OrphanCount do begin
            TenantMedia.ID := Any.GuidValue();
            TenantMedia.Content.CreateOutStream(MediaOutStream);
            for i := 1 to Round(Size / 100, 1) do
                MediaOutStream.Write('1234567890qwertyuiopåasdfghjklæøzxcvbnm,.-¨''-.<>\½1234567890qwertyuiopåasdfghjklæøzxcvbnm,.-¨''-.<>\½');
            TenantMedia.Insert();
        end;
    end;

    procedure CreateDetachedMediaThroughMediaSet(OrphanCount: Integer; Size: Integer)
    var
        TenantMediaSet: Record "Tenant Media Set";
        TempBlob: Codeunit "Temp Blob";
        MediaOutStream: OutStream;
        OrphanNo: Integer;
        i: Integer;
    begin
        TenantMediaSet.ID := Any.GuidValue();
        for OrphanNo := 1 to OrphanCount do begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(MediaOutStream);
            for i := 1 to Size / 100 do
                MediaOutStream.Write('1234567890qwertyuiopåasdfghjklæøzxcvbnm,.-¨''-.<>\½1234567890qwertyuiopåasdfghjklæøzxcvbnm,.-¨''-.<>\½');

            TenantMediaSet."Media ID".ImportStream(TempBlob.CreateInStream(), '');
            TenantMediaSet.Insert();
        end;
    end;

}
