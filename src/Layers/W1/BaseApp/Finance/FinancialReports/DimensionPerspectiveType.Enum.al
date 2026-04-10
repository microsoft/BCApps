// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 8363 "Dimension Perspective Type" implements IDimensionPerspective
{
    Caption = 'Financial Report Dimension Perspective Type';

    value(0; Custom)
    {
        Caption = 'Custom';
        Implementation = IDimensionPerspective = DimPerspectiveCustom;
    }
    value(1; Dimension1)
    {
        Caption = 'Dimension 1';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(2; Dimension2)
    {
        Caption = 'Dimension 2';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(3; Dimension3)
    {
        Caption = 'Dimension 3';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(4; Dimension4)
    {
        Caption = 'Dimension 4';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(5; Dimension5)
    {
        Caption = 'Dimension 5';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(6; Dimension6)
    {
        Caption = 'Dimension 6';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(7; Dimension7)
    {
        Caption = 'Dimension 7';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(8; Dimension8)
    {
        Caption = 'Dimension 8';
        Implementation = IDimensionPerspective = DimPerspectiveDimension;
    }
    value(9; BusinessUnit)
    {
        Caption = 'Business Unit';
        Implementation = IDimensionPerspective = DimPerspectiveBusinessUnit;
    }
}