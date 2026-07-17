// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

enum 10974 "FR E-Invoice Lifecycle Proc."
{
    Extensible = false;

    value(0; Captured)
    {
        Caption = 'Captured';
    }
    value(1; "Message Created")
    {
        Caption = 'Message Created';
    }
    value(2; Queued)
    {
        Caption = 'Queued';
    }
    value(3; Sent)
    {
        Caption = 'Sent';
    }
    value(4; Failed)
    {
        Caption = 'Failed';
    }
}