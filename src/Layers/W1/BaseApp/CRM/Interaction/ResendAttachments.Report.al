// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Segment;

report 5183 "Resend Attachments"
{
    Caption = 'Resend Attachments';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Interaction Log Entry"; "Interaction Log Entry")
        {
            DataItemTableView = sorting("Logged Segment Entry No.") where(Postponed = const(false));
            RequestFilterFields = "Logged Segment Entry No.", "Entry No.", "Delivery Status", "Correspondence Type", "Contact No.", "Campaign No.";

            trigger OnAfterGetRecord()
            var
                Attachment: Record Attachment;
                InteractionLogEntryNew: Record "Interaction Log Entry";
                SegLine: Record "Segment Line";
                InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
                SegManagement: Codeunit SegManagement;
                NewEntryNo: Integer;
            begin
                if not Attachment.Get("Attachment No.") then
                    CurrReport.Skip();
                if Attachment."Storage Type" = Attachment."Storage Type"::"Exchange Storage" then
                    CurrReport.Skip();
                if CorrespondenceType = CorrespondenceType::"Same as Entry" then
                    TestField("Correspondence Type");

                if UpdateMergeFields then begin
                    if TempDeliverySorter.Get("Entry No.") then
                        CurrReport.Skip();
                    InteractionLogEntryNew.TransferFields("Interaction Log Entry", false);
                    InteractionLogEntryNew.Validate(Date, WorkDate());
                    InteractionLogEntryNew.Validate("Time of Interaction", Time);
                    if StrPos(Description, Text003) <> 1 then
                        if StrLen(Description) + StrLen(Text003) <= MaxStrLen(InteractionLogEntryNew.Description) then
                            InteractionLogEntryNew.Validate(Description, Text003 + Description)
                        else
                            InteractionLogEntryNew.Validate(Description, CopyStr(
                                Text003 + Description, 1, MaxStrLen(InteractionLogEntryNew.Description)));
                    if CorrespondenceType <> CorrespondenceType::"Same as Entry" then
                        InteractionLogEntryNew."Correspondence Type" := AttachmentManagement.ConvertCorrespondenceType(CorrespondenceType);
                    SegLine.CopyFromInteractLogEntry(InteractionLogEntryNew);
                    InterLogEntryCommentLine.SetRange("Entry No.", "Entry No.");
                    if InterLogEntryCommentLine.FindFirst() then;
                    Attachment.CalcFields("Attachment File");
                    Clear(Attachment."Merge Source");
                    NewEntryNo := SegManagement.LogInteraction(SegLine, Attachment, InterLogEntryCommentLine, false, false);
                    InteractionLogEntryNew.Get(NewEntryNo);
                    InteractionLogEntryNew.Validate("Logged Segment Entry No.", "Logged Segment Entry No.");
                    InteractionLogEntryNew.Validate("Delivery Status", "Delivery Status"::"In Progress");
                    InteractionLogEntryNew.Validate("E-Mail Logged", false);
                    InteractionLogEntryNew.Modify(true);
                end else begin
                    if CorrespondenceType <> CorrespondenceType::"Same as Entry" then
                        "Correspondence Type" := AttachmentManagement.ConvertCorrespondenceType(CorrespondenceType);
                    "Delivery Status" := "Delivery Status"::"In Progress";
                    "E-Mail Logged" := false;
                    Modify();
                end;

                TempDeliverySorter.Init();
                if UpdateMergeFields then begin
                    TempDeliverySorter."No." := NewEntryNo;
                    TempDeliverySorter."Attachment No." := InteractionLogEntryNew."Attachment No.";
                    TempDeliverySorter."Correspondence Type" := InteractionLogEntryNew."Correspondence Type"
                end else begin
                    TempDeliverySorter."No." := "Entry No.";
                    TempDeliverySorter."Attachment No." := "Attachment No.";
                    TempDeliverySorter."Correspondence Type" := "Correspondence Type"
                end;
                TempDeliverySorter.Subject := Subject;
                TempDeliverySorter."Send Word Docs. as Attmt." := "Send Word Docs. as Attmt.";
                TempDeliverySorter."Language Code" := "Interaction Language Code";
                OnBeforeDeliverySorterInsert(TempDeliverySorter, "Interaction Log Entry");
                TempDeliverySorter.Insert();
            end;

            trigger OnPostDataItem()
            begin
                if TempDeliverySorter.Count = 0 then
                    Error(Text002);

                Commit();
                AttachmentManagement.Send(TempDeliverySorter);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CorrespondenceType; CorrespondenceType)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                        OptionCaption = 'Same as Entry,Hard Copy,Email,Fax';
                        ToolTip = 'Specifies a correspondence type to specify how you want the program to resend the attachment.';
                    }
                    field("Update Merge Fields"; UpdateMergeFields)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Update Merge Fields';
                        ToolTip = 'Specifies if you want to refresh the information in your Word document merge.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        LoggedSeg: Record "Logged Segment";
    begin
        if "Interaction Log Entry".GetFilter("Logged Segment Entry No.") = '' then
            Error(Text000, "Interaction Log Entry".FieldCaption("Logged Segment Entry No."));

        if "Interaction Log Entry".GetFilter("Logged Segment Entry No.") <> '0' then begin
            LoggedSeg.SetFilter("Entry No.", "Interaction Log Entry".GetFilter("Logged Segment Entry No."));
            if LoggedSeg.Count <> 1 then
                Error(
                  Text001, LoggedSeg.TableCaption());
        end;
    end;

    var
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
        CorrespondenceType: Option "Same as Entry","Hard Copy",Email,Fax;
        UpdateMergeFields: Boolean;
#pragma warning disable AA0074
        Text003: Label 'Resend:';
#pragma warning restore AA0074

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
        Text001: Label 'The interaction log entries must always be from the same %1.';
#pragma warning restore AA0470
        Text002: Label 'There is nothing to send.\\Only Microsoft Word documents can be resent.';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliverySorterInsert(var TempDeliverySorter: Record "Delivery Sorter" temporary; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;
}

