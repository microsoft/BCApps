// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7222 "EA Corp Card Trans Status"
{
    Caption = 'Corp Card Trans Status';

    value(0; Imported)
    {
        Caption = 'Imported';
    }
    value(1; Matched)
    {
        Caption = 'Matched';
    }
    value(2; DraftCreated)
    {
        Caption = 'Draft Created';
    }
    value(3; Submitted)
    {
        Caption = 'Submitted';
    }
    value(4; Posted)
    {
        Caption = 'Posted';
    }
    value(5; Rejected)
    {
        Caption = 'Rejected';
    }
    value(6; Exception)
    {
        Caption = 'Exception';
    }
}