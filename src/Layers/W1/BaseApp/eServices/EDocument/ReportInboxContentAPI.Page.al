// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 691 "Report Inbox Content API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'reportInbox';
    APIVersion = 'v1.0';
    EntityName = 'reportInboxContent';
    EntitySetName = 'reportInboxContents';
    EntityCaption = 'Report Inbox Content';
    EntitySetCaption = 'Report Inbox Contents';
    SourceTable = "Report Inbox";
    ODataKeyFields = SystemId;
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
                field(id; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(fileName; FileNameTxt)
                {
                    Caption = 'File Name';
                }
                field(outputType; Rec."Output Type") { }
                field(byteSize; ByteSizeInt)
                {
                    Caption = 'Byte Size';
                }
                field(documentContent; Rec."Report Output")
                {
                    Caption = 'Content';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ReadIsolation := IsolationLevel::ReadCommitted;
        Rec.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(Rec."User ID")));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.GetFilter(SystemId) = '' then
            Error(KeyRequiredErr);
        if Rec.Count() > 1 then
            Error(KeyRequiredErr);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Report Output", "Report Name");
        FileNameTxt := Rec.GetFileNameWithExtension();
        ByteSizeInt := Rec."Report Output".Length();
    end;

    var
        FileNameTxt: Text;
        ByteSizeInt: Integer;
        KeyRequiredErr: Label 'Specify a single report inbox entry by its id, for example reportInboxContents(<id>). This endpoint cannot be listed as a collection; use the reportInboxItems endpoint to discover an id.';
}
