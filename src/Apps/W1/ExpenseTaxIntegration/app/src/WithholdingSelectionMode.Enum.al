// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

enum 7055 "Withholding Selection Mode"
{
    Extensible = true;
    Caption = 'Withholding Selection Mode';

    value(0; "Single Tax")
    {
        Caption = 'Single Tax';
    }
    value(1; "Tax Group")
    {
        Caption = 'Tax Group';
    }
}
