// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.Utilities;

page 4408 "SOA Create Task Attachments"
{
    PageType = ListPart;
    ApplicationArea = All;
    Caption = 'Attachments';
    SourceTable = "Agent Task File";
    InsertAllowed = false;
    DeleteAllowed = false;
    ShowFilter = false;
    SourceTableTemporary = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Attachments)
            {
                field(FileName; Rec."File Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'File name';
                    ToolTip = 'Specifies the name of the attachment.';

                    trigger OnDrillDown()
                    begin
                        ShowOrDownloadAttachment();
                    end;
                }
                field(MimeType; Rec."File MIME Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'MIME type';
                    ToolTip = 'Specifies the MIME type of the attachment.';
                }
                field(FileSize; AttachmentFileSize)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Width = 10;
                    Caption = 'File size';
                    ToolTip = 'Specifies the size of the attachment.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Add)
            {
                ApplicationArea = All;
                Caption = 'Add';
                ToolTip = 'Add a new attachment.';
                Image = Import;

                trigger OnAction()
                var
                    TempLastAgentTaskFile: Record "Agent Task File" temporary;
                begin
                    TempLastAgentTaskFile.Copy(Rec, true);
                    TempLastAgentTaskFile.Reset();
                    TempLastAgentTaskFile.SetCurrentKey(ID);
                    if TempLastAgentTaskFile.FindLast() then;

                    if not AgentTaskMessageBuilder.UploadAttachment() then
                        exit;

                    Rec := AgentTaskMessageBuilder.GetLastAttachment();
                    Rec.ID := TempLastAgentTaskFile.ID + 1;
                    Rec.Insert();
                end;
            }
            action(Remove)
            {
                ApplicationArea = All;
                Caption = 'Remove';
                ToolTip = 'Removes the attachment.';
                Image = Delete;

                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AgentMessage: Codeunit "Agent Message";
    begin
        AttachmentFileSize := AgentMessage.GetFileSizeDisplayText(Rec.Content.Length());
    end;

    internal procedure GetUploadedFiles(var TempAgentTaskFile: Record "Agent Task File" temporary): Boolean
    begin
        Rec.Reset();
        Rec.SetAutoCalcFields(Content);
        if not Rec.FindSet() then
            exit(false);

        repeat
            TempAgentTaskFile.Copy(Rec);
            TempAgentTaskFile.Insert();
        until Rec.Next() = 0;

        exit(true);
    end;

    internal procedure ClearAttachments()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;

    internal procedure AddSampleAttachment(NewFileName: Text; NewMimeType: Text; var TempBlob: Codeunit "Temp Blob")
    var
        TempLastAgentTaskFile: Record "Agent Task File" temporary;
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempLastAgentTaskFile.Reset();
        TempLastAgentTaskFile.SetCurrentKey(ID);
        if TempLastAgentTaskFile.FindLast() then;

        Clear(Rec);
        Rec.ID := TempLastAgentTaskFile.ID + 1;
        Rec."File Name" := CopyStr(NewFileName, 1, MaxStrLen(Rec."File Name"));
        Rec."File MIME Type" := CopyStr(NewMimeType, 1, MaxStrLen(Rec."File MIME Type"));
        TempBlob.CreateInStream(InStream);
        Rec.Content.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        Rec.Insert();
        CurrPage.Update(false);
    end;

    local procedure ShowOrDownloadAttachment()
    var
        AgentMessage: Codeunit "Agent Message";
    begin
        AgentMessage.ShowAttachment(Rec);
    end;

    var
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AttachmentFileSize: Text;
}