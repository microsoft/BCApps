// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

page 5192 "Contact Duplicate Details"
{
    Caption = 'Contact Duplicate Details';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Contact Dupl. Details Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the name of the field where the duplicate was found.';
                }
                field("Field Value"; Rec."Field Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the value of the field where the duplicate was found.';
                }
                field("Duplicate Field Value"; Rec."Duplicate Field Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the value of the duplicate that was found.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.CreateContactDuplicateDetails(NewContactNo, NewDuplicateContactNo);
    end;

    var
        NewContactNo: Code[20];
        NewDuplicateContactNo: Code[20];

    procedure SetContactNo(ContactNo: Code[20]; DuplicateContactNo: Code[20])
    begin
        NewContactNo := ContactNo;
        NewDuplicateContactNo := DuplicateContactNo;
    end;
}

