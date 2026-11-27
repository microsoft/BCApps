// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7422 "EA Card Receipt Particip. API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'cardReceiptParticipant';
    EntitySetName = 'cardReceiptParticipants';
    EntityCaption = 'Card Receipt Participant';
    EntitySetCaption = 'Card Receipt Participants';
    SourceTable = "EA Card Receipt Participant";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(participantType; Rec."Participant Type")
                {
                    Caption = 'Participant Type';
                }
                field(participantEmployeeNo; Rec."Participant Employee No.")
                {
                    Caption = 'Participant Employee No.';
                }
                field(participantName; Rec."Participant Name")
                {
                    Caption = 'Participant Name';
                }
                field(participantOrganization; Rec."Participant Organization")
                {
                    Caption = 'Participant Organization';
                }
                field(participantEmail; Rec."Participant Email")
                {
                    Caption = 'Participant Email';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CardReceiptData: Record "EA Card Receipt Data";
        CardReceiptParticipant: Record "EA Card Receipt Participant";
        ReceiptDataFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        if IsNullGuid(Rec."Receipt Data Id") then begin
            OriginalFilterGroup := Rec.FilterGroup();
            Rec.FilterGroup(4);
            ReceiptDataFilter := Rec.GetFilter("Receipt Data Id");
            Rec.FilterGroup(OriginalFilterGroup);
            if ReceiptDataFilter <> '' then
                if Evaluate(Rec."Receipt Data Id", ReceiptDataFilter) then;
        end;
        CardReceiptData.Get(Rec."Receipt Data Id");
        if Rec."Line No." = 0 then begin
            CardReceiptParticipant.SetRange("Receipt Data Id", Rec."Receipt Data Id");
            if CardReceiptParticipant.FindLast() then;
            Rec."Line No." := CardReceiptParticipant."Line No." + 10000;
        end;
        exit(true);
    end;
}
