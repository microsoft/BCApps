// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Environment;

table 137 "Inc. Doc. Attachment Overview"
{
    Caption = 'Inc. Doc. Attachment Overview';
    TableType = Temporary;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            InitValue = 0;
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(4; "Created By User Name"; Code[50])
        {
            Caption = 'Created By User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; Name; Text[250])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = ' ,Image,PDF,Word,Excel,PowerPoint,Email,XML,Other';
            OptionMembers = " ",Image,PDF,Word,Excel,PowerPoint,Email,XML,Other;
        }
        field(7; "File Extension"; Text[30])
        {
            Caption = 'File Extension';
            Editable = false;
        }

        field(100; "Attachment Type"; Option)
        {
            Caption = 'Attachment Type';
            Editable = false;
            OptionCaption = ',Group,Main Attachment,OCR Result,Supporting Attachment,Link';
            OptionMembers = ,Group,"Main Attachment","OCR Result","Supporting Attachment",Link;
        }
        field(101; "Sorting Order"; Integer)
        {
            Caption = 'Sorting Order';
        }
        field(102; Indentation; Integer)
        {
            Caption = 'Indentation';
        }

        field(103; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }

        field(104; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Sorting Order", "Incoming Document Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Created Date-Time", Name, "File Extension")
        {
        }
    }

    trigger OnDelete()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if IncomingDocumentAttachment.Get("Incoming Document Entry No.", "Line No.") then
            IncomingDocumentAttachment.Delete(true);
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

        SupportingAttachmentsTxt: Label 'Supporting Attachments';
        NotAvailableAttachmentMsg: Label 'The attachment is no longer available.';

    internal procedure NameDrillDown()
    begin
        NameDrillDown(false)
    end;

    [Scope('OnPrem')]
    procedure NameDrillDown(DownloadFilePreset: Boolean)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNameDrillDown(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Attachment Type" of
            "Attachment Type"::Group:
                exit;
            "Attachment Type"::Link:
                begin
                    IncomingDocument.Get("Incoming Document Entry No.");
                    HyperLink(IncomingDocument.GetURL());
                end
            else
                if not IncomingDocumentAttachment.Get("Incoming Document Entry No.", "Line No.") then
                    Message(NotAvailableAttachmentMsg)
                else
                    if (Type = Type::Image) and (ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone) then
                        PAGE.Run(PAGE::"O365 Incoming Doc. Att. Pict.", IncomingDocumentAttachment)
                    else
                        if IncomingDocumentAttachment.SupportedByFileViewer() and not DownloadFilePreset then
                            ViewFile(IncomingDocumentAttachment, Name + '.' + "File Extension")
                        else
                            IncomingDocumentAttachment.Export(Name + '.' + "File Extension", true);
        end;
    end;

    local procedure ViewFile(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; FileName: Text)
    var
        FileInStream: InStream;
    begin
        IncomingDocumentAttachment.CalcFields(Content);
        IncomingDocumentAttachment.Content.CreateInStream(FileInStream);
        File.ViewFromStream(FileInStream, FileName, true);
    end;

    procedure GetStyleTxt(): Text
    begin
        case "Attachment Type" of
            "Attachment Type"::Group,
          "Attachment Type"::"Main Attachment",
          "Attachment Type"::Link:
                exit('Strong');
            else
                exit('Standard');
        end;
    end;

    procedure InsertFromIncomingDocument(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary)
    var
        SortingOrder: Integer;
    begin
        InsertMainAttachment(IncomingDocument, TempIncDocAttachmentOverview, SortingOrder);
        InsertLinkAddress(IncomingDocument, TempIncDocAttachmentOverview, SortingOrder);
        InsertSupportingAttachments(
          IncomingDocument, TempIncDocAttachmentOverview, SortingOrder,
          IncomingDocument."Document Type" <> IncomingDocument."Document Type"::"Sales Invoice");

        OnAfterInsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview, SortingOrder);
    end;

    procedure InsertSupportingAttachmentsFromIncomingDocument(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary)
    var
        SortingOrder: Integer;
    begin
        InsertSupportingAttachments(IncomingDocument, TempIncDocAttachmentOverview, SortingOrder, false);
    end;

    local procedure InsertMainAttachment(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; var SortingOrder: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not IncomingDocument.GetMainAttachment(IncomingDocumentAttachment) then
            exit;

        if IncomingDocument."Document Type" = IncomingDocument."Document Type"::"Sales Invoice" then
            InsertFromIncomingDocumentAttachment(
              TempIncDocAttachmentOverview, IncomingDocumentAttachment, SortingOrder,
              TempIncDocAttachmentOverview."Attachment Type"::"Supporting Attachment", 0)
        else
            InsertFromIncomingDocumentAttachment(
              TempIncDocAttachmentOverview, IncomingDocumentAttachment, SortingOrder,
              TempIncDocAttachmentOverview."Attachment Type"::"Main Attachment", 0);
    end;

    local procedure InsertSupportingAttachments(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; var SortingOrder: Integer; IncludeGroupCaption: Boolean)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Indentation2: Integer;
    begin
        if not IncomingDocument.GetAdditionalAttachments(IncomingDocumentAttachment) then
            exit;

        if IncludeGroupCaption then
            InsertGroup(TempIncDocAttachmentOverview, IncomingDocument, SortingOrder, SupportingAttachmentsTxt);
        if IncomingDocument."Document Type" = IncomingDocument."Document Type"::"Sales Invoice" then
            Indentation2 := 0
        else
            Indentation2 := 1;
        repeat
            InsertFromIncomingDocumentAttachment(
              TempIncDocAttachmentOverview, IncomingDocumentAttachment, SortingOrder,
              TempIncDocAttachmentOverview."Attachment Type"::"Supporting Attachment", Indentation2);
        until IncomingDocumentAttachment.Next() = 0;
    end;

    local procedure InsertLinkAddress(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; var SortingOrder: Integer)
    var
        URL: Text;
    begin
        URL := IncomingDocument.GetURL();
        if URL = '' then
            exit;

        Clear(TempIncDocAttachmentOverview);
        TempIncDocAttachmentOverview.Init();
        TempIncDocAttachmentOverview."Incoming Document Entry No." := IncomingDocument."Entry No.";
        AssignSortingNo(TempIncDocAttachmentOverview, SortingOrder);
        TempIncDocAttachmentOverview.Name := CopyStr(URL, 1, MaxStrLen(TempIncDocAttachmentOverview.Name));
        TempIncDocAttachmentOverview."Attachment Type" := TempIncDocAttachmentOverview."Attachment Type"::Link;
        TempIncDocAttachmentOverview.Insert(true);
    end;

    local procedure InsertFromIncomingDocumentAttachment(var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; IncomingDocumentAttachment: Record "Incoming Document Attachment"; var SortingOrder: Integer; AttachmentType: Option; Indentation2: Integer)
    begin
        Clear(TempIncDocAttachmentOverview);
        TempIncDocAttachmentOverview.Init();
        TempIncDocAttachmentOverview.TransferFields(IncomingDocumentAttachment);
        AssignSortingNo(TempIncDocAttachmentOverview, SortingOrder);
        TempIncDocAttachmentOverview."Attachment Type" := AttachmentType;
        TempIncDocAttachmentOverview.Indentation := Indentation2;
        TempIncDocAttachmentOverview.Insert(true);
    end;

    local procedure InsertGroup(var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; IncomingDocument: Record "Incoming Document"; var SortingOrder: Integer; Description: Text[50])
    begin
        Clear(TempIncDocAttachmentOverview);
        TempIncDocAttachmentOverview.Init();
        TempIncDocAttachmentOverview."Incoming Document Entry No." := IncomingDocument."Entry No.";
        AssignSortingNo(TempIncDocAttachmentOverview, SortingOrder);
        TempIncDocAttachmentOverview."Attachment Type" := TempIncDocAttachmentOverview."Attachment Type"::Group;
        TempIncDocAttachmentOverview.Type := Type::" ";
        TempIncDocAttachmentOverview.Name := Description;
        TempIncDocAttachmentOverview.Insert(true);
    end;

    local procedure AssignSortingNo(var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; var SortingOrder: Integer)
    begin
        SortingOrder += 1;
        TempIncDocAttachmentOverview."Sorting Order" := SortingOrder;
    end;

    procedure IsGroupOrLink(): Boolean
    begin
        exit(("Attachment Type" = "Attachment Type"::Group) or ("Attachment Type" = "Attachment Type"::Link));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertFromIncomingDocument(IncomingDocument: Record "Incoming Document"; var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; var SortingOrder: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNameDrillDown(var IncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview"; var IsHandled: Boolean)
    begin
    end;
}

