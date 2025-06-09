// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

/// <summary>
/// Specifies the detail level for image processing in vision-enabled models.
/// </summary>
enum 7770 "AOAI Image Detail Level"
{
    Extensible = true;
    Access = Public;

    value(0; low)
    {
        Caption = 'low';
    }
    value(1; high)
    {
        Caption = 'high';
    }
    value(2; auto)
    {
        Caption = 'auto';
    }
}