// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;

pageextension 20409 "Qlty. Item Tracking Summary" extends "Item Tracking Summary"
{
    layout
    {
        addafter("Selected Quantity")
        {
            field(QltyInspectionResultDescription; MostRecentQltyResultDescription)
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Caption = 'Quality Result';
                ToolTip = 'Specifies the most recent result for this item tracking specification.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader.SetRange("Source Lot No.", Rec."Lot No.");
                    QltyInspectionHeader.SetRange("Source Serial No.", Rec."Serial No.");
                    QltyInspectionHeader.SetRange("Source Package No.", Rec."Package No.");
                    if QltyInspectionHeader.FindFirst() then;
                    Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
                end;
            }
            field("Qlty. Inspection Count"; Rec."Qlty. Inspection Count")
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Editable = false;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(Qlty_ChooseFromAnyDocument)
            {
                ApplicationArea = QualityManagement;
                Image = AllLines;
                Caption = 'Show all Tracking for Item';
                ToolTip = 'Click this to see item tracking regardless of the source document. Use this if you need to choose a lot, serial or package number that is not related to the source document you are creating the inspection for.';
                Visible = ShowQltyManagementActions;

                trigger OnAction()
                begin
                    QltySessionHelper.SetTrackingFormModeFlag(QltySessionHelper.GetTrackingFormFlagValueAllDocs());
                    CurrPage.Close();
                end;
            }
            action(Qlty_ChooseSingleDocument)
            {
                ApplicationArea = QualityManagement;
                Image = Line;
                Caption = 'Source Document Item Tracking';
                ToolTip = 'Shows item tracking that relates to the matching source document number.';
                Visible = ShowQltyManagementActions;

                trigger OnAction()
                begin
                    QltySessionHelper.SetTrackingFormModeFlag(QltySessionHelper.GetTrackingFormFlagValueSourceDoc());
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        MostRecentQltyResultDescription: Text;
        ShowQltyManagementActions: Boolean;

    trigger OnOpenPage()
    begin
        ShowQltyManagementActions := ShowQltyManagementActions or QltySessionHelper.GetStartingFromQualityManagementFlagAndResetFlag();
    end;

    trigger OnAfterGetRecord()
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        DummyResultCode: Code[20];
    begin
        QltyItemTracking.GetMostRecentResultFor('', '', Rec."Lot No.", Rec."Serial No.", Rec."Package No.", DummyResultCode, MostRecentQltyResultDescription);
    end;
}
