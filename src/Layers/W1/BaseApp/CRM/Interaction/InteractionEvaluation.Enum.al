// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

enum 5078 "Interaction Evaluation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Very Positive")
    {
        Caption = 'Very Positive';
    }
    value(2; "Positive")
    {
        Caption = 'Positive';
    }
    value(3; "Neutral")
    {
        Caption = 'Neutral';
    }
    value(4; "Negative")
    {
        Caption = 'Negative';
    }
    value(5; "Very Negative")
    {
        Caption = 'Very Negative';
    }
}
