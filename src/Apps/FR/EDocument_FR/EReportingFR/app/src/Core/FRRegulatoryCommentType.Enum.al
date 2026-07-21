// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10971 "FR Regulatory Comment Type"
{
    Extensible = false;

    value(0; None)
    {
        Caption = '';
    }
    value(1; AAB)
    {
        Caption = 'AAB';
    }
    value(2; PMD)
    {
        Caption = 'PMD';
    }
    value(3; PMT)
    {
        Caption = 'PMT';
    }
}