// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

enum 5930 "Archive Service Quotes"
{
    Caption = 'Archive Service Quotes';

    value(0; Never)
    {
        Caption = 'Never';
    }
    value(1; Question)
    {
        Caption = 'Question';
    }
    value(2; Always)
    {
        Caption = 'Always';
    }
}