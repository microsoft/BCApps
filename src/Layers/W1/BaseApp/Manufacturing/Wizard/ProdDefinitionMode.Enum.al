// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

enum 99001011 "Prod. Definition Mode"
{
    Extensible = true;

    value(0; DefineItemStructure)
    {
        Caption = 'Define Item Structure';
    }
    value(1; CreateProductionOrder)
    {
        Caption = 'Create Production Order';
    }
}