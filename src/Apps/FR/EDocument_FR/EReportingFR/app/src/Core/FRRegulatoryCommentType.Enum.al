// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10971 "FR Regulatory Comment Type"
{
    Extensible = false;

    value(0; AAB)
    {
        Caption = 'AAB';
    }
    value(1; PMD)
    {
        Caption = 'PMD';
    }
    value(2; PMT)
    {
        Caption = 'PMT';
    }
}