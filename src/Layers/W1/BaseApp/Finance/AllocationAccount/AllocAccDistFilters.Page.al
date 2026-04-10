// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Dimension;

/// <summary>
/// Interface for setting dimension and business unit filters for allocation account distribution calculations.
/// Provides dynamic dimension visibility and filter configuration capabilities for balance calculations.
/// </summary>
page 2677 "Alloc. Acc. Dist. Filters"
{
    PageType = Card;
    SourceTable = "Alloc. Account Distribution";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Allocation Account Distribution Filters';

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                Caption = 'Dimension filters';

                field("Dimension 1 Filter"; Rec."Dimension 1 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim1Visible;
                }
                field("Dimension 2 Filter"; Rec."Dimension 2 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim2Visible;
                }
                field("Dimension 3 Filter"; Rec."Dimension 3 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim3Visible;
                }
                field("Dimension 4 Filter"; Rec."Dimension 4 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim4Visible;
                }
                field("Dimension 5 Filter"; Rec."Dimension 5 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim5Visible;
                }
                field("Dimension 6 Filter"; Rec."Dimension 6 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim6Visible;
                }
                field("Dimension 7 Filter"; Rec."Dimension 7 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim7Visible;
                }
                field("Dimension 8 Filter"; Rec."Dimension 8 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim8Visible;
                }
            }

            group(BusinessUnitCode)
            {
                Caption = 'Business Unit Code Filters';
                field("Business Unit Code Filter"; Rec."Business Unit Code Filter")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    var
                        BusinessUnitFilter: Text;
                    begin
#pragma warning disable AA0139
                        if Rec.LookupBusinessUnitFilter(BusinessUnitFilter) then begin
                            Rec."Business Unit Code Filter" := BusinessUnitFilter;
                            Rec.Modify();
                        end;
#pragma warning restore AA0139
                    end;
                }
            }
        }
    }

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;
}
