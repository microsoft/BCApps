// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Security.User;

page 9092 "Approval FactBox"
{
    Caption = 'Approval';
    PageType = CardPart;
    SourceTable = "Approval Entry";

    layout
    {
        area(content)
        {
            field(DocumentHeading; DocumentHeading)
            {
                ApplicationArea = Suite;
                Caption = 'Document';
                ToolTip = 'Specifies the document that has been approved.';
            }
            field(Status; Rec.Status)
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the approval status for the entry:';
            }
            field("Approver ID"; Rec."Approver ID")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the ID of the user who must approve the document (the Approver).';

                trigger OnDrillDown()
                var
                    UserMgt: Codeunit "User Management";
                begin
                    UserMgt.DisplayUserInformation(Rec."Approver ID");
                end;
            }
            field("Date-Time Sent for Approval"; Rec."Date-Time Sent for Approval")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the date and the time that the document was sent for approval.';
            }
            field(Comment; Rec.Comment)
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies whether there are comments relating to the approval of the record. If you want to read the comments, choose the field to open the Approval Comment Sheet window.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DocumentHeading := GetDocumentHeading(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        OnBeforeOnFindRecord(Rec);

        DocumentHeading := '';
        exit(Rec.FindLast());
    end;

    var
        DocumentHeading: Text[250];
#pragma warning disable AA0074
        Text000: Label 'Document';
#pragma warning restore AA0074

    local procedure GetDocumentHeading(ApprovalEntry: Record "Approval Entry"): Text[50]
    var
        Heading: Text[50];
    begin
        if ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::" " then
            Heading := Text000
        else
            Heading := Format(ApprovalEntry."Document Type");
        Heading := Heading + ' ' + ApprovalEntry."Document No.";
        exit(Heading);
    end;

    procedure UpdateApprovalEntriesFromSourceRecord(SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateApprovalEntriesFromSourceRecord(Rec, SourceRecordID, IsHandled);
        if IsHandled then
            exit;

        Rec.FilterGroup(2);
        Rec.SetRange("Record ID to Approve", SourceRecordID);
        ApprovalEntry.Copy(Rec);
        if ApprovalEntry.FindFirst() then
            Rec.SetFilter("Approver ID", '<>%1', ApprovalEntry."Sender ID");
        Rec.FilterGroup(0);
        OnUpdateApprovalEntriesFromSourceRecordOnAfterApprovalEntrySetFilter(ApprovalEntry);
        if Rec.FindLast() then;
        CurrPage.Update(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnFindRecord(var ApprovalEntry: Record "Approval Entry");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateApprovalEntriesFromSourceRecord(var ApprovalEntry: Record "Approval Entry"; SourceRecordID: RecordID; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateApprovalEntriesFromSourceRecordOnAfterApprovalEntrySetFilter(var ApprovalEntry: Record "Approval Entry")
    begin
    end;
}

