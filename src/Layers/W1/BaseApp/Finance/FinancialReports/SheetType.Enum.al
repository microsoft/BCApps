// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 8363 "Sheet Type" implements ISheetDefinition
{
    Caption = 'Financial Report Sheet Type';

    value(0; Custom)
    {
        Caption = 'Custom';
        Implementation = ISheetDefinition = SheetDefCustom;
    }
    value(1; Dimension1)
    {
        Caption = 'Dimension 1';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(2; Dimension2)
    {
        Caption = 'Dimension 2';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(3; Dimension3)
    {
        Caption = 'Dimension 3';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(4; Dimension4)
    {
        Caption = 'Dimension 4';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(5; Dimension5)
    {
        Caption = 'Dimension 5';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(6; Dimension6)
    {
        Caption = 'Dimension 6';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(7; Dimension7)
    {
        Caption = 'Dimension 7';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(8; Dimension8)
    {
        Caption = 'Dimension 8';
        Implementation = ISheetDefinition = SheetDefDimension;
    }
    value(9; BusinessUnit)
    {
        Caption = 'Business Unit';
        Implementation = ISheetDefinition = SheetDefBusinessUnit;
    }
}