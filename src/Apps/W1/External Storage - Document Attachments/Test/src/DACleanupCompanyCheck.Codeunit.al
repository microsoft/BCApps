// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Foundation.Attachment;
using System.Environment;
using System.TestLibraries.Utilities;

codeunit 136823 "DA Cleanup Company Check"
{
    TableNo = "Document Attachment";
    Permissions = tabledata "Document Attachment" = ri,
                  tabledata "Tenant Media" = r,
                  tabledata Company = r,
                  tabledata "DA Internal Cleanup Entry" = r;

    trigger OnRun()
    var
        TestCompany: Record Company;
        OtherAttachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        TenantMedia: Record "Tenant Media";
        Worker: Codeunit "DA Internal Cleanup Worker";
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        MediaId: Guid;
        OwnerSystemId: Guid;
    begin
        Assert.AreEqual(CompanyName(), Rec.CurrentCompany(), 'Cleanup must run against the source company, not redirect to the fixture company');
        Assert.AreNotEqual(CompanyName(), TestCompanyName, 'The fixture must be a different company');
        TestCompany.Get(TestCompanyName);
        Assert.AreEqual(TestCompanyId, TestCompany.SystemId, 'The fixture company must still be the one created by this test');
        MediaId := Rec."Document Reference ID".MediaId();
        Assert.IsTrue(TenantMedia.Get(MediaId), 'Source media must exist before the ownership fixture is created');
        TenantMedia.CalcFields(Content);
        Assert.IsTrue(TenantMedia.Content.HasValue(), 'Source media must be nonempty before cleanup');

        OtherAttachment.ChangeCompany(TestCompanyName);
        OtherAttachment.TransferFields(Rec);
        OtherAttachment.ID := Any.IntegerInRange(100000, 999999);
        OtherAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(OtherAttachment."No."));
        OtherAttachment.Insert(false);
        OwnerSystemId := OtherAttachment.SystemId;
        Commit();
        OtherAttachment.GetBySystemId(OwnerSystemId);
        Assert.AreEqual(MediaId, OtherAttachment."Document Reference ID".MediaId(), 'The committed other-company attachment must reference the same media');

        Worker.ProcessPending();
        Commit();
        Entry.Get(Rec.SystemId);
        Assert.AreEqual(Entry.Status::Blocked, Entry.Status, 'The cross-company check must exercise the blocked release gate');
        Assert.AreEqual('InternalReleaseUnsupported', Entry.Outcome, 'Successful validation must not claim that media was released');
        Rec.GetBySystemId(Rec.SystemId);
        Assert.AreEqual(MediaId, Rec."Document Reference ID".MediaId(), 'The source-company attachment must retain its reference');
        Assert.IsTrue(Rec."Stored Internally", 'The source company must retain internal storage');
        OtherAttachment.GetBySystemId(OwnerSystemId);
        Assert.AreEqual(MediaId, OtherAttachment."Document Reference ID".MediaId(), 'Cleanup must preserve the other-company media reference');
        Assert.IsTrue(TenantMedia.Get(MediaId), 'Another company must retain the physical media after blocked cleanup');
        TenantMedia.CalcFields(Content);
        Assert.IsTrue(TenantMedia.Content.HasValue(), 'Another company must retain actual nonempty content after blocked cleanup');
    end;

    procedure SetTestCompany(Name: Text[30]; SystemId: Guid)
    begin
        TestCompanyName := Name;
        TestCompanyId := SystemId;
    end;

    var
        TestCompanyName: Text[30];
        TestCompanyId: Guid;
}
