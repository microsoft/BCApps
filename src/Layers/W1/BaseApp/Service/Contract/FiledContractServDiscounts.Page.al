// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6089 "Filed Contract/Serv. Discounts"
{
    Caption = 'Filed Contract/Service Discounts';
    DataCaptionFields = "Contract No.";
    Editable = false;
    PageType = List;
    SourceTable = "Filed Contract/Serv. Discount";

    layout
    {
        area(content)
        {
            repeater(ContractServiceDiscounts)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Service;
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}