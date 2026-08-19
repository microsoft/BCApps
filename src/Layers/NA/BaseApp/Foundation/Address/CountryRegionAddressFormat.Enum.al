// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

enum 8 "Country/Region Address Format"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Post Code+City") { Caption = 'Post Code+City'; }
    value(1; "City+Post Code") { Caption = 'City+Post Code'; }
    value(2; "City+County+Post Code") { Caption = 'City+County+Post Code'; }
    value(3; "Blank Line+Post Code+City") { Caption = 'Blank Line+Post Code+City'; }
    value(5; "City+County+New Line+Post Code") { Caption = 'City+County+New Line+Post Code'; }
    value(6; "Post Code+City+County") { Caption = 'Post Code+City+County'; }
    value(13; "Custom") { Caption = 'Custom'; }
}
