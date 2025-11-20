// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.BusinessRelation;

page 9130 "Contact Statistics FactBox"
{
    Caption = 'Contact Statistics';
    PageType = CardPart;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total cost of all the interactions involving the contact. The field is not editable.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total duration of all the interactions involving the contact. The field is not editable.';
                }
            }
            group(Opportunities)
            {
                Caption = 'Opportunities';
                field("No. of Opportunities"; Rec."No. of Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of open opportunities involving the contact. The field is not editable.';
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total estimated value of all the opportunities involving the contact. The field is not editable.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total calculated current value of all the opportunities involving the contact. The field is not editable.';
                }
            }
            group(Segmentation)
            {
                Caption = 'Segmentation';
                field("No. of Job Responsibilities"; Rec."No. of Job Responsibilities")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of job responsibilities for this contact. This field is valid for persons only and is not editable.';
                }
                field("No. of Industry Groups"; Rec."No. of Industry Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of industry groups to which the contact belongs. When the contact is a person, this field contains the number of industry groups for the contact''s company. This field is not editable.';
                }
                field("No. of Business Relations"; NoOfBusinessRelations)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'No. of Business Relations';
                    ToolTip = 'Specifies the number of business relations, such as customer, vendor, or competitor, that your company has with this contact.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowBusinessRelation(Enum::"Contact Business Relation Link To Table"::" ", true);
                    end;
                }
                field("No. of Mailing Groups"; Rec."No. of Mailing Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of mailing groups for this contact.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        NoOfBusinessRelations := Rec.CountNoOfBusinessRelations(Enum::"Contact Business Relation Link To Table"::" ");
    end;

    var
        NoOfBusinessRelations: Integer;
}

