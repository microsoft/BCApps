// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

page 7417 "Item Excise Tax API"
{
    PageType = API;
    Caption = 'Item Excise Tax';
    APIPublisher = 'microsoft';
    APIGroup = 'exciseTaxes';
    APIVersion = 'v1.0';
    EntityName = 'itemExciseTax';
    EntitySetName = 'itemExciseTaxes';
    SourceTable = "Item Excise Tax";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(exciseTaxType; Rec."Excise Tax Type Code")
                {
                    Caption = 'Excise Tax Type';
                }
                field(quantityExciseTax; Rec."Quantity for Excise Tax")
                {
                    Caption = 'Quantity Excise Tax';
                }
                field(exciseTaxUom; Rec."Excise Unit of Measure Code")
                {
                    Caption = 'Excise Tax UOM';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }
}
