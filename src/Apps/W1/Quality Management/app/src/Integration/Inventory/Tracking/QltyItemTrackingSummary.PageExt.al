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
        addafter("Total Available Quantity")
        {
            field(QltyInspectionGradeDescription; MostRecentQltyGradeDescription)
            {
                AccessByPermission = tabledata "Qlty. Inspection Test Header" = R;
                ApplicationArea = QualityManagement;
                Caption = 'Quality Grade';
                ToolTip = 'Specifies the most recent grade for this item tracking specification.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader.SetRange("Source Lot No.", Rec."Lot No.");
                    QltyInspectionTestHeader.SetRange("Source Serial No.", Rec."Serial No.");
                    QltyInspectionTestHeader.SetRange("Source Package No.", Rec."Package No.");
                    if QltyInspectionTestHeader.FindFirst() then;
                    Page.Run(Page::"Qlty. Inspection Test List", QltyInspectionTestHeader);
                end;
            }
            field("Qlty. Inspection Test Count"; Rec."Qlty. Inspection Test Count")
            {
                AccessByPermission = tabledata "Qlty. Inspection Test Header" = R;
                ApplicationArea = QualityManagement;
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
                ToolTip = 'Click this to see item tracking regardless of the source document. Use this if you need to choose a lot, serial or package number that is not related to the source document you are creating the test for.';
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
                Caption = 'Source Document Item Tracking only';
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
        MostRecentQltyGradeDescription: Text;
        ShowQltyManagementActions: Boolean;

    trigger OnOpenPage()
    begin
        ShowQltyManagementActions := ShowQltyManagementActions or QltySessionHelper.GetStartingFromQualityManagementFlagAndResetFlag();
    end;

    trigger OnAfterGetRecord()
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        DummyGradeCode: Code[20];
    begin
        QltyItemTracking.GetMostRecentGradeFor('', '', Rec."Lot No.", Rec."Serial No.", Rec."Package No.", DummyGradeCode, MostRecentQltyGradeDescription);
    end;
}
