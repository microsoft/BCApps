// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Staged participant from a receipt. Added to the expense and its expense report line only when they have no participants.
/// </summary>
table 7432 "EA Card Receipt Participant"
{
    Access = Internal;
    Caption = 'Card Receipt Participant';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Receipt Data Id"; Guid)
        {
            Caption = 'Receipt Data Id';
            ToolTip = 'Specifies the receipt data that the participant belongs to.';
            TableRelation = "EA Card Receipt Data".Id;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the participant.';
        }
        field(10; "Participant Type"; Enum "Expense Participant Type")
        {
            Caption = 'Participant Type';
            ToolTip = 'Specifies the type of participant.';
        }
        field(11; "Participant Employee No."; Code[20])
        {
            Caption = 'Participant Employee No.';
            DataClassification = EndUserPseudonymousIdentifiers;
            ToolTip = 'Specifies the employee number when the participant is an employee.';
        }
        field(12; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
            ToolTip = 'Specifies the name of the participant.';
        }
        field(13; "Participant Organization"; Text[100])
        {
            Caption = 'Participant Organization';
            ToolTip = 'Specifies the organization of the participant.';
        }
        field(16; "Participant Email"; Text[80])
        {
            Caption = 'Participant Email';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the email address of the participant.';
        }
    }

    keys
    {
        key(PK; "Receipt Data Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
