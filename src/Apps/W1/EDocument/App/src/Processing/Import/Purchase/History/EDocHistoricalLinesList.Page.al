// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.History;

page 6186 "E-Doc. Historical Lines List"
{
    ApplicationArea = All;
    Caption = 'Historical Purchase Lines';
    PageType = List;
    SourceTable = "Purch. Inv. Line";
    SourceTableTemporary = true;
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the historical purchase line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the item, resource, or G/L account.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the purchase line.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number for this historical purchase line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure.';
                    Visible = false;
                }
                field("Allocation Account No."; Rec."Allocation Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the allocation account number used for distributing the cost.';
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the deferral code assigned to this line.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the shortcut dimension 1 code.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the shortcut dimension 2 code.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the historical purchase invoice.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted purchase invoice number.';
                    Visible = false;
                }
            }
        }
    }

    procedure SetRecords(var TempPurchInvLine: Record "Purch. Inv. Line" temporary)
    begin
        if TempPurchInvLine.FindSet() then
            repeat
                Rec := TempPurchInvLine;
                Rec.Insert();
            until TempPurchInvLine.Next() = 0;
    end;
}
