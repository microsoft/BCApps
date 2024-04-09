// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text;

using System.Text;
#pragma warning disable AS0099
enumextension 132584 AutoFormatTest extends "Auto Format"
{
    value(132584; Whatever)
    {
        Caption = 'Whatever';
    }
#pragma warning disable PTE0023 // The ID is in the right range but unfortunately there's only one ID in that range
    value(132585; "1 decimal")
    {
        Caption = '1 decimal';
    }
#pragma warning restore PTE0023 // The ID is in the right range but unfortunately there's only one ID in that range
}
#pragma warning restore AS0099
