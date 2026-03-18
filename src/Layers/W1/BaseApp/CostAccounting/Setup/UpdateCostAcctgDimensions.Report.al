// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Setup;

using Microsoft.Finance.Dimension;

report 1140 "Update Cost Acctg. Dimensions"
{
    Caption = 'Update Cost Acctg. Dimensions';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CostCenterDimension; NewCCDimension)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Cost Center Dimension';
                        TableRelation = Dimension;
                        ToolTip = 'Specifies the new cost object dimension.';

                        trigger OnValidate()
                        begin
                            if NewCCDimension = '' then begin
                                GetInitialDimensions();
                                UpdateDimension := false;
                                Error(MustBeFilleddErr, CostAccSetup.FieldCaption("Cost Center Dimension"));
                            end;
                            if NewCCDimension = NewCODimension then begin
                                GetInitialDimensions();
                                UpdateDimension := false;
                                Error(DimensionValuesSameErr);
                            end;

                            if CostAccSetup."Cost Center Dimension" <> NewCCDimension then
                                UpdateDimension := true;
                        end;
                    }
                    field(CostObjectDimension; NewCODimension)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Cost Object Dimension';
                        TableRelation = Dimension;
                        ToolTip = 'Specifies where you should assign costs.';

                        trigger OnValidate()
                        begin
                            if NewCODimension = '' then begin
                                GetInitialDimensions();
                                UpdateDimension := false;
                                Error(MustBeFilleddErr, CostAccSetup.FieldCaption("Cost Object Dimension"));
                            end;
                            if NewCCDimension = NewCODimension then begin
                                GetInitialDimensions();
                                UpdateDimension := false;
                                Error(DimensionValuesSameErr);
                            end;

                            if CostAccSetup."Cost Object Dimension" <> NewCODimension then
                                UpdateDimension := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CostAccSetup.Get();
            GetInitialDimensions();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if UpdateDimension then begin
            if not Confirm(UpdateDimensionsQst, true) then
                Error('');

            CostAccSetup.Validate("Cost Center Dimension", NewCCDimension);
            CostAccSetup.Validate("Cost Object Dimension", NewCODimension);
            CostAccSetup.Modify(true);
        end;
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        NewCCDimension: Code[20];
        NewCODimension: Code[20];
        UpdateDimension: Boolean;
        UpdateDimensionsQst: Label 'Before you change the corresponding dimension on G/L entries, make sure all G/L entries using the previously defined dimension have been transferred to Cost Accounting. \\Do you want to proceed?';
        DimensionValuesSameErr: Label 'The dimension values for cost center and cost object cannot be same.';
#pragma warning disable AA0470
        MustBeFilleddErr: Label '%1 must be filled in. Enter a value.';
#pragma warning restore AA0470

    local procedure GetInitialDimensions()
    begin
        NewCCDimension := CostAccSetup."Cost Center Dimension";
        NewCODimension := CostAccSetup."Cost Object Dimension";
    end;
}

