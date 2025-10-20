// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

page 6154 "E-Doc. Purchase Line History"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "E-Doc. Purchase Line History";
    Caption = 'E-Doc. Purchase Line History';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number.';
                }
                field("Product Code"; Rec."Product Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the product code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field("Purch. Inv. Line SystemId"; Rec."Purch. Inv. Line SystemId")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the system ID of the purchase invoice line.';
                }
            }
        }
    }
}
