// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// A general categorization of whether this result represents good or bad.
/// </summary>
enum 20434 "Qlty. Result Category"
{
    Caption = 'Quality Result Category';

    value(0; Uncategorized)
    {
        Caption = ' ';
    }
    value(1; Acceptable)
    {
        Caption = 'Acceptable';
    }
    value(2; "Not acceptable")
    {
        Caption = 'Not acceptable';
    }
}
