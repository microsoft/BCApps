// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7437 "EA Corp Card Settle Status"
{
    Caption = 'Corp Card Settlement Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; ReadyToPost)
    {
        Caption = 'Ready to Post';
    }
    value(2; Posted)
    {
        Caption = 'Posted';
    }
    value(3; Reversed)
    {
        Caption = 'Reversed';
    }
}
