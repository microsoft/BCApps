// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

enum 20461 "Qlty. Certainty"
{
    Caption = 'Quality Certainty';
    Extensible = false;

    value(0; Maybe)
    {
        Caption = 'Maybe';
    }
    value(1; No)
    {
        Caption = 'No';
    }
    value(2; Yes)
    {
        Caption = 'Yes';
    }
}
