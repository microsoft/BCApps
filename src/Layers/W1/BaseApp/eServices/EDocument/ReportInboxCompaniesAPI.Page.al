// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;

page 694 "Report Inbox Companies API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'reportInbox';
    APIVersion = 'v1.0';
    EntityName = 'reportInboxCompany';
    EntitySetName = 'reportInboxCompanies';
    EntityCaption = 'Report Inbox Company';
    EntitySetCaption = 'Report Inbox Companies';
    SourceTable = "Report Inbox Company Buffer";
    ODataKeyFields = Id;
    DataAccessIntent = ReadOnly;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.Id) { }
                field(companyName; Rec."Company Name") { }
                field(companyNameLower; Rec."Company Name Lower") { }
                field(entryCount; Rec."Entry Count") { }
                field(unreadCount; Rec."Unread Count") { }
                field(lastModifiedDateTime; Rec."Last Modified Date-Time") { }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CompanyRec: Record Company;
        View: Text;
    begin
        if Initialized then
            exit(Rec.Find(Which));

        View := Rec.GetView();
        Rec.Reset();

        CompanyRec.SetLoadFields(Name);
        if CompanyRec.FindSet() then
            repeat
                AddCompany(CompanyRec.Name, CompanyRec.SystemId);
            until CompanyRec.Next() = 0;

        Rec.SetView(View);
        Initialized := true;
        exit(Rec.Find(Which));
    end;

    var
        Initialized: Boolean;

    local procedure AddCompany(CompanyNameToRead: Text[30]; CompanyId: Guid)
    var
        ReportInbox: Record "Report Inbox";
    begin
        if not ReportInbox.ChangeCompany(CompanyNameToRead) then
            exit;
        if not ReportInbox.ReadPermission then
            exit;

        ReportInbox.ReadIsolation := IsolationLevel::ReadCommitted;
        ReportInbox.SetCurrentKey("User ID", "Created Date-Time");
        ReportInbox.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID")));
        ReportInbox.SetLoadFields(Read);
        if not ReportInbox.FindSet() then
            exit;

        Rec.Init();
        Rec."Company Name" := CompanyNameToRead;
        Rec."Company Name Lower" := CompanyNameToRead.ToLower();
        Rec.Id := CompanyId;

        repeat
            Rec."Entry Count" += 1;
            if not ReportInbox.Read then
                Rec."Unread Count" += 1;
            if ReportInbox.SystemModifiedAt > Rec."Last Modified Date-Time" then
                Rec."Last Modified Date-Time" := ReportInbox.SystemModifiedAt;
        until ReportInbox.Next() = 0;

        Rec.Insert();
    end;
}
