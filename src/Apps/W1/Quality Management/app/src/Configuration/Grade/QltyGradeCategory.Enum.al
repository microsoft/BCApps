// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

/// <summary>
/// A general categorization of whether this grade represents good or bad.
/// </summary>
enum 20434 "Qlty. Grade Category"
{
    Caption = 'Quality Grade Category';

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
